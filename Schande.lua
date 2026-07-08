-- Schande.lua
-- Per-character Schande record (RP-Tribunal verdicts) and officer <-> player messaging.
-- Own record lives in SchlingelOwnSchande (SavedVariablesPerCharacter) — there is no
-- account-wide cache; each player only ever knows their own Schande state, delivered
-- live by an officer via addon whisper (mirrors /deathset in death/SlashCommands.lua).

SchlingelInc.Schande = {}

-- entries: array of { id = number, freetext = string, active = bool }, oldest first.
-- nextId: the id to assign to the next received verdict (ids are assigned locally
-- by the receiver, so an officer only learns an entry's id from the player after the fact).
-- Patched onto whatever's already saved rather than replaced outright, so earlier
-- pre-release saves (from before entries/nextId existed) still pick up the new fields.
SchlingelOwnSchande = SchlingelOwnSchande or {}
SchlingelOwnSchande.entries = SchlingelOwnSchande.entries or {}
SchlingelOwnSchande.nextId  = SchlingelOwnSchande.nextId or 1

local MSG_IMPOSE  = "SCHANDE_IMPOSE"
local MSG_RESOLVE = "SCHANDE_RESOLVE"

-- Returns the local player's own Schande record ({ entries = {...} }).
function SchlingelInc.Schande:GetOwn()
    return SchlingelOwnSchande
end

-- Returns true if any entry is currently an active (unresolved) Schande.
function SchlingelInc.Schande:IsActive()
    for _, entry in ipairs(SchlingelOwnSchande.entries) do
        if entry.active then return true end
    end
    return false
end

-- Officer action: impose a new Schande verdict on targetName (must be online).
function SchlingelInc.Schande:Impose(targetName, freetext)
    if not CanGuildInvite() then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Keine Berechtigung für diesen Befehl.|r")
        return
    end
    if not targetName or targetName == "" then return end
    freetext = freetext or ""

    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, MSG_IMPOSE .. "|" .. freetext, "WHISPER", targetName)
    SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
        "Schande gegen " .. targetName .. " verhängt.|r")
end

-- Officer action: mark a specific Schande entry (by id) as resolved (target must be online).
function SchlingelInc.Schande:Resolve(targetName, id)
    if not CanGuildInvite() then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Keine Berechtigung für diesen Befehl.|r")
        return
    end
    if not targetName or targetName == "" then return end
    id = tonumber(id)
    if not id then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Ungültige Schande-ID.|r")
        return
    end

    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, MSG_RESOLVE .. "|" .. id, "WHISPER", targetName)
    SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
        "Schande #" .. id .. " von " .. targetName .. " aufgehoben.|r")
end

-- Handle incoming SCHANDE_IMPOSE / SCHANDE_RESOLVE addon whispers (applies to own record).
function SchlingelInc.Schande:HandleMessage(message)
    local resolveIdStr = message:match("^" .. MSG_RESOLVE .. "|(%d+)$")
    if resolveIdStr then
        local id = tonumber(resolveIdStr)
        local found = nil
        for _, entry in ipairs(SchlingelOwnSchande.entries) do
            if entry.id == id then found = entry break end
        end

        if found then
            found.active = false
            SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
                "Deine Schande #" .. id .. " wurde aufgehoben.|r")
        else
            SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING ..
                "Kein Schande-Eintrag mit ID #" .. id .. " gefunden.|r")
        end

        if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshSchande then
            SchlingelInc.GuildPanel:RefreshSchande()
        end
        return true
    end

    local freetext = message:match("^" .. MSG_IMPOSE .. "|(.*)$")
    if freetext then
        local id = SchlingelOwnSchande.nextId or 1
        SchlingelOwnSchande.nextId = id + 1
        table.insert(SchlingelOwnSchande.entries, { id = id, freetext = freetext, active = true })
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING ..
            "Schande #" .. id .. "! Aufgabe: " .. freetext .. "|r")
        if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshSchande then
            SchlingelInc.GuildPanel:RefreshSchande()
        end
        return true
    end

    return false
end

function SchlingelInc.Schande:Initialize()
    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
        function(_, prefix, message, _, _)
            if prefix ~= SchlingelInc.prefix then return end
            SchlingelInc.Schande:HandleMessage(message)
        end, 0, "SchandeReceive")
end
