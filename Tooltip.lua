-- Tooltip.lua
-- Shows guild profile data for guild members in unit tooltips.
-- Reads from SchlingelGuildProfileCache (synced via GuildProfiles.lua).

_G.GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    local _, unit = self:GetUnit()
    if not unit then return end

    local guildName, rank = _G.GetGuildInfo(unit)
    if not (guildName and _G.UnitExists(unit) and _G.UnitPlayerControlled(unit)) then return end

    _G.GameTooltip:AddLine(string.format("%s der Gilde %s", rank, guildName), 1, 1, 1)

    if not IsInGuild() then return end

    local playerName = UnitName(unit)
    if not playerName then return end

    local profile = SchlingelGuildProfileCache and
                    SchlingelGuildProfileCache[SchlingelInc:RemoveRealmFromName(playerName)]
    if not profile then return end

    -- Discord Handle
    if profile.discord and profile.discord ~= "" then
        local safe = SchlingelInc:SanitizeText(profile.discord)
        _G.GameTooltip:AddLine(" ")
        _G.GameTooltip:AddLine("Discord:", 0.39, 0.25, 0.65)
        _G.GameTooltip:AddLine(safe, 1, 1, 1)
    end

    -- Role
    if profile.role then
        _G.GameTooltip:AddDoubleLine("Rolle:", profile.role, 0.6, 0.8, 1, 0.6, 0.8, 1)
    end

    -- Professions
    if profile.prof1 then
        local txt = profile.prof1
        if profile.prof1rank then txt = txt .. " (" .. profile.prof1rank .. ")" end
        if profile.prof2 then
            local txt2 = profile.prof2
            if profile.prof2rank then txt2 = txt2 .. " (" .. profile.prof2rank .. ")" end
            txt = txt .. "  |  " .. txt2
        end
        _G.GameTooltip:AddLine(txt, 0.9, 0.75, 0.4)
    end

    -- Deaths
    if profile.deaths and profile.deaths > 0 then
        _G.GameTooltip:AddDoubleLine("Tode:", tostring(profile.deaths), 0.8, 0.2, 0.2, 0.8, 0.2, 0.2)
    end

    -- Dev info: NPC ID shown only to players with the Devschlingel rank
    local _, myRank = _G.GetGuildInfo("player")
    if myRank == "Devschlingel" then
        _G.GameTooltip:AddLine(" ")
        _G.GameTooltip:AddDoubleLine("[Dev] Player ID:", UnitGUID(unit):match("%-(%d+)$") or "?", 0.4, 1, 0.4, 0.7, 0.7, 0.7)
    end
end)

-- Dev info for NPCs: show NPC ID for Devschlingel rank players
_G.GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    local _, unit = self:GetUnit()
    if not unit then return end
    if UnitPlayerControlled(unit) then return end

    local _, myRank = _G.GetGuildInfo("player")
    if myRank ~= "Devschlingel" then return end

    local guid = UnitGUID(unit)
    if not guid then return end

    local npcID = guid:match("Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    if npcID then
        _G.GameTooltip:AddLine(" ")
        _G.GameTooltip:AddDoubleLine("[Dev] NPC ID:", npcID, 0.4, 1, 0.4, 0.7, 0.7, 0.7)
    end
end)
