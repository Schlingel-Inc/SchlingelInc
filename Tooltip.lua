-- Tooltip.lua
-- Shows guild profile data for guild members in unit tooltips.
-- Reads from SchlingelGuildProfileCache (synced via GuildProfiles.lua).

_G.GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    local _, unit = self:GetUnit()
    if not unit then return end

    local guildName, rank = _G.GetGuildInfo(unit)
    if not (guildName and _G.UnitExists(unit) and _G.UnitPlayerControlled(unit)) then return end

    _G.GameTooltip:AddLine(string.format("%s der Gilde %s", rank, guildName))

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
        _G.GameTooltip:AddLine("Rolle: " .. profile.role, 0.6, 0.8, 1)
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
        _G.GameTooltip:AddLine("Tode: " .. profile.deaths, 0.8, 0.2, 0.2)
    end
end)
