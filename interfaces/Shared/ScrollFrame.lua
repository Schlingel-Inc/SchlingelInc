-- interfaces/Shared/ScrollFrame.lua
-- Shared scroll frame + scroll child factory: every scrollable list/card
-- panel in the addon hand-rolled the same ScrollFrame + mouse-wheel clamp +
-- scroll child boilerplate. Anchoring stays with each caller since every
-- panel anchors the scroll frame to a different sibling.

SchlingelInc.Shared = SchlingelInc.Shared or {}

-- cfg = {
--   parent     : Frame
--   name       : string  -- optional, forwarded to CreateFrame
--   template   : string  -- optional, e.g. "UIPanelScrollFrameTemplate"; nil = no visible scrollbar
--   step       : number  -- default 24, mouse-wheel scroll distance per notch
--   childName  : string  -- optional, forwarded to the scroll child's CreateFrame
--   childWidth : number  -- optional, sets the scroll child's width at creation
-- }
-- Returns scrollFrame, scrollChild. Caller still anchors scrollFrame via :SetPoint.
function SchlingelInc.Shared.CreateScrollFrame(cfg)
    local scrollFrame = CreateFrame("ScrollFrame", cfg.name, cfg.parent, cfg.template)
    scrollFrame:EnableMouseWheel(true)

    local step = cfg.step or 24
    scrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        sf:SetVerticalScroll(
            math.max(0, math.min(sf:GetVerticalScrollRange(), sf:GetVerticalScroll() - delta * step))
        )
    end)

    local scrollChild = CreateFrame("Frame", cfg.childName, scrollFrame)
    if cfg.childWidth then
        scrollChild:SetWidth(cfg.childWidth)
    end
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    return scrollFrame, scrollChild
end
