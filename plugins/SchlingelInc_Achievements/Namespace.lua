-- Namespace.lua
-- Namespace, shared constants, and SavedVariable init for the Achievements framework.
-- Loaded first; all other files in this addon depend on these values.
--
-- Catalog (achievement definitions) is account-wide: officers create/edit/retire
-- entries and broadcast them to the guild, so every character on the account shares
-- the same catalog without re-syncing per alt.
-- Progress is mixed: entries with `isGlobal` are account-wide (all characters),
-- while non-global entries stay per-character.

SchlingelInc.Achievements = {}

SchlingelInc.Achievements.KIND = {
    LEVEL      = "level",       -- criteria: level (threshold), requireNoDeath (bool)
    KILL_COUNT = "kill_count",  -- criteria: npcID, count (required kills)
    MANUAL     = "manual",      -- no criteria; only unlockable via officer grant (RP achievements)
}

SchlingelInc.Achievements.KIND_LABELS = {
    [SchlingelInc.Achievements.KIND.LEVEL]      = "Level",
    [SchlingelInc.Achievements.KIND.KILL_COUNT] = "Kill-Zähler",
    [SchlingelInc.Achievements.KIND.MANUAL]     = "Manuell (RP)",
}

-- Coerces a stored boolean-ish value (Lua true, or "1"/1 from wire/SavedVariables
-- round-trips) to an actual boolean. Used for isGlobal, requireNoDeath, etc.
function SchlingelInc.Achievements.IsTruthyFlag(value)
    return value == true or value == 1 or value == "1"
end

function SchlingelInc.Achievements.IsGrantableKind(kind)
    local KIND = SchlingelInc.Achievements.KIND
    return kind == KIND.LEVEL or kind == KIND.MANUAL or kind == KIND.KILL_COUNT
end

SchlingelAchievementDB         = SchlingelAchievementDB         or {}
SchlingelAchievementDB.entries = SchlingelAchievementDB.entries or {} -- [id] = definition
SchlingelAchievementDB.globalUnlocked     = SchlingelAchievementDB.globalUnlocked     or {} -- [id] = timestamp
SchlingelAchievementDB.globalKillProgress = SchlingelAchievementDB.globalKillProgress or {} -- [id] = count

SchlingelOwnAchievements               = SchlingelOwnAchievements               or {}
SchlingelOwnAchievements.unlocked      = SchlingelOwnAchievements.unlocked      or {} -- [id] = timestamp
SchlingelOwnAchievements.killProgress  = SchlingelOwnAchievements.killProgress  or {} -- [id] = count

function SchlingelInc.Achievements:Initialize()
    SchlingelInc.Achievements.AchievementList:Initialize()
    SchlingelInc.Achievements.Catalog:Initialize()
    SchlingelInc.Achievements.Progress:Initialize()
    SchlingelInc.Achievements.LevelDetector:Initialize()
    SchlingelInc.Achievements.KillDetector:Initialize()
    SchlingelInc.Achievements.ManualGrant:Initialize()
end
