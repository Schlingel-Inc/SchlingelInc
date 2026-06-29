local OfficerPanel = SchlingelInc.OfficerPanel

local BACKDROP = {
    bgFile   = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

local function BuildPanel()
    local f = CreateFrame("Frame", "SchlingelIncOfficerPanel", UIParent, "BackdropTemplate")
    f:SetSize(OfficerPanel.PANEL_W, OfficerPanel.PANEL_H)
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetBackdrop(BACKDROP)
    f:SetBackdropColor(0.07, 0.07, 0.07, 0.96)
    f:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SchlingelInc:SaveFramePosition(self, "officerpanel_position")
    end)
    SchlingelInc:RestoreFramePosition(f, "officerpanel_position")
    f:Hide()
    SchlingelInc:RegisterFrameForEscape(f)

    -- ── Title bar ─────────────────────────────────────────────────────────
    local titleBg = f:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -4)
    titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    titleBg:SetHeight(OfficerPanel.TITLE_H)
    titleBg:SetColorTexture(0.12, 0.12, 0.12, 1)

    local titleIcon = f:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("LEFT", titleBg, "LEFT", 6, 0)
    titleIcon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\SI_Transp_512_x_512_px.tga")

    local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleIcon, "RIGHT", 4, 0)
    titleText:SetText("Offizier Panel")
    titleText:SetTextColor(1, 0.82, 0, 1)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- ── Tab buttons ───────────────────────────────────────────────────────
    local tabDefs = {
        { id = "rules",    label = "Regeln"      },
        { id = "inactive", label = "Inaktiv"     },
        { id = "progress", label = "Fortschritt" },
        { id = "discord",  label = "Discord"     },
        { id = "invites",  label = "Anfragen"    },
    }

    local CONTENT_TOP = -(OfficerPanel.TITLE_H + OfficerPanel.TAB_H + 14)
    local TAB_GAP     = 4
    local TAB_BTN_W   = math.floor((OfficerPanel.PANEL_W - 16 - TAB_GAP * (#tabDefs - 1)) / #tabDefs)
    local TAB_STEP    = TAB_BTN_W + TAB_GAP

    for i, tab in ipairs(tabDefs) do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(TAB_BTN_W, OfficerPanel.TAB_H)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", 8 + (i - 1) * TAB_STEP, -(OfficerPanel.TITLE_H + 6))
        btn:EnableMouse(true)

        local tabBg = btn:CreateTexture(nil, "BACKGROUND")
        tabBg:SetAllPoints()
        tabBg:SetColorTexture(0.06, 0.06, 0.06, 1)
        btn.tabBg = tabBg

        local activeLine = btn:CreateTexture(nil, "OVERLAY")
        activeLine:SetHeight(2)
        activeLine:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  2, 0)
        activeLine:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 0)
        activeLine:SetColorTexture(1, 0.82, 0, 1)
        activeLine:Hide()
        btn.activeLine = activeLine

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetAllPoints()
        lbl:SetJustifyH("CENTER")
        lbl:SetText(tab.label)
        btn.lbl = lbl

        OfficerPanel.tabBtns[tab.id] = btn

        local content = CreateFrame("Frame", nil, f)
        content:SetPoint("TOPLEFT",     f, "TOPLEFT",     8, CONTENT_TOP)
        content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)
        content:Hide()
        OfficerPanel.tabContents[tab.id] = content
    end

    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    divider:SetPoint("TOPLEFT",  f, "TOPLEFT",  8, CONTENT_TOP + 2)
    divider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, CONTENT_TOP + 2)

    local function SwitchTab(id)
        for _, fp in pairs(OfficerPanel.tabFilterPanels) do
            if fp and fp:IsShown() then fp:Hide() end
        end
        for tid, c in pairs(OfficerPanel.tabContents) do c:SetShown(tid == id) end
        for tid, btn in pairs(OfficerPanel.tabBtns) do
            local active = tid == id
            btn.lbl:SetTextColor(active and 1 or 0.5, active and 0.82 or 0.5, active and 0 or 0.5, 1)
            btn.tabBg:SetColorTexture(active and 0.14 or 0.06, active and 0.14 or 0.06, active and 0.14 or 0.06, 1)
            btn.activeLine:SetShown(active)
        end
    end

    -- ── Build tab content ─────────────────────────────────────────────────
    OfficerPanel.BuildRulesTab(OfficerPanel.tabContents["rules"])
    OfficerPanel.BuildInactiveTab(OfficerPanel.tabContents["inactive"])
    OfficerPanel.BuildProgressTab(OfficerPanel.tabContents["progress"])
    OfficerPanel.BuildDiscordTab(OfficerPanel.tabContents["discord"])
    OfficerPanel.BuildInvitesTab(OfficerPanel.tabContents["invites"])

    -- ── Wire tab button clicks ────────────────────────────────────────────
    OfficerPanel.tabBtns["rules"]:SetScript("OnClick", function()
        SwitchTab("rules")
    end)

    OfficerPanel.tabBtns["inactive"]:SetScript("OnClick", function()
        if not OfficerPanel.IsOfficer() then
            SchlingelInc:Print("Inaktive Mitglieder sind nur für Offiziere sichtbar.")
            return
        end
        SwitchTab("inactive")
        C_GuildInfo.GuildRoster()
        C_Timer.After(0.3, OfficerPanel.RefreshInactive)
    end)

    OfficerPanel.tabBtns["progress"]:SetScript("OnClick", function()
        if not OfficerPanel.IsOfficer() then
            SchlingelInc:Print("Fortschritt ist nur für Offiziere sichtbar.")
            return
        end
        SwitchTab("progress")
        OfficerPanel.RefreshProgress()
    end)

    OfficerPanel.tabBtns["discord"]:SetScript("OnClick", function()
        if not OfficerPanel.IsOfficer() then
            SchlingelInc:Print("Discord-Übersicht ist nur für Offiziere sichtbar.")
            return
        end
        SwitchTab("discord")
        C_GuildInfo.GuildRoster()
        C_Timer.After(0.3, OfficerPanel.RefreshDiscordHandles)
    end)

    OfficerPanel.tabBtns["invites"]:SetScript("OnClick", function()
        if not OfficerPanel.IsOfficer() then
            SchlingelInc:Print("Anfragen sind nur für Offiziere sichtbar.")
            return
        end
        SwitchTab("invites")
        OfficerPanel.RefreshInvites()
    end)

    -- ── Filter panels ─────────────────────────────────────────────────────
    OfficerPanel.BuildFilters(f)

    f.RefreshInvites  = OfficerPanel.RefreshInvites
    f.RefreshProgress = OfficerPanel.RefreshProgress
    f.RefreshDiscord  = OfficerPanel.RefreshDiscordHandles
    f.SwitchToInvites = function()
        SwitchTab("invites")
        OfficerPanel.RefreshInvites()
    end

    f:HookScript("OnHide", function()
        for _, fp in pairs(OfficerPanel.tabFilterPanels) do
            if fp then fp:Hide() end
        end
    end)

    SwitchTab("rules")
    return f
end

-- ── Public API ────────────────────────────────────────────────────────────────

function SchlingelInc.OfficerPanel:Toggle()
    if not CanGuildInvite() then return end
    if not OfficerPanel.frame then
        OfficerPanel.frame = BuildPanel()
    end
    if OfficerPanel.frame:IsShown() then
        OfficerPanel.frame:Hide()
    else
        OfficerPanel.frame:Show()
    end
end

function SchlingelInc.OfficerPanel:ShowInvites()
    if not CanGuildInvite() then return end
    if not OfficerPanel.frame then OfficerPanel.frame = BuildPanel() end
    if not OfficerPanel.frame:IsShown() then OfficerPanel.frame:Show() end
    OfficerPanel.frame.SwitchToInvites()
end

function SchlingelInc.OfficerPanel:RefreshInvites()
    if OfficerPanel.frame and OfficerPanel.frame.RefreshInvites then
        OfficerPanel.frame.RefreshInvites()
    end
end

function SchlingelInc.OfficerPanel:RefreshProgress()
    if OfficerPanel.frame and OfficerPanel.frame:IsShown() and OfficerPanel.frame.RefreshProgress then
        OfficerPanel.frame.RefreshProgress()
    end
end
