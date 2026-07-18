local OfficerPanel = SchlingelInc.OfficerPanel
local MemberInspector = SchlingelInc.MemberInspector

local function FormatGoldShort(copper)
    if not copper then return "\226\128\148" end
    local goldPart   = math.floor(copper / 10000)
    local silverPart = math.floor((copper % 10000) / 100)
    local copperPart = copper % 100
    return string.format("%dg %ds %dc", goldPart, silverPart, copperPart)
end

local function FormatAge(timestamp)
    if not timestamp or timestamp <= 0 then return "\226\128\148" end
    local age = time() - timestamp
    if age < 60    then return "gerade"
    elseif age < 3600 then return math.floor(age / 60)   .. "m"
    else                   return math.floor(age / 3600) .. "h"
    end
end

function OfficerPanel.BuildProgressTab(progressContainer)
    local scrollWidth = OfficerPanel.SCROLL_W

    local progressColumns = {
        { label = "Name",    x = 0,   w = 88,  sortKey = "name",       justifyH = "LEFT"   },
        { label = "Level",   x = 92,  w = 44,  sortKey = "level",      justifyH = "CENTER" },
        { label = "Runen",   x = 140, w = 42,  sortKey = "runesKnown", justifyH = "CENTER" },
        { label = "XP",      x = 186, w = 59,  sortKey = "xpPct",      justifyH = "CENTER" },
        { label = "%",       x = 249, w = 41,  sortKey = "xpPct",      justifyH = "CENTER" },
        { label = "Gold",    x = 292, w = 68,  sortKey = "gold",       justifyH = "RIGHT"  },
        { label = "Version", x = 362, w = 42,  sortKey = "version",    justifyH = "RIGHT"  },
        { label = "Aktuell", x = 406, w = 42,  sortKey = "timestamp",  justifyH = "RIGHT"  },
    }

    local hideOfflineProgress = false
    local progressSortCol     = 2
    local progressSortAsc     = false
    local progressHeaders     = {}

    for i, column in ipairs(progressColumns) do
        local button = CreateFrame("Button", nil, progressContainer)
        button:SetPoint("TOPLEFT", progressContainer, "TOPLEFT", column.x + 4, -24)
        button:SetSize(column.w, 18)
        button:EnableMouse(true)
        local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetAllPoints()
        label:SetJustifyH(column.justifyH or "LEFT")
        label:SetText(column.label)
        label:SetTextColor(1, 0.82, 0, 1)
        progressHeaders[i] = label
        local columnIndex = i
        button:SetScript("OnClick", function()
            if progressSortCol == columnIndex then
                progressSortAsc = not progressSortAsc
            else
                progressSortCol = columnIndex
                progressSortAsc = columnIndex == 1
            end
            if OfficerPanel.frame and OfficerPanel.frame:IsShown() then
                SchlingelInc.OfficerPanel:RefreshProgress()
            end
        end)
        button:SetScript("OnEnter", function() label:SetTextColor(1, 1, 0.7, 1) end)
        button:SetScript("OnLeave", function()
            label:SetTextColor(
                columnIndex == progressSortCol and 1    or 1,
                columnIndex == progressSortCol and 1    or 0.82,
                columnIndex == progressSortCol and 0.45 or 0, 1)
        end)
    end

    -- Right side: Offline toggle + member count
    local memberCountLabel = progressContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    memberCountLabel:SetPoint("RIGHT", progressContainer, "TOPRIGHT", -4, -11)
    memberCountLabel:SetJustifyH("RIGHT")
    memberCountLabel:SetTextColor(0.6, 0.6, 0.6, 1)
    progressContainer.memberCountLabel = memberCountLabel

    local offlineToggleButton = CreateFrame("Button", nil, progressContainer)
    offlineToggleButton:SetSize(50, 18)
    offlineToggleButton:SetPoint("RIGHT", memberCountLabel, "LEFT", -6, 0)
    offlineToggleButton:EnableMouse(true)
    local offlineToggleLabel = offlineToggleButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    offlineToggleLabel:SetAllPoints()
    offlineToggleLabel:SetJustifyH("RIGHT")
    offlineToggleLabel:SetTextColor(0.45, 0.45, 0.45, 1)
    offlineToggleLabel:SetText("Offline")
    local function UpdateOfflineToggleAppearance()
        offlineToggleLabel:SetTextColor(
            hideOfflineProgress and 1    or 0.45,
            hideOfflineProgress and 0.82 or 0.45,
            hideOfflineProgress and 0    or 0.45, 1)
    end
    offlineToggleButton:SetScript("OnClick", function()
        hideOfflineProgress = not hideOfflineProgress
        UpdateOfflineToggleAppearance()
        if OfficerPanel.frame and OfficerPanel.frame:IsShown() then
            SchlingelInc.OfficerPanel:RefreshProgress()
        end
    end)
    offlineToggleButton:SetScript("OnEnter", function() offlineToggleLabel:SetTextColor(1, 1, 0.7, 1) end)
    offlineToggleButton:SetScript("OnLeave", UpdateOfflineToggleAppearance)

    -- Left side: Lade-Indikator | Anfordern | Filter
    local loadStatusLabel = progressContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    loadStatusLabel:SetPoint("LEFT", progressContainer, "TOPLEFT", 4, -11)
    loadStatusLabel:SetWidth(72)
    loadStatusLabel:SetJustifyH("LEFT")
    loadStatusLabel:SetTextColor(0.6, 0.82, 1, 1)
    loadStatusLabel:Hide()

    local requestButton = CreateFrame("Button", nil, progressContainer, "UIPanelButtonTemplate")
    requestButton:SetSize(90, 18)
    requestButton:SetPoint("TOPLEFT", progressContainer, "TOPLEFT", 80, -4)
    requestButton:SetText("Anfordern")
    requestButton:SetScript("OnClick", function()
        SchlingelInc.LevelUps:RequestProgress()
    end)

    OfficerPanel.StartProgressLoad = function(total)
        loadStatusLabel:SetText("Lade 0/" .. total)
        loadStatusLabel:Show()
    end

    OfficerPanel.UpdateProgressLoad = function(received, total)
        loadStatusLabel:SetText("Lade " .. received .. "/" .. total)
    end

    OfficerPanel.EndProgressLoad = function()
        loadStatusLabel:Hide()
    end

    local filterToggleButton = CreateFrame("Button", nil, progressContainer, "UIPanelButtonTemplate")
    filterToggleButton:SetSize(60, 18)
    filterToggleButton:SetPoint("LEFT", requestButton, "RIGHT", 4, 0)
    filterToggleButton:SetText("Filter")
    filterToggleButton:SetScript("OnClick", function()
        local panel = OfficerPanel.tabFilterPanels.progress
        if panel then panel:SetShown(not panel:IsShown()) end
    end)

    local headerDivider = progressContainer:CreateTexture(nil, "ARTWORK")
    headerDivider:SetHeight(1)
    headerDivider:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.DIVIDER))
    headerDivider:SetPoint("TOPLEFT",  progressContainer, "TOPLEFT",  4, -44)
    headerDivider:SetPoint("TOPRIGHT", progressContainer, "TOPRIGHT", -4, -44)

    local scrollFrame, scrollChild = SchlingelInc.Shared.CreateScrollFrame({
        parent     = progressContainer,
        template   = "UIPanelScrollFrameTemplate",
        step       = 20,
        childWidth = scrollWidth,
    })
    scrollFrame:SetPoint("TOPLEFT",     progressContainer, "TOPLEFT",     4, -48)
    scrollFrame:SetPoint("BOTTOMRIGHT", progressContainer, "BOTTOMRIGHT", -20, 8)

    progressContainer.scrollChild  = scrollChild
    progressContainer.progressRows = {}

    local barWidth = 55
    local barX     = 190

    local function GetMemberVersion(shortName)
        local version = SchlingelInc.guildMemberVersions[shortName]
        if version then return version end
        for name, storedVersion in pairs(SchlingelInc.guildMemberVersions) do
            if SchlingelInc:RemoveRealmFromName(name) == shortName then return storedVersion end
        end
    end

    local function RefreshProgress()
        if not progressContainer:IsShown() then return end
        for _, row in ipairs(progressContainer.progressRows) do row:Hide() end
        wipe(progressContainer.progressRows)

        local list = {}
        for i = 1, GetNumGuildMembers() or 0 do
            local name, rankName, _, rosterLevel, classDisplay, zone, note, _, isOnline, _, classToken = GetGuildRosterInfo(i)
            if name then
                local shortName   = SchlingelInc:RemoveRealmFromName(name)
                local data        = SchlingelInc.LevelUps.progressCache[shortName]
                local level       = rosterLevel or 0
                local xpCurrent, xpMax, xpPct = 0, 0, 0
                local gold, runesKnown, xpStop, timestamp = nil, nil, nil, 0
                local hasProgress = false

                if data then
                    hasProgress = true
                    level       = data.level or level
                    xpCurrent   = data.xpCurrent or 0
                    xpMax       = data.xpMax or 0
                    if xpMax > 0 then
                        xpPct = math.floor(xpCurrent / xpMax * 100)
                    elseif xpMax == 0 and level >= SchlingelInc.Constants.MAX_LEVEL then
                        xpPct = 100
                    end
                    gold       = data.gold
                    runesKnown = data.runesKnown
                    xpStop     = data.xpStop
                    timestamp  = data.timestamp or 0
                end

                local memberInfo = MemberInspector.GetProfileEntry(shortName)

                table.insert(list, {
                    name         = shortName,
                    level        = level,
                    xpCurrent    = xpCurrent,
                    xpMax        = xpMax,
                    xpPct        = xpPct,
                    gold         = gold,
                    runesKnown   = runesKnown,
                    xpStop       = xpStop,
                    isOnline     = isOnline == true,
                    timestamp    = timestamp,
                    hasProgress  = hasProgress,
                    version      = GetMemberVersion(shortName),
                    rank         = rankName     or "",
                    classDisplay = classDisplay or "",
                    classToken   = classToken   or "",
                    zone         = zone         or "",
                    note         = note         or "",
                    role         = memberInfo.role,
                    prof1        = memberInfo.prof1,
                    prof2        = memberInfo.prof2,
                    discord      = memberInfo.discord,
                    deaths       = memberInfo.deaths,
                })
            end
        end

        local onlineCount = 0
        for _, entry in ipairs(list) do if entry.isOnline then onlineCount = onlineCount + 1 end end
        if progressContainer.memberCountLabel then
            progressContainer.memberCountLabel:SetText(#list .. " (|cff44ff44" .. onlineCount .. " online|r)")
        end

        if hideOfflineProgress then
            local filtered = {}
            for _, entry in ipairs(list) do
                if entry.isOnline then table.insert(filtered, entry) end
            end
            list = filtered
        end

        local progressFilter = OfficerPanel.progressFilter
        local search          = (progressFilter.filterName or ""):lower()
        if search ~= "" then
            local filtered = {}
            for _, entry in ipairs(list) do
                if (entry.name or ""):lower():find(search, 1, true) then table.insert(filtered, entry) end
            end
            list = filtered
        end
        if progressFilter.levelValue then
            local levelThreshold = progressFilter.levelValue
            local filtered = {}
            for _, entry in ipairs(list) do
                if (progressFilter.levelBelow and entry.level <= levelThreshold) or
                   (not progressFilter.levelBelow and entry.level >= levelThreshold) then
                    table.insert(filtered, entry)
                end
            end
            list = filtered
        end
        if progressFilter.capOnly then
            local levelCap = SchlingelInc.Rules.CurrentCap or 0
            if levelCap > 0 then
                local filtered = {}
                for _, entry in ipairs(list) do
                    if entry.level >= levelCap then table.insert(filtered, entry) end
                end
                list = filtered
            end
        end
        if progressFilter.goldValue then
            local goldThreshold = progressFilter.goldValue * 10000
            local filtered = {}
            for _, entry in ipairs(list) do
                local entryGold = entry.gold or 0
                if (progressFilter.goldBelow and entryGold <= goldThreshold) or
                   (not progressFilter.goldBelow and entryGold >= goldThreshold) then
                    table.insert(filtered, entry)
                end
            end
            list = filtered
        end

        for i, column in ipairs(progressColumns) do
            local active = i == progressSortCol
            local arrow  = active and (progressSortAsc and " ^" or " v") or ""
            progressHeaders[i]:SetText(column.label .. arrow)
            progressHeaders[i]:SetTextColor(active and 1 or 1, active and 1 or 0.82, active and 0.45 or 0, 1)
        end

        local compact = {}
        for _, entry in ipairs(list) do
            if type(entry) == "table" then table.insert(compact, entry) end
        end
        list = compact

        local sortColumn = progressColumns[progressSortCol] or progressColumns[1]
        local key        = sortColumn and sortColumn.sortKey or "name"
        local ascending  = progressSortAsc == true

        -- Manual selection sort avoids Lua's table.sort edge-cases with malformed input.
        local function IsLess(entryA, entryB)
            if entryA == entryB then return false end
            if type(entryA) ~= "table" then return false end
            if type(entryB) ~= "table" then return true end
            local valueA, valueB
            if key == "name" then
                valueA = tostring(entryA.name or ""):lower()
                valueB = tostring(entryB.name or ""):lower()
            else
                valueA = tonumber(entryA[key]) or 0
                valueB = tonumber(entryB[key]) or 0
            end
            if valueA ~= valueB then
                if ascending then return valueA < valueB else return valueA > valueB end
            end
            local nameA = tostring(entryA.name or ""):lower()
            local nameB = tostring(entryB.name or ""):lower()
            if nameA ~= nameB then return nameA < nameB end
            local levelA, levelB = tonumber(entryA.level) or 0, tonumber(entryB.level) or 0
            if levelA ~= levelB then return levelA > levelB end
            local xpA, xpB = tonumber(entryA.xpPct) or 0, tonumber(entryB.xpPct) or 0
            if xpA ~= xpB then return xpA > xpB end
            local timeA, timeB = tonumber(entryA.timestamp) or 0, tonumber(entryB.timestamp) or 0
            if timeA ~= timeB then return timeA > timeB end
            return false
        end

        local count = #list
        for i = 1, count - 1 do
            local best = i
            for j = i + 1, count do
                if IsLess(list[j], list[best]) then best = j end
            end
            if best ~= i then list[i], list[best] = list[best], list[i] end
        end

        if #list == 0 then
            local message = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            message:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, 0)
            message:SetText("Noch keine Daten. Klicke auf Anfordern, um alle Online-Mitglieder um ihre Fortschritte zu bitten.")
            message:SetTextColor(0.6, 0.6, 0.6, 1)
            table.insert(progressContainer.progressRows, message)
            scrollChild:SetHeight(20)
            return
        end

        local rowHeight = 22
        local levelCap  = SchlingelInc.Rules.CurrentCap

        for idx, entry in ipairs(list) do
            local row = CreateFrame("Frame", nil, scrollChild)
            row:SetSize(scrollWidth, rowHeight)
            row:SetPoint("TOPLEFT", 0, -(idx - 1) * rowHeight)
            row:EnableMouse(true)
            row:SetScript("OnMouseUp", function(_, mouseButton)
                if mouseButton == "LeftButton" then
                    SchlingelInc.LevelUps:RequestProgress(entry.name)
                elseif mouseButton == "RightButton" then
                    SchlingelInc.OfficerPanel:ShowMemberContextMenu(entry.name)
                end
            end)

            local isAtCap = levelCap > 0 and entry.level >= levelCap
            if isAtCap and entry.xpStop == false then
                local background = row:CreateTexture(nil, "BACKGROUND")
                background:SetAllPoints()
                background:SetColorTexture(0.4, 0.65, 0.9, 0.55)
            elseif idx % 2 == 0 then
                local background = row:CreateTexture(nil, "BACKGROUND")
                background:SetAllPoints()
                background:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.ROW_STRIPE))
            end

            local hoverTexture = row:CreateTexture(nil, "BACKGROUND")
            hoverTexture:SetAllPoints()
            hoverTexture:SetColorTexture(1, 1, 1, 0)
            row:SetScript("OnEnter", function()
                hoverTexture:SetColorTexture(1, 1, 1, 0.06)
                MemberInspector.ShowTooltip(row, entry)
            end)
            row:SetScript("OnLeave", function()
                hoverTexture:SetColorTexture(1, 1, 1, 0)
                GameTooltip:Hide()
            end)

            local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nameLabel:SetPoint("LEFT", row, "LEFT", 4, 0)
            nameLabel:SetWidth(84)
            nameLabel:SetJustifyH("LEFT")
            nameLabel:SetText(entry.name)
            if not entry.isOnline then nameLabel:SetTextColor(0.5, 0.5, 0.5, 1) end

            local levelLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            levelLabel:SetPoint("LEFT", row, "LEFT", 96, 0)
            levelLabel:SetWidth(40)
            levelLabel:SetJustifyH("CENTER")
            levelLabel:SetText(tostring(entry.level))
            levelLabel:SetTextColor(isAtCap and 1 or 1, isAtCap and 0.82 or 1, isAtCap and 0 or 1, 1)

            local runesLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            runesLabel:SetPoint("LEFT", row, "LEFT", 144, 0)
            runesLabel:SetWidth(38)
            runesLabel:SetJustifyH("CENTER")
            if entry.runesKnown ~= nil then
                runesLabel:SetText(tostring(entry.runesKnown))
                runesLabel:SetTextColor(1, 1, 1, 1)
            else
                runesLabel:SetText("\226\128\148")
                runesLabel:SetTextColor(0.55, 0.55, 0.55, 1)
            end

            local barBackground = row:CreateTexture(nil, "BACKGROUND")
            barBackground:SetSize(barWidth, 8)
            barBackground:SetPoint("LEFT", row, "LEFT", barX, 0)
            barBackground:SetColorTexture(0.15, 0.15, 0.15, 1)

            local fillWidth = 0
            if entry.hasProgress then
                fillWidth = math.max(1, math.floor(barWidth * entry.xpPct / 100))
            elseif isAtCap then
                fillWidth = barWidth
            end
            local fillBar = row:CreateTexture(nil, "ARTWORK")
            fillBar:SetSize(fillWidth, 8)
            fillBar:SetPoint("LEFT", barBackground, "LEFT", 0, 0)
            fillBar:SetColorTexture(
                isAtCap and 1 or 0.2, isAtCap and 0.82 or 0.75, isAtCap and 0 or 0.2,
                entry.hasProgress and 1 or 0)

            local percentLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            percentLabel:SetPoint("LEFT", row, "LEFT", barX + barWidth + 4, 0)
            percentLabel:SetWidth(41)
            percentLabel:SetJustifyH("CENTER")
            if not entry.hasProgress then
                if isAtCap then
                    percentLabel:SetText("Cap")
                    percentLabel:SetTextColor(1, 0.82, 0, 1)
                else
                    percentLabel:SetText("\226\128\148")
                    percentLabel:SetTextColor(0.55, 0.55, 0.55, 1)
                end
            else
                percentLabel:SetText(entry.xpPct .. "%")
                percentLabel:SetTextColor(isAtCap and 1 or 1, isAtCap and 0.82 or 1, isAtCap and 0 or 1, 1)
            end

            local goldLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            goldLabel:SetPoint("LEFT", row, "LEFT", 294, 0)
            goldLabel:SetWidth(64)
            goldLabel:SetJustifyH("RIGHT")
            goldLabel:SetWordWrap(false)
            goldLabel:SetText(FormatGoldShort(entry.gold))
            goldLabel:SetTextColor(1, 0.82, 0, 1)

            local versionLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            versionLabel:SetPoint("LEFT", row, "LEFT", 362, 0)
            versionLabel:SetWidth(38)
            versionLabel:SetJustifyH("RIGHT")
            versionLabel:SetWordWrap(false)
            if entry.version then
                versionLabel:SetText(entry.version)
                versionLabel:SetTextColor(1, 1, 1, 1)
            else
                versionLabel:SetText("\226\128\148")
                versionLabel:SetTextColor(0.55, 0.55, 0.55, 1)
            end

            local ageLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ageLabel:SetPoint("LEFT", row, "LEFT", 408, 0)
            ageLabel:SetWidth(38)
            ageLabel:SetJustifyH("RIGHT")
            ageLabel:SetText(FormatAge(entry.timestamp))
            ageLabel:SetTextColor(entry.isOnline and 0.5 or 0.8, 0.5, entry.isOnline and 0.5 or 0.2, 1)

            table.insert(progressContainer.progressRows, row)
        end

        scrollChild:SetHeight(math.max(1, #list * rowHeight))
        scrollFrame:SetVerticalScroll(0)
    end

    progressContainer.Refresh = RefreshProgress
    SchlingelInc.OfficerPanel.RefreshProgress = RefreshProgress
end
