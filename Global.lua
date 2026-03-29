-- Global table for the addon
SchlingelInc = {}

-- Addon name
SchlingelInc.name = "SchlingelInc"

-- Chat message prefix
-- This prefix is used to identify addon-internal messages.
SchlingelInc.prefix = "SchlingelInc"

-- Color code for chat text
-- Determines the color in which addon messages are displayed in chat.
SchlingelInc.colorCode = "|cFFF48CBA"

-- Version from TOC file
-- Loads the addon version from the .toc file. If not available, "Unknown" is used.
SchlingelInc.version = C_AddOns.GetAddOnMetadata("SchlingelInc", "Version") or "Unknown"

-- Playtime variables are updated in Main.lua via TIME_PLAYED_MSG event
-- and displayed in SchlingelInterface.lua.
SchlingelInc.GameTimeTotal = 0
SchlingelInc.GameTimePerLevel = 0

-- Plays either a standard WoW sound or a Torro custom sound file based on the sound_pack setting.
-- torroFile may be a single path string or a table of paths (one is picked at random).
function SchlingelInc:PlayAnnouncementSound(standardId, torroFile)
	if SchlingelOptionsDB["sound_pack"] == "torro" and torroFile then
		local file = torroFile
		if type(torroFile) == "table" then
			file = torroFile[math.random(#torroFile)]
		end
		PlaySoundFile(file, SchlingelOptionsDB["sound_channel"])
	else
		PlaySound(standardId, SchlingelOptionsDB["sound_channel"])
	end
end

function SchlingelInc:CountTable(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- Stores the timestamp of the last PvP warning for each player.
SchlingelInc.lastPvPAlert = {}

-- Global module initialization
SchlingelInc.Global = {}

function SchlingelInc.Global:Initialize()
	-- Register addon message prefix
	C_ChatInfo.RegisterAddonMessagePrefix(SchlingelInc.prefix)

	-- PLAYER_TARGET_CHANGED for PvP warnings
	SchlingelInc.EventManager:RegisterHandler("PLAYER_TARGET_CHANGED",
		function()
			if SchlingelOptionsDB["pvp_alert"] == false then
				return
			end
			if not SchlingelInc:IsInBattleground() then
				SchlingelInc:CheckTargetPvP()
			end
		end, 0, "PvPTargetChecker")

	-- Version checking handler
	local newestVersionSeen = SchlingelInc.version
	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
		function(_, prefix, message, _, sender)
			if prefix == SchlingelInc.prefix then
				local incomingVersion = message:match("^VERSION:(.+)$")
				if incomingVersion then
					-- Store version of guild member
					if sender then
						SchlingelInc.guildMemberVersions[sender] = incomingVersion
					end

					-- Check if incoming version is newer than the currently known newest version
					if SchlingelInc:CompareVersions(incomingVersion, newestVersionSeen) > 0 then
						newestVersionSeen = incomingVersion
						SchlingelInc:Print("Eine neue Version des Addons wurde gefunden: " ..
							newestVersionSeen .. ". Bitte aktualisiere das Addon!")
					end
				elseif message == "VERSION_REQUEST" and IsInGuild() then
					-- Respond to version requests from already-online guild members
					C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD")
				else
					local levelName, levelNum = message:match("^LEVELUP:(.+):(%d+)$")
					if levelName and levelNum and SchlingelInc:IsValidGuildSender(sender) then
						SchlingelInc.LevelUpAnnouncement:ShowMessage(levelName, tonumber(levelNum))
					end

					local capName, capNum = message:match("^CAP:(.+):(%d+)$")
					if capName and capNum and SchlingelInc:IsValidGuildSender(sender) then
						SchlingelInc.LevelUpAnnouncement:ShowCap(capName, tonumber(capNum))
					end

					-- Structured death message (guild chat parsing remains as fallback)
					if message:match("^DEATH|") and SchlingelInc:IsValidGuildSender(sender) then
						local parts = {}
						for part in (message .. "|"):gmatch("([^|]*)|?") do
							table.insert(parts, part)
						end
						if #parts >= 5 then
							local senderShort = SchlingelInc:RemoveRealmFromName(sender)
							if senderShort ~= UnitName("player") then
								local deathData = {
									name    = parts[2],
									class   = parts[3],
									level   = tonumber(parts[4]),
									zone    = parts[5],
									cause   = (parts[6] and parts[6] ~= "") and parts[6] or nil,
									pronoun = SchlingelInc.Constants.PRONOUNS[2] or "der",
								}
								local profile = SchlingelGuildProfileCache and
									SchlingelGuildProfileCache[senderShort]
								if profile then
									deathData.discordHandle = profile.discord
									profile.deaths = (profile.deaths or 0) + 1
								end
								SchlingelInc.Death.ProcessDeath(deathData)
							end
						end
					end

					-- Profile sync messages
					SchlingelInc.GuildProfiles:HandleMessage(sender, message)
				end
			end
		end, 0, "VersionChecker")

	-- Broadcast own version and request versions from already-online guild members
	if IsInGuild() then
		C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD")
		C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION_REQUEST", "GUILD")
	end
    C_GuildInfo.GuildRoster() -- Fetch guild roster to build cache.
end

-- Outputs a formatted message in chat.
function SchlingelInc:Print(message)
    print(SchlingelInc.colorCode .. "[" .. SchlingelInc.name .. "]|r " .. message)
end

-- Checks if the player is in a battleground.
function SchlingelInc:IsInBattleground()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == SchlingelInc.Constants.INSTANCE_TYPES.PVP
end

function SchlingelInc:IsInRaid()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == SchlingelInc.Constants.INSTANCE_TYPES.RAID
end

function SchlingelInc:IsInArena()
    local isArena, _ = IsActiveBattlefieldArena()
    return isArena
end

function SchlingelInc:ParseVersion(v)
    local major, minor, patch = string.match(v, "(%d+)%.(%d+)%.?(%d*)")
    return tonumber(major or 0), tonumber(minor or 0), tonumber(patch or 0)
end

-- Compares two version numbers (e.g. "1.2.3" with "1.3.0").
-- Returns >0 if version1 > version2; <0 if version1 < version2; 0 if equal.
function SchlingelInc:CompareVersions(version1, version2)
    local major1, minor1, patch1 = SchlingelInc:ParseVersion(version1)
    local major2, minor2, patch2 = SchlingelInc:ParseVersion(version2)

    if major1 ~= major2 then return major1 - major2 end -- Compare major version.
    if minor1 ~= minor2 then return minor1 - minor2 end -- Compare minor version.
    return patch1 - patch2                              -- Compare patch version.
end


-- Stores addon versions of guild members (sender name -> version).
SchlingelInc.guildMemberVersions = {}

-- Chat filter function (defined once, reused if already registered)
local function GuildChatVersionFilter(_, _, msg, sender, ...)
    local modifiedMessage = msg

    -- Prepend guild public note (Gildeninfo) only if the option is explicitly enabled
    if SchlingelOptionsDB and SchlingelOptionsDB.show_discord_handle == true then
        local notePrefix = SchlingelInc:GetGuildPublicNotePrefix(sender)
        if notePrefix ~= "" then
            modifiedMessage = notePrefix .. modifiedMessage
        end
    end

    -- Prepend stored addon version only if the option is explicitly enabled
    if SchlingelOptionsDB and SchlingelOptionsDB.show_version == true then
        local version = SchlingelInc.guildMemberVersions[sender]
        if version then
            modifiedMessage = SchlingelInc.colorCode .. "[" .. version .. "]|r " .. modifiedMessage
        end
    end

    return false, modifiedMessage, sender, ...
end

-- Add filter for multiple chat message events (only once).
if not SchlingelInc.guildChatFilterRegistered then
    local events = {
        "CHAT_MSG_GUILD",
        "CHAT_MSG_OFFICER",
        "CHAT_MSG_SAY",
        "CHAT_MSG_YELL",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_INSTANCE_CHAT",
        "CHAT_MSG_INSTANCE_CHAT_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_CHANNEL",
    }
    for _, ev in ipairs(events) do
        ChatFrame_AddMessageEventFilter(ev, GuildChatVersionFilter)
    end
    SchlingelInc.guildChatFilterRegistered = true
end

-- Removes the realm name from a full player name (e.g. "Player-Realm" -> "Player").
-- Uses the Blizzard API function Ambiguate.
function SchlingelInc:RemoveRealmFromName(fullName)
    return Ambiguate(fullName, "short")
end

-- Sanitizes text to prevent UI injection via escape codes
-- Removes texture, color, and hyperlink escape sequences
function SchlingelInc:SanitizeText(text)
    if not text or type(text) ~= "string" then
        return text
    end
    -- Remove texture escape sequences |Tpath:height:width:...|t
    text = text:gsub("|T[^|]*|t", "")
    -- Remove color escape sequences |cFFFFFFFF...|r
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    -- Remove hyperlink escape sequences |Htype:data|h...|h
    text = text:gsub("|H[^|]*|h", "")
    text = text:gsub("|h", "")
    return text
end

-- Returns a formatted prefix containing the Discord handle for a sender.
function SchlingelInc:GetGuildPublicNotePrefix(sender)
    if not sender then return "" end
    local shortName = SchlingelInc:RemoveRealmFromName(sender)
    local profile = SchlingelGuildProfileCache and SchlingelGuildProfileCache[shortName]
    if profile and profile.discord and profile.discord ~= "" then
        return SchlingelInc.colorCode .. "[" .. SchlingelInc:SanitizeText(profile.discord) .. "]|r "
    end
    return ""
end

-- Validates that an addon message sender is a guild member
-- Uses GuildCache for fast lookup to prevent spoofed messages
function SchlingelInc:IsValidGuildSender(sender)
    if not sender then return false end
    local shortName = self:RemoveRealmFromName(sender)
    return SchlingelInc.GuildCache:IsGuildMember(shortName)
end
