-- Deathlog.lua
-- Creates and manages the mini death log window with tooltips and resizing

local FONT_NORMAL = "GameFontNormal"
local FONT_SMALL = "GameFontNormalSmall"

-- Constants for dynamic layout
local MIN_WIDTH = 250
local MIN_HEIGHT = 120
local MAX_WIDTH = 500
local MAX_HEIGHT = 350
local HEADER_HEIGHT = 30
local ROW_HEIGHT = 14
local LEFT_PADDING = 10
local RIGHT_PADDING = 10

-- Calculate column widths dynamically based on frame width
local function CalculateColumnLayout(frameWidth)
    local availableWidth = frameWidth - LEFT_PADDING - RIGHT_PADDING
    -- Column proportions: Name=40%, Class=40%, Level=20%
    return {
        math.floor(availableWidth * 0.40),  -- Name
        math.floor(availableWidth * 0.40),  -- Class
        math.floor(availableWidth * 0.20)   -- Level
    }
end

-- Calculate how many rows can fit in the frame
local function CalculateMaxRows(frameHeight)
    local availableHeight = frameHeight - HEADER_HEIGHT - 30 -- 30 for bottom padding
    return math.max(1, math.floor(availableHeight / ROW_HEIGHT))
end

-- Function to update layout when frame is resized
local function UpdateDeathLogLayout(frame)
    if not frame.columnHeaders or not frame.rows then return end

    local frameWidth = frame:GetWidth()
    local frameHeight = frame:GetHeight()
    local columnWidths = CalculateColumnLayout(frameWidth)
    local maxRows = CalculateMaxRows(frameHeight)

    -- Update column headers
    local xOffset = LEFT_PADDING
    for i, header in ipairs(frame.columnHeaders) do
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, -HEADER_HEIGHT)
        header:SetWidth(columnWidths[i])
        if i == 3 then
            header:SetJustifyH("CENTER")
        else
            header:SetJustifyH("LEFT")
        end
        xOffset = xOffset + columnWidths[i] + 5
    end

    -- Update rows
    for i = 1, #frame.rows do
        local row = frame.rows[i]
        local rowFrame = frame.rowFrames[i]
        local highlight = frame.rowHighlights[i]
        local yOffset = -HEADER_HEIGHT - 20 - ((i - 1) * ROW_HEIGHT)

        if i <= maxRows then
            -- Update highlight and hover frame first
            highlight:ClearAllPoints()
            highlight:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, yOffset)
            highlight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, yOffset)

            -- Position cells (aligned with highlight)
            xOffset = LEFT_PADDING
            for j = 1, #row do
                row[j]:ClearAllPoints()
                row[j]:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, yOffset - 2)
                row[j]:SetWidth(columnWidths[j])
                if j == 3 then
                    row[j]:SetJustifyH("CENTER")
                else
                    row[j]:SetJustifyH("LEFT")
                end
                xOffset = xOffset + columnWidths[j] + 5
            end

            rowFrame:ClearAllPoints()
            rowFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, yOffset)
            rowFrame:SetSize(frameWidth - 20, ROW_HEIGHT)

            -- Show row elements
            for _, cell in ipairs(row) do cell:Show() end
            rowFrame:Show()
        else
            -- Hide rows that don't fit
            for _, cell in ipairs(row) do cell:Hide() end
            highlight:Hide()
            rowFrame:Hide()
        end
    end

    -- Refresh data display
    SchlingelInc:UpdateMiniDeathLog()
end

-- Creates the mini death log frame
function SchlingelInc:CreateMiniDeathLog()
    if self.MiniDeathLogFrame then return end

    local frame = CreateFrame("Frame", "MiniDeathLog", UIParent, "BackdropTemplate")

    -- Load saved size or use default
    local savedWidth = MIN_WIDTH
    local savedHeight = MIN_HEIGHT
    if SchlingelOptionsDB and SchlingelOptionsDB["deathlog_size"] then
        savedWidth = SchlingelOptionsDB["deathlog_size"].width or MIN_WIDTH
        savedHeight = SchlingelOptionsDB["deathlog_size"].height or MIN_HEIGHT
    end
    frame:SetSize(savedWidth, savedHeight)

    SchlingelInc:RestoreFramePosition(frame, "deathlog_position", "BOTTOMLEFT", 40, 60)

    frame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.07, 0.07, 0.07, 0.96)
    frame:SetBackdropBorderColor(1, 0.55, 0.73, 1)  -- Pink border matching addon theme
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SchlingelInc:SaveFramePosition(self, "deathlog_position")
    end)
    frame:SetFrameStrata("MEDIUM")
    frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)

    -- Smart resize grip - supports both vertical and diagonal resizing
    local resizeGrip = CreateFrame("Button", nil, frame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    local startMouseX, startMouseY

    resizeGrip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            -- Store initial positions
            startMouseX, startMouseY = GetCursorPosition()

            -- Start with both directions enabled
            frame:StartSizing("BOTTOMRIGHT")
            frame:SetScript("OnUpdate", function()
                local currentX, currentY = GetCursorPosition()
                local deltaX = math.abs(currentX - startMouseX)
                local deltaY = math.abs(currentY - startMouseY)

                -- If user is dragging mostly vertically, lock width
                if deltaY > deltaX * 2 then
                    frame:StopMovingOrSizing()
                    frame:StartSizing("BOTTOM")
                -- If user is dragging diagonally, allow both
                elseif deltaX > 10 or deltaY > 10 then
                    frame:StopMovingOrSizing()
                    frame:StartSizing("BOTTOMRIGHT")
                end
            end)
        end
    end)

    resizeGrip:SetScript("OnMouseUp", function()
        frame:SetScript("OnUpdate", nil)
        frame:StopMovingOrSizing()

        -- Save size
        SchlingelOptionsDB = SchlingelOptionsDB or {}
        SchlingelOptionsDB["deathlog_size"] = {
            width = frame:GetWidth(),
            height = frame:GetHeight()
        }
        -- Update layout
        UpdateDeathLogLayout(frame)
    end)

    -- Header section with title
    local headerBg = frame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
    headerBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    headerBg:SetHeight(22)
    headerBg:SetColorTexture(0.12, 0.12, 0.12, 1)

    local titleIcon = frame:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(16, 16)
    titleIcon:SetPoint("LEFT", headerBg, "LEFT", 5, 0)
    titleIcon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\SI_Transp_512_x_512_px.tga")

    local title = frame:CreateFontString(nil, "OVERLAY", FONT_NORMAL)
    title:SetPoint("LEFT", titleIcon, "RIGHT", 4, 0)
    title:SetText("Letzte Tode")
    title:SetTextColor(1, 0.82, 0, 1)

    local headers = { "Name", "Klasse", "Level" }

    -- Create column headers
    frame.columnHeaders = {}
    for _, text in ipairs(headers) do
        local header = frame:CreateFontString(nil, "OVERLAY", FONT_NORMAL)
        header:SetText(text)
        header:SetTextColor(1, 0.82, 0, 1)
        table.insert(frame.columnHeaders, header)
    end

    -- Create maximum possible rows (will be hidden if they don't fit)
    local maxPossibleRows = math.floor((MAX_HEIGHT - HEADER_HEIGHT - 30) / ROW_HEIGHT)
    frame.rows = {}
    frame.rowFrames = {}
    frame.rowHighlights = {}

    for _ = 1, maxPossibleRows do
        local row = {}

        -- Create highlight background for row
        local highlight = frame:CreateTexture(nil, "BACKGROUND")
        highlight:SetHeight(ROW_HEIGHT)
        highlight:SetColorTexture(0.3, 0.3, 0.3, 0.3)
        highlight:Hide()
        table.insert(frame.rowHighlights, highlight)

        -- Create invisible frame for hover detection
        local rowFrame = CreateFrame("Frame", nil, frame)
        rowFrame:EnableMouse(true)
        table.insert(frame.rowFrames, rowFrame)

        -- Create cells for this row
        for _ = 1, #headers do
            local cell = frame:CreateFontString(nil, "OVERLAY", FONT_SMALL)
            cell:SetText("")
            cell:SetJustifyV("MIDDLE")
            table.insert(row, cell)
        end
        table.insert(frame.rows, row)
    end

    -- Store reference
    self.MiniDeathLogFrame = frame

    -- Perform initial layout
    UpdateDeathLogLayout(frame)

    frame:Hide()
end

-- Updates the death log with current data
function SchlingelInc:UpdateMiniDeathLog()
    if not self.MiniDeathLogFrame then self:CreateMiniDeathLog() end
    local frame = self.MiniDeathLogFrame
    local data = self.DeathLogData or {}

    -- Calculate how many rows are currently visible
    local maxRows = CalculateMaxRows(frame:GetHeight())

    local localizedToToken = {}
    for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE) do localizedToToken[name] = token end
    for token, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do localizedToToken[name] = token end

    -- Only update visible rows
    for i = 1, maxRows do
        if i > #frame.rows then break end

        local row = frame.rows[i]
        local rowFrame = frame.rowFrames[i]
        local highlight = frame.rowHighlights[i]
        local entry = data[i]

        if entry and rowFrame:IsShown() then
            local classToken = localizedToToken[entry.class]
            local color = classToken and RAID_CLASS_COLORS[classToken]
            -- Sanitize text fields to prevent UI injection
            local safeName = SchlingelInc:SanitizeText(entry.name) or "?"
            local safeClass = SchlingelInc:SanitizeText(entry.class) or "?"
            local safeZone = SchlingelInc:SanitizeText(entry.zone)

            row[1]:SetText(safeName)
            row[2]:SetText(color and string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, safeClass) or safeClass)
            row[3]:SetText(entry.level or "?")

            -- Setup tooltip on hover
            rowFrame:SetScript("OnEnter", function()
                highlight:Show()
                GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
                GameTooltip:ClearLines()
                if entry.discordHandle then
                    local safeHandle = SchlingelInc:SanitizeText(entry.discordHandle)
                    GameTooltip:AddDoubleLine("Discord:", safeHandle, 0.8, 0.8, 0.8, 0.45, 0.63, 0.82)
                end
                GameTooltip:AddDoubleLine("Klasse:", safeClass, 0.8, 0.8, 0.8, 1, 1, 1)
                GameTooltip:AddDoubleLine("Level:", tostring(entry.level or "?"), 0.8, 0.8, 0.8, 1, 1, 1)
                if safeZone then
                    GameTooltip:AddDoubleLine("Zone:", safeZone, 0.8, 0.8, 0.8, 1, 1, 1)
                end
                if entry.cause then
                    local safeCause = SchlingelInc:SanitizeText(entry.cause)
                    GameTooltip:AddDoubleLine("Todesursache:", safeCause, 0.8, 0.8, 0.8, 1, 0.3, 0.3)
                end
                if entry.lastWords then
                    local safeLastWords = SchlingelInc:SanitizeText(entry.lastWords)
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Letzte Worte:", 0.8, 0.8, 0.8)
                    GameTooltip:AddLine('"' .. safeLastWords .. '"', 1, 0.85, 0.1, true)
                end
                GameTooltip:Show()
            end)
            rowFrame:SetScript("OnLeave", function()
                highlight:Hide()
                GameTooltip:Hide()
            end)

            for _, cell in ipairs(row) do
                if i % 2 == 0 then
                    cell:SetTextColor(0.9, 0.9, 0.9)
                else
                    cell:SetTextColor(0.8, 0.8, 0.8)
                end
            end
        elseif rowFrame:IsShown() then
            -- Clear rows that are visible but have no data
            rowFrame:SetScript("OnEnter", nil)
            rowFrame:SetScript("OnLeave", nil)
            highlight:Hide()
            for _, cell in ipairs(row) do cell:SetText("") end
        end
    end
end

-- Toggles the death log window visibility
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
