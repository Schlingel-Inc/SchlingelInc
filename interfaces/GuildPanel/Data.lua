-- GuildPanel/Data.lua
-- Data fetching, normalization, sorting, and filtering.
-- Reads sort/filter state from SchlingelInc.GuildPanel (set in init.lua).

local GP = SchlingelInc.GuildPanel
local MI = SchlingelInc.MemberInspector

function GP.BuildRosterData()
    local data    = {}
    local n       = GetNumGuildMembers()

    for i = 1, n do
        -- Field order (TBC Classic):
        -- 1:name  2:rankName  3:rankIndex  4:level  5:classDisplay(localized)
        -- 6:zone  7:note  8:officerNote  9:isOnline  10:status  11:classToken
        local fullName, rankName, rankIndex, level, classDisplay, zone, note, _, isOnline, _, classToken =
            GetGuildRosterInfo(i)
        if fullName then
            local shortName = SchlingelInc:RemoveRealmFromName(fullName)
            local mi        = MI.GetProfileEntry(shortName)

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
                role         = mi.role,
                prof1        = mi.prof1,
                prof2        = mi.prof2,
                profName1    = mi.profName1,
                profName2    = mi.profName2,
                discord      = mi.discord,
                deaths       = mi.deaths,  -- nil | number  (nil = no profile data yet)
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
            -- sort by best (lowest-order) role when multiple are set
            local function bestOrder(roleStr)
                local best = 99
                for part in (roleStr or ""):gmatch("[^/]+") do
                    local v = GP.ROLE_ORDER[part]; if v and v < best then best = v end
                end
                return best
            end
            va = bestOrder(a.role)
            vb = bestOrder(b.role)
        elseif GP.sortCol == 6 then
            va, vb = (a.discord or ""):lower(), (b.discord or ""):lower()
        elseif GP.sortCol == 7 then
            va = a.deaths or -1
            vb = b.deaths or -1
        else
            return a.name < b.name
        end

        if va == vb then return a.name < b.name end  -- stable tiebreak
        if GP.sortAsc then return va < vb else return va > vb end
    end)
end
