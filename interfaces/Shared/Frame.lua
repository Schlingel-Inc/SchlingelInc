-- interfaces/Shared/Frame.lua
-- Shared "draggable form frame" factory: backdrop, drag handling, position
-- persistence, Escape registration, and an optional close button. Every
-- top-level panel/popup used to hand-roll this chrome; title bars and body
-- content still stay with each caller since those genuinely differ.

SchlingelInc.Shared = SchlingelInc.Shared or {}

-- cfg = {
--   name          : string  -- global frame name; required for registerEscape
--   parent        : Frame   -- default UIParent
--   width, height : number
--   strata        : string  -- default "DIALOG"
--   backdrop      : table   -- default SchlingelInc.Constants.BACKDROP
--   bgColor       : {r,g,b,a} -- default FORM_COLORS.FORM_BG
--   borderColor   : {r,g,b,a} -- default FORM_COLORS.FORM_BORDER
--   movable       : bool    -- default true
--   positionKey   : string  -- SavedVariables key for Save/RestoreFramePosition; nil = don't persist
--   defaultPoint, defaultX, defaultY  -- forwarded to RestoreFramePosition
--   registerEscape: bool    -- default false (opt-in)
--   closeButton   : bool    -- default false (opt-in); UIPanelCloseButton, TOPRIGHT -2,-2, 20x20, OnClick -> f:Hide()
--   onHide        : function -- optional, wired to f:SetScript("OnHide", ...)
-- }
-- Returns the frame, already Hidden, with drag/position/escape/close wired.
function SchlingelInc.Shared.CreateStandardFrame(cfg)
    local FC = SchlingelInc.Constants.FORM_COLORS

    local f = CreateFrame("Frame", cfg.name, cfg.parent or UIParent, "BackdropTemplate")
    f:SetSize(cfg.width, cfg.height)
    f:SetFrameStrata(cfg.strata or "DIALOG")
    f:SetBackdrop(cfg.backdrop or SchlingelInc.Constants.BACKDROP)
    f:SetBackdropColor(unpack(cfg.bgColor or FC.FORM_BG))
    f:SetBackdropBorderColor(unpack(cfg.borderColor or FC.FORM_BORDER))

    if cfg.movable ~= false then
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            if cfg.positionKey then
                SchlingelInc:SaveFramePosition(self, cfg.positionKey)
            end
        end)
    end

    if cfg.positionKey then
        SchlingelInc:RestoreFramePosition(f, cfg.positionKey, cfg.defaultPoint, cfg.defaultX, cfg.defaultY)
    end

    if cfg.registerEscape then
        SchlingelInc:RegisterFrameForEscape(f)
    end

    if cfg.closeButton then
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetSize(20, 20)
        closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
        closeBtn:SetScript("OnClick", function() f:Hide() end)
        f.closeBtn = closeBtn
    end

    if cfg.onHide then
        f:SetScript("OnHide", cfg.onHide)
    end

    f:Hide()
    return f
end
