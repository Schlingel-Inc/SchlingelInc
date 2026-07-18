-- interfaces/popups/RaidAddParticipantForm.lua
-- Poster-only popup to add (or correct) a raid participant who signed up outside
-- the addon, e.g. in Discord. Name must resolve to an actual guild member.

SchlingelInc.Popup = SchlingelInc.Popup or {}

local FC = SchlingelInc.Constants.FORM_COLORS

local FORM_W  = 280
local INNER_W = FORM_W - 32
local MAX_SUGGESTIONS = 8
local MAX_ROLES = #SchlingelInc.Constants.ROLES

-- Roles a given roster member has configured in their guild profile ("Tank/Heal"
-- style, "/"-delimited), in canonical ROLES order. Empty if no profile or no roles set.
local function GetProfileRoles(name)
    local profile = SchlingelGuildProfileCache and SchlingelGuildProfileCache[name]
    local raw = profile and profile.role or ""
    local set = {}
    for part in raw:gmatch("[^/]+") do set[part] = true end
    local out = {}
    for _, r in ipairs(SchlingelInc.Constants.ROLES) do
        if set[r] then table.insert(out, r) end
    end
    return out
end

local function ResolveRosterName(typed)
    typed = typed:match("^%s*(.-)%s*$")
    for _, member in ipairs(SchlingelInc.GuildCache:GetFullRoster()) do
        if member.name:lower() == typed:lower() then
            return member.name
        end
    end
    return nil
end

-- Shows only the given roles' buttons (in order), keeping the previous selection
-- if it's still among them, auto-selecting when only one choice remains.
local function ApplyRoleChoices(f, choices)
    local previousSelection = f.selectedRole
    local rbW = math.floor((INNER_W - 4 * (#choices - 1)) / #choices)
    for i, btn in ipairs(f.roleBtns) do
        if i <= #choices then
            btn.roleName = choices[i]
            btn.lbl:SetText(choices[i])
            btn:ClearAllPoints()
            btn:SetSize(rbW, 22)
            btn:SetPoint("TOPLEFT", f.roleLbl, "BOTTOMLEFT", (i - 1) * (rbW + 4), -4)
            btn:Show()
        else
            btn:Hide()
        end
    end

    if #choices == 1 then
        f.selectedRole = choices[1]
    else
        local stillValid = false
        for _, r in ipairs(choices) do if r == previousSelection then stillValid = true end end
        f.selectedRole = stillValid and previousSelection or nil
    end
    for _, b in ipairs(f.roleBtns) do b.UpdateAppearance() end
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
    local f = SchlingelInc.Shared.CreateStandardFrame({
        name          = "SchlingelRaidAddParticipantForm",
        width         = FORM_W,
        height        = 230,
        strata        = "DIALOG",
        positionKey   = "raidaddparticipantform_position",
        defaultPoint  = "CENTER",
        defaultX      = 0,
        defaultY      = 40,
        registerEscape = true,
        closeButton   = true,
    })

    local titleFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFs:SetPoint("TOP", f, "TOP", 0, -16)
    titleFs:SetText("Teilnehmer hinzufügen")
    titleFs:SetTextColor(unpack(FC.TITLE))

    local raidFs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    raidFs:SetPoint("TOP", titleFs, "BOTTOM", 0, -6)
    raidFs:SetWidth(INNER_W)
    raidFs:SetJustifyH("CENTER")
    f.raidFs = raidFs

    -- ── Name (autocomplete against Charaktername + Discord-Handle) ──────────
    local nameLbl = SchlingelInc.Shared.CreateLabel(f, "Name oder Discord:")
    nameLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -66)

    local nameEB = SchlingelInc.Shared.CreateEditBox(f, INNER_W, 24)
    nameEB:SetPoint("TOPLEFT", nameLbl, "BOTTOMLEFT", 0, -4)
    f.nameEB = nameEB

    local suggestList = CreateFrame("Frame", "SchlingelRaidAddParticipantSuggestions", UIParent, "BackdropTemplate")
    suggestList:SetSize(INNER_W, 10)
    suggestList:SetFrameStrata("TOOLTIP")
    suggestList:SetBackdrop(SchlingelInc.Constants.DROPDOWNBACKDROP)
    suggestList:SetBackdropColor(unpack(FC.FORM_BG))
    suggestList:SetBackdropBorderColor(unpack(FC.FORM_BORDER))
    suggestList:SetPoint("TOPLEFT", nameEB, "BOTTOMLEFT", 0, -2)
    suggestList:Hide()
    -- Outside-click catcher (the same convention every other dropdown list in this
    -- addon uses) excludes nameEB itself, so clicking back into the box to keep
    -- typing doesn't fight with it — but Escape/Enter still clear keyboard focus
    -- without a click, so also close on focus-lost as a fallback, delayed slightly
    -- so a click on a suggestion button still registers first.
    SchlingelInc:RegisterOutsideClickClose(suggestList, f, nameEB)
    nameEB:SetScript("OnEditFocusLost", function()
        C_Timer.After(0.15, function() suggestList:Hide() end)
    end)

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
    -- ── Rolle ────────────────────────────────────────────────────────────────
    local roleLbl = SchlingelInc.Shared.CreateLabel(f, "Rolle:")
    roleLbl:SetPoint("TOPLEFT", nameEB, "BOTTOMLEFT", 0, -14)
    f.roleLbl = roleLbl

    -- Fixed pool of buttons, sized in ApplyRoleChoices() to whichever subset of
    -- roles applies to the currently typed name (their profile roles, or the full
    -- list if unresolved / no profile roles set).
    f.roleBtns = SchlingelInc.Shared.CreateRoleToggleGroup(f, f, MAX_ROLES)

    local function RefreshRoleChoices()
        local resolvedName = ResolveRosterName(nameEB:GetText())
        local choices = resolvedName and GetProfileRoles(resolvedName) or {}
        if #choices == 0 then
            choices = { unpack(SchlingelInc.Constants.ROLES) }
        end
        ApplyRoleChoices(f, choices)
    end

    nameEB:SetScript("OnTextChanged", function()
        RefreshSuggestions()
        RefreshRoleChoices()
    end)
    nameEB:SetScript("OnEditFocusGained", RefreshSuggestions)

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

        local resolvedName = ResolveRosterName(nameEB:GetText())
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
