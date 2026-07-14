-- Achievements/Catalog.lua
-- Officer-authored achievement definitions (the catalog), broadcast to the guild and
-- kept in sync the same way Raid.lua syncs its entries: the creator re-broadcasts
-- their own entries on login, and answers sync requests from anyone who missed one.

local KIND = SchlingelInc.Achievements.KIND

SchlingelInc.Achievements.Catalog = {}
local Catalog = SchlingelInc.Achievements.Catalog

local MSG_DEFINE       = "ACH_DEFINE"
local MSG_RETIRE       = "ACH_RETIRE"
local MSG_SYNC_REQUEST = "ACH_SYNC_REQUEST"

local NAME_MAX_LEN = 60
local DESC_MAX_LEN = 120

local function OwnName()
    return UnitName("player")
end

local function SanitizeForMessage(text)
    text = (text or ""):gsub("|", "/")
    return SchlingelInc:SanitizeText(text) or text
end

local function IsValidKind(kind)
    return kind == KIND.LEVEL or kind == KIND.KILL_COUNT or kind == KIND.MANUAL
end

-- ── Broadcast ────────────────────────────────────────────────────────────────────

local function BroadcastDefine(entry)
    local payload = table.concat({
        MSG_DEFINE, entry.id, entry.kind,
        SanitizeForMessage(entry.name), SanitizeForMessage(entry.description),
        tostring(entry.points), tostring(entry.critA or ""), tostring(entry.critB or ""),
        entry.retired and "1" or "0", (entry.isGlobal and "1" or "0"),
    }, "|")
    ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, payload, "GUILD", nil, "SchlingelInc-Achievements")
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
    if not points or points < 0 then return nil, "Ungültige Punktzahl." end
    isGlobal = isGlobal == true or isGlobal == 1 or isGlobal == "1"

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
    SchlingelAchievementDB.entries[id] = entry
    BroadcastDefine(entry)
    return id
end

function Catalog:Edit(id, name, description, points, critA, critB, isGlobal)
    if not CanGuildInvite() then return nil, "Keine Berechtigung für diesen Befehl." end
    local entry = SchlingelAchievementDB.entries[id]
    if not entry then return nil, "Erfolg nicht gefunden." end
    if entry.createdBy == "builtin" then return nil, "Eingebaute Erfolge können nicht bearbeitet werden." end
    name = (name or ""):match("^%s*(.-)%s*$")
    if name == "" then return nil, "Name darf nicht leer sein." end
    points = tonumber(points)
    if not points or points < 0 then return nil, "Ungültige Punktzahl." end
    isGlobal = isGlobal == true or isGlobal == 1 or isGlobal == "1"

    entry.name        = SanitizeForMessage(name):sub(1, NAME_MAX_LEN)
    entry.description = SanitizeForMessage(description or ""):sub(1, DESC_MAX_LEN)
    entry.points      = points
    entry.critA       = critA
    entry.critB       = critB
    entry.isGlobal    = isGlobal
    entry.updatedAt   = time()

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
    table.sort(out, function(a, b) return a.createdAt < b.createdAt end)
    return out
end

-- Non-retired entries only (member view + detectors).
function Catalog:GetActive()
    local out = {}
    for _, entry in pairs(SchlingelAchievementDB.entries) do
        if not entry.retired then table.insert(out, entry) end
    end
    table.sort(out, function(a, b) return a.createdAt < b.createdAt end)
    return out
end

function Catalog:RequestSync()
    if not IsInGuild() then return end
    ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, MSG_SYNC_REQUEST, "GUILD", nil, "SchlingelInc-Achievements")
end

-- Re-broadcasts every entry this character created, so a login catches up anyone
-- who missed the original broadcast. Mirrors Raid.lua's BroadcastOwnState.
local function BroadcastOwnState()
    if not IsInGuild() then return end
    local own = OwnName()
    for _, entry in pairs(SchlingelAchievementDB.entries) do
        if entry.createdBy == own then
            BroadcastDefine(entry)
        end
    end
end

-- ── Incoming messages ────────────────────────────────────────────────────────────

function Catalog:HandleMessage(message, sender)
    if message == MSG_SYNC_REQUEST then
        BroadcastOwnState()
        return true
    end

    local id, kind, name, description, pointsStr, critAStr, critBStr, retiredStr, isGlobalStr =
        message:match("^" .. MSG_DEFINE .. "|([^|]+)|([^|]+)|([^|]*)|([^|]*)|(%d+)|([^|]*)|([^|]*)|([01])|([01])$")
    if not id then
        id, kind, name, description, pointsStr, critAStr, critBStr, retiredStr =
            message:match("^" .. MSG_DEFINE .. "|([^|]+)|([^|]+)|([^|]*)|([^|]*)|(%d+)|([^|]*)|([^|]*)|([01])$")
        isGlobalStr = "0"
    end
    if id then
        if not IsValidKind(kind) then return true end
        local existing = SchlingelAchievementDB.entries[id]
        -- id's creator prefix must match the sender, guarding against a spoofed creator.
        local idCreator = id:match("^(.-)-%d+$")
        local senderShort = SchlingelInc:RemoveRealmFromName(sender)
        if idCreator ~= senderShort then return true end
        if existing and existing.createdBy ~= senderShort then return true end

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
            updatedAt   = time(),
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

    SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
        function()
            C_Timer.After(6, function()
                if IsInGuild() then
                    BroadcastOwnState()
                    Catalog:RequestSync()
                end
            end)
        end, 0, "AchievementCatalogBroadcastAndSync")
end
