-- interfaces/CardFrame.lua
-- Shared card-frame factory: the backdrop skeleton used by every scrollable
-- "card" list in the addon (achievement/raid/schande entries), so the visual
-- treatment (background, border, hover state) stays in one place.

SchlingelInc.Shared = SchlingelInc.Shared or {}

local CARD_PAD = 8

-- cfg = {
--   clickable : bool | nil  -- true creates a Button with mouse enabled and a
--                              gold hover-border swap; false/nil a plain Frame.
-- }
function SchlingelInc.Shared.CreateCardFrame(parent, cardW, cfg)
    cfg = cfg or {}
    local FC = SchlingelInc.Constants.FORM_COLORS

    local card = CreateFrame(cfg.clickable and "Button" or "Frame", nil, parent, "BackdropTemplate")
    card:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    card:SetBackdropColor(unpack(FC.FORM_BG))
    card:SetBackdropBorderColor(unpack(FC.FORM_BORDER))
    card:SetWidth(cardW)

    if cfg.clickable then
        card:EnableMouse(true)
        card:SetScript("OnEnter", function() card:SetBackdropBorderColor(unpack(FC.TITLE)) end)
        card:SetScript("OnLeave", function() card:SetBackdropBorderColor(unpack(FC.FORM_BORDER)) end)
    end

    return card
end

-- Small clickable card used by the achievement grant/revoke picker popups: a
-- name line plus a "N Punkte — Art" meta line, selects `entry` via onClick.
-- kindLabels lets each caller keep its own kind->label wording.
function SchlingelInc.Shared.CreateAchievementPickerCard(parent, cardW, entry, kindLabels, onClick)
    local card = SchlingelInc.Shared.CreateCardFrame(parent, cardW, { clickable = true })
    card:SetHeight(40)

    local nameFs = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -CARD_PAD)
    nameFs:SetPoint("RIGHT", card, "RIGHT", -CARD_PAD, 0)
    nameFs:SetJustifyH("LEFT")
    nameFs:SetText(SchlingelInc:SanitizeText(entry.name) or "(ohne Namen)")
    nameFs:SetTextColor(1, 1, 1, 1)

    local metaFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    metaFs:SetPoint("TOPLEFT", nameFs, "BOTTOMLEFT", 0, -3)
    metaFs:SetText((entry.points or 0) .. " Punkte — " .. (kindLabels[entry.kind] or entry.kind))
    metaFs:SetTextColor(0.6, 0.8, 1, 1)

    card:SetScript("OnClick", function() onClick(entry) end)

    return card
end
