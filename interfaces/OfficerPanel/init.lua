SchlingelInc.OfficerPanel = {}

local OfficerPanel = SchlingelInc.OfficerPanel

OfficerPanel.PANEL_W  = 500
OfficerPanel.PANEL_H  = 420
OfficerPanel.TITLE_H  = 28
OfficerPanel.TAB_H    = 24
OfficerPanel.SCROLL_W = 464  -- PANEL_W - left(8) - right(8) - scrollbar(20)

OfficerPanel.frame           = nil
OfficerPanel.tabContents     = {}
OfficerPanel.tabBtns         = {}
OfficerPanel.tabFilterPanels = {}

OfficerPanel.inactiveFilter = { filterName = "" }
OfficerPanel.progressFilter = {
    filterName = "", levelValue = nil, levelBelow = true,
    capOnly    = false, goldValue  = nil, goldBelow  = true,
}
OfficerPanel.discordFilter  = { filterName = "", minCount = nil }

function OfficerPanel.IsOfficer()
    return CanGuildRemove()
end
