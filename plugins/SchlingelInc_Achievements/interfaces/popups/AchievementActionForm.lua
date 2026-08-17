-- interfaces/popups/AchievementActionForm.lua
-- Shared builder for the officer "grant"/"revoke" achievement popups.

SchlingelInc.Popup = SchlingelInc.Popup or {}

local FORM_W  = 340
local FORM_H  = 420
local CARD_GAP = 6
local CARD_PAD = 8
local STATUS_TIMEOUT = 5

local function CreateCard(parent, cardW, entry, onClick)
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
    card:SetHeight(40)

    local nameFs = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -CARD_PAD)
    nameFs:SetPoint("RIGHT", card, "RIGHT", -CARD_PAD, 0)
    nameFs:SetJustifyH("LEFT")
    nameFs:SetText(SchlingelInc:SanitizeText(entry.name) or "(ohne Namen)")
    nameFs:SetTextColor(1, 1, 1, 1)

    local metaFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    metaFs:SetPoint("TOPLEFT", nameFs, "BOTTOMLEFT", 0, -3)
    metaFs:SetText((entry.points or 0) .. " Punkte — " .. (SchlingelInc.Achievements.KIND_LABELS[entry.kind] or entry.kind))
    metaFs:SetTextColor(0.6, 0.8, 1, 1)

    card:SetScript("OnEnter", function() card:SetBackdropBorderColor(1, 0.82, 0, 1) end)
    card:SetScript("OnLeave", function() card:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end)
    card:SetScript("OnClick", function() onClick(entry) end)

    return card
end

local function BuildForm(frameName, positionKey)
    local f = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    f:SetSize(FORM_W, FORM_H)
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop(SchlingelInc.Constants.BACKDROP)
    f:SetBackdropColor(0.07, 0.07, 0.07, 0.98)
    f:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SchlingelInc:SaveFramePosition(self, positionKey)
    end)
    SchlingelInc:RestoreFramePosition(f, positionKey, "CENTER", 0, 80)
    SchlingelInc:RegisterFrameForEscape(f)
    f:Hide()

    local titleFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFs:SetPoint("TOP", f, "TOP", 0, -14)
    titleFs:SetTextColor(1, 0.82, 0, 1)
    f.titleFs = titleFs

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        if f.timeoutTimer then f.timeoutTimer:Cancel() f.timeoutTimer = nil end
        f:Hide()
    end)

    local statusFs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusFs:SetPoint("TOP", f, "TOP", 0, -32)
    statusFs:SetPoint("LEFT", f, "LEFT", 10, 0)
    statusFs:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    statusFs:SetJustifyH("CENTER")
    f.statusFs = statusFs

    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    divider:SetPoint("TOPLEFT",  f, "TOPLEFT",  10, -46)
    divider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -46)

    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     f, "TOPLEFT",     10, -52)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 14)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        sf:SetVerticalScroll(
            math.max(0, math.min(sf:GetVerticalScrollRange(), sf:GetVerticalScroll() - delta * 24))
        )
    end)
    f.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild

    f.cards = {}
    f.collapsedCategories = SchlingelInc.Achievements.NewCollapsedCategoryState()

    return f
end

function SchlingelInc.Popup.CreateAchievementActionForm(cfg)
    local currentTarget = nil

    StaticPopupDialogs[cfg.confirmDialogKey] = {
        text = cfg.confirmText,
        button1 = cfg.confirmButton,
        button2 = "Abbrechen",
        OnAccept = function(self)
            local data = self.data
            cfg.performAction(data.target, data.id)
            local f = SchlingelInc.Popup[cfg.popupKey]
            if f then f:Hide() end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local function Refresh(f)
        for _, c in ipairs(f.cards) do c:Hide() end
        wipe(f.cards)

        local cardW = math.max(1, f.scrollFrame:GetWidth())
        f.scrollChild:SetWidth(cardW)

        local eligible = {}
        for _, entry in ipairs(cfg.getEntries()) do
            if SchlingelInc.Achievements.IsGrantableKind(entry.kind) and cfg.isEligible(f, entry) then
                table.insert(eligible, entry)
            end
        end

        local yOff = 0
        if #eligible == 0 then
            local msg = f.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            msg:SetPoint("TOPLEFT", f.scrollChild, "TOPLEFT", 4, 0)
            msg:SetText(f[cfg.eligibleSetField] and cfg.emptyWithSet or cfg.emptyNoSet)
            msg:SetTextColor(0.6, 0.6, 0.6, 1)
            table.insert(f.cards, msg)
            yOff = -20
        else
            local groups = SchlingelInc.Achievements.GroupByKind(eligible)

            for _, kind in ipairs(SchlingelInc.Achievements.CATEGORY_ORDER) do
                local list = groups[kind]
                if list and #list > 0 then
                    local header = SchlingelInc.Achievements.CreateCategoryHeader(
                        f.scrollChild, cardW, kind, #list, f.collapsedCategories, function() Refresh(f) end)
                    header:SetPoint("TOPLEFT", f.scrollChild, "TOPLEFT", 0, yOff)
                    table.insert(f.cards, header)
                    yOff = yOff - header:GetHeight() - 6

                    if not f.collapsedCategories[kind] then
                        for _, entry in ipairs(list) do
                            local card = CreateCard(f.scrollChild, cardW, entry, function(selected)
                                StaticPopup_Show(cfg.confirmDialogKey, selected.name, currentTarget,
                                    { target = currentTarget, id = selected.id })
                            end)
                            card:SetPoint("TOPLEFT", f.scrollChild, "TOPLEFT", 0, yOff)
                            table.insert(f.cards, card)
                            yOff = yOff - card:GetHeight() - CARD_GAP
                        end
                    end

                    yOff = yOff - 6
                end
            end
        end

        f.scrollChild:SetHeight(math.max(1, -yOff))
    end

    local function Show(targetName)
        if not targetName or targetName == "" then return end
        if not SchlingelInc.Popup[cfg.popupKey] then
            SchlingelInc.Popup[cfg.popupKey] = BuildForm(cfg.frameName, cfg.positionKey)
        end
        local f = SchlingelInc.Popup[cfg.popupKey]

        if f.timeoutTimer then f.timeoutTimer:Cancel() f.timeoutTimer = nil end

        currentTarget = targetName
        f[cfg.eligibleSetField] = nil
        f.pendingChunks = { received = {}, receivedCount = 0, total = nil, mergedSet = {} }
        f.titleFs:SetText(cfg.titlePrefix .. targetName)
        f.statusFs:SetTextColor(0.8, 0.8, 0.4, 1)
        f.statusFs:SetText("Frage Freischaltungsstatus ab...")
        Refresh(f)
        SchlingelInc:RestoreFramePosition(f, cfg.positionKey, "CENTER", 0, 80)
        f:Show()

        cfg.requestEligibility(targetName)
        f.timeoutTimer = C_Timer.NewTimer(STATUS_TIMEOUT, function()
            f.timeoutTimer = nil
            if currentTarget ~= targetName or f[cfg.eligibleSetField] then return end

            local pending = f.pendingChunks
            if pending and pending.receivedCount > 0 then
                f[cfg.eligibleSetField] = pending.mergedSet
                f.statusFs:SetText("")
                Refresh(f)
            else
                f.statusFs:SetTextColor(1, 0.4, 0.4, 1)
                f.statusFs:SetText("Status konnte nicht bestätigt werden — bitte beim Spieler nachfragen.")
            end
        end)
    end

    local function OnReceived(senderShort, chunkIndex, totalChunks, ids)
        local f = SchlingelInc.Popup[cfg.popupKey]
        if not f or not f:IsShown() or currentTarget ~= senderShort then return end

        local pending = f.pendingChunks
        if not pending or pending.received[chunkIndex] then return end

        pending.received[chunkIndex] = true
        pending.receivedCount = pending.receivedCount + 1
        pending.total = totalChunks
        for _, id in ipairs(ids) do pending.mergedSet[id] = true end

        if pending.receivedCount < pending.total then return end

        if f.timeoutTimer then f.timeoutTimer:Cancel() f.timeoutTimer = nil end
        f[cfg.eligibleSetField] = pending.mergedSet
        f.statusFs:SetText("")
        Refresh(f)
    end

    return { Show = Show, OnReceived = OnReceived }
end
