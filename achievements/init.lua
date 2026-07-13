-- Achievements/init.lua
-- Namespace, shared constants, and SavedVariable init for the Achievements framework.
-- Loaded first; all other Achievements/* files depend on these values.
--
-- Catalog (achievement definitions) is account-wide: officers create/edit/retire
-- entries and broadcast them to the guild, so every character on the account shares
-- the same catalog without re-syncing per alt.
-- Progress (which achievements THIS character unlocked) is per-character, mirroring
-- CharacterDeaths/SchlingelOwnSchande — achievements are earned by a character, not
-- shared across an account's alts.

SchlingelInc.Achievements = {}

SchlingelInc.Achievements.KIND = {
    LEVEL      = "level",       -- criteria: level (threshold), requireNoDeath (bool)
    KILL_COUNT = "kill_count",  -- criteria: npcID, count (required kills)
    MANUAL     = "manual",      -- no criteria; only unlockable via officer grant (RP achievements)
}

SchlingelAchievementDB         = SchlingelAchievementDB         or {}
SchlingelAchievementDB.entries = SchlingelAchievementDB.entries or {} -- [id] = definition

SchlingelOwnAchievements               = SchlingelOwnAchievements               or {}
SchlingelOwnAchievements.unlocked      = SchlingelOwnAchievements.unlocked      or {} -- [id] = timestamp
SchlingelOwnAchievements.killProgress  = SchlingelOwnAchievements.killProgress  or {} -- [id] = count

function SchlingelInc.Achievements:Initialize()
    SchlingelInc.Achievements.Catalog:Initialize()
    SchlingelInc.Achievements.Progress:Initialize()
    SchlingelInc.Achievements.LevelDetector:Initialize()
    SchlingelInc.Achievements.KillDetector:Initialize()
    SchlingelInc.Achievements.ManualGrant:Initialize()
end
