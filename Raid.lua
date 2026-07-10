-- Raid.lua
-- "Raid Panel mit LFG-light": guild members post raid entries and others signal
-- interest with a role. Each client owns and broadcasts the entries/signals it
-- created; everyone else merges what they receive into a shared, account-wide
-- cache (SchlingelRaidDB).

SchlingelInc.Raid = {}

SchlingelRaidDB         = SchlingelRaidDB or {}
SchlingelRaidDB.entries = SchlingelRaidDB.entries or {}
SchlingelRaidDB.signals = SchlingelRaidDB.signals or {}

local MSG_POST         = "RAID_POST"
local MSG_CANCEL       = "RAID_CANCEL"
local MSG_SIGNAL       = "RAID_SIGNAL"
local MSG_UNSIGNAL     = "RAID_UNSIGNAL"
local MSG_SYNC_REQUEST = "RAID_SYNC_REQUEST"

local TITLE_MAX_LEN = 60
local NOTE_MAX_LEN  = 80

local EXPIRE_GRACE_SECONDS = 3 * 3600
local PURGE_AFTER_SECONDS  = 24 * 3600

-- "|" is the message field separator, so it can't appear in free-text fields.
local function SanitizeForMessage(text)
    text = (text or ""):gsub("|", "/")
    return SchlingelInc:SanitizeText(text) or text
end

local function OwnName()
    return UnitName("player")
end

-- ── Storage helpers ─────────────────────────────────────────────────────────────

local function IsValidInstance(instance)
    for _, name in ipairs(SchlingelInc.Constants.RAID_INSTANCES) do
        if name == instance then return true end
    end
    return false
end

local function IsValidRole(role)
    for _, name in ipairs(SchlingelInc.Constants.ROLES) do
        if name == role then return true end
    end
    return false
end

local function PurgeStale()
    local now = time()
    for id, entry in pairs(SchlingelRaidDB.entries) do
        if now - entry.timestamp > EXPIRE_GRACE_SECONDS + PURGE_AFTER_SECONDS then
            SchlingelRaidDB.entries[id] = nil
            SchlingelRaidDB.signals[id] = nil
        end
    end
end

local function IsEntryActive(entry)
    if not entry or entry.cancelled then return false end
    return time() - entry.timestamp <= EXPIRE_GRACE_SECONDS
end

-- ── Outgoing messages ────────────────────────────────────────────────────────────

local function BroadcastPost(entry)
    local payload = table.concat({
        MSG_POST, entry.id, SanitizeForMessage(entry.title), entry.instance,
        tostring(entry.timestamp), SanitizeForMessage(entry.note or ""),
    }, "|")
    ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, payload, "GUILD", nil, "SchlingelInc-Raid")
end

local function BroadcastCancel(id)
    ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, MSG_CANCEL .. "|" .. id, "GUILD", nil, "SchlingelInc-Raid")
end

local function BroadcastSignal(id, signal)
    local payload = table.concat({ MSG_SIGNAL, id, signal.role }, "|")
    ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, payload, "GUILD", nil, "SchlingelInc-Raid")
end

local function BroadcastUnsignal(id)
    ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, MSG_UNSIGNAL .. "|" .. id, "GUILD", nil, "SchlingelInc-Raid")
end

-- ── Public API ───────────────────────────────────────────────────────────────────

function SchlingelInc.Raid:Post(title, instance, timestamp, note)
    if not IsInGuild() then return nil, "Nicht in einer Gilde." end
    title = (title or ""):match("^%s*(.-)%s*$")
    if title == "" then return nil, "Titel darf nicht leer sein." end
    if not IsValidInstance(instance) then return nil, "Ungültige Instanz." end
    timestamp = tonumber(timestamp)
    if not timestamp or timestamp <= time() then return nil, "Zeitpunkt liegt in der Vergangenheit." end

    local id = OwnName() .. "-" .. time()
    local entry = {
        id        = id,
        poster    = OwnName(),
        title     = SanitizeForMessage(title):sub(1, TITLE_MAX_LEN),
        instance  = instance,
        timestamp = timestamp,
        note      = SanitizeForMessage(note or ""):sub(1, NOTE_MAX_LEN),
        cancelled = false,
        updatedAt = time(),
    }
    SchlingelRaidDB.entries[id] = entry
    BroadcastPost(entry)
    return id
end

function SchlingelInc.Raid:Edit(id, title, instance, timestamp, note)
    local entry = SchlingelRaidDB.entries[id]
    if not entry or entry.poster ~= OwnName() then return nil, "Kein eigener Raid-Eintrag." end
    title = (title or ""):match("^%s*(.-)%s*$")
    if title == "" then return nil, "Titel darf nicht leer sein." end
    if not IsValidInstance(instance) then return nil, "Ungültige Instanz." end
    timestamp = tonumber(timestamp)
    if not timestamp or timestamp <= time() then return nil, "Zeitpunkt liegt in der Vergangenheit." end

    entry.title     = SanitizeForMessage(title):sub(1, TITLE_MAX_LEN)
    entry.instance  = instance
    entry.timestamp = timestamp
    entry.note      = SanitizeForMessage(note or ""):sub(1, NOTE_MAX_LEN)
    entry.cancelled = false
    entry.updatedAt = time()

    BroadcastPost(entry)
    return true
end

function SchlingelInc.Raid:Cancel(id)
    local entry = SchlingelRaidDB.entries[id]
    if not entry or entry.poster ~= OwnName() then return nil, "Kein eigener Raid-Eintrag." end

    entry.cancelled = true
    entry.updatedAt = time()
    BroadcastCancel(id)
    return true
end

function SchlingelInc.Raid:Signal(id, role)
    local entry = SchlingelRaidDB.entries[id]
    if not entry or not IsEntryActive(entry) then return nil, "Raid nicht (mehr) aktiv." end
    if not IsValidRole(role) then return nil, "Ungültige Rolle." end

    local signal = { role = role, updatedAt = time() }
    SchlingelRaidDB.signals[id] = SchlingelRaidDB.signals[id] or {}
    SchlingelRaidDB.signals[id][OwnName()] = signal
    BroadcastSignal(id, signal)
    return true
end

function SchlingelInc.Raid:Unsignal(id)
    local forId = SchlingelRaidDB.signals[id]
    if forId then forId[OwnName()] = nil end
    BroadcastUnsignal(id)
end

function SchlingelInc.Raid:GetEntry(id)
    return SchlingelRaidDB.entries[id]
end

function SchlingelInc.Raid:GetOwnSignal(id)
    local forId = SchlingelRaidDB.signals[id]
    return forId and forId[OwnName()]
end

function SchlingelInc.Raid:GetSignals(id)
    local out = {}
    for name, signal in pairs(SchlingelRaidDB.signals[id] or {}) do
        table.insert(out, { name = name, role = signal.role })
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

function SchlingelInc.Raid:GetRoleCounts(id)
    local counts = {}
    for _, role in ipairs(SchlingelInc.Constants.ROLES) do counts[role] = 0 end
    for _, signal in pairs(SchlingelRaidDB.signals[id] or {}) do
        counts[signal.role] = (counts[signal.role] or 0) + 1
    end
    return counts
end

function SchlingelInc.Raid:GetActiveEntries()
    PurgeStale()
    local out = {}
    for _, entry in pairs(SchlingelRaidDB.entries) do
        if IsEntryActive(entry) then table.insert(out, entry) end
    end
    table.sort(out, function(a, b) return a.timestamp < b.timestamp end)
    return out
end

function SchlingelInc.Raid:RequestSync()
    if not IsInGuild() then return end
    ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, MSG_SYNC_REQUEST, "GUILD", nil, "SchlingelInc-Raid")
end

-- A signal keyed under the local player's name can only have been created by the
-- local player, so scanning for it is safe even against a merged/shared cache.
local function BroadcastOwnState()
    if not IsInGuild() then return end
    local own = OwnName()
    for _, entry in pairs(SchlingelRaidDB.entries) do
        if entry.poster == own and IsEntryActive(entry) then
            BroadcastPost(entry)
        end
    end
    for id, forId in pairs(SchlingelRaidDB.signals) do
        local signal = forId[own]
        if signal and IsEntryActive(SchlingelRaidDB.entries[id]) then
            BroadcastSignal(id, signal)
        end
    end
end

-- ── Incoming messages ────────────────────────────────────────────────────────────

function SchlingelInc.Raid:HandleMessage(message, sender)
    local senderShort = SchlingelInc:RemoveRealmFromName(sender)

    if message == MSG_SYNC_REQUEST then
        BroadcastOwnState()
        return true
    end

    local id, title, instance, timestampStr, note =
        message:match("^" .. MSG_POST .. "|([^|]+)|([^|]*)|([^|]*)|(%d+)|(.*)$")
    if id then
        -- id's own poster prefix must match the sender too, guarding against a spoofed poster.
        local idPoster = id:match("^(.-)-%d+$")
        if idPoster ~= senderShort or not IsValidInstance(instance) then return true end
        local existing = SchlingelRaidDB.entries[id]
        if existing and existing.poster ~= senderShort then return true end

        SchlingelRaidDB.entries[id] = {
            id        = id,
            poster    = senderShort,
            title     = title,
            instance  = instance,
            timestamp = tonumber(timestampStr),
            note      = note,
            cancelled = false,
            updatedAt = time(),
        }
        if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshRaid then
            SchlingelInc.GuildPanel:RefreshRaid()
        end
        return true
    end

    local cancelId = message:match("^" .. MSG_CANCEL .. "|(.+)$")
    if cancelId then
        local entry = SchlingelRaidDB.entries[cancelId]
        if entry and entry.poster == senderShort then
            entry.cancelled = true
            entry.updatedAt = time()
            if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshRaid then
                SchlingelInc.GuildPanel:RefreshRaid()
            end
        end
        return true
    end

    local signalId, role = message:match("^" .. MSG_SIGNAL .. "|([^|]+)|([^|]*)$")
    if signalId then
        if IsValidRole(role) then
            SchlingelRaidDB.signals[signalId] = SchlingelRaidDB.signals[signalId] or {}
            SchlingelRaidDB.signals[signalId][senderShort] = { role = role, updatedAt = time() }
            if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshRaid then
                SchlingelInc.GuildPanel:RefreshRaid()
            end
        end
        return true
    end

    local unsignalId = message:match("^" .. MSG_UNSIGNAL .. "|(.+)$")
    if unsignalId then
        local forId = SchlingelRaidDB.signals[unsignalId]
        if forId then forId[senderShort] = nil end
        if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshRaid then
            SchlingelInc.GuildPanel:RefreshRaid()
        end
        return true
    end

    return false
end

function SchlingelInc.Raid:Initialize()
    PurgeStale()

    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
        function(_, prefix, message, _, sender)
            if prefix ~= SchlingelInc.prefix then return end
            SchlingelInc.Raid:HandleMessage(message, sender)
        end, 0, "RaidAddonMessage")

    SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
        function()
            C_Timer.After(6, function()
                if IsInGuild() then
                    BroadcastOwnState()
                    SchlingelInc.Raid:RequestSync()
                end
            end)
        end, 0, "RaidBroadcastAndSync")
end
