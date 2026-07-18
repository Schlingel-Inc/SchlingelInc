local OfficerPanel = SchlingelInc.OfficerPanel

function OfficerPanel.BuildDiscordTab(discordContainer)
    local scrollWidth = OfficerPanel.SCROLL_W

    local discordColumns = {
        { label = "Discord",    x = 0,   w = 150 },
        { label = "Chars",      x = 154, w = 42  },
        { label = "Charaktere", x = 200, w = 250 },
    }
    for _, column in ipairs(discordColumns) do
        local headerLabel = discordContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        headerLabel:SetPoint("TOPLEFT", discordContainer, "TOPLEFT", column.x + 4, -6)
        headerLabel:SetWidth(column.w)
        headerLabel:SetJustifyH("LEFT")
        headerLabel:SetText(column.label)
        headerLabel:SetTextColor(1, 0.82, 0, 1)
    end

    local headerDivider = discordContainer:CreateTexture(nil, "ARTWORK")
    headerDivider:SetHeight(1)
    headerDivider:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.DIVIDER))
    headerDivider:SetPoint("TOPLEFT",  discordContainer, "TOPLEFT",  4, -22)
    headerDivider:SetPoint("TOPRIGHT", discordContainer, "TOPRIGHT", -4, -22)

    local filterToggleButton = CreateFrame("Button", nil, discordContainer, "UIPanelButtonTemplate")
    filterToggleButton:SetSize(70, 22)
    filterToggleButton:SetPoint("BOTTOMRIGHT", discordContainer, "BOTTOMRIGHT", -4, 8)
    filterToggleButton:SetText("Filter")
    filterToggleButton:SetScript("OnClick", function()
        local panel = OfficerPanel.tabFilterPanels.discord
        if panel then panel:SetShown(not panel:IsShown()) end
    end)

    local scrollFrame, scrollChild = SchlingelInc.Shared.CreateScrollFrame({
        parent     = discordContainer,
        template   = "UIPanelScrollFrameTemplate",
        step       = 20,
        childWidth = scrollWidth,
    })
    scrollFrame:SetPoint("TOPLEFT",     discordContainer, "TOPLEFT",     4, -26)
    scrollFrame:SetPoint("BOTTOMRIGHT", discordContainer, "BOTTOMRIGHT", -20, 36)

    discordContainer.scrollChild  = scrollChild
    discordContainer.discordRows  = {}

    local function BuildDiscordHandleData()
        local byHandle = {}
        local ownName  = UnitName("player")

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
                        byHandle[key] = { handle = handle, chars = {}, online = 0 }
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
        table.sort(list, function(groupA, groupB)
            if groupA.count ~= groupB.count then return groupA.count > groupB.count end
            return string.lower(groupA.handle) < string.lower(groupB.handle)
        end)
        return list
    end

    local function RefreshDiscordHandles()
        for _, row in ipairs(discordContainer.discordRows) do row:Hide() end
        wipe(discordContainer.discordRows)

        local discordFilter = OfficerPanel.discordFilter
        local raw           = BuildDiscordHandleData()
        local search         = (discordFilter.filterName or ""):lower()
        local list = raw
        if search ~= "" then
            list = {}
            for _, entry in ipairs(raw) do
                if (entry.handle or ""):lower():find(search, 1, true) or
                   (entry.names  or ""):lower():find(search, 1, true) then
                    table.insert(list, entry)
                end
            end
        end
        if discordFilter.minCount then
            local minCountThreshold = discordFilter.minCount
            local filtered = {}
            for _, entry in ipairs(list) do
                if entry.count >= minCountThreshold then table.insert(filtered, entry) end
            end
            list = filtered
        end

        local rowHeight = 22

        if #list == 0 then
            local message = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            message:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, 0)
            message:SetText("Keine Discord Handles in den Profilen gefunden.")
            message:SetTextColor(0.6, 0.6, 0.6, 1)
            table.insert(discordContainer.discordRows, message)
            scrollChild:SetHeight(20)
            return
        end

        for idx, entry in ipairs(list) do
            local row = CreateFrame("Frame", nil, scrollChild)
            row:SetSize(scrollWidth, rowHeight)
            row:SetPoint("TOPLEFT", 0, -(idx - 1) * rowHeight)

            if idx % 2 == 0 then
                local background = row:CreateTexture(nil, "BACKGROUND")
                background:SetAllPoints()
                background:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.ROW_STRIPE))
            end

            local function Cell(text, xPos, width, red, green, blue)
                local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                label:SetPoint("LEFT", row, "LEFT", xPos + 4, 0)
                label:SetWidth(width)
                label:SetJustifyH("LEFT")
                label:SetText(text)
                if red then label:SetTextColor(red, green, blue, 1) end
            end

            Cell(entry.handle,          0,   146, 0.65, 0.65, 1)
            Cell(tostring(entry.count), 154, 38,  1,    0.82, 0)
            Cell(entry.names,           200, 246)

            table.insert(discordContainer.discordRows, row)
        end

        scrollChild:SetHeight(math.max(1, #list * rowHeight))
        scrollFrame:SetVerticalScroll(0)
    end

    discordContainer.Refresh          = RefreshDiscordHandles
    OfficerPanel.RefreshDiscordHandles = RefreshDiscordHandles
end
