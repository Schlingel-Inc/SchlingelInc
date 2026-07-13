-- Achievements/Progress.lua
-- Per-character unlock bookkeeping, kill-progress counters, and the achievement
-- score fed into GuildProfiles. Knows the catalog (to look up points/names) but no
-- detection logic — LevelDetector/KillDetector decide *when* to call Unlock().

SchlingelInc.Achievements.Progress = {}
local Progress = SchlingelInc.Achievements.Progress

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

function Progress:Initialize()
    -- No events of its own; LevelDetector/KillDetector/ManualGrant drive Unlock().
end
