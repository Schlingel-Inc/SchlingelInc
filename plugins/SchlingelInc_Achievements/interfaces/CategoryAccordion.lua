-- interfaces/CategoryAccordion.lua
-- Shared collapsible category-header helpers, used by the Guild/Officer panel
-- achievement tabs and the grant/revoke popups to group entries by kind.

local KIND = SchlingelInc.Achievements.KIND

SchlingelInc.Achievements.CATEGORY_ORDER = { KIND.LEVEL, KIND.KILL_COUNT, KIND.MANUAL }

function SchlingelInc.Achievements.GroupByKind(entries)
    local groups = {}
    for _, entry in ipairs(entries) do
        groups[entry.kind] = groups[entry.kind] or {}
        table.insert(groups[entry.kind], entry)
    end
    return groups
end

function SchlingelInc.Achievements.NewCollapsedCategoryState()
    local state = {}
    for _, kind in ipairs(SchlingelInc.Achievements.CATEGORY_ORDER) do
        state[kind] = true
    end
    return state
end

-- Flips state[kind] on click and calls onToggle() so the caller can re-render.
function SchlingelInc.Achievements.CreateCategoryHeader(parent, cardW, kind, count, state, onToggle)
    local isCollapsed = state[kind]

    local header = CreateFrame("Button", nil, parent)
    header:SetSize(cardW, 20)

    local headerFs = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerFs:SetPoint("LEFT", header, "LEFT", 4, 0)
    headerFs:SetTextColor(1, 0.82, 0, 1)
    headerFs:SetText((isCollapsed and "[+] " or "[-] ") .. (SchlingelInc.Achievements.KIND_LABELS[kind] or kind)
        .. "  |cff888888(" .. count .. ")|r")

    header:SetScript("OnClick", function()
        state[kind] = not isCollapsed or nil
        onToggle()
    end)
    header:SetScript("OnEnter", function() headerFs:SetTextColor(1, 1, 0.6, 1) end)
    header:SetScript("OnLeave", function() headerFs:SetTextColor(1, 0.82, 0, 1) end)

    return header
end
