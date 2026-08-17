-- ManualGrant.lua
-- Officer -> player whisper grant/revoke for manual, level, and kill_count achievements.

SchlingelInc.Achievements.ManualGrant = {}
local ManualGrant = SchlingelInc.Achievements.ManualGrant

local MSG_GRANT = "ACH_GRANT"
local MSG_REVOKE = "ACH_REVOKE"

function ManualGrant:Grant(targetName, achievementId)
    if not CanGuildInvite() then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Keine Berechtigung für diesen Befehl.|r")
        return nil, "Keine Berechtigung."
    end
    if not targetName or targetName == "" then return nil, "Kein Ziel gewählt." end

    local entry = SchlingelInc.Achievements.Catalog:Get(achievementId)
    local grantable = entry and SchlingelInc.Achievements.IsGrantableKind(entry.kind)
    if not entry or not grantable or entry.retired then
        return nil, "Ungültiger Erfolg."
    end

    SchlingelInc:SendAddonMessage(MSG_GRANT .. "|" .. achievementId, "WHISPER", targetName)
    SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
        "Erfolg \"" .. entry.name .. "\" an " .. targetName .. " verliehen.|r")
    return true
end

function ManualGrant:Revoke(targetName, achievementId)
    if not CanGuildInvite() then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Keine Berechtigung für diesen Befehl.|r")
        return nil, "Keine Berechtigung."
    end
    if not targetName or targetName == "" then return nil, "Kein Ziel gewählt." end

    local entry = SchlingelInc.Achievements.Catalog:Get(achievementId)
    local grantable = entry and SchlingelInc.Achievements.IsGrantableKind(entry.kind)
    if not entry or not grantable then
        return nil, "Ungültiger Erfolg."
    end

    SchlingelInc:SendAddonMessage(MSG_REVOKE .. "|" .. achievementId, "WHISPER", targetName)
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
