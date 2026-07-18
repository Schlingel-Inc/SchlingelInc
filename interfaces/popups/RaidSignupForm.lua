-- interfaces/popups/RaidSignupForm.lua
-- Popup to signal interest (role only) on a raid entry, or withdraw an existing
-- signal. Role choices come from SchlingelOwnProfile.role: a single-role profile
-- skips the selector entirely; multi-role shows a selector limited to those roles;
-- no role set falls back to the full Tank/Heal/DPS list.

SchlingelInc.Popup = SchlingelInc.Popup or {}

local FC = SchlingelInc.Constants.FORM_COLORS

local FORM_W    = 260
local INNER_W   = FORM_W - 32
local MAX_ROLES = #SchlingelInc.Constants.ROLES

local function GetOwnRoles()
    local raw = SchlingelOwnProfile and SchlingelOwnProfile.role or ""
    local set = {}
    for part in raw:gmatch("[^/]+") do set[part] = true end
    local out = {}
    for _, r in ipairs(SchlingelInc.Constants.ROLES) do
        if set[r] then table.insert(out, r) end
    end
    return out
end

local function BuildForm()
    local f = SchlingelInc.Shared.CreateStandardFrame({
        name          = "SchlingelRaidSignupForm",
        width         = FORM_W,
        height        = 150,
        strata        = "DIALOG",
        positionKey   = "raidsignupform_position",
        defaultPoint  = "CENTER",
        defaultX      = 0,
        defaultY      = 40,
        registerEscape = true,
        closeButton   = true,
    })

    local titleFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFs:SetPoint("TOP", f, "TOP", 0, -16)
    titleFs:SetText("Zusagen")
    titleFs:SetTextColor(unpack(FC.TITLE))

    local raidFs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    raidFs:SetPoint("TOP", titleFs, "BOTTOM", 0, -6)
    raidFs:SetWidth(INNER_W)
    raidFs:SetJustifyH("CENTER")
    f.raidFs = raidFs

    -- ── Rolle ────────────────────────────────────────────────────────────────
    local roleLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    roleLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -68)
    roleLbl:SetText("Rolle:")
    roleLbl:SetTextColor(unpack(FC.LABEL))

    local soloFs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    soloFs:SetPoint("TOPLEFT", roleLbl, "BOTTOMLEFT", 2, -6)
    f.soloFs = soloFs

    local roleBtns = {}
    for i = 1, MAX_ROLES do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(10, 22)
        btn:EnableMouse(true)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(unpack(FC.OPTION_BG))

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints()
        lbl:SetJustifyH("CENTER")
        btn.lbl = lbl

        local function UpdateBtn()
            if f.selectedRole == btn.roleName then
                bg:SetColorTexture(unpack(FC.OPTION_BG_SELECTED))
                lbl:SetTextColor(unpack(FC.TITLE))
            else
                bg:SetColorTexture(unpack(FC.OPTION_BG))
                lbl:SetTextColor(unpack(FC.OPTION_TEXT))
            end
        end
        btn.UpdateAppearance = UpdateBtn

        btn:SetScript("OnClick", function()
            f.selectedRole = btn.roleName
            for _, b in ipairs(roleBtns) do b.UpdateAppearance() end
        end)
        btn:SetScript("OnEnter", function() lbl:SetTextColor(unpack(FC.HOVER)) end)
        btn:SetScript("OnLeave", UpdateBtn)

        roleBtns[i] = btn
    end
    f.roleBtns = roleBtns
    f.roleLbl  = roleLbl

    local errorFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    errorFs:SetPoint("TOPLEFT", roleLbl, "BOTTOMLEFT", 0, -34)
    errorFs:SetWidth(INNER_W)
    errorFs:SetJustifyH("LEFT")
    errorFs:SetTextColor(unpack(FC.ERROR))
    f.errorFs = errorFs

    local confirmBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    confirmBtn:SetSize(100, 22)
    confirmBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
    confirmBtn:SetText("Bestätigen")
    f.confirmBtn = confirmBtn

    local withdrawBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    withdrawBtn:SetSize(90, 22)
    withdrawBtn:SetPoint("RIGHT", confirmBtn, "LEFT", -8, 0)
    withdrawBtn:SetText("Absagen")
    f.withdrawBtn = withdrawBtn

    confirmBtn:SetScript("OnClick", function()
        errorFs:SetText("")
        if not f.selectedRole then
            errorFs:SetText("Bitte eine Rolle auswählen.")
            return
        end
        local ok, err = SchlingelInc.Raid:Signal(f.entryId, f.selectedRole)
        if not ok then
            errorFs:SetText(err or "Unbekannter Fehler.")
            return
        end
        f:Hide()
        if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshRaid then
            SchlingelInc.GuildPanel:RefreshRaid()
        end
    end)

    withdrawBtn:SetScript("OnClick", function()
        SchlingelInc.Raid:Unsignal(f.entryId)
        f:Hide()
        if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshRaid then
            SchlingelInc.GuildPanel:RefreshRaid()
        end
    end)

    f.titleFs = titleFs
    return f
end

local function ApplyRoleChoices(f, choices, preselected)
    if #choices == 1 then
        f.soloFs:Show()
        f.soloFs:SetText(choices[1])
        for _, b in ipairs(f.roleBtns) do b:Hide() end
        f.selectedRole = choices[1]
        return
    end

    f.soloFs:Hide()
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
    f.selectedRole = preselected
    for _, b in ipairs(f.roleBtns) do b.UpdateAppearance() end
end

function SchlingelInc.Popup:ShowRaidSignup(entry, existingSignal)
    if not entry then return end
    if not SchlingelInc.Popup.raidSignupForm then
        SchlingelInc.Popup.raidSignupForm = BuildForm()
    end
    local f = SchlingelInc.Popup.raidSignupForm

    f.entryId = entry.id
    f.raidFs:SetText(SchlingelInc:SanitizeText(entry.title))
    f.errorFs:SetText("")
    f.withdrawBtn:SetShown(existingSignal ~= nil)

    local choices = GetOwnRoles()
    -- Keep an existing signal's role selectable even if it's since fallen outside
    -- the player's current profile roles.
    if existingSignal and existingSignal.role then
        local found = false
        for _, r in ipairs(choices) do if r == existingSignal.role then found = true break end end
        if not found then table.insert(choices, existingSignal.role) end
    end
    if #choices == 0 then
        for _, r in ipairs(SchlingelInc.Constants.ROLES) do table.insert(choices, r) end
    end

    ApplyRoleChoices(f, choices, existingSignal and existingSignal.role or nil)

    f:Show()
end
