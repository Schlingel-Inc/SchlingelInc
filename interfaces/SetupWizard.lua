-- SetupWizard.lua
-- Unified first-login setup wizard.
-- Steps are built dynamically: only steps that are actually needed are shown.

local WizardFrame
local steps       = {}   -- array of {id, render, onNext} tables
local currentStep = 1

-- ── Helpers ──────────────────────────────────────────────────────────────────

local FRAME_W, FRAME_H = 460, 320
local DOT_SIZE          = 12
local DOT_SPACING       = 20

-- Orphaned content widgets are reparented here so they stop rendering
-- (SetParent(nil) can crash in some Classic builds).
local trashFrame = CreateFrame("Frame")
trashFrame:Hide()

local function ClearContent(frame)
    if frame.contentChildren then
        for _, child in ipairs(frame.contentChildren) do
            child:Hide()
            child:SetParent(trashFrame)
        end
    end
    frame.contentChildren = {}
end

local function TrackChild(frame, child)
    frame.contentChildren = frame.contentChildren or {}
    table.insert(frame.contentChildren, child)
end

-- ── Progress bar ─────────────────────────────────────────────────────────────
-- Uses small colored square textures — Unicode dots are not supported in Classic fonts.

local function UpdateProgress(frame)
    local total = #steps
    -- Resize the container to exactly span the active dots so they stay centered
    frame.dotContainer:SetSize((total - 1) * DOT_SPACING + DOT_SIZE, DOT_SIZE)
    for i, dot in ipairs(frame.dots) do
        if i <= total then
            dot:Show()
            if i < currentStep then
                dot:SetColorTexture(0.3, 0.8, 0.3, 1)   -- done: green
            elseif i == currentStep then
                dot:SetColorTexture(1, 0.82, 0, 1)       -- active: gold
            else
                dot:SetColorTexture(0.3, 0.3, 0.3, 1)   -- future: grey
            end
        else
            dot:Hide()
        end
    end
    frame.stepLabel:SetText("Schritt " .. currentStep .. " von " .. total)
end

-- ── Navigation ───────────────────────────────────────────────────────────────

local function ShowStep(frame, index)
    currentStep = index
    ClearContent(frame)

    local step = steps[index]
    if step then
        step.render(frame)
        frame:SetHeight(step.frameH or FRAME_H)
    end

    UpdateProgress(frame)

    -- Back button
    if index > 1 then
        frame.backBtn:Enable()
        frame.backBtn:SetAlpha(1)
    else
        frame.backBtn:Disable()
        frame.backBtn:SetAlpha(0.4)
    end

    -- Next/Fertig button label
    if index == #steps then
        frame.nextBtn:SetText("Fertig")
    else
        frame.nextBtn:SetText("Weiter >")
    end
end

local function NextStep(frame)
    local step = steps[currentStep]
    local ok = true
    if step and step.onNext then
        ok = step.onNext(frame)
    end
    if not ok then return end

    if currentStep < #steps then
        ShowStep(frame, currentStep + 1)
    else
        frame:Hide()
        -- After wizard: broadcast profile
        SchlingelInc.GuildProfiles:Broadcast()
    end
end

local function PrevStep(frame)
    if currentStep > 1 then
        ShowStep(frame, currentStep - 1)
    end
end

-- ── Frame construction ───────────────────────────────────────────────────────

local function BuildFrame()
    local TITLE_H = 28

    local frame = CreateFrame("Frame", "SchlingelSetupWizard", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_W, FRAME_H)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.07, 0.07, 0.07, 0.96)
    frame:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- Title bar
    local titleBg = frame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT",  frame, "TOPLEFT",  4, -4)
    titleBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    titleBg:SetHeight(TITLE_H)
    titleBg:SetColorTexture(0.12, 0.12, 0.12, 1)

    local titleIcon = frame:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("LEFT", titleBg, "LEFT", 6, 0)
    titleIcon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\SI_Transp_512_x_512_px.tga")

    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleIcon, "RIGHT", 4, 0)
    titleText:SetText("Schlingel Inc Setup")
    titleText:SetTextColor(1, 0.82, 0, 1)

    -- Progress dots (max 5) — small colored squares, Classic-font-safe
    frame.dots = {}
    local dotContainer = CreateFrame("Frame", nil, frame)
    dotContainer:SetSize(DOT_SPACING * 5, DOT_SIZE)  -- resized dynamically in UpdateProgress
    dotContainer:SetPoint("TOP", frame, "TOP", 0, -(TITLE_H + 14))
    frame.dotContainer = dotContainer
    for i = 1, 5 do
        local dot = dotContainer:CreateTexture(nil, "OVERLAY")
        dot:SetSize(DOT_SIZE, DOT_SIZE)
        dot:SetPoint("LEFT", dotContainer, "LEFT", (i - 1) * DOT_SPACING, 0)
        dot:SetColorTexture(0.3, 0.3, 0.3, 1)
        frame.dots[i] = dot
    end

    -- Step label
    frame.stepLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.stepLabel:SetPoint("TOP", dotContainer, "BOTTOM", 0, -4)
    frame.stepLabel:SetTextColor(0.7, 0.7, 0.7, 1)

    -- Divider below header
    local divTop = frame:CreateTexture(nil, "ARTWORK")
    divTop:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    divTop:SetSize(FRAME_W - 40, 1)
    divTop:SetPoint("TOP", frame.stepLabel, "BOTTOM", 0, -8)

    -- Content anchor: invisible Frame sitting just below the header divider.
    -- Step renderers anchor their widgets to this frame's BOTTOMLEFT/TOPLEFT.
    -- Using a real Frame (not a Texture) ensures anchoring works in Classic.
    local contentAnchor = CreateFrame("Frame", nil, frame)
    contentAnchor:SetSize(FRAME_W - 40, 1)
    contentAnchor:SetPoint("TOPLEFT", divTop, "BOTTOMLEFT", 0, 0)
    frame.contentAnchor = contentAnchor

    -- Footer divider
    local divBot = frame:CreateTexture(nil, "ARTWORK")
    divBot:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    divBot:SetSize(FRAME_W - 40, 1)
    divBot:SetPoint("BOTTOM", frame, "BOTTOM", 0, 52)

    -- Footer buttons: Back (left) and Weiter/Fertig (right) — no skip button
    frame.backBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.backBtn:SetSize(90, 26)
    frame.backBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 16)
    frame.backBtn:SetText("< Zurück")
    frame.backBtn:SetScript("OnClick", function() PrevStep(frame) end)

    frame.nextBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.nextBtn:SetSize(90, 26)
    frame.nextBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 16)
    frame.nextBtn:SetText("Weiter >")
    frame.nextBtn:SetScript("OnClick", function() NextStep(frame) end)

    return frame
end

-- ── Step renderers ────────────────────────────────────────────────────────────

-- Step: Discord Handle
local function RenderDiscord(frame)
    local f = frame.contentAnchor

    local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -20)
    lbl:SetWidth(FRAME_W - 40)
    lbl:SetJustifyH("CENTER")
    lbl:SetText("Gib deinen Discord Handle ein.\nEr wird mit deinem Profil gespeichert.")
    TrackChild(frame, lbl)

    local eb = CreateFrame("EditBox", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    eb:SetSize(FRAME_W - 140, 28)
    eb:SetPoint("TOP", lbl, "BOTTOM", 0, -14)
    eb:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
    eb:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    eb:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    eb:SetFontObject("GameFontHighlight")
    eb:SetTextInsets(8, 8, 0, 0)
    eb:SetAutoFocus(true)
    eb:SetMaxLetters(50)
    eb:SetText(DiscordHandle or "")
    eb:SetScript("OnEnterPressed", function() NextStep(frame) end)
    TrackChild(frame, eb)

    frame._discordEditBox = eb
end

local function OnNextDiscord(frame)
    local eb = frame._discordEditBox
    if not eb then return true end
    local handle = eb:GetText():match("^%s*(.-)%s*$")
    if handle == "" then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING ..
            "Bitte einen Discord Handle eingeben.|r")
        return false
    end
    DiscordHandle = handle
    return true
end

-- Step: Pronouns
local function RenderPronouns(frame)
    local f = frame.contentAnchor

    local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -20)
    lbl:SetWidth(FRAME_W - 40)
    lbl:SetJustifyH("CENTER")
    lbl:SetText("Möchtest du bevorzugte Pronomen angeben?\nz.B. er/ihm, sie/ihr, they/them")
    TrackChild(frame, lbl)

    local eb = CreateFrame("EditBox", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    eb:SetSize(FRAME_W - 140, 28)
    eb:SetPoint("TOP", lbl, "BOTTOM", 0, -14)
    eb:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
    eb:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    eb:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    eb:SetFontObject("GameFontHighlight")
    eb:SetTextInsets(8, 8, 0, 0)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(30)
    eb:SetText(Pronouns or "")
    eb:SetScript("OnEnterPressed", function() NextStep(frame) end)
    TrackChild(frame, eb)

    frame._pronounsEditBox = eb
end

local function OnNextPronouns(frame)
    local eb = frame._pronounsEditBox
    if eb then
        local val = eb:GetText():match("^%s*(.-)%s*$")
        -- Store empty string (not nil) so this step is not shown again on next login
        Pronouns = val
    end
    return true
end

-- Step: Role
local function RenderRole(frame)
    local f = frame.contentAnchor

    local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -24)
    lbl:SetWidth(FRAME_W - 40)
    lbl:SetJustifyH("CENTER")
    lbl:SetText("Welche Rollen spielst du? (Mehrfachauswahl möglich)")
    TrackChild(frame, lbl)

    local roles = SchlingelInc.Constants.ROLES
    local btnW   = 90
    local totalW = btnW * #roles + 10 * (#roles - 1)
    local startX = -(totalW / 2) + btnW / 2

    -- Load existing selections from saved profile (split "/" delimited string)
    frame._selectedRoles = {}
    local savedRole = SchlingelOwnProfile and SchlingelOwnProfile.role or ""
    for part in savedRole:gmatch("[^/]+") do
        frame._selectedRoles[part] = true
    end
    frame._roleBtns = {}

    local function RefreshRoleButtons()
        for _, entry in ipairs(frame._roleBtns) do
            if frame._selectedRoles[entry.name] then
                entry.btn:SetNormalFontObject(GameFontHighlight)
            else
                entry.btn:SetNormalFontObject(GameFontNormal)
            end
        end
    end

    for i, roleName in ipairs(roles) do
        local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        btn:SetSize(btnW, 30)
        btn:SetPoint("TOP", lbl, "BOTTOM", startX + (i - 1) * (btnW + 10), -20)
        btn:SetText(roleName)
        TrackChild(frame, btn)
        table.insert(frame._roleBtns, { name = roleName, btn = btn })

        btn:SetScript("OnClick", function()
            if frame._selectedRoles[roleName] then
                frame._selectedRoles[roleName] = nil
            else
                frame._selectedRoles[roleName] = true
            end
            RefreshRoleButtons()
        end)
    end

    RefreshRoleButtons()
end

local function OnNextRole(frame)
    SchlingelOwnProfile = SchlingelOwnProfile or {}
    -- Build ordered list (maintain ROLES order for consistent display)
    local selected = {}
    for _, roleName in ipairs(SchlingelInc.Constants.ROLES) do
        if frame._selectedRoles[roleName] then
            table.insert(selected, roleName)
        end
    end
    SchlingelOwnProfile.role = #selected > 0 and table.concat(selected, "/") or nil
    return true
end

-- Step: Professions
local function RenderProfessions(frame)
    local f = frame.contentAnchor

    local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -16)
    lbl:SetWidth(FRAME_W - 40)
    lbl:SetJustifyH("CENTER")
    lbl:SetText("Deine Berufe (erkannt oder manuell eingeben):")
    TrackChild(frame, lbl)

    local detected = SchlingelInc.GuildProfiles:DetectProfessions()

    frame._profFields = {}

    -- Columns centered: 225px name + 15px gap + 100px skill = 340px block, centered in 420px
    local NAME_X  = 40
    local SKILL_X = 280

    for slot = 1, 2 do
        local d = detected[slot]
        local yOff = -20 - (slot - 1) * 68

        -- "Beruf N:" label above name field
        local nameLbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameLbl:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", NAME_X, yOff)
        nameLbl:SetText("Beruf " .. slot .. ":")
        nameLbl:SetTextColor(0.8, 0.8, 0.8, 1)
        TrackChild(frame, nameLbl)

        local skillLbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        skillLbl:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", SKILL_X, yOff)
        skillLbl:SetText("Skill:")
        skillLbl:SetTextColor(0.8, 0.8, 0.8, 1)
        TrackChild(frame, skillLbl)

        -- Name EditBox (below nameLbl)
        local nameEb = CreateFrame("EditBox", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
        nameEb:SetSize(225, 24)
        nameEb:SetPoint("TOPLEFT", nameLbl, "BOTTOMLEFT", 0, -4)
        nameEb:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
        nameEb:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        nameEb:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        nameEb:SetFontObject("GameFontHighlight")
        nameEb:SetTextInsets(6, 6, 0, 0)
        nameEb:SetAutoFocus(false)
        nameEb:SetMaxLetters(40)
        nameEb:SetText(d and d.name or
            (SchlingelOwnProfile and SchlingelOwnProfile["prof"..slot] or ""))
        TrackChild(frame, nameEb)

        -- Skill EditBox (below skillLbl)
        local skillEb = CreateFrame("EditBox", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
        skillEb:SetSize(100, 24)
        skillEb:SetPoint("TOPLEFT", skillLbl, "BOTTOMLEFT", 0, -4)
        skillEb:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
        skillEb:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        skillEb:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        skillEb:SetFontObject("GameFontHighlight")
        skillEb:SetTextInsets(6, 6, 0, 0)
        skillEb:SetAutoFocus(false)
        skillEb:SetMaxLetters(7)
        if d then
            skillEb:SetText(d.rank .. "/" .. d.maxRank)
        else
            local cached = SchlingelOwnProfile and SchlingelOwnProfile["prof"..slot.."rank"]
            skillEb:SetText(cached and tostring(cached) or "")
        end
        TrackChild(frame, skillEb)

        frame._profFields[slot] = { nameEb = nameEb, skillEb = skillEb }
    end
end

local function OnNextProfessions(frame)
    SchlingelOwnProfile = SchlingelOwnProfile or {}
    for slot = 1, 2 do
        local fields = frame._profFields and frame._profFields[slot]
        if fields then
            local name = fields.nameEb:GetText():match("^%s*(.-)%s*$")
            local skillRaw = fields.skillEb:GetText():match("^%s*(.-)%s*$")
            -- skill field may be "225/300" or just "225"
            local rank = tonumber(skillRaw:match("^(%d+)")) or nil

            SchlingelOwnProfile["prof"..slot]         = (name ~= "") and name or nil
            SchlingelOwnProfile["prof"..slot.."rank"] = rank
        end
    end
    return true
end

-- Step: Guild join (only shown when not in guild)
local function RenderGuildJoin(frame)
    local f = frame.contentAnchor

    local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -24)
    lbl:SetWidth(FRAME_W - 40)
    lbl:SetJustifyH("CENTER")
    lbl:SetText("Du bist noch nicht in der Gilde!\nSende eine Beitrittsanfrage an unsere Offiziere.")
    TrackChild(frame, lbl)

    local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btn:SetSize(200, 28)
    btn:SetPoint("TOP", lbl, "BOTTOM", 0, -16)
    btn:SetText("Beitrittsanfrage senden")
    btn:SetScript("OnClick", function()
        SchlingelInc.GuildRecruitment:SendGuildRequest()
    end)
    TrackChild(frame, btn)
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Build the step list based on current player state.
-- forceAll = true (from /schlingelsetup): include optional steps like Pronouns/Professions.
-- forceAll = false (login auto-trigger): only mandatory incomplete steps.
function SchlingelInc:BuildWizardSteps(forceAll)
    steps = {}

    if forceAll or not DiscordHandle or DiscordHandle == "" then
        table.insert(steps, {
            id     = "discord",
            render = RenderDiscord,
            onNext = OnNextDiscord,
            frameH = 250,
        })
    end

    -- Pronouns: auto-show only if never seen (nil). forceAll always includes it.
    if forceAll or Pronouns == nil then
        table.insert(steps, {
            id     = "pronouns",
            render = RenderPronouns,
            onNext = OnNextPronouns,
            frameH = 250,
        })
    end

    if forceAll or not SchlingelOwnProfile or not SchlingelOwnProfile.role then
        table.insert(steps, {
            id     = "role",
            render = RenderRole,
            onNext = OnNextRole,
            frameH = 240,
        })
    end

    if forceAll or not SchlingelOwnProfile or not SchlingelOwnProfile.prof1 then
        table.insert(steps, {
            id     = "professions",
            render = RenderProfessions,
            onNext = OnNextProfessions,
            frameH = 315,
        })
    end

    if not IsInGuild() then
        table.insert(steps, {
            id     = "guild",
            render = RenderGuildJoin,
            onNext = nil,
            frameH = 255,
        })
    end
end

function SchlingelInc:IsProfileComplete()
    if not DiscordHandle or DiscordHandle == "" then return false end
    if Pronouns == nil then return false end
    if not SchlingelOwnProfile or not SchlingelOwnProfile.role then return false end
    if not SchlingelOwnProfile or not SchlingelOwnProfile.prof1 then return false end
    return true
end

function SchlingelInc:ShowSetupWizard(forceAll)
    if not forceAll and WizardFrame and WizardFrame:IsShown() then return end
    SchlingelInc:BuildWizardSteps(forceAll)
    if #steps == 0 then return end

    WizardFrame = WizardFrame or BuildFrame()
    currentStep = 1
    ShowStep(WizardFrame, 1)
    WizardFrame:Show()
end

-- Called from Main.lua on login (after guild cache is ready).
function SchlingelInc:InitializeSetupWizard()
    SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
        function(event, isLogin, isReload)
            if isLogin == false and isReload == false then return end
            C_Timer.After(6, function()
                -- First: migrate old note data if present
                SchlingelInc:MigrateFromGuildNoteIfNeeded()
                -- Then show wizard if anything is needed
                C_Timer.After(0.5, function()
                    SchlingelInc:ShowSetupWizard(false)
                end)
            end)
        end, 0, "SetupWizardInit")

    -- Slash command to re-open wizard with all steps (including optional ones)
    SLASH_SETUPWIZARD1 = '/schlingelsetup'
    SlashCmdList["SETUPWIZARD"] = function()
        SchlingelInc:ShowSetupWizard(true)
    end
end
