-- OfficerPanel/SchandeViewer.lua
-- Officer-only popup showing a live-fetched Schande history for an arbitrary guild
-- member (opened via the "Schande anzeigen" entry in TabProgress.lua's row context
-- menu). Visually reuses the same card list as GuildPanel's own-Schande tab
-- (SchlingelInc.Shared.BuildSchandeList), plus impose/resolve actions.

local OfficerPanel = SchlingelInc.OfficerPanel

local VIEWER_W = 340
local VIEWER_H = 420
local TITLE_H  = 28

local BACKDROP = {
    bgFile   = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

local currentTarget = nil
local Fetch -- forward-declared; assigned below, referenced by the StaticPopups' OnAccept

StaticPopupDialogs["SCHLINGEL_SCHANDE_VIEWER_IMPOSE"] = {
    text = "Schande-Aufgabe für %s:",
    button1 = "Verhängen",
    button2 = "Abbrechen",
    hasEditBox = true,
    maxLetters = 200,
    OnShow = function(self)
        self.EditBox:SetText("")
        self.EditBox:SetFocus()
    end,
    OnAccept = function(self)
        SchlingelInc.Schande:Impose(self.data, self.EditBox:GetText())
        C_Timer.After(0.3, function() Fetch(self.data) end)
    end,
    EditBoxOnEnterPressed = function(self)
        self:GetParent().button1:Click()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["SCHLINGEL_SCHANDE_VIEWER_RESOLVE"] = {
    text = "Schande #%d aufheben?",
    button1 = "Aufheben",
    button2 = "Abbrechen",
    OnAccept = function(self)
        local data = self.data
        SchlingelInc.Schande:Resolve(data.target, data.id)
        C_Timer.After(0.3, function() Fetch(data.target) end)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function SetStatus(f, text, r, g, b)
    f.statusLbl:SetText(text)
    f.statusLbl:SetTextColor(r, g, b, 1)
end

local function BuildViewer()
    local f = CreateFrame("Frame", "SchlingelIncSchandeViewer", UIParent, "BackdropTemplate")
    f:SetSize(VIEWER_W, VIEWER_H)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetBackdrop(BACKDROP)
    f:SetBackdropColor(0.07, 0.07, 0.07, 0.96)
    f:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SchlingelInc:SaveFramePosition(self, "schandeviewer_position")
    end)
    SchlingelInc:RestoreFramePosition(f, "schandeviewer_position", "CENTER", 0, 0)
    f:Hide()
    SchlingelInc:RegisterFrameForEscape(f)

    -- ── Title bar ─────────────────────────────────────────────────────────
    local titleBg = f:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -4)
    titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    titleBg:SetHeight(TITLE_H)
    titleBg:SetColorTexture(0.12, 0.12, 0.12, 1)

    local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBg, "LEFT", 8, 0)
    titleText:SetTextColor(1, 0.82, 0, 1)
    f.titleText = titleText

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- ── Actions + status ─────────────────────────────────────────────────
    local imposeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    imposeBtn:SetSize(120, 22)
    imposeBtn:SetText("Neue Schande")
    imposeBtn:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 4, -8)
    imposeBtn:SetScript("OnClick", function()
        if not currentTarget then return end
        StaticPopup_Show("SCHLINGEL_SCHANDE_VIEWER_IMPOSE", currentTarget, nil, currentTarget)
    end)
    f.imposeBtn = imposeBtn

    local statusLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusLbl:SetPoint("TOPLEFT", imposeBtn, "BOTTOMLEFT", 0, -8)
    statusLbl:SetJustifyH("LEFT")
    f.statusLbl = statusLbl

    -- ── Card list (shared with GuildPanel's own-Schande tab) ────────────────
    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT",     statusLbl, "BOTTOMLEFT", -4, -8)
    body:SetPoint("BOTTOMRIGHT", f,          "BOTTOMRIGHT", -8, 8)

    f.list = SchlingelInc.Shared.BuildSchandeList(body, {
        onResolve = function(entry)
            if not currentTarget then return end
            StaticPopup_Show("SCHLINGEL_SCHANDE_VIEWER_RESOLVE", entry.id, nil,
                { target = currentTarget, id = entry.id })
        end,
    })

    return f
end

-- (Re)fetches targetName's Schande and updates the viewer once it's the current
-- request's target and the viewer is still open (guards against stale responses
-- landing after the viewer moved on to someone else, or got closed).
Fetch = function(targetName)
    local f = OfficerPanel.schandeViewer
    if not f or currentTarget ~= targetName then return end

    SetStatus(f, "Lade Schande...", 0.6, 0.6, 0.6)
    f.list.Clear()
    f.imposeBtn:Disable()

    SchlingelInc.Schande:GetAllOf(targetName, function(entries)
        local vf = OfficerPanel.schandeViewer
        if currentTarget ~= targetName or not vf or not vf:IsShown() then return end

        vf.imposeBtn:Enable()

        if not entries then
            SetStatus(vf, "Keine Antwort erhalten.", 1, 0.2, 0.2)
            vf.list.Clear()
            return
        end

        if SchlingelInc.Schande.IsEntriesActive(entries) then
            SetStatus(vf, targetName .. " ist in Schande.", 1, 0.2, 0.2)
        elseif #entries > 0 then
            SetStatus(vf, targetName .. "s Schande ist aufgehoben.", 0.4, 1, 0.4)
        else
            SetStatus(vf, "Keine Schande.", 0.6, 0.6, 0.6)
        end

        vf.list.Refresh(entries)
    end)
end

-- ── Public API ────────────────────────────────────────────────────────────────

function OfficerPanel:ShowSchandeViewer(targetName)
    if not CanGuildInvite() then return end
    if not targetName or targetName == "" then return end

    if not OfficerPanel.schandeViewer then
        OfficerPanel.schandeViewer = BuildViewer()
    end
    local f = OfficerPanel.schandeViewer

    currentTarget = targetName
    f.titleText:SetText("Schande: " .. targetName)
    f:Show()

    Fetch(targetName)
end
