-- OfficerPanel/SchandeViewer.lua
-- Officer-only popup showing a live-fetched Schande history for an arbitrary guild
-- member (opened via the "Schande anzeigen" entry in TabProgress.lua's row context
-- menu). Visually reuses the same card list as GuildPanel's own-Schande tab
-- (SchlingelInc.Shared.BuildSchandeList), plus impose/resolve actions.

local OfficerPanel = SchlingelInc.OfficerPanel

local VIEWER_W = 340
local VIEWER_H = 420
local TITLE_H  = 28

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
        local dialog = self:GetParent()
        if not dialog then return end

        local button1 = (dialog.GetName and _G[dialog:GetName() .. "Button1"]) or dialog.button1
        if button1 and button1.Click then
            button1:Click()
            return
        end

        local info = dialog.which and StaticPopupDialogs[dialog.which]
        if info and info.OnAccept then
            info.OnAccept(dialog)
            dialog:Hide()
        end
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
    local f = SchlingelInc.Shared.CreateStandardFrame({
        name          = "SchlingelIncSchandeViewer",
        width         = VIEWER_W,
        height        = VIEWER_H,
        strata        = "DIALOG",
        backdrop      = SchlingelInc.Constants.POPUPBACKDROP,
        positionKey   = "schandeviewer_position",
        defaultPoint  = "CENTER",
        defaultX      = 0,
        defaultY      = 0,
        registerEscape = true,
        closeButton   = true,
    })

    -- ── Title bar ─────────────────────────────────────────────────────────
    local titleBg = f:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -4)
    titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    titleBg:SetHeight(TITLE_H)
    titleBg:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BG))

    local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBg, "LEFT", 8, 0)
    titleText:SetTextColor(1, 0.82, 0, 1)
    f.titleText = titleText

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
