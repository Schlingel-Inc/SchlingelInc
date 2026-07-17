-- PopupEditMode.lua
-- Lets players reposition popup anchors without waiting for each popup to appear.

SchlingelInc.PopupEditMode = SchlingelInc.PopupEditMode or {}

local EditMode = SchlingelInc.PopupEditMode

local SPECS = {
    { label = "Generic Popup", dbKey = "genericpopup_position", w = 370, h = 160, point = "TOP", x = 0, y = -150 },
    { label = "Death Announcement", dbKey = "deathannouncement_position", w = 380, h = 200, point = "TOP", x = 0, y = 0 },
    { label = "Small Death", dbKey = "smalldeathannouncement_position", w = 220, h = 40, point = "TOPRIGHT", x = -20, y = -200 },
    { label = "Level Up", dbKey = "levelupannouncement_position", w = 380, h = 200, point = "TOP", x = 0, y = 0 },
    { label = "Guild Invites", dbKey = "guildinvites_popup_position", w = 260, h = 64, point = "TOPRIGHT", x = -60, y = -200 },
    { label = "Achievement Announcement", dbKey = "achievementannouncement_position", w = 220, h = 40, point = "TOPRIGHT", x = -20, y = -260 },
    { label = "Guild Join Prompt", dbKey = "guildjoinprompt_position", w = 300, h = 130, point = "CENTER", x = 0, y = 0 },
}

local overlays = {}
local container
local controls
local snapGuide
local enabled = false
local CENTER_SNAP_THRESHOLD = 24
local BRAND_R, BRAND_G, BRAND_B = 1, 0.55, 0.73

local function IsWithinHorizontalSnap(frame)
    local fx = frame and frame:GetCenter()
    local ux = UIParent:GetCenter()
    if not fx or not ux then
        return false
    end
    return math.abs(fx - ux) <= CENTER_SNAP_THRESHOLD
end

local function BuildSnapGuide()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(2005)
    f:SetWidth(1)
    f:SetPoint("TOP", UIParent, "TOP", 0, 0)
    f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)

    local t = f:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints()
    t:SetColorTexture(BRAND_R, BRAND_G, BRAND_B, 0.95)

    f:Hide()
    return f
end

local function SnapToHorizontalCenter(frame)
    local fx, fy = frame:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not fx or not fy or not ux or not uy then
        return false
    end

    if IsWithinHorizontalSnap(frame) then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, fy - uy)
        return true
    end

    return false
end

local function BuildOverlay(spec)
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(spec.w, spec.h)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(1992)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")

    f:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
    f:SetBackdropColor(0.24, 0.08, 0.15, 0.35)
    f:SetBackdropBorderColor(BRAND_R, BRAND_G, BRAND_B, 1)

    f:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self:SetScript("OnUpdate", function(updater)
            if not enabled then
                if snapGuide then snapGuide:Hide() end
                return
            end
            if IsWithinHorizontalSnap(updater) then
                if snapGuide then snapGuide:Show() end
            else
                if snapGuide then snapGuide:Hide() end
            end
        end)
    end)
    f:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:StopMovingOrSizing()
        if snapGuide then snapGuide:Hide() end
        SnapToHorizontalCenter(self)
        SchlingelInc:SaveFramePosition(self, spec.dbKey)
    end)

    SchlingelInc:RestoreFramePosition(f, spec.dbKey, spec.point, spec.x, spec.y)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -8)
    title:SetTextColor(BRAND_R, BRAND_G, BRAND_B, 1)
    title:SetText(spec.label)

    return f
end

local function BuildContainer()
    local c = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    c:SetAllPoints(UIParent)
    c:SetFrameStrata("FULLSCREEN_DIALOG")
    c:SetFrameLevel(1990)
    c:EnableMouse(true)
    c:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    c:SetBackdropColor(0, 0, 0, 0.2)

    local title = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", c, "TOP", 0, -40)
    title:SetText("Schlingel Popup-Edit-Modus")
    title:SetTextColor(1, 0.85, 0.2, 1)

    local hint = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hint:SetPoint("TOP", title, "BOTTOM", 0, -8)
    hint:SetText("Verschiebe die Platzhalter und klicke oben auf \"Speichern & beenden\".")
    hint:SetTextColor(0.9, 0.9, 0.9, 1)

    c:Hide()
    return c
end

local function BuildControls()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(220, 28)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(2010)
    f:SetPoint("TOP", UIParent, "TOP", 0, -8)

    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetAllPoints(f)
    saveBtn:SetText("Speichern & beenden")
    saveBtn:SetScript("OnClick", function()
        EditMode:Disable()
    end)

    f:Hide()
    return f
end

function EditMode:IsEnabled()
    return enabled
end

function EditMode:Enable()
    if enabled then return end

    if not container then
        container = BuildContainer()
    end
    if not controls then
        controls = BuildControls()
    end
    if not snapGuide then
        snapGuide = BuildSnapGuide()
    end

    container:Show()
    controls:Show()
    snapGuide:Hide()

    if #overlays == 0 then
        for _, spec in ipairs(SPECS) do
            local frame = BuildOverlay(spec)
            table.insert(overlays, frame)
        end
    end

    for i, frame in ipairs(overlays) do
        local spec = SPECS[i]
        if spec then
            SchlingelInc:RestoreFramePosition(frame, spec.dbKey, spec.point, spec.x, spec.y)
        end
        frame:Show()
    end

    enabled = true
    SchlingelInc:Print("Popup-Edit-Modus aktiv: Ziehe die Platzhalter, um Positionen zu speichern.")
end

function EditMode:Disable()
    if not enabled then return end

    for i = 1, #overlays do
        overlays[i]:Hide()
    end

    if container then
        container:Hide()
    end
    if controls then
        controls:Hide()
    end
    if snapGuide then
        snapGuide:Hide()
    end

    enabled = false
    SchlingelInc:Print("Popup-Edit-Modus beendet.")
end

function EditMode:Toggle()
    if enabled then
        self:Disable()
    else
        self:Enable()
    end
end
