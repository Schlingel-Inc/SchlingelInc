local OfficerPanel = SchlingelInc.OfficerPanel

local function FormatGoldShort(copper)
    if not copper then return "\226\128\148" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    return string.format("%dg %ds %dc", g, s, c)
end

local function FormatAge(timestamp)
    if not timestamp or timestamp <= 0 then return "\226\128\148" end
    local age = time() - timestamp
    if age < 60    then return "gerade"
    elseif age < 3600 then return math.floor(age / 60)   .. "m"
    else                   return math.floor(age / 3600) .. "h"
    end
end

function OfficerPanel.BuildProgressTab(pc)
    local SCROLL_W = OfficerPanel.SCROLL_W

    local PCOLS = {
        { label = "Name",    x = 0,   w = 88,  sortKey = "name",       justifyH = "LEFT"   },
        { label = "Level",   x = 92,  w = 44,  sortKey = "level",      justifyH = "CENTER" },
        { label = "Runen",   x = 140, w = 42,  sortKey = "runesKnown", justifyH = "CENTER" },
        { label = "XP",      x = 186, w = 79,  sortKey = "xpPct",      justifyH = "CENTER" },
        { label = "%",       x = 265, w = 45,  sortKey = "xpPct",      justifyH = "CENTER" },
        { label = "Gold",    x = 314, w = 88,  sortKey = "gold",       justifyH = "RIGHT"  },
        { label = "Aktuell", x = 398, w = 62,  sortKey = "timestamp",  justifyH = "RIGHT"  },
    }

    local hideOfflineProgress = false
    local progressSortCol     = 2
    local progressSortAsc     = false
    local progressHdrs        = {}

    for i, col in ipairs(PCOLS) do
        local btn = CreateFrame("Button", nil, pc)
        btn:SetPoint("TOPLEFT", pc, "TOPLEFT", col.x + 4, -24)
        btn:SetSize(col.w, 18)
        btn:EnableMouse(true)
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints()
        lbl:SetJustifyH(col.justifyH or "LEFT")
        lbl:SetText(col.label)
        lbl:SetTextColor(1, 0.82, 0, 1)
        progressHdrs[i] = lbl
        local colIdx = i
        btn:SetScript("OnClick", function()
            if progressSortCol == colIdx then
                progressSortAsc = not progressSortAsc
            else
                progressSortCol = colIdx
                progressSortAsc = colIdx == 1
            end
            if OfficerPanel.frame and OfficerPanel.frame:IsShown() then
                OfficerPanel.RefreshProgress()
            end
        end)
        btn:SetScript("OnEnter", function() lbl:SetTextColor(1, 1, 0.7, 1) end)
        btn:SetScript("OnLeave", function()
            lbl:SetTextColor(
                colIdx == progressSortCol and 1    or 1,
                colIdx == progressSortCol and 1    or 0.82,
                colIdx == progressSortCol and 0.45 or 0, 1)
        end)
    end

    local pCountFs = pc:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pCountFs:SetPoint("RIGHT", pc, "TOPRIGHT", -4, -11)
    pCountFs:SetJustifyH("RIGHT")
    pCountFs:SetTextColor(0.6, 0.6, 0.6, 1)
    pc.pCountFs = pCountFs

    local pOfflineBtn = CreateFrame("Button", nil, pc)
    pOfflineBtn:SetSize(50, 18)
    pOfflineBtn:SetPoint("RIGHT", pCountFs, "LEFT", -6, 0)
    pOfflineBtn:EnableMouse(true)
    local pOfflineLbl = pOfflineBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pOfflineLbl:SetAllPoints()
    pOfflineLbl:SetJustifyH("RIGHT")
    pOfflineLbl:SetTextColor(0.45, 0.45, 0.45, 1)
    pOfflineLbl:SetText("Offline")
    local function UpdateOfflineBtn()
        pOfflineLbl:SetTextColor(
            hideOfflineProgress and 1    or 0.45,
            hideOfflineProgress and 0.82 or 0.45,
            hideOfflineProgress and 0    or 0.45, 1)
    end
    pOfflineBtn:SetScript("OnClick", function()
        hideOfflineProgress = not hideOfflineProgress
        UpdateOfflineBtn()
        if OfficerPanel.frame and OfficerPanel.frame:IsShown() then
            OfficerPanel.RefreshProgress()
        end
    end)
    pOfflineBtn:SetScript("OnEnter", function() pOfflineLbl:SetTextColor(1, 1, 0.7, 1) end)
    pOfflineBtn:SetScript("OnLeave", UpdateOfflineBtn)

    local pRequestBtn = CreateFrame("Button", nil, pc, "UIPanelButtonTemplate")
    pRequestBtn:SetSize(96, 18)
    pRequestBtn:SetPoint("RIGHT", pOfflineBtn, "LEFT", -6, 0)
    pRequestBtn:SetText("Anfordern")
    pRequestBtn:SetScript("OnClick", function()
        SchlingelInc.LevelUps:RequestProgress()
        if OfficerPanel.frame and OfficerPanel.frame:IsShown() then
            OfficerPanel.RefreshProgress()
        end
    end)

    local pfFilterBtn = CreateFrame("Button", nil, pc, "UIPanelButtonTemplate")
    pfFilterBtn:SetSize(70, 18)
    pfFilterBtn:SetPoint("RIGHT", pRequestBtn, "LEFT", -6, 0)
    pfFilterBtn:SetText("Filter")
    pfFilterBtn:SetScript("OnClick", function()
        local fp = OfficerPanel.tabFilterPanels.progress
        if fp then fp:SetShown(not fp:IsShown()) end
    end)

    local phdrDiv = pc:CreateTexture(nil, "ARTWORK")
    phdrDiv:SetHeight(1)
    phdrDiv:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    phdrDiv:SetPoint("TOPLEFT",  pc, "TOPLEFT",  4, -44)
    phdrDiv:SetPoint("TOPRIGHT", pc, "TOPRIGHT", -4, -44)

    local pScrollFrame = CreateFrame("ScrollFrame", nil, pc, "UIPanelScrollFrameTemplate")
    pScrollFrame:SetPoint("TOPLEFT",     pc, "TOPLEFT",     4, -48)
    pScrollFrame:SetPoint("BOTTOMRIGHT", pc, "BOTTOMRIGHT", -20, 8)
    pScrollFrame:EnableMouseWheel(true)
    pScrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        sf:SetVerticalScroll(
            math.max(0, math.min(sf:GetVerticalScrollRange(), sf:GetVerticalScroll() - delta * 20))
        )
    end)

    local pScrollChild = CreateFrame("Frame", nil, pScrollFrame)
    pScrollChild:SetWidth(SCROLL_W)
    pScrollChild:SetHeight(1)
    pScrollFrame:SetScrollChild(pScrollChild)

    pc.pScrollChild = pScrollChild
    pc.progressRows = {}

    local BAR_W = 75
    local BAR_X = 190

    local function RefreshProgress()
        for _, row in ipairs(pc.progressRows) do row:Hide() end
        wipe(pc.progressRows)

        local list = {}
        for i = 1, GetNumGuildMembers() or 0 do
            local name, _, _, rosterLevel, _, _, _, _, isOnline = GetGuildRosterInfo(i)
            if name then
                local shortName   = SchlingelInc:RemoveRealmFromName(name)
                local data        = SchlingelInc.LevelUps.progressCache[shortName]
                local level       = rosterLevel or 0
                local xpCurrent, xpMax, xpPct = 0, 0, 0
                local gold, runesKnown, xpStop, timestamp = nil, nil, nil, 0
                local hasProgress = false

                if data then
                    hasProgress = true
                    level       = data.level or level
                    xpCurrent   = data.xpCurrent or 0
                    xpMax       = data.xpMax or 0
                    if xpMax > 0 then
                        xpPct = math.floor(xpCurrent / xpMax * 100)
                    elseif xpMax == 0 and level >= SchlingelInc.Constants.MAX_LEVEL then
                        xpPct = 100
                    end
                    gold       = data.gold
                    runesKnown = data.runesKnown
                    xpStop     = data.xpStop
                    timestamp  = data.timestamp or 0
                end

                table.insert(list, {
                    name        = shortName,
                    level       = level,
                    xpCurrent   = xpCurrent,
                    xpMax       = xpMax,
                    xpPct       = xpPct,
                    gold        = gold,
                    runesKnown  = runesKnown,
                    xpStop      = xpStop,
                    isOnline    = isOnline == true,
                    timestamp   = timestamp,
                    hasProgress = hasProgress,
                })
            end
        end

        local onlineCount = 0
        for _, e in ipairs(list) do if e.isOnline then onlineCount = onlineCount + 1 end end
        if pc.pCountFs then
            pc.pCountFs:SetText(#list .. " (|cff44ff44" .. onlineCount .. " online|r)")
        end

        if hideOfflineProgress then
            local filtered = {}
            for _, e in ipairs(list) do
                if e.isOnline then table.insert(filtered, e) end
            end
            list = filtered
        end

        local pf   = OfficerPanel.progressFilter
        local srch = (pf.filterName or ""):lower()
        if srch ~= "" then
            local out = {}
            for _, e in ipairs(list) do
                if (e.name or ""):lower():find(srch, 1, true) then table.insert(out, e) end
            end
            list = out
        end
        if pf.levelValue then
            local lv  = pf.levelValue
            local out = {}
            for _, e in ipairs(list) do
                if (pf.levelBelow and e.level <= lv) or (not pf.levelBelow and e.level >= lv) then
                    table.insert(out, e)
                end
            end
            list = out
        end
        if pf.capOnly then
            local cap = SchlingelInc.Rules.CurrentCap or 0
            if cap > 0 then
                local out = {}
                for _, e in ipairs(list) do
                    if e.level >= cap then table.insert(out, e) end
                end
                list = out
            end
        end
        if pf.goldValue then
            local gv  = pf.goldValue * 10000
            local out = {}
            for _, e in ipairs(list) do
                local g = e.gold or 0
                if (pf.goldBelow and g <= gv) or (not pf.goldBelow and g >= gv) then
                    table.insert(out, e)
                end
            end
            list = out
        end

        for i, col in ipairs(PCOLS) do
            local active = i == progressSortCol
            local arrow  = active and (progressSortAsc and " ^" or " v") or ""
            progressHdrs[i]:SetText(col.label .. arrow)
            progressHdrs[i]:SetTextColor(active and 1 or 1, active and 1 or 0.82, active and 0.45 or 0, 1)
        end

        local compact = {}
        for _, e in ipairs(list) do
            if type(e) == "table" then table.insert(compact, e) end
        end
        list = compact

        local sortCol  = PCOLS[progressSortCol] or PCOLS[1]
        local key      = sortCol and sortCol.sortKey or "name"
        local ascending = progressSortAsc == true

        -- Manual selection sort avoids Lua's table.sort edge-cases with malformed input.
        local function IsLess(a, b)
            if a == b then return false end
            if type(a) ~= "table" then return false end
            if type(b) ~= "table" then return true end
            local va, vb
            if key == "name" then
                va = tostring(a.name or ""):lower()
                vb = tostring(b.name or ""):lower()
            else
                va = tonumber(a[key]) or 0
                vb = tonumber(b[key]) or 0
            end
            if va ~= vb then return ascending and va < vb or va > vb end
            local na = tostring(a.name or ""):lower()
            local nb = tostring(b.name or ""):lower()
            if na ~= nb then return na < nb end
            local la, lb = tonumber(a.level) or 0, tonumber(b.level) or 0
            if la ~= lb then return la > lb end
            local xa, xb = tonumber(a.xpPct) or 0, tonumber(b.xpPct) or 0
            if xa ~= xb then return xa > xb end
            local ta, tb = tonumber(a.timestamp) or 0, tonumber(b.timestamp) or 0
            if ta ~= tb then return ta > tb end
            return false
        end

        local n = #list
        for i = 1, n - 1 do
            local best = i
            for j = i + 1, n do
                if IsLess(list[j], list[best]) then best = j end
            end
            if best ~= i then list[i], list[best] = list[best], list[i] end
        end

        if #list == 0 then
            local msg = pScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            msg:SetPoint("TOPLEFT", pScrollChild, "TOPLEFT", 4, 0)
            msg:SetText("Noch keine Daten. Klicke auf Anfordern, um alle Online-Mitglieder um ihre Fortschritte zu bitten.")
            msg:SetTextColor(0.6, 0.6, 0.6, 1)
            table.insert(pc.progressRows, msg)
            pScrollChild:SetHeight(20)
            return
        end

        local ROW_H = 22
        local cap   = SchlingelInc.Rules.CurrentCap

        for idx, entry in ipairs(list) do
            local row = CreateFrame("Frame", nil, pScrollChild)
            row:SetSize(SCROLL_W, ROW_H)
            row:SetPoint("TOPLEFT", 0, -(idx - 1) * ROW_H)

            local atCap = cap > 0 and entry.level >= cap
            if atCap and entry.xpStop == false then
                local bg = row:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(0.4, 0.65, 0.9, 0.55)
            elseif idx % 2 == 0 then
                local bg = row:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(1, 1, 1, 0.03)
            end

            local nameFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nameFs:SetPoint("LEFT", row, "LEFT", 4, 0)
            nameFs:SetWidth(84)
            nameFs:SetJustifyH("LEFT")
            nameFs:SetText(entry.name)
            if not entry.isOnline then nameFs:SetTextColor(0.5, 0.5, 0.5, 1) end

            local levelFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            levelFs:SetPoint("LEFT", row, "LEFT", 96, 0)
            levelFs:SetWidth(40)
            levelFs:SetJustifyH("CENTER")
            levelFs:SetText(tostring(entry.level))
            levelFs:SetTextColor(atCap and 1 or 1, atCap and 0.82 or 1, atCap and 0 or 1, 1)

            local runesFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            runesFs:SetPoint("LEFT", row, "LEFT", 144, 0)
            runesFs:SetWidth(38)
            runesFs:SetJustifyH("CENTER")
            if entry.runesKnown ~= nil then
                runesFs:SetText(tostring(entry.runesKnown))
                runesFs:SetTextColor(1, 1, 1, 1)
            else
                runesFs:SetText("\226\128\148")
                runesFs:SetTextColor(0.55, 0.55, 0.55, 1)
            end

            local barBg = row:CreateTexture(nil, "BACKGROUND")
            barBg:SetSize(BAR_W, 8)
            barBg:SetPoint("LEFT", row, "LEFT", BAR_X, 0)
            barBg:SetColorTexture(0.15, 0.15, 0.15, 1)

            local fillW = 0
            if atCap then
                fillW = BAR_W
            elseif entry.hasProgress then
                fillW = math.max(1, math.floor(BAR_W * entry.xpPct / 100))
            end
            local fill = row:CreateTexture(nil, "ARTWORK")
            fill:SetSize(fillW, 8)
            fill:SetPoint("LEFT", barBg, "LEFT", 0, 0)
            fill:SetColorTexture(
                atCap and 1 or 0.2, atCap and 0.82 or 0.75, atCap and 0 or 0.2,
                entry.hasProgress and 1 or 0)

            local pctFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            pctFs:SetPoint("LEFT", row, "LEFT", BAR_X + BAR_W + 4, 0)
            pctFs:SetWidth(41)
            pctFs:SetJustifyH("CENTER")
            if atCap then
                pctFs:SetText("Cap")
                pctFs:SetTextColor(1, 0.82, 0, 1)
            elseif not entry.hasProgress then
                pctFs:SetText("\226\128\148")
                pctFs:SetTextColor(0.55, 0.55, 0.55, 1)
            else
                pctFs:SetText(entry.xpPct .. "%")
                pctFs:SetTextColor(1, 1, 1, 1)
            end

            local goldFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            goldFs:SetPoint("LEFT", row, "LEFT", BAR_X + BAR_W + 50, 0)
            goldFs:SetWidth(86)
            goldFs:SetJustifyH("RIGHT")
            goldFs:SetWordWrap(false)
            goldFs:SetText(FormatGoldShort(entry.gold))
            goldFs:SetTextColor(1, 0.82, 0, 1)

            local ageFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ageFs:SetPoint("LEFT", row, "LEFT", 402, 0)
            ageFs:SetWidth(58)
            ageFs:SetJustifyH("RIGHT")
            ageFs:SetText(FormatAge(entry.timestamp))
            ageFs:SetTextColor(entry.isOnline and 0.5 or 0.8, 0.5, entry.isOnline and 0.5 or 0.2, 1)

            table.insert(pc.progressRows, row)
        end

        pScrollChild:SetHeight(math.max(1, #list * ROW_H))
        pScrollFrame:SetVerticalScroll(0)
    end

    pc.Refresh = RefreshProgress
    OfficerPanel.RefreshProgress = RefreshProgress
end
