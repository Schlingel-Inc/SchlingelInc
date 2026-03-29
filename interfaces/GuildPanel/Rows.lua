-- GuildPanel/Rows.lua
-- Row frame factory, tooltip display, and class color helper.

local GP = SchlingelInc.GuildPanel

local function ClassColor(token)
    local c = RAID_CLASS_COLORS and token and RAID_CLASS_COLORS[token]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

function GP.ShowMemberTooltip(anchor, entry)
    local r, g, b = ClassColor(entry.classToken)
    GameTooltip:SetOwner(anchor, "ANCHOR_LEFT", -10, -50)
    GameTooltip:ClearLines()

    -- Name colored by class
    GameTooltip:AddLine(entry.name, r, g, b)
    GameTooltip:AddDoubleLine("Klasse:",
        entry.classDisplay ~= "" and entry.classDisplay or "-",
        0.65, 0.65, 0.65, r, g, b)
    GameTooltip:AddDoubleLine("Rang:",
        entry.rank ~= "" and entry.rank or "-",
        0.65, 0.65, 0.65, 1, 1, 1)
    if entry.zone ~= "" then
        GameTooltip:AddDoubleLine("Zone:",
            SchlingelInc:SanitizeText(entry.zone),
            0.65, 0.65, 0.65, 1, 1, 1)
    end

    -- Guild note
    local safeNote = entry.note ~= "" and SchlingelInc:SanitizeText(entry.note) or nil
    if safeNote and safeNote ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Notiz:", safeNote, 0.65, 0.65, 0.65, 1, 0.9, 0.5, true)
    end

    -- Profile extras
    local hasProfile = entry.role ~= "" or entry.discord ~= "" or entry.prof1 or entry.prof2
    if hasProfile then
        GameTooltip:AddLine(" ")
        if entry.role ~= "" then
            GameTooltip:AddDoubleLine("Rolle:",   entry.role,    0.65, 0.65, 0.65, 1,    1,    1)
        end
        if entry.discord ~= "" then
            GameTooltip:AddDoubleLine("Discord:", entry.discord, 0.65, 0.65, 0.65, 0.55, 0.55, 0.9)
        end
        if entry.prof1 then
            GameTooltip:AddDoubleLine("Beruf 1:", entry.prof1, 0.65, 0.65, 0.65, 0.9, 0.75, 0.4)
        end
        if entry.prof2 then
            GameTooltip:AddDoubleLine("Beruf 2:", entry.prof2, 0.65, 0.65, 0.65, 0.9, 0.75, 0.4)
        end
    end

    -- Deaths: shown whenever we have data (including 0)
    if entry.deaths ~= nil then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Tode:", tostring(entry.deaths), 0.65, 0.65, 0.65, 1, 1, 1)
    end

    GameTooltip:Show()
end

function GP.CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(GP.TotalColWidth(), GP.ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index - 1) * GP.ROW_H)
    row:EnableMouse(true)
    row:SetFrameLevel(parent:GetFrameLevel() + 2)

    -- Alternating stripe
    if index % 2 == 0 then
        local stripe = row:CreateTexture(nil, "BACKGROUND")
        stripe:SetAllPoints()
        stripe:SetColorTexture(1, 1, 1, 0.04)
    end

    -- Hover highlight (gold tint, hidden by default)
    local hl = row:CreateTexture(nil, "BACKGROUND")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 0.82, 0, 0.08)
    hl:Hide()
    row.hl = hl

    -- Cell font strings
    row.cells = {}
    local xOff = 0
    for i, col in ipairs(GP.COLUMNS) do
        local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetWidth(col.width - 2)
        fs:SetHeight(GP.ROW_H)
        fs:SetPoint("LEFT", row, "LEFT", xOff + 2, 0)
        fs:SetJustifyH(i == 2 and "CENTER" or "LEFT")
        row.cells[i] = fs
        xOff = xOff + col.width
    end

    return row
end
