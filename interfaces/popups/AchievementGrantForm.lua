-- interfaces/popups/AchievementGrantForm.lua
-- Small officer popup to grant a `manual`-kind (RP) achievement to a specific
-- target, opened via "Erfolg verleihen" in MemberContextMenu.lua.

SchlingelInc.Popup = SchlingelInc.Popup or {}

local KIND = SchlingelInc.Achievements.KIND

local FORM_W  = 300
local ITEM_H  = 22
local PAD     = 10

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

local function BuildForm()
    local f = CreateFrame("Frame", "SchlingelAchievementGrantForm", UIParent, "BackdropTemplate")
    f:SetSize(FORM_W, 200)
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
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -40)
    body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, PAD)
    f.body = body

    f.entryBtns = {}

    return f
end

local function Refresh(f)
    for _, btn in ipairs(f.entryBtns) do btn:Hide() end
    wipe(f.entryBtns)

    local manualEntries = {}
    for _, entry in ipairs(SchlingelInc.Achievements.Catalog:GetActive()) do
        if entry.kind == KIND.MANUAL then table.insert(manualEntries, entry) end
    end

    local yOff = 0
    if #manualEntries == 0 then
        local msg = f.body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        msg:SetPoint("TOPLEFT", f.body, "TOPLEFT", 0, 0)
        msg:SetText("Keine manuellen Erfolge angelegt.")
        msg:SetTextColor(0.6, 0.6, 0.6, 1)
        table.insert(f.entryBtns, msg)
        yOff = -20
    else
        for _, entry in ipairs(manualEntries) do
            local btn = CreateFrame("Button", nil, f.body, "UIPanelButtonTemplate")
            btn:SetSize(FORM_W - PAD * 2, ITEM_H)
            btn:SetPoint("TOPLEFT", f.body, "TOPLEFT", 0, yOff)
            btn:SetText(entry.name)
            btn:GetFontString():SetWordWrap(false)
            btn:SetScript("OnClick", function()
                StaticPopup_Show("SCHLINGEL_ACHIEVEMENT_GRANT_CONFIRM", entry.name, currentTarget,
                    { target = currentTarget, id = entry.id })
            end)
            table.insert(f.entryBtns, btn)
            yOff = yOff - ITEM_H - 4
        end
    end

    f.body:SetHeight(math.max(1, -yOff))
    f:SetHeight(math.max(140, 40 + math.abs(yOff) + PAD * 2))
end

function SchlingelInc.Popup:ShowAchievementGrantForm(targetName)
    if not targetName or targetName == "" then return end
    if not SchlingelInc.Popup.achievementGrantForm then
        SchlingelInc.Popup.achievementGrantForm = BuildForm()
    end
    local f = SchlingelInc.Popup.achievementGrantForm

    currentTarget = targetName
    f.titleFs:SetText("Erfolg verleihen: " .. targetName)
    Refresh(f)
    SchlingelInc:RestoreFramePosition(f, "achievementgrantform_position", "CENTER", 0, 80)
    f:Show()
end
