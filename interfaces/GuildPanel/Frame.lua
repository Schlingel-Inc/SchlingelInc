-- GuildPanel/Frame.lua
-- Main panel: Create(), Refresh(), Toggle(), Initialize().

local GP = SchlingelInc.GuildPanel

local function ComputeFrameWidth()
    GP.FRAME_W = GP.TotalColWidth() + GP.PAD_X + 8  -- extra 8 for visual breathing room
end

-- ── Panel construction ────────────────────────────────────────────────────────

function SchlingelInc.GuildPanel:Create()
    if self.frame then return end
    ComputeFrameWidth()

    local f = CreateFrame("Frame", GP.PANEL_NAME, UIParent, "BackdropTemplate")
    f:SetSize(GP.FRAME_W, GP.FRAME_H)
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0.07, 0.07, 0.07, 0.96)
    f:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)

    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SchlingelOptionsDB = SchlingelOptionsDB or {}
        local point, _, relPoint, x, y = self:GetPoint()
        SchlingelOptionsDB.guildpanel_position = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    -- Restore saved position or default to center
    if SchlingelOptionsDB and SchlingelOptionsDB.guildpanel_position then
        local p = SchlingelOptionsDB.guildpanel_position
        f:ClearAllPoints()
        f:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else
        f:SetPoint("CENTER")
    end

    -- ── Title bar ──────────────────────────────────────────────────────────
    local titleBg = f:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -4)
    titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    titleBg:SetHeight(GP.TITLE_H - 4)
    titleBg:SetColorTexture(0.12, 0.12, 0.12, 1)

    -- Schlingel icon
    local titleIcon = f:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("LEFT", titleBg, "LEFT", 4, 0)
    titleIcon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\SI_Transp_512_x_512_px.tga")

    local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleIcon, "RIGHT", 4, 0)
    titleText:SetText("Schlingel Inc")
    titleText:SetTextColor(1, 0.82, 0, 1)

    local countLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countLabel:SetPoint("RIGHT", titleBg, "RIGHT", -28, 0)
    countLabel:SetTextColor(0.6, 0.6, 0.6, 1)
    self.countLabel = countLabel

    -- Hide-offline toggle (left of count label)
    local hideBtn = CreateFrame("Button", nil, f)
    hideBtn:SetSize(50, GP.TITLE_H - 4)
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

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
        if SchlingelInc.GuildPanel.filterPanel    then SchlingelInc.GuildPanel.filterPanel:Hide()    end
        if SchlingelInc.GuildPanel.filterProfList then SchlingelInc.GuildPanel.filterProfList:Hide() end
    end)

    -- ── Column headers (clickable — sort asc/desc on each click) ──────────
    self.headerBtns = {}
    local xOff = 8
    for i, col in ipairs(GP.COLUMNS) do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(col.width - 2, GP.COL_H)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", xOff, -(GP.TITLE_H + 3))
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

    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    divider:SetPoint("TOPLEFT",  f, "TOPLEFT",  8, -(GP.TITLE_H + GP.COL_H + 3))
    divider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -(GP.TITLE_H + GP.COL_H + 3))

    -- ── Scroll frame ───────────────────────────────────────────────────────
    local scrollTop = GP.TITLE_H + GP.COL_H + 6
    local scrollFrame = CreateFrame("ScrollFrame", GP.PANEL_NAME .. "Scroll", f)
    scrollFrame:SetPoint("TOPLEFT",     f, "TOPLEFT",     8, -scrollTop)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 30)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        local step = GP.ROW_H * 3
        sf:SetVerticalScroll(
            math.max(0, math.min(sf:GetVerticalScrollRange(), sf:GetVerticalScroll() - delta * step))
        )
    end)

    local content = CreateFrame("Frame", GP.PANEL_NAME .. "Content", scrollFrame)
    content:SetWidth(GP.TotalColWidth())
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)

    -- Filter toggle button (bottom right)
    local filterToggleBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    filterToggleBtn:SetSize(70, 20)
    filterToggleBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 6)
    filterToggleBtn:SetText("Filter")
    filterToggleBtn:SetScript("OnClick", function()
        SchlingelInc.GuildPanel:ToggleFilterPanel()
    end)

    f.scrollFrame = scrollFrame
    f.content     = content
    f.rows        = {}
    f:Hide()
    self.frame = f
end

-- ── Rendering ─────────────────────────────────────────────────────────────────

function SchlingelInc.GuildPanel:Refresh()
    if not self.frame then return end

    -- Build full unfiltered roster for the count display
    self.data = GP.BuildRosterData()
    local allData = self.data

    local onlineCount = 0
    for _, e in ipairs(allData) do if e.online then onlineCount = onlineCount + 1 end end
    if self.countLabel then
        self.countLabel:SetText(onlineCount .. " / " .. #allData .. " online")
    end

    -- Apply offline filter
    local data = allData
    if GP.hideOffline then
        data = {}
        for _, e in ipairs(allData) do
            if e.online then table.insert(data, e) end
        end
    end

    -- Apply name search (case-insensitive substring)
    if GP.filterName ~= "" then
        local search = GP.filterName:lower()
        local filtered = {}
        for _, e in ipairs(data) do
            if (e.name or ""):lower():find(search, 1, true) then
                table.insert(filtered, e)
            end
        end
        data = filtered
    end

    -- Apply role filter (any active role must match)
    if next(GP.filterRoles) then
        local filtered = {}
        for _, e in ipairs(data) do
            if GP.filterRoles[e.role] then table.insert(filtered, e) end
        end
        data = filtered
    end

    -- Apply profession filter
    if GP.filterProf then
        local filtered = {}
        for _, e in ipairs(data) do
            if e.profName1 == GP.filterProf or e.profName2 == GP.filterProf then
                table.insert(filtered, e)
            end
        end
        data = filtered
    end

    -- Sort
    GP.SortData(data)

    -- Update header sort indicators
    for i, btn in ipairs(self.headerBtns or {}) do
        if i == GP.sortCol then
            btn.lbl:SetText(GP.COLUMNS[i].label .. (GP.sortAsc and " ^" or " v"))
            btn.lbl:SetTextColor(1, 1, 0.45, 1)
        else
            btn.lbl:SetText(GP.COLUMNS[i].label)
            btn.lbl:SetTextColor(1, 0.82, 0, 1)
        end
    end

    local content = self.frame.content
    local rows    = self.frame.rows

    for i = 1, math.max(#data, #rows) do
        if i <= #data then
            if not rows[i] then rows[i] = GP.CreateRow(content, i) end
            local row   = rows[i]
            local entry = data[i]
            row._entry  = entry

            local nameCol = entry.online and "|cff44ff44" or "|cff888888"
            row.cells[1]:SetText(nameCol .. SchlingelInc:SanitizeText(entry.name) .. "|r")
            row.cells[2]:SetText(tostring(entry.level))
            row.cells[3]:SetText(SchlingelInc:SanitizeText(entry.rank))
            row.cells[4]:SetText(SchlingelInc:SanitizeText(entry.zone))
            row.cells[5]:SetText(entry.role)
            -- Deaths: show the number whenever we have data (including 0),
            -- blank only when nil (no profile received yet for this player)
            row.cells[6]:SetText(entry.deaths ~= nil and tostring(entry.deaths) or "")

            row:SetScript("OnEnter", function()
                row.hl:Show()
                GP.ShowMemberTooltip(row, entry)
            end)
            row:SetScript("OnLeave", function()
                row.hl:Hide()
                GameTooltip:Hide()
            end)
            -- Right-click opens the standard WoW player context menu (Whisper, Invite, etc.)
            row:SetScript("OnMouseDown", function(_, button)
                if button == "RightButton" then
                    SetItemRef("player:" .. entry.name,
                        "|Hplayer:" .. entry.name .. "|h[" .. entry.name .. "]|h",
                        "RightButton")
                end
            end)
            row:Show()
        elseif rows[i] then
            rows[i]:SetScript("OnEnter", nil)
            rows[i]:SetScript("OnLeave", nil)
            rows[i]:SetScript("OnMouseDown", nil)
            rows[i]:Hide()
        end
    end

    content:SetHeight(math.max(1, #data * GP.ROW_H))
    self.frame.scrollFrame:SetVerticalScroll(0)
end

-- ── Toggle / Init ─────────────────────────────────────────────────────────────

function SchlingelInc.GuildPanel:Toggle()
    if not self.frame then self:Create() end
    if self.frame:IsShown() then
        self.frame:Hide()
        if self.filterPanel    then self.filterPanel:Hide()    end
        if self.filterProfList then self.filterProfList:Hide() end
    else
        self:Refresh()
        self.frame:Show()
    end
end

function SchlingelInc.GuildPanel:Initialize()
    SchlingelInc.EventManager:RegisterHandler("GUILD_ROSTER_UPDATE", function()
        if SchlingelInc.GuildPanel.frame and SchlingelInc.GuildPanel.frame:IsShown() then
            C_Timer.After(0, function()
                SchlingelInc.GuildPanel:Refresh()
            end)
        end
    end, 0, "GuildPanelRefresh")
end
