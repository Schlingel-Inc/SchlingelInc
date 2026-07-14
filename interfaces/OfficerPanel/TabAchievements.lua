-- OfficerPanel/TabAchievements.lua
-- Officer-facing achievement catalog management: create/edit/retire definitions.
-- Shows every entry, including retired ones (with a "Eingestellt" badge), since
-- officers need the full picture to manage the catalog — unlike the member-facing
-- GuildPanel tab, which hides not-yet-earned retired entries.

local OfficerPanel = SchlingelInc.OfficerPanel

local CARD_GAP = 6
local CARD_PAD = 8

local KIND = SchlingelInc.Achievements.KIND

local KIND_LABELS = {
    [KIND.LEVEL]      = "Level",
    [KIND.KILL_COUNT] = "Kill-Zähler",
    [KIND.MANUAL]     = "Manuell (RP)",
}

local function ScopeText(entry)
    if entry.isGlobal == true or entry.isGlobal == 1 or entry.isGlobal == "1" then
        return "Global"
    end
    return "Char"
end

local function CriteriaText(entry)
    if entry.kind == KIND.LEVEL then
        local threshold = tonumber(entry.critA) or 0
        local requireNoDeath = entry.critB == true or entry.critB == 1 or entry.critB == "1"
        return "Level " .. threshold .. (requireNoDeath and " (ohne zu sterben)" or "")
    elseif entry.kind == KIND.KILL_COUNT then
        return "NPC-ID " .. (tostring(entry.critA) or "?") .. ", " .. (tostring(entry.critB) or "?") .. " Kills"
    end
    return "wird per Rechtsklick-Menü verliehen"
end

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

    local titleFs = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -CARD_PAD)
    titleFs:SetWidth(cardW - CARD_PAD * 2 - 160)
    titleFs:SetJustifyH("LEFT")
    local isBuiltin = entry.createdBy == "builtin"
    local nameText = SchlingelInc:SanitizeText(entry.name) or "(ohne Namen)"
    titleFs:SetText(nameText
        .. (entry.retired and "  |cff888888(Eingestellt)|r" or "")
        .. (isBuiltin and "  |cff888888(Systemerfolg)|r" or ""))
    titleFs:SetTextColor(1, 1, 1, 1)

    local kindFs = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    kindFs:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PAD, -CARD_PAD)
    kindFs:SetJustifyH("RIGHT")
    kindFs:SetText((entry.points or 0) .. " Punkte — " .. (KIND_LABELS[entry.kind] or entry.kind) .. " — " .. ScopeText(entry))
    kindFs:SetTextColor(0.6, 0.8, 1, 1)

    local descFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descFs:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -3)
    descFs:SetWidth(cardW - CARD_PAD * 2)
    descFs:SetJustifyH("LEFT")
    descFs:SetWordWrap(true)
    local hasDescription = entry.description and entry.description ~= ""
    descFs:SetText(hasDescription and (SchlingelInc:SanitizeText(entry.description) or "") or "|cff888888— keine Beschreibung —|r")

    local critFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    critFs:SetPoint("TOPLEFT", descFs, "BOTTOMLEFT", 0, -3)
    critFs:SetText("|cff888888" .. CriteriaText(entry) .. "|r")

    local height = CARD_PAD + 16 + descFs:GetStringHeight() + 3 + 14 + CARD_PAD

    if not isBuiltin then
        local editBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        editBtn:SetSize(80, 20)
        editBtn:SetPoint("TOPLEFT", critFs, "BOTTOMLEFT", 0, -6)
        editBtn:SetText("Bearbeiten")
        editBtn:SetScript("OnClick", function()
            SchlingelInc.Popup:ShowAchievementForm(entry)
        end)

        if not entry.retired then
            local retireBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
            retireBtn:SetSize(90, 20)
            retireBtn:SetPoint("LEFT", editBtn, "RIGHT", 6, 0)
            retireBtn:SetText("Einstellen")
            retireBtn:SetScript("OnClick", function()
                StaticPopup_Show("SCHLINGEL_ACHIEVEMENT_RETIRE", entry.name, nil, entry.id)
            end)
        end

        height = height + 20 + 6
    end

    card:SetHeight(height)
    return card
end

StaticPopupDialogs["SCHLINGEL_ACHIEVEMENT_RETIRE"] = {
    text = "Erfolg \"%s\" einstellen? Bereits freigeschaltete Erfolge bleiben bei den Mitgliedern erhalten, er kann aber nicht mehr neu erreicht werden.",
    button1 = "Einstellen",
    button2 = "Abbrechen",
    OnAccept = function(self)
        SchlingelInc.Achievements.Catalog:Retire(self.data)
        if SchlingelInc.OfficerPanel and SchlingelInc.OfficerPanel.RefreshAchievements then
            SchlingelInc.OfficerPanel:RefreshAchievements()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function OfficerPanel.BuildAchievementsTab(content)
    local createBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    createBtn:SetSize(120, 22)
    createBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -2)
    createBtn:SetText("Neuer Erfolg")
    createBtn:SetScript("OnClick", function()
        SchlingelInc.Popup:ShowAchievementForm(nil)
    end)

    local divider = content:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    divider:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -28)
    divider:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -28)

    local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     content, "TOPLEFT",     0, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -20, 0)
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
        for _, c in ipairs(cards) do c:Hide() end
        wipe(cards)

        local cardW = math.max(1, scrollFrame:GetWidth())
        scrollChild:SetWidth(cardW)
        local yOff = 0

        local entries = SchlingelInc.Achievements.Catalog:GetAll()

        if #entries == 0 then
            local msg = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            msg:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, 0)
            msg:SetText("Noch keine Erfolge angelegt.")
            msg:SetTextColor(0.6, 0.6, 0.6, 1)
            table.insert(cards, msg)
            yOff = -20
        else
            for _, entry in ipairs(entries) do
                local card = CreateCard(scrollChild, cardW, entry)
                card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOff)
                table.insert(cards, card)
                yOff = yOff - card:GetHeight() - CARD_GAP
            end
        end

        scrollChild:SetHeight(math.max(1, -yOff))
    end

    content.Refresh = Refresh
end
