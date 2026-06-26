local OfficerPanel = SchlingelInc.OfficerPanel

local function BuildInactiveData()
    if not IsInGuild() then return {} end
    local total = GetNumGuildMembers() or 0
    local list  = {}
    for i = 1, total do
        local name, rankName, _, level, _, _, _, _, isOnline = GetGuildRosterInfo(i)
        if name and not isOnline then
            local y, mo, d, h = GetGuildRosterLastOnline(i)
            y, mo, d, h = y or 0, mo or 0, d or 0, h or 0
            local totalDays = y * 365 + mo * 30 + d + h / 24
            if y > 0 or mo > 0 or d >= SchlingelInc.Constants.INACTIVE_DAYS_THRESHOLD then
                local dur = y > 0 and (y .. " J") or mo > 0 and (mo .. " M") or (d .. " T")
                table.insert(list, {
                    name         = SchlingelInc:RemoveRealmFromName(name),
                    fullName     = name,
                    level        = level or 0,
                    rank         = rankName or "?",
                    displayDur   = dur,
                    sortableDays = totalDays,
                })
            end
        end
    end
    table.sort(list, function(a, b)
        if a.sortableDays ~= b.sortableDays then return a.sortableDays > b.sortableDays end
        return a.level > b.level
    end)
    return list
end

function OfficerPanel.BuildInactiveTab(ic)
    local SCROLL_W = OfficerPanel.SCROLL_W

    local COLS = {
        { label = "Name",    x = 0,   w = 140 },
        { label = "Level",   x = 144, w = 36  },
        { label = "Rang",    x = 184, w = 120 },
        { label = "Offline", x = 308, w = 70  },
    }
    for _, col in ipairs(COLS) do
        local hdr = ic:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hdr:SetPoint("TOPLEFT", ic, "TOPLEFT", col.x + 4, -6)
        hdr:SetWidth(col.w)
        hdr:SetJustifyH("LEFT")
        hdr:SetText(col.label)
        hdr:SetTextColor(1, 0.82, 0, 1)
    end

    local hdrDiv = ic:CreateTexture(nil, "ARTWORK")
    hdrDiv:SetHeight(1)
    hdrDiv:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    hdrDiv:SetPoint("TOPLEFT",  ic, "TOPLEFT",  4, -22)
    hdrDiv:SetPoint("TOPRIGHT", ic, "TOPRIGHT", -4, -22)

    local scrollFrame = CreateFrame("ScrollFrame", nil, ic, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     ic, "TOPLEFT",     4, -26)
    scrollFrame:SetPoint("BOTTOMRIGHT", ic, "BOTTOMRIGHT", -20, 36)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        sf:SetVerticalScroll(
            math.max(0, math.min(sf:GetVerticalScrollRange(), sf:GetVerticalScroll() - delta * 20))
        )
    end)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(SCROLL_W)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    ic.scrollChild  = scrollChild
    ic.inactiveRows = {}

    local refreshBtn = CreateFrame("Button", nil, ic, "UIPanelButtonTemplate")
    refreshBtn:SetSize(100, 22)
    refreshBtn:SetPoint("BOTTOMRIGHT", ic, "BOTTOMRIGHT", -4, 8)
    refreshBtn:SetText("Aktualisieren")

    local inFilterBtn = CreateFrame("Button", nil, ic, "UIPanelButtonTemplate")
    inFilterBtn:SetSize(70, 22)
    inFilterBtn:SetPoint("RIGHT", refreshBtn, "LEFT", -4, 0)
    inFilterBtn:SetText("Filter")
    inFilterBtn:SetScript("OnClick", function()
        local fp = OfficerPanel.tabFilterPanels.inactive
        if fp then fp:SetShown(not fp:IsShown()) end
    end)

    local function RefreshInactive()
        for _, row in ipairs(ic.inactiveRows) do row:Hide() end
        wipe(ic.inactiveRows)

        local raw  = BuildInactiveData()
        local srch = (OfficerPanel.inactiveFilter.filterName or ""):lower()
        local list = raw
        if srch ~= "" then
            list = {}
            for _, e in ipairs(raw) do
                if (e.name or ""):lower():find(srch, 1, true) then
                    table.insert(list, e)
                end
            end
        end

        local ROW_H = 20

        if #list == 0 then
            local msg = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            msg:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, 0)
            msg:SetText("Keine inaktiven Mitglieder gefunden.")
            msg:SetTextColor(0.6, 0.6, 0.6, 1)
            table.insert(ic.inactiveRows, msg)
            scrollChild:SetHeight(20)
            return
        end

        for idx, member in ipairs(list) do
            local row = CreateFrame("Frame", nil, scrollChild)
            row:SetSize(SCROLL_W, ROW_H)
            row:SetPoint("TOPLEFT", 0, -(idx - 1) * ROW_H)

            if idx % 2 == 0 then
                local bg = row:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(1, 1, 1, 0.03)
            end

            local function Cell(text, xPos, w, r, g, b)
                local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                fs:SetPoint("LEFT", row, "LEFT", xPos + 4, 0)
                fs:SetWidth(w)
                fs:SetJustifyH("LEFT")
                fs:SetText(text)
                if r then fs:SetTextColor(r, g, b, 1) end
            end

            Cell(member.name,            0,   136)
            Cell(tostring(member.level), 144, 32,  1,   0.82, 0)
            Cell(member.rank,            184, 116)
            Cell(member.displayDur,      308, 66,  0.8, 0.5,  0.5)

            if OfficerPanel.IsOfficer() then
                local kickBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                kickBtn:SetSize(80, ROW_H - 2)
                kickBtn:SetPoint("LEFT", row, "LEFT", 382, 0)
                kickBtn:SetText("Entfernen")
                local fullName = member.fullName
                kickBtn:SetScript("OnClick", function()
                    if not CanGuildRemove() then return end
                    StaticPopup_Show("CONFIRM_GUILD_KICK", fullName, nil, { memberName = fullName })
                end)
            end

            table.insert(ic.inactiveRows, row)
        end

        scrollChild:SetHeight(math.max(1, #list * ROW_H))
        scrollFrame:SetVerticalScroll(0)
    end

    ic.Refresh = RefreshInactive
    OfficerPanel.RefreshInactive = RefreshInactive
    refreshBtn:SetScript("OnClick", RefreshInactive)
end
