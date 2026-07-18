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
    return C_PlayerInfo.IsXPUserDisabled()
end

local function GetRunesKnown()
    return C_Engraving.GetNumRunesKnown()
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

    ChatThrottleLib:SendAddonMessage(
        "NORMAL",
        SchlingelInc.prefix,
        string.format("PROGRESS:%s:%d:%d:%d:%d:%d:%d",
            entry.name, entry.level, entry.xpCurrent, entry.xpMax, entry.gold, entry.runesKnown, entry.xpStop and 1 or 0),
        "WHISPER",
        targetName,
        "SchlingelInc-Progress"
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
            ChatThrottleLib:SendAddonMessage("ALERT", SchlingelInc.prefix, "LEVELUP:" .. player .. ":" .. level, "GUILD", nil, "SchlingelInc-Announce")
        end
    end
end

function SchlingelInc.LevelUps:Initialize()
    local progressLoadTotal    = 0
    local progressLoadReceived = 0
    local progressLoadTimer    = nil

    local versionLoadTotal    = 0
    local versionLoadReceived = 0
    local versionLoadTimer    = nil

    local function RefreshWhenLoadsDone()
        if progressLoadTotal == 0 and versionLoadTotal == 0 then
            SchlingelInc.OfficerPanel:RefreshProgress()
        end
    end

    local function EndProgressLoad()
        if progressLoadTimer then progressLoadTimer:Cancel() progressLoadTimer = nil end
        progressLoadTotal    = 0
        progressLoadReceived = 0
        if SchlingelInc.OfficerPanel and SchlingelInc.OfficerPanel.EndProgressLoad then SchlingelInc.OfficerPanel.EndProgressLoad() end
        RefreshWhenLoadsDone()
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

    local function EndVersionLoad()
        if versionLoadTimer then versionLoadTimer:Cancel() versionLoadTimer = nil end
        versionLoadTotal    = 0
        versionLoadReceived = 0
        RefreshWhenLoadsDone()
    end

    SchlingelInc.LevelUps.StartVersionLoad = function(total)
        versionLoadTotal    = total
        versionLoadReceived = 0
        if versionLoadTimer then versionLoadTimer:Cancel() end
        versionLoadTimer = C_Timer.NewTimer(math.max(5, total * 0.1 + 5), EndVersionLoad)
    end

    SchlingelInc.LevelUps.OnVersionReceived = function()
        if versionLoadTotal == 0 then return end
        versionLoadReceived = versionLoadReceived + 1
        if versionLoadReceived >= versionLoadTotal then
            EndVersionLoad()
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
            local msgType, _, levelStr, xpCurrentStr, xpMaxStr, goldStr, runesStr, xpStopStr = strsplit(":", message)
            if msgType == "PROGRESS" and tonumber(levelStr) and tonumber(xpCurrentStr) and tonumber(xpMaxStr) and tonumber(goldStr) and tonumber(runesStr) then
                local shortName = SchlingelInc:RemoveRealmFromName(sender)
                local entry = {
                    level      = tonumber(levelStr),
                    xpCurrent  = tonumber(xpCurrentStr),
                    xpMax      = tonumber(xpMaxStr),
                    gold       = tonumber(goldStr),
                    runesKnown = tonumber(runesStr),
                    xpStop     = xpStopStr == "1",
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

    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
        function(_, prefix, message, _, sender)
            if prefix ~= SchlingelInc.prefix then return end
            local senderShort = SchlingelInc:RemoveRealmFromName(sender)
            if senderShort == UnitName("player") then return end
            if message:match("^LEVELUP:") then
                local levelName, levelNum = message:match("^LEVELUP:(.+):(%d+)$")
                if levelName and levelNum then
                    SchlingelInc.LevelUpAnnouncement:ShowMessage(levelName, tonumber(levelNum))
                end
            elseif message:match("^CAP:") then
                local capName, capNum = message:match("^CAP:(.+):(%d+)$")
                if capName and capNum then
                    SchlingelInc.LevelUpAnnouncement:ShowCap(capName, tonumber(capNum))
                end
            end
        end, 0, "MilestoneAddonMessage")
end

function SchlingelInc.LevelUps:RequestProgress(targetName)
    if not IsInGuild() then return end

    CacheOwnProgress()

    if targetName then
        SchlingelInc.LevelUps.StartLoad(1)
        ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, "PROGRESS_REQUEST", "WHISPER", targetName, "SchlingelInc-Progress")
        return
    end

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
    SchlingelInc.LevelUps.StartVersionLoad(#online)
    ChatThrottleLib:SendAddonMessage("BULK", SchlingelInc.prefix, "VERSION_REQUEST", "GUILD", nil, "SchlingelInc-Version")
    for _, name in ipairs(online) do
        ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, "PROGRESS_REQUEST", "WHISPER", name, "SchlingelInc-Progress")
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
            ChatThrottleLib:SendAddonMessage("ALERT", SchlingelInc.prefix, "CAP:" .. player .. ":" .. level, "GUILD", nil, "SchlingelInc-Announce")
        end
    end
end
