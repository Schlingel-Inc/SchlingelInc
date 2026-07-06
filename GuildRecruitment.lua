SchlingelInc.GuildRecruitment = SchlingelInc.GuildRecruitment or {}
SchlingelInc.GuildRecruitment.inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests or {}

local pendingOfficerFilter = {}

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, message)
    for name in pairs(pendingOfficerFilter) do
        if message == ERR_CHAT_PLAYER_NOT_FOUND_S:format(name) then
            return true
        end
    end
    return false
end)

local function GetDefaultOfficerRanks()
    return SchlingelInc.Constants.OFFICER_RANKS
end

local function GetFallbackOfficerNames()
    return SchlingelInc.Constants.FALLBACK_OFFICERS
end

-- /who-based online detection, usable even by players who aren't guild
-- members yet (GetGuildRosterInfo/CanGuildInvite require membership).
-- Note: /who caps results at 50 entries guild-wide, not per-officer - if more
-- than 50 guild members are online at once (e.g. raid times), an online
-- officer could be left out of the results. Accepted tradeoff for simplicity.
local WHO_QUERY_COOLDOWN = 5
local lastWhoQueryTime = 0
local onlineOfficersFromWho = {}

-- SendWho pops open the default Blizzard Who/FriendsFrame window as a side
-- effect; hide it back up since this is meant to be a silent background check.
local function HideWhoWindow()
    if FriendsFrame and FriendsFrame:IsShown() then
        HideUIPanel(FriendsFrame)
    end
end

function SchlingelInc.GuildRecruitment:CheckOfficersOnline()
    local now = time()
    if (now - lastWhoQueryTime) < WHO_QUERY_COOLDOWN then return end
    lastWhoQueryTime = now
    C_FriendList.SendWho(string.format('g-"%s"', SchlingelInc.Constants.GUILD_NAME))
    HideWhoWindow()
end

-- Officers detected online via the last /who query, or an empty table if
-- none were found yet (callers should fall back to GetFallbackOfficerNames).
function SchlingelInc.GuildRecruitment:GetOnlineOfficers()
    return onlineOfficersFromWho
end

local function GetRunesKnown()
    local engraving = C_Engraving
    if type(engraving) ~= "table" or type(engraving.GetNumRunesKnown) ~= "function" then
        return nil
    end
    local ok, count = pcall(engraving.GetNumRunesKnown)
    if not ok then return nil end
    return tonumber(count)
end

local function GetAuthorizedOfficers()
	if not IsInGuild() then
		SchlingelInc.Debug:Print("Player is not in a guild - cannot retrieve officers")
		return {}
	end

	local officers = {}
	local officerRanks = GetDefaultOfficerRanks()
	local self = UnitName("player")

	for _, rankName in ipairs(officerRanks) do
		local membersWithRank = SchlingelInc.GuildCache:GetMembersByRank(rankName)

		for _, member in ipairs(membersWithRank) do
			if member.isOnline and member.name ~= self then
				table.insert(officers, member.name)
			end
		end
	end

	SchlingelInc.Debug:Print(string.format(
		"Found online officers with invite permissions: %d", #officers
	))

	return officers
end

function SchlingelInc.GuildRecruitment:SendGuildRequest()
    local playerName = UnitName("player")
    local playerLevel = UnitLevel("player")
    local playerExp = UnitXP("player")
    local playerGold = GetMoney()
    local runesKnown = GetRunesKnown() or 0

    local zone = SchlingelInc.GuildRecruitment:GetPlayerZone()

    -- colons and pipes in zone names would break message parsing
    local safeZone = zone:gsub(":", "-"):gsub("|", "-")

    if playerLevel > 1 or playerExp > 0 or playerGold > 0 then
        SchlingelInc.Popup:Show({
        title = "Anfrage abgebrochen",
        message = "Neue Charaktere müssen Level 1 mit 0% XP ohne Gold sein. Bitte lies dir die Regeln im Discord durch."
        })
        SchlingelInc:Print("Anfrage abgebrochen!")
        return
    end

    local message = string.format("INVITE_REQUEST:%s:%d:%d:%d:%d:%s", playerName, playerLevel, playerExp, playerGold, runesKnown, safeZone)

    local guildOfficers = SchlingelInc.GuildRecruitment:GetOnlineOfficers()
    if #guildOfficers == 0 then
        guildOfficers = GetFallbackOfficerNames()
    end

    if #guildOfficers == 0 then
        return
    end

    wipe(pendingOfficerFilter)
    for _, name in ipairs(guildOfficers) do
        pendingOfficerFilter[name] = true
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", name)
    end
    SchlingelInc:Print("Anfrage gesendet...")
    C_Timer.After(3, function() wipe(pendingOfficerFilter) end)
end

local function HandleAddonMessage(message)
    if message:find("^INVITE_REQUEST:") then
        local name, level, xp, gold, runes, zone = message:match("^INVITE_REQUEST:([^:]+):(%d+):(%d+):(%d+):(%d+):([^:]+)$")
        if not name then
            -- Legacy format without runes.
            name, level, xp, gold, zone = message:match("^INVITE_REQUEST:([^:]+):(%d+):(%d+):(%d+):([^:]+)$")
        end

        if name and level and xp and gold and zone then
            local levelNum = tonumber(level)
            local xpNum = tonumber(xp)
            local goldNum = tonumber(gold)
            local runesNum = tonumber(runes)

            if not levelNum or levelNum < 1 or levelNum > 60 then
                SchlingelInc.Debug:Print("Invalid level in guild request: " .. tostring(level))
                return
            end

            if not xpNum or xpNum < 0 then
                SchlingelInc.Debug:Print("Invalid XP in guild request: " .. tostring(xp))
                return
            end

            if not goldNum or goldNum < 0 then
                SchlingelInc.Debug:Print("Invalid gold in guild request: " .. tostring(gold))
                return
            end

            if runesNum ~= nil and runesNum < 0 then
                SchlingelInc.Debug:Print("Invalid rune count in guild request: " .. tostring(runes))
                return
            end

            if name == "" or zone == "" then
                SchlingelInc.Debug:Print("Empty fields received in guild request")
                return
            end

            local requestData = {
                name = name,
                level = level,
                xp = xpNum,
                gold = goldNum,
                runesKnown = runesNum,
                zone = zone,
            }
            local isNew = not SchlingelInc.GuildRecruitment.inviteRequests[name]
            SchlingelInc.GuildRecruitment.inviteRequests[name] = requestData
            if isNew then
                SchlingelInc:Print(string.format("Neue Anfrage von %s (Level %s) aus %s erhalten.", name, level, zone))
            end
            SchlingelInc.GuildInvites:NotifyPendingInvites()
            SchlingelInc.OfficerPanel:RefreshInvites()
        end
    elseif message:find("^INVITE_SENT:") and CanGuildInvite() then
        local name = message:match("^INVITE_SENT:(.+)$")
        if name and name ~= "" then
            SchlingelInc.GuildRecruitment.inviteRequests[name] = nil
            SchlingelInc.OfficerPanel:RefreshInvites()
            SchlingelInc.GuildInvites:NotifyPendingInvites()
        end
    elseif message:find("^INVITE_DECLINED:") then
        local name = message:match("^INVITE_DECLINED:(.+)$")
        if name and name ~= "" then
            SchlingelInc:Print("Ein Offi hat die Anfrage von " .. name .. " abgelehnt.")
            SchlingelInc.GuildRecruitment.inviteRequests[name] = nil
            SchlingelInc.OfficerPanel:RefreshInvites()
            SchlingelInc.GuildInvites:NotifyPendingInvites()
        end
    end
end

function SchlingelInc.GuildRecruitment:HandleAcceptRequest(playerName)
    if not playerName then return end

    if CanGuildInvite() then
        SchlingelInc:Print("Versuche " .. playerName .. " in die Gilde einzuladen...")
        C_GuildInfo.Invite(playerName)
        SchlingelInc.GuildRecruitment.inviteRequests[playerName] = nil
        SchlingelInc.OfficerPanel:RefreshInvites()

        local guildOfficers = GetAuthorizedOfficers()
        for _, name in ipairs(guildOfficers) do
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "INVITE_SENT:" .. playerName, "WHISPER", name)
        end
    end
end

function SchlingelInc.GuildRecruitment:HandleDeclineRequest(playerName)
    if not playerName then return end

    local guildOfficers = GetAuthorizedOfficers()
    for _, name in ipairs(guildOfficers) do
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "INVITE_DECLINED:" .. playerName, "WHISPER", name)
    end

    SchlingelInc.GuildRecruitment.inviteRequests[playerName] = nil
    SchlingelInc.OfficerPanel:RefreshInvites()
    SchlingelInc:Print("Anfrage von " .. playerName .. " wurde abgelehnt.")
end

function SchlingelInc.GuildRecruitment:Initialize()
	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
		function(_, prefix, message, _, sender)
			if prefix == SchlingelInc.prefix then
				if message:find("^INVITE_REQUEST:") then
					HandleAddonMessage(message)
				elseif (message:find("INVITE_SENT") or message:find("INVITE_DECLINED"))
					and SchlingelInc:IsValidGuildSender(sender) then
					HandleAddonMessage(message)
				end
			end
		end, 0, "GuildInviteHandler")

	-- Priority 10 so this runs before the join prompt's hint-refresh handler
	-- (registered at priority 0), which reads onlineOfficersFromWho.
	SchlingelInc.EventManager:RegisterHandler("WHO_LIST_UPDATE", function()
		HideWhoWindow()
		wipe(onlineOfficersFromWho)
		for i = 1, C_FriendList.GetNumWhoResults() do
			local info = C_FriendList.GetWhoInfo(i)
			local name = info and info.fullName and SchlingelInc:RemoveRealmFromName(info.fullName)
			if name then
				for _, officer in ipairs(GetFallbackOfficerNames()) do
					if name == officer then
						table.insert(onlineOfficersFromWho, name)
						break
					end
				end
			end
		end
	end, 10, "WhoOfficerCheck")
end

function SchlingelInc.GuildRecruitment:GetPlayerZone()
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        return mapID and C_Map.GetMapInfo(mapID) and C_Map.GetMapInfo(mapID).name or GetZoneText() or "Unknown"
    end
    return GetZoneText() or "Unknown"
end
