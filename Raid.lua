-- Raid.lua
-- "Raid Panel mit LFG-light": guild members post raid entries and others signal
-- interest with a role. Everyone merges what they receive into a shared,
-- account-wide cache (SchlingelRaidDB); any online member can relay cached
-- entries/signals to others, since the original poster/signaler may be offline.

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

local function IsEntryActive(entry)
    if not entry or entry.cancelled then return false end
    return time() - entry.timestamp <= EXPIRE_GRACE_SECONDS
end

-- No history is kept, so anything no longer active (cancelled, or past its grace
-- period) is dropped right away instead of lingering in the DB.
local function PurgeStale()
    for id, entry in pairs(SchlingelRaidDB.entries) do
        if not IsEntryActive(entry) then
            SchlingelRaidDB.entries[id] = nil
            SchlingelRaidDB.signals[id] = nil
        end
    end
end

local function RefreshRaidUI()
    if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshRaid then
        SchlingelInc.GuildPanel:RefreshRaid()
    end
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

local function BroadcastSignal(id, signal, signalerName)
    local payload = table.concat({ MSG_SIGNAL, id, signal.role, signalerName }, "|")
    ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, payload, "GUILD", nil, "SchlingelInc-Raid")
end

local function BroadcastUnsignal(id, signalerName)
    local payload = table.concat({ MSG_UNSIGNAL, id, signalerName }, "|")
    ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, payload, "GUILD", nil, "SchlingelInc-Raid")
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
    BroadcastSignal(id, signal, OwnName())
    return true
end

function SchlingelInc.Raid:Unsignal(id)
    local forId = SchlingelRaidDB.signals[id]
    if forId then forId[OwnName()] = nil end
    BroadcastUnsignal(id, OwnName())
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

-- Relays the whole local cache, not just what this client posted/signaled itself,
-- so a peer can catch someone up even if the original poster/signaler is offline.
local function BroadcastKnownState()
    if not IsInGuild() then return end
    for _, entry in pairs(SchlingelRaidDB.entries) do
        if IsEntryActive(entry) then
            BroadcastPost(entry)
        end
    end
    for id, forId in pairs(SchlingelRaidDB.signals) do
        if IsEntryActive(SchlingelRaidDB.entries[id]) then
            for signalerName, signal in pairs(forId) do
                BroadcastSignal(id, signal, signalerName)
            end
        end
    end
end

-- ── Incoming messages ────────────────────────────────────────────────────────────

function SchlingelInc.Raid:HandleMessage(message, sender)
    local senderShort = SchlingelInc:RemoveRealmFromName(sender)

    if message == MSG_SYNC_REQUEST then
        BroadcastKnownState()
        return true
    end

    local id, title, instance, timestampStr, note =
        message:match("^" .. MSG_POST .. "|([^|]+)|([^|]*)|([^|]*)|(%d+)|(.*)$")
    if id then
        -- poster comes from the id (set at creation), not the sender, since a relay isn't the poster
        local idPoster = id:match("^(.-)-%d+$")
        if not idPoster or idPoster == "" or not IsValidInstance(instance) then return true end

        SchlingelRaidDB.entries[id] = {
            id        = id,
            poster    = idPoster,
            title     = title,
            instance  = instance,
            timestamp = tonumber(timestampStr),
            note      = note,
            cancelled = false,
            updatedAt = time(),
        }
        RefreshRaidUI()
        return true
    end

    local cancelId = message:match("^" .. MSG_CANCEL .. "|(.+)$")
    if cancelId then
        local entry = SchlingelRaidDB.entries[cancelId]
        if entry and entry.poster == senderShort then
            entry.cancelled = true
            entry.updatedAt = time()
            RefreshRaidUI()
        end
        return true
    end

    -- signalerName is the real owner, since sender may just be relaying
    local signalId, role, signalerName = message:match("^" .. MSG_SIGNAL .. "|([^|]+)|([^|]*)|([^|]+)$")
    if signalId then
        if IsValidRole(role) then
            SchlingelRaidDB.signals[signalId] = SchlingelRaidDB.signals[signalId] or {}
            SchlingelRaidDB.signals[signalId][signalerName] = { role = role, updatedAt = time() }
            RefreshRaidUI()
        end
        return true
    end

    local unsignalId, unsignalerName = message:match("^" .. MSG_UNSIGNAL .. "|([^|]+)|([^|]+)$")
    if unsignalId then
        local forId = SchlingelRaidDB.signals[unsignalId]
        if forId then forId[unsignalerName] = nil end
        RefreshRaidUI()
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

    -- Only request sync here; BroadcastKnownState() already fires as every online
    -- peer's reply, so also blasting our own full cache on login would just double
    -- guild-wide traffic without helping anyone catch up faster.
    SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
        function()
            C_Timer.After(6, function()
                if IsInGuild() then
                    SchlingelInc.Raid:RequestSync()
                end
            end)
        end, 0, "RaidRequestSync")
end
