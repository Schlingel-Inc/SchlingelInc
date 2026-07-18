-- interfaces/popups/AchievementGrantForm.lua
-- Small officer popup to manually grant a `manual`-kind (RP), `level`-kind, or
-- `kill_count` achievement to a specific target, opened via "Erfolg verleihen" in
-- MemberContextMenu.lua.
-- Card list mirrors OfficerPanel/TabAchievements.lua's catalog view.

SchlingelInc.Popup = SchlingelInc.Popup or {}

local KIND = SchlingelInc.Achievements.KIND

local KIND_LABELS = {
    [KIND.LEVEL]  = "Level",
    [KIND.MANUAL] = "Manuell (RP)",
    [KIND.KILL_COUNT] = "Kill-Count"
}

local FORM_W  = 340
local FORM_H  = 420
local CARD_GAP = 6
local STATUS_TIMEOUT = 5

local currentGrantTarget = nil

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

local function BuildForm(frameName)
    local f = SchlingelInc.Shared.CreateStandardFrame({
        name          = frameName,
        width         = FORM_W,
        height        = FORM_H,
        strata        = "DIALOG",
        positionKey   = "achievementgrantform_position",
        defaultPoint  = "CENTER",
        defaultX      = 0,
        defaultY      = 80,
        registerEscape = true,
    })

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
    divider:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.DIVIDER))
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

local function RefreshGrantForm(f)
    for _, c in ipairs(f.cards) do c:Hide() end
    wipe(f.cards)

    local cardW = math.max(1, f.scrollFrame:GetWidth())
    f.scrollChild:SetWidth(cardW)

    local grantable = {}
    for _, entry in ipairs(SchlingelInc.Achievements.Catalog:GetActive()) do
        local stillReachable = not f.unreachedSet or f.unreachedSet[entry.id]
        if IsGrantableKind(entry.kind) and stillReachable then
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
            local card = SchlingelInc.Shared.CreateAchievementPickerCard(f.scrollChild, cardW, entry, KIND_LABELS, function(selected)
                StaticPopup_Show("SCHLINGEL_ACHIEVEMENT_GRANT_CONFIRM", selected.name, currentGrantTarget,
                    { target = currentGrantTarget, id = selected.id })
            end)
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
        SchlingelInc.Popup.achievementGrantForm = BuildForm("SchlingelAchievementGrantForm")
    end
    local f = SchlingelInc.Popup.achievementGrantForm

    if f.timeoutTimer then f.timeoutTimer:Cancel() f.timeoutTimer = nil end

    currentGrantTarget = targetName
    f.unreachedSet = nil
    f.titleFs:SetText("Erfolg verleihen: " .. targetName)
    f.statusFs:SetTextColor(0.8, 0.8, 0.4, 1)
    f.statusFs:SetText("Frage Freischaltungsstatus ab...")
    RefreshGrantForm(f)
    SchlingelInc:RestoreFramePosition(f, "achievementgrantform_position", "CENTER", 0, 80)
    f:Show()

    SchlingelInc.Achievements.Progress:RequestUnreached(targetName)
    f.timeoutTimer = C_Timer.NewTimer(STATUS_TIMEOUT, function()
        f.timeoutTimer = nil
        if currentGrantTarget == targetName and not f.unreachedSet then
            f.statusFs:SetTextColor(1, 0.4, 0.4, 1)
            f.statusFs:SetText("Status konnte nicht bestätigt werden — bitte beim Spieler nachfragen.")
        end
    end)
end

-- Routes an incoming ACH_UNREACHED response to the popup if it's still open for
-- this sender; stale responses (form closed or reopened for someone else) are ignored.
function SchlingelInc.Popup:OnUnreachedReceived(senderShort, ids)
    local f = SchlingelInc.Popup.achievementGrantForm
    if not f or not f:IsShown() or currentGrantTarget ~= senderShort then return end

    if f.timeoutTimer then f.timeoutTimer:Cancel() f.timeoutTimer = nil end

    local set = {}
    for _, id in ipairs(ids) do set[id] = true end
    f.unreachedSet = set
    f.statusFs:SetText("")
    RefreshGrantForm(f)
end
