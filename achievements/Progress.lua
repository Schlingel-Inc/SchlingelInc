-- Achievements/Progress.lua
-- Per-character unlock bookkeeping, kill-progress counters, and the achievement
-- score fed into GuildProfiles. Knows the catalog (to look up points/names) but no
-- detection logic — LevelDetector/KillDetector decide *when* to call Unlock().

SchlingelInc.Achievements.Progress = {}
local Progress = SchlingelInc.Achievements.Progress

function Progress:IsUnlocked(id)
    return SchlingelOwnAchievements.unlocked[id] ~= nil
end

function Progress:GetUnlockedIds()
    local out = {}
    for id in pairs(SchlingelOwnAchievements.unlocked) do table.insert(out, id) end
    return out
end

function Progress:GetUnlockedAt(id)
    return SchlingelOwnAchievements.unlocked[id]
end

-- Sum of points for every currently-unlocked achievement that still exists in the
-- catalog. Computed live so an officer editing an entry's points retroactively
-- updates everyone's score consistently.
function Progress:GetScore()
    local total = 0
    for id in pairs(SchlingelOwnAchievements.unlocked) do
        local entry = SchlingelInc.Achievements.Catalog:Get(id)
        if entry then total = total + (entry.points or 0) end
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
    return SchlingelOwnAchievements.killProgress[id] or 0
end

function Progress:IncrementKillProgress(id)
    local newCount = (SchlingelOwnAchievements.killProgress[id] or 0) + 1
    SchlingelOwnAchievements.killProgress[id] = newCount
    return newCount
end

-- Marks id unlocked (idempotent), shows a personal popup + sound, and re-broadcasts
-- the guild profile so the updated score reaches the guild via the normal sync path.
function Progress:Unlock(id)
    if Progress:IsUnlocked(id) then return false end
    local entry = SchlingelInc.Achievements.Catalog:Get(id)
    if not entry then return false end

    SchlingelOwnAchievements.unlocked[id] = time()
    SchlingelOwnAchievements.killProgress[id] = nil

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
