-- interfaces/popups/AchievementGrantForm.lua
-- Small officer popup to manually grant a `manual`-kind (RP) or `level`-kind
-- achievement to a specific target, opened via "Erfolg verleihen" in
-- MemberContextMenu.lua. `kill_count` achievements stay auto-detect only.
-- Card list mirrors OfficerPanel/TabAchievements.lua's catalog view.

SchlingelInc.Popup = SchlingelInc.Popup or {}

local KIND = SchlingelInc.Achievements.KIND

local KIND_LABELS = {
    [KIND.LEVEL]  = "Level",
    [KIND.MANUAL] = "Manuell (RP)",
}

local FORM_W  = 340
local FORM_H  = 420
local CARD_GAP = 6
local CARD_PAD = 8
local UNREACHED_TIMEOUT = 5

local currentTarget = nil

StaticPopupDialogs["SCHLINGEL_ACHIEVEMENT_GRANT_CONFIRM"] = {
    text = "Erfolg \"%s\" an %s verleihen?",
    button1 = "Verleihen",
    button2 = "Abbrechen",
    OnAccept = function(self)
        local data = self.data
        SchlingelInc.Achievements.ManualGrant:Grant(data.target, data.id)
        if SchlingelInc.Popup.achievementGrantForm then
            SchlingelInc.Popup.achievementGrantForm:Hide()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function CreateCard(parent, cardW, entry)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    card:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
    card:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    card:SetWidth(cardW)
    card:SetHeight(40)

    local nameFs = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -CARD_PAD)
    nameFs:SetPoint("RIGHT", card, "RIGHT", -CARD_PAD, 0)
    nameFs:SetJustifyH("LEFT")
    nameFs:SetText(SchlingelInc:SanitizeText(entry.name) or "(ohne Namen)")
    nameFs:SetTextColor(1, 1, 1, 1)

    local metaFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    metaFs:SetPoint("TOPLEFT", nameFs, "BOTTOMLEFT", 0, -3)
    metaFs:SetText((entry.points or 0) .. " Punkte — " .. (KIND_LABELS[entry.kind] or entry.kind))
    metaFs:SetTextColor(0.6, 0.8, 1, 1)

    card:SetScript("OnEnter", function() card:SetBackdropBorderColor(1, 0.82, 0, 1) end)
    card:SetScript("OnLeave", function() card:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end)
    card:SetScript("OnClick", function()
        StaticPopup_Show("SCHLINGEL_ACHIEVEMENT_GRANT_CONFIRM", entry.name, currentTarget,
            { target = currentTarget, id = entry.id })
    end)

    return card
end

local function BuildForm()
    local f = CreateFrame("Frame", "SchlingelAchievementGrantForm", UIParent, "BackdropTemplate")
    f:SetSize(FORM_W, FORM_H)
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop(SchlingelInc.Constants.BACKDROP)
    f:SetBackdropColor(0.07, 0.07, 0.07, 0.98)
    f:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SchlingelInc:SaveFramePosition(self, "achievementgrantform_position")
    end)
    SchlingelInc:RestoreFramePosition(f, "achievementgrantform_position", "CENTER", 0, 80)
    SchlingelInc:RegisterFrameForEscape(f)
    f:Hide()

    local titleFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFs:SetPoint("TOP", f, "TOP", 0, -14)
    titleFs:SetTextColor(1, 0.82, 0, 1)
    f.titleFs = titleFs

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        if f.timeoutTimer then f.timeoutTimer:Cancel() f.timeoutTimer = nil end
        f:Hide()
    end)

    local statusFs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusFs:SetPoint("TOP", f, "TOP", 0, -32)
    statusFs:SetPoint("LEFT", f, "LEFT", 10, 0)
    statusFs:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    statusFs:SetJustifyH("CENTER")
    f.statusFs = statusFs

    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    divider:SetPoint("TOPLEFT",  f, "TOPLEFT",  10, -46)
    divider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -46)

    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     f, "TOPLEFT",     10, -52)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 14)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        sf:SetVerticalScroll(
            math.max(0, math.min(sf:GetVerticalScrollRange(), sf:GetVerticalScroll() - delta * 24))
        )
    end)
    f.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild

    f.cards = {}

    return f
end

local function Refresh(f)
    for _, c in ipairs(f.cards) do c:Hide() end
    wipe(f.cards)

    local cardW = math.max(1, f.scrollFrame:GetWidth())
    f.scrollChild:SetWidth(cardW)

    local grantable = {}
    for _, entry in ipairs(SchlingelInc.Achievements.Catalog:GetActive()) do
        local isGrantableKind = entry.kind == KIND.MANUAL or entry.kind == KIND.LEVEL
        local stillReachable = not f.unreachedSet or f.unreachedSet[entry.id]
        if isGrantableKind and stillReachable then
            table.insert(grantable, entry)
        end
    end

    local yOff = 0
    if #grantable == 0 then
        local msg = f.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        msg:SetPoint("TOPLEFT", f.scrollChild, "TOPLEFT", 4, 0)
        msg:SetText(f.unreachedSet and "Spieler hat bereits alle verleihbaren Erfolge." or "Keine verleihbaren Erfolge vorhanden.")
        msg:SetTextColor(0.6, 0.6, 0.6, 1)
        table.insert(f.cards, msg)
        yOff = -20
    else
        for _, entry in ipairs(grantable) do
            local card = CreateCard(f.scrollChild, cardW, entry)
            card:SetPoint("TOPLEFT", f.scrollChild, "TOPLEFT", 0, yOff)
            table.insert(f.cards, card)
            yOff = yOff - card:GetHeight() - CARD_GAP
        end
    end

    f.scrollChild:SetHeight(math.max(1, -yOff))
end

function SchlingelInc.Popup:ShowAchievementGrantForm(targetName)
    if not targetName or targetName == "" then return end
    if not SchlingelInc.Popup.achievementGrantForm then
        SchlingelInc.Popup.achievementGrantForm = BuildForm()
    end
    local f = SchlingelInc.Popup.achievementGrantForm

    if f.timeoutTimer then f.timeoutTimer:Cancel() f.timeoutTimer = nil end

    currentTarget = targetName
    f.unreachedSet = nil
    f.titleFs:SetText("Erfolg verleihen: " .. targetName)
    f.statusFs:SetTextColor(0.8, 0.8, 0.4, 1)
    f.statusFs:SetText("Frage Freischaltungsstatus ab...")
    Refresh(f)
    SchlingelInc:RestoreFramePosition(f, "achievementgrantform_position", "CENTER", 0, 80)
    f:Show()

    SchlingelInc.Achievements.Progress:RequestUnreached(targetName)
    f.timeoutTimer = C_Timer.NewTimer(UNREACHED_TIMEOUT, function()
        f.timeoutTimer = nil
        if currentTarget == targetName and not f.unreachedSet then
            f.statusFs:SetTextColor(1, 0.4, 0.4, 1)
            f.statusFs:SetText("Status konnte nicht bestätigt werden — bitte beim Spieler nachfragen.")
        end
    end)
end

-- Routes an incoming ACH_UNREACHED response to the popup if it's still open for
-- this sender; stale responses (form closed or reopened for someone else) are ignored.
function SchlingelInc.Popup:OnUnreachedReceived(senderShort, ids)
    local f = SchlingelInc.Popup.achievementGrantForm
    if not f or not f:IsShown() or currentTarget ~= senderShort then return end

    if f.timeoutTimer then f.timeoutTimer:Cancel() f.timeoutTimer = nil end

    local set = {}
    for _, id in ipairs(ids) do set[id] = true end
    f.unreachedSet = set
    f.statusFs:SetText("")
    Refresh(f)
end
