-- interfaces/SchandeList.lua
-- Shared, scrollable Schande card list used by both the player-facing GuildPanel
-- "Schande" tab (read-only) and the officer's Schande viewer popup (with an optional
-- resolve button per active entry), so the two stay visually identical.

SchlingelInc.Shared = SchlingelInc.Shared or {}

local CARD_GAP       = 6
local CARD_PAD       = 8
local BADGE_H        = 16
local RESOLVE_BTN_H  = 20

local function CreateCard(parent, cardW, entry, opts)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    card:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
    card:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    card:SetWidth(cardW)

    local idText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    idText:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -CARD_PAD)
    idText:SetTextColor(0.6, 0.6, 0.6, 1)
    idText:SetText("#" .. tostring(entry.id))

    local badgeText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badgeText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -(CARD_PAD + 6), -CARD_PAD)
    badgeText:SetTextColor(1, 1, 1, 1)
    badgeText:SetText(entry.active and "Schande" or "Reingewaschen")

    local badgeBg = card:CreateTexture(nil, "ARTWORK")
    badgeBg:SetPoint("TOPLEFT",     badgeText, "TOPLEFT",     -6, 3)
    badgeBg:SetPoint("BOTTOMRIGHT", badgeText, "BOTTOMRIGHT",  6, -3)
    badgeBg:SetColorTexture(entry.active and 0.55 or 0.16, entry.active and 0.12 or 0.45, 0.12, 0.9)

    local text = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -(CARD_PAD + BADGE_H))
    text:SetWidth(cardW - CARD_PAD * 2)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(true)
    text:SetText(entry.freetext ~= "" and entry.freetext or "|cff888888— keine Angabe —|r")

    local height = CARD_PAD + BADGE_H + text:GetStringHeight() + CARD_PAD

    if opts and opts.onResolve and entry.active then
        local resolveBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        resolveBtn:SetSize(90, RESOLVE_BTN_H)
        resolveBtn:SetText("Aufheben")
        resolveBtn:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -6)
        resolveBtn:SetScript("OnClick", function() opts.onResolve(entry) end)
        height = height + RESOLVE_BTN_H + 6
    end

    card:SetHeight(height)
    return card
end

-- Builds a mouse-wheel-scrollable Schande card list filling `parent`. Returns
-- { Refresh = function(entries) ... end }. opts.onResolve(entry), if given, adds an
-- "Aufheben" button to every active card.
function SchlingelInc.Shared.BuildSchandeList(parent, opts)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -20, 0)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        sf:SetVerticalScroll(
            math.max(0, math.min(sf:GetVerticalScrollRange(), sf:GetVerticalScroll() - delta * 24))
        )
    end)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    local cards = {}

    local function Refresh(entries)
        for _, c in ipairs(cards) do c:Hide() end
        wipe(cards)

        local cardW = math.max(1, scrollFrame:GetWidth())
        scrollChild:SetWidth(cardW)
        local yOff = 0

        if #entries == 0 then
            local msg = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            msg:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 8, 0)
            msg:SetText("Noch keine Einträge.")
            msg:SetTextColor(0.6, 0.6, 0.6, 1)
            table.insert(cards, msg)
            yOff = -20
        else
            -- newest first
            for i = #entries, 1, -1 do
                local card = CreateCard(scrollChild, cardW, entries[i], opts)
                card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOff)
                table.insert(cards, card)
                yOff = yOff - card:GetHeight() - CARD_GAP
            end
        end

        scrollChild:SetHeight(math.max(1, -yOff))
    end

    -- Empties the card area without asserting "no entries" (unlike Refresh({})) —
    -- for use while a result is still pending, e.g. during an async fetch.
    local function Clear()
        for _, c in ipairs(cards) do c:Hide() end
        wipe(cards)
        scrollChild:SetHeight(1)
    end

    return { scrollFrame = scrollFrame, Refresh = Refresh, Clear = Clear }
end
