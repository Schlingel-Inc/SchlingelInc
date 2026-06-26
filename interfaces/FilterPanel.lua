-- interfaces/FilterPanel.lua
-- Shared filter panel factory used by GuildPanel and OfficerPanel.

SchlingelInc.Shared = SchlingelInc.Shared or {}

-- cfg = {
--   panelName  : string        -- prefix for named WoW frames
--   anchorFrame: Frame         -- panel anchors TOPLEFT -> TOPRIGHT of this frame
--   filterState: table         -- receives filterName, filterRoles, filterProf fields
--   onChangeFn : function      -- called whenever any filter value changes
--   showRoles  : bool | nil    -- default true; pass false to omit role toggles
--   getDataFn  : function | nil -- returns array with profName1/profName2; nil = no profession dropdown
-- }
-- Returns the filter panel frame. fp.profList holds the profession dropdown (or nil).
function SchlingelInc.Shared.CreateFilterPanel(cfg)
    local panelName = cfg.panelName
    local anchor    = cfg.anchorFrame
    local state     = cfg.filterState
    local getDataFn = cfg.getDataFn
    local showRoles = cfg.showRoles ~= false
    local onChange  = cfg.onChangeFn

    local FP_W   = 190
    local PAD    = 10
    local INNER_W = FP_W - PAD * 2

    -- Compute panel height from visible sections
    local h = PAD + 18 + 10 + 14 + 4 + 22  -- top pad, title, gap, name lbl, gap, editbox
    if showRoles  then h = h + 10 + 14 + 4 + 22 end
    if getDataFn  then h = h + 12 + 14 + 4 + 22 end
    h = h + 12 + 22 + PAD  -- gap, reset btn, bottom pad

    local fp = CreateFrame("Frame", panelName .. "Filter", UIParent, "BackdropTemplate")
    fp:SetSize(FP_W, h)
    fp:SetFrameStrata("HIGH")
    fp:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    fp:SetBackdropColor(0.07, 0.07, 0.07, 0.97)
    fp:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    fp:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 6, 0)
    fp:Hide()
    fp:SetScript("OnHide", function()
        if fp.profList then fp.profList:Hide() end
    end)
    SchlingelInc:RegisterFrameForEscape(fp)

    -- ── Title ────────────────────────────────────────────────────────────────
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
        state.filterName = eb:GetText():match("^%s*(.-)%s*$") or ""
        onChange()
    end)
    nameEB:SetScript("OnEscapePressed", function(eb) eb:ClearFocus() end)

    local prevWidget = nameEB

    -- ── Role toggles (optional) ───────────────────────────────────────────────
    local roleBtns
    if showRoles then
        local roleLbl = fp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        roleLbl:SetPoint("TOPLEFT", prevWidget, "BOTTOMLEFT", 0, -10)
        roleLbl:SetText("Rolle:")
        roleLbl:SetTextColor(0.8, 0.8, 0.8, 1)

        roleBtns = {}
        local roles = SchlingelInc.Constants.ROLES
        local rbW   = math.floor((INNER_W - 4 * (#roles - 1)) / #roles)

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
                state.filterRoles[roleName] = btn._active or nil
                UpdateBtn()
                onChange()
            end)
            btn:SetScript("OnEnter", function() lbl:SetTextColor(1, 1, 0.7, 1) end)
            btn:SetScript("OnLeave", UpdateBtn)

            roleBtns[i] = btn
        end

        prevWidget = roleBtns[1]
    end

    -- ── Profession dropdown (optional) ────────────────────────────────────────
    local profBtn, profList
    if getDataFn then
        local profLbl = fp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        profLbl:SetPoint("TOPLEFT", prevWidget, "BOTTOMLEFT", 0, -12)
        profLbl:SetText("Beruf:")
        profLbl:SetTextColor(0.8, 0.8, 0.8, 1)

        profBtn = CreateFrame("Button", nil, fp, "UIPanelButtonTemplate")
        profBtn:SetSize(INNER_W, 22)
        profBtn:SetPoint("TOPLEFT", profLbl, "BOTTOMLEFT", 0, -4)
        profBtn:SetText("Alle Berufe")

        profList = CreateFrame("Frame", panelName .. "ProfList", UIParent, "BackdropTemplate")
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
            local seen, profs = {}, {}
            local data = getDataFn()
            if data then
                for _, e in ipairs(data) do
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
                    local a = isActive
                    lbl:SetTextColor(a and 1 or 0.75, a and 0.82 or 0.75, a and 0 or 0.75, 1)
                end)
                table.insert(profList.btns, btn)
                yOff = yOff - ITEM_H - 2
            end

            addItem("Alle Berufe", function()
                state.filterProf = nil
                profBtn:SetText("Alle Berufe")
                profList:Hide()
                onChange()
            end, state.filterProf == nil)

            for _, pn in ipairs(profs) do
                local name = pn
                addItem(name, function()
                    state.filterProf = name
                    profBtn:SetText(name)
                    profList:Hide()
                    onChange()
                end, state.filterProf == name)
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

        prevWidget  = profBtn
        fp.profList = profList
    end

    -- ── Reset ─────────────────────────────────────────────────────────────────
    local resetBtn = CreateFrame("Button", nil, fp, "UIPanelButtonTemplate")
    resetBtn:SetSize(INNER_W, 22)
    resetBtn:SetPoint("TOPLEFT", prevWidget, "BOTTOMLEFT", 0, -12)
    resetBtn:SetText("Zurücksetzen")
    resetBtn:SetScript("OnClick", function()
        state.filterName = ""
        nameEB:SetText("")
        if showRoles and roleBtns then
            state.filterRoles = {}
            for _, btn in ipairs(roleBtns) do
                btn._active = false
                btn.UpdateAppearance()
            end
        end
        if getDataFn and profBtn then
            state.filterProf = nil
            profBtn:SetText("Alle Berufe")
            if profList then profList:Hide() end
        end
        onChange()
    end)

    return fp
end
