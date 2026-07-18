-- interfaces/Shared/ToggleGroup.lua
-- Shared single-select toggle button pool, used by role pickers. Callers keep
-- sizing/positioning each button themselves (the visible subset and layout
-- differs per context), this only wires selection state and appearance.

SchlingelInc.Shared = SchlingelInc.Shared or {}

-- Builds `count` toggle buttons parented to `parent`, tracking single-selection
-- on `form[selectionKey]` (default "selectedRole"). Returns the button array;
-- assign it to whatever field the caller used before (e.g. `f.roleBtns = ...`).
function SchlingelInc.Shared.CreateRoleToggleGroup(parent, form, count, selectionKey)
    selectionKey = selectionKey or "selectedRole"
    local FC = SchlingelInc.Constants.FORM_COLORS

    local btns = {}
    for i = 1, count do
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(10, 22)
        btn:EnableMouse(true)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(unpack(FC.OPTION_BG))

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints()
        lbl:SetJustifyH("CENTER")
        btn.lbl = lbl

        local function UpdateBtn()
            if form[selectionKey] == btn.roleName then
                bg:SetColorTexture(unpack(FC.OPTION_BG_SELECTED))
                lbl:SetTextColor(unpack(FC.TITLE))
            else
                bg:SetColorTexture(unpack(FC.OPTION_BG))
                lbl:SetTextColor(unpack(FC.OPTION_TEXT))
            end
        end
        btn.UpdateAppearance = UpdateBtn

        btn:SetScript("OnClick", function()
            form[selectionKey] = btn.roleName
            for _, b in ipairs(btns) do b.UpdateAppearance() end
        end)
        btn:SetScript("OnEnter", function() lbl:SetTextColor(unpack(FC.HOVER)) end)
        btn:SetScript("OnLeave", UpdateBtn)

        btns[i] = btn
    end

    return btns
end
