-- interfaces/popups/AchievementRevokeForm.lua
-- Small officer popup to remove a previously unlocked `manual`-kind (RP),
-- `level`-kind, or `kill_count` achievement from a specific target, opened via
-- "Erfolg entziehen" in MemberContextMenu.lua.

SchlingelInc.Popup = SchlingelInc.Popup or {}

local KIND = SchlingelInc.Achievements.KIND

local KIND_LABELS = {
    [KIND.LEVEL] = "Level",
    [KIND.MANUAL] = "Manuell (RP)",
    [KIND.KILL_COUNT] = "Kill-Count"
}

local FORM_W  = 340
local FORM_H  = 420
local CARD_GAP = 6
local CARD_PAD = 8
local STATUS_TIMEOUT = 5

local currentRevokeTarget = nil

StaticPopupDialogs["SCHLINGEL_ACHIEVEMENT_REVOKE_CONFIRM"] = {
    text = "Erfolg \"%s\" von %s entfernen?",
    button1 = "Entfernen",
    button2 = "Abbrechen",
    OnAccept = function(self)
        local data = self.data
        SchlingelInc.Achievements.ManualGrant:Revoke(data.target, data.id)
        if SchlingelInc.Popup.achievementRevokeForm then
            SchlingelInc.Popup.achievementRevokeForm:Hide()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function CreateCard(parent, cardW, entry, onClick)
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
    card:SetScript("OnClick", function() onClick(entry) end)

    return card
end

local function BuildForm()
    local f = CreateFrame("Frame", "SchlingelAchievementRevokeForm", UIParent, "BackdropTemplate")
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
        SchlingelInc:SaveFramePosition(self, "achievementrevokeform_position")
    end)
    SchlingelInc:RestoreFramePosition(f, "achievementrevokeform_position", "CENTER", 0, 80)
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

local function IsGrantableKind(kind)
    return kind == KIND.MANUAL or kind == KIND.LEVEL or kind == KIND.KILL_COUNT
end

local function Refresh(f)
    for _, c in ipairs(f.cards) do c:Hide() end
    wipe(f.cards)

    local cardW = math.max(1, f.scrollFrame:GetWidth())
    f.scrollChild:SetWidth(cardW)

    local revokable = {}
    for _, entry in ipairs(SchlingelInc.Achievements.Catalog:GetAll()) do
        local isUnlocked = f.reachedSet and f.reachedSet[entry.id]
        if IsGrantableKind(entry.kind) and isUnlocked then
            table.insert(revokable, entry)
        end
    end

    local yOff = 0
    if #revokable == 0 then
        local msg = f.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        msg:SetPoint("TOPLEFT", f.scrollChild, "TOPLEFT", 4, 0)
        msg:SetText(f.reachedSet and "Spieler hat keine entziehbaren Erfolge." or "Keine entziehbaren Erfolge vorhanden.")
        msg:SetTextColor(0.6, 0.6, 0.6, 1)
        table.insert(f.cards, msg)
        yOff = -20
    else
        for _, entry in ipairs(revokable) do
            local card = CreateCard(f.scrollChild, cardW, entry, function(selected)
                StaticPopup_Show("SCHLINGEL_ACHIEVEMENT_REVOKE_CONFIRM", selected.name, currentRevokeTarget,
                    { target = currentRevokeTarget, id = selected.id })
            end)
            card:SetPoint("TOPLEFT", f.scrollChild, "TOPLEFT", 0, yOff)
            table.insert(f.cards, card)
            yOff = yOff - card:GetHeight() - CARD_GAP
        end
    end

    f.scrollChild:SetHeight(math.max(1, -yOff))
end

function SchlingelInc.Popup:ShowAchievementRevokeForm(targetName)
    if not targetName or targetName == "" then return end
    if not SchlingelInc.Popup.achievementRevokeForm then
        SchlingelInc.Popup.achievementRevokeForm = BuildForm()
    end
    local f = SchlingelInc.Popup.achievementRevokeForm

    if f.timeoutTimer then f.timeoutTimer:Cancel() f.timeoutTimer = nil end

    currentRevokeTarget = targetName
    f.reachedSet = nil
    f.titleFs:SetText("Erfolg entziehen: " .. targetName)
    f.statusFs:SetTextColor(0.8, 0.8, 0.4, 1)
    f.statusFs:SetText("Frage Freischaltungsstatus ab...")
    Refresh(f)
    SchlingelInc:RestoreFramePosition(f, "achievementrevokeform_position", "CENTER", 0, 80)
    f:Show()

    SchlingelInc.Achievements.Progress:RequestReached(targetName)
    f.timeoutTimer = C_Timer.NewTimer(STATUS_TIMEOUT, function()
        f.timeoutTimer = nil
        if currentRevokeTarget == targetName and not f.reachedSet then
            f.statusFs:SetTextColor(1, 0.4, 0.4, 1)
            f.statusFs:SetText("Status konnte nicht bestätigt werden — bitte beim Spieler nachfragen.")
        end
    end)
end

-- Routes an incoming ACH_REACHED response to the revoke popup if it's still open for
-- this sender; stale responses (form closed or reopened for someone else) are ignored.
function SchlingelInc.Popup:OnReachedReceived(senderShort, ids)
    local f = SchlingelInc.Popup.achievementRevokeForm
    if not f or not f:IsShown() or currentRevokeTarget ~= senderShort then return end

    if f.timeoutTimer then f.timeoutTimer:Cancel() f.timeoutTimer = nil end

    local set = {}
    for _, id in ipairs(ids) do set[id] = true end
    f.reachedSet = set
    f.statusFs:SetText("")
    Refresh(f)
end