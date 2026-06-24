-- interfaces/OfficerPanel.lua
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

local function FormatGold(copper)
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if g > 0 then
        return string.format("%dg %ds %dc", g, s, c)
    elseif s > 0 then
        return string.format("%ds %dc", s, c)
    else
        return string.format("%dc", c)
    end
end

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
    SchlingelInc:RegisterFrameForEscape(f)

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
        { id = "inactive", label = "Inaktiv" },
        { id = "progress", label = "Fortschritt" },
        { id = "discord",  label = "Discord" },
        { id = "invites",  label = "Anfragen" },
    }
    local tabBtns     = {}
    local tabContents = {}
    local CONTENT_TOP = -(TITLE_H + TAB_H + 14)

    local TAB_GAP   = 4
    local TAB_BTN_W = math.floor((PANEL_W - 16 - (TAB_GAP * (#tabDefs - 1))) / #tabDefs)
    local TAB_STEP  = TAB_BTN_W + TAB_GAP

    for i, tab in ipairs(tabDefs) do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(TAB_BTN_W, TAB_H)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", 8 + (i - 1) * TAB_STEP, -(TITLE_H + 6))
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

    local SCROLL_CONTENT_W = PANEL_W - 8 - 8 - 20

    -- ── Rules tab ─────────────────────────────────────────────────────────
    local rc      = tabContents["rules"]
    local officer = IsOfficer()

    local mailRuleOptions = {
        { value = 0, label = "Briefkasten erlauben" },
        { value = 2, label = "Nur gildeninterne Post erlauben" },
        { value = 1, label = "Briefkasten vollständig sperren" },
    }
    local selectedMailRule = tonumber(SchlingelInc.InfoRules.mailRule) or 1
    if selectedMailRule ~= 0 and selectedMailRule ~= 1 and selectedMailRule ~= 2 then
        selectedMailRule = 1
    end

    local mailLbl = rc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mailLbl:SetPoint("TOPLEFT", rc, "TOPLEFT", 34, -16)
    mailLbl:SetText("Briefkasten:")

    local mailDropdown = CreateFrame("Frame", "SchlingelIncMailDropdown", rc, "UIDropDownMenuTemplate")
    mailDropdown:SetPoint("TOPLEFT", rc, "TOPLEFT", 140, -5)
    UIDropDownMenu_SetWidth(mailDropdown, 235)
    UIDropDownMenu_Initialize(mailDropdown, function()
        for _, option in ipairs(mailRuleOptions) do
            local value, label = option.value, option.label
            local info = UIDropDownMenu_CreateInfo()
            info.text = label
            info.value = value
            info.checked = selectedMailRule == value
            info.func = function()
                selectedMailRule = value
                UIDropDownMenu_SetSelectedValue(mailDropdown, value)
                UIDropDownMenu_SetText(mailDropdown, label)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    for _, option in ipairs(mailRuleOptions) do
        if option.value == selectedMailRule then
            UIDropDownMenu_SetSelectedValue(mailDropdown, option.value)
            UIDropDownMenu_SetText(mailDropdown, option.label)
            break
        end
    end
    if not officer then
        UIDropDownMenu_DisableDropDown(mailDropdown)
        mailLbl:SetTextColor(0.5, 0.5, 0.5, 1)
    end

    local ruleDefs = {
        { label = "Auktionshaus sperren",                      dbKey = "auctionHouseRule" },
        { label = "Handel mit Nicht-Mitgliedern sperren",      dbKey = "tradeRule" },
        { label = "Gruppierung mit Nicht-Mitgliedern sperren", dbKey = "groupingRule" },
        { label = "SoD-Händler sperren",                       dbKey = "blockedTraderRule" },
        { label = "Fortschritt-Broadcast aktivieren",          dbKey = "progressBroadcastRule" },
        { label = "Duelle automatisch ablehnen",               dbKey = nil },
    }

    local checkboxes = {}
    local yOff = -38
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
        local updateBtn = CreateFrame("Button", nil, rc, "UIPanelButtonTemplate")
        updateBtn:SetSize(180, 26)
        updateBtn:SetPoint("BOTTOMRIGHT", rc, "BOTTOMRIGHT", -8, 8)
        updateBtn:SetText("Gildeninfo aktualisieren")
        updateBtn:SetScript("OnClick", function()
            local cap = tonumber(capEb:GetText()) or 0
            SchlingelInc:WriteGuildInfo(
                selectedMailRule,
                checkboxes["Auktionshaus sperren"]:GetChecked(),
                checkboxes["Handel mit Nicht-Mitgliedern sperren"]:GetChecked(),
                checkboxes["Gruppierung mit Nicht-Mitgliedern sperren"]:GetChecked(),
                checkboxes["SoD-Händler sperren"]:GetChecked(),
                checkboxes["Fortschritt-Broadcast aktivieren"]:GetChecked(),
                cap
            )
            SchlingelOptionsDB = SchlingelOptionsDB or {}
            SchlingelOptionsDB.auto_decline_duels = checkboxes["Duelle automatisch ablehnen"]:GetChecked() == true
        end)
    end

    -- ── Inactive Members tab ──────────────────────────────────────────────
    local ic = tabContents["inactive"]

    local COLS = {
        { label = "Name",    x = 0,   w = 140 },
        { label = "Level",   x = 144, w = 36  },
        { label = "Rang",    x = 184, w = 120 },
        { label = "Offline", x = 308, w = 70  },
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

    -- ── Progress tab ──────────────────────────────────────────────────────
    local pc = tabContents["progress"]

    local PCOLS = {
        { label = "Name",    x = 0,   w = 88,  sortKey = "name",       justifyH = "LEFT"  },
        { label = "Level",   x = 92,  w = 44,  sortKey = "level",      justifyH = "CENTER" },
        { label = "Runen",   x = 140, w = 42,  sortKey = "runesKnown", justifyH = "CENTER" },
        { label = "XP",      x = 186, w = 79,  sortKey = "xpPct",      justifyH = "CENTER" },
        { label = "%",       x = 265, w = 45,  sortKey = "xpPct",      justifyH = "CENTER" },
        { label = "Gold",    x = 314, w = 88,  sortKey = "gold",       justifyH = "RIGHT" },
        { label = "Aktuell", x = 398, w = 62,  sortKey = "timestamp",  justifyH = "RIGHT" },
    }

    local hideOfflineProgress = false

    local progressSortCol = 2
    local progressSortAsc = false
    local progressHdrs    = {}

    for i, col in ipairs(PCOLS) do
        local btn = CreateFrame("Button", nil, pc)
        btn:SetPoint("TOPLEFT", pc, "TOPLEFT", col.x + 4, -24)
        btn:SetSize(col.w, 18)
        btn:EnableMouse(true)
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints()
        lbl:SetJustifyH(col.justifyH or "LEFT")
        lbl:SetText(col.label)
        lbl:SetTextColor(1, 0.82, 0, 1)
        progressHdrs[i] = lbl
        local colIdx = i
        btn:SetScript("OnClick", function()
            if progressSortCol == colIdx then
                progressSortAsc = not progressSortAsc
            else
                progressSortCol = colIdx
                progressSortAsc = colIdx == 1
            end
            if frame and frame:IsShown() and frame.RefreshProgress then
                frame.RefreshProgress()
            end
        end)
        btn:SetScript("OnEnter", function() lbl:SetTextColor(1, 1, 0.7, 1) end)
        btn:SetScript("OnLeave", function()
            lbl:SetTextColor(colIdx == progressSortCol and 1 or 1,
                             colIdx == progressSortCol and 1 or 0.82,
                             colIdx == progressSortCol and 0.45 or 0, 1)
        end)
    end

    local pCountFs = pc:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pCountFs:SetPoint("RIGHT", pc, "TOPRIGHT", -4, -11)
    pCountFs:SetJustifyH("RIGHT")
    pCountFs:SetTextColor(0.6, 0.6, 0.6, 1)
    pc.pCountFs = pCountFs

    local pOfflineBtn = CreateFrame("Button", nil, pc)
    pOfflineBtn:SetSize(50, 18)
    pOfflineBtn:SetPoint("RIGHT", pCountFs, "LEFT", -6, 0)
    pOfflineBtn:EnableMouse(true)
    local pOfflineLbl = pOfflineBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pOfflineLbl:SetAllPoints()
    pOfflineLbl:SetJustifyH("RIGHT")
    pOfflineLbl:SetTextColor(0.45, 0.45, 0.45, 1)
    pOfflineLbl:SetText("Offline")
    local function UpdateOfflineBtn()
        pOfflineLbl:SetTextColor(
            hideOfflineProgress and 1    or 0.45,
            hideOfflineProgress and 0.82 or 0.45,
            hideOfflineProgress and 0    or 0.45, 1)
    end
    pOfflineBtn:SetScript("OnClick", function()
        hideOfflineProgress = not hideOfflineProgress
        UpdateOfflineBtn()
        if frame and frame:IsShown() and frame.RefreshProgress then
            frame.RefreshProgress()
        end
    end)
    pOfflineBtn:SetScript("OnEnter", function() pOfflineLbl:SetTextColor(1, 1, 0.7, 1) end)
    pOfflineBtn:SetScript("OnLeave", UpdateOfflineBtn)

    local phdrDiv = pc:CreateTexture(nil, "ARTWORK")
    phdrDiv:SetHeight(1)
    phdrDiv:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    phdrDiv:SetPoint("TOPLEFT",  pc, "TOPLEFT",  4, -44)
    phdrDiv:SetPoint("TOPRIGHT", pc, "TOPRIGHT", -4, -44)

    local pScrollFrame = CreateFrame("ScrollFrame", nil, pc, "UIPanelScrollFrameTemplate")
    pScrollFrame:SetPoint("TOPLEFT",     pc, "TOPLEFT",     4, -48)
    pScrollFrame:SetPoint("BOTTOMRIGHT", pc, "BOTTOMRIGHT", -20, 8)
    pScrollFrame:EnableMouseWheel(true)
    pScrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        sf:SetVerticalScroll(
            math.max(0, math.min(sf:GetVerticalScrollRange(), sf:GetVerticalScroll() - delta * 20))
        )
    end)

    local pScrollChild = CreateFrame("Frame", nil, pScrollFrame)
    pScrollChild:SetWidth(SCROLL_CONTENT_W)
    pScrollChild:SetHeight(1)
    pScrollFrame:SetScrollChild(pScrollChild)

    pc.pScrollChild = pScrollChild
    pc.progressRows = {}

    local BAR_W = 75
    local BAR_X = 190

    local function FormatGoldShort(copper)
        if not copper then return "—" end
        local g = math.floor(copper / 10000)
        local s = math.floor((copper % 10000) / 100)
        local c = copper % 100
        return string.format("%dg %ds %dc", g, s, c)
    end

    local function FormatAge(timestamp)
        if not timestamp or timestamp <= 0 then return "—" end
        local age = time() - timestamp
        if age < 60    then return "gerade"
        elseif age < 3600 then return math.floor(age / 60) .. "m"
        else return math.floor(age / 3600) .. "h"
        end
    end

    local function RefreshProgress()
        for _, row in ipairs(pc.progressRows) do row:Hide() end
        wipe(pc.progressRows)

        local list = {}
        for i = 1, GetNumGuildMembers() or 0 do
            local name, _, _, rosterLevel, _, _, _, _, isOnline = GetGuildRosterInfo(i)
            if name then
                local shortName = SchlingelInc:RemoveRealmFromName(name)
                local data = SchlingelInc.LevelUps.progressCache[shortName]

                local level = rosterLevel or 0
                local xpCurrent, xpMax, xpPct = 0, 0, 0
                local gold, runesKnown, xpStop, timestamp = nil, nil, nil, 0
                local hasProgress = false

                if data then
                    hasProgress = true
                    level = data.level or level
                    xpCurrent = data.xpCurrent or 0
                    xpMax = data.xpMax or 0
                    if xpMax > 0 then
                        xpPct = math.floor(xpCurrent / xpMax * 100)
                    elseif xpMax == 0 and level >= SchlingelInc.Constants.MAX_LEVEL then
                        xpPct = 100
                    end
                    gold = data.gold
                    runesKnown = data.runesKnown
                    xpStop = data.xpStop
                    timestamp = data.timestamp or 0
                end

                table.insert(list, {
                    name        = shortName,
                    level       = level,
                    xpCurrent   = xpCurrent,
                    xpMax       = xpMax,
                    xpPct       = xpPct,
                    gold        = gold,
                    runesKnown  = runesKnown,
                    xpStop      = xpStop,
                    isOnline    = isOnline == true,
                    timestamp   = timestamp,
                    hasProgress = hasProgress,
                })
            end
        end

        local onlineCount = 0
        for _, e in ipairs(list) do if e.isOnline then onlineCount = onlineCount + 1 end end
        if pc.pCountFs then
            pc.pCountFs:SetText(#list .. " (|cff44ff44" .. onlineCount .. " online|r)")
        end

        if hideOfflineProgress then
            local filtered = {}
            for _, e in ipairs(list) do
                if e.isOnline then table.insert(filtered, e) end
            end
            list = filtered
        end

        for i, col in ipairs(PCOLS) do
            local active = i == progressSortCol
            local arrow  = active and (progressSortAsc and " ^" or " v") or ""
            progressHdrs[i]:SetText(col.label .. arrow)
            progressHdrs[i]:SetTextColor(active and 1 or 1, active and 1 or 0.82, active and 0.45 or 0, 1)
        end

        local compact = {}
        for _, e in ipairs(list) do
            if type(e) == "table" then
                table.insert(compact, e)
            end
        end
        list = compact

        local sortCol = PCOLS[progressSortCol] or PCOLS[1]
        local key = sortCol and sortCol.sortKey or "name"
        local ascending = progressSortAsc == true

        local function IsLess(a, b)
            if a == b then return false end
            if type(a) ~= "table" then return false end
            if type(b) ~= "table" then return true end

            local va, vb
            if key == "name" then
                va = tostring(a.name or ""):lower()
                vb = tostring(b.name or ""):lower()
            else
                va = tonumber(a[key]) or 0
                vb = tonumber(b[key]) or 0
            end

            if va ~= vb then
                return ascending and va < vb or va > vb
            end

            local na = tostring(a.name or ""):lower()
            local nb = tostring(b.name or ""):lower()
            if na ~= nb then return na < nb end

            local la, lb = tonumber(a.level) or 0, tonumber(b.level) or 0
            if la ~= lb then return la > lb end

            local xa, xb = tonumber(a.xpPct) or 0, tonumber(b.xpPct) or 0
            if xa ~= xb then return xa > xb end

            local ta, tb = tonumber(a.timestamp) or 0, tonumber(b.timestamp) or 0
            if ta ~= tb then return ta > tb end

            return false
        end

        -- Manual selection sort avoids Lua's table.sort edge-cases with malformed input.
        local n = #list
        for i = 1, n - 1 do
            local best = i
            for j = i + 1, n do
                if IsLess(list[j], list[best]) then
                    best = j
                end
            end
            if best ~= i then
                list[i], list[best] = list[best], list[i]
            end
        end

        if #list == 0 then
            local msg = pScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            msg:SetPoint("TOPLEFT", pScrollChild, "TOPLEFT", 4, 0)
            msg:SetText("Noch keine Daten. Mitglieder schicken diese beim Login oder Zonenchange.")
            msg:SetTextColor(0.6, 0.6, 0.6, 1)
            table.insert(pc.progressRows, msg)
            pScrollChild:SetHeight(20)
            return
        end

        local ROW_H = 22
        local cap   = SchlingelInc.Rules.CurrentCap

        for idx, entry in ipairs(list) do
            local row = CreateFrame("Frame", nil, pScrollChild)
            row:SetSize(SCROLL_CONTENT_W, ROW_H)
            row:SetPoint("TOPLEFT", 0, -(idx - 1) * ROW_H)

            local atCap = cap > 0 and entry.level >= cap
            if atCap and entry.xpStop == false then
                local bg = row:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(0.4, 0.65, 0.9, 0.55)
            elseif idx % 2 == 0 then
                local bg = row:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(1, 1, 1, 0.03)
            end

            local nameFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nameFs:SetPoint("LEFT", row, "LEFT", 4, 0)
            nameFs:SetWidth(84)
            nameFs:SetJustifyH("LEFT")
            nameFs:SetText(entry.name)
            if not entry.isOnline then
                nameFs:SetTextColor(0.5, 0.5, 0.5, 1)
            end

            local levelFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            levelFs:SetPoint("LEFT", row, "LEFT", 96, 0)
            levelFs:SetWidth(40)
            levelFs:SetJustifyH("CENTER")
            levelFs:SetText(tostring(entry.level))
            levelFs:SetTextColor(atCap and 1 or 1, atCap and 0.82 or 1, atCap and 0 or 1, 1)

            local runesFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            runesFs:SetPoint("LEFT", row, "LEFT", 144, 0)
            runesFs:SetWidth(38)
            runesFs:SetJustifyH("CENTER")
            if entry.runesKnown ~= nil then
                runesFs:SetText(tostring(entry.runesKnown))
                runesFs:SetTextColor(1, 1, 1, 1)
            else
                runesFs:SetText("—")
                runesFs:SetTextColor(0.55, 0.55, 0.55, 1)
            end

            local barBg = row:CreateTexture(nil, "BACKGROUND")
            barBg:SetSize(BAR_W, 8)
            barBg:SetPoint("LEFT", row, "LEFT", BAR_X, 0)
            barBg:SetColorTexture(0.15, 0.15, 0.15, 1)

            local fillW = 0
            if atCap then
                fillW = BAR_W
            elseif entry.hasProgress then
                fillW = math.max(1, math.floor(BAR_W * entry.xpPct / 100))
            end
            local fill = row:CreateTexture(nil, "ARTWORK")
            fill:SetSize(fillW, 8)
            fill:SetPoint("LEFT", barBg, "LEFT", 0, 0)
            fill:SetColorTexture(atCap and 1 or 0.2, atCap and 0.82 or 0.75, atCap and 0 or 0.2, entry.hasProgress and 1 or 0)

            local pctFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            pctFs:SetPoint("LEFT", row, "LEFT", BAR_X + BAR_W + 4, 0)
            pctFs:SetWidth(41)
            pctFs:SetJustifyH("CENTER")
            if atCap then
                pctFs:SetText("Cap")
                pctFs:SetTextColor(1, 0.82, 0, 1)
            elseif not entry.hasProgress then
                pctFs:SetText("—")
                pctFs:SetTextColor(0.55, 0.55, 0.55, 1)
            else
                pctFs:SetText(entry.xpPct .. "%")
                pctFs:SetTextColor(1, 1, 1, 1)
            end

            local goldFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            goldFs:SetPoint("LEFT", row, "LEFT", BAR_X + BAR_W + 50, 0)
            goldFs:SetWidth(86)
            goldFs:SetJustifyH("RIGHT")
            goldFs:SetWordWrap(false)
            goldFs:SetText(FormatGoldShort(entry.gold))
            goldFs:SetTextColor(1, 0.82, 0, 1)

            local ageFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ageFs:SetPoint("LEFT", row, "LEFT", 402, 0)
            ageFs:SetWidth(58)
            ageFs:SetJustifyH("RIGHT")
            ageFs:SetText(FormatAge(entry.timestamp))
            ageFs:SetTextColor(entry.isOnline and 0.5 or 0.8, 0.5, entry.isOnline and 0.5 or 0.2, 1)

            table.insert(pc.progressRows, row)
        end

        pScrollChild:SetHeight(math.max(1, #list * ROW_H))
        pScrollFrame:SetVerticalScroll(0)
    end

    pc.Refresh = RefreshProgress

    -- ── Discord tab ───────────────────────────────────────────────────────
    local dc = tabContents["discord"]

    local DCOLS = {
        { label = "Discord",     x = 0,   w = 150 },
        { label = "Chars",       x = 154, w = 42  },
        { label = "Charaktere",  x = 200, w = 250 },
    }

    for _, col in ipairs(DCOLS) do
        local hdr = dc:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hdr:SetPoint("TOPLEFT", dc, "TOPLEFT", col.x + 4, -6)
        hdr:SetWidth(col.w)
        hdr:SetJustifyH("LEFT")
        hdr:SetText(col.label)
        hdr:SetTextColor(1, 0.82, 0, 1)
    end

    local dhdrDiv = dc:CreateTexture(nil, "ARTWORK")
    dhdrDiv:SetHeight(1)
    dhdrDiv:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    dhdrDiv:SetPoint("TOPLEFT",  dc, "TOPLEFT",  4, -22)
    dhdrDiv:SetPoint("TOPRIGHT", dc, "TOPRIGHT", -4, -22)

    local dScrollFrame = CreateFrame("ScrollFrame", nil, dc, "UIPanelScrollFrameTemplate")
    dScrollFrame:SetPoint("TOPLEFT",     dc, "TOPLEFT",     4, -26)
    dScrollFrame:SetPoint("BOTTOMRIGHT", dc, "BOTTOMRIGHT", -20, 8)
    dScrollFrame:EnableMouseWheel(true)
    dScrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        sf:SetVerticalScroll(
            math.max(0, math.min(sf:GetVerticalScrollRange(), sf:GetVerticalScroll() - delta * 20))
        )
    end)

    local dScrollChild = CreateFrame("Frame", nil, dScrollFrame)
    dScrollChild:SetWidth(SCROLL_CONTENT_W)
    dScrollChild:SetHeight(1)
    dScrollFrame:SetScrollChild(dScrollChild)

    dc.dScrollChild = dScrollChild
    dc.discordRows  = {}

    local function BuildDiscordHandleData()
        local byHandle = {}
        local ownName = UnitName("player")

        for i = 1, GetNumGuildMembers() or 0 do
            local name, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
            if name then
                local shortName = SchlingelInc:RemoveRealmFromName(name)
                local handle
                if shortName == ownName then
                    handle = DiscordHandle
                elseif SchlingelGuildProfileCache and SchlingelGuildProfileCache[shortName] then
                    handle = SchlingelGuildProfileCache[shortName].discord
                end
                handle = handle and strtrim(handle) or ""

                if handle ~= "" then
                    local key = string.lower(handle)
                    if not byHandle[key] then
                        byHandle[key] = {
                            handle  = handle,
                            chars   = {},
                            online  = 0,
                        }
                    end
                    table.insert(byHandle[key].chars, shortName)
                    if isOnline then byHandle[key].online = byHandle[key].online + 1 end
                end
            end
        end

        local list = {}
        for _, group in pairs(byHandle) do
            table.sort(group.chars)
            table.insert(list, {
                handle = group.handle,
                count  = #group.chars,
                names  = table.concat(group.chars, ", "),
            })
        end

        table.sort(list, function(a, b)
            if a.count ~= b.count then return a.count > b.count end
            return string.lower(a.handle) < string.lower(b.handle)
        end)

        return list
    end

    local function RefreshDiscordHandles()
        for _, row in ipairs(dc.discordRows) do row:Hide() end
        wipe(dc.discordRows)

        local list = BuildDiscordHandleData()
        local ROW_H = 22

        if #list == 0 then
            local msg = dScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            msg:SetPoint("TOPLEFT", dScrollChild, "TOPLEFT", 4, 0)
            msg:SetText("Keine Discord Handles in den Profilen gefunden.")
            msg:SetTextColor(0.6, 0.6, 0.6, 1)
            table.insert(dc.discordRows, msg)
            dScrollChild:SetHeight(20)
            return
        end

        for idx, entry in ipairs(list) do
            local row = CreateFrame("Frame", nil, dScrollChild)
            row:SetSize(SCROLL_CONTENT_W, ROW_H)
            row:SetPoint("TOPLEFT", 0, -(idx - 1) * ROW_H)

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

            Cell(entry.handle,           0,   146, 0.65, 0.65, 1)
            Cell(tostring(entry.count),  154, 38,  1,    0.82, 0)
            Cell(entry.names,            200, 246)

            table.insert(dc.discordRows, row)
        end

        dScrollChild:SetHeight(math.max(1, #list * ROW_H))
        dScrollFrame:SetVerticalScroll(0)
    end

    dc.Refresh = RefreshDiscordHandles

    -- ── Anfragen tab ──────────────────────────────────────────────────────
    local vc = tabContents["invites"]

    local VCOLS = {
        { label = "Name",  x = 0,   w = 80 },
        { label = "Level", x = 84,  w = 32 },
        { label = "Runen", x = 120, w = 42 },
        { label = "XP",    x = 166, w = 50 },
        { label = "Gold",  x = 220, w = 58 },
        { label = "Zone",  x = 282, w = 126 },
    }

    for _, col in ipairs(VCOLS) do
        local hdr = vc:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hdr:SetPoint("TOPLEFT", vc, "TOPLEFT", col.x + 4, -6)
        hdr:SetWidth(col.w)
        hdr:SetJustifyH("LEFT")
        hdr:SetText(col.label)
        hdr:SetTextColor(1, 0.82, 0, 1)
    end

    local vhdrDiv = vc:CreateTexture(nil, "ARTWORK")
    vhdrDiv:SetHeight(1)
    vhdrDiv:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    vhdrDiv:SetPoint("TOPLEFT",  vc, "TOPLEFT",  4, -22)
    vhdrDiv:SetPoint("TOPRIGHT", vc, "TOPRIGHT", -4, -22)

    local vScrollFrame = CreateFrame("ScrollFrame", nil, vc, "UIPanelScrollFrameTemplate")
    vScrollFrame:SetPoint("TOPLEFT",     vc, "TOPLEFT",     4, -26)
    vScrollFrame:SetPoint("BOTTOMRIGHT", vc, "BOTTOMRIGHT", -20, 8)
    vScrollFrame:EnableMouseWheel(true)
    vScrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        sf:SetVerticalScroll(
            math.max(0, math.min(sf:GetVerticalScrollRange(), sf:GetVerticalScroll() - delta * 20))
        )
    end)

    local vScrollChild = CreateFrame("Frame", nil, vScrollFrame)
    vScrollChild:SetWidth(SCROLL_CONTENT_W)
    vScrollChild:SetHeight(1)
    vScrollFrame:SetScrollChild(vScrollChild)

    vc.vScrollChild = vScrollChild
    vc.inviteRows   = {}

    local function RefreshInvites()
        for _, row in ipairs(vc.inviteRows) do row:Hide() end
        wipe(vc.inviteRows)

        local list = {}
        for _, data in pairs(SchlingelInc.GuildRecruitment.inviteRequests) do
            table.insert(list, data)
        end
        table.sort(list, function(a, b) return a.name < b.name end)

        local ROW_H = 22

        if #list == 0 then
            local msg = vScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            msg:SetPoint("TOPLEFT", vScrollChild, "TOPLEFT", 4, 0)
            msg:SetText("Keine ausstehenden Anfragen.")
            msg:SetTextColor(0.6, 0.6, 0.6, 1)
            table.insert(vc.inviteRows, msg)
            vScrollChild:SetHeight(20)
            return
        end

        for idx, entry in ipairs(list) do
            local row = CreateFrame("Frame", nil, vScrollChild)
            row:SetSize(SCROLL_CONTENT_W, ROW_H)
            row:SetPoint("TOPLEFT", 0, -(idx - 1) * ROW_H)

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

            Cell(entry.name,                    0,   76, 1, 1, 1)
            Cell(tostring(entry.level),          84,  28, 1, 1, 1)
            Cell(entry.runesKnown ~= nil and tostring(entry.runesKnown) or "—", 120, 38, 1, 1, 1)
            Cell(tostring(entry.xp),             166, 46, 1, 1, 1)
            Cell(FormatGold(entry.gold or 0),    220, 54, 1, 1, 1)
            Cell(entry.zone,                     282, 122, 1, 1, 1)

            if IsOfficer() then
                local entryName = entry.name
                local acceptBtn = CreateFrame("Button", nil, row)
                acceptBtn:SetSize(18, 18)
                acceptBtn:SetPoint("RIGHT", row, "RIGHT", -28, 0)
                local acceptIcon = acceptBtn:CreateTexture(nil, "ARTWORK")
                acceptIcon:SetAllPoints()
                acceptIcon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
                acceptBtn:SetScript("OnClick", function()
                    SchlingelInc.GuildRecruitment:HandleAcceptRequest(entryName)
                end)
                acceptBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Annehmen", 1, 1, 1)
                    GameTooltip:Show()
                end)
                acceptBtn:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                local declineBtn = CreateFrame("Button", nil, row)
                declineBtn:SetSize(18, 18)
                declineBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
                local declineIcon = declineBtn:CreateTexture(nil, "ARTWORK")
                declineIcon:SetAllPoints()
                declineIcon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
                declineBtn:SetScript("OnClick", function()
                    SchlingelInc.GuildRecruitment:HandleDeclineRequest(entryName)
                end)
                declineBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Ablehnen", 1, 1, 1)
                    GameTooltip:Show()
                end)
                declineBtn:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
            end

            table.insert(vc.inviteRows, row)
        end

        vScrollChild:SetHeight(math.max(1, #list * ROW_H))
        vScrollFrame:SetVerticalScroll(0)
    end

    vc.Refresh = RefreshInvites

    -- ── Wire up tab buttons ───────────────────────────────────────────────
    tabBtns["rules"]:SetScript("OnClick", function() SwitchTab("rules") end)

    tabBtns["inactive"]:SetScript("OnClick", function()
        if not IsOfficer() then
            SchlingelInc:Print("Inaktive Mitglieder sind nur für Offiziere sichtbar.")
            return
        end
        SwitchTab("inactive")
        C_GuildInfo.GuildRoster()
        C_Timer.After(0.3, RefreshInactive)
    end)

    tabBtns["progress"]:SetScript("OnClick", function()
        if not IsOfficer() then
            SchlingelInc:Print("Fortschritt ist nur für Offiziere sichtbar.")
            return
        end
        SwitchTab("progress")
        RefreshProgress()
    end)

    tabBtns["discord"]:SetScript("OnClick", function()
        if not IsOfficer() then
            SchlingelInc:Print("Discord-Übersicht ist nur für Offiziere sichtbar.")
            return
        end
        SwitchTab("discord")
        C_GuildInfo.GuildRoster()
        C_Timer.After(0.3, RefreshDiscordHandles)
    end)

    tabBtns["invites"]:SetScript("OnClick", function()
        if not IsOfficer() then
            SchlingelInc:Print("Anfragen sind nur für Offiziere sichtbar.")
            return
        end
        SwitchTab("invites")
        RefreshInvites()
    end)

    f.RefreshInvites  = RefreshInvites
    f.RefreshProgress = RefreshProgress
    f.RefreshDiscord  = RefreshDiscordHandles
    f.SwitchToInvites = function()
        SwitchTab("invites")
        RefreshInvites()
    end

    SwitchTab("rules")
    return f
end

-- ── Public API ────────────────────────────────────────────────────────────────

function SchlingelInc.OfficerPanel:Toggle()
    if not CanGuildRemove() then return end
    if not frame then
        frame = BuildPanel()
    end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

function SchlingelInc.OfficerPanel:ShowInvites()
    if not CanGuildRemove() then return end
    if not frame then frame = BuildPanel() end
    if not frame:IsShown() then frame:Show() end
    frame.SwitchToInvites()
end

function SchlingelInc.OfficerPanel:RefreshInvites()
    if frame and frame.RefreshInvites then
        frame.RefreshInvites()
    end
end

function SchlingelInc.OfficerPanel:RefreshProgress()
    if frame and frame:IsShown() and frame.RefreshProgress then
        frame.RefreshProgress()
    end
end
