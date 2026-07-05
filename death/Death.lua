-- Initialize the Death module in the SchlingelInc namespace
SchlingelInc.Death = {}

-- Initialize CharacterDeaths to avoid nil reference
CharacterDeaths = CharacterDeaths or 0

-- Cooldown for sending own death to guild (seconds)
local lastOwnDeathSendTime = 0

-- Track deaths we've already processed to prevent duplicates
local seenDeaths = {}

local function processDeath(data, isOwnDeath)
	-- Create unique ID to prevent duplicates (bucket to 5s to handle dual-path latency)
	local deathID = data.name .. "-" .. data.level .. "-" .. data.zone .. "-" .. math.floor(time() / 5)
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
	SchlingelInc.Deathlog:AddEntry(deathEntry)

	if isOwnDeath then
		CharacterDeaths = CharacterDeaths + 1
		return
	end

	local pronoun = data.pronoun or "der"
	local messageString
	if data.discordHandle and data.discordHandle ~= "" then
		messageString = string.format("%s (%s) %s %s ist mit Level %s in %s gestorben.",
			data.name, data.discordHandle, pronoun, data.class, data.level, data.zone)
	else
		messageString = string.format("%s %s %s ist mit Level %s in %s gestorben.",
			data.name, pronoun, data.class, data.level, data.zone)
	end

	if SchlingelOptionsDB["deathframe_always_small"] or IsInInstance() then
		SchlingelInc.DeathAnnouncement:ShowSmallDeathMessage(data.name)
	else
		SchlingelInc.DeathAnnouncement:ShowDeathMessage(messageString)
	end
end

-- Public wrapper for use from other modules (e.g. Global.lua addon message handler)
SchlingelInc.Death.ProcessDeath = function(data)
	processDeath(data, false)
end

-- Initializes the Death module and registers events
function SchlingelInc.Death:Initialize()
	SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
		function() wipe(seenDeaths) end, 0, "DeathSeenClear")

	-- PLAYER_DEAD event handler
	SchlingelInc.EventManager:RegisterHandler("PLAYER_DEAD",
		function()
			local name = UnitName("player")
			if not name then return end

			local _, rank = GetGuildInfo("player")
			local class = UnitClass("player")
			local level = UnitLevel("player")
			local sex = UnitSex("player")

			-- local inPvP = SchlingelInc:IsInBattleground() or SchlingelInc:IsInRaid() or SchlingelInc:IsInArena()
			-- if inPvP and level == SchlingelInc.Rules.CurrentCap then
			-- 	return
			-- end

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

			if SchlingelInc.DeathCauseHandler.DeathCause ~= "" then
				messageString = string.format("%s Gestorben an %s", messageString, SchlingelInc.DeathCauseHandler.DeathCause)
			end

			local now = time()
			if (now - lastOwnDeathSendTime) >= SchlingelInc.Constants.COOLDOWNS.DEATH_ANNOUNCEMENT then
				SchlingelInc:SendGuildChatMessage(messageString)
				if SchlingelInc.LastMessageHandler.LastWords ~= "" then
					SchlingelInc:SendGuildChatMessage(string.format('Die letzten Worte: "%s"', SchlingelInc.LastMessageHandler.LastWords))
				end
				lastOwnDeathSendTime = now

				-- Addon message triggers the popup alert for others.
				-- Suppress during raids to avoid wipe spam; chat message still goes through.
				-- Format: DEATH|name|class|level|zone|cause
				if not SchlingelInc:IsInRaid() then
					local addonDeathMsg = table.concat({
						"DEATH",
						name,
						class,
						tostring(level),
						zone,
						SchlingelInc.DeathCauseHandler.DeathCause,
					}, "|")
					C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, addonDeathMsg, "GUILD")
				end
			end

			-- Process own death immediately (add to log with cause, last words, and handle)
			local deathData = {
				name = name,
				class = class,
				level = level,
				zone = zone,
				cause = SchlingelInc.DeathCauseHandler.DeathCause,
				lastWords = SchlingelInc.LastMessageHandler.LastWords,
				discordHandle = discordHandle,
				pronoun = pronoun,
			}
			processDeath(deathData, true)

			SchlingelInc.DeathCauseHandler.DeathCause = ""
			SchlingelInc.LastMessageHandler.LastWords = ""

			C_Timer.After(2, function()
				SchlingelInc.GuildProfiles:Broadcast()
			end)
		end, 0, "DeathTracker")
end