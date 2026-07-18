-- GuildPanel/TabRoster.lua
-- "Mitglieder" tab: the guild roster list (column headers + scrollable rows).

local GP = SchlingelInc.GuildPanel

local TOP_H = 20

function GP.BuildRosterTab(content, f)
    local self = SchlingelInc.GuildPanel

    -- ── Count + offline toggle ──────────────────────────────────────────────
    local countLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countLabel:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -2)
    countLabel:SetTextColor(0.6, 0.6, 0.6, 1)
    f.countLabel = countLabel

    local hideBtn = CreateFrame("Button", nil, content)
    hideBtn:SetSize(50, TOP_H)
    hideBtn:SetPoint("RIGHT", countLabel, "LEFT", -6, 0)
    hideBtn:EnableMouse(true)
    local hideLbl = hideBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hideLbl:SetAllPoints()
    hideLbl:SetJustifyH("RIGHT")
    hideLbl:SetTextColor(0.45, 0.45, 0.45, 1)
    hideLbl:SetText("Offline")
    local function UpdateHideBtnColor()
        hideLbl:SetTextColor(
            GP.hideOffline and 1    or 0.45,
            GP.hideOffline and 0.82 or 0.45,
            GP.hideOffline and 0    or 0.45, 1)
    end
    hideBtn:SetScript("OnClick", function()
        GP.hideOffline = not GP.hideOffline
        UpdateHideBtnColor()
        SchlingelInc.GuildPanel:Refresh()
    end)
    hideBtn:SetScript("OnEnter", function() hideLbl:SetTextColor(1, 1, 0.7, 1) end)
    hideBtn:SetScript("OnLeave", UpdateHideBtnColor)

    -- ── Column headers (clickable — sort asc/desc on each click) ──────────
    self.headerBtns = {}
    local xOff = 4
    for i, col in ipairs(GP.COLUMNS) do
        local btn = CreateFrame("Button", nil, content)
        btn:SetSize(col.width - 2, GP.COL_H)
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", xOff, -(TOP_H + 2))
        btn:EnableMouse(true)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints()
        lbl:SetJustifyH(i == 2 and "CENTER" or "LEFT")
        lbl:SetTextColor(1, 0.82, 0, 1)
        lbl:SetText(col.label)
        btn.lbl = lbl

        local colIdx = i
        btn:SetScript("OnClick", function()
            if GP.sortCol == colIdx then
                GP.sortAsc = not GP.sortAsc
            else
                GP.sortCol = colIdx
                GP.sortAsc = true
            end
            SchlingelInc.GuildPanel:Refresh()
        end)
        btn:SetScript("OnEnter", function() lbl:SetTextColor(1, 1, 0.7, 1) end)
        btn:SetScript("OnLeave", function()
            if GP.sortCol == colIdx then
                lbl:SetTextColor(1, 1, 0.45, 1)
            else
                lbl:SetTextColor(1, 0.82, 0, 1)
            end
        end)

        self.headerBtns[i] = btn
        xOff = xOff + col.width
    end

    local divider = content:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.DIVIDER))
    divider:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -(TOP_H + GP.COL_H + 2))
    divider:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(TOP_H + GP.COL_H + 2))

    -- ── Scroll frame ───────────────────────────────────────────────────────
    local scrollFrame, rosterContent = SchlingelInc.Shared.CreateScrollFrame({
        parent     = content,
        name       = GP.PANEL_NAME .. "Scroll",
        childName  = GP.PANEL_NAME .. "Content",
        step       = GP.ROW_H * 3,
        childWidth = GP.TotalColWidth(),
    })
    scrollFrame:SetPoint("TOPLEFT",     content, "TOPLEFT",     0, -(TOP_H + GP.COL_H + 5))
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 24)

    -- Filter toggle button (bottom right)
    local filterToggleBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    filterToggleBtn:SetSize(70, 20)
    filterToggleBtn:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 2)
    filterToggleBtn:SetText("Filter")
    filterToggleBtn:SetScript("OnClick", function()
        SchlingelInc.GuildPanel:ToggleFilterPanel()
    end)

    f.scrollFrame = scrollFrame
    f.content     = rosterContent
    f.rows        = {}
end
