-- GuildPanel/TabSchande.lua
-- "Schande" tab: read-only view of the player's own Schande history.
-- There is no roster of other players' Schande here — see Schande.lua for why.

local GP = SchlingelInc.GuildPanel

local CARD_GAP     = 6
local CARD_PAD     = 8
local BADGE_H      = 16

local function CreateCard(parent, cardW, entry)
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

    card:SetHeight(CARD_PAD + BADGE_H + text:GetStringHeight() + CARD_PAD)
    return card
end

function GP.BuildSchandeTab(content)
    local statusLbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    statusLbl:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -10)
    statusLbl:SetJustifyH("LEFT")

    local listHeaderLbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listHeaderLbl:SetPoint("TOPLEFT", statusLbl, "BOTTOMLEFT", 0, -14)
    listHeaderLbl:SetText("Verlauf:")
    listHeaderLbl:SetTextColor(1, 0.82, 0, 1)

    local divider = content:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    divider:SetPoint("TOPLEFT",  listHeaderLbl, "BOTTOMLEFT", 0, -4)
    divider:SetPoint("RIGHT",    content, "RIGHT", -8, 0)

    local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     divider, "BOTTOMLEFT", 0, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", content,  "BOTTOMRIGHT", -20, 4)
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

    local function Refresh()
        local entries = SchlingelInc.Schande:GetOwn().entries

        if SchlingelInc.Schande:IsActive() then
            statusLbl:SetText("Du bist in Schande.")
            statusLbl:SetTextColor(1, 0.2, 0.2, 1)
        elseif #entries > 0 then
            statusLbl:SetText("Deine Schande ist aufgehoben.")
            statusLbl:SetTextColor(0.4, 1, 0.4, 1)
        else
            statusLbl:SetText("Keine Schande.")
            statusLbl:SetTextColor(0.6, 0.6, 0.6, 1)
        end

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
                local card = CreateCard(scrollChild, cardW, entries[i])
                card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOff)
                table.insert(cards, card)
                yOff = yOff - card:GetHeight() - CARD_GAP
            end
        end

        scrollChild:SetHeight(math.max(1, -yOff))
    end

    content.Refresh = Refresh
    Refresh()
end
