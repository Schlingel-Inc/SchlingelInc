-- GuildPanel/FilterPanel.lua
-- Secondary filter panel: name search, role toggles, profession dropdown.

local GP = SchlingelInc.GuildPanel

function SchlingelInc.GuildPanel:CreateFilterPanel()
    if self.filterPanel then return end
    local f    = self.frame
    local FP_W = 190
    local PAD  = 10

    local fp = CreateFrame("Frame", GP.PANEL_NAME .. "Filter", UIParent, "BackdropTemplate")
    fp:SetSize(FP_W, 220)
    fp:SetFrameStrata("HIGH")
    fp:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    fp:SetBackdropColor(0.07, 0.07, 0.07, 0.97)
    fp:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    -- Anchored to main frame's TOPRIGHT so it moves with it
    fp:SetPoint("TOPLEFT", f, "TOPRIGHT", 6, 0)
    fp:Hide()

    local INNER_W = FP_W - PAD * 2

    -- Title
    local titleLbl = fp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLbl:SetPoint("TOPLEFT", fp, "TOPLEFT", PAD, -PAD)
    titleLbl:SetText("Filter")
    titleLbl:SetTextColor(1, 0.82, 0, 1)

    -- ── Name search ──────────────────────────────────────────────────────────
    local nameLbl = fp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLbl:SetPoint("TOPLEFT", titleLbl, "BOTTOMLEFT", 0, -10)
    nameLbl:SetText("Name:")
    nameLbl:SetTextColor(0.8, 0.8, 0.8, 1)

    local nameEB = CreateFrame("EditBox", nil, fp, BackdropTemplateMixin and "BackdropTemplate")
    nameEB:SetSize(INNER_W, 22)
    nameEB:SetPoint("TOPLEFT", nameLbl, "BOTTOMLEFT", 0, -4)
    nameEB:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
    nameEB:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    nameEB:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    nameEB:SetFontObject("GameFontHighlight")
    nameEB:SetTextInsets(6, 6, 0, 0)
    nameEB:SetAutoFocus(false)
    nameEB:SetMaxLetters(50)
    nameEB:SetScript("OnTextChanged", function(eb)
        GP.filterName = eb:GetText():match("^%s*(.-)%s*$") or ""
        SchlingelInc.GuildPanel:Refresh()
    end)
    nameEB:SetScript("OnEscapePressed", function(eb) eb:ClearFocus() end)

    -- ── Role toggles ─────────────────────────────────────────────────────────
    local roleLbl = fp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    roleLbl:SetPoint("TOPLEFT", nameEB, "BOTTOMLEFT", 0, -10)
    roleLbl:SetText("Rolle:")
    roleLbl:SetTextColor(0.8, 0.8, 0.8, 1)

    local roleBtns = {}
    local roles    = SchlingelInc.Constants.ROLES
    local rbW      = math.floor((INNER_W - 4 * (#roles - 1)) / #roles)

    for i, roleName in ipairs(roles) do
        local btn = CreateFrame("Button", nil, fp)
        btn:SetSize(rbW, 22)
        btn:SetPoint("TOPLEFT", roleLbl, "BOTTOMLEFT", (i - 1) * (rbW + 4), -4)
        btn:EnableMouse(true)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.18, 0.18, 0.18, 0.9)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints()
        lbl:SetJustifyH("CENTER")
        lbl:SetText(roleName)

        btn._active = false
        local function UpdateBtn()
            if btn._active then
                bg:SetColorTexture(0.28, 0.20, 0.0, 1)
                lbl:SetTextColor(1, 0.82, 0, 1)
            else
                bg:SetColorTexture(0.18, 0.18, 0.18, 0.9)
                lbl:SetTextColor(0.6, 0.6, 0.6, 1)
            end
        end
        btn.UpdateAppearance = UpdateBtn
        UpdateBtn()

        btn:SetScript("OnClick", function()
            btn._active = not btn._active
            GP.filterRoles[roleName] = btn._active or nil
            UpdateBtn()
            SchlingelInc.GuildPanel:Refresh()
        end)
        btn:SetScript("OnEnter", function() lbl:SetTextColor(1, 1, 0.7, 1) end)
        btn:SetScript("OnLeave", UpdateBtn)

        roleBtns[i] = btn
    end

    -- ── Profession dropdown ───────────────────────────────────────────────────
    local profLbl = fp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    profLbl:SetPoint("TOPLEFT", roleBtns[1], "BOTTOMLEFT", 0, -12)
    profLbl:SetText("Beruf:")
    profLbl:SetTextColor(0.8, 0.8, 0.8, 1)

    local profBtn = CreateFrame("Button", nil, fp, "UIPanelButtonTemplate")
    profBtn:SetSize(INNER_W, 22)
    profBtn:SetPoint("TOPLEFT", profLbl, "BOTTOMLEFT", 0, -4)
    profBtn:SetText("Alle Berufe")

    -- Dropdown list (child of UIParent so it can overflow fp bounds)
    local profList = CreateFrame("Frame", GP.PANEL_NAME .. "ProfList", UIParent, "BackdropTemplate")
    profList:SetSize(INNER_W, 10)
    profList:SetFrameStrata("TOOLTIP")
    profList:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    profList:SetBackdropColor(0.05, 0.05, 0.05, 0.98)
    profList:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    profList:SetPoint("TOPLEFT", profBtn, "BOTTOMLEFT", 0, -2)
    profList:Hide()
    profList.btns = {}

    local function BuildProfList()
        -- Collect unique profession names from current full data
        local seen, profs = {}, {}
        if self.data then
            for _, e in ipairs(self.data) do
                for _, pn in ipairs({ e.profName1, e.profName2 }) do
                    if pn and not seen[pn] then
                        seen[pn] = true
                        table.insert(profs, pn)
                    end
                end
            end
        end
        table.sort(profs)

        for _, b in ipairs(profList.btns) do b:Hide() end
        profList.btns = {}

        local ITEM_H = 18
        local yOff   = -4

        local function addItem(label, onClickFn, isActive)
            local btn = CreateFrame("Button", nil, profList)
            btn:SetSize(INNER_W - 8, ITEM_H)
            btn:SetPoint("TOPLEFT", profList, "TOPLEFT", 4, yOff)
            btn:EnableMouse(true)
            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetAllPoints()
            lbl:SetJustifyH("LEFT")
            lbl:SetText(label)
            lbl:SetTextColor(isActive and 1 or 0.75, isActive and 0.82 or 0.75, isActive and 0 or 0.75, 1)
            btn:SetScript("OnClick", onClickFn)
            btn:SetScript("OnEnter", function() lbl:SetTextColor(1, 1, 0.7, 1) end)
            btn:SetScript("OnLeave", function()
                local a = isActive  -- captured; refreshed per open
                lbl:SetTextColor(a and 1 or 0.75, a and 0.82 or 0.75, a and 0 or 0.75, 1)
            end)
            table.insert(profList.btns, btn)
            yOff = yOff - ITEM_H - 2
        end

        addItem("Alle Berufe", function()
            GP.filterProf = nil
            profBtn:SetText("Alle Berufe")
            profList:Hide()
            SchlingelInc.GuildPanel:Refresh()
        end, GP.filterProf == nil)

        for _, pn in ipairs(profs) do
            local name = pn  -- capture
            addItem(name, function()
                GP.filterProf = name
                profBtn:SetText(name)
                profList:Hide()
                SchlingelInc.GuildPanel:Refresh()
            end, GP.filterProf == name)
        end

        profList:SetHeight(math.abs(yOff) + 4)
    end

    profBtn:SetScript("OnClick", function()
        if profList:IsShown() then
            profList:Hide()
        else
            BuildProfList()
            profList:Show()
        end
    end)

    -- ── Reset ─────────────────────────────────────────────────────────────────
    local resetBtn = CreateFrame("Button", nil, fp, "UIPanelButtonTemplate")
    resetBtn:SetSize(INNER_W, 22)
    resetBtn:SetPoint("TOPLEFT", profBtn, "BOTTOMLEFT", 0, -12)
    resetBtn:SetText("Zurücksetzen")
    resetBtn:SetScript("OnClick", function()
        GP.filterName  = ""
        GP.filterRoles = {}
        GP.filterProf  = nil
        nameEB:SetText("")
        profBtn:SetText("Alle Berufe")
        profList:Hide()
        for _, btn in ipairs(roleBtns) do
            btn._active = false
            btn.UpdateAppearance()
        end
        SchlingelInc.GuildPanel:Refresh()
    end)

    self.filterPanel    = fp
    self.filterProfList = profList
    self.filterNameEB   = nameEB
    self.filterRoleBtns = roleBtns
    self.filterProfBtn  = profBtn
end

function SchlingelInc.GuildPanel:ToggleFilterPanel()
    if not self.filterPanel then self:CreateFilterPanel() end
    if self.filterPanel:IsShown() then
        self.filterPanel:Hide()
        if self.filterProfList then self.filterProfList:Hide() end
    else
        self.filterPanel:Show()
    end
end
