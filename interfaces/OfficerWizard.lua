-- interfaces/OfficerWizard.lua
-- First-run setup wizard for officers.
-- Auto-triggers when CanGuildRemove() and no SchlingelInc rule block exists in guild info.
-- Re-openable via the "Offi-Einrichtung" button in OfficerPanel.

local WizFrame
local steps = {}
local currentStep = 1

local FRAME_W, FRAME_H = 460, 380

local trashFrame = CreateFrame("Frame")
trashFrame:Hide()

local function ClearContent(frame)
    if frame.contentChildren then
        for _, child in ipairs(frame.contentChildren) do
            child:Hide()
            child:SetParent(trashFrame)
        end
    end
    frame.contentChildren = {}
end

local function Track(frame, child)
    frame.contentChildren = frame.contentChildren or {}
    table.insert(frame.contentChildren, child)
end

local function ShowStep(frame, index)
    currentStep = index
    ClearContent(frame)
    local step = steps[index]
    if step then step.render(frame) end

    frame.stepLabel:SetText("Schritt " .. index .. " von " .. #steps)
    frame.backBtn:SetEnabled(index > 1)
    frame.backBtn:SetAlpha(index > 1 and 1 or 0.4)
    frame.nextBtn:SetText(index == #steps and "Fertig" or "Weiter >")
end

local function NextStep(frame)
    local step = steps[currentStep]
    if step and step.onNext and not step.onNext(frame) then return end
    if currentStep < #steps then
        ShowStep(frame, currentStep + 1)
    else
        frame:Hide()
        SchlingelInc:Print("Offi-Einrichtung abgeschlossen. Nutze das Offizier Panel zum Anpassen der Regeln.")
    end
end

local function BuildWizFrame()
    local TITLE_H = 28

    local f = CreateFrame("Frame", "SchlingelIncOfficerWizard", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_W, FRAME_H)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0.07, 0.07, 0.07, 0.96)
    f:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    -- Title bar
    local titleBg = f:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -4)
    titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    titleBg:SetHeight(TITLE_H)
    titleBg:SetColorTexture(0.12, 0.12, 0.12, 1)

    local titleIcon = f:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("LEFT", titleBg, "LEFT", 6, 0)
    titleIcon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\SI_Transp_512_x_512_px.tga")

    local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleIcon, "RIGHT", 4, 0)
    titleText:SetText("Offizier-Einrichtung")
    titleText:SetTextColor(1, 0.82, 0, 1)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    f.stepLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.stepLabel:SetPoint("TOP", f, "TOP", 0, -(TITLE_H + 12))
    f.stepLabel:SetTextColor(0.7, 0.7, 0.7, 1)

    local divTop = f:CreateTexture(nil, "ARTWORK")
    divTop:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    divTop:SetSize(FRAME_W - 40, 1)
    divTop:SetPoint("TOP", f.stepLabel, "BOTTOM", 0, -8)

    local anchor = CreateFrame("Frame", nil, f)
    anchor:SetSize(FRAME_W - 40, 1)
    anchor:SetPoint("TOPLEFT", divTop, "BOTTOMLEFT", 0, 0)
    f.contentAnchor = anchor

    f.backBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.backBtn:SetSize(90, 26)
    f.backBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 16)
    f.backBtn:SetText("< Zurück")
    f.backBtn:SetScript("OnClick", function()
        if currentStep > 1 then ShowStep(f, currentStep - 1) end
    end)

    f.nextBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.nextBtn:SetSize(90, 26)
    f.nextBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 16)
    f.nextBtn:SetText("Weiter >")
    f.nextBtn:SetScript("OnClick", function() NextStep(f) end)

    return f
end

-- ── Step 1: Rank Selection ─────────────────────────────────────────────────────

local function RenderRanks(frame)
    local f = frame.contentAnchor
    local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 20, -16)
    lbl:SetWidth(FRAME_W - 40)
    lbl:SetJustifyH("CENTER")
    lbl:SetText("Welche Ränge sollen Gilden-Beitrittsanfragen erhalten?")
    Track(frame, lbl)

    local numRanks = GuildControlGetNumRanks and GuildControlGetNumRanks() or 0
    frame._rankChecks = {}

    for i = 1, numRanks do
        local rankName = GuildControlGetRankName(i)
        if rankName and rankName ~= "" then
            local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -8 - (#frame._rankChecks) * 28)
            cb:SetSize(24, 24)

            -- Pre-check ranks already saved
            local saved = SchlingelGuildDB and SchlingelGuildDB.officerRanks or {}
            for _, r in ipairs(saved) do
                if r == rankName then cb:SetChecked(true) break end
            end

            cb.rankName = rankName
            local cblbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cblbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            cblbl:SetText(rankName)
            Track(frame, cb)
            table.insert(frame._rankChecks, cb)
        end
    end
end

local function OnNextRanks(frame)
    local selected = {}
    for _, cb in ipairs(frame._rankChecks or {}) do
        if cb:GetChecked() then
            table.insert(selected, cb.rankName)
        end
    end
    SchlingelGuildDB = SchlingelGuildDB or {}
    SchlingelGuildDB.officerRanks = selected
    return true
end

-- ── Step 2: Initial Rules ─────────────────────────────────────────────────────

local function RenderInitialRules(frame)
    local f = frame.contentAnchor
    local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 20, -12)
    lbl:SetWidth(FRAME_W - 40)
    lbl:SetJustifyH("CENTER")
    lbl:SetText("Gildenregeln konfigurieren.\nDiese werden beim Klick auf Fertig in die Gildeninfo gespeichert.")
    Track(frame, lbl)

    local ruleDefs = {
        { label = "Briefkasten sperren" },
        { label = "Auktionshaus sperren" },
        { label = "Handel mit Nicht-Mitgliedern sperren" },
        { label = "Gruppierung mit Nicht-Mitgliedern sperren" },
    }

    frame._initRuleChecks = {}
    for i, rule in ipairs(ruleDefs) do
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -8 - (i - 1) * 28)
        cb:SetSize(24, 24)
        cb:SetChecked(true)

        local cblbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cblbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        cblbl:SetText(rule.label)
        Track(frame, cb)
        table.insert(frame._initRuleChecks, cb)
    end

    local capLbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    capLbl:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -8 - #ruleDefs * 28 - 10)
    capLbl:SetText("Aktuelles Level Cap (0 = keines):")
    Track(frame, capLbl)

    local capEb = CreateFrame("EditBox", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    capEb:SetSize(50, 22)
    capEb:SetPoint("LEFT", capLbl, "RIGHT", 8, 0)
    capEb:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
    capEb:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    capEb:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    capEb:SetFontObject("GameFontHighlight")
    capEb:SetTextInsets(4, 4, 0, 0)
    capEb:SetAutoFocus(false)
    capEb:SetNumeric(true)
    capEb:SetMaxLetters(3)
    capEb:SetText("0")
    Track(frame, capEb)
    frame._capEb = capEb
end

local function OnNextInitialRules(frame)
    if not CanGuildRemove() then return false end
    local checks = frame._initRuleChecks or {}
    local cap = tonumber(frame._capEb and frame._capEb:GetText()) or 0
    return SchlingelInc:WriteGuildInfo(
        checks[1] and checks[1]:GetChecked(),
        checks[2] and checks[2]:GetChecked(),
        checks[3] and checks[3]:GetChecked(),
        checks[4] and checks[4]:GetChecked(),
        cap
    )
end

-- ── Public API ────────────────────────────────────────────────────────────────

function SchlingelInc:BuildOfficerWizardSteps()
    steps = {}
    table.insert(steps, { id = "ranks", render = RenderRanks,        onNext = OnNextRanks })
    table.insert(steps, { id = "rules", render = RenderInitialRules,  onNext = OnNextInitialRules })
end

function SchlingelInc:ShowOfficerWizard()
    if not CanGuildRemove() then return end
    SchlingelInc:BuildOfficerWizardSteps()
    if #steps == 0 then return end
    WizFrame = WizFrame or BuildWizFrame()
    currentStep = 1
    ShowStep(WizFrame, 1)
    WizFrame:Show()
end

-- Auto-trigger on login/reload only: officer + no SchlingelInc rule block in guild info
function SchlingelInc:InitializeOfficerWizard()
    SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
        function(event, isLogin, isReload)
            -- PLAYER_ENTERING_WORLD fires for instance transitions too; only run on actual login/reload
            if isLogin == false and isReload == false then return end
            C_Timer.After(8, function()
                if not CanGuildRemove() then return end
                local info = GetGuildInfoText() or ""
                if not info:find(SchlingelInc.Constants.RULES_KEY .. ":", 1, true) then
                    SchlingelInc:ShowOfficerWizard()
                end
            end)
        end, 0, "OfficerWizardInit")
end
