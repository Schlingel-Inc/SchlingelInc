-- interfaces/CollapsibleHeader.lua
-- Generic collapsible section-header widget (card-styled, optional progress bar),
-- used by list views that group entries into expandable sections.

SchlingelInc.UI = SchlingelInc.UI or {}

local HEADER_LABEL_H = 20
local HEADER_BAR_H   = 12
local HEADER_BAR_PAD = 4

function SchlingelInc.UI.NewCollapsedState(keys)
    local state = {}
    for _, key in ipairs(keys) do
        state[key] = true
    end
    return state
end

-- Flips state[key] on click and calls onToggle() so the caller can re-render.
-- progress, if given, is { current, max, text } and renders a bar inside the
-- same card, below the label.
function SchlingelInc.UI.CreateCollapsibleHeader(parent, cardW, key, label, count, state, onToggle, progress)
    local isCollapsed = state[key]
    local headerH = HEADER_LABEL_H + (progress and (HEADER_BAR_PAD + HEADER_BAR_H + HEADER_BAR_PAD) or 0)

    local header = CreateFrame("Button", nil, parent, "BackdropTemplate")
    header:SetSize(cardW, headerH)
    header:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    header:SetBackdropColor(0.18, 0.18, 0.18, 0.95)
    header:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local headerFs = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerFs:SetPoint("TOPLEFT", header, "TOPLEFT", 8, -4)
    headerFs:SetTextColor(1, 0.82, 0, 1)
    headerFs:SetText((isCollapsed and "[+] " or "[-] ") .. label .. "  |cff888888(" .. count .. ")|r")

    if progress then
        local bar = CreateFrame("StatusBar", nil, header, "BackdropTemplate")
        bar:SetPoint("TOPLEFT", header, "TOPLEFT", 6, -(HEADER_LABEL_H))
        bar:SetPoint("TOPRIGHT", header, "TOPRIGHT", -6, -(HEADER_LABEL_H))
        bar:SetHeight(HEADER_BAR_H)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetStatusBarColor(1, 0.82, 0, 1)
        bar:SetBackdrop({
            bgFile   = "Interface\\BUTTONS\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        bar:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        bar:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        bar:SetMinMaxValues(0, math.max(progress.max, 1))
        bar:SetValue(progress.current)

        local barFs = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        barFs:SetPoint("CENTER", bar, "CENTER", 0, 0)
        barFs:SetText(progress.text)
    end

    header:SetScript("OnClick", function()
        state[key] = not isCollapsed or nil
        onToggle()
    end)
    header:SetScript("OnEnter", function() header:SetBackdropBorderColor(1, 0.82, 0, 1) end)
    header:SetScript("OnLeave", function() header:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end)

    return header
end
