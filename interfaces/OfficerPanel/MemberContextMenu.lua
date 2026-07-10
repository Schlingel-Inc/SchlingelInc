local OfficerPanel = SchlingelInc.OfficerPanel

StaticPopupDialogs["SCHLINGEL_DEATHSET_SET"] = {
    text = "Deathcounter für %s setzen:",
    button1 = "Setzen",
    button2 = "Abbrechen",
    hasEditBox = true,
    maxLetters = 6,
    OnShow = function(self)
        self.EditBox:SetText("")
        self.EditBox:SetFocus()
    end,
    OnAccept = function(self)
        SchlingelInc.Death:SetRemote(self.data, self.EditBox:GetText())
    end,
    EditBoxOnEnterPressed = function(self)
        self:GetParent().button1:Click()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local contextMenu = CreateFrame("Frame", "SchlingelIncMemberContextMenu", UIParent, "UIDropDownMenuTemplate")
local contextMenuTarget = nil

UIDropDownMenu_Initialize(contextMenu, function(self, level)
    if not contextMenuTarget then return end
    local targetName = contextMenuTarget

    local info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true

    info.text = "Schande-Ansicht öffnen"
    info.func = function()
        CloseDropDownMenus()
        OfficerPanel:ShowSchandeViewer(targetName)
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.text = "Deathset setzen"
    info.func = function()
        CloseDropDownMenus()
        StaticPopup_Show("SCHLINGEL_DEATHSET_SET", targetName, nil, targetName)
    end
    UIDropDownMenu_AddButton(info, level)
end, "MENU")

-- Public API

function OfficerPanel:ShowMemberContextMenu(targetName)
    if not targetName or targetName == "" then return end
    contextMenuTarget = targetName
    ToggleDropDownMenu(1, nil, contextMenu, "cursor", 0, 0)
end
