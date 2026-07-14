-- Achievements/KillDetector.lua
-- Auto-detects `kill_count`-kind achievements via the combat log. Same detection
-- shape as the guild's CounterDerSchande addon: PARTY_KILL + Creature GUID + npcID.

local KIND = SchlingelInc.Achievements.KIND

SchlingelInc.Achievements.KillDetector = {}
local KillDetector = SchlingelInc.Achievements.KillDetector

-- Same npcID pattern already used for the Dev NPC-ID tooltip line (Tooltip.lua).
local function GetNpcID(destGUID)
    return tonumber(destGUID:match("Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)"))
end

function KillDetector:HandleCombatLogEvent()
    local _, subEvent, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
    if subEvent ~= "PARTY_KILL" then return end
    if not destGUID or not destGUID:find("^Creature") then return end

    local npcID = GetNpcID(destGUID)
    if not npcID then return end

    local Progress = SchlingelInc.Achievements.Progress
    for _, entry in ipairs(SchlingelInc.Achievements.Catalog:GetActive()) do
        if entry.kind == KIND.KILL_COUNT and tonumber(entry.critA) == npcID
                and not Progress:IsUnlocked(entry.id) then
            local required = tonumber(entry.critB) or 0
            local newCount = Progress:IncrementKillProgress(entry.id)
            if newCount >= required then
                Progress:Unlock(entry.id)
            end
        end
    end
end

function KillDetector:Initialize()
    SchlingelInc.EventManager:RegisterHandler("COMBAT_LOG_EVENT_UNFILTERED",
        function() KillDetector:HandleCombatLogEvent() end, 0, "AchievementKillDetector")
end
