-- interfaces/OfficerPanel.lua
-- Tabbed officer panel: Rules tab (read/write for officers, read-only for members)
-- and Inactive Members tab (officers only).

SchlingelInc.OfficerPanel = {}

local frame
local PANEL_W, PANEL_H = 420, 340
local currentTab = "rules"

local function IsOfficer()
    return CanGuildRemove()
end

-- ── Frame construction ────────────────────────────────────────────────────────

local function BuildPanel()
    local f = CreateFrame("Frame", "SchlingelIncOfficerPanel", UIParent,
        BackdropTemplateMixin and "BackdropTemplate")
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER")
    f:SetBackdrop(SchlingelInc.Constants.BACKDROP)
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.97)
    f:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SchlingelInc:SaveFramePosition(self, "officerpanel_position")
    end)
    SchlingelInc:RestoreFramePosition(f, "officerpanel_position")
    f:Hide()

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -12)
    title:SetText("Schlingel Inc — Offizier Panel")
    title:SetTextColor(1, 0.82, 0, 1)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Tab buttons and content frames
    local TAB_H = 28
    local tabDefs = { { id = "rules", label = "Regeln" }, { id = "inactive", label = "Inaktive Mitglieder" } }
    local tabBtns = {}
    local tabContents = {}
    local tabY = -40

    for i, tab in ipairs(tabDefs) do
        local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetSize(150, TAB_H)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", 10 + (i - 1) * 160, tabY)
        btn:SetText(tab.label)
        tabBtns[tab.id] = btn

        local content = CreateFrame("Frame", nil, f)
        content:SetPoint("TOPLEFT", f, "TOPLEFT", 10, tabY - TAB_H - 4)
        content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
        content:Hide()
        tabContents[tab.id] = content
    end

    local function SwitchTab(id)
        currentTab = id
        for tid, content in pairs(tabContents) do
            content:SetShown(tid == id)
        end
        for tid, btn in pairs(tabBtns) do
            btn:SetNormalFontObject(tid == id and GameFontHighlight or GameFontNormal)
        end
    end

    -- ── Rules tab content ──────────────────────────────────────────────────
    local rc = tabContents["rules"]
    local officer = IsOfficer()

    local ruleDefs = {
        { label = "Briefkasten sperren",                 dbKey = "mailRule" },
        { label = "Auktionshaus sperren",                dbKey = "auctionHouseRule" },
        { label = "Handel mit Nicht-Mitgliedern sperren",dbKey = "tradeRule" },
        { label = "Gruppierung mit Nicht-Mitgliedern sperren", dbKey = "groupingRule" },
        { label = "Duelle automatisch ablehnen",          dbKey = nil },
    }

    local checkboxes = {}
    local yOff = -8
    for _, rule in ipairs(ruleDefs) do
        local cb = CreateFrame("CheckButton", nil, rc, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", rc, "TOPLEFT", 8, yOff)
        cb:SetSize(24, 24)

        local cblbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cblbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        cblbl:SetText(rule.label)

        if rule.dbKey then
            cb:SetChecked(SchlingelInc.InfoRules[rule.dbKey] == 1)
        else
            cb:SetChecked(SchlingelOptionsDB and SchlingelOptionsDB.auto_decline_duels == true)
        end

        if not officer then
            cb:Disable()
            cblbl:SetTextColor(0.5, 0.5, 0.5, 1)
        end

        checkboxes[rule.label] = cb
        yOff = yOff - 30
    end

    -- Cap level input
    yOff = yOff - 10
    local capLbl = rc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    capLbl:SetPoint("TOPLEFT", rc, "TOPLEFT", 8, yOff)
    capLbl:SetText("Aktuelles Level Cap:")
    if not officer then capLbl:SetTextColor(0.5, 0.5, 0.5, 1) end

    local capEb = CreateFrame("EditBox", nil, rc, BackdropTemplateMixin and "BackdropTemplate")
    capEb:SetSize(50, 22)
    capEb:SetPoint("LEFT", capLbl, "RIGHT", 8, 0)
    capEb:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
    capEb:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    capEb:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    capEb:SetFontObject("GameFontHighlight")
    capEb:SetTextInsets(4, 4, 0, 0)
    capEb:SetAutoFocus(false)
    capEb:SetMaxLetters(3)
    capEb:SetNumeric(true)
    capEb:SetText(tostring(SchlingelInc.Rules.CurrentCap or 0))
    if not officer then capEb:Disable() end

    -- Read-only notice for non-officers
    if not officer then
        yOff = yOff - 40
        local notice = rc:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        notice:SetPoint("TOPLEFT", rc, "TOPLEFT", 8, yOff)
        notice:SetTextColor(0.6, 0.6, 0.6, 1)
        notice:SetText("Nur lesen — Offiziersrechte erforderlich zum Ändern")
    end

    -- Officer-only controls
    if officer then
        local updateBtn = CreateFrame("Button", nil, rc, "UIPanelButtonTemplate")
        updateBtn:SetSize(160, 26)
        updateBtn:SetPoint("BOTTOM", rc, "BOTTOM", 0, 10)
        updateBtn:SetText("Gildeninfo aktualisieren")
        updateBtn:SetScript("OnClick", function()
            local cap = tonumber(capEb:GetText()) or 0
            SchlingelInc:WriteGuildInfo(
                checkboxes["Briefkasten sperren"]:GetChecked(),
                checkboxes["Auktionshaus sperren"]:GetChecked(),
                checkboxes["Handel mit Nicht-Mitgliedern sperren"]:GetChecked(),
                checkboxes["Gruppierung mit Nicht-Mitgliedern sperren"]:GetChecked(),
                cap
            )
            SchlingelOptionsDB = SchlingelOptionsDB or {}
            SchlingelOptionsDB.auto_decline_duels = checkboxes["Duelle automatisch ablehnen"]:GetChecked() == true
        end)

        local wizBtn = CreateFrame("Button", nil, rc, "UIPanelButtonTemplate")
        wizBtn:SetSize(130, 26)
        wizBtn:SetPoint("BOTTOMLEFT", rc, "BOTTOMLEFT", 8, 10)
        wizBtn:SetText("Offi-Einrichtung")
        wizBtn:SetScript("OnClick", function()
            f:Hide()
            SchlingelInc:ShowOfficerWizard()
        end)
    end

    -- ── Inactive Members tab ───────────────────────────────────────────────
    tabBtns["inactive"]:SetScript("OnClick", function()
        SwitchTab("inactive")
        if officer then
            SchlingelInc:ToggleInactivityWindow()
        else
            SchlingelInc:Print("Inaktive Mitglieder sind nur für Offiziere sichtbar.")
        end
    end)

    tabBtns["rules"]:SetScript("OnClick", function() SwitchTab("rules") end)

    SwitchTab("rules")

    return f
end

-- ── Public API ────────────────────────────────────────────────────────────────

function SchlingelInc.OfficerPanel:Toggle()
    if not frame then
        frame = BuildPanel()
    end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
