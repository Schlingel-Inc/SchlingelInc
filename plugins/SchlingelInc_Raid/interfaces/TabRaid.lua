-- GuildPanel/TabRaid.lua
-- "Raid" tab: LFG-light. Scrollable list of active raid postings, soonest first.
--
-- Cards are pooled: each card frame is built once (CreateCardShell) and reused
-- across refreshes (UpdateCard just re-texts/resizes/repositions it), keyed by
-- entry id so the same entry keeps the same frame. Total card-frame count settles
-- at the highest number of concurrently active raids this session, instead of
-- growing forever (every past Refresh() used to leave its old frames behind,
-- hidden but never destroyed — Classic WoW has no way to actually destroy a frame).

local GP = SchlingelInc.GuildPanel

local CARD_GAP     = 6
local CARD_PAD     = 8
local ROW_H        = 16
local COL_GAP      = 4
local COL_HEADER_H = 12
local SIGNUP_SLOTS = 40 -- no per-role or total cap; generous pool so any real-world signup count still renders
local ROWS_PER_SUBCOL = 3
local SUBCOL_GAP   = 3
local REFRESH_COOLDOWN_SECONDS = 30
-- DPS normally wraps into 2 name-columns (6 DD in 10-man), Tank/Heal stay single
-- -column, so DPS gets twice the width instead of an equal three-way split.
local COL_WEIGHTS  = { Tank = 1, Heal = 1, DPS = 2 }

local expanded = {}

local function FormatWhen(timestamp)
    return date("%d.%m. %H:%M", timestamp)
end

local ROLE_LABELS = { Tank = "Tank", Heal = "Heal", DPS = "DD" }

-- Matches the blue/green/red role convention used across raid-frame addons
-- (Grid, VuhDo, etc.), so the grouping reads at a glance without the label.
local ROLE_HEADER_COLORS = {
    Tank = { 0.45, 0.65, 0.95 },
    Heal = { 0.4,  0.85, 0.45 },
    DPS  = { 0.9,  0.45, 0.35 },
}

local function HexColor(rgb)
    return string.format("|cff%02x%02x%02x", rgb[1] * 255, rgb[2] * 255, rgb[3] * 255)
end

local function RoleCountsText(id)
    local counts = SchlingelInc.Raid:GetRoleCounts(id)
    local parts = {}
    for _, role in ipairs(SchlingelInc.Constants.ROLES) do
        local hc = ROLE_HEADER_COLORS[role]
        table.insert(parts, HexColor(hc) .. ROLE_LABELS[role] .. ": " .. counts[role] .. "|r")
    end
    return table.concat(parts, "  ")
end

-- Builds every element a card could ever need, once. Nothing here runs again
-- for this card's lifetime — UpdateCard only shows/hides/re-texts/repositions.
local function CreateCardShell(parent, cardW)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    card:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
    card:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    card:SetWidth(cardW)
    card:EnableMouse(true)

    card.titleFs = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    card.titleFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -CARD_PAD)
    card.titleFs:SetWidth(cardW - CARD_PAD * 2 - 90)
    card.titleFs:SetJustifyH("LEFT")
    card.titleFs:SetTextColor(1, 1, 1, 1)

    card.whenFs = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.whenFs:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PAD, -CARD_PAD)
    card.whenFs:SetJustifyH("RIGHT")
    card.whenFs:SetTextColor(1, 0.82, 0, 1)

    card.subFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.subFs:SetPoint("TOPLEFT", card.titleFs, "BOTTOMLEFT", 0, -3)
    card.subFs:SetWidth(cardW - CARD_PAD * 2)
    card.subFs:SetJustifyH("LEFT")
    card.subFs:SetWordWrap(false)

    card.badgeFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.badgeFs:SetPoint("TOPLEFT", card.subFs, "BOTTOMLEFT", 0, -3)
    card.badgeFs:SetTextColor(0.6, 0.8, 1, 1)

    card.ownFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.ownFs:SetPoint("LEFT", card.badgeFs, "RIGHT", 10, 0)

    card.divider = card:CreateTexture(nil, "ARTWORK")
    card.divider:SetHeight(1)
    card.divider:SetColorTexture(0.35, 0.35, 0.35, 0.8)

    card.noteFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.noteFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, 0)
    card.noteFs:SetWidth(cardW - CARD_PAD * 2)
    card.noteFs:SetJustifyH("LEFT")
    card.noteFs:SetWordWrap(true)

    card.emptyFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.emptyFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, 0)
    card.emptyFs:SetText("|cff888888Noch keine Zusagen.|r")

    -- One column per role (Tank/Heal/DPS), each with its own header and a fixed
    -- pool of row slots — grouping is a column, not a per-row role suffix.
    card.roleColumns = {}
    for _, role in ipairs(SchlingelInc.Constants.ROLES) do
        local col = { rows = {} }

        col.headerFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        col.headerFs:SetJustifyH("LEFT")
        local hc = ROLE_HEADER_COLORS[role] or { 0.6, 0.6, 0.6 }
        col.headerFs:SetTextColor(hc[1], hc[2], hc[3], 1)

        for i = 1, SIGNUP_SLOTS do
            local row = {}
            row.fs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.fs:SetJustifyH("LEFT")

            row.removeBtn = CreateFrame("Button", nil, card)
            row.removeBtn:SetSize(14, 14)
            row.removeFs = row.removeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.removeFs:SetAllPoints()
            row.removeFs:SetJustifyH("CENTER")
            row.removeFs:SetText("x")
            row.removeFs:SetTextColor(0.7, 0.3, 0.3, 1)
            row.removeBtn:SetScript("OnClick", function()
                SchlingelInc.Raid:RemoveParticipant(card.entry.id, row.signupName)
                SchlingelInc.GuildPanel:RefreshRaid()
            end)
            row.removeBtn:SetScript("OnEnter", function() row.removeFs:SetTextColor(1, 0.4, 0.4, 1) end)
            row.removeBtn:SetScript("OnLeave", function() row.removeFs:SetTextColor(0.7, 0.3, 0.3, 1) end)

            col.rows[i] = row
        end

        card.roleColumns[role] = col
    end

    card.signupBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    card.signupBtn:SetSize(110, 20)
    card.signupBtn:SetScript("OnClick", function()
        SchlingelInc.Popup:ShowRaidSignup(card.entry, SchlingelInc.Raid:GetOwnSignal(card.entry.id))
    end)

    card.editBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    card.editBtn:SetSize(90, 20)
    card.editBtn:SetText("Bearbeiten")
    card.editBtn:SetScript("OnClick", function()
        SchlingelInc.Popup:ShowRaidForm(card.entry)
    end)

    card.cancelBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    card.cancelBtn:SetSize(90, 20)
    card.cancelBtn:SetText("Absagen")
    card.cancelBtn:SetScript("OnClick", function()
        SchlingelInc.Raid:Cancel(card.entry.id)
        SchlingelInc.GuildPanel:RefreshRaid()
    end)

    -- Same underlying action as "Absagen" (hides the entry immediately instead of
    -- waiting out the grace period) — separate button so the wording matches intent.
    card.doneBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    card.doneBtn:SetSize(90, 20)
    card.doneBtn:SetText("Erledigt")
    card.doneBtn:SetScript("OnClick", function()
        SchlingelInc.Raid:Cancel(card.entry.id)
        SchlingelInc.GuildPanel:RefreshRaid()
    end)

    card.addParticipantBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    card.addParticipantBtn:SetSize(120, 20)
    card.addParticipantBtn:SetText("+ Teilnehmer")
    card.addParticipantBtn:SetScript("OnClick", function()
        SchlingelInc.Popup:ShowRaidAddParticipantForm(card.entry)
    end)

    card:SetScript("OnClick", function()
        expanded[card.entry.id] = not (expanded[card.entry.id] == true) or nil
        SchlingelInc.GuildPanel:RefreshRaid()
    end)
    card:SetScript("OnEnter", function() card:SetBackdropBorderColor(0.6, 0.6, 0.6, 1) end)
    card:SetScript("OnLeave", function() card:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end)

    return card
end

-- Re-texts/resizes/repositions an existing shell for `entry`. Never creates a
-- frame. Returns the card's total height so the caller can stack the next card.
local function UpdateCard(card, cardW, entry)
    card.entry = entry
    card:SetWidth(cardW)
    card.titleFs:SetWidth(cardW - CARD_PAD * 2 - 90)
    card.subFs:SetWidth(cardW - CARD_PAD * 2)
    card.noteFs:SetWidth(cardW - CARD_PAD * 2)

    local isOwn      = entry.poster == UnitName("player")
    local ownSignal  = SchlingelInc.Raid:GetOwnSignal(entry.id)
    local isExpanded = expanded[entry.id] == true

    card.titleFs:SetText(SchlingelInc:SanitizeText(entry.title))
    card.whenFs:SetText(FormatWhen(entry.timestamp))
    card.subFs:SetText(entry.instance .. "  |cff888888— " .. SchlingelInc:SanitizeText(entry.poster) .. "|r")
    card.badgeFs:SetText(RoleCountsText(entry.id))

    if ownSignal then
        card.ownFs:SetText("|cff44ff44Zugesagt (" .. ownSignal.role .. ")|r")
        card.ownFs:Show()
    else
        card.ownFs:Hide()
    end

    local height = CARD_PAD + 16 + 14 + 14 + CARD_PAD

    card.divider:Hide()
    card.noteFs:Hide()
    card.emptyFs:Hide()
    for _, col in pairs(card.roleColumns) do
        col.headerFs:Hide()
        for _, row in ipairs(col.rows) do
            row.fs:Hide()
            row.removeBtn:Hide()
        end
    end
    card.signupBtn:Hide()
    card.editBtn:Hide()
    card.cancelBtn:Hide()
    card.doneBtn:Hide()
    card.addParticipantBtn:Hide()

    if isExpanded then
        card.divider:ClearAllPoints()
        card.divider:SetPoint("TOPLEFT",  card.badgeFs, "BOTTOMLEFT",  0, -(CARD_PAD))
        card.divider:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PAD, -(height - CARD_PAD))
        card.divider:Show()
        height = height + 6

        if entry.note ~= "" then
            card.noteFs:ClearAllPoints()
            card.noteFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -height)
            card.noteFs:SetText("|cffaaaaaaNotiz:|r " .. SchlingelInc:SanitizeText(entry.note))
            card.noteFs:Show()
            height = height + card.noteFs:GetStringHeight() + 6
        end

        local signups = SchlingelInc.Raid:GetSignals(entry.id)
        if #signups == 0 then
            card.emptyFs:ClearAllPoints()
            card.emptyFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -height)
            card.emptyFs:Show()
            height = height + ROW_H
        else
            local byRole = {}
            for _, role in ipairs(SchlingelInc.Constants.ROLES) do byRole[role] = {} end
            for _, s in ipairs(signups) do
                local list = byRole[s.role]
                if list then table.insert(list, s) end
            end

            local innerW = cardW - CARD_PAD * 2
            local numCols = #SchlingelInc.Constants.ROLES
            local totalWeight = 0
            for _, role in ipairs(SchlingelInc.Constants.ROLES) do
                totalWeight = totalWeight + (COL_WEIGHTS[role] or 1)
            end
            local unitW = (innerW - COL_GAP * (numCols - 1)) / totalWeight

            local maxRows = 0
            local colX = CARD_PAD

            for _, role in ipairs(SchlingelInc.Constants.ROLES) do
                local col  = card.roleColumns[role]
                local list = byRole[role]
                local colW = unitW * (COL_WEIGHTS[role] or 1)

                col.headerFs:ClearAllPoints()
                col.headerFs:SetPoint("TOPLEFT", card, "TOPLEFT", colX, -height)
                col.headerFs:SetText((ROLE_LABELS[role] or role) .. " (" .. #list .. ")")
                col.headerFs:Show()

                -- Wraps into a new sub-column every ROWS_PER_SUBCOL entries, so a
                -- role with many signups (DPS is usually ~6 in 10-man content)
                -- doesn't tower over the other two columns.
                local subColCount = math.max(1, math.ceil(#list / ROWS_PER_SUBCOL))
                local subColW = (colW - SUBCOL_GAP * (subColCount - 1)) / subColCount

                for i, row in ipairs(col.rows) do
                    local s = list[i]
                    if s then
                        local subIdx   = math.floor((i - 1) / ROWS_PER_SUBCOL)
                        local rowInSub = (i - 1) % ROWS_PER_SUBCOL
                        local subColX  = colX + subIdx * (subColW + SUBCOL_GAP)
                        local rowY     = height + COL_HEADER_H + rowInSub * ROW_H

                        row.signupName = s.name
                        row.fs:ClearAllPoints()
                        row.fs:SetPoint("TOPLEFT", card, "TOPLEFT", subColX, -rowY)
                        row.fs:SetWidth(subColW - (isOwn and 16 or 0))
                        row.fs:SetText(SchlingelInc:SanitizeText(s.name))
                        row.fs:Show()

                        if isOwn then
                            row.removeBtn:ClearAllPoints()
                            row.removeBtn:SetPoint("TOPLEFT", card, "TOPLEFT", subColX + subColW - 14, -rowY - 1)
                            row.removeBtn:Show()
                        end
                    end
                end

                local colRows = math.min(#list, ROWS_PER_SUBCOL)
                if colRows > maxRows then maxRows = colRows end
                colX = colX + colW + COL_GAP
            end

            height = height + COL_HEADER_H + maxRows * ROW_H
        end

        height = height + 6

        card.signupBtn:ClearAllPoints()
        card.signupBtn:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -height)
        card.signupBtn:SetText(ownSignal and "Zusage ändern" or "Zusagen")
        card.signupBtn:Show()

        if isOwn then
            card.editBtn:ClearAllPoints()
            card.editBtn:SetPoint("LEFT", card.signupBtn, "RIGHT", 6, 0)
            card.editBtn:Show()

            card.cancelBtn:ClearAllPoints()
            card.cancelBtn:SetPoint("LEFT", card.editBtn, "RIGHT", 6, 0)
            card.cancelBtn:Show()

            card.doneBtn:ClearAllPoints()
            card.doneBtn:SetPoint("LEFT", card.cancelBtn, "RIGHT", 6, 0)
            card.doneBtn:Show()

            height = height + 20 + 6

            card.addParticipantBtn:ClearAllPoints()
            card.addParticipantBtn:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -height)
            card.addParticipantBtn:Show()
        end

        height = height + 20 + CARD_PAD
    end

    card:SetHeight(height)
    return height
end

function GP.BuildRaidTab(content)
    local refreshBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    refreshBtn:SetSize(100, 22)
    refreshBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", -100, -2)
    refreshBtn:SetText("Aktualisieren")
    refreshBtn:SetScript("OnClick", function()
        SchlingelInc.Raid:RequestSync()
        refreshBtn:Disable()
        C_Timer.After(REFRESH_COOLDOWN_SECONDS, function() refreshBtn:Enable() end)
    end)
    local postBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    postBtn:SetSize(100, 22)
    postBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -2)
    postBtn:SetText("Raid posten")
    postBtn:SetScript("OnClick", function()
        SchlingelInc.Popup:ShowRaidForm(nil)
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

    local emptyMsg = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyMsg:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, 0)
    emptyMsg:SetText("Keine aktiven Raids. Sei der Erste und poste einen!")
    emptyMsg:SetTextColor(0.6, 0.6, 0.6, 1)
    emptyMsg:Hide()

    -- id -> card currently showing that entry
    local cardsByEntryId = {}
    -- released cards, available for the next new entry id
    local freeCards = {}
    -- category headers, recreated each refresh (small bounded set, one per instance)
    local headers = {}
    local collapsedInstances = SchlingelInc.UI.NewCollapsedState(SchlingelInc.Raid.Constants.RAID_INSTANCES)

    local function AcquireCard(cardW)
        local card = table.remove(freeCards)
        if not card then
            card = CreateCardShell(scrollChild, cardW)
        end
        card:Show()
        return card
    end

    local function Refresh()
        emptyMsg:Hide()

        for _, h in ipairs(headers) do h:Hide() end
        wipe(headers)

        local cardW = math.max(1, scrollFrame:GetWidth())
        scrollChild:SetWidth(cardW)

        local entries = SchlingelInc.Raid:GetActiveEntries()

        if #entries == 0 then
            emptyMsg:Show()
            for id, card in pairs(cardsByEntryId) do
                card:Hide()
                cardsByEntryId[id] = nil
                table.insert(freeCards, card)
            end
            scrollChild:SetHeight(20)
            return
        end

        local stillActive = {}
        for _, entry in ipairs(entries) do
            stillActive[entry.id] = true
        end
        for id, card in pairs(cardsByEntryId) do
            if not stillActive[id] then
                card:Hide()
                cardsByEntryId[id] = nil
                table.insert(freeCards, card)
            end
        end

        local groups = {}
        for _, entry in ipairs(entries) do
            groups[entry.instance] = groups[entry.instance] or {}
            table.insert(groups[entry.instance], entry)
        end

        local instanceNames = {}
        for name in pairs(groups) do table.insert(instanceNames, name) end
        table.sort(instanceNames)

        local yOff = 0
        for _, instanceName in ipairs(instanceNames) do
            local list = groups[instanceName]

            local header = SchlingelInc.UI.CreateCollapsibleHeader(
                scrollChild, cardW, instanceName, instanceName, #list, collapsedInstances, Refresh)
            header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOff)
            table.insert(headers, header)
            yOff = yOff - header:GetHeight() - 6

            if not collapsedInstances[instanceName] then
                for _, entry in ipairs(list) do
                    local card = cardsByEntryId[entry.id]
                    if not card then
                        card = AcquireCard(cardW)
                        cardsByEntryId[entry.id] = card
                    end
                    card:Show()
                    local height = UpdateCard(card, cardW, entry)
                    card:ClearAllPoints()
                    card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOff)
                    yOff = yOff - height - CARD_GAP
                end
            else
                for _, entry in ipairs(list) do
                    local card = cardsByEntryId[entry.id]
                    if card then card:Hide() end
                end
            end

            yOff = yOff - 6
        end

        scrollChild:SetHeight(math.max(1, -yOff))
    end

    content.Refresh = Refresh
end
