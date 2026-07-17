-- interfaces/popups/AchievementForm.lua
-- Officer popup to create a new achievement catalog entry, or edit an existing one.

SchlingelInc.Popup = SchlingelInc.Popup or {}

local KIND = SchlingelInc.Achievements.KIND

local KIND_OPTIONS = {
    { value = KIND.LEVEL,      label = "Level" },
    { value = KIND.KILL_COUNT, label = "Kill-Zähler" },
    { value = KIND.MANUAL,     label = "Manuell (RP)" },
}

local FORM_W  = 460
local INNER_W = FORM_W - 32

local function CreateEditBox(parent, width, maxLetters, numeric)
    local eb = CreateFrame("EditBox", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
    eb:SetSize(width, 22)
    eb:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
    eb:SetBackdropColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BG))
    eb:SetBackdropBorderColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BORDER))
    eb:SetFontObject("GameFontHighlight")
    eb:SetTextInsets(6, 6, 0, 0)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(maxLetters)
    if numeric then eb:SetNumeric(true) end
    eb:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    return eb
end

local function CreateLabel(parent, text)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetText(text)
    lbl:SetTextColor(0.8, 0.8, 0.8, 1)
    return lbl
end

local function BuildForm()
    local f = CreateFrame("Frame", "SchlingelAchievementForm", UIParent, "BackdropTemplate")
    f:SetSize(FORM_W, 490)
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop(SchlingelInc.Constants.BACKDROP)
    f:SetBackdropColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BG))
    f:SetBackdropBorderColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BORDER))
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SchlingelInc:SaveFramePosition(self, "achievementform_position")
    end)
    SchlingelInc:RestoreFramePosition(f, "achievementform_position", "CENTER", 0, 80)
    SchlingelInc:RegisterFrameForEscape(f)
    f:Hide()

    local titleFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFs:SetPoint("TOP", f, "TOP", 0, -16)
    titleFs:SetTextColor(1, 0.82, 0, 1)
    f.titleFs = titleFs

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- ── Name ─────────────────────────────────────────────────────────────────
    local nameLbl = CreateLabel(f, "Name:")
    nameLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -48)

    local nameEB = CreateEditBox(f, INNER_W, 60, false)
    nameEB:SetPoint("TOPLEFT", nameLbl, "BOTTOMLEFT", 0, -4)
    f.nameEB = nameEB

    -- ── Beschreibung ─────────────────────────────────────────────────────────
    local descLbl = CreateLabel(f, "Beschreibung (optional):")
    descLbl:SetPoint("TOPLEFT", nameEB, "BOTTOMLEFT", 0, -10)

    local descEB = CreateEditBox(f, INNER_W, 120, false)
    descEB:SetPoint("TOPLEFT", descLbl, "BOTTOMLEFT", 0, -4)
    f.descEB = descEB

    -- ── Punkte ───────────────────────────────────────────────────────────────
    local pointsLbl = CreateLabel(f, "Punkte:")
    pointsLbl:SetPoint("TOPLEFT", descEB, "BOTTOMLEFT", 0, -10)

    local pointsEB = CreateEditBox(f, 80, 5, true)
    pointsEB:SetPoint("TOPLEFT", pointsLbl, "BOTTOMLEFT", 0, -4)
    f.pointsEB = pointsEB

    -- ── Art (dropdown) ───────────────────────────────────────────────────────
    local kindLbl = CreateLabel(f, "Art:")
    kindLbl:SetPoint("TOPLEFT", pointsEB, "TOPLEFT", INNER_W / 2 + 10, 0)

    local kindBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    kindBtn:SetSize(INNER_W / 2 - 10, 22)
    kindBtn:SetPoint("TOPLEFT", pointsLbl, "TOPLEFT", INNER_W / 2 + 10, -4)
    kindBtn:GetFontString():SetWordWrap(false)
    kindBtn:SetNormalFontObject("GameFontHighlightSmall")
    kindBtn:SetHighlightFontObject("GameFontHighlightSmall")
    f.kindBtn = kindBtn

    local globalCb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    globalCb:SetSize(24, 24)
    globalCb:SetPoint("TOPLEFT", pointsEB, "BOTTOMLEFT", 0, -10)
    f.globalCb = globalCb

    local globalLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    globalLbl:SetPoint("LEFT", globalCb, "RIGHT", 2, 0)
    globalLbl:SetText("Global (für alle Charaktere)")
    globalLbl:SetTextColor(0.85, 0.85, 0.85, 1)

    local kindList = CreateFrame("Frame", "SchlingelAchievementFormKindList", UIParent, "BackdropTemplate")
    kindList:SetSize(INNER_W / 2 - 10, 10)
    kindList:SetFrameStrata("TOOLTIP")
    kindList:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    kindList:SetBackdropColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BG))
    kindList:SetBackdropBorderColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BORDER))
    kindList:SetPoint("TOPLEFT", kindBtn, "BOTTOMLEFT", 0, -2)
    kindList:Hide()
    f.kindList = kindList
    SchlingelInc:RegisterOutsideClickClose(kindList, f)

    -- ── Kriterien (dynamic per kind, all anchored at the same point) ────────
    local criteriaAnchor = CreateFrame("Frame", nil, f)
    criteriaAnchor:SetPoint("TOPLEFT", globalCb, "BOTTOMLEFT", 0, -12)
    criteriaAnchor:SetSize(INNER_W, 1)
    f.criteriaAnchor = criteriaAnchor

    -- Level fields
    local levelGroup = CreateFrame("Frame", nil, f)
    levelGroup:SetPoint("TOPLEFT", criteriaAnchor, "TOPLEFT", 0, 0)
    levelGroup:SetSize(INNER_W, 50)
    f.levelGroup = levelGroup

    local levelLbl = CreateLabel(levelGroup, "Level:")
    levelLbl:SetPoint("TOPLEFT", levelGroup, "TOPLEFT", 0, 0)
    local levelEB = CreateEditBox(levelGroup, 60, 2, true)
    levelEB:SetPoint("TOPLEFT", levelLbl, "BOTTOMLEFT", 0, -4)
    f.levelEB = levelEB

    local noDeathCb = CreateFrame("CheckButton", nil, levelGroup, "UICheckButtonTemplate")
    noDeathCb:SetSize(24, 24)
    noDeathCb:SetPoint("LEFT", levelEB, "RIGHT", 20, 0)
    local noDeathLbl = levelGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noDeathLbl:SetPoint("LEFT", noDeathCb, "RIGHT", 2, 0)
    noDeathLbl:SetText("ohne zu sterben")
    f.noDeathCb = noDeathCb

    -- Kill-count fields
    local killGroup = CreateFrame("Frame", nil, f)
    killGroup:SetPoint("TOPLEFT", criteriaAnchor, "TOPLEFT", 0, 0)
    killGroup:SetSize(INNER_W, 50)
    f.killGroup = killGroup

    local npcLbl = CreateLabel(killGroup, "NPC-ID (z.B. von Wowhead):")
    npcLbl:SetPoint("TOPLEFT", killGroup, "TOPLEFT", 0, 0)
    local npcEB = CreateEditBox(killGroup, 100, 8, true)
    npcEB:SetPoint("TOPLEFT", npcLbl, "BOTTOMLEFT", 0, -4)
    f.npcEB = npcEB

    local countLbl = CreateLabel(killGroup, "Benötigte Kills:")
    countLbl:SetPoint("TOPLEFT", npcLbl, "TOPLEFT", INNER_W / 2 + 10, 0)
    local countEB = CreateEditBox(killGroup, 80, 5, true)
    countEB:SetPoint("TOPLEFT", countLbl, "BOTTOMLEFT", 0, -4)
    f.countEB = countEB

    -- Manual note
    local manualGroup = CreateFrame("Frame", nil, f)
    manualGroup:SetPoint("TOPLEFT", criteriaAnchor, "TOPLEFT", 0, 0)
    manualGroup:SetSize(INNER_W, 30)
    f.manualGroup = manualGroup

    local manualLbl = manualGroup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    manualLbl:SetPoint("TOPLEFT", manualGroup, "TOPLEFT", 0, 0)
    manualLbl:SetText("Wird über das Rechtsklick-Menü im Mitglieder-Tab an einzelne Spieler verliehen.")
    manualLbl:SetTextColor(0.7, 0.7, 0.7, 1)

    local function SelectKind(value)
        f.selectedKind = value
        for _, opt in ipairs(KIND_OPTIONS) do
            if opt.value == value then kindBtn:SetText(opt.label) end
        end
        levelGroup:SetShown(value == KIND.LEVEL)
        killGroup:SetShown(value == KIND.KILL_COUNT)
        manualGroup:SetShown(value == KIND.MANUAL)
    end
    f.SelectKind = SelectKind

    local ITEM_H = 18
    local yOff = -4
    for _, opt in ipairs(KIND_OPTIONS) do
        local btn = CreateFrame("Button", nil, kindList)
        btn:SetSize(INNER_W / 2 - 10 - 8, ITEM_H)
        btn:SetPoint("TOPLEFT", kindList, "TOPLEFT", 4, yOff)
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints()
        lbl:SetJustifyH("LEFT")
        lbl:SetText(opt.label)
        lbl:SetTextColor(0.85, 0.85, 0.85, 1)
        btn:SetScript("OnClick", function()
            SelectKind(opt.value)
            kindList:Hide()
        end)
        btn:SetScript("OnEnter", function() lbl:SetTextColor(1, 1, 0.7, 1) end)
        btn:SetScript("OnLeave", function() lbl:SetTextColor(0.85, 0.85, 0.85, 1) end)
        yOff = yOff - ITEM_H - 2
    end
    kindList:SetHeight(math.abs(yOff) + 4)

    kindBtn:SetScript("OnClick", function()
        kindList:SetShown(not kindList:IsShown())
    end)

    -- ── Fehler / Submit ─────────────────────────────────────────────────────
    local errorFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    errorFs:SetPoint("TOPLEFT", criteriaAnchor, "BOTTOMLEFT", 0, -64)
    errorFs:SetWidth(INNER_W)
    errorFs:SetJustifyH("LEFT")
    errorFs:SetTextColor(1, 0.3, 0.3, 1)
    f.errorFs = errorFs

    local submitBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    submitBtn:SetSize(120, 22)
    submitBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
    f.submitBtn = submitBtn

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(90, 22)
    cancelBtn:SetPoint("RIGHT", submitBtn, "LEFT", -8, 0)
    cancelBtn:SetText("Abbrechen")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    submitBtn:SetScript("OnClick", function()
        errorFs:SetText("")

        local name = nameEB:GetText()
        local description = descEB:GetText()
        local points = pointsEB:GetText()
        local kind = f.selectedKind
        local isGlobal = globalCb:GetChecked() and true or false

        if not kind then
            errorFs:SetText("Bitte eine Art auswählen.")
            return
        end

        local critA, critB
        if kind == KIND.LEVEL then
            critA = tonumber(levelEB:GetText())
            critB = noDeathCb:GetChecked() and 1 or 0
            if not critA or critA < 1 or critA > SchlingelInc.Constants.MAX_LEVEL then
                errorFs:SetText("Bitte ein gültiges Level angeben.")
                return
            end
        elseif kind == KIND.KILL_COUNT then
            critA = tonumber(npcEB:GetText())
            critB = tonumber(countEB:GetText())
            if not critA or critA <= 0 then
                errorFs:SetText("Bitte eine gültige NPC-ID angeben.")
                return
            end
            if not critB or critB <= 0 then
                errorFs:SetText("Bitte eine gültige Kill-Anzahl angeben.")
                return
            end
        end

        local ok, err
        if f.editId then
            ok, err = SchlingelInc.Achievements.Catalog:Edit(f.editId, name, description, points, critA, critB, isGlobal)
        else
            ok, err = SchlingelInc.Achievements.Catalog:Create(kind, name, description, points, critA, critB, isGlobal)
        end

        if not ok then
            errorFs:SetText(err or "Unbekannter Fehler.")
            return
        end

        f:Hide()
        if SchlingelInc.OfficerPanel and SchlingelInc.OfficerPanel.RefreshAchievements then
            SchlingelInc.OfficerPanel:RefreshAchievements()
        end
        if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshAchievements then
            SchlingelInc.GuildPanel:RefreshAchievements()
        end
    end)

    return f
end

function SchlingelInc.Popup:ShowAchievementForm(existingEntry)
    if not SchlingelInc.Popup.achievementForm then
        SchlingelInc.Popup.achievementForm = BuildForm()
    end
    local f = SchlingelInc.Popup.achievementForm

    f.errorFs:SetText("")
    f.kindList:Hide()

    if existingEntry then
        f.editId = existingEntry.id
        f.titleFs:SetText("Erfolg bearbeiten")
        f.submitBtn:SetText("Speichern")
        f.nameEB:SetText(existingEntry.name)
        f.descEB:SetText(existingEntry.description or "")
        f.pointsEB:SetText(tostring(existingEntry.points or 0))
        f.SelectKind(existingEntry.kind)
        f.kindBtn:Disable() -- kind can't change after creation (criteria fields are kind-specific)
        f.globalCb:SetChecked(existingEntry.isGlobal == true or existingEntry.isGlobal == 1 or existingEntry.isGlobal == "1")
        if existingEntry.kind == KIND.LEVEL then
            f.levelEB:SetText(tostring(tonumber(existingEntry.critA) or ""))
            f.noDeathCb:SetChecked(existingEntry.critB == true or existingEntry.critB == 1 or existingEntry.critB == "1")
        elseif existingEntry.kind == KIND.KILL_COUNT then
            f.npcEB:SetText(tostring(tonumber(existingEntry.critA) or ""))
            f.countEB:SetText(tostring(tonumber(existingEntry.critB) or ""))
        end
    else
        f.editId = nil
        f.titleFs:SetText("Neuer Erfolg")
        f.submitBtn:SetText("Erstellen")
        f.nameEB:SetText("")
        f.descEB:SetText("")
        f.pointsEB:SetText("")
        f.kindBtn:Enable()
        f.SelectKind(nil)
        f.kindBtn:SetText("Auswählen...")
        f.levelEB:SetText("")
        f.noDeathCb:SetChecked(false)
        f.globalCb:SetChecked(false)
        f.npcEB:SetText("")
        f.countEB:SetText("")
    end

    f:Show()
end
