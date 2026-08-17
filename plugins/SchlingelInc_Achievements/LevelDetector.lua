-- LevelDetector.lua
-- Auto-detects `level`-kind achievements.

local KIND = SchlingelInc.Achievements.KIND

SchlingelInc.Achievements.LevelDetector = {}
local LevelDetector = SchlingelInc.Achievements.LevelDetector

function LevelDetector:Check()
    local level = UnitLevel("player")
    local Progress = SchlingelInc.Achievements.Progress

    SchlingelInc.Achievements.Catalog:ForEachActive(function(entry)
        if entry.kind == KIND.LEVEL and not Progress:IsUnlocked(entry.id) then
            local threshold      = tonumber(entry.critA)
            local requireNoDeath = SchlingelInc.Achievements.IsTruthyFlag(entry.critB)
            if threshold and level >= threshold and (not requireNoDeath or (CharacterDeaths or 0) == 0) then
                Progress:Unlock(entry.id)
            end
        end
    end)
end

function LevelDetector:Initialize()
    SchlingelInc.EventManager:RegisterHandler("PLAYER_LEVEL_UP",
        function() LevelDetector:Check() end, 0, "AchievementLevelDetectorLevelUp")

    SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
        function()
            C_Timer.After(3, function() LevelDetector:Check() end)
        end, 0, "AchievementLevelDetectorLogin")
end
