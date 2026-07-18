-- interfaces/FilterPanel.lua
-- Shared filter panel factory used by GuildPanel and OfficerPanel.

SchlingelInc.Shared = SchlingelInc.Shared or {}

-- config = {
--   panelName  : string        -- prefix for named WoW frames
--   anchorFrame: Frame         -- panel anchors TOPLEFT -> TOPRIGHT of this frame
--   filterState: table         -- receives filterName, filterRoles, filterProf fields
--   onChangeFn : function      -- called whenever any filter value changes
--   showRoles  : bool | nil    -- default true; pass false to omit role toggles
--   getDataFn  : function | nil -- returns array with profName1/profName2; nil = no profession dropdown
-- }
-- Returns the filter panel frame. panel.profList holds the profession dropdown (or nil).
function SchlingelInc.Shared.CreateFilterPanel(config)
    local panelName = config.panelName
    local anchor    = config.anchorFrame
    local state     = config.filterState
    local getDataFn = config.getDataFn
    local showRoles = config.showRoles ~= false
    local onChange  = config.onChangeFn

    local panelWidth = SchlingelInc.Shared.FILTER_PANEL_WIDTH
    local padding     = SchlingelInc.Shared.FILTER_PANEL_PAD
    local innerWidth  = panelWidth - padding * 2

    -- Compute panel height from visible sections
    local height = padding + 18 + 10 + 14 + 4 + 22  -- top pad, title, gap, name label, gap, editbox
    if showRoles  then height = height + 10 + 14 + 4 + 22 end
    if getDataFn  then height = height + 12 + 14 + 4 + 22 end
    height = height + 12 + 22 + padding  -- gap, reset button, bottom pad

    local panel = SchlingelInc.Shared.CreateFilterPanelShell({
        panelName   = panelName .. "Filter",
        anchorFrame = anchor,
        width       = panelWidth,
        height      = height,
    })

    -- ── Title ────────────────────────────────────────────────────────────────
    local titleLabel = SchlingelInc.Shared.CreateFilterTitle(panel)

    -- ── Name search ──────────────────────────────────────────────────────────
    local nameLabel = SchlingelInc.Shared.CreateLabel(panel, "Name:")
    nameLabel:SetPoint("TOPLEFT", titleLabel, "BOTTOMLEFT", 0, -10)

    local nameEditBox = SchlingelInc.Shared.CreateEditBox(panel, innerWidth, 50)
    nameEditBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -4)
    nameEditBox:SetScript("OnTextChanged", function(editBox)
        state.filterName = editBox:GetText():match("^%s*(.-)%s*$") or ""
        onChange()
    end)

    local prevWidget = nameEditBox

    -- ── Role toggles (optional) ───────────────────────────────────────────────
    local roleButtons
    if showRoles then
        local roleLabel = SchlingelInc.Shared.CreateLabel(panel, "Rolle:")
        roleLabel:SetPoint("TOPLEFT", prevWidget, "BOTTOMLEFT", 0, -10)

        roleButtons = {}
        local roles = SchlingelInc.Constants.ROLES
        local roleButtonWidth = math.floor((innerWidth - 4 * (#roles - 1)) / #roles)

        for i, roleName in ipairs(roles) do
            local button = CreateFrame("Button", nil, panel)
            button:SetSize(roleButtonWidth, 22)
            button:SetPoint("TOPLEFT", roleLabel, "BOTTOMLEFT", (i - 1) * (roleButtonWidth + 4), -4)
            button:EnableMouse(true)

            local background = button:CreateTexture(nil, "BACKGROUND")
            background:SetAllPoints()
            background:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.OPTION_BG))

            local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetAllPoints()
            label:SetJustifyH("CENTER")
            label:SetText(roleName)

            button._active = false
            local function UpdateButtonAppearance()
                if button._active then
                    background:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.OPTION_BG_SELECTED))
                    label:SetTextColor(1, 0.82, 0, 1)
                else
                    background:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.OPTION_BG))
                    label:SetTextColor(0.6, 0.6, 0.6, 1)
                end
            end
            button.UpdateAppearance = UpdateButtonAppearance
            UpdateButtonAppearance()

            button:SetScript("OnClick", function()
                button._active = not button._active
                state.filterRoles[roleName] = button._active or nil
                UpdateButtonAppearance()
                onChange()
            end)
            button:SetScript("OnEnter", function() label:SetTextColor(1, 1, 0.7, 1) end)
            button:SetScript("OnLeave", UpdateButtonAppearance)

            roleButtons[i] = button
        end

        prevWidget = roleButtons[1]
    end

    -- ── Profession dropdown (optional) ────────────────────────────────────────
    local professionButton, professionList
    if getDataFn then
        local professionLabel = SchlingelInc.Shared.CreateLabel(panel, "Beruf:")
        professionLabel:SetPoint("TOPLEFT", prevWidget, "BOTTOMLEFT", 0, -12)

        professionButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        professionButton:SetSize(innerWidth, 22)
        professionButton:SetPoint("TOPLEFT", professionLabel, "BOTTOMLEFT", 0, -4)
        professionButton:SetText("Alle Berufe")

        professionList = CreateFrame("Frame", panelName .. "ProfList", UIParent, "BackdropTemplate")
        professionList:SetSize(innerWidth, 10)
        professionList:SetFrameStrata("TOOLTIP")
        professionList:SetBackdrop(SchlingelInc.Constants.DROPDOWNBACKDROP)
        professionList:SetBackdropColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BG))
        professionList:SetBackdropBorderColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BORDER))
        professionList:SetPoint("TOPLEFT", professionButton, "BOTTOMLEFT", 0, -2)
        professionList:Hide()
        professionList.buttons = {}

        local function BuildProfessionList()
            local seen, professions = {}, {}
            local data = getDataFn()
            if data then
                for _, entry in ipairs(data) do
                    for _, professionName in ipairs({ entry.profName1, entry.profName2 }) do
                        if professionName and not seen[professionName] then
                            seen[professionName] = true
                            table.insert(professions, professionName)
                        end
                    end
                end
            end
            table.sort(professions)

            for _, button in ipairs(professionList.buttons) do button:Hide() end
            professionList.buttons = {}

            local itemHeight = 18
            local yOffset     = -4

            local function AddItem(text, onClickFn, isActive)
                local button = CreateFrame("Button", nil, professionList)
                button:SetSize(innerWidth - 8, itemHeight)
                button:SetPoint("TOPLEFT", professionList, "TOPLEFT", 4, yOffset)
                button:EnableMouse(true)
                local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                label:SetAllPoints()
                label:SetJustifyH("LEFT")
                label:SetText(text)
                label:SetTextColor(isActive and 1 or 0.75, isActive and 0.82 or 0.75, isActive and 0 or 0.75, 1)
                button:SetScript("OnClick", onClickFn)
                button:SetScript("OnEnter", function() label:SetTextColor(1, 1, 0.7, 1) end)
                button:SetScript("OnLeave", function()
                    local active = isActive
                    label:SetTextColor(active and 1 or 0.75, active and 0.82 or 0.75, active and 0 or 0.75, 1)
                end)
                table.insert(professionList.buttons, button)
                yOffset = yOffset - itemHeight - 2
            end

            AddItem("Alle Berufe", function()
                state.filterProf = nil
                professionButton:SetText("Alle Berufe")
                professionList:Hide()
                onChange()
            end, state.filterProf == nil)

            for _, professionName in ipairs(professions) do
                local name = professionName
                AddItem(name, function()
                    state.filterProf = name
                    professionButton:SetText(name)
                    professionList:Hide()
                    onChange()
                end, state.filterProf == name)
            end

            professionList:SetHeight(math.abs(yOffset) + 4)
        end

        professionButton:SetScript("OnClick", function()
            if professionList:IsShown() then
                professionList:Hide()
            else
                BuildProfessionList()
                professionList:Show()
            end
        end)

        prevWidget       = professionButton
        panel.profList   = professionList
        SchlingelInc:RegisterOutsideClickClose(professionList, panel)
    end

    -- ── Reset ─────────────────────────────────────────────────────────────────
    local resetButton = SchlingelInc.Shared.CreateFilterResetButton(panel, prevWidget, innerWidth, function()
        state.filterName = ""
        nameEditBox:SetText("")
        if showRoles and roleButtons then
            state.filterRoles = {}
            for _, button in ipairs(roleButtons) do
                button._active = false
                button.UpdateAppearance()
            end
        end
        if getDataFn and professionButton then
            state.filterProf = nil
            professionButton:SetText("Alle Berufe")
            if professionList then professionList:Hide() end
        end
        onChange()
    end)

    return panel
end
