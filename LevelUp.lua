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
local lastKnownXPStop = nil

local function GetXPStopState()
    local api = C_PlayerInfo and C_PlayerInfo.IsXPUserDisabled
    if type(api) ~= "function" then return nil end
    local ok, result = pcall(api)
    if not ok or type(result) ~= "boolean" then return nil end
    return result
end

local function BroadcastProgress()
    if not IsInGuild() then return end
    local now = time()
    if now - lastBroadcast < 10 then return end
    lastBroadcast = now
    local name = UnitName("player")
    if not name then return end
    local xpStop = GetXPStopState()
    local suffix = xpStop ~= nil and (":" .. (xpStop and "1" or "0")) or ""
    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix,
        string.format("PROGRESS:%s:%d:%d:%d:%d%s",
            name, UnitLevel("player"), UnitXP("player"), UnitXPMax("player"), GetMoney(), suffix),
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

    SchlingelInc.EventManager:RegisterHandler("PLAYER_XP_UPDATE",
        function()
            BroadcastProgress()
        end, 0, "LevelUpProgressXP")

    SchlingelInc.EventManager:RegisterHandler("PLAYER_MONEY",
        function()
            BroadcastProgress()
        end, 0, "LevelUpProgressMoney")

    SchlingelInc.EventManager:RegisterHandler("PLAYER_FLAGS_CHANGED",
        function(_, unit)
            if unit ~= "player" then return end
            local cap = SchlingelInc.Rules.CurrentCap
            if not cap or cap <= 0 or cap >= SchlingelInc.Constants.MAX_LEVEL then return end
            if UnitLevel("player") < cap then return end
            local xpStop = GetXPStopState()
            if xpStop == lastKnownXPStop then return end
            lastKnownXPStop = xpStop
            BroadcastProgress()
            if xpStop == false then
                SchlingelInc.Popup:Show({
                    title   = "XP-Stopp deaktiviert!",
                    message = string.format("XP-Stopp ist NICHT aktiv auf Level Cap %d!", cap),
                    displayTime = 10,
                })
            end
        end, 0, "LevelUpFlagsChanged")

    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
        function(_, prefix, message, _, sender)
            if prefix ~= SchlingelInc.prefix then return end
            local level, xpCurrent, xpMax = message:match("^PROGRESS:[^:]+:(%d+):(%d+):(%d+)")
            if level then
                local gold      = message:match("^PROGRESS:[^:]+:%d+:%d+:%d+:(%d+)")
                local xpStopStr = message:match("^PROGRESS:[^:]+:%d+:%d+:%d+:%d+:([01])$")
                local xpStop
                if xpStopStr ~= nil then xpStop = xpStopStr == "1" end
                local shortName = SchlingelInc:RemoveRealmFromName(sender)
                local entry = {
                    level     = tonumber(level),
                    xpCurrent = tonumber(xpCurrent),
                    xpMax     = tonumber(xpMax),
                    gold      = gold and tonumber(gold) or nil,
                    xpStop    = xpStop,
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
        function() PruneProgressCache() BroadcastProgress() end, 0, "LevelUpProgressPrune")
end

function SchlingelInc.LevelUps:CheckForCap(level, announce)
    if SchlingelInc.Rules.CurrentCap == 0 or level == SchlingelInc.Constants.MAX_LEVEL then return end
    if level >= SchlingelInc.Rules.CurrentCap then
        local xpStop = GetXPStopState()
        if xpStop == false and lastKnownXPStop == nil then
            SchlingelInc.Popup:Show({
                title   = "Level Cap " .. SchlingelInc.Rules.CurrentCap .. " erreicht!",
                message = "XP-Stopp ist NICHT aktiv!\nBitte jetzt aktivieren!",
                displayTime = 10,
            })
        end
        lastKnownXPStop = xpStop

        if announce then
            local player = UnitName("player")
            local handle = SchlingelInc:GetDiscordHandle()
            local playerDisplay = (handle and handle ~= "") and (player .. " (" .. handle .. ")") or player
            SendChatMessage(playerDisplay .. " hat das Level Cap von " .. level .. " erreicht! Herzlichen Glückwunsch!", "GUILD")
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "CAP:" .. player .. ":" .. level, "GUILD")
        end
    end
end
