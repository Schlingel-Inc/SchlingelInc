-- Schande.lua
-- Per-character Schande record (RP-Tribunal verdicts) and officer <-> player messaging.
-- Own record lives in SchlingelOwnSchande (SavedVariablesPerCharacter) — there is no
-- account-wide cache; each player only ever knows their own Schande state, delivered
-- live by an officer via addon whisper (mirrors /deathset in death/SlashCommands.lua).

SchlingelInc.Schande = {}

-- entries: array of { id = number, freetext = string, active = bool }, oldest first.
-- nextId: the id to assign to the next received verdict (ids are assigned locally
-- by the receiver, so an officer only learns an entry's id from the player after the fact).
-- Patched onto whatever's already saved rather than replaced outright, so earlier
-- pre-release saves (from before entries/nextId existed) still pick up the new fields.
SchlingelOwnSchande = SchlingelOwnSchande or {}
SchlingelOwnSchande.entries = SchlingelOwnSchande.entries or {}
SchlingelOwnSchande.nextId  = SchlingelOwnSchande.nextId or 1

local MSG_IMPOSE     = "SCHANDE_IMPOSE"
local MSG_RESOLVE    = "SCHANDE_RESOLVE"
local MSG_FETCH      = "SCHANDE_FETCH"
local MSG_PUSH_COUNT = "SCHANDE_PUSH_COUNT"
local MSG_PUSH       = "SCHANDE_PUSH"

local FETCH_TIMEOUT = 5

-- Officer-side state for an in-flight GetAllOf() request. seq guards against a late
-- response (or timeout) from a superseded request clobbering a newer one.
local fetchSeq = 0
local pendingFetch = nil -- { target = shortName, seq = number, callback = fn, count = number|nil, entries = {} }

-- Returns the local player's own Schande record ({ entries = {...} }).
function SchlingelInc.Schande:GetOwn()
    return SchlingelOwnSchande
end

-- True if any of entries is currently an active (unresolved) Schande.
function SchlingelInc.Schande.IsEntriesActive(entries)
    for _, entry in ipairs(entries) do
        if entry.active then return true end
    end
    return false
end

-- Returns true if any entry is currently an active (unresolved) Schande.
function SchlingelInc.Schande:IsActive()
    return SchlingelInc.Schande.IsEntriesActive(SchlingelOwnSchande.entries)
end

-- Officer action: impose a new Schande verdict on targetName (must be online).
function SchlingelInc.Schande:Impose(targetName, freetext)
    if not CanGuildInvite() then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Keine Berechtigung für diesen Befehl.|r")
        return
    end
    if not targetName or targetName == "" then return end
    freetext = freetext or ""

    ChatThrottleLib:SendAddonMessage("ALERT", SchlingelInc.prefix, MSG_IMPOSE .. "|" .. freetext, "WHISPER", targetName, "SchlingelInc-Schande")
    SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
        "Schande gegen " .. targetName .. " verhängt.|r")
end

-- Officer action: mark a specific Schande entry (by id) as resolved (target must be online).
function SchlingelInc.Schande:Resolve(targetName, id)
    if not CanGuildInvite() then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Keine Berechtigung für diesen Befehl.|r")
        return
    end
    if not targetName or targetName == "" then return end
    id = tonumber(id)
    if not id then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Ungültige Schande-ID.|r")
        return
    end

    ChatThrottleLib:SendAddonMessage("ALERT", SchlingelInc.prefix, MSG_RESOLVE .. "|" .. id, "WHISPER", targetName, "SchlingelInc-Schande")
    SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
        "Schande #" .. id .. " von " .. targetName .. " aufgehoben.|r")
end

-- Officer action: request targetName's full Schande list (must be online and have the addon).
-- callback is invoked as callback(entries) on success, or callback(nil) if targetName
-- doesn't respond within FETCH_TIMEOUT seconds. Any earlier pending request is superseded.
function SchlingelInc.Schande:GetAllOf(targetName, callback)
    if not CanGuildInvite() then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Keine Berechtigung für diesen Befehl.|r")
        return
    end
    if not targetName or targetName == "" then return end

    fetchSeq = fetchSeq + 1
    local seq = fetchSeq
    pendingFetch = {
        target   = SchlingelInc:RemoveRealmFromName(targetName),
        seq      = seq,
        callback = callback,
        count    = nil,
        entries  = {},
    }

    ChatThrottleLib:SendAddonMessage("ALERT", SchlingelInc.prefix, MSG_FETCH, "WHISPER", targetName, "SchlingelInc-Schande")

    C_Timer.After(FETCH_TIMEOUT, function()
        if pendingFetch and pendingFetch.seq == seq then
            local cb = pendingFetch.callback
            pendingFetch = nil
            if cb then cb(nil) end
        end
    end)
end

-- Handle incoming Schande addon whispers (SCHANDE_IMPOSE / SCHANDE_RESOLVE apply to own
-- record; SCHANDE_FETCH / SCHANDE_PUSH* implement GetAllOf's officer <-> player round trip).
function SchlingelInc.Schande:HandleMessage(message, sender)
    local resolveIdStr = message:match("^" .. MSG_RESOLVE .. "|(%d+)$")
    if resolveIdStr then
        local id = tonumber(resolveIdStr)
        local found = nil
        for _, entry in ipairs(SchlingelOwnSchande.entries) do
            if entry.id == id then found = entry break end
        end

        if found then
            found.active = false
            SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
                "Deine Schande #" .. id .. " wurde aufgehoben.|r")
        else
            SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING ..
                "Kein Schande-Eintrag mit ID #" .. id .. " gefunden.|r")
        end

        if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshSchande then
            SchlingelInc.GuildPanel:RefreshSchande()
        end
        return true
    end

    local freetext = message:match("^" .. MSG_IMPOSE .. "|(.*)$")
    if freetext then
        local id = SchlingelOwnSchande.nextId or 1
        SchlingelOwnSchande.nextId = id + 1
        table.insert(SchlingelOwnSchande.entries, { id = id, freetext = freetext, active = true })
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING ..
            "Schande #" .. id .. "! Aufgabe: " .. freetext .. "|r")
        if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshSchande then
            SchlingelInc.GuildPanel:RefreshSchande()
        end
        return true
    end

    if message == MSG_FETCH then
        local entries = SchlingelOwnSchande.entries
        ChatThrottleLib:SendAddonMessage("ALERT", SchlingelInc.prefix, MSG_PUSH_COUNT .. "|" .. #entries, "WHISPER", sender, "SchlingelInc-Schande")
        for _, entry in ipairs(entries) do
            ChatThrottleLib:SendAddonMessage("ALERT", SchlingelInc.prefix,
                MSG_PUSH .. "|" .. entry.id .. "|" .. (entry.active and "1" or "0") .. "|" .. entry.freetext,
                "WHISPER", sender, "SchlingelInc-Schande")
        end
        return true
    end

    local countStr = message:match("^" .. MSG_PUSH_COUNT .. "|(%d+)$")
    if countStr then
        local senderShort = SchlingelInc:RemoveRealmFromName(sender)
        if pendingFetch and pendingFetch.target == senderShort then
            local count = tonumber(countStr)
            pendingFetch.count = count
            pendingFetch.entries = {}
            if count == 0 then
                local cb = pendingFetch.callback
                pendingFetch = nil
                if cb then cb({}) end
            end
        end
        return true
    end

    local idStr, activeStr, pushFreetext = message:match("^" .. MSG_PUSH .. "|(%d+)|([01])|(.*)$")
    if idStr then
        local senderShort = SchlingelInc:RemoveRealmFromName(sender)
        if pendingFetch and pendingFetch.target == senderShort and pendingFetch.count then
            table.insert(pendingFetch.entries, {
                id = tonumber(idStr), active = activeStr == "1", freetext = pushFreetext,
            })
            if #pendingFetch.entries >= pendingFetch.count then
                local cb = pendingFetch.callback
                local result = pendingFetch.entries
                pendingFetch = nil
                if cb then cb(result) end
            end
        end
        return true
    end

    return false
end

function SchlingelInc.Schande:Initialize()
    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
        function(_, prefix, message, _, sender)
            if prefix ~= SchlingelInc.prefix then return end
            SchlingelInc.Schande:HandleMessage(message, sender)
        end, 0, "SchandeReceive")
end
