-- Deathlog.lua

SchlingelInc.Deathlog = SchlingelInc.Deathlog or {}
SchlingelInc.DeathLogData = {}

local FONT_NORMAL = "GameFontNormal"
local FONT_SMALL  = "GameFontNormalSmall"

local FRAME_WIDTH   = 280
local FRAME_HEIGHT  = 150
local HEADER_HEIGHT = 30
local ROW_HEIGHT    = 14
local LEFT_PADDING  = 10
local RIGHT_PADDING = 10

local COLUMN_WEIGHTS = { 0.40, 0.40, 0.20 }
local COLUMN_LABELS  = { "Name", "Klasse", "Level" }

local localizedToToken = {}
for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE)   do localizedToToken[name] = token end
for token, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do localizedToToken[name] = token end

function SchlingelInc.Deathlog:AddEntry(deathEntry)
    table.insert(SchlingelInc.DeathLogData, 1, deathEntry)
    SchlingelInc:UpdateMiniDeathLog()
end

function SchlingelInc:CreateMiniDeathLog()
    if self.MiniDeathLogFrame then return end

    local frame = CreateFrame("Frame", "MiniDeathLog", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    SchlingelInc:RestoreFramePosition(frame, "deathlog_position", "BOTTOMLEFT", 40, 60)
    frame:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
    frame:SetBackdropColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BG))
    frame:SetBackdropBorderColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BORDER))
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SchlingelInc:SaveFramePosition(self, "deathlog_position")
    end)
    frame:SetFrameStrata("MEDIUM")

    -- Header bar
    local headerBg = frame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetPoint("TOPLEFT",  frame, "TOPLEFT",  4, -4)
    headerBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    headerBg:SetHeight(22)
    headerBg:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BG))

    local titleIcon = frame:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(16, 16)
    titleIcon:SetPoint("LEFT", headerBg, "LEFT", 5, 0)
    titleIcon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\SI_Transp_512_x_512_px.tga")

    local title = frame:CreateFontString(nil, "OVERLAY", FONT_NORMAL)
    title:SetPoint("LEFT", titleIcon, "RIGHT", 4, 0)
    title:SetText("Letzte Tode")
    title:SetTextColor(1, 0.82, 0, 1)

    -- Column headers and fixed layout
    local availableWidth = FRAME_WIDTH - LEFT_PADDING - RIGHT_PADDING
    local columnWidths = {
        math.floor(availableWidth * COLUMN_WEIGHTS[1]),
        math.floor(availableWidth * COLUMN_WEIGHTS[2]),
        math.floor(availableWidth * COLUMN_WEIGHTS[3]),
    }

    local xOffset = LEFT_PADDING
    for i, text in ipairs(COLUMN_LABELS) do
        local header = frame:CreateFontString(nil, "OVERLAY", FONT_NORMAL)
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, -HEADER_HEIGHT)
        header:SetWidth(columnWidths[i])
        header:SetText(text)
        header:SetTextColor(1, 0.82, 0, 1)
        header:SetJustifyH(i == 3 and "CENTER" or "LEFT")
        xOffset = xOffset + columnWidths[i] + 5
    end

    -- Row pool — fixed count based on frame size
    local numRows = math.max(1, math.floor((FRAME_HEIGHT - HEADER_HEIGHT - 30) / ROW_HEIGHT))
    frame.rows          = {}
    frame.rowFrames     = {}
    frame.rowHighlights = {}

    for r = 1, numRows do
        local yOffset = -HEADER_HEIGHT - 20 - ((r - 1) * ROW_HEIGHT)

        local highlight = frame:CreateTexture(nil, "BACKGROUND")
        highlight:SetPoint("TOPLEFT",  frame, "TOPLEFT",  10, yOffset)
        highlight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, yOffset)
        highlight:SetHeight(ROW_HEIGHT)
        highlight:SetColorTexture(0.3, 0.3, 0.3, 0.3)
        highlight:Hide()
        table.insert(frame.rowHighlights, highlight)

        local rowFrame = CreateFrame("Frame", nil, frame)
        rowFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, yOffset)
        rowFrame:SetSize(FRAME_WIDTH - 20, ROW_HEIGHT)
        rowFrame:EnableMouse(true)
        table.insert(frame.rowFrames, rowFrame)

        local row = {}
        local rx = LEFT_PADDING
        for c = 1, #COLUMN_LABELS do
            local cell = frame:CreateFontString(nil, "OVERLAY", FONT_SMALL)
            cell:SetPoint("TOPLEFT", frame, "TOPLEFT", rx, yOffset - 2)
            cell:SetWidth(columnWidths[c])
            cell:SetJustifyV("MIDDLE")
            cell:SetJustifyH(c == 3 and "CENTER" or "LEFT")
            table.insert(row, cell)
            rx = rx + columnWidths[c] + 5
        end
        table.insert(frame.rows, row)
    end

    self.MiniDeathLogFrame = frame
    frame:Hide()
end

function SchlingelInc:UpdateMiniDeathLog()
    if not self.MiniDeathLogFrame then self:CreateMiniDeathLog() end
    local frame = self.MiniDeathLogFrame
    local data  = self.DeathLogData or {}

    for i, row in ipairs(frame.rows) do
        local rowFrame = frame.rowFrames[i]
        local highlight = frame.rowHighlights[i]
        local entry = data[i]

        if entry then
            local classToken = localizedToToken[entry.class]
            local color      = classToken and RAID_CLASS_COLORS[classToken]
            local safeName   = SchlingelInc:SanitizeText(entry.name)  or "?"
            local safeClass  = SchlingelInc:SanitizeText(entry.class) or "?"
            local safeZone   = SchlingelInc:SanitizeText(entry.zone)

            row[1]:SetText(safeName)
            row[2]:SetText(color
                and string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, safeClass)
                or safeClass)
            row[3]:SetText(tostring(entry.level or "?"))

            local shade = (i % 2 == 0) and 0.9 or 0.8
            for _, cell in ipairs(row) do cell:SetTextColor(shade, shade, shade) end

            rowFrame:SetScript("OnEnter", function()
                highlight:Show()
                GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
                GameTooltip:ClearLines()
                if entry.discordHandle then
                    GameTooltip:AddDoubleLine("Discord:", SchlingelInc:SanitizeText(entry.discordHandle), 0.8, 0.8, 0.8, 0.45, 0.63, 0.82)
                end
                GameTooltip:AddDoubleLine("Klasse:", safeClass, 0.8, 0.8, 0.8, 1, 1, 1)
                GameTooltip:AddDoubleLine("Level:", tostring(entry.level or "?"), 0.8, 0.8, 0.8, 1, 1, 1)
                if safeZone then
                    GameTooltip:AddDoubleLine("Zone:", safeZone, 0.8, 0.8, 0.8, 1, 1, 1)
                end
                if entry.cause and entry.cause ~= "Unbekannt" then
                    GameTooltip:AddDoubleLine("Todesursache:", SchlingelInc:SanitizeText(entry.cause), 0.8, 0.8, 0.8, 1, 0.3, 0.3)
                end
                if entry.lastWords then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Letzte Worte:", 0.8, 0.8, 0.8)
                    GameTooltip:AddLine('"' .. SchlingelInc:SanitizeText(entry.lastWords) .. '"', 1, 0.85, 0.1, true)
                end
                GameTooltip:Show()
            end)
            rowFrame:SetScript("OnLeave", function()
                highlight:Hide()
                GameTooltip:Hide()
            end)
        else
            for _, cell in ipairs(row) do cell:SetText("") end
            rowFrame:SetScript("OnEnter", nil)
            rowFrame:SetScript("OnLeave", nil)
            highlight:Hide()
        end
    end
end

function SchlingelInc:ToggleDeathLogWindow()
    if not IsInGuild() then return end
    if not self.MiniDeathLogFrame then
        self:CreateMiniDeathLog()
        self:UpdateMiniDeathLog()
        self.MiniDeathLogFrame:Show()
    elseif self.MiniDeathLogFrame:IsShown() then
        self.MiniDeathLogFrame:Hide()
    else
        self:UpdateMiniDeathLog()
        self.MiniDeathLogFrame:Show()
    end
end
