SchlingelInc = SchlingelInc or {}

-- Account-wide guild configuration. WoW has already loaded the SavedVariable
-- by the time this file runs, so the `or {}` guard only fires on a fresh installation.
SchlingelGuildDB = SchlingelGuildDB or {}

SchlingelInc.name = "SchlingelInc"
SchlingelInc.prefix = "SchlingelInc"
SchlingelInc.colorCode = "|cFFF48CBA"
SchlingelInc.version = C_AddOns.GetAddOnMetadata("SchlingelInc", "Version") or "Unknown"

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

function SchlingelInc:RegisterFrameForEscape(frame)
    if not frame or not frame.GetName or not UISpecialFrames then
        return
    end

    local frameName = frame:GetName()
    if not frameName or frameName == "" then
        return
    end

    for _, registeredName in ipairs(UISpecialFrames) do
        if registeredName == frameName then
            return
        end
    end

    table.insert(UISpecialFrames, frameName)
end

SchlingelInc.lastPvPAlert = {}

SchlingelInc.Global = {}

function SchlingelInc.Global:Initialize()
	C_ChatInfo.RegisterAddonMessagePrefix(SchlingelInc.prefix)

    local pendingDeathMessages = {}
    local pendingMilestoneMessages = {}

    local function ProcessLevelUpMessage(message, sender)
        local levelName, levelNum = message:match("^LEVELUP:(.+):(%d+)$")
        if not levelName or not levelNum then
            return false
        end

        local senderShort = SchlingelInc:RemoveRealmFromName(sender)
        if senderShort == UnitName("player") then
            return true
        end

        SchlingelInc.LevelUpAnnouncement:ShowMessage(levelName, tonumber(levelNum))
        return true
    end

    local function ProcessCapMessage(message, sender)
        local capName, capNum = message:match("^CAP:(.+):(%d+)$")
        if not capName or not capNum then
            return false
        end

        local senderShort = SchlingelInc:RemoveRealmFromName(sender)
        if senderShort == UnitName("player") then
            return true
        end

        SchlingelInc.LevelUpAnnouncement:ShowCap(capName, tonumber(capNum))
        return true
    end

    local function HandleMilestoneAddonMessage(message, sender)
        local isLevelUp = message:match("^LEVELUP:") ~= nil
        local isCap = message:match("^CAP:") ~= nil
        if not isLevelUp and not isCap then
            return false
        end

        if SchlingelInc:IsValidGuildSender(sender) then
            if isLevelUp then
                return ProcessLevelUpMessage(message, sender)
            end
            return ProcessCapMessage(message, sender)
        end

        table.insert(pendingMilestoneMessages, {
            message = message,
            sender = sender,
            receivedAt = time(),
        })
        SchlingelInc.GuildCache:RequestUpdate()
        return true
    end

    local function ProcessStructuredDeathMessage(message, sender)
        local parts = SchlingelInc:ParsePipeMessage(message)
        if #parts < 5 then
            return false
        end

        local senderShort = SchlingelInc:RemoveRealmFromName(sender)
        if senderShort == UnitName("player") then
            return true
        end

        local deathLevel = tonumber(parts[4])
        if not deathLevel then
            return false
        end

        local deathData = {
            name    = parts[2],
            class   = parts[3],
            level   = deathLevel,
            zone    = parts[5],
            cause   = (parts[6] and parts[6] ~= "") and parts[6] or nil,
            pronoun = SchlingelInc.Constants.PRONOUNS[2] or "der",
        }

        local profile = SchlingelGuildProfileCache and SchlingelGuildProfileCache[senderShort]
        if profile then
            deathData.discordHandle = profile.discord
            profile.deaths = (profile.deaths or 0) + 1
        end

        SchlingelInc.Death.ProcessDeath(deathData)
        return true
    end

    local function HandleDeathAddonMessage(message, sender)
        if not message:match("^DEATH|") then
            return false
        end

        if SchlingelInc:IsValidGuildSender(sender) then
            return ProcessStructuredDeathMessage(message, sender)
        end

        table.insert(pendingDeathMessages, {
            message = message,
            sender = sender,
            receivedAt = time(),
        })
        SchlingelInc.GuildCache:RequestUpdate()
        return true
    end

	SchlingelInc.EventManager:RegisterHandler("PLAYER_TARGET_CHANGED",
		function()
			if SchlingelOptionsDB["pvp_alert"] == false then
				return
			end
			if not SchlingelInc:IsInBattleground() then
				SchlingelInc:CheckTargetPvP()
			end
		end, 0, "PvPTargetChecker")

	local newestVersionSeen = SchlingelInc.version
	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
		function(_, prefix, message, _, sender)
			if prefix == SchlingelInc.prefix then
				local incomingVersion = message:match("^VERSION:(.+)$")
				if incomingVersion then
					if sender then
						SchlingelInc.guildMemberVersions[sender] = incomingVersion
					end

					if SchlingelInc:CompareVersions(incomingVersion, newestVersionSeen) > 0 then
						newestVersionSeen = incomingVersion
						SchlingelInc:Print("Eine neue Version des Addons wurde gefunden: " ..
							newestVersionSeen .. ". Bitte aktualisiere das Addon!")
					end
				elseif message == "VERSION_REQUEST" and IsInGuild() then
					C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD")
				else
                    HandleMilestoneAddonMessage(message, sender)

                    HandleDeathAddonMessage(message, sender)

					SchlingelInc.GuildProfiles:HandleMessage(sender, message)
				end
			end
		end, 0, "VersionChecker")

    SchlingelInc.EventManager:RegisterHandler("GUILD_ROSTER_UPDATE",
        function()
            if #pendingDeathMessages > 0 then
                for i = #pendingDeathMessages, 1, -1 do
                    local pending = pendingDeathMessages[i]
                    if not pending or (time() - pending.receivedAt) > 30 then
                        table.remove(pendingDeathMessages, i)
                    elseif SchlingelInc:IsValidGuildSender(pending.sender) then
                        ProcessStructuredDeathMessage(pending.message, pending.sender)
                        table.remove(pendingDeathMessages, i)
                    end
                end
            end

            if #pendingMilestoneMessages > 0 then
                for i = #pendingMilestoneMessages, 1, -1 do
                    local pending = pendingMilestoneMessages[i]
                    if not pending or (time() - pending.receivedAt) > 30 then
                        table.remove(pendingMilestoneMessages, i)
                    elseif SchlingelInc:IsValidGuildSender(pending.sender) then
                        if pending.message:match("^LEVELUP:") then
                            ProcessLevelUpMessage(pending.message, pending.sender)
                        elseif pending.message:match("^CAP:") then
                            ProcessCapMessage(pending.message, pending.sender)
                        end
                        table.remove(pendingMilestoneMessages, i)
                    end
                end
            end
        end, 0, "DeferredDeathAddonMessageReplay")

	if IsInGuild() then
		C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD")
		C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION_REQUEST", "GUILD")
	end
    C_GuildInfo.GuildRoster()
end

function SchlingelInc:Print(message)
    print(SchlingelInc.colorCode .. "[" .. SchlingelInc.name .. "]|r " .. message)
end

function SchlingelInc:IsInBattleground()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == SchlingelInc.Constants.INSTANCE_TYPES.PVP
end

function SchlingelInc:IsInRaid()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == SchlingelInc.Constants.INSTANCE_TYPES.RAID
end

function SchlingelInc:IsInArena()
    return false -- arenas don't exist in SoD
end

function SchlingelInc:ParseVersion(v)
    local major, minor, patch = string.match(v, "(%d+)%.(%d+)%.?(%d*)")
    return tonumber(major or 0), tonumber(minor or 0), tonumber(patch or 0)
end

-- Returns >0 if version1 > version2; <0 if version1 < version2; 0 if equal.
function SchlingelInc:CompareVersions(version1, version2)
    local major1, minor1, patch1 = SchlingelInc:ParseVersion(version1)
    local major2, minor2, patch2 = SchlingelInc:ParseVersion(version2)

    if major1 ~= major2 then return major1 - major2 end
    if minor1 ~= minor2 then return minor1 - minor2 end
    return patch1 - patch2
end

-- Stores addon versions of guild members (sender name -> version).
SchlingelInc.guildMemberVersions = {}

local function GuildChatVersionFilter(_, _, msg, sender, ...)
    local modifiedMessage = msg

    if SchlingelOptionsDB and SchlingelOptionsDB.show_discord_handle == true then
        local notePrefix = SchlingelInc:GetGuildPublicNotePrefix(sender)
        if notePrefix ~= "" then
            modifiedMessage = notePrefix .. modifiedMessage
        end
    end

    if SchlingelOptionsDB and SchlingelOptionsDB.show_version == true then
        local version = SchlingelInc.guildMemberVersions[sender]
        if version then
            modifiedMessage = SchlingelInc.colorCode .. "[" .. version .. "]|r " .. modifiedMessage
        end
    end

    return false, modifiedMessage, sender, ...
end

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

function SchlingelInc:ParsePipeMessage(message)
    local parts = {}
    for part in (message .. "|"):gmatch("([^|]*)|") do
        table.insert(parts, part)
    end
    return parts
end

-- Encodes and writes guild rules into the SchlingelInc block of guild info text.
-- Returns true on success, false if the player lacks officer permission.
function SchlingelInc:WriteGuildInfo(mail, ah, trade, group, blockedTrader, progressBroadcast, cap)
    if not CanGuildRemove() then return false end
    local mailRule = tonumber(mail)
    if mailRule ~= 0 and mailRule ~= 1 and mailRule ~= 2 then
        mailRule = mail and 1 or 0
    end
    if cap == nil and (type(progressBroadcast) == "number" or tonumber(progressBroadcast) ~= nil) then
        cap = tonumber(progressBroadcast)
        progressBroadcast = true
    elseif cap == nil and (type(blockedTrader) == "number" or tonumber(blockedTrader) ~= nil) then
        cap = tonumber(blockedTrader)
        blockedTrader = true
    end
    if progressBroadcast == nil then
        progressBroadcast = true
    end
    local sep = SchlingelInc.Constants.GUILD_INFO_SEPARATOR
    local current = GetGuildInfoText() or ""
    local sepPos = current:find("\n\n" .. sep, 1, true)
                or current:find("\n" .. sep, 1, true)
                or current:find(sep, 1, true)
    if sepPos then
        current = current:sub(1, sepPos - 1)
    else
        current = current:gsub(SchlingelInc.Constants.RULES_KEY .. ":%d+", "")
        current = current:gsub(SchlingelInc.Constants.RULES_CAP_KEY .. ":%d+", "")
    end
    current = current:gsub("%s+$", "")
    local block = string.format("%s:%d%d%d%d%d%d",
        SchlingelInc.Constants.RULES_KEY,
        mailRule,
        ah    and 1 or 0,
        trade and 1 or 0,
        group and 1 or 0,
        blockedTrader and 1 or 0,
        progressBroadcast and 1 or 0)
    if cap and cap > 0 then
        block = block .. string.format(" %s:%d", SchlingelInc.Constants.RULES_CAP_KEY, cap)
    end
    local newText = (current ~= "") and (current .. "\n\n" .. sep .. "\n" .. block) or (sep .. "\n" .. block)
    SetGuildInfoText(newText)
    SchlingelInc:Print("Gildeninfo mit neuen Regeln aktualisiert.")
    SchlingelInc.Rules:LoadFromGuildInfo()
    return true
end

function SchlingelInc:SaveFramePosition(frame, dbKey)
    SchlingelOptionsDB = SchlingelOptionsDB or {}
    local point, _, relPoint, x, y = frame:GetPoint()
    if not point then return end
    SchlingelOptionsDB[dbKey] = { point = point, relPoint = relPoint, x = x, y = y }
end

function SchlingelInc:RestoreFramePosition(frame, dbKey, defaultPoint, defaultX, defaultY)
    local p = SchlingelOptionsDB and SchlingelOptionsDB[dbKey]
    if p then
        frame:ClearAllPoints()
        frame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else
        frame:SetPoint(defaultPoint or "CENTER", UIParent, defaultPoint or "CENTER", defaultX or 0, defaultY or 0)
    end
end

-- Uses the Blizzard API Ambiguate to strip the realm suffix (e.g. "Player-Realm" -> "Player").
function SchlingelInc:RemoveRealmFromName(fullName)
    return Ambiguate(fullName, "short")
end

-- Sanitizes text to prevent UI injection via escape codes.
function SchlingelInc:SanitizeText(text)
    if not text or type(text) ~= "string" then
        return text
    end
    text = text:gsub("|T[^|]*|t", "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    text = text:gsub("|H[^|]*|h", "")
    text = text:gsub("|h", "")
    return text
end

function SchlingelInc:GetGuildPublicNotePrefix(sender)
    if not sender then return "" end
    local shortName = SchlingelInc:RemoveRealmFromName(sender)
    local profile = SchlingelGuildProfileCache and SchlingelGuildProfileCache[shortName]
    if profile and profile.discord and profile.discord ~= "" then
        return SchlingelInc.colorCode .. "[" .. SchlingelInc:SanitizeText(profile.discord) .. "]|r "
    end
    return ""
end

-- Uses GuildCache for fast lookup to prevent spoofed addon messages.
function SchlingelInc:IsValidGuildSender(sender)
    if not sender then return false end
    local shortName = self:RemoveRealmFromName(sender)
    return SchlingelInc.GuildCache:IsGuildMember(shortName)
end
