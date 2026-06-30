SchlingelInc.MemberInspector = {}
local MI = SchlingelInc.MemberInspector

local function ProfName(profile, slot)
    if not profile then return nil end
    local name = profile["prof" .. slot]
    if not name then return nil end
    return SchlingelInc.Constants.PROFESSION_NAMES_DE[name] or name
end

local function ProfString(profile, slot)
    if not profile then return nil end
    local name = profile["prof" .. slot]
    if not name then return nil end
    name = SchlingelInc.Constants.PROFESSION_NAMES_DE[name] or name
    local rank = profile["prof" .. slot .. "rank"]
    return rank and (name .. " (" .. rank .. ")") or name
end

function MI.GetProfileEntry(shortName)
    local ownName = UnitName("player")
    if shortName == ownName then
        local p = SchlingelOwnProfile or {}
        return {
            role      = p.role or "",
            prof1     = ProfString(p, 1),
            prof2     = ProfString(p, 2),
            profName1 = ProfName(p, 1),
            profName2 = ProfName(p, 2),
            discord   = DiscordHandle or "",
            deaths    = CharacterDeaths or 0,
        }
    else
        local profile = SchlingelGuildProfileCache and SchlingelGuildProfileCache[shortName]
        return {
            role      = profile and profile.role    or "",
            prof1     = ProfString(profile, 1),
            prof2     = ProfString(profile, 2),
            profName1 = ProfName(profile, 1),
            profName2 = ProfName(profile, 2),
            discord   = profile and profile.discord or "",
            deaths    = profile and profile.deaths,
        }
    end
end

function MI.ShowTooltip(anchor, entry)
    local r, g, b = 1, 1, 1
    local c = RAID_CLASS_COLORS and entry.classToken and RAID_CLASS_COLORS[entry.classToken]
    if c then r, g, b = c.r, c.g, c.b end

    GameTooltip:SetOwner(anchor, "ANCHOR_LEFT", -10, -50)
    GameTooltip:ClearLines()

    GameTooltip:AddLine(entry.name, r, g, b)
    GameTooltip:AddDoubleLine("Klasse:",
        entry.classDisplay ~= "" and entry.classDisplay or "-",
        0.65, 0.65, 0.65, r, g, b)
    GameTooltip:AddDoubleLine("Rang:",
        entry.rank ~= "" and entry.rank or "-",
        0.65, 0.65, 0.65, 1, 1, 1)
    if entry.zone ~= "" then
        GameTooltip:AddDoubleLine("Zone:",
            SchlingelInc:SanitizeText(entry.zone),
            0.65, 0.65, 0.65, 1, 1, 1)
    end

    local safeNote = entry.note ~= "" and SchlingelInc:SanitizeText(entry.note) or nil
    if safeNote and safeNote ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Notiz:", safeNote, 0.65, 0.65, 0.65, 1, 0.9, 0.5, true)
    end

    local hasProfile = entry.role ~= "" or entry.discord ~= "" or entry.prof1 or entry.prof2
    if hasProfile then
        GameTooltip:AddLine(" ")
        if entry.role ~= "" then
            GameTooltip:AddDoubleLine("Rolle:",   entry.role,    0.65, 0.65, 0.65, 1,    1,    1)
        end
        if entry.discord ~= "" then
            GameTooltip:AddDoubleLine("Discord:", entry.discord, 0.65, 0.65, 0.65, 0.55, 0.55, 0.9)
        end
        if entry.prof1 then
            GameTooltip:AddDoubleLine("Beruf 1:", entry.prof1, 0.65, 0.65, 0.65, 0.9, 0.75, 0.4)
        end
        if entry.prof2 then
            GameTooltip:AddDoubleLine("Beruf 2:", entry.prof2, 0.65, 0.65, 0.65, 0.9, 0.75, 0.4)
        end
    end

    if entry.deaths ~= nil then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Tode:", tostring(entry.deaths), 0.65, 0.65, 0.65, 1, 1, 1)
    end

    GameTooltip:Show()
end
