local OfficerPanel = SchlingelInc.OfficerPanel

local panelWidth   = SchlingelInc.Shared.FILTER_PANEL_WIDTH
local panelPadding = SchlingelInc.Shared.FILTER_PANEL_PAD
local innerWidth   = panelWidth - panelPadding * 2   -- 170
local toggleWidth  = 28
local editBoxWidth = innerWidth - toggleWidth - 4

local function CreatePanelFrame(mainFrame, name, height)
    return SchlingelInc.Shared.CreateFilterPanelShell({
        panelName   = name,
        anchorFrame = mainFrame,
        width       = panelWidth,
        height      = height,
    })
end

-- maxLetters is 0 (unlimited) here; every call site sets its own limit afterward.
local function CreateEditBoxField(parent, width)
    return SchlingelInc.Shared.CreateEditBox(parent, width, 0)
end

local function CreateToggleButton(parent, width, labelA, labelB)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 22)
    button:EnableMouse(true)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.OPTION_BG_SELECTED))
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetAllPoints()
    label:SetJustifyH("CENTER")
    label:SetTextColor(1, 0.82, 0, 1)
    button._stateA = true
    local function Update() label:SetText(button._stateA and labelA or labelB) end
    button.Update  = Update
    Update()
    button:SetScript("OnEnter", function() label:SetTextColor(1, 1, 0.7, 1) end)
    button:SetScript("OnLeave", function() label:SetTextColor(1, 0.82, 0, 1) end)
    return button
end

local function CreateSectionLabel(parent, text, anchorWidget, gap)
    local label = SchlingelInc.Shared.CreateLabel(parent, text)
    label:SetPoint("TOPLEFT", anchorWidget, "BOTTOMLEFT", 0, -(gap or 10))
    return label
end

local function CreateTitle(panel)
    return SchlingelInc.Shared.CreateFilterTitle(panel)
end

local function CreateResetButton(panel, anchorWidget, onReset)
    return SchlingelInc.Shared.CreateFilterResetButton(panel, anchorWidget, innerWidth, onReset)
end

function OfficerPanel.BuildFilters(mainFrame)
    -- ── Inaktiv: name only (shared factory) ───────────────────────────────
    local inactiveFilterPanel = SchlingelInc.Shared.CreateFilterPanel({
        panelName   = "SchlingelIncOfficerInactive",
        anchorFrame = mainFrame,
        filterState = OfficerPanel.inactiveFilter,
        showRoles   = false,
        getDataFn   = nil,
        onChangeFn  = function() OfficerPanel.RefreshInactive() end,
    })
    OfficerPanel.tabFilterPanels.inactive = inactiveFilterPanel

    -- ── Fortschritt: name / level / cap / gold ─────────────────────────────
    local progressFilterPanel = CreatePanelFrame(mainFrame, "SchlingelIncOfficerProgressFilter", 258)
    local progressFilter      = OfficerPanel.progressFilter

    local progressTitle          = CreateTitle(progressFilterPanel)
    local progressNameLabel      = CreateSectionLabel(progressFilterPanel, "Name:", progressTitle, 10)
    local progressNameEditBox    = CreateEditBoxField(progressFilterPanel, innerWidth)
    progressNameEditBox:SetMaxLetters(50)
    progressNameEditBox:SetPoint("TOPLEFT", progressNameLabel, "BOTTOMLEFT", 0, -4)
    progressNameEditBox:SetScript("OnTextChanged", function(editBox)
        progressFilter.filterName = editBox:GetText():match("^%s*(.-)%s*$") or ""
        SchlingelInc.OfficerPanel:RefreshProgress()
    end)

    local progressLevelLabel   = CreateSectionLabel(progressFilterPanel, "Level:", progressNameEditBox, 10)
    local progressLevelEditBox = CreateEditBoxField(progressFilterPanel, editBoxWidth)
    progressLevelEditBox:SetMaxLetters(3)
    progressLevelEditBox:SetNumeric(true)
    progressLevelEditBox:SetPoint("TOPLEFT", progressLevelLabel, "BOTTOMLEFT", 0, -4)
    progressLevelEditBox:SetScript("OnTextChanged", function(editBox)
        progressFilter.levelValue = tonumber(editBox:GetText()) or nil
        SchlingelInc.OfficerPanel:RefreshProgress()
    end)
    local progressLevelToggle = CreateToggleButton(progressFilterPanel, toggleWidth, "<", ">")
    progressLevelToggle:SetPoint("TOPLEFT", progressLevelLabel, "BOTTOMLEFT", editBoxWidth + 4, -4)
    progressLevelToggle:SetScript("OnClick", function()
        progressFilter.levelBelow    = not progressFilter.levelBelow
        progressLevelToggle._stateA  = progressFilter.levelBelow
        progressLevelToggle.Update()
        SchlingelInc.OfficerPanel:RefreshProgress()
    end)

    local progressCapButton = CreateFrame("Button", nil, progressFilterPanel)
    progressCapButton:SetSize(innerWidth, 22)
    progressCapButton:SetPoint("TOPLEFT", progressLevelEditBox, "BOTTOMLEFT", 0, -6)
    progressCapButton:EnableMouse(true)
    local progressCapBackground = progressCapButton:CreateTexture(nil, "BACKGROUND")
    progressCapBackground:SetAllPoints()
    progressCapBackground:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.OPTION_BG))
    local progressCapLabel = progressCapButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    progressCapLabel:SetAllPoints()
    progressCapLabel:SetJustifyH("CENTER")
    progressCapLabel:SetText("Nur Cap")
    local function UpdateCapButtonAppearance()
        if progressFilter.capOnly then
            progressCapBackground:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.OPTION_BG_SELECTED))
            progressCapLabel:SetTextColor(1, 0.82, 0, 1)
        else
            progressCapBackground:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.OPTION_BG))
            progressCapLabel:SetTextColor(0.6, 0.6, 0.6, 1)
        end
    end
    UpdateCapButtonAppearance()
    progressCapButton:SetScript("OnClick", function()
        progressFilter.capOnly = not progressFilter.capOnly
        UpdateCapButtonAppearance()
        SchlingelInc.OfficerPanel:RefreshProgress()
    end)
    progressCapButton:SetScript("OnEnter", function() progressCapLabel:SetTextColor(1, 1, 0.7, 1) end)
    progressCapButton:SetScript("OnLeave", UpdateCapButtonAppearance)

    local progressGoldLabel   = CreateSectionLabel(progressFilterPanel, "Gold (g):", progressCapButton, 10)
    local progressGoldEditBox = CreateEditBoxField(progressFilterPanel, editBoxWidth)
    progressGoldEditBox:SetMaxLetters(8)
    progressGoldEditBox:SetNumeric(true)
    progressGoldEditBox:SetPoint("TOPLEFT", progressGoldLabel, "BOTTOMLEFT", 0, -4)
    progressGoldEditBox:SetScript("OnTextChanged", function(editBox)
        progressFilter.goldValue = tonumber(editBox:GetText()) or nil
        SchlingelInc.OfficerPanel:RefreshProgress()
    end)
    local progressGoldToggle = CreateToggleButton(progressFilterPanel, toggleWidth, "\226\137\164", "\226\137\165")  -- ≤ / ≥
    progressGoldToggle:SetPoint("TOPLEFT", progressGoldLabel, "BOTTOMLEFT", editBoxWidth + 4, -4)
    progressGoldToggle:SetScript("OnClick", function()
        progressFilter.goldBelow     = not progressFilter.goldBelow
        progressGoldToggle._stateA   = progressFilter.goldBelow
        progressGoldToggle.Update()
        SchlingelInc.OfficerPanel:RefreshProgress()
    end)

    CreateResetButton(progressFilterPanel, progressGoldEditBox, function()
        progressFilter.filterName = "";    progressNameEditBox:SetText("")
        progressFilter.levelValue = nil;   progressLevelEditBox:SetText("")
        progressFilter.levelBelow = true;  progressLevelToggle._stateA = true; progressLevelToggle.Update()
        progressFilter.capOnly    = false; UpdateCapButtonAppearance()
        progressFilter.goldValue  = nil;   progressGoldEditBox:SetText("")
        progressFilter.goldBelow  = true;  progressGoldToggle._stateA = true;  progressGoldToggle.Update()
        SchlingelInc.OfficerPanel:RefreshProgress()
    end)

    OfficerPanel.tabFilterPanels.progress = progressFilterPanel

    -- ── Discord: name + min char count ─────────────────────────────────────
    local discordFilterPanel = CreatePanelFrame(mainFrame, "SchlingelIncOfficerDiscordFilter", 176)
    local discordFilter      = OfficerPanel.discordFilter

    local discordTitle        = CreateTitle(discordFilterPanel)
    local discordNameLabel    = CreateSectionLabel(discordFilterPanel, "Name:", discordTitle, 10)
    local discordNameEditBox  = CreateEditBoxField(discordFilterPanel, innerWidth)
    discordNameEditBox:SetMaxLetters(50)
    discordNameEditBox:SetPoint("TOPLEFT", discordNameLabel, "BOTTOMLEFT", 0, -4)
    discordNameEditBox:SetScript("OnTextChanged", function(editBox)
        discordFilter.filterName = editBox:GetText():match("^%s*(.-)%s*$") or ""
        OfficerPanel.RefreshDiscordHandles()
    end)

    local discordCountLabel   = CreateSectionLabel(discordFilterPanel, "Min. Chars:", discordNameEditBox, 10)
    local discordCountEditBox = CreateEditBoxField(discordFilterPanel, innerWidth)
    discordCountEditBox:SetMaxLetters(3)
    discordCountEditBox:SetNumeric(true)
    discordCountEditBox:SetPoint("TOPLEFT", discordCountLabel, "BOTTOMLEFT", 0, -4)
    discordCountEditBox:SetScript("OnTextChanged", function(editBox)
        local value = tonumber(editBox:GetText())
        discordFilter.minCount = (value and value > 0) and value or nil
        OfficerPanel.RefreshDiscordHandles()
    end)

    CreateResetButton(discordFilterPanel, discordCountEditBox, function()
        discordFilter.filterName = ""; discordNameEditBox:SetText("")
        discordFilter.minCount   = nil; discordCountEditBox:SetText("")
        OfficerPanel.RefreshDiscordHandles()
    end)

    OfficerPanel.tabFilterPanels.discord = discordFilterPanel
end
