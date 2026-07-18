local OfficerPanel = SchlingelInc.OfficerPanel

function OfficerPanel.BuildDiscordTab(dc)
    local SCROLL_W = OfficerPanel.SCROLL_W

    local DCOLS = {
        { label = "Discord",    x = 0,   w = 150 },
        { label = "Chars",      x = 154, w = 42  },
        { label = "Charaktere", x = 200, w = 250 },
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
    dhdrDiv:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.DIVIDER))
    dhdrDiv:SetPoint("TOPLEFT",  dc, "TOPLEFT",  4, -22)
    dhdrDiv:SetPoint("TOPRIGHT", dc, "TOPRIGHT", -4, -22)

    local dcFilterBtn = CreateFrame("Button", nil, dc, "UIPanelButtonTemplate")
    dcFilterBtn:SetSize(70, 22)
    dcFilterBtn:SetPoint("BOTTOMRIGHT", dc, "BOTTOMRIGHT", -4, 8)
    dcFilterBtn:SetText("Filter")
    dcFilterBtn:SetScript("OnClick", function()
        local fp = OfficerPanel.tabFilterPanels.discord
        if fp then fp:SetShown(not fp:IsShown()) end
    end)

    local dScrollFrame, dScrollChild = SchlingelInc.Shared.CreateScrollFrame({
        parent     = dc,
        template   = "UIPanelScrollFrameTemplate",
        step       = 20,
        childWidth = SCROLL_W,
    })
    dScrollFrame:SetPoint("TOPLEFT",     dc, "TOPLEFT",     4, -26)
    dScrollFrame:SetPoint("BOTTOMRIGHT", dc, "BOTTOMRIGHT", -20, 36)

    dc.dScrollChild = dScrollChild
    dc.discordRows  = {}

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
        table.sort(list, function(a, b)
            if a.count ~= b.count then return a.count > b.count end
            return string.lower(a.handle) < string.lower(b.handle)
        end)
        return list
    end

    local function RefreshDiscordHandles()
        for _, row in ipairs(dc.discordRows) do row:Hide() end
        wipe(dc.discordRows)

        local df   = OfficerPanel.discordFilter
        local raw  = BuildDiscordHandleData()
        local srch = (df.filterName or ""):lower()
        local list = raw
        if srch ~= "" then
            list = {}
            for _, e in ipairs(raw) do
                if (e.handle or ""):lower():find(srch, 1, true) or
                   (e.names  or ""):lower():find(srch, 1, true) then
                    table.insert(list, e)
                end
            end
        end
        if df.minCount then
            local mc  = df.minCount
            local out = {}
            for _, e in ipairs(list) do
                if e.count >= mc then table.insert(out, e) end
            end
            list = out
        end

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
            row:SetSize(SCROLL_W, ROW_H)
            row:SetPoint("TOPLEFT", 0, -(idx - 1) * ROW_H)

            if idx % 2 == 0 then
                local bg = row:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.ROW_STRIPE))
            end

            local function Cell(text, xPos, w, r, g, b)
                local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                fs:SetPoint("LEFT", row, "LEFT", xPos + 4, 0)
                fs:SetWidth(w)
                fs:SetJustifyH("LEFT")
                fs:SetText(text)
                if r then fs:SetTextColor(r, g, b, 1) end
            end

            Cell(entry.handle,          0,   146, 0.65, 0.65, 1)
            Cell(tostring(entry.count), 154, 38,  1,    0.82, 0)
            Cell(entry.names,           200, 246)

            table.insert(dc.discordRows, row)
        end

        dScrollChild:SetHeight(math.max(1, #list * ROW_H))
        dScrollFrame:SetVerticalScroll(0)
    end

    dc.Refresh = RefreshDiscordHandles
    OfficerPanel.RefreshDiscordHandles = RefreshDiscordHandles
end
