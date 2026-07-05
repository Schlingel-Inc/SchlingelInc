SchlingelInc.DeathCauseHandler = SchlingelInc.DeathCauseHandler or {}

SchlingelInc.DeathCauseHandler.DeathCause = ""

-- Combat log for last attack source
SchlingelInc.EventManager:RegisterHandler("COMBAT_LOG_EVENT_UNFILTERED",
    function()
        local _, subevent, _, _, sourceName, _, _, destGUID = CombatLogGetCurrentEventInfo()

        if destGUID ~= UnitGUID("player") then return end

        -- Track damage events
        if subevent == "SWING_DAMAGE" or subevent == "RANGE_DAMAGE" or
            subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" then
            SchlingelInc.DeathCauseHandler.DeathCause = sourceName or "Unbekannt"
        end
    end, 0, "LastAttackTracker")