-- GuildPanel/Data.lua
-- Data fetching, normalization, sorting, and filtering.
-- Reads sort/filter state from SchlingelInc.GuildPanel (set in init.lua).

local GP = SchlingelInc.GuildPanel

-- Returns the translated profession name only (no rank suffix) — used for filter matching.
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

function GP.BuildRosterData()
    local data    = {}
    local n       = GetNumGuildMembers()
    local ownName = UnitName("player")

    for i = 1, n do
        -- Field order (TBC Classic):
        -- 1:name  2:rankName  3:rankIndex  4:level  5:classDisplay(localized)
        -- 6:zone  7:note  8:officerNote  9:isOnline  10:status  11:classToken
        local fullName, rankName, rankIndex, level, classDisplay, zone, note, _, isOnline, _, classToken =
            GetGuildRosterInfo(i)
        if fullName then
            local shortName = SchlingelInc:RemoveRealmFromName(fullName)
            local isOwn     = shortName == ownName

            -- For own character use the per-character SavedVars directly — they are
            -- always current and don't depend on the broadcast having been received yet.
            -- For other players fall back to the guild profile cache.
            local role, prof1, prof2, profName1, profName2, discord, deaths

            if isOwn then
                local p = SchlingelOwnProfile or {}
                role      = p.role or ""
                prof1     = ProfString(p, 1)
                prof2     = ProfString(p, 2)
                profName1 = ProfName(p, 1)
                profName2 = ProfName(p, 2)
                discord   = DiscordHandle or ""
                deaths    = CharacterDeaths or 0
            else
                local profile = SchlingelGuildProfileCache and SchlingelGuildProfileCache[shortName]
                role      = profile and profile.role    or ""
                prof1     = ProfString(profile, 1)
                prof2     = ProfString(profile, 2)
                profName1 = ProfName(profile, 1)
                profName2 = ProfName(profile, 2)
                discord   = profile and profile.discord or ""
                deaths    = profile and profile.deaths  -- nil = no profile received yet
            end

            table.insert(data, {
                name         = shortName,
                level        = level        or 0,
                rank         = rankName     or "",
                rankIndex    = rankIndex    or 99,   -- 0 = highest guild rank
                classDisplay = classDisplay or "",   -- localized (e.g. "Krieger")
                classToken   = classToken   or "",   -- token for color (e.g. "WARRIOR")
                zone         = zone         or "",
                note         = note         or "",
                online       = isOnline == true,  -- normalise: GetGuildRosterInfo may return nil
                role         = role,
                prof1        = prof1,
                prof2        = prof2,
                profName1    = profName1,
                profName2    = profName2,
                discord      = discord,
                deaths       = deaths,  -- nil | number  (nil = no profile data yet)
            })
        end
    end

    return data
end

function GP.SortData(data)
    table.sort(data, function(a, b)
        -- Online players always above offline
        if a.online ~= b.online then return a.online end
        -- Default sort: alphabetical by name
        if GP.sortCol == 0 then return a.name < b.name end

        local va, vb
        if GP.sortCol == 1 then
            va, vb = a.name or "",  b.name or ""
        elseif GP.sortCol == 2 then
            va, vb = a.level or 0,  b.level or 0
        elseif GP.sortCol == 3 then
            va, vb = a.rankIndex, b.rankIndex   -- 0 = highest rank; API-driven, no hardcoding
        elseif GP.sortCol == 4 then
            va, vb = a.zone or "", b.zone or "" -- alphabetical
        elseif GP.sortCol == 5 then
            va = GP.ROLE_ORDER[a.role] or 99
            vb = GP.ROLE_ORDER[b.role] or 99
        elseif GP.sortCol == 6 then
            va = a.deaths or -1
            vb = b.deaths or -1
        else
            return a.name < b.name
        end

        if va == vb then return a.name < b.name end  -- stable tiebreak
        if GP.sortAsc then return va < vb else return va > vb end
    end)
end
