-- LevelUp.lua
SchlingelInc.LevelUps = {}
SchlingelInc.LevelUps.progressCache = {}  -- shortName -> { level, xpCurrent, xpMax, timestamp }

-- Persists an entry to the officer-only progress DB.
local function SaveProgressEntry(shortName, entry)
    if not CanGuildInvite() then return end
    SchlingelProgressDB = SchlingelProgressDB or {}
    SchlingelProgressDB[shortName] = entry
end

local lastKnownXPStop = nil

local function GetXPStopState()
    local api = C_PlayerInfo and C_PlayerInfo.IsXPUserDisabled
    if type(api) ~= "function" then return nil end
    local ok, result = pcall(api)
    if not ok or type(result) ~= "boolean" then return nil end
    return result
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

local function BuildProgressEntry()
    local name = UnitName("player")
    if not name then return nil end

    return {
        name       = name,
        level      = UnitLevel("player"),
        xpCurrent  = UnitXP("player") or 0,
        xpMax      = UnitXPMax("player") or 0,
        gold       = GetMoney() or 0,
        runesKnown = GetRunesKnown() or 0,
        xpStop     = GetXPStopState(),
        timestamp  = time(),
    }
end

local function CacheOwnProgress()
    local entry = BuildProgressEntry()
    if not entry then return nil end

    local shortName = SchlingelInc:RemoveRealmFromName(entry.name)
    SchlingelInc.LevelUps.progressCache[shortName] = entry
    SaveProgressEntry(shortName, entry)
    return entry
end

local function SendProgressTo(targetName)
    if not IsInGuild() then return end
    if not targetName or targetName == "" then return end

    local entry = BuildProgressEntry()
    if not entry then return end

    local xpStopSuffix = entry.xpStop ~= nil and (":" .. (entry.xpStop and "1" or "0")) or ""
    C_ChatInfo.SendAddonMessage(
        SchlingelInc.prefix,
        string.format("PROGRESS:%s:%d:%d:%d:%d:%d%s",
            entry.name, entry.level, entry.xpCurrent, entry.xpMax, entry.gold, entry.runesKnown, xpStopSuffix),
        "WHISPER",
        targetName
    )
end

local function CheckForMilestone(level)
    if SchlingelInc.Rules.CurrentCap > 0 and level >= SchlingelInc.Rules.CurrentCap then return end
    for _, lvl in pairs(SchlingelInc.Constants.LEVEL_MILESTONES) do
        if level == lvl then
            local player = UnitName("player")
            local handle = SchlingelInc:GetDiscordHandle()
            local playerDisplay = (handle and handle ~= "") and (player .. " (" .. handle .. ")") or player
            SchlingelInc:SendGuildChatMessage(playerDisplay .. " hat Level " .. level .. " erreicht! Schlingel! Schlingel! Schlingel!")
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "LEVELUP:" .. player .. ":" .. level, "GUILD")
        end
    end
end

function SchlingelInc.LevelUps:Initialize()
    local progressLoadTotal    = 0
    local progressLoadReceived = 0
    local progressLoadTimer    = nil

    local function EndProgressLoad()
        if progressLoadTimer then progressLoadTimer:Cancel() progressLoadTimer = nil end
        progressLoadTotal    = 0
        progressLoadReceived = 0
        if SchlingelInc.OfficerPanel and SchlingelInc.OfficerPanel.EndProgressLoad then SchlingelInc.OfficerPanel.EndProgressLoad() end
        SchlingelInc.OfficerPanel:RefreshProgress()
    end

    SchlingelInc.LevelUps.StartLoad = function(total)
        progressLoadTotal    = total
        progressLoadReceived = 0
        if progressLoadTimer then progressLoadTimer:Cancel() end
        progressLoadTimer = C_Timer.NewTimer(math.max(5, total * 0.5 + 5), EndProgressLoad)
        local panel = SchlingelInc.OfficerPanel
        if panel and panel.StartProgressLoad then panel.StartProgressLoad(total) end
    end

    SchlingelInc.LevelUps.OnProgressReceived = function()
        if progressLoadTotal == 0 then return end
        progressLoadReceived = progressLoadReceived + 1
        local panel = SchlingelInc.OfficerPanel
        if panel and panel.UpdateProgressLoad then
            panel.UpdateProgressLoad(progressLoadReceived, progressLoadTotal)
        end
        if progressLoadReceived >= progressLoadTotal then
            EndProgressLoad()
        end
    end

    SchlingelInc.EventManager:RegisterHandler("PLAYER_LEVEL_UP",
        function(_, level)
            CheckForMilestone(level)
            SchlingelInc.LevelUps:CheckForCap(level, true)
            CacheOwnProgress()
        end, 0, "LevelUpEvents")

    SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
        function()
            -- Officers: restore progress cache from persistent storage.
            C_Timer.After(2, function()
                if CanGuildInvite() and SchlingelProgressDB then
                    for k, v in pairs(SchlingelProgressDB) do
                        if not SchlingelInc.LevelUps.progressCache[k] then
                            SchlingelInc.LevelUps.progressCache[k] = v
                        end
                    end
                end
            end)
            C_Timer.After(3, CacheOwnProgress)
        end, 0, "LevelUpProgressLogin")

    SchlingelInc.EventManager:RegisterHandler("ZONE_CHANGED_NEW_AREA",
        function()
            CacheOwnProgress()
        end, 0, "LevelUpProgressZone")

    SchlingelInc.EventManager:RegisterHandler("PLAYER_GUILD_UPDATE",
        function()
            if IsInGuild() then
                C_Timer.After(3, CacheOwnProgress)
            end
        end, 0, "LevelUpProgressGuildUpdate")

    SchlingelInc.EventManager:RegisterHandler("PLAYER_FLAGS_CHANGED",
        function(_, unit)
            if unit ~= "player" then return end
            local cap = SchlingelInc.Rules.CurrentCap
            if not cap or cap <= 0 or cap >= SchlingelInc.Constants.MAX_LEVEL then return end
            if UnitLevel("player") < cap then return end
            local xpStop = GetXPStopState()
            if xpStop == lastKnownXPStop then return end
            lastKnownXPStop = xpStop
            CacheOwnProgress()
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
            if message == "PROGRESS_REQUEST" then
                if sender and sender ~= UnitName("player") then
                    SendProgressTo(sender)
                end
                return
            end
            local msgType, _, levelStr, xpCurrentStr, xpMaxStr, goldStr, field7, field8 = strsplit(":", message)
            if msgType == "PROGRESS" and tonumber(levelStr) and tonumber(xpCurrentStr) and tonumber(xpMaxStr) and tonumber(goldStr) then
                local runesKnown
                local xpStop

                -- Legacy format: PROGRESS:name:level:xpCurrent:xpMax:gold[:xpStop]
                if field7 == "0" or field7 == "1" then
                    xpStop = field7 == "1"
                else
                    -- New format: PROGRESS:name:level:xpCurrent:xpMax:gold:runesKnown[:xpStop]
                    runesKnown = tonumber(field7)
                    if field8 == "0" or field8 == "1" then
                        xpStop = field8 == "1"
                    end
                end

                local shortName = SchlingelInc:RemoveRealmFromName(sender)
                local entry = {
                    level      = tonumber(levelStr),
                    xpCurrent  = tonumber(xpCurrentStr),
                    xpMax      = tonumber(xpMaxStr),
                    gold       = tonumber(goldStr),
                    runesKnown = runesKnown,
                    xpStop     = xpStop,
                    timestamp  = time(),
                }
                SchlingelInc.LevelUps.progressCache[shortName] = entry
                SaveProgressEntry(shortName, entry)
                SchlingelInc.LevelUps.OnProgressReceived()
            end
        end, 0, "LevelUpProgressReceive")

    local function PruneProgressCache()
        if not CanGuildInvite() then return end
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
        function() PruneProgressCache() CacheOwnProgress() end, 0, "LevelUpProgressPrune")
end

function SchlingelInc.LevelUps:RequestProgress(targetName)
    if not IsInGuild() then return end

    CacheOwnProgress()

    if targetName then
        SchlingelInc.LevelUps.StartLoad(1)
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "PROGRESS_REQUEST", "WHISPER", targetName)
        return
    end

    -- Staggered whispers to avoid simultaneous response flood
    local online = {}
    local selfName = UnitName("player")
    for i = 1, GetNumGuildMembers() or 0 do
        local name, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
        if name and isOnline then
            local short = SchlingelInc:RemoveRealmFromName(name)
            if short ~= selfName then
                table.insert(online, short)
            end
        end
    end
    SchlingelInc.LevelUps.StartLoad(#online)
    for i, name in ipairs(online) do
        C_Timer.After((i - 1) * 0.5, function()
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "PROGRESS_REQUEST", "WHISPER", name)
        end)
    end
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
            SchlingelInc:SendGuildChatMessage(playerDisplay .. " hat das Level Cap von " .. level .. " erreicht! Herzlichen Glückwunsch!")
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "CAP:" .. player .. ":" .. level, "GUILD")
        end
    end
end
