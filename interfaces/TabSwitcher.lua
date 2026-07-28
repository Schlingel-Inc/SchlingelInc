-- interfaces/TabSwitcher.lua
-- Shared tab-bar factory used by OfficerPanel and GuildPanel.

SchlingelInc.Shared = SchlingelInc.Shared or {}

local TAB_GAP = 4

-- cfg = {
--   parent       : Frame   -- main panel frame the tab row/content attach to
--   tabDefs      : array of {
--                    id         : string
--                    label      : string
--                    canSelect  : function() -> bool|nil  -- optional; return false to block the switch (e.g. show a permission message)
--                    onSelected : function()              -- optional; runs after the switch completes (e.g. trigger a data refresh)
--                  }
--   width        : number  -- total width available for the tab row (usually parent width - 16)
--   tabHeight    : number  -- height of each tab button
--   topOffset    : number  -- distance from parent TOP to the tab row TOP
--   contentTop   : number  -- y-offset (from parent TOPLEFT) where tab content frames start (negative)
--   defaultTab   : string  -- id of the tab selected once building is done
-- }
-- Returns switcher = {
--   tabBtns      = { id -> button Frame },
--   tabContents  = { id -> content Frame },
--   filterPanels = { id -> Frame }  -- empty; callers may populate per-tab filter panels here.
--                                      Any panel registered here is hidden whenever the tab switches away.
--   SwitchTab    = function(id)
-- }
function SchlingelInc.Shared.CreateTabSwitcher(cfg)
    local parent     = cfg.parent
    local width      = cfg.width
    local tabHeight  = cfg.tabHeight
    local topOffset  = cfg.topOffset
    local contentTop = cfg.contentTop

    local switcher = {
        tabBtns      = {},
        tabContents  = {},
        filterPanels = {},
        tabDefs      = {},
    }

    local function LayoutTabs()
        local tabBtnW = math.floor((width - TAB_GAP * (#switcher.tabDefs - 1)) / #switcher.tabDefs)
        local tabStep = tabBtnW + TAB_GAP
        for i, tab in ipairs(switcher.tabDefs) do
            local btn = switcher.tabBtns[tab.id]
            btn:SetSize(tabBtnW, tabHeight)
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 8 + (i - 1) * tabStep, topOffset)
        end
    end

    local function CreateTabButton(tab)
        local btn = CreateFrame("Button", nil, parent)
        btn:EnableMouse(true)

        local tabBg = btn:CreateTexture(nil, "BACKGROUND")
        tabBg:SetAllPoints()
        tabBg:SetColorTexture(0.06, 0.06, 0.06, 1)
        btn.tabBg = tabBg

        local activeLine = btn:CreateTexture(nil, "OVERLAY")
        activeLine:SetHeight(2)
        activeLine:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  2, 0)
        activeLine:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 0)
        activeLine:SetColorTexture(1, 0.82, 0, 1)
        activeLine:Hide()
        btn.activeLine = activeLine

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetAllPoints()
        lbl:SetJustifyH("CENTER")
        lbl:SetText(tab.label)
        btn.lbl = lbl

        btn:SetScript("OnClick", function()
            if tab.canSelect and tab.canSelect() == false then return end
            switcher.SwitchTab(tab.id)
            if tab.onSelected then tab.onSelected() end
        end)

        switcher.tabBtns[tab.id] = btn

        local content = CreateFrame("Frame", nil, parent)
        content:SetPoint("TOPLEFT",     parent, "TOPLEFT",     8, contentTop)
        content:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)
        content:Hide()
        switcher.tabContents[tab.id] = content
    end

    for _, tab in ipairs(cfg.tabDefs) do
        table.insert(switcher.tabDefs, tab)
        CreateTabButton(tab)
    end
    LayoutTabs()

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    divider:SetPoint("TOPLEFT",  parent, "TOPLEFT",  8, contentTop + 2)
    divider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, contentTop + 2)

    function switcher.SwitchTab(id)
        switcher.activeTab = id
        for _, fp in pairs(switcher.filterPanels) do
            if fp and fp:IsShown() then fp:Hide() end
        end
        for tid, c in pairs(switcher.tabContents) do c:SetShown(tid == id) end
        for tid, btn in pairs(switcher.tabBtns) do
            local active = tid == id
            btn.lbl:SetTextColor(active and 1 or 0.5, active and 0.82 or 0.5, active and 0 or 0.5, 1)
            btn.tabBg:SetColorTexture(active and 0.14 or 0.06, active and 0.14 or 0.06, active and 0.14 or 0.06, 1)
            btn.activeLine:SetShown(active)
        end
    end

    function switcher.AddTab(tab)
        table.insert(switcher.tabDefs, tab)
        CreateTabButton(tab)
        LayoutTabs()
        if switcher.activeTab then
            switcher.SwitchTab(switcher.activeTab)
        end
        return switcher.tabContents[tab.id]
    end

    if cfg.defaultTab then
        switcher.SwitchTab(cfg.defaultTab)
    end

    return switcher
end
