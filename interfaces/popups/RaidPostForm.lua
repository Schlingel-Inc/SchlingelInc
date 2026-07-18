-- interfaces/popups/RaidPostForm.lua
-- Popup form to post a new raid entry, or edit one the local player already posted.

SchlingelInc.Popup = SchlingelInc.Popup or {}

local FC = SchlingelInc.Constants.FORM_COLORS

local FORM_W  = 460
local INNER_W = FORM_W - 32

local function BuildForm()
    local f = SchlingelInc.Shared.CreateStandardFrame({
        name          = "SchlingelRaidPostForm",
        width         = FORM_W,
        height        = 380,
        strata        = "DIALOG",
        positionKey   = "raidpostform_position",
        defaultPoint  = "CENTER",
        defaultX      = 0,
        defaultY      = 80,
        registerEscape = true,
        closeButton   = true,
    })

    local titleFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFs:SetPoint("TOP", f, "TOP", 0, -16)
    titleFs:SetTextColor(unpack(FC.TITLE))
    f.titleFs = titleFs

    -- ── Titel ────────────────────────────────────────────────────────────────
    local titleLbl = SchlingelInc.Shared.CreateLabel(f, "Titel:")
    titleLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -48)

    local titleEB = SchlingelInc.Shared.CreateEditBox(f, INNER_W, 60, false)
    titleEB:SetPoint("TOPLEFT", titleLbl, "BOTTOMLEFT", 0, -4)
    f.titleEB = titleEB

    -- ── Instanz (dropdown) ──────────────────────────────────────────────────
    local instLbl = SchlingelInc.Shared.CreateLabel(f, "Instanz:")
    instLbl:SetPoint("TOPLEFT", titleEB, "BOTTOMLEFT", 0, -10)

    local instBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    instBtn:SetSize(INNER_W, 22)
    instBtn:SetPoint("TOPLEFT", instLbl, "BOTTOMLEFT", 0, -4)
    instBtn:SetText("Auswählen...")
    instBtn:GetFontString():SetWordWrap(false)
    instBtn:SetNormalFontObject("GameFontHighlightSmall")
    instBtn:SetHighlightFontObject("GameFontHighlightSmall")
    f.instBtn = instBtn

    local instList = CreateFrame("Frame", "SchlingelRaidPostFormInstList", UIParent, "BackdropTemplate")
    instList:SetSize(INNER_W, 10)
    instList:SetFrameStrata("TOOLTIP")
    instList:SetBackdrop(SchlingelInc.Constants.DROPDOWNBACKDROP)
    instList:SetBackdropColor(unpack(FC.FORM_BG))
    instList:SetBackdropBorderColor(unpack(FC.FORM_BORDER))
    instList:SetPoint("TOPLEFT", instBtn, "BOTTOMLEFT", 0, -2)
    instList:Hide()
    f.instList = instList
    SchlingelInc:RegisterOutsideClickClose(instList, f)

    local ITEM_H = 18
    local yOff   = -4
    for _, name in ipairs(SchlingelInc.Constants.RAID_INSTANCES) do
        local btn = CreateFrame("Button", nil, instList)
        btn:SetSize(INNER_W - 8, ITEM_H)
        btn:SetPoint("TOPLEFT", instList, "TOPLEFT", 4, yOff)
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints()
        lbl:SetJustifyH("LEFT")
        lbl:SetWordWrap(false)
        lbl:SetText(name)
        lbl:SetTextColor(unpack(FC.LIST_ITEM_TEXT))
        btn:SetScript("OnClick", function()
            f.selectedInstance = name
            instBtn:SetText(name)
            instList:Hide()
        end)
        btn:SetScript("OnEnter", function() lbl:SetTextColor(unpack(FC.HOVER)) end)
        btn:SetScript("OnLeave", function() lbl:SetTextColor(unpack(FC.LIST_ITEM_TEXT)) end)
        yOff = yOff - ITEM_H - 2
    end
    instList:SetHeight(math.abs(yOff) + 4)

    instBtn:SetScript("OnClick", function()
        instList:SetShown(not instList:IsShown())
    end)

    -- ── Datum / Uhrzeit ─────────────────────────────────────────────────────
    local dateLbl = SchlingelInc.Shared.CreateLabel(f, "Datum (TT.MM):")
    dateLbl:SetPoint("TOPLEFT", instBtn, "BOTTOMLEFT", 0, -10)

    local dayEB = SchlingelInc.Shared.CreateEditBox(f, 40, 2, true)
    dayEB:SetPoint("TOPLEFT", dateLbl, "BOTTOMLEFT", 0, -4)
    f.dayEB = dayEB

    local dotFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dotFs:SetPoint("LEFT", dayEB, "RIGHT", 4, 0)
    dotFs:SetText(".")

    local monthEB = SchlingelInc.Shared.CreateEditBox(f, 40, 2, true)
    monthEB:SetPoint("LEFT", dotFs, "RIGHT", 4, 0)
    f.monthEB = monthEB

    local timeLbl = SchlingelInc.Shared.CreateLabel(f, "Uhrzeit (HH:MM):")
    timeLbl:SetPoint("TOPLEFT", dateLbl, "TOPLEFT", INNER_W / 2 + 10, 0)

    local hourEB = SchlingelInc.Shared.CreateEditBox(f, 40, 2, true)
    hourEB:SetPoint("TOPLEFT", dayEB, "TOPLEFT", INNER_W / 2 + 10, 0)
    f.hourEB = hourEB

    local colonFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colonFs:SetPoint("LEFT", hourEB, "RIGHT", 4, 0)
    colonFs:SetText(":")

    local minuteEB = SchlingelInc.Shared.CreateEditBox(f, 40, 2, true)
    minuteEB:SetPoint("LEFT", colonFs, "RIGHT", 4, 0)
    f.minuteEB = minuteEB

    -- ── Notiz ────────────────────────────────────────────────────────────────
    local noteLbl = SchlingelInc.Shared.CreateLabel(f, "Notiz (optional):")
    noteLbl:SetPoint("TOPLEFT", dayEB, "BOTTOMLEFT", 0, -10)

    local noteEB = SchlingelInc.Shared.CreateEditBox(f, INNER_W, 80, false)
    noteEB:SetPoint("TOPLEFT", noteLbl, "BOTTOMLEFT", 0, -4)
    f.noteEB = noteEB

    -- ── Fehler / Submit ─────────────────────────────────────────────────────
    local errorFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    errorFs:SetPoint("TOPLEFT", noteEB, "BOTTOMLEFT", 0, -12)
    errorFs:SetWidth(INNER_W)
    errorFs:SetJustifyH("LEFT")
    errorFs:SetTextColor(unpack(FC.ERROR))
    f.errorFs = errorFs

    local submitBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    submitBtn:SetSize(120, 22)
    submitBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
    f.submitBtn = submitBtn

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(90, 22)
    cancelBtn:SetPoint("RIGHT", submitBtn, "LEFT", -8, 0)
    cancelBtn:SetText("Abbrechen")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    submitBtn:SetScript("OnClick", function()
        errorFs:SetText("")

        local title = titleEB:GetText()
        local instance = f.selectedInstance
        if not instance then
            errorFs:SetText("Bitte eine Instanz auswählen.")
            return
        end

        local day    = tonumber(dayEB:GetText())
        local month  = tonumber(monthEB:GetText())
        local hour   = tonumber(hourEB:GetText()) or 0
        local minute = tonumber(minuteEB:GetText()) or 0
        if not day or not month or day < 1 or day > 31 or month < 1 or month > 12
           or hour < 0 or hour > 23 or minute < 0 or minute > 59 then
            errorFs:SetText("Bitte ein gültiges Datum/Uhrzeit angeben.")
            return
        end

        local now = date("*t")
        local timestamp = time({
            year = now.year, month = month, day = day,
            hour = hour, min = minute, sec = 0,
        })

        local note = noteEB:GetText()
        local isNewPost = not f.editId
        local ok, err
        if f.editId then
            ok, err = SchlingelInc.Raid:Edit(f.editId, title, instance, timestamp, note)
        else
            ok, err = SchlingelInc.Raid:Post(title, instance, timestamp, note)
        end

        if not ok then
            errorFs:SetText(err or "Unbekannter Fehler.")
            return
        end

        f:Hide()
        if SchlingelInc.GuildPanel and SchlingelInc.GuildPanel.RefreshRaid then
            SchlingelInc.GuildPanel:RefreshRaid()
        end

        if isNewPost then
            local newEntry = SchlingelInc.Raid:GetEntry(ok)
            if newEntry then
                SchlingelInc.Popup:ShowRaidSignup(newEntry, nil)
            end
        end
    end)

    return f
end

function SchlingelInc.Popup:ShowRaidForm(existingEntry)
    if not SchlingelInc.Popup.raidForm then
        SchlingelInc.Popup.raidForm = BuildForm()
    end
    local f = SchlingelInc.Popup.raidForm

    f.errorFs:SetText("")
    f.instList:Hide()

    if existingEntry then
        f.editId = existingEntry.id
        f.titleFs:SetText("Raid bearbeiten")
        f.submitBtn:SetText("Speichern")
        f.titleEB:SetText(existingEntry.title)
        f.selectedInstance = existingEntry.instance
        f.instBtn:SetText(existingEntry.instance)
        local t = date("*t", existingEntry.timestamp)
        f.dayEB:SetText(string.format("%02d", t.day))
        f.monthEB:SetText(string.format("%02d", t.month))
        f.hourEB:SetText(string.format("%02d", t.hour))
        f.minuteEB:SetText(string.format("%02d", t.min))
        f.noteEB:SetText(existingEntry.note or "")
    else
        f.editId = nil
        f.titleFs:SetText("Raid posten")
        f.submitBtn:SetText("Posten")
        f.titleEB:SetText("")
        f.selectedInstance = nil
        f.instBtn:SetText("Auswählen...")
        f.dayEB:SetText("")
        f.monthEB:SetText("")
        f.hourEB:SetText("")
        f.minuteEB:SetText("")
        f.noteEB:SetText("")
    end

    f:Show()
end
