-- Initialize the namespace for the guild recruitment module
SchlingelInc.GuildRecruitment = SchlingelInc.GuildRecruitment or {}
SchlingelInc.GuildRecruitment.inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests or {}

-- Returns a list of all officers who have invite permissions
-- Based on ranks defined in Constants.OFFICER_RANKS
-- Only works for players who are already in the guild!
local function GetAuthorizedOfficers()
	-- Check if player is in a guild
	if not IsInGuild() then
		SchlingelInc.Debug:Print("Player is not in a guild - cannot retrieve officers")
		return {}
	end

	local officers = {}

	-- Use ranks configured via OfficerWizard; fall back to hardcoded Constants if not set yet
	local officerRanks = (SchlingelGuildDB and SchlingelGuildDB.officerRanks
		and #SchlingelGuildDB.officerRanks > 0)
		and SchlingelGuildDB.officerRanks
		or SchlingelInc.Constants.OFFICER_RANKS

	-- Loop through all authorized ranks
	for _, rankName in ipairs(officerRanks) do
		local membersWithRank = SchlingelInc.GuildCache:GetMembersByRank(rankName)

		-- Add all online members of this rank to the officer list
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

    -- Sanitize inputs by replacing delimiters with safe characters
    -- This prevents zone names with colons from breaking the message parsing
    local safeZone = zone:gsub(":", "-"):gsub("|", "-")

    local message = string.format("INVITE_REQUEST:%s:%d:%d:%s", playerName, playerLevel, playerExp, safeZone)

    -- Level 1 players are ALWAYS outside the guild
    -- Use the fallback officer list from Constants
    local guildOfficers = SchlingelInc.Constants.FALLBACK_OFFICERS

    if #guildOfficers == 0 then
        return
    end

    -- Send the request to all officers via whisper
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
            -- Validate data before using
            local levelNum = tonumber(level)
            local xpNum = tonumber(xp)

            -- Ensure values are reasonable
            if not levelNum or levelNum < 1 or levelNum > 60 then
                SchlingelInc.Debug:Print("Invalid level in guild request: " .. tostring(level))
                return
            end

            if not xpNum or xpNum < 0 then
                SchlingelInc.Debug:Print("Invalid XP in guild request: " .. tostring(xp))
                return
            end

            -- Ensure strings are not empty
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

        -- Notify all online officers about the sent invitation
        local guildOfficers = GetAuthorizedOfficers()
        for _, name in ipairs(guildOfficers) do
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "INVITE_SENT:" .. playerName, "WHISPER", name)
        end
    end
end

function SchlingelInc.GuildRecruitment:HandleDeclineRequest(playerName)
    if not playerName then return end

    -- Notify all online officers about the declined request
    local guildOfficers = GetAuthorizedOfficers()
    for _, name in ipairs(guildOfficers) do
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "INVITE_DECLINED:" .. playerName, "WHISPER", name)
    end

    SchlingelInc:Print("Anfrage von " .. playerName .. " wurde abgelehnt.")
end

-- Initializes the GuildRecruitment module
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

-- Returns formatted zone name
function SchlingelInc.GuildRecruitment:GetPlayerZone()
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        return mapID and C_Map.GetMapInfo(mapID) and C_Map.GetMapInfo(mapID).name or GetZoneText() or "Unknown"
    end
    return GetZoneText() or "Unknown"
end
