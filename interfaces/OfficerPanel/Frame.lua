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

    -- ── Tab buttons + content (shared factory) ─────────────────────────────
    local function RequirePermission(message)
        return function()
            if not OfficerPanel.IsOfficer() then
                SchlingelInc:Print(message)
                return false
            end
        end
    end

    local switcher = SchlingelInc.Shared.CreateTabSwitcher({
        parent    = f,
        width     = OfficerPanel.PANEL_W - 16,
        tabHeight = OfficerPanel.TAB_H,
        topOffset = -(OfficerPanel.TITLE_H + 6),
        contentTop = -(OfficerPanel.TITLE_H + OfficerPanel.TAB_H + 14),
        tabDefs   = {
            { id = "rules",    label = "Regeln" },
            { id = "inactive", label = "Inaktiv", canSelect = RequirePermission("Inaktive Mitglieder sind nur für Offiziere sichtbar."),
              onSelected = function()
                  C_GuildInfo.GuildRoster()
                  C_Timer.After(0.3, OfficerPanel.RefreshInactive)
              end },
            { id = "progress", label = "Mitglieder", canSelect = RequirePermission("Mitgliederliste ist nur für Offiziere sichtbar."),
              onSelected = function() SchlingelInc.OfficerPanel:RefreshProgress() end },
            { id = "discord",  label = "Discord", canSelect = RequirePermission("Discord-Übersicht ist nur für Offiziere sichtbar."),
              onSelected = function()
                  C_GuildInfo.GuildRoster()
                  C_Timer.After(0.3, OfficerPanel.RefreshDiscordHandles)
              end },
            { id = "invites",  label = "Anfragen", canSelect = RequirePermission("Anfragen sind nur für Offiziere sichtbar."),
              onSelected = function() SchlingelInc.OfficerPanel:RefreshInvites() end },
        },
    })

    OfficerPanel.tabBtns         = switcher.tabBtns
    OfficerPanel.tabContents     = switcher.tabContents
    OfficerPanel.tabFilterPanels = switcher.filterPanels

    -- ── Build tab content ─────────────────────────────────────────────────
    OfficerPanel.BuildRulesTab(OfficerPanel.tabContents["rules"])
    OfficerPanel.BuildInactiveTab(OfficerPanel.tabContents["inactive"])
    OfficerPanel.BuildProgressTab(OfficerPanel.tabContents["progress"])
    OfficerPanel.BuildDiscordTab(OfficerPanel.tabContents["discord"])
    OfficerPanel.BuildInvitesTab(OfficerPanel.tabContents["invites"])

    -- ── Filter panels ─────────────────────────────────────────────────────
    OfficerPanel.BuildFilters(f)

    f.RefreshInvites  = OfficerPanel.RefreshInvites
    f.RefreshProgress = OfficerPanel.RefreshProgress
    f.RefreshDiscord  = OfficerPanel.RefreshDiscordHandles
    f.SwitchToInvites = function()
        switcher.SwitchTab("invites")
        SchlingelInc.OfficerPanel:RefreshInvites()
    end

    f:HookScript("OnHide", function()
        for _, fp in pairs(OfficerPanel.tabFilterPanels) do
            if fp then fp:Hide() end
        end
    end)

    switcher.SwitchTab("rules")
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
        SchlingelInc.OfficerPanel.frame.RefreshInvites()
    end
end

function SchlingelInc.OfficerPanel:RefreshProgress()
    if OfficerPanel.frame and OfficerPanel.frame:IsShown() and OfficerPanel.frame.RefreshProgress then
        OfficerPanel.frame.RefreshProgress()
    end
end
