-- GuildPanel/Frame.lua
-- Main panel: Create(), Refresh(), Toggle(), Initialize().

local GP = SchlingelInc.GuildPanel

local function ComputeFrameWidth()
    GP.FRAME_W = GP.TotalColWidth() + GP.PAD_X + 8  -- extra 8 for visual breathing room
end

-- ── Panel construction ────────────────────────────────────────────────────────

function SchlingelInc.GuildPanel:Create()
    if self.frame then return end
    ComputeFrameWidth()

    local function HideFilterFrames()
        if SchlingelInc.GuildPanel.filterPanel then SchlingelInc.GuildPanel.filterPanel:Hide() end
        if SchlingelInc.GuildPanel.filterProfList then SchlingelInc.GuildPanel.filterProfList:Hide() end
    end

    local f = SchlingelInc.Shared.CreateStandardFrame({
        name          = GP.PANEL_NAME,
        width         = GP.FRAME_W,
        height        = GP.FRAME_H,
        strata        = "MEDIUM",
        backdrop      = SchlingelInc.Constants.POPUPBACKDROP,
        positionKey   = "guildpanel_position",
        defaultPoint  = "CENTER",
        defaultX      = 0,
        defaultY      = 0,
        registerEscape = true,
        closeButton   = true,
        onHide        = HideFilterFrames,
    })

    -- ── Title bar ──────────────────────────────────────────────────────────
    local titleBg = f:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -4)
    titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    titleBg:SetHeight(GP.TITLE_H - 4)
    titleBg:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BG))

    -- Schlingel icon
    local titleIcon = f:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("LEFT", titleBg, "LEFT", 4, 0)
    titleIcon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\SI_Transp_512_x_512_px.tga")

    local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleIcon, "RIGHT", 4, 0)
    titleText:SetText("Schlingel Inc")
    titleText:SetTextColor(1, 0.82, 0, 1)

    -- ── Tabs (shared factory) ──────────────────────────────────────────────
    local switcher = SchlingelInc.Shared.CreateTabSwitcher({
        parent     = f,
        width      = GP.FRAME_W - 16,
        tabHeight  = GP.TAB_H,
        topOffset  = -(GP.TITLE_H + 6),
        contentTop = -(GP.TITLE_H + GP.TAB_H + 14),
        tabDefs    = {
            { id = "roster",  label = "Mitglieder" },
            { id = "schande", label = "Schande",
              onSelected = function() SchlingelInc.GuildPanel:RefreshSchande() end },
            { id = "raid",    label = "Raid",
              onSelected = function()
                  SchlingelInc.Raid:RequestSync()
                  SchlingelInc.GuildPanel:RefreshRaid()
              end },
            { id = "achievements", label = "Erfolge",
              onSelected = function()
                  SchlingelInc.Achievements.Catalog:RequestSync()
                  SchlingelInc.GuildPanel:RefreshAchievements()
              end },
        },
        defaultTab = "roster",
    })
    f.tabSwitcher = switcher

    GP.BuildRosterTab(switcher.tabContents["roster"], f)
    GP.BuildSchandeTab(switcher.tabContents["schande"])
    GP.BuildRaidTab(switcher.tabContents["raid"])
    GP.BuildAchievementsTab(switcher.tabContents["achievements"])

    self.frame = f
end

-- ── Rendering ─────────────────────────────────────────────────────────────────

function SchlingelInc.GuildPanel:Refresh()
    if not self.frame then return end

    -- Build full unfiltered roster for the count display
    self.data = GP.BuildRosterData()
    local allData = self.data

    local onlineCount = 0
    for _, e in ipairs(allData) do if e.online then onlineCount = onlineCount + 1 end end
    if self.frame.countLabel then
        self.frame.countLabel:SetText(#allData .. " (|cff44ff44" .. onlineCount .. " online|r)")
    end

    -- Apply offline filter
    local data = allData
    if GP.hideOffline then
        data = {}
        for _, e in ipairs(allData) do
            if e.online then table.insert(data, e) end
        end
    end

    -- Apply name search (case-insensitive substring, also matches Discord handle)
    if GP.filterName ~= "" then
        local search = GP.filterName:lower()
        local filtered = {}
        for _, e in ipairs(data) do
            if (e.name    or ""):lower():find(search, 1, true) or
               (e.discord or ""):lower():find(search, 1, true) then
                table.insert(filtered, e)
            end
        end
        data = filtered
    end

    -- Apply role filter: member matches if any of their roles matches any active filter
    if next(GP.filterRoles) then
        local filtered = {}
        for _, e in ipairs(data) do
            local match = false
            for part in (e.role or ""):gmatch("[^/]+") do
                if GP.filterRoles[part] then match = true; break end
            end
            if match then table.insert(filtered, e) end
        end
        data = filtered
    end

    -- Apply profession filter
    if GP.filterProf then
        local filtered = {}
        for _, e in ipairs(data) do
            if e.profName1 == GP.filterProf or e.profName2 == GP.filterProf then
                table.insert(filtered, e)
            end
        end
        data = filtered
    end

    -- Sort
    GP.SortData(data)

    -- Update header sort indicators
    for i, btn in ipairs(self.headerBtns or {}) do
        if i == GP.sortCol then
            btn.lbl:SetText(GP.COLUMNS[i].label .. (GP.sortAsc and " ^" or " v"))
            btn.lbl:SetTextColor(1, 1, 0.45, 1)
        else
            btn.lbl:SetText(GP.COLUMNS[i].label)
            btn.lbl:SetTextColor(1, 0.82, 0, 1)
        end
    end

    local content = self.frame.content
    local rows    = self.frame.rows

    for i = 1, math.max(#data, #rows) do
        if i <= #data then
            if not rows[i] then rows[i] = GP.CreateRow(content, i) end
            local row   = rows[i]
            local entry = data[i]
            row._entry  = entry

            local nameCol = entry.online and "|cff44ff44" or "|cff888888"
            row.cells[1]:SetText(nameCol .. SchlingelInc:SanitizeText(entry.name) .. "|r")
            row.cells[2]:SetText(tostring(entry.level))
            row.cells[3]:SetText(SchlingelInc:SanitizeText(entry.rank))
            row.cells[4]:SetText(SchlingelInc:SanitizeText(entry.zone))
            row.cells[5]:SetText(entry.role)
            row.cells[6]:SetText(SchlingelInc:SanitizeText(entry.discord or ""))
            -- Deaths: show the number whenever we have data (including 0),
            -- blank only when nil (no profile received yet for this player)
            row.cells[7]:SetText(entry.deaths ~= nil and tostring(entry.deaths) or "")

            row:SetScript("OnEnter", function()
                row.hl:Show()
                SchlingelInc.MemberInspector.ShowTooltip(row, entry)
            end)
            row:SetScript("OnLeave", function()
                row.hl:Hide()
                GameTooltip:Hide()
            end)
            -- Right-click opens the standard WoW player context menu (Whisper, Invite, etc.)
            row:SetScript("OnMouseDown", function(_, button)
                if button == "RightButton" then
                    SetItemRef("player:" .. entry.name,
                        "|Hplayer:" .. entry.name .. "|h[" .. entry.name .. "]|h",
                        "RightButton")
                end
            end)
            row:Show()
        elseif rows[i] then
            rows[i]:SetScript("OnEnter", nil)
            rows[i]:SetScript("OnLeave", nil)
            rows[i]:SetScript("OnMouseDown", nil)
            rows[i]:Hide()
        end
    end

    content:SetHeight(math.max(1, #data * GP.ROW_H))
    self.frame.scrollFrame:SetVerticalScroll(0)
end

function SchlingelInc.GuildPanel:RefreshSchande()
    local content = self.frame and self.frame.tabSwitcher and self.frame.tabSwitcher.tabContents.schande
    if content and content.Refresh then
        content.Refresh()
    end
end

function SchlingelInc.GuildPanel:RefreshRaid()
    local content = self.frame and self.frame.tabSwitcher and self.frame.tabSwitcher.tabContents.raid
    if content and content.Refresh then
        content.Refresh()
    end
end

function SchlingelInc.GuildPanel:RefreshAchievements()
    local content = self.frame and self.frame.tabSwitcher and self.frame.tabSwitcher.tabContents.achievements
    if content and content.Refresh then
        content.Refresh()
    end
end

-- ── Toggle / Init ─────────────────────────────────────────────────────────────

function SchlingelInc.GuildPanel:Toggle()
    if not IsInGuild() then return end
    if not self.frame then self:Create() end
    if self.frame:IsShown() then
        self.frame:Hide()
        if self.filterPanel    then self.filterPanel:Hide()    end
        if self.filterProfList then self.filterProfList:Hide() end
    else
        self:Refresh()
        self.frame:Show()
    end
end

function SchlingelInc.GuildPanel:Initialize()
    SchlingelInc.EventManager:RegisterHandler("GUILD_ROSTER_UPDATE", function()
        if SchlingelInc.GuildPanel.frame and SchlingelInc.GuildPanel.frame:IsShown() then
            C_Timer.After(0, function()
                SchlingelInc.GuildPanel:Refresh()
            end)
        end
    end, 0, "GuildPanelRefresh")
end
