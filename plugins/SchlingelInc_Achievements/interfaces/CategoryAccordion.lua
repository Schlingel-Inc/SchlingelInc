-- interfaces/CategoryAccordion.lua
-- Achievement-specific wrapper around the base addon's shared collapsible-header
-- widget (SchlingelInc.UI): groups entries by kind and labels/orders sections.

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
    return SchlingelInc.UI.NewCollapsedState(SchlingelInc.Achievements.CATEGORY_ORDER)
end

-- points, if given, is { current, max } and renders a Punkte-progress bar inside
-- the header card (GuildPanel only — Officer/popup callers omit it).
function SchlingelInc.Achievements.CreateCategoryHeader(parent, cardW, kind, count, state, onToggle, points)
    local label = SchlingelInc.Achievements.KIND_LABELS[kind] or kind
    local progress = points and {
        current = points.current,
        max     = points.max,
        text    = points.current .. " / " .. points.max .. " Punkte",
    }
    return SchlingelInc.UI.CreateCollapsibleHeader(parent, cardW, kind, label, count, state, onToggle, progress)
end
