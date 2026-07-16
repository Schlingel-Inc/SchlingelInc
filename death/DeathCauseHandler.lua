SchlingelInc.DeathCauseHandler = SchlingelInc.DeathCauseHandler or {}

SchlingelInc.DeathCauseHandler.DeathCause = ""

-- CLEU's environmentalType field is one of this fixed Blizzard-defined set; it has no
-- combat log source unit, so it needs its own display text instead of a sourceName.
local ENVIRONMENTAL_CAUSES = {
    Falling  = "Sturzschaden",
    Drowning = "Ertrinken",
    Fatigue  = "Erschöpfung",
    Fire     = "Feuer",
    Lava     = "Lava",
    Slime    = "Schleim",
}

function SchlingelInc.DeathCauseHandler:Initialize()
    -- Combat log for last attack source
    SchlingelInc.EventManager:RegisterHandler("COMBAT_LOG_EVENT_UNFILTERED",
        function()
            local _, subevent, _, _, sourceName, _, _, destGUID, _, _, _, environmentalType = CombatLogGetCurrentEventInfo()

            if destGUID ~= UnitGUID("player") then return end

            -- Track damage events
            if subevent == "SWING_DAMAGE" or subevent == "RANGE_DAMAGE" or
                subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" then
                SchlingelInc.DeathCauseHandler.DeathCause = sourceName or "Unbekannt"
            elseif subevent == "ENVIRONMENTAL_DAMAGE" then
                SchlingelInc.DeathCauseHandler.DeathCause = ENVIRONMENTAL_CAUSES[environmentalType] or "Umgebung"
            end
        end, 0, "LastAttackTracker")

    -- A hit taken mid-fight (but survived) must not stick around to be misattributed to
    -- a later, unrelated death (e.g. fall damage/drowning after the fight is long over) —
    -- clear once combat ends so only damage from the encounter that actually kills us counts.
    SchlingelInc.EventManager:RegisterHandler("PLAYER_REGEN_ENABLED",
        function() SchlingelInc.DeathCauseHandler.DeathCause = "" end, 0, "LastAttackTrackerCombatEnd")
end