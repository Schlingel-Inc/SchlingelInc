-- GuildPanel/TabRaid.lua
-- "Raid" tab: LFG-light. Scrollable list of active raid postings, soonest first.

local GP = SchlingelInc.GuildPanel

local CARD_GAP  = 6
local CARD_PAD  = 8
local ROW_H     = 16

local expanded = {}

local function FormatWhen(timestamp)
    return date("%d.%m. %H:%M", timestamp)
end

local ROLE_LABELS = { Tank = "Tank", Heal = "Heal", DPS = "DD" }

local function RoleCountsText(id)
    local counts = SchlingelInc.Raid:GetRoleCounts(id)
    local parts = {}
    for _, role in ipairs(SchlingelInc.Constants.ROLES) do
        table.insert(parts, ROLE_LABELS[role] .. ": " .. counts[role])
    end
    return table.concat(parts, "  ")
end

local function CreateCard(parent, cardW, entry)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    card:SetBackdropColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BG))
    card:SetBackdropBorderColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BORDER))
    card:SetWidth(cardW)
    card:EnableMouse(true)

    local isOwn       = entry.poster == UnitName("player")
    local ownSignal    = SchlingelInc.Raid:GetOwnSignal(entry.id)
    local isExpanded   = expanded[entry.id] == true

    local titleFs = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -CARD_PAD)
    titleFs:SetWidth(cardW - CARD_PAD * 2 - 90)
    titleFs:SetJustifyH("LEFT")
    titleFs:SetText(SchlingelInc:SanitizeText(entry.title))
    titleFs:SetTextColor(1, 1, 1, 1)

    local whenFs = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    whenFs:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PAD, -CARD_PAD)
    whenFs:SetJustifyH("RIGHT")
    whenFs:SetText(FormatWhen(entry.timestamp))
    whenFs:SetTextColor(1, 0.82, 0, 1)

    local subFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subFs:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -3)
    subFs:SetWidth(cardW - CARD_PAD * 2)
    subFs:SetJustifyH("LEFT")
    subFs:SetWordWrap(false)
    subFs:SetText(entry.instance .. "  |cff888888— " .. SchlingelInc:SanitizeText(entry.poster) .. "|r")

    local badgeFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    badgeFs:SetPoint("TOPLEFT", subFs, "BOTTOMLEFT", 0, -3)
    badgeFs:SetText(RoleCountsText(entry.id))
    badgeFs:SetTextColor(0.6, 0.8, 1, 1)

    if ownSignal then
        local ownFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        ownFs:SetPoint("LEFT", badgeFs, "RIGHT", 10, 0)
        ownFs:SetText("|cff44ff44Zugesagt (" .. ownSignal.role .. ")|r")
    end

    local height = CARD_PAD + 16 + 14 + 14 + CARD_PAD

    if isExpanded then
        local divider = card:CreateTexture(nil, "ARTWORK")
        divider:SetHeight(1)
        divider:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.DIVIDER))
        divider:SetPoint("TOPLEFT",  badgeFs, "BOTTOMLEFT",  0, -(CARD_PAD))
        divider:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PAD, -(height - CARD_PAD))
        height = height + 6

        if entry.note ~= "" then
            local noteFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            noteFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -height)
            noteFs:SetWidth(cardW - CARD_PAD * 2)
            noteFs:SetJustifyH("LEFT")
            noteFs:SetWordWrap(true)
            noteFs:SetText("|cffaaaaaaNotiz:|r " .. SchlingelInc:SanitizeText(entry.note))
            height = height + noteFs:GetStringHeight() + 6
        end

        local signups = SchlingelInc.Raid:GetSignals(entry.id)
        if #signups == 0 then
            local emptyFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            emptyFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -height)
            emptyFs:SetText("|cff888888Noch keine Zusagen.|r")
            height = height + ROW_H
        else
            for _, s in ipairs(signups) do
                local rowFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                rowFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -height)
                rowFs:SetWidth(cardW - CARD_PAD * 2 - (isOwn and 16 or 0))
                rowFs:SetJustifyH("LEFT")
                rowFs:SetText(SchlingelInc:SanitizeText(s.name) .. " |cff6699ff(" .. s.role .. ")|r")

                if isOwn then
                    local removeBtn = CreateFrame("Button", nil, card)
                    removeBtn:SetSize(14, 14)
                    removeBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PAD, -height - 1)
                    local removeFs = removeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    removeFs:SetAllPoints()
                    removeFs:SetJustifyH("CENTER")
                    removeFs:SetText("x")
                    removeFs:SetTextColor(0.7, 0.3, 0.3, 1)
                    removeBtn:SetScript("OnClick", function()
                        SchlingelInc.Raid:RemoveParticipant(entry.id, s.name)
                        SchlingelInc.GuildPanel:RefreshRaid()
                    end)
                    removeBtn:SetScript("OnEnter", function() removeFs:SetTextColor(1, 0.4, 0.4, 1) end)
                    removeBtn:SetScript("OnLeave", function() removeFs:SetTextColor(0.7, 0.3, 0.3, 1) end)
                end

                height = height + ROW_H
            end
        end

        height = height + 6

        local signupBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        signupBtn:SetSize(110, 20)
        signupBtn:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -height)
        signupBtn:SetText(ownSignal and "Zusage ändern" or "Zusagen")
        signupBtn:SetScript("OnClick", function()
            SchlingelInc.Popup:ShowRaidSignup(entry, ownSignal)
        end)

        if isOwn then
            local editBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
            editBtn:SetSize(90, 20)
            editBtn:SetPoint("LEFT", signupBtn, "RIGHT", 6, 0)
            editBtn:SetText("Bearbeiten")
            editBtn:SetScript("OnClick", function()
                SchlingelInc.Popup:ShowRaidForm(entry)
            end)

            local cancelBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
            cancelBtn:SetSize(90, 20)
            cancelBtn:SetPoint("LEFT", editBtn, "RIGHT", 6, 0)
            cancelBtn:SetText("Absagen")
            cancelBtn:SetScript("OnClick", function()
                SchlingelInc.Raid:Cancel(entry.id)
                SchlingelInc.GuildPanel:RefreshRaid()
            end)

            -- Same underlying action as "Absagen" (hides the entry immediately instead of
            -- waiting out the grace period) — separate button so the wording matches intent.
            local doneBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
            doneBtn:SetSize(90, 20)
            doneBtn:SetPoint("LEFT", cancelBtn, "RIGHT", 6, 0)
            doneBtn:SetText("Erledigt")
            doneBtn:SetScript("OnClick", function()
                SchlingelInc.Raid:Cancel(entry.id)
                SchlingelInc.GuildPanel:RefreshRaid()
            end)

            height = height + 20 + 6

            local addParticipantBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
            addParticipantBtn:SetSize(120, 20)
            addParticipantBtn:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -height)
            addParticipantBtn:SetText("+ Teilnehmer")
            addParticipantBtn:SetScript("OnClick", function()
                SchlingelInc.Popup:ShowRaidAddParticipantForm(entry)
            end)
        end

        height = height + 20 + CARD_PAD
    end

    card:SetHeight(height)

    card:SetScript("OnClick", function()
        expanded[entry.id] = not isExpanded or nil
        SchlingelInc.GuildPanel:RefreshRaid()
    end)
    card:SetScript("OnEnter", function() card:SetBackdropBorderColor(0.6, 0.6, 0.6, 1) end)
    card:SetScript("OnLeave", function() card:SetBackdropBorderColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BORDER)) end)

    return card
end

function GP.BuildRaidTab(content)
    local postBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    postBtn:SetSize(100, 22)
    postBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -2)
    postBtn:SetText("Raid posten")
    postBtn:SetScript("OnClick", function()
        SchlingelInc.Popup:ShowRaidForm(nil)
    end)

    local divider = content:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.DIVIDER))
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

        local entries = SchlingelInc.Raid:GetActiveEntries()

        if #entries == 0 then
            local msg = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            msg:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, 0)
            msg:SetText("Keine aktiven Raids. Sei der Erste und poste einen!")
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
