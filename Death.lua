-- Initialize the Death module in the SchlingelInc namespace
SchlingelInc.Death = {
	lastChatMessage = "",
	lastAttackSource = "",
	MAX_LOG_ENTRIES = 50  -- Maximum number of stored deaths
}

-- Initialize CharacterDeaths to avoid nil reference
CharacterDeaths = CharacterDeaths or 0

-- Cooldown for sending own death to guild (seconds)
local lastOwnDeathSendTime = 0

-- Session-based death log (NOT persisted, only during session)
-- This prevents out-of-sync issues when players are offline
SchlingelInc.DeathLogData = {}

-- Track deaths we've already processed to prevent duplicates
local seenDeaths = {}

-- Function to add an entry to the death log with rotation
function SchlingelInc.Death:AddLogEntry(entry)
	table.insert(SchlingelInc.DeathLogData, 1, entry)

	-- Rotation: Keep only the last MAX_LOG_ENTRIES entries
	while #SchlingelInc.DeathLogData > SchlingelInc.Death.MAX_LOG_ENTRIES do
		table.remove(SchlingelInc.DeathLogData)
	end
end

-- Parse guild chat death messages
-- Format: "Name der/die Class ist mit Level X in Zone gestorben. Schande!"
-- Format with handle: "Name (DiscordHandle) der/die Class ist mit Level X in Zone gestorben. Schande!"
-- Format with rank: "Ewiger Schlingel Name, der/die Class ist mit Level X in Zone gestorben. Schande!"
-- Format with rank and handle: "Ewiger Schlingel Name (DiscordHandle), der/die Class ist mit Level X in Zone gestorben. Schande!"
-- Format with cause: "... Gestorben an Source"
-- Format with last words: '... Die letzten Worte: "text"'
local function parseGuildDeathMessage(message)
	local name, discordHandle, pronoun, className, level, zone, cause, lastWords

	-- Extract optional ' Die letzten Worte: "..."' suffix
	lastWords = message:match(' Die letzten Worte: "(.+)"$')
	local cleanMessage = message:gsub('%. Die letzten Worte: ".-"$', "")

	-- Extract optional " Gestorben an [source]" suffix
	cause = cleanMessage:match(" Gestorben an (.+)$")
	if cause then
		-- Remove the "Gestorben an" part for further parsing
		cleanMessage = cleanMessage:gsub(" Gestorben an .+$", "")
	end

	-- Try format with rank and handle: "Ewiger Schlingel Name (Handle), der/die Class ist mit Level X in Zone gestorben. Schande!"
	name, discordHandle, pronoun, className, level, zone = cleanMessage:match("^Ewiger Schlingel ([^%(]+) %(([^%)]+)%), (d[ei][re]) (.+) ist mit Level (%d+) in (.+) gestorben%. Schande!$")

	-- Try format with rank without handle: "Ewiger Schlingel Name, der/die Class ist mit Level X in Zone gestorben. Schande!"
	if not name then
		name, pronoun, className, level, zone = cleanMessage:match("^Ewiger Schlingel ([^,]+), (d[ei][re]) (.+) ist mit Level (%d+) in (.+) gestorben%. Schande!$")
		discordHandle = nil
	end

	-- Try format with handle: "Name (Handle) der/die Class ist mit Level X in Zone gestorben. Schande!"
	if not name then
		name, discordHandle, pronoun, className, level, zone = cleanMessage:match("^([^%(]+) %(([^%)]+)%) (d[ei][re]) (.+) ist mit Level (%d+) in (.+) gestorben%. Schande!$")
	end

	-- Try standard format without handle: "Name der/die Class ist mit Level X in Zone gestorben. Schande!"
	if not name then
		name, pronoun, className, level, zone = cleanMessage:match("^(.+) (d[ei][re]) (.+) ist mit Level (%d+) in (.+) gestorben%. Schande!$")
		discordHandle = nil
	end

	if not name or not level or not zone then return nil end

	-- Trim whitespace from name
	name = name:match("^%s*(.-)%s*$")

	return {
		name = name,
		class = className,
		level = tonumber(level),
		zone = zone,
		cause = cause,
		lastWords = lastWords,
		discordHandle = discordHandle,
		pronoun = pronoun,
	}
end

-- Process a death (from guild chat parsing or addon messages)
local function processDeath(data, isOwnDeath)
	-- Create unique ID to prevent duplicates
	local deathID = data.name .. "-" .. data.level .. "-" .. data.zone .. "-" .. time()
	if seenDeaths[deathID] then
		return
	end
	seenDeaths[deathID] = true

	-- Add to death log
	local deathEntry = {
		name = data.name,
		class = data.class,
		level = data.level,
		zone = data.zone,
		cause = data.cause or "Unbekannt",
		lastWords = data.lastWords,
		discordHandle = data.discordHandle,
		timestamp = time()
	}
	SchlingelInc.Death:AddLogEntry(deathEntry)

	-- Update UI
	SchlingelInc:UpdateMiniDeathLog()

	-- Show death announcement popup
	local pronoun = data.pronoun or "der"
	local messageString
	if data.discordHandle and data.discordHandle ~= "" then
		messageString = string.format("%s (%s) %s %s ist mit Level %s in %s gestorben.",
			data.name, data.discordHandle, pronoun, data.class, data.level, data.zone)
	else
		messageString = string.format("%s %s %s ist mit Level %s in %s gestorben.",
			data.name, pronoun, data.class, data.level, data.zone)
	end
	SchlingelInc.DeathAnnouncement:ShowDeathMessage(messageString)
end

-- Public wrapper for use from other modules (e.g. Global.lua addon message handler)
SchlingelInc.Death.ProcessDeath = function(data)
	processDeath(data, false)
end

-- Initializes the Death module and registers events
function SchlingelInc.Death:Initialize()
	local playerName = UnitName("player")

	-- PLAYER_DEAD event handler
	SchlingelInc.EventManager:RegisterHandler("PLAYER_DEAD",
		function()
			local name = UnitName("player")
			if not name then return end

			local _, rank = GetGuildInfo("player")
			local class = UnitClass("player")
			local level = UnitLevel("player")
			local sex = UnitSex("player")

			local inPvP = SchlingelInc:IsInBattleground() or SchlingelInc:IsInRaid() or SchlingelInc:IsInArena()
			if inPvP and level == SchlingelInc.Rules.CurrentCap then
				return
			end

			-- Safe zone query with error handling
			local zone, mapID
			if IsInInstance() then
				zone = GetInstanceInfo()
			else
				mapID = C_Map.GetBestMapForUnit("player")
				if mapID then
					local mapInfo = C_Map.GetMapInfo(mapID)
					zone = mapInfo and mapInfo.name or "Unknown"
				else
					zone = "Unknown"
				end
			end

			local pronoun = SchlingelInc.Constants.PRONOUNS[sex] or "der"

			-- Get Discord handle for death message
			local discordHandle = SchlingelInc:GetDiscordHandle()

			-- Build death message with optional Discord handle
			local messageString
			if (rank ~= nil and rank == "EwigerSchlingel") then
				if discordHandle and discordHandle ~= "" then
					messageString = string.format("Ewiger Schlingel %s (%s), %s %s ist mit Level %s in %s gestorben. Schande!",
						name, discordHandle, pronoun, class, level, zone)
				else
					messageString = string.format("Ewiger Schlingel %s, %s %s ist mit Level %s in %s gestorben. Schande!",
						name, pronoun, class, level, zone)
				end
			else
				if discordHandle and discordHandle ~= "" then
					messageString = string.format("%s (%s) %s %s ist mit Level %s in %s gestorben. Schande!",
						name, discordHandle, pronoun, class, level, zone)
				else
					messageString = string.format("%s %s %s ist mit Level %s in %s gestorben. Schande!",
						name, pronoun, class, level, zone)
				end
			end

			-- Store cause and last words before adding to message (for own death log entry)
			local deathCause = nil
			local deathLastWords = nil

			if SchlingelInc.Death.lastAttackSource and SchlingelInc.Death.lastAttackSource ~= "" then
				deathCause = SchlingelInc.Death.lastAttackSource
				messageString = string.format("%s Gestorben an %s", messageString, SchlingelInc.Death.lastAttackSource)
				SchlingelInc.Death.lastAttackSource = ""
			end

			if SchlingelInc.Death.lastChatMessage and SchlingelInc.Death.lastChatMessage ~= "" then
				deathLastWords = SchlingelInc.Death.lastChatMessage
				messageString = string.format('%s. Die letzten Worte: "%s"', messageString, SchlingelInc.Death.lastChatMessage)
				SchlingelInc.Death.lastChatMessage = ""
			end

			-- Enforce cooldown: only send own death every OWN_DEATH_COOLDOWN seconds
			local now = time()
			if (now - lastOwnDeathSendTime) >= SchlingelInc.Constants.COOLDOWNS.DEATH_ANNOUNCEMENT then
				SendChatMessage(messageString, "GUILD")
				CharacterDeaths = CharacterDeaths + 1
				lastOwnDeathSendTime = now

				-- Structured addon message for other addon users (chat parsing stays as fallback)
				-- Format: DEATH|name|class|level|zone|cause
				local addonDeathMsg = table.concat({
					"DEATH",
					name,
					class,
					tostring(level),
					zone,
					deathCause or "",
				}, "|")
				C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, addonDeathMsg, "GUILD")
			end

			-- Process own death immediately (add to log with cause, last words, and handle)
			local deathData = {
				name = name,
				class = class,
				level = level,
				zone = zone,
				cause = deathCause,
				lastWords = deathLastWords,
				discordHandle = discordHandle,
				pronoun = pronoun,
			}
			processDeath(deathData, true)

			-- Clear legacy guild note and broadcast updated profile with new death count
			SchlingelInc:ClearGuildNote()
			C_Timer.After(2, function()
				SchlingelInc.GuildProfiles:Broadcast()
			end)
		end, 0, "DeathTracker")

	-- Chat message tracker for last words
	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_SAY", function(_, msg, sender)
		if sender == playerName or sender:match("^" .. playerName .. "%-") then
			SchlingelInc.Death.lastChatMessage = msg
		end
	end, 0, "LastWordsSay")

	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_GUILD", function(_, msg, sender)
		local senderBase = sender:match("^([^-]+)") or sender

		-- Track last words for own messages
		if senderBase == playerName then
			SchlingelInc.Death.lastChatMessage = msg
		end

		-- Parse death messages from guild chat (for other players' deaths)
		local deathData = parseGuildDeathMessage(msg)
		if deathData then
			-- Only process if it's not our own death (already processed in PLAYER_DEAD)
			if deathData.name ~= playerName then
				processDeath(deathData, false)
			end
		end
	end, 0, "LastWordsGuild")

	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_PARTY", function(_, msg, sender)
		if sender == playerName or sender:match("^" .. playerName .. "%-") then
			SchlingelInc.Death.lastChatMessage = msg
		end
	end, 0, "LastWordsParty")

	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_RAID", function(_, msg, sender)
		if sender == playerName or sender:match("^" .. playerName .. "%-") then
			SchlingelInc.Death.lastChatMessage = msg
		end
	end, 0, "LastWordsRaid")

	-- Combat log for last attack source
	SchlingelInc.EventManager:RegisterHandler("COMBAT_LOG_EVENT_UNFILTERED",
		function()
			local _, subevent, _, _, sourceName, _, _, destGUID = CombatLogGetCurrentEventInfo()

			if destGUID ~= UnitGUID("player") then return end

			-- Track damage events
			if subevent == "SWING_DAMAGE" or subevent == "RANGE_DAMAGE" or
			   subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" then
				SchlingelInc.Death.lastAttackSource = sourceName or "Unbekannt"
			end
		end, 0, "LastAttackTracker")
end

-- Define slash command
SLASH_DEATHSET1 = '/deathset'
SlashCmdList["DEATHSET"] = function(msg)
	local inputValue = tonumber(msg)

	-- If user didn't provide a number, show error message with instructions
	if not inputValue then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Invalid input. Use: /deathset <number>|r")
		return
	end

	-- Validation: Number must be in a reasonable range
	if inputValue < 0 or inputValue > 999999 then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Value must be between 0 and 999999|r")
		return
	end

	CharacterDeaths = inputValue
	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS .. "Death counter set to " .. CharacterDeaths .. "|r")
end
