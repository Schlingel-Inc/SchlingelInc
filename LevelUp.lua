-- LevelUp.lua
SchlingelInc.LevelUps = {}
SchlingelInc.LevelUps.progressCache = {}  -- shortName -> { level, xpCurrent, xpMax, timestamp }

-- Persists an entry to the officer-only progress DB.
local function SaveProgressEntry(shortName, entry)
    if not CanGuildRemove() then return end
    SchlingelProgressDB = SchlingelProgressDB or {}
    SchlingelProgressDB[shortName] = entry
end

local lastBroadcast = 0
local lastXPBroadcast = 0

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

-- Separate rate-limited broadcast for XP gain events (fires very frequently during play).
local function BroadcastProgressOnXP()
    if not IsInGuild() then return end
    local now = time()
    if now - lastXPBroadcast < 60 then return end
    lastXPBroadcast = now
    lastBroadcast = now  -- prevent the 5s guard from firing right after
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
            -- Officers: restore progress cache from persistent storage.
            C_Timer.After(2, function()
                if CanGuildRemove() and SchlingelProgressDB then
                    for k, v in pairs(SchlingelProgressDB) do
                        if not SchlingelInc.LevelUps.progressCache[k] then
                            SchlingelInc.LevelUps.progressCache[k] = v
                        end
                    end
                end
            end)
            C_Timer.After(3, BroadcastProgress)
        end, 0, "LevelUpProgressLogin")

    SchlingelInc.EventManager:RegisterHandler("ZONE_CHANGED_NEW_AREA",
        function()
            BroadcastProgress()
        end, 0, "LevelUpProgressZone")

    SchlingelInc.EventManager:RegisterHandler("PLAYER_GUILD_UPDATE",
        function()
            if IsInGuild() then
                C_Timer.After(3, BroadcastProgress)
            end
        end, 0, "LevelUpProgressGuildUpdate")

    -- PLAYER_XP_UPDATE fires on every XP gain (kills, quests, etc.).
    -- Uses a 60s cooldown to avoid flooding the guild channel during active grinding.
    SchlingelInc.EventManager:RegisterHandler("PLAYER_XP_UPDATE",
        function()
            BroadcastProgressOnXP()
        end, 0, "LevelUpProgressXP")

    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
        function(_, prefix, message, _, sender)
            if prefix ~= SchlingelInc.prefix then return end
            local level, xpCurrent, xpMax = message:match("^PROGRESS:[^:]+:(%d+):(%d+):(%d+)$")
            if level then
                local shortName = SchlingelInc:RemoveRealmFromName(sender)
                local entry = {
                    level     = tonumber(level),
                    xpCurrent = tonumber(xpCurrent),
                    xpMax     = tonumber(xpMax),
                    timestamp = time(),
                }
                SchlingelInc.LevelUps.progressCache[shortName] = entry
                SaveProgressEntry(shortName, entry)
                SchlingelInc.OfficerPanel:RefreshProgress()
            end
        end, 0, "LevelUpProgressReceive")

    local function PruneProgressCache()
        if not CanGuildRemove() then return end
        local members = {}
        local total = GetNumGuildMembers() or 0
        for i = 1, total do
            local name = GetGuildRosterInfo(i)
            if name then
                members[SchlingelInc:RemoveRealmFromName(name)] = true
            end
        end
        for k in pairs(SchlingelInc.LevelUps.progressCache) do
            if not members[k] then
                SchlingelInc.LevelUps.progressCache[k] = nil
                if SchlingelProgressDB then SchlingelProgressDB[k] = nil end
            end
        end
    end

    SchlingelInc.EventManager:RegisterHandler("GUILD_ROSTER_UPDATE",
        function() PruneProgressCache() end, 0, "LevelUpProgressPrune")
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
