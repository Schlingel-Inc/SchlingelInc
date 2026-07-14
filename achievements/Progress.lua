-- Achievements/Progress.lua
-- Per-character unlock bookkeeping, kill-progress counters, and the achievement
-- score fed into GuildProfiles. Knows the catalog (to look up points/names) but no
-- detection logic — LevelDetector/KillDetector decide *when* to call Unlock().

SchlingelInc.Achievements.Progress = {}
local Progress = SchlingelInc.Achievements.Progress

local KIND = SchlingelInc.Achievements.KIND

local MSG_UNREACHED_REQUEST = "ACH_UNREACHED_REQUEST"
local MSG_UNREACHED         = "ACH_UNREACHED"

local function IsGlobalFlag(value)
    return value == true or value == 1 or value == "1"
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
    local useGlobal = entry and IsGlobalFlag(entry.isGlobal)

    local unlockedStore = useGlobal and SchlingelAchievementDB.globalUnlocked or SchlingelOwnAchievements.unlocked
    local killStore = useGlobal and SchlingelAchievementDB.globalKillProgress or SchlingelOwnAchievements.killProgress

    -- Keep progress when officers toggle an achievement between character/global scope.
    if useGlobal then
        if unlockedStore[id] == nil and SchlingelOwnAchievements.unlocked[id] ~= nil then
            unlockedStore[id] = SchlingelOwnAchievements.unlocked[id]
        end
        if killStore[id] == nil and SchlingelOwnAchievements.killProgress[id] ~= nil then
            killStore[id] = SchlingelOwnAchievements.killProgress[id]
        end
    else
        if unlockedStore[id] == nil and SchlingelAchievementDB.globalUnlocked[id] ~= nil then
            unlockedStore[id] = SchlingelAchievementDB.globalUnlocked[id]
        end
        if killStore[id] == nil and SchlingelAchievementDB.globalKillProgress[id] ~= nil then
            killStore[id] = SchlingelAchievementDB.globalKillProgress[id]
        end
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

-- Achievement kinds an officer can manually grant (mirrors ManualGrant's allow-list).
local function IsGrantableKind(kind)
    return kind == KIND.LEVEL or kind == KIND.MANUAL
end

-- Own not-yet-unlocked grantable achievement ids, for the achievement-grant popup.
-- Sending the "still missing" set rather than the "already have" set keeps the
-- response short for veteran characters, who are exactly the ones with the most
-- unlocked achievements to otherwise list.
local function OwnUnreachedGrantableIds()
    local ids = {}
    for _, entry in ipairs(SchlingelInc.Achievements.Catalog:GetActive()) do
        if IsGrantableKind(entry.kind) and not Progress:IsUnlocked(entry.id) then
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
    ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, MSG_UNREACHED_REQUEST, "WHISPER", targetName, "SchlingelInc-Achievements")
end

function Progress:HandleMessage(message, sender)
    if message == MSG_UNREACHED_REQUEST then
        local payload = table.concat({ MSG_UNREACHED, unpack(OwnUnreachedGrantableIds()) }, "|")
        ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, payload, "WHISPER", sender, "SchlingelInc-Achievements")
        return true
    end

    if message == MSG_UNREACHED or message:match("^" .. MSG_UNREACHED .. "|") then
        local ids = SchlingelInc:ParsePipeMessage(message)
        table.remove(ids, 1) -- drop the MSG_UNREACHED tag
        local senderShort = SchlingelInc:RemoveRealmFromName(sender)
        if SchlingelInc.Popup and SchlingelInc.Popup.OnUnreachedReceived then
            SchlingelInc.Popup:OnUnreachedReceived(senderShort, ids)
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
