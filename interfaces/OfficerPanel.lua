-- interfaces/OfficerPanel.lua
-- Tabbed officer panel: Rules tab (read/write for officers, read-only for members)
-- and Inactive Members tab (officers only, embedded list).

SchlingelInc.OfficerPanel = {}

local frame
local PANEL_W, PANEL_H = 500, 420
local TITLE_H = 28
local TAB_H   = 24
local currentTab = "rules"

local BACKDROP = {
    bgFile   = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

local function IsOfficer()
    return CanGuildRemove()
end

-- ── Inactive data helper ──────────────────────────────────────────────────────

local function BuildInactiveData()
    if not IsInGuild() then return {} end
    local total = GetNumGuildMembers() or 0
    local list = {}
    for i = 1, total do
        local name, rankName, _, level, _, _, _, _, isOnline = GetGuildRosterInfo(i)
        if name and not isOnline then
            local y, mo, d, h = GetGuildRosterLastOnline(i)
            y, mo, d, h = y or 0, mo or 0, d or 0, h or 0
            local totalDays = y * 365 + mo * 30 + d + h / 24
            if y > 0 or mo > 0 or d >= SchlingelInc.Constants.INACTIVE_DAYS_THRESHOLD then
                local dur = y > 0 and (y .. " J") or mo > 0 and (mo .. " M") or (d .. " T")
                table.insert(list, {
                    name         = SchlingelInc:RemoveRealmFromName(name),
                    fullName     = name,
                    level        = level or 0,
                    rank         = rankName or "?",
                    displayDur   = dur,
                    sortableDays = totalDays,
                })
            end
        end
    end
    table.sort(list, function(a, b)
        if a.sortableDays ~= b.sortableDays then return a.sortableDays > b.sortableDays end
        return a.level > b.level
    end)
    return list
end

-- ── Panel construction ────────────────────────────────────────────────────────

local function BuildPanel()
    local f = CreateFrame("Frame", "SchlingelIncOfficerPanel", UIParent, "BackdropTemplate")
    f:SetSize(PANEL_W, PANEL_H)
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetBackdrop(BACKDROP)
    f:SetBackdropColor(0.07, 0.07, 0.07, 0.96)
    f:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SchlingelInc:SaveFramePosition(self, "officerpanel_position")
    end)
    SchlingelInc:RestoreFramePosition(f, "officerpanel_position")
    f:Hide()

    -- ── Title bar ─────────────────────────────────────────────────────────
    local titleBg = f:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -4)
    titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    titleBg:SetHeight(TITLE_H)
    titleBg:SetColorTexture(0.12, 0.12, 0.12, 1)

    local titleIcon = f:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("LEFT", titleBg, "LEFT", 6, 0)
    titleIcon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\SI_Transp_512_x_512_px.tga")

    local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleIcon, "RIGHT", 4, 0)
    titleText:SetText("Offizier Panel")
    titleText:SetTextColor(1, 0.82, 0, 1)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- ── Tab buttons ───────────────────────────────────────────────────────
    local tabDefs = {
        { id = "rules",    label = "Regeln" },
        { id = "inactive", label = "Inaktive Mitglieder" },
    }
    local tabBtns    = {}
    local tabContents = {}
    local CONTENT_TOP = -(TITLE_H + TAB_H + 14)  -- top edge of shared content area

    for i, tab in ipairs(tabDefs) do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(160, TAB_H)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", 8 + (i - 1) * 166, -(TITLE_H + 6))
        btn:EnableMouse(true)

        local tabBg = btn:CreateTexture(nil, "BACKGROUND")
        tabBg:SetAllPoints()
        tabBg:SetColorTexture(0.06, 0.06, 0.06, 1)
        btn.tabBg = tabBg

        local activeLine = btn:CreateTexture(nil, "OVERLAY")
        activeLine:SetHeight(2)
        activeLine:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  2, 0)
        activeLine:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 0)
        activeLine:SetColorTexture(1, 0.82, 0, 1)
        activeLine:Hide()
        btn.activeLine = activeLine

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetAllPoints()
        lbl:SetJustifyH("CENTER")
        lbl:SetText(tab.label)
        btn.lbl = lbl
        tabBtns[tab.id] = btn

        local content = CreateFrame("Frame", nil, f)
        content:SetPoint("TOPLEFT",     f, "TOPLEFT",     8, CONTENT_TOP)
        content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)
        content:Hide()
        tabContents[tab.id] = content
    end

    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    divider:SetPoint("TOPLEFT",  f, "TOPLEFT",  8, CONTENT_TOP + 2)
    divider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, CONTENT_TOP + 2)

    local function SwitchTab(id)
        currentTab = id
        for tid, c in pairs(tabContents) do c:SetShown(tid == id) end
        for tid, btn in pairs(tabBtns) do
            local active = tid == id
            btn.lbl:SetTextColor(active and 1 or 0.5, active and 0.82 or 0.5, active and 0 or 0.5, 1)
            btn.tabBg:SetColorTexture(active and 0.14 or 0.06, active and 0.14 or 0.06, active and 0.14 or 0.06, 1)
            btn.activeLine:SetShown(active)
        end
    end

    -- ── Rules tab ─────────────────────────────────────────────────────────
    local rc      = tabContents["rules"]
    local officer = IsOfficer()

    local ruleDefs = {
        { label = "Briefkasten sperren",                       dbKey = "mailRule" },
        { label = "Auktionshaus sperren",                      dbKey = "auctionHouseRule" },
        { label = "Handel mit Nicht-Mitgliedern sperren",      dbKey = "tradeRule" },
        { label = "Gruppierung mit Nicht-Mitgliedern sperren", dbKey = "groupingRule" },
        { label = "Duelle automatisch ablehnen",               dbKey = nil },
    }

    local checkboxes = {}
    local yOff = -8
    for _, rule in ipairs(ruleDefs) do
        local cb = CreateFrame("CheckButton", nil, rc, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", rc, "TOPLEFT", 8, yOff)
        cb:SetSize(24, 24)
        local cblbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cblbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        cblbl:SetText(rule.label)
        if rule.dbKey then
            cb:SetChecked(SchlingelInc.InfoRules[rule.dbKey] == 1)
        else
            cb:SetChecked(SchlingelOptionsDB and SchlingelOptionsDB.auto_decline_duels == true)
        end
        if not officer then
            cb:Disable()
            cblbl:SetTextColor(0.5, 0.5, 0.5, 1)
        end
        checkboxes[rule.label] = cb
        yOff = yOff - 30
    end

    yOff = yOff - 10
    local capLbl = rc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    capLbl:SetPoint("TOPLEFT", rc, "TOPLEFT", 34, yOff)
    capLbl:SetText("Aktuelles Level Cap:")
    if not officer then capLbl:SetTextColor(0.5, 0.5, 0.5, 1) end

    local capEb = CreateFrame("EditBox", nil, rc, "BackdropTemplate")
    capEb:SetSize(50, 22)
    capEb:SetPoint("LEFT", capLbl, "RIGHT", 8, 0)
    capEb:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
    capEb:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    capEb:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    capEb:SetFontObject("GameFontHighlight")
    capEb:SetTextInsets(4, 4, 0, 0)
    capEb:SetAutoFocus(false)
    capEb:SetMaxLetters(3)
    capEb:SetNumeric(true)
    capEb:SetText(tostring(SchlingelInc.Rules.CurrentCap or 0))
    if not officer then capEb:Disable() end

    if not officer then
        local notice = rc:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        notice:SetPoint("BOTTOMLEFT", rc, "BOTTOMLEFT", 8, 10)
        notice:SetTextColor(0.55, 0.55, 0.55, 1)
        notice:SetText("Nur lesen — Offiziersrechte erforderlich zum Ändern")
    else
        -- Wizard button on the left, update button on the right — no overlap
        local wizBtn = CreateFrame("Button", nil, rc, "UIPanelButtonTemplate")
        wizBtn:SetSize(130, 26)
        wizBtn:SetPoint("BOTTOMLEFT", rc, "BOTTOMLEFT", 8, 8)
        wizBtn:SetText("Offi-Einrichtung")
        wizBtn:SetScript("OnClick", function()
            f:Hide()
            SchlingelInc:ShowOfficerWizard()
        end)

        local updateBtn = CreateFrame("Button", nil, rc, "UIPanelButtonTemplate")
        updateBtn:SetSize(180, 26)
        updateBtn:SetPoint("BOTTOMRIGHT", rc, "BOTTOMRIGHT", -8, 8)
        updateBtn:SetText("Gildeninfo aktualisieren")
        updateBtn:SetScript("OnClick", function()
            local cap = tonumber(capEb:GetText()) or 0
            SchlingelInc:WriteGuildInfo(
                checkboxes["Briefkasten sperren"]:GetChecked(),
                checkboxes["Auktionshaus sperren"]:GetChecked(),
                checkboxes["Handel mit Nicht-Mitgliedern sperren"]:GetChecked(),
                checkboxes["Gruppierung mit Nicht-Mitgliedern sperren"]:GetChecked(),
                cap
            )
            SchlingelOptionsDB = SchlingelOptionsDB or {}
            SchlingelOptionsDB.auto_decline_duels = checkboxes["Duelle automatisch ablehnen"]:GetChecked() == true
        end)
    end

    -- ── Inactive Members tab ──────────────────────────────────────────────
    local ic = tabContents["inactive"]

    -- Column definitions: { label, xOffset, width }
    local COLS = {
        { label = "Name",       x = 0,   w = 140 },
        { label = "Level",      x = 144, w = 36  },
        { label = "Rang",       x = 184, w = 120 },
        { label = "Offline",    x = 308, w = 70  },
    }

    for _, col in ipairs(COLS) do
        local hdr = ic:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hdr:SetPoint("TOPLEFT", ic, "TOPLEFT", col.x + 4, -6)
        hdr:SetWidth(col.w)
        hdr:SetJustifyH("LEFT")
        hdr:SetText(col.label)
        hdr:SetTextColor(1, 0.82, 0, 1)
    end

    local hdrDiv = ic:CreateTexture(nil, "ARTWORK")
    hdrDiv:SetHeight(1)
    hdrDiv:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    hdrDiv:SetPoint("TOPLEFT",  ic, "TOPLEFT",  4, -22)
    hdrDiv:SetPoint("TOPRIGHT", ic, "TOPRIGHT", -4, -22)

    local SCROLL_CONTENT_W = PANEL_W - 8 - 8 - 20  -- panel inner - scrollbar
    local scrollFrame = CreateFrame("ScrollFrame", nil, ic, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     ic, "TOPLEFT",     4, -26)
    scrollFrame:SetPoint("BOTTOMRIGHT", ic, "BOTTOMRIGHT", -20, 36)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        sf:SetVerticalScroll(
            math.max(0, math.min(sf:GetVerticalScrollRange(), sf:GetVerticalScroll() - delta * 20))
        )
    end)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(SCROLL_CONTENT_W)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    ic.scrollChild  = scrollChild
    ic.inactiveRows = {}

    local refreshBtn = CreateFrame("Button", nil, ic, "UIPanelButtonTemplate")
    refreshBtn:SetSize(100, 22)
    refreshBtn:SetPoint("BOTTOMRIGHT", ic, "BOTTOMRIGHT", -4, 8)
    refreshBtn:SetText("Aktualisieren")

    local function RefreshInactive()
        for _, row in ipairs(ic.inactiveRows) do row:Hide() end
        wipe(ic.inactiveRows)

        local list = BuildInactiveData()
        local ROW_H = 20

        if #list == 0 then
            local msg = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            msg:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, 0)
            msg:SetText("Keine inaktiven Mitglieder gefunden.")
            msg:SetTextColor(0.6, 0.6, 0.6, 1)
            table.insert(ic.inactiveRows, msg)
            scrollChild:SetHeight(20)
            return
        end

        for idx, member in ipairs(list) do
            local row = CreateFrame("Frame", nil, scrollChild)
            row:SetSize(SCROLL_CONTENT_W, ROW_H)
            row:SetPoint("TOPLEFT", 0, -(idx - 1) * ROW_H)

            -- Alternating row tint
            if idx % 2 == 0 then
                local bg = row:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(1, 1, 1, 0.03)
            end

            local function Cell(text, xPos, w, r, g, b)
                local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                fs:SetPoint("LEFT", row, "LEFT", xPos + 4, 0)
                fs:SetWidth(w)
                fs:SetJustifyH("LEFT")
                fs:SetText(text)
                if r then fs:SetTextColor(r, g, b, 1) end
            end

            Cell(member.name,             0,   136)
            Cell(tostring(member.level),  144, 32,  1,   0.82, 0)
            Cell(member.rank,             184, 116)
            Cell(member.displayDur,       308, 66,  0.8, 0.5,  0.5)

            if IsOfficer() then
                local kickBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                kickBtn:SetSize(80, ROW_H - 2)
                kickBtn:SetPoint("LEFT", row, "LEFT", 382, 0)
                kickBtn:SetText("Entfernen")
                local fullName = member.fullName
                kickBtn:SetScript("OnClick", function()
                    if not CanGuildRemove() then return end
                    StaticPopup_Show("CONFIRM_GUILD_KICK", fullName, nil, { memberName = fullName })
                end)
            end

            table.insert(ic.inactiveRows, row)
        end

        scrollChild:SetHeight(math.max(1, #list * ROW_H))
        scrollFrame:SetVerticalScroll(0)
    end

    ic.Refresh = RefreshInactive
    refreshBtn:SetScript("OnClick", RefreshInactive)

    -- ── Wire up tab buttons ───────────────────────────────────────────────
    tabBtns["rules"]:SetScript("OnClick", function() SwitchTab("rules") end)
    tabBtns["inactive"]:SetScript("OnClick", function()
        if not officer then
            SchlingelInc:Print("Inaktive Mitglieder sind nur für Offiziere sichtbar.")
            return
        end
        SwitchTab("inactive")
        C_GuildInfo.GuildRoster()
        C_Timer.After(0.3, RefreshInactive)
    end)

    SwitchTab("rules")
    return f
end

-- ── Public API ────────────────────────────────────────────────────────────────

function SchlingelInc.OfficerPanel:Toggle()
    if not frame then
        frame = BuildPanel()
    end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
