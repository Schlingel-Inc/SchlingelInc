-- interfaces/Shared/FilterWidgets.lua
-- Shared chrome for filter side-panels: the panel shell (backdrop/size/position/
-- Escape), the "Filter" heading, and the "Zurücksetzen" reset button. Used by
-- FilterPanel.lua's all-in-one factory and OfficerPanel/Filters.lua's custom
-- progress/discord panels, which need the same chrome but a different body.

SchlingelInc.Shared = SchlingelInc.Shared or {}

SchlingelInc.Shared.FILTER_PANEL_WIDTH = 190
SchlingelInc.Shared.FILTER_PANEL_PAD   = 10

-- config = {
--   panelName   : string  -- global frame name
--   anchorFrame : Frame   -- panel anchors TOPLEFT -> TOPRIGHT of this frame
--   width       : number | nil -- default FILTER_PANEL_WIDTH
--   height      : number  -- required, caller computes from its own section layout
-- }
-- Returns the panel frame: backdrop, sized, positioned, Hidden, Escape-registered.
function SchlingelInc.Shared.CreateFilterPanelShell(config)
    local panel = CreateFrame("Frame", config.panelName, UIParent, "BackdropTemplate")
    panel:SetSize(config.width or SchlingelInc.Shared.FILTER_PANEL_WIDTH, config.height)
    panel:SetFrameStrata("HIGH")
    panel:SetBackdrop(SchlingelInc.Constants.DROPDOWNBACKDROP)
    panel:SetBackdropColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BG))
    panel:SetBackdropBorderColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BORDER))
    panel:SetPoint("TOPLEFT", config.anchorFrame, "TOPRIGHT", 6, 0)
    panel:Hide()
    SchlingelInc:RegisterFrameForEscape(panel)
    return panel
end

-- Standard "Filter" heading anchored to the panel's top-left corner.
function SchlingelInc.Shared.CreateFilterTitle(parent)
    local padding = SchlingelInc.Shared.FILTER_PANEL_PAD
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, -padding)
    title:SetText("Filter")
    title:SetTextColor(unpack(SchlingelInc.Constants.FORM_COLORS.TITLE))
    return title
end

-- Standard "Zurücksetzen" button, anchored below anchorWidget.
function SchlingelInc.Shared.CreateFilterResetButton(parent, anchorWidget, width, onReset)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetPoint("TOPLEFT", anchorWidget, "BOTTOMLEFT", 0, -12)
    button:SetText("Zurücksetzen")
    button:SetScript("OnClick", onReset)
    return button
end
