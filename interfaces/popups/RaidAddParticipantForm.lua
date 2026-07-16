-- interfaces/popups/RaidAddParticipantForm.lua
-- Poster-only popup to add (or correct) a raid participant who signed up outside
-- the addon, e.g. in Discord. Name must resolve to an actual guild member.

SchlingelInc.Popup = SchlingelInc.Popup or {}

local FC = SchlingelInc.Constants.FORM_COLORS

local FORM_W  = 280
local INNER_W = FORM_W - 32
local MAX_SUGGESTIONS = 8

local function CreateEditBox(parent, width, maxLetters)
    local eb = CreateFrame("EditBox", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
    eb:SetSize(width, 22)
    eb:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
    eb:SetBackdropColor(unpack(FC.EDITBOX_BG))
    eb:SetBackdropBorderColor(unpack(FC.EDITBOX_BORDER))
    eb:SetFontObject("GameFontHighlight")
    eb:SetTextInsets(6, 6, 0, 0)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(maxLetters)
    eb:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    return eb
end

local function CreateLabel(parent, text)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetText(text)
    lbl:SetTextColor(unpack(FC.LABEL))
    return lbl
end

-- Matches roster members by character name OR by the Discord handle stored in their
-- profile — a Discord signup names the person, not necessarily this specific
-- character, so one query can surface several of that player's guild characters.
local function MatchingRosterNames(query)
    query = query:lower()
    if query == "" then return {} end

    local out = {}
    for _, member in ipairs(SchlingelInc.GuildCache:GetFullRoster()) do
        local nameMatches = member.name:lower():find(query, 1, true)
        local profile = SchlingelGuildProfileCache and SchlingelGuildProfileCache[member.name]
        local discord = profile and profile.discord or ""
        local discordMatches = not nameMatches and discord ~= "" and discord:lower():find(query, 1, true)
        if nameMatches or discordMatches then
            table.insert(out, { name = member.name, discord = discordMatches and discord or nil })
            if #out >= MAX_SUGGESTIONS then break end
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

local function BuildForm()
    local f = CreateFrame("Frame", "SchlingelRaidAddParticipantForm", UIParent, "BackdropTemplate")
    f:SetSize(FORM_W, 230)
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop(SchlingelInc.Constants.BACKDROP)
    f:SetBackdropColor(unpack(FC.FORM_BG))
    f:SetBackdropBorderColor(unpack(FC.FORM_BORDER))
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SchlingelInc:SaveFramePosition(self, "raidaddparticipantform_position")
    end)
    SchlingelInc:RestoreFramePosition(f, "raidaddparticipantform_position", "CENTER", 0, 40)
    SchlingelInc:RegisterFrameForEscape(f)
    f:Hide()

    local titleFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFs:SetPoint("TOP", f, "TOP", 0, -16)
    titleFs:SetText("Teilnehmer hinzufügen")
    titleFs:SetTextColor(unpack(FC.TITLE))

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local raidFs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    raidFs:SetPoint("TOP", titleFs, "BOTTOM", 0, -6)
    raidFs:SetWidth(INNER_W)
    raidFs:SetJustifyH("CENTER")
    f.raidFs = raidFs

    -- ── Name (autocomplete against Charaktername + Discord-Handle) ──────────
    local nameLbl = CreateLabel(f, "Name oder Discord:")
    nameLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -66)

    local nameEB = CreateEditBox(f, INNER_W, 24)
    nameEB:SetPoint("TOPLEFT", nameLbl, "BOTTOMLEFT", 0, -4)
    f.nameEB = nameEB

    local suggestList = CreateFrame("Frame", "SchlingelRaidAddParticipantSuggestions", UIParent, "BackdropTemplate")
    suggestList:SetSize(INNER_W, 10)
    suggestList:SetFrameStrata("TOOLTIP")
    suggestList:SetBackdrop(SchlingelInc.Constants.DROPDOWNBACKDROP)
    suggestList:SetBackdropColor(unpack(FC.LIST_BG))
    suggestList:SetBackdropBorderColor(unpack(FC.FORM_BORDER))
    suggestList:SetPoint("TOPLEFT", nameEB, "BOTTOMLEFT", 0, -2)
    suggestList:Hide()
    -- A full-screen click-catcher (like the other dropdown lists use) would also
    -- swallow clicks meant for nameEB itself, so close on focus-lost instead —
    -- delayed slightly so a click on a suggestion button still registers first.
    nameEB:SetScript("OnEditFocusLost", function()
        C_Timer.After(0.15, function() suggestList:Hide() end)
    end)
    f:HookScript("OnHide", function() suggestList:Hide() end)

    local ITEM_H = 18
    local function RefreshSuggestions()
        for _, child in ipairs({ suggestList:GetChildren() }) do child:Hide() end

        local matches = MatchingRosterNames(nameEB:GetText())
        if #matches == 0 then
            suggestList:Hide()
            return
        end

        local yOff = -4
        for _, match in ipairs(matches) do
            local btn = CreateFrame("Button", nil, suggestList)
            btn:SetSize(INNER_W - 8, ITEM_H)
            btn:SetPoint("TOPLEFT", suggestList, "TOPLEFT", 4, yOff)
            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetAllPoints()
            lbl:SetJustifyH("LEFT")
            lbl:SetText(match.discord and (match.name .. " |cff888888(" .. match.discord .. ")|r") or match.name)
            lbl:SetTextColor(unpack(FC.LIST_ITEM_TEXT))
            btn:SetScript("OnClick", function()
                nameEB:SetText(match.name)
                nameEB:ClearFocus()
                suggestList:Hide()
            end)
            btn:SetScript("OnEnter", function() lbl:SetTextColor(unpack(FC.HOVER)) end)
            btn:SetScript("OnLeave", function() lbl:SetTextColor(unpack(FC.LIST_ITEM_TEXT)) end)
            yOff = yOff - ITEM_H - 2
        end
        suggestList:SetHeight(math.abs(yOff) + 4)
        suggestList:Show()
    end
    nameEB:SetScript("OnTextChanged", RefreshSuggestions)
    nameEB:SetScript("OnEditFocusGained", RefreshSuggestions)

    -- ── Rolle ────────────────────────────────────────────────────────────────
    local roleLbl = CreateLabel(f, "Rolle:")
    roleLbl:SetPoint("TOPLEFT", nameEB, "BOTTOMLEFT", 0, -14)

    local roleBtns = {}
    local roles = SchlingelInc.Constants.ROLES
    local rbW   = math.floor((INNER_W - 4 * (#roles - 1)) / #roles)
    for i, roleName in ipairs(roles) do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(rbW, 22)
        btn:SetPoint("TOPLEFT", roleLbl, "BOTTOMLEFT", (i - 1) * (rbW + 4), -4)
        btn:EnableMouse(true)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(unpack(FC.OPTION_BG))

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints()
        lbl:SetJustifyH("CENTER")
        lbl:SetText(roleName)

        local function UpdateBtn()
            if f.selectedRole == roleName then
                bg:SetColorTexture(unpack(FC.OPTION_BG_SELECTED))
                lbl:SetTextColor(unpack(FC.TITLE))
            else
                bg:SetColorTexture(unpack(FC.OPTION_BG))
                lbl:SetTextColor(unpack(FC.OPTION_TEXT))
            end
        end
        btn.UpdateAppearance = UpdateBtn
        UpdateBtn()

        btn:SetScript("OnClick", function()
            f.selectedRole = roleName
            for _, b in ipairs(roleBtns) do b.UpdateAppearance() end
        end)
        btn:SetScript("OnEnter", function() lbl:SetTextColor(unpack(FC.HOVER)) end)
        btn:SetScript("OnLeave", UpdateBtn)

        roleBtns[i] = btn
    end
    f.roleBtns = roleBtns

    local errorFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    errorFs:SetPoint("TOPLEFT", roleLbl, "BOTTOMLEFT", 0, -34)
    errorFs:SetWidth(INNER_W)
    errorFs:SetJustifyH("LEFT")
    errorFs:SetTextColor(unpack(FC.ERROR))
    f.errorFs = errorFs

    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(100, 22)
    addBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
    addBtn:SetText("Hinzufügen")

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(90, 22)
    cancelBtn:SetPoint("RIGHT", addBtn, "LEFT", -8, 0)
    cancelBtn:SetText("Abbrechen")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    addBtn:SetScript("OnClick", function()
        errorFs:SetText("")

        local typed = nameEB:GetText():match("^%s*(.-)%s*$")
        local resolvedName = nil
        for _, member in ipairs(SchlingelInc.GuildCache:GetFullRoster()) do
            if member.name:lower() == typed:lower() then
                resolvedName = member.name
                break
            end
        end
        if not resolvedName then
            errorFs:SetText("Bitte einen gültigen Namen aus der Gilde auswählen.")
            return
        end
        if not f.selectedRole then
            errorFs:SetText("Bitte eine Rolle auswählen.")
            return
        end

        local ok, err = SchlingelInc.Raid:AddParticipant(f.entryId, resolvedName, f.selectedRole)
        if not ok then
            errorFs:SetText(err or "Unbekannter Fehler.")
            return
        end

        f:Hide()
        if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshRaid then
            SchlingelInc.GuildPanel:RefreshRaid()
        end
    end)

    f.titleFs = titleFs
    return f
end

function SchlingelInc.Popup:ShowRaidAddParticipantForm(entry)
    if not entry then return end
    if not SchlingelInc.Popup.raidAddParticipantForm then
        SchlingelInc.Popup.raidAddParticipantForm = BuildForm()
    end
    local f = SchlingelInc.Popup.raidAddParticipantForm

    f.entryId = entry.id
    f.raidFs:SetText(SchlingelInc:SanitizeText(entry.title))
    f.errorFs:SetText("")
    f.nameEB:SetText("")
    f.selectedRole = nil
    for _, b in ipairs(f.roleBtns) do b.UpdateAppearance() end

    f:Show()
end
