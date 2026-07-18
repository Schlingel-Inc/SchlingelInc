-- interfaces/Shared/FormWidgets.lua
-- Small shared form-field factories duplicated verbatim across popup forms.

SchlingelInc.Shared = SchlingelInc.Shared or {}

function SchlingelInc.Shared.CreateEditBox(parent, width, maxLetters, numeric)
    local FC = SchlingelInc.Constants.FORM_COLORS
    local eb = CreateFrame("EditBox", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
    eb:SetSize(width, 22)
    eb:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
    eb:SetBackdropColor(unpack(FC.FORM_BG))
    eb:SetBackdropBorderColor(unpack(FC.FORM_BORDER))
    eb:SetFontObject("GameFontHighlight")
    eb:SetTextInsets(6, 6, 0, 0)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(maxLetters)
    if numeric then eb:SetNumeric(true) end
    eb:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    return eb
end

function SchlingelInc.Shared.CreateLabel(parent, text)
    local FC = SchlingelInc.Constants.FORM_COLORS
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetText(text)
    lbl:SetTextColor(unpack(FC.LABEL))
    return lbl
end
