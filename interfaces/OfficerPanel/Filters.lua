local OfficerPanel = SchlingelInc.OfficerPanel

local FP_BACKDROP = {
    bgFile   = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

local FP_W     = 190
local FP_PAD   = 10
local FP_IW    = FP_W - FP_PAD * 2   -- 170
local FP_TOG_W = 28
local FP_EB_W  = FP_IW - FP_TOG_W - 4

local function MakeFp(mainFrame, name, h)
    local fp = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    fp:SetSize(FP_W, h)
    fp:SetFrameStrata("HIGH")
    fp:SetBackdrop(FP_BACKDROP)
    fp:SetBackdropColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BG))
    fp:SetBackdropBorderColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BORDER))
    fp:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 6, 0)
    fp:Hide()
    SchlingelInc:RegisterFrameForEscape(fp)
    return fp
end

local function MakeEB(parent, w)
    local eb = CreateFrame("EditBox", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
    eb:SetSize(w, 22)
    eb:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
    eb:SetBackdropColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BG))
    eb:SetBackdropBorderColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BORDER))
    eb:SetFontObject("GameFontHighlight")
    eb:SetTextInsets(6, 6, 0, 0)
    eb:SetAutoFocus(false)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return eb
end

local function MakeToggle(parent, w, labelA, labelB)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w, 22)
    btn:EnableMouse(true)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.OPTION_BG_SELECTED))
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetAllPoints()
    lbl:SetJustifyH("CENTER")
    lbl:SetTextColor(1, 0.82, 0, 1)
    btn._stateA = true
    local function Update() lbl:SetText(btn._stateA and labelA or labelB) end
    btn.Update  = Update
    Update()
    btn:SetScript("OnEnter", function() lbl:SetTextColor(1, 1, 0.7, 1) end)
    btn:SetScript("OnLeave", function() lbl:SetTextColor(1, 0.82, 0, 1) end)
    return btn
end

local function MakeSectionLabel(parent, text, anchorWidget, gap)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", anchorWidget, "BOTTOMLEFT", 0, -(gap or 10))
    lbl:SetText(text)
    lbl:SetTextColor(0.8, 0.8, 0.8, 1)
    return lbl
end

local function MakeTitle(fp)
    local title = fp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", fp, "TOPLEFT", FP_PAD, -FP_PAD)
    title:SetText("Filter")
    title:SetTextColor(1, 0.82, 0, 1)
    return title
end

local function MakeResetButton(fp, anchorWidget, onReset)
    local btn = CreateFrame("Button", nil, fp, "UIPanelButtonTemplate")
    btn:SetSize(FP_IW, 22)
    btn:SetPoint("TOPLEFT", anchorWidget, "BOTTOMLEFT", 0, -12)
    btn:SetText("Zurücksetzen")
    btn:SetScript("OnClick", onReset)
    return btn
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
    local pfFp = MakeFp(mainFrame, "SchlingelIncOfficerProgressFilter", 258)
    local pf   = OfficerPanel.progressFilter

    local pfTitle   = MakeTitle(pfFp)
    local pfNameLbl = MakeSectionLabel(pfFp, "Name:", pfTitle, 10)
    local pfNameEB  = MakeEB(pfFp, FP_IW)
    pfNameEB:SetMaxLetters(50)
    pfNameEB:SetPoint("TOPLEFT", pfNameLbl, "BOTTOMLEFT", 0, -4)
    pfNameEB:SetScript("OnTextChanged", function(eb)
        pf.filterName = eb:GetText():match("^%s*(.-)%s*$") or ""
        SchlingelInc.OfficerPanel:RefreshProgress()
    end)

    local pfLvLbl = MakeSectionLabel(pfFp, "Level:", pfNameEB, 10)
    local pfLvEB  = MakeEB(pfFp, FP_EB_W)
    pfLvEB:SetMaxLetters(3)
    pfLvEB:SetNumeric(true)
    pfLvEB:SetPoint("TOPLEFT", pfLvLbl, "BOTTOMLEFT", 0, -4)
    pfLvEB:SetScript("OnTextChanged", function(eb)
        pf.levelValue = tonumber(eb:GetText()) or nil
        SchlingelInc.OfficerPanel:RefreshProgress()
    end)
    local pfLvTog = MakeToggle(pfFp, FP_TOG_W, "<", ">")
    pfLvTog:SetPoint("TOPLEFT", pfLvLbl, "BOTTOMLEFT", FP_EB_W + 4, -4)
    pfLvTog:SetScript("OnClick", function()
        pf.levelBelow   = not pf.levelBelow
        pfLvTog._stateA = pf.levelBelow
        pfLvTog.Update()
                SchlingelInc.OfficerPanel:RefreshProgress()
    end)

    local pfCapBtn = CreateFrame("Button", nil, pfFp)
    pfCapBtn:SetSize(FP_IW, 22)
    pfCapBtn:SetPoint("TOPLEFT", pfLvEB, "BOTTOMLEFT", 0, -6)
    pfCapBtn:EnableMouse(true)
    local pfCapBg  = pfCapBtn:CreateTexture(nil, "BACKGROUND")
    pfCapBg:SetAllPoints()
    pfCapBg:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.OPTION_BG))
    local pfCapLbl = pfCapBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pfCapLbl:SetAllPoints()
    pfCapLbl:SetJustifyH("CENTER")
    pfCapLbl:SetText("Nur Cap")
    local function UpdateCapBtn()
        if pf.capOnly then
            pfCapBg:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.OPTION_BG_SELECTED))
            pfCapLbl:SetTextColor(1, 0.82, 0, 1)
        else
            pfCapBg:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.OPTION_BG))
            pfCapLbl:SetTextColor(0.6, 0.6, 0.6, 1)
        end
    end
    UpdateCapBtn()
    pfCapBtn:SetScript("OnClick", function()
        pf.capOnly = not pf.capOnly
        UpdateCapBtn()
        SchlingelInc.OfficerPanel:RefreshProgress()
    end)
    pfCapBtn:SetScript("OnEnter", function() pfCapLbl:SetTextColor(1, 1, 0.7, 1) end)
    pfCapBtn:SetScript("OnLeave", UpdateCapBtn)

    local pfGoldLbl = MakeSectionLabel(pfFp, "Gold (g):", pfCapBtn, 10)
    local pfGoldEB  = MakeEB(pfFp, FP_EB_W)
    pfGoldEB:SetMaxLetters(8)
    pfGoldEB:SetNumeric(true)
    pfGoldEB:SetPoint("TOPLEFT", pfGoldLbl, "BOTTOMLEFT", 0, -4)
    pfGoldEB:SetScript("OnTextChanged", function(eb)
        pf.goldValue = tonumber(eb:GetText()) or nil
        SchlingelInc.OfficerPanel:RefreshProgress()
    end)
    local pfGoldTog = MakeToggle(pfFp, FP_TOG_W, "\226\137\164", "\226\137\165")  -- ≤ / ≥
    pfGoldTog:SetPoint("TOPLEFT", pfGoldLbl, "BOTTOMLEFT", FP_EB_W + 4, -4)
    pfGoldTog:SetScript("OnClick", function()
        pf.goldBelow      = not pf.goldBelow
        pfGoldTog._stateA = pf.goldBelow
        pfGoldTog.Update()
        SchlingelInc.OfficerPanel:RefreshProgress()
    end)

    MakeResetButton(pfFp, pfGoldEB, function()
        pf.filterName = "";   pfNameEB:SetText("")
        pf.levelValue = nil;  pfLvEB:SetText("")
        pf.levelBelow = true; pfLvTog._stateA  = true; pfLvTog.Update()
        pf.capOnly    = false; UpdateCapBtn()
        pf.goldValue  = nil;  pfGoldEB:SetText("")
        pf.goldBelow  = true; pfGoldTog._stateA = true; pfGoldTog.Update()
        SchlingelInc.OfficerPanel:RefreshProgress()
    end)

    OfficerPanel.tabFilterPanels.progress = pfFp

    -- ── Discord: name + min char count ─────────────────────────────────────
    local dcFp = MakeFp(mainFrame, "SchlingelIncOfficerDiscordFilter", 176)
    local df   = OfficerPanel.discordFilter

    local dcTitle   = MakeTitle(dcFp)
    local dcNameLbl = MakeSectionLabel(dcFp, "Name:", dcTitle, 10)
    local dcNameEB  = MakeEB(dcFp, FP_IW)
    dcNameEB:SetMaxLetters(50)
    dcNameEB:SetPoint("TOPLEFT", dcNameLbl, "BOTTOMLEFT", 0, -4)
    dcNameEB:SetScript("OnTextChanged", function(eb)
        df.filterName = eb:GetText():match("^%s*(.-)%s*$") or ""
        OfficerPanel.RefreshDiscordHandles()
    end)

    local dcCntLbl = MakeSectionLabel(dcFp, "Min. Chars:", dcNameEB, 10)
    local dcCntEB  = MakeEB(dcFp, FP_IW)
    dcCntEB:SetMaxLetters(3)
    dcCntEB:SetNumeric(true)
    dcCntEB:SetPoint("TOPLEFT", dcCntLbl, "BOTTOMLEFT", 0, -4)
    dcCntEB:SetScript("OnTextChanged", function(eb)
        local v = tonumber(eb:GetText())
        df.minCount = (v and v > 0) and v or nil
        OfficerPanel.RefreshDiscordHandles()
    end)

    MakeResetButton(dcFp, dcCntEB, function()
        df.filterName = ""; dcNameEB:SetText("")
        df.minCount   = nil; dcCntEB:SetText("")
        OfficerPanel.RefreshDiscordHandles()
    end)

    OfficerPanel.tabFilterPanels.discord = dcFp
end
