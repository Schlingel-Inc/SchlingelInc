-- SetupWizard.lua
-- Unified first-login setup wizard.
-- Steps are built dynamically: only steps that are actually needed are shown.

local WizardFrame
local steps       = {}   -- array of {id, render, onNext} tables
local currentStep = 1

-- ── Helpers ──────────────────────────────────────────────────────────────────

local FRAME_W, FRAME_H = 460, 420
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
    local frame = CreateFrame("Frame", "SchlingelSetupWizard", UIParent,
        BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(FRAME_W, FRAME_H)
    frame:SetPoint("CENTER")
    frame:SetBackdrop(SchlingelInc.Constants.BACKDROP)
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.97)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- Logo
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\SI_Transp_512_x_512_px.tga")
    icon:SetSize(64, 64)
    icon:SetPoint("TOP", frame, "TOP", 0, -16)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", icon, "BOTTOM", 0, -8)
    title:SetText("Schlingel Inc Setup")
    title:SetTextColor(1, 0.82, 0, 1)

    -- Progress dots (max 5) — small colored squares, Classic-font-safe
    frame.dots = {}
    local dotContainer = CreateFrame("Frame", nil, frame)
    dotContainer:SetSize(DOT_SPACING * 5, DOT_SIZE)  -- resized dynamically in UpdateProgress
    dotContainer:SetPoint("TOP", title, "BOTTOM", 0, -12)
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
    divTop:SetColorTexture(0.3, 0.3, 0.3, 0.8)
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
    divBot:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    divBot:SetSize(FRAME_W - 40, 1)
    divBot:SetPoint("BOTTOM", frame, "BOTTOM", 0, 52)

    -- Footer buttons: Back (left) and Weiter/Fertig (right) — no skip button
    frame.backBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.backBtn:SetSize(90, 26)
    frame.backBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 16)
    frame.backBtn:SetText("< Zurueck")
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
    lbl:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 20, -20)
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
    lbl:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 20, -20)
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
    lbl:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 20, -24)
    lbl:SetWidth(FRAME_W - 40)
    lbl:SetJustifyH("CENTER")
    lbl:SetText("Welche Rolle spielst du hauptsächlich?")
    TrackChild(frame, lbl)

    local roles = SchlingelInc.Constants.ROLES
    local btnW   = 90
    local totalW = btnW * #roles + 10 * (#roles - 1)
    local startX = -(totalW / 2) + btnW / 2

    frame._selectedRole = SchlingelOwnProfile and SchlingelOwnProfile.role or nil
    frame._roleBtns = {}

    local function RefreshRoleButtons()
        for _, entry in ipairs(frame._roleBtns) do
            if entry.name == frame._selectedRole then
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
            frame._selectedRole = roleName
            RefreshRoleButtons()
        end)
    end

    RefreshRoleButtons()
end

local function OnNextRole(frame)
    if not frame._selectedRole then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING ..
            "Bitte eine Rolle auswählen.|r")
        return false
    end
    SchlingelOwnProfile = SchlingelOwnProfile or {}
    SchlingelOwnProfile.role = frame._selectedRole
    return true
end

-- Step: Professions
local function RenderProfessions(frame)
    local f = frame.contentAnchor

    local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 20, -16)
    lbl:SetWidth(FRAME_W - 40)
    lbl:SetJustifyH("CENTER")
    lbl:SetText("Deine Berufe (erkannt oder manuell eingeben):")
    TrackChild(frame, lbl)

    local detected = SchlingelInc.GuildProfiles:DetectProfessions()

    frame._profFields = {}

    -- Column offsets: name col at x=0, skill col at x=240
    local SKILL_X = 240

    for slot = 1, 2 do
        local d = detected[slot]
        local yOff = -20 - (slot - 1) * 68

        -- "Beruf N:" label above name field
        local nameLbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameLbl:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, yOff)
        nameLbl:SetText("Beruf " .. slot .. ":")
        nameLbl:SetTextColor(0.8, 0.8, 0.8, 1)
        TrackChild(frame, nameLbl)

        -- "Skill:" label above skill field, same row as nameLbl
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
    lbl:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 20, -24)
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
        })
    end

    -- Pronouns: auto-show only if never seen (nil). forceAll always includes it.
    if forceAll or Pronouns == nil then
        table.insert(steps, {
            id     = "pronouns",
            render = RenderPronouns,
            onNext = OnNextPronouns,
        })
    end

    if forceAll or not SchlingelOwnProfile or not SchlingelOwnProfile.role then
        table.insert(steps, {
            id     = "role",
            render = RenderRole,
            onNext = OnNextRole,
        })
    end

    if forceAll or not SchlingelOwnProfile or not SchlingelOwnProfile.prof1 then
        table.insert(steps, {
            id     = "professions",
            render = RenderProfessions,
            onNext = OnNextProfessions,
        })
    end

    if forceAll and not IsInGuild() then
        table.insert(steps, {
            id     = "guild",
            render = RenderGuildJoin,
            onNext = nil,
        })
    end
end

function SchlingelInc:ShowSetupWizard(forceAll)
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
        function()
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
