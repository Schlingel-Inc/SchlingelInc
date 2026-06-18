-- LevelUp.lua
SchlingelInc.LevelUps = {}
SchlingelInc.LevelUps.progressCache = {}  -- shortName -> { level, xpCurrent, xpMax, timestamp }

local lastBroadcast = 0

local function BroadcastProgress()
    if not IsInGuild() then return end
    local now = time()
    if now - lastBroadcast < 5 then return end
    lastBroadcast = now
    local name = UnitName("player")
    if not name then return end
    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix,
        string.format("PROGRESS:%s:%d:%d:%d", name, UnitLevel("player"), UnitXP("player"), UnitXPMax("player")),
        "GUILD")
end

local function CheckForMilestone(level)
    if level >= SchlingelInc.Rules.CurrentCap then return end
    for _, lvl in pairs(SchlingelInc.Constants.LEVEL_MILESTONES) do
        if level == lvl then
            local player = UnitName("player")
            local handle = SchlingelInc:GetDiscordHandle()
            local playerDisplay = (handle and handle ~= "") and (player .. " (" .. handle .. ")") or player
            SendChatMessage(playerDisplay .. " hat Level " .. level .. " erreicht! Schlingel! Schlingel! Schlingel!", "GUILD")
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "LEVELUP:" .. player .. ":" .. level, "GUILD")
        end
    end
end

function SchlingelInc.LevelUps:Initialize()
    SchlingelInc.EventManager:RegisterHandler("PLAYER_LEVEL_UP",
        function(_, level)
            CheckForMilestone(level)
            SchlingelInc.LevelUps:CheckForCap(level, true)
            BroadcastProgress()
        end, 0, "LevelUpEvents")

    SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
        function()
            C_Timer.After(3, BroadcastProgress)
        end, 0, "LevelUpProgressLogin")

    SchlingelInc.EventManager:RegisterHandler("ZONE_CHANGED_NEW_AREA",
        function()
            BroadcastProgress()
        end, 0, "LevelUpProgressZone")

    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
        function(_, prefix, message, _, sender)
            if prefix ~= SchlingelInc.prefix then return end
            local level, xpCurrent, xpMax = message:match("^PROGRESS:[^:]+:(%d+):(%d+):(%d+)$")
            if level then
                local shortName = SchlingelInc:RemoveRealmFromName(sender)
                SchlingelInc.LevelUps.progressCache[shortName] = {
                    level     = tonumber(level),
                    xpCurrent = tonumber(xpCurrent),
                    xpMax     = tonumber(xpMax),
                    timestamp = time(),
                }
            end
        end, 0, "LevelUpProgressReceive")
end

function SchlingelInc.LevelUps:CheckForCap(level, announce)
    if SchlingelInc.Rules.CurrentCap == 0 or level == SchlingelInc.Constants.MAX_LEVEL then return end
    if level >= SchlingelInc.Rules.CurrentCap then
        local playerExp = UnitXP("player")
        local levelUpXP = UnitXPMax("player")
        local currentXPPercent = (levelUpXP > 0) and (playerExp / levelUpXP * 100) or 0
        SchlingelInc.Popup:Show({
            title = "Level Cap erreicht",
            message = string.format("Du bist bei %d%% von Level %d.\nDas aktuelle Cap ist %d.\n Achte auf die Level Schande!", currentXPPercent, level + 1, SchlingelInc.Rules.CurrentCap),
            displayTime = 8
        })

        if announce then
            local player = UnitName("player")
            local handle = SchlingelInc:GetDiscordHandle()
            local playerDisplay = (handle and handle ~= "") and (player .. " (" .. handle .. ")") or player
            SendChatMessage(playerDisplay .. " hat das Level Cap von " .. level .. " erreicht! Herzlichen Glückwunsch!", "GUILD")
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "CAP:" .. player .. ":" .. level, "GUILD")
        end
    end
end
