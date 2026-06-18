SchlingelInc.GuildRecruitment = SchlingelInc.GuildRecruitment or {}
SchlingelInc.GuildRecruitment.inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests or {}

local function GetDefaultOfficerRanks()
    return SchlingelInc.Constants.OFFICER_RANKS
end

local function GetFallbackOfficerNames()
    return SchlingelInc.Constants.FALLBACK_OFFICERS
end

local function GetAuthorizedOfficers()
	if not IsInGuild() then
		SchlingelInc.Debug:Print("Player is not in a guild - cannot retrieve officers")
		return {}
	end

	local officers = {}
	local officerRanks = GetDefaultOfficerRanks()

	for _, rankName in ipairs(officerRanks) do
		local membersWithRank = SchlingelInc.GuildCache:GetMembersByRank(rankName)

		for _, member in ipairs(membersWithRank) do
			if member.isOnline then
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

    local zone = SchlingelInc.GuildRecruitment:GetPlayerZone()

    -- colons and pipes in zone names would break message parsing
    local safeZone = zone:gsub(":", "-"):gsub("|", "-")

    local message = string.format("INVITE_REQUEST:%s:%d:%d:%s", playerName, playerLevel, playerExp, safeZone)

    local guildOfficers = GetFallbackOfficerNames()

    if #guildOfficers == 0 then
        return
    end

    local sentCount = 0
    for _, name in ipairs(guildOfficers) do
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", name)
        sentCount = sentCount + 1
    end
end

local function HandleAddonMessage(message)
    if message:find("^INVITE_REQUEST:") then
        local name, level, xp, zone = message:match("^INVITE_REQUEST:([^:]+):(%d+):(%d+):([^:]+)$")
        if name and level and xp and zone then
            local levelNum = tonumber(level)
            local xpNum = tonumber(xp)

            if not levelNum or levelNum < 1 or levelNum > 60 then
                SchlingelInc.Debug:Print("Invalid level in guild request: " .. tostring(level))
                return
            end

            if not xpNum or xpNum < 0 then
                SchlingelInc.Debug:Print("Invalid XP in guild request: " .. tostring(xp))
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
                zone = zone,
            }
            local displayMessage = string.format("Neue Anfrage von %s (Level %s) aus %s erhalten.",
                name, level, zone)
            SchlingelInc:Print(displayMessage)
            SchlingelInc.GuildInvites:ShowInviteMessage(displayMessage, requestData)
        end
    elseif message:find("^INVITE_SENT:") and CanGuildInvite() then
        SchlingelInc.GuildInvites:HideInviteMessage()
    elseif message:find("^INVITE_DECLINED:") then
        local name = message:match("^INVITE_DECLINED:(.+)$")
        if name and name ~= "" then
            SchlingelInc:Print("Ein Offi hat die Anfrage von " .. name .. " abgelehnt.")
            SchlingelInc.GuildInvites:HideInviteMessage()
        end
    end
end

function SchlingelInc.GuildRecruitment:HandleAcceptRequest(playerName)
    if not playerName then return end

    if CanGuildInvite() then
        SchlingelInc:Print("Versuche " .. playerName .. " in die Gilde einzuladen...")
        C_GuildInfo.Invite(playerName)

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
end

function SchlingelInc.GuildRecruitment:GetPlayerZone()
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        return mapID and C_Map.GetMapInfo(mapID) and C_Map.GetMapInfo(mapID).name or GetZoneText() or "Unknown"
    end
    return GetZoneText() or "Unknown"
end
