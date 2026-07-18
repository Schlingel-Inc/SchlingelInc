local OfficerPanel = SchlingelInc.OfficerPanel

local function FormatGold(copper)
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if g > 0 then     return string.format("%dg %ds %dc", g, s, c)
    elseif s > 0 then return string.format("%ds %dc", s, c)
    else              return string.format("%dc", c)
    end
end

function OfficerPanel.BuildInvitesTab(vc)
    local SCROLL_W = OfficerPanel.SCROLL_W

    local VCOLS = {
        { label = "Name",  x = 0,   w = 80  },
        { label = "Level", x = 84,  w = 32  },
        { label = "Runen", x = 120, w = 42  },
        { label = "XP",    x = 166, w = 50  },
        { label = "Gold",  x = 220, w = 58  },
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
    vhdrDiv:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.DIVIDER))
    vhdrDiv:SetPoint("TOPLEFT",  vc, "TOPLEFT",  4, -22)
    vhdrDiv:SetPoint("TOPRIGHT", vc, "TOPRIGHT", -4, -22)

    local vScrollFrame, vScrollChild = SchlingelInc.Shared.CreateScrollFrame({
        parent     = vc,
        template   = "UIPanelScrollFrameTemplate",
        step       = 20,
        childWidth = SCROLL_W,
    })
    vScrollFrame:SetPoint("TOPLEFT",     vc, "TOPLEFT",     4, -26)
    vScrollFrame:SetPoint("BOTTOMRIGHT", vc, "BOTTOMRIGHT", -20, 8)

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

            Cell(entry.name,                                                       0,   76,  1, 1, 1)
            Cell(tostring(entry.level),                                            84,  28,  1, 1, 1)
            Cell(entry.runesKnown ~= nil and tostring(entry.runesKnown) or "\226\128\148", 120, 38, 1, 1, 1)
            Cell(tostring(entry.xp),                                               166, 46,  1, 1, 1)
            Cell(FormatGold(entry.gold or 0),                                      220, 54,  1, 1, 1)
            Cell(entry.zone,                                                       282, 122, 1, 1, 1)

            if OfficerPanel.IsOfficer() then
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
                acceptBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

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
                declineBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end

            table.insert(vc.inviteRows, row)
        end

        vScrollChild:SetHeight(math.max(1, #list * ROW_H))
        vScrollFrame:SetVerticalScroll(0)
    end

    vc.Refresh = RefreshInvites
    OfficerPanel.RefreshInvites = RefreshInvites
end
