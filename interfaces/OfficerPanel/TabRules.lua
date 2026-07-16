local OfficerPanel = SchlingelInc.OfficerPanel

function OfficerPanel.BuildRulesTab(rc)
    local officer = OfficerPanel.IsOfficer()

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
    SchlingelInc:RegisterDropdownAutoClose(mailDropdown)
    UIDropDownMenu_Initialize(mailDropdown, function()
        for _, option in ipairs(mailRuleOptions) do
            local value, label = option.value, option.label
            local info = UIDropDownMenu_CreateInfo()
            info.text    = label
            info.value   = value
            info.checked = selectedMailRule == value
            info.func    = function()
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
        { label = "Auktionshaus sperren",                      dbKey = "auctionHouseRule"  },
        { label = "Handel mit Nicht-Mitgliedern sperren",      dbKey = "tradeRule"         },
        { label = "Gruppierung mit Nicht-Mitgliedern sperren", dbKey = "groupingRule"      },
        { label = "SoD-Händler sperren",                       dbKey = "blockedTraderRule" },
        { label = "Duelle automatisch ablehnen",               dbKey = nil                 },
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
                cap
            )
            SchlingelOptionsDB = SchlingelOptionsDB or {}
            SchlingelOptionsDB.auto_decline_duels =
                checkboxes["Duelle automatisch ablehnen"]:GetChecked() == true
        end)
    end
end
