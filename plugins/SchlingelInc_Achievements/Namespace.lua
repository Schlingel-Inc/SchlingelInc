-- Namespace.lua
-- Namespace, shared constants, and SavedVariable init for the Achievements framework.

SchlingelInc.Achievements = {}

SchlingelInc.Achievements.KIND = {
    LEVEL      = "level",
    KILL_COUNT = "kill_count",
    MANUAL     = "manual",
}

SchlingelInc.Achievements.KIND_LABELS = {
    [SchlingelInc.Achievements.KIND.LEVEL]      = "Level",
    [SchlingelInc.Achievements.KIND.KILL_COUNT] = "Kill-Zähler",
    [SchlingelInc.Achievements.KIND.MANUAL]     = "Manuell (RP)",
}

function SchlingelInc.Achievements.IsTruthyFlag(value)
    return value == true or value == 1 or value == "1"
end

function SchlingelInc.Achievements.IsGrantableKind(kind)
    local KIND = SchlingelInc.Achievements.KIND
    return kind == KIND.LEVEL or kind == KIND.MANUAL or kind == KIND.KILL_COUNT
end

SchlingelAchievementDB         = SchlingelAchievementDB         or {}
SchlingelAchievementDB.entries = SchlingelAchievementDB.entries or {}
SchlingelAchievementDB.globalUnlocked     = SchlingelAchievementDB.globalUnlocked     or {}
SchlingelAchievementDB.globalKillProgress = SchlingelAchievementDB.globalKillProgress or {}

SchlingelOwnAchievements               = SchlingelOwnAchievements               or {}
SchlingelOwnAchievements.unlocked      = SchlingelOwnAchievements.unlocked      or {}
SchlingelOwnAchievements.killProgress  = SchlingelOwnAchievements.killProgress  or {}

function SchlingelInc.Achievements:Initialize()
    SchlingelInc.Achievements.AchievementList:Initialize()
    SchlingelInc.Achievements.Catalog:Initialize()
    SchlingelInc.Achievements.Progress:Initialize()
    SchlingelInc.Achievements.LevelDetector:Initialize()
    SchlingelInc.Achievements.KillDetector:Initialize()
    SchlingelInc.Achievements.ManualGrant:Initialize()
end
