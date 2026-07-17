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

-- Closes a floating dropdown-style list on any click outside it, and whenever
-- ownerFrame (the popup/panel it belongs to) is hidden. listFrame must use a
-- higher strata than "FULLSCREEN_DIALOG" (e.g. "TOOLTIP", the convention used by
-- every dropdown list in this addon) so the catcher never swallows item clicks.
-- excludeFrame (optional) lets clicks on that frame pass through without closing
-- the list — e.g. an EditBox the list is suggesting against, so clicking it to
-- keep typing/reposition the cursor doesn't fight with the outside-click catcher.
function SchlingelInc:RegisterOutsideClickClose(listFrame, ownerFrame, excludeFrame)
    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:EnableMouse(true)
    catcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    catcher:Hide()
    catcher:SetScript("OnClick", function()
        if excludeFrame and excludeFrame:IsMouseOver() then return end
        listFrame:Hide()
    end)

    listFrame:HookScript("OnShow", function() catcher:Show() end)
    listFrame:HookScript("OnHide", function() catcher:Hide() end)
    if ownerFrame then
        ownerFrame:HookScript("OnHide", function() listFrame:Hide() end)
    end
end

-- Closes a Blizzard UIDropDownMenuTemplate dropdown (context menu or combo box) on any
-- click outside it — needed because clicking another same/higher-strata addon frame
-- (e.g. our own panels) eats the click before Blizzard's own auto-close logic ever sees
-- it. onCloseFn (optional) runs extra cleanup whenever the dropdown closes.
function SchlingelInc:RegisterDropdownAutoClose(dropdownFrame, onCloseFn)
    if not DropDownList1 then return end

    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("DIALOG")
    catcher:EnableMouse(true)
    catcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    catcher:Hide()
    catcher:SetScript("OnClick", function() CloseDropDownMenus() end)

    DropDownList1:HookScript("OnShow", function()
        if UIDROPDOWNMENU_OPEN_MENU == dropdownFrame then
            catcher:Show()
        end
    end)
    DropDownList1:HookScript("OnHide", function()
        catcher:Hide()
        if onCloseFn then onCloseFn() end
    end)
end

SchlingelInc.Global = {}

function SchlingelInc.Global:Initialize()
	C_ChatInfo.RegisterAddonMessagePrefix(SchlingelInc.prefix)

	local newestVersionSeen = SchlingelInc.version
	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
		function(_, prefix, message, _, sender)
			if prefix ~= SchlingelInc.prefix then return end
			local incomingVersion = message:match("^VERSION:(.+)$")
			if incomingVersion then
				if sender then
					SchlingelInc.guildMemberVersions[sender] = incomingVersion
				end
				if SchlingelInc.LevelUps and SchlingelInc.LevelUps.OnVersionReceived then
					SchlingelInc.LevelUps.OnVersionReceived()
				end
				if SchlingelInc:CompareVersions(incomingVersion, newestVersionSeen) > 0 then
					newestVersionSeen = incomingVersion
					SchlingelInc:Print("Eine neue Version des Addons wurde gefunden: " ..
						newestVersionSeen .. ". Bitte aktualisiere das Addon!")
				end
			elseif message == "VERSION_REQUEST" and IsInGuild() then
				ChatThrottleLib:SendAddonMessage("BULK", SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD", nil, "SchlingelInc-Version")
			elseif message == "RULES_UPDATE" then
				C_Timer.After(2, function()
					SchlingelInc.Rules:LoadFromGuildInfo()
				end)
			end
		end, 0, "VersionChecker")

	if IsInGuild() then
		ChatThrottleLib:SendAddonMessage("BULK", SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD", nil, "SchlingelInc-Version")
		ChatThrottleLib:SendAddonMessage("BULK", SchlingelInc.prefix, "VERSION_REQUEST", "GUILD", nil, "SchlingelInc-Version")
	end
    C_GuildInfo.GuildRoster()
end

function SchlingelInc:Print(message)
    print(SchlingelInc.colorCode .. "[" .. SchlingelInc.name .. "]|r " .. message)
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
function SchlingelInc:WriteGuildInfo(mail, ah, trade, group, blockedTrader, cap)
    if not CanGuildInvite() then return false end
    local mailRule = tonumber(mail)
    if mailRule ~= 0 and mailRule ~= 1 and mailRule ~= 2 then
        mailRule = mail and 1 or 0
    end
    if cap == nil and (type(blockedTrader) == "number" or tonumber(blockedTrader) ~= nil) then
        cap = tonumber(blockedTrader)
        blockedTrader = true
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
    local block = string.format("%s:%d%d%d%d%d",
        SchlingelInc.Constants.RULES_KEY,
        mailRule,
        ah    and 1 or 0,
        trade and 1 or 0,
        group and 1 or 0,
        blockedTrader and 1 or 0)
    if cap and cap > 0 then
        block = block .. string.format(" %s:%d", SchlingelInc.Constants.RULES_CAP_KEY, cap)
    end
    local newText = (current ~= "") and (current .. "\n\n" .. sep .. "\n" .. block) or (sep .. "\n" .. block)
    SetGuildInfoText(newText)
    SchlingelInc:Print("Gildeninfo mit neuen Regeln aktualisiert.")
    SchlingelInc.Rules:LoadFromGuildInfo()
    ChatThrottleLib:SendAddonMessage("BULK", SchlingelInc.prefix, "RULES_UPDATE", "GUILD", nil, "SchlingelInc-Rules")
    return true
end

function SchlingelInc:SaveFramePosition(frame, dbKey)
    SchlingelOptionsDB = SchlingelOptionsDB or {}
    local point, _, relPoint, x, y = frame:GetPoint()
    if not point then return end
    relPoint = relPoint or point
    SchlingelOptionsDB[dbKey] = { point = point, relPoint = relPoint, x = x, y = y }
end

function SchlingelInc:RestoreFramePosition(frame, dbKey, defaultPoint, defaultX, defaultY)
    local p = SchlingelOptionsDB and SchlingelOptionsDB[dbKey]
    if p and p.point then
        local relPoint = p.relPoint or p.point
        frame:ClearAllPoints()
        frame:SetPoint(p.point, UIParent, relPoint, tonumber(p.x) or 0, tonumber(p.y) or 0)
    else
        frame:SetPoint(defaultPoint or "CENTER", UIParent, defaultPoint or "CENTER", defaultX or 0, defaultY or 0)
    end
end

-- Uses the Blizzard API Ambiguate to strip the realm suffix (e.g. "Player-Realm" -> "Player").
function SchlingelInc:RemoveRealmFromName(fullName)
    return Ambiguate(fullName, "short")
end

-- Sends a GUILD chat message, hard-truncated to stay under WoW's ~255 byte
-- SendChatMessage limit (which errors instead of truncating when exceeded).
-- Wrapped in pcall so any remaining edge case degrades to "message not sent"
-- rather than silently aborting the rest of the calling event handler.
function SchlingelInc:SendGuildChatMessage(text)
    if not text then return end
    pcall(function()
        ChatThrottleLib:SendChatMessage("NORMAL", SchlingelInc.prefix, text:sub(1, 250), "GUILD")
    end)
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
