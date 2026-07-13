-- Achievements/LevelDetector.lua
-- Auto-detects `level`-kind achievements. Registers its own independent handlers
-- (EventManager supports multiple handlers per event) rather than hooking into
-- LevelUp.lua, so the Achievements framework stays self-contained.

local KIND = SchlingelInc.Achievements.KIND

SchlingelInc.Achievements.LevelDetector = {}
local LevelDetector = SchlingelInc.Achievements.LevelDetector

-- Re-evaluates every active `level` achievement against the character's current
-- level and death count. CharacterDeaths only ever increases, so checking it "now"
-- is always correct for a requireNoDeath achievement — once you've died, that
-- specific achievement can never become unlockable again, no matter when this runs.
function LevelDetector:Check()
    local level = UnitLevel("player")
    local Progress = SchlingelInc.Achievements.Progress

    for _, entry in ipairs(SchlingelInc.Achievements.Catalog:GetActive()) do
        if entry.kind == KIND.LEVEL and not Progress:IsUnlocked(entry.id) then
            local threshold      = tonumber(entry.critA)
            local requireNoDeath = entry.critB == true or entry.critB == 1 or entry.critB == "1"
            if threshold and level >= threshold and (not requireNoDeath or (CharacterDeaths or 0) == 0) then
                Progress:Unlock(entry.id)
            end
        end
    end
end

function LevelDetector:Initialize()
    SchlingelInc.EventManager:RegisterHandler("PLAYER_LEVEL_UP",
        function() LevelDetector:Check() end, 0, "AchievementLevelDetectorLevelUp")

    SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
        function()
            C_Timer.After(3, function() LevelDetector:Check() end)
        end, 0, "AchievementLevelDetectorLogin")
end
