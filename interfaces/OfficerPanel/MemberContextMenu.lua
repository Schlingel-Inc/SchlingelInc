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
        local dialog = self:GetParent()
        if not dialog then return end

        local button1 = (dialog.GetName and _G[dialog:GetName() .. "Button1"]) or dialog.button1
        if button1 and button1.Click then
            button1:Click()
            return
        end

        local info = dialog.which and StaticPopupDialogs[dialog.which]
        if info and info.OnAccept then
            info.OnAccept(dialog)
            dialog:Hide()
        end
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
local contextMenuClickCatcher = CreateFrame("Button", nil, UIParent)

contextMenuClickCatcher:SetAllPoints(UIParent)
contextMenuClickCatcher:SetFrameStrata("HIGH")
contextMenuClickCatcher:EnableMouse(true)
contextMenuClickCatcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
contextMenuClickCatcher:SetScript("OnClick", function()
    CloseDropDownMenus()
    contextMenuClickCatcher:Hide()
    contextMenuTarget = nil
end)
contextMenuClickCatcher:Hide()

if DropDownList1 and not DropDownList1.SchlingelIncCloseHooked then
    DropDownList1:HookScript("OnHide", function()
        contextMenuClickCatcher:Hide()
        contextMenuTarget = nil
    end)
    DropDownList1.SchlingelIncCloseHooked = true
end

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

    info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.text = "Erfolg verleihen"
    info.func = function()
        CloseDropDownMenus()
        SchlingelInc.Popup:ShowAchievementGrantForm(targetName)
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.text = "Erfolg entziehen"
    info.func = function()
        CloseDropDownMenus()
        SchlingelInc.Popup:ShowAchievementRevokeForm(targetName)
    end
    UIDropDownMenu_AddButton(info, level)
end, "MENU")

-- Public API

function OfficerPanel:ShowMemberContextMenu(targetName)
    if not targetName or targetName == "" then return end
    contextMenuTarget = targetName
    ToggleDropDownMenu(1, nil, contextMenu, "cursor", 0, 0)
    if DropDownList1 and DropDownList1:IsShown() then
        contextMenuClickCatcher:Show()
    else
        contextMenuClickCatcher:Hide()
        contextMenuTarget = nil
    end
end
