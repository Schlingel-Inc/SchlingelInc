-- Achievements/ManualGrant.lua
-- Officer -> player whisper grant for `manual`-kind (RP) achievements, which have no
-- auto-detectable criteria, and for `level`-kind milestones, so officers can resolve
-- disputed auto-detection (e.g. a death-counter disagreement blocking an UNBROKEN
-- achievement), plus `kill_count` achievements when officers need to resolve missed
-- progress. Mirrors Schande:Impose's officer-whisper
-- pattern.

local KIND = SchlingelInc.Achievements.KIND

SchlingelInc.Achievements.ManualGrant = {}
local ManualGrant = SchlingelInc.Achievements.ManualGrant

local MSG_GRANT = "ACH_GRANT"
local MSG_REVOKE = "ACH_REVOKE"

-- Officer action: grant a `manual`, `level`, or `kill_count` achievement to targetName (must be online).
function ManualGrant:Grant(targetName, achievementId)
    if not CanGuildInvite() then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Keine Berechtigung für diesen Befehl.|r")
        return nil, "Keine Berechtigung."
    end
    if not targetName or targetName == "" then return nil, "Kein Ziel gewählt." end

    local entry = SchlingelInc.Achievements.Catalog:Get(achievementId)
    local grantable = entry and (entry.kind == KIND.MANUAL or entry.kind == KIND.LEVEL or entry.kind == KIND.KILL_COUNT)
    if not entry or not grantable or entry.retired then
        return nil, "Ungültiger Erfolg."
    end

    ChatThrottleLib:SendAddonMessage("ALERT", SchlingelInc.prefix, MSG_GRANT .. "|" .. achievementId, "WHISPER", targetName, "SchlingelInc-Achievements")
    SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
        "Erfolg \"" .. entry.name .. "\" an " .. targetName .. " verliehen.|r")
    return true
end

-- Officer action: revoke a previously unlocked `manual`, `level`, or `kill_count`
-- achievement from targetName (must be online).
function ManualGrant:Revoke(targetName, achievementId)
    if not CanGuildInvite() then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Keine Berechtigung für diesen Befehl.|r")
        return nil, "Keine Berechtigung."
    end
    if not targetName or targetName == "" then return nil, "Kein Ziel gewählt." end

    local entry = SchlingelInc.Achievements.Catalog:Get(achievementId)
    local grantable = entry and (entry.kind == KIND.MANUAL or entry.kind == KIND.LEVEL or entry.kind == KIND.KILL_COUNT)
    if not entry or not grantable then
        return nil, "Ungültiger Erfolg."
    end

    ChatThrottleLib:SendAddonMessage("ALERT", SchlingelInc.prefix, MSG_REVOKE .. "|" .. achievementId, "WHISPER", targetName, "SchlingelInc-Achievements")
    SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
        "Erfolg \"" .. entry.name .. "\" von " .. targetName .. " entfernt.|r")
    return true
end

function ManualGrant:HandleMessage(message)
    local id = message:match("^" .. MSG_GRANT .. "|(.+)$")
    if id then
        SchlingelInc.Achievements.Progress:Unlock(id)
        return true
    end

    id = message:match("^" .. MSG_REVOKE .. "|(.+)$")
    if id then
        SchlingelInc.Achievements.Progress:Revoke(id)
        return true
    end

    return false
end

function ManualGrant:Initialize()
    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
        function(_, prefix, message, _, sender)
            if prefix ~= SchlingelInc.prefix then return end
            ManualGrant:HandleMessage(message)
        end, 0, "AchievementManualGrantReceive")
end
