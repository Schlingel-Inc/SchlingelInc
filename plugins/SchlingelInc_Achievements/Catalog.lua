-- Catalog.lua
-- Officer-authored achievement definitions (the catalog), broadcast to the guild.
-- Sync is manual (RequestSync, triggered by the refresh button): any online peer
-- relays what it knows, jittered and suppressed the same way Raid.lua does.

local KIND = SchlingelInc.Achievements.KIND

SchlingelInc.Achievements.Catalog = {}
local Catalog = SchlingelInc.Achievements.Catalog

local MSG_DEFINE       = "ACH_DEFINE"
local MSG_SYNC_REQUEST = "ACH_SYNC_REQUEST"

-- Wire-format kind codes: keeps ACH_DEFINE's fixed overhead small so more of the
-- 255-byte addon-message budget is left for name/description (see MAX_MESSAGE_LEN
-- below). Internally, entries always use the human-readable KIND.* constants —
-- this mapping only applies at the message-serialize/parse boundary.
local KIND_WIRE_CODE = {
    [KIND.LEVEL]      = "L",
    [KIND.KILL_COUNT] = "K",
    [KIND.MANUAL]     = "M",
}
local WIRE_CODE_KIND = {
    L = KIND.LEVEL,
    K = KIND.KILL_COUNT,
    M = KIND.MANUAL,
}

-- WoW's addon-message hard ceiling (both C_ChatInfo.SendAddonMessage and
-- ChatThrottleLib reject anything longer outright — neither truncates for us).
local MAX_MESSAGE_LEN = 255

-- ACH_DEFINE's fixed overhead, worst case, everything except name/description:
--   tag(10) id(35) kind(1) points(4) critA(7) critB(6) retired(1) isGlobal(1) updatedAt(10)
--   + 10 "|" separators (11 fields) = 85
-- id budget: up to 12-char realm character name (worst case ~2 bytes/char for
-- accented locale characters) + "-" + a 10-digit unix timestamp = ~35 bytes.
-- points is capped at 4 digits (see MAX_POINTS below); critA/critB budgeted for a
-- kill_count entry's NPC id (critA) and required kill count (critB).
-- That leaves 255-85=170 bytes for name+description combined; the limits below
-- stay under that with margin so sanitization/edge cases can't tip it over.
local NAME_MAX_LEN = 50
local DESC_MAX_LEN = 110
local MAX_POINTS   = 9999

local function OwnName()
    return UnitName("player")
end

local function SortEntries(entries)
    table.sort(entries, function(a, b)
        local nameA = string.lower(tostring(a and a.name or ""))
        local nameB = string.lower(tostring(b and b.name or ""))
        if nameA ~= nameB then
            return nameA < nameB
        end

        local createdAtA = tonumber(a and a.createdAt) or 0
        local createdAtB = tonumber(b and b.createdAt) or 0
        if createdAtA ~= createdAtB then
            return createdAtA < createdAtB
        end

        return tostring(a and a.id or "") < tostring(b and b.id or "")
    end)
end

local function SanitizeForMessage(text)
    text = (text or ""):gsub("|", "/")
    return SchlingelInc:SanitizeText(text) or text
end

local function IsValidKind(kind)
    return kind == KIND.LEVEL or kind == KIND.KILL_COUNT or kind == KIND.MANUAL
end

local function RandomDelay(minSeconds, maxSeconds)
    return minSeconds + math.random() * (maxSeconds - minSeconds)
end

local RELAY_JITTER_MIN = 0.5
local RELAY_JITTER_MAX = 3.0

local pendingRelay  = {}
local answeredSince = {}

-- ── Wire serialization ──────────────────────────────────────────────────────────

local function SerializeDefine(entry)
    local kindCode = KIND_WIRE_CODE[entry.kind]
    if not kindCode then return nil end
    return table.concat({
        MSG_DEFINE, entry.id, kindCode,
        SanitizeForMessage(entry.name), SanitizeForMessage(entry.description),
        tostring(entry.points), tostring(entry.critA or ""), tostring(entry.critB or ""),
        entry.retired and "1" or "0", (entry.isGlobal and "1" or "0"), tostring(entry.updatedAt or time()),
    }, "|")
end

-- ── Broadcast ────────────────────────────────────────────────────────────────────

local function SendRelayMessage(payload)
    SchlingelInc:SendAddonMessage(payload, "GUILD")
end

local function BroadcastDefine(entry, isRelay)
    local payload = SerializeDefine(entry)
    if not payload then return end
    if isRelay then
        SendRelayMessage(payload)
    else
        SchlingelInc:SendAddonMessage(payload, "GUILD")
    end
end

-- ── Public API (officer actions) ──────────────────────────────────────────────────

-- kind-specific criteria: LEVEL -> critA=threshold level, critB=requireNoDeath (bool)
--                         KILL_COUNT -> critA=npcID, critB=required kill count
--                         MANUAL -> critA/critB unused
function Catalog:Create(kind, name, description, points, critA, critB, isGlobal)
    if not CanGuildInvite() then return nil, "Keine Berechtigung für diesen Befehl." end
    if not IsValidKind(kind) then return nil, "Ungültige Erfolgsart." end
    name = (name or ""):match("^%s*(.-)%s*$")
    if name == "" then return nil, "Name darf nicht leer sein." end
    points = tonumber(points)
    if not points or points < 0 or points > MAX_POINTS then
        return nil, "Ungültige Punktzahl (0-" .. MAX_POINTS .. ")."
    end
    isGlobal = SchlingelInc.Achievements.IsTruthyFlag(isGlobal)

    local id = OwnName() .. "-" .. time()
    local entry = {
        id          = id,
        kind        = kind,
        name        = SanitizeForMessage(name):sub(1, NAME_MAX_LEN),
        description = SanitizeForMessage(description or ""):sub(1, DESC_MAX_LEN),
        points      = points,
        critA       = critA,
        critB       = critB,
        createdBy   = OwnName(),
        createdAt   = time(),
        updatedAt   = time(),
        retired     = false,
        isGlobal    = isGlobal,
    }

    local payload = SerializeDefine(entry)
    if not payload or #payload > MAX_MESSAGE_LEN then
        return nil, "Name und Beschreibung sind zusammen zu lang für die Synchronisation. Bitte kürzen."
    end

    SchlingelAchievementDB.entries[id] = entry
    BroadcastDefine(entry)
    return id
end

function Catalog:Edit(id, name, description, points, critA, critB, isGlobal)
    if not CanGuildInvite() then return nil, "Keine Berechtigung für diesen Befehl." end
    local existing = SchlingelAchievementDB.entries[id]
    if not existing then return nil, "Erfolg nicht gefunden." end
    if existing.createdBy == "builtin" then return nil, "Eingebaute Erfolge können nicht bearbeitet werden." end
    name = (name or ""):match("^%s*(.-)%s*$")
    if name == "" then return nil, "Name darf nicht leer sein." end
    points = tonumber(points)
    if not points or points < 0 or points > MAX_POINTS then
        return nil, "Ungültige Punktzahl (0-" .. MAX_POINTS .. ")."
    end
    isGlobal = SchlingelInc.Achievements.IsTruthyFlag(isGlobal)

    local entry = {
        id          = id,
        kind        = existing.kind,
        name        = SanitizeForMessage(name):sub(1, NAME_MAX_LEN),
        description = SanitizeForMessage(description or ""):sub(1, DESC_MAX_LEN),
        points      = points,
        critA       = critA,
        critB       = critB,
        createdBy   = existing.createdBy,
        createdAt   = existing.createdAt,
        updatedAt   = time(),
        retired     = existing.retired,
        isGlobal    = isGlobal,
    }

    local payload = SerializeDefine(entry)
    if not payload or #payload > MAX_MESSAGE_LEN then
        return nil, "Name und Beschreibung sind zusammen zu lang für die Synchronisation. Bitte kürzen."
    end

    SchlingelAchievementDB.entries[id] = entry
    BroadcastDefine(entry)
    return true
end

function Catalog:Retire(id)
    if not CanGuildInvite() then return nil, "Keine Berechtigung für diesen Befehl." end
    local entry = SchlingelAchievementDB.entries[id]
    if not entry then return nil, "Erfolg nicht gefunden." end
    if entry.createdBy == "builtin" then return nil, "Eingebaute Erfolge können nicht eingestellt werden." end

    entry.retired   = true
    entry.updatedAt = time()
    BroadcastDefine(entry)
    return true
end

function Catalog:Get(id)
    return SchlingelAchievementDB.entries[id]
end

-- All known entries, including retired ones (officer management view).
function Catalog:GetAll()
    local out = {}
    for _, entry in pairs(SchlingelAchievementDB.entries) do
        table.insert(out, entry)
    end
    SortEntries(out)
    return out
end

-- Non-retired entries only (member view).
function Catalog:GetActive()
    local out = {}
    for _, entry in pairs(SchlingelAchievementDB.entries) do
        if not entry.retired then table.insert(out, entry) end
    end
    SortEntries(out)
    return out
end

-- Unsorted scan over non-retired entries, for detectors (KillDetector/LevelDetector)
-- that only need to test each entry, not display them in order.
function Catalog:ForEachActive(fn)
    for _, entry in pairs(SchlingelAchievementDB.entries) do
        if not entry.retired then fn(entry) end
    end
end

function Catalog:RequestSync()
    if not IsInGuild() then return end
    SchlingelInc:SendAddonMessage(MSG_SYNC_REQUEST, "GUILD")
end

local function RelayEntry(id)
    local entry = SchlingelAchievementDB.entries[id]
    if not entry then return end
    BroadcastDefine(entry, true)
end

local function ScheduleRelay(id)
    if pendingRelay[id] then return end
    pendingRelay[id] = true
    local requestedAt = time()
    C_Timer.After(RandomDelay(RELAY_JITTER_MIN, RELAY_JITTER_MAX), function()
        pendingRelay[id] = nil
        if (answeredSince[id] or 0) >= requestedAt then return end
        RelayEntry(id)
    end)
end

local function HandleSyncRequest()
    if not IsInGuild() then return end
    for id in pairs(SchlingelAchievementDB.entries) do
        ScheduleRelay(id)
    end
end

-- ── Incoming messages ────────────────────────────────────────────────────────────

function Catalog:HandleMessage(message, sender)
    if message == MSG_SYNC_REQUEST then
        HandleSyncRequest()
        return true
    end

    local id, kindCode, name, description, pointsStr, critAStr, critBStr, retiredStr, isGlobalStr, updatedAtStr =
        message:match("^" .. MSG_DEFINE .. "|([^|]+)|([A-Z])|([^|]*)|([^|]*)|(%d+)|([^|]*)|([^|]*)|([01])|([01])|(%d+)$")
    if id then
        local kind = WIRE_CODE_KIND[kindCode]
        if not kind then return true end
        local existing = SchlingelAchievementDB.entries[id]
        -- id's creator prefix must match the sender, guarding against a spoofed creator.
        local idCreator = id:match("^(.-)-%d+$")
        local senderShort = SchlingelInc:RemoveRealmFromName(sender)
        if idCreator ~= senderShort then return true end
        if existing and existing.createdBy ~= senderShort then return true end
        answeredSince[id] = time()

        local incomingUpdatedAt = tonumber(updatedAtStr) or 0
        if existing and existing.updatedAt and existing.updatedAt >= incomingUpdatedAt then
            return true
        end

        SchlingelAchievementDB.entries[id] = {
            id          = id,
            kind        = kind,
            name        = name,
            description = description,
            points      = tonumber(pointsStr) or 0,
            critA       = critAStr ~= "" and (tonumber(critAStr) or critAStr) or nil,
            critB       = critBStr ~= "" and (tonumber(critBStr) or critBStr) or nil,
            createdBy   = senderShort,
            createdAt   = (existing and existing.createdAt) or time(),
            updatedAt   = incomingUpdatedAt,
            retired     = retiredStr == "1",
            isGlobal    = isGlobalStr == "1",
        }

        SchlingelInc.Achievements.LevelDetector:Check()

        if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshAchievements then
            SchlingelInc.GuildPanel:RefreshAchievements()
        end
        if SchlingelInc.OfficerPanel and SchlingelInc.OfficerPanel.RefreshAchievements then
            SchlingelInc.OfficerPanel:RefreshAchievements()
        end
        return true
    end

    return false
end

function Catalog:Initialize()
    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
        function(_, prefix, message, _, sender)
            if prefix ~= SchlingelInc.prefix then return end
            Catalog:HandleMessage(message, sender)
        end, 0, "AchievementCatalogAddonMessage")
end
