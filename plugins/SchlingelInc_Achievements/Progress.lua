-- Progress.lua
-- Per-character unlock bookkeeping, kill-progress counters, and the achievement
-- score fed into GuildProfiles. Knows the catalog (to look up points/names) but no
-- detection logic — LevelDetector/KillDetector decide *when* to call Unlock().

SchlingelInc.Achievements.Progress = {}
local Progress = SchlingelInc.Achievements.Progress

local MSG_UNREACHED_REQUEST = "ACH_UNREACHED_REQUEST"
local MSG_UNREACHED         = "ACH_UNREACHED"
local MSG_REACHED_REQUEST   = "ACH_REACHED_REQUEST"
local MSG_REACHED           = "ACH_REACHED"

-- WoW's addon-message hard ceiling — same limit Catalog.lua budgets ACH_DEFINE
-- against (see its MAX_MESSAGE_LEN comment for why neither SendAddonMessage nor
-- ChatThrottleLib will truncate an oversized message for us).
local MAX_MESSAGE_LEN = 255

-- Greedily packs `ids` into as few "tag|chunkIndex|totalChunks|id1|id2|..." messages
-- as fit under MAX_MESSAGE_LEN. A veteran character's unreached/reached id list has
-- no natural upper bound, so this can't be a single message the way it used to be.
-- chunkIndex/totalChunks let the receiver (AchievementActionForm.OnReceived) know
-- when it has everything, regardless of delivery order. Always emits at least one
-- message — even for an empty id list — so the requester gets a definitive "you
-- have none of these" answer instead of waiting out the popup's timeout.
local function BuildChunkedMessages(tag, ids)
    local groups = { {} }
    for _, id in ipairs(ids) do
        local g = groups[#groups]
        local candidate = (#g == 0) and id or (table.concat(g, "|") .. "|" .. id)
        -- Reserve room for "tag|<idx>|<total>|" ahead of the ids; idx/total stay
        -- small in practice, so a flat reserve is safe.
        if #g > 0 and (#candidate + #tag + 8) > MAX_MESSAGE_LEN then
            table.insert(groups, { id })
        else
            table.insert(g, id)
        end
    end

    local total = #groups
    local messages = {}
    for i, g in ipairs(groups) do
        table.insert(messages, table.concat({ tag, tostring(i), tostring(total), unpack(g) }, "|"))
    end
    return messages
end

-- Parses a "tag|chunkIndex|totalChunks|id1|id2|..." message. Returns nil if
-- `message` isn't a chunk of `tag` at all.
local function ParseChunkedMessage(tag, message)
    if not message:match("^" .. tag .. "|%d+|%d+") then return nil end
    local parts = SchlingelInc:ParsePipeMessage(message)
    table.remove(parts, 1) -- tag
    local chunkIndex = tonumber(table.remove(parts, 1))
    local totalChunks = tonumber(table.remove(parts, 1))
    return chunkIndex, totalChunks, parts
end

local function EnsureStores()
    SchlingelAchievementDB = SchlingelAchievementDB or {}
    SchlingelAchievementDB.globalUnlocked = SchlingelAchievementDB.globalUnlocked or {}
    SchlingelAchievementDB.globalKillProgress = SchlingelAchievementDB.globalKillProgress or {}

    SchlingelOwnAchievements = SchlingelOwnAchievements or {}
    SchlingelOwnAchievements.unlocked = SchlingelOwnAchievements.unlocked or {}
    SchlingelOwnAchievements.killProgress = SchlingelOwnAchievements.killProgress or {}
end

local function ResolveStores(id)
    EnsureStores()

    local entry = SchlingelInc.Achievements.Catalog:Get(id)
    local useGlobal = entry and SchlingelInc.Achievements.IsTruthyFlag(entry.isGlobal)

    local unlockedStore = useGlobal and SchlingelAchievementDB.globalUnlocked or SchlingelOwnAchievements.unlocked
    local killStore     = useGlobal and SchlingelAchievementDB.globalKillProgress or SchlingelOwnAchievements.killProgress
    local otherUnlocked  = useGlobal and SchlingelOwnAchievements.unlocked or SchlingelAchievementDB.globalUnlocked
    local otherKill      = useGlobal and SchlingelOwnAchievements.killProgress or SchlingelAchievementDB.globalKillProgress

    -- Keep progress when officers toggle an achievement between character/global scope.
    if unlockedStore[id] == nil and otherUnlocked[id] ~= nil then
        unlockedStore[id] = otherUnlocked[id]
    end
    if killStore[id] == nil and otherKill[id] ~= nil then
        killStore[id] = otherKill[id]
    end

    return unlockedStore, killStore
end

function Progress:IsUnlocked(id)
    local unlockedStore = ResolveStores(id)
    return unlockedStore[id] ~= nil
end

function Progress:GetUnlockedIds()
    EnsureStores()
    local out = {}
    local seen = {}
    for id in pairs(SchlingelOwnAchievements.unlocked) do
        seen[id] = true
    end
    for id in pairs(SchlingelAchievementDB.globalUnlocked) do
        seen[id] = true
    end
    for id in pairs(seen) do
        table.insert(out, id)
    end
    return out
end

function Progress:GetUnlockedAt(id)
    local unlockedStore = ResolveStores(id)
    return unlockedStore[id]
end

-- Sum of points for every currently-unlocked achievement that still exists in the
-- catalog. Computed live so an officer editing an entry's points retroactively
-- updates everyone's score consistently.
function Progress:GetScore()
    local total = 0
    for _, id in ipairs(Progress:GetUnlockedIds()) do
        local entry = SchlingelInc.Achievements.Catalog:Get(id)
        if entry and Progress:IsUnlocked(id) then
            total = total + (entry.points or 0)
        end
    end
    return total
end

-- Returns (currentRank, nextRank) for an arbitrary score — used both for the local
-- player's own rank and for computing another player's rank from their broadcast
-- achievementScore (the rank name itself never needs to go over the wire, since
-- every client derives it from the same Constants.ACHIEVEMENT_RANKS table).
function Progress:GetRankForScore(score)
    local current, nextRank
    for _, rank in ipairs(SchlingelInc.Constants.ACHIEVEMENT_RANKS) do
        if score >= rank.minPoints then
            current = rank
        elseif not nextRank then
            nextRank = rank
        end
    end
    return current, nextRank
end

function Progress:GetRank()
    return Progress:GetRankForScore(Progress:GetScore())
end

function Progress:GetKillProgress(id)
    local _, killStore = ResolveStores(id)
    return killStore[id] or 0
end

function Progress:IncrementKillProgress(id)
    local _, killStore = ResolveStores(id)
    local newCount = (killStore[id] or 0) + 1
    killStore[id] = newCount
    return newCount
end

-- Marks id unlocked (idempotent), shows a personal popup + sound, and re-broadcasts
-- the guild profile so the updated score reaches the guild via the normal sync path.
function Progress:Unlock(id)
    if Progress:IsUnlocked(id) then return false end
    local entry = SchlingelInc.Achievements.Catalog:Get(id)
    if not entry then return false end

    local unlockedStore, killStore = ResolveStores(id)
    unlockedStore[id] = time()
    killStore[id] = nil

    SchlingelInc.AchievementAnnouncement:Show(entry.name)

    if SchlingelInc.GuildProfiles then
        SchlingelInc.GuildProfiles:Broadcast()
    end
    if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshAchievements then
        SchlingelInc.GuildPanel:RefreshAchievements()
    end

    return true
end

-- Removes an unlock from the local character/account, clearing any stored kill
-- progress alongside it so a mistaken grant does not immediately reappear.
function Progress:Revoke(id)
    EnsureStores()

    local hadUnlock = SchlingelOwnAchievements.unlocked[id] ~= nil
        or SchlingelAchievementDB.globalUnlocked[id] ~= nil
    if not hadUnlock then return false end

    SchlingelOwnAchievements.unlocked[id] = nil
    SchlingelAchievementDB.globalUnlocked[id] = nil
    SchlingelOwnAchievements.killProgress[id] = nil
    SchlingelAchievementDB.globalKillProgress[id] = nil

    if SchlingelInc.GuildProfiles then
        SchlingelInc.GuildProfiles:Broadcast()
    end
    if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshAchievements then
        SchlingelInc.GuildPanel:RefreshAchievements()
    end

    return true
end

-- Achievement kinds an officer can manually grant (mirrors ManualGrant's allow-list).
-- Own not-yet-unlocked grantable achievement ids, for the achievement-grant popup.
-- Sending the "still missing" set rather than the "already have" set keeps the
-- response short for veteran characters, who are exactly the ones with the most
-- unlocked achievements to otherwise list.
local function OwnUnreachedGrantableIds()
    local ids = {}
    for _, entry in ipairs(SchlingelInc.Achievements.Catalog:GetActive()) do
        if SchlingelInc.Achievements.IsGrantableKind(entry.kind) and not Progress:IsUnlocked(entry.id) then
            table.insert(ids, entry.id)
        end
    end
    return ids
end

-- Own currently unlocked grantable achievement ids, including retired entries so
-- officers can still remove achievements that are no longer obtainable.
local function OwnReachedGrantableIds()
    local ids = {}
    for _, entry in ipairs(SchlingelInc.Achievements.Catalog:GetAll()) do
        if SchlingelInc.Achievements.IsGrantableKind(entry.kind) and Progress:IsUnlocked(entry.id) then
            table.insert(ids, entry.id)
        end
    end
    return ids
end

-- Officer action: ask targetName's client which grantable achievements it hasn't
-- unlocked yet. The response arrives asynchronously via HandleMessage and is routed
-- to the achievement-grant popup if it's still open for this target.
function Progress:RequestUnreached(targetName)
    if not targetName or targetName == "" then return end
    SchlingelInc:SendAddonMessage(MSG_UNREACHED_REQUEST, "WHISPER", targetName)
end

-- Officer action: ask targetName's client which grantable achievements it currently
-- has unlocked, so the revoke popup can offer only removable entries.
function Progress:RequestReached(targetName)
    if not targetName or targetName == "" then return end
    SchlingelInc:SendAddonMessage(MSG_REACHED_REQUEST, "WHISPER", targetName)
end

function Progress:HandleMessage(message, sender)
    if message == MSG_UNREACHED_REQUEST then
        for _, payload in ipairs(BuildChunkedMessages(MSG_UNREACHED, OwnUnreachedGrantableIds())) do
            SchlingelInc:SendAddonMessage(payload, "WHISPER", sender)
        end
        return true
    end

    if message == MSG_REACHED_REQUEST then
        for _, payload in ipairs(BuildChunkedMessages(MSG_REACHED, OwnReachedGrantableIds())) do
            SchlingelInc:SendAddonMessage(payload, "WHISPER", sender)
        end
        return true
    end

    local chunkIndex, totalChunks, ids = ParseChunkedMessage(MSG_UNREACHED, message)
    if chunkIndex then
        local senderShort = SchlingelInc:RemoveRealmFromName(sender)
        if SchlingelInc.Popup and SchlingelInc.Popup.OnUnreachedReceived then
            SchlingelInc.Popup:OnUnreachedReceived(senderShort, chunkIndex, totalChunks, ids)
        end
        return true
    end

    chunkIndex, totalChunks, ids = ParseChunkedMessage(MSG_REACHED, message)
    if chunkIndex then
        local senderShort = SchlingelInc:RemoveRealmFromName(sender)
        if SchlingelInc.Popup and SchlingelInc.Popup.OnReachedReceived then
            SchlingelInc.Popup:OnReachedReceived(senderShort, chunkIndex, totalChunks, ids)
        end
        return true
    end

    return false
end

function Progress:Initialize()
    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
        function(_, prefix, message, _, sender)
            if prefix ~= SchlingelInc.prefix then return end
            Progress:HandleMessage(message, sender)
        end, 0, "AchievementProgressAddonMessage")
end
