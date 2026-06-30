-- GuildPanel/Rows.lua
-- Row frame factory.

local GP = SchlingelInc.GuildPanel

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
