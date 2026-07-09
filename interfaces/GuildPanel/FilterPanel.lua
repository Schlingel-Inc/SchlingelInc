-- GuildPanel/FilterPanel.lua
-- Wraps the shared FilterPanel factory with GuildPanel-specific state and callbacks.

local GP = SchlingelInc.GuildPanel

function SchlingelInc.GuildPanel:CreateFilterPanel()
    if self.filterPanel then return end

    local fp = SchlingelInc.Shared.CreateFilterPanel({
        panelName   = GP.PANEL_NAME,
        anchorFrame = self.frame,
        filterState = GP,
        getDataFn   = function() return SchlingelInc.GuildPanel.data end,
        showRoles   = true,
        onChangeFn  = function() SchlingelInc.GuildPanel:Refresh() end,
    })

    self.filterPanel    = fp
    self.filterProfList = fp.profList

    if self.frame.tabSwitcher then
        self.frame.tabSwitcher.filterPanels.roster = fp
    end
end

function SchlingelInc.GuildPanel:ToggleFilterPanel()
    if not self.filterPanel then self:CreateFilterPanel() end
    if self.filterPanel:IsShown() then
        self.filterPanel:Hide()
        if self.filterProfList then self.filterProfList:Hide() end
    else
        self.filterPanel:Show()
    end
end
