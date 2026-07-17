-- GuildInvites.lua
-- Notification popup for incoming guild invite requests (officers only).
-- Accept/Decline happens in the Anfragen tab of the OfficerPanel.

SchlingelInc.GuildInvites = {}

local InviteMessageFrame = CreateFrame("Button", "InviteMessageFrame", UIParent, "BackdropTemplate")
InviteMessageFrame:SetSize(260, 64)
SchlingelInc:RestoreFramePosition(InviteMessageFrame, "guildinvites_popup_position", "TOPRIGHT", -60, -200)
InviteMessageFrame:SetFrameStrata("FULLSCREEN_DIALOG")
InviteMessageFrame:SetFrameLevel(1000)
InviteMessageFrame:RegisterForClicks("LeftButtonUp")
InviteMessageFrame:RegisterForDrag("LeftButton")
InviteMessageFrame:SetMovable(true)
InviteMessageFrame:EnableMouse(true)
InviteMessageFrame:Hide()

InviteMessageFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

InviteMessageFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SchlingelInc:SaveFramePosition(self, "guildinvites_popup_position")
end)

InviteMessageFrame:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
InviteMessageFrame:SetBackdropColor(unpack(SchlingelInc.Constants.FORM_COLORS.FORM_BG))
InviteMessageFrame:SetBackdropBorderColor(unpack(SchlingelInc.Constants.FORM_COLORS.ACCENT_BORDER))

local header = InviteMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
header:SetPoint("TOPLEFT", InviteMessageFrame, "TOPLEFT", 10, -10)
header:SetPoint("RIGHT", InviteMessageFrame, "RIGHT", -28, 0)
header:SetJustifyH("LEFT")
header:SetText("Neue Gildenanfragen!")
header:SetTextColor(unpack(SchlingelInc.Constants.FORM_COLORS.TITLE))

local div = InviteMessageFrame:CreateTexture(nil, "ARTWORK")
div:SetHeight(1)
div:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.DIVIDER))
div:SetPoint("TOPLEFT",  InviteMessageFrame, "TOPLEFT",  8, -32)
div:SetPoint("TOPRIGHT", InviteMessageFrame, "TOPRIGHT", -8, -32)

local countText = InviteMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
countText:SetPoint("TOPLEFT", InviteMessageFrame, "TOPLEFT", 10, -40)
countText:SetPoint("RIGHT",   InviteMessageFrame, "RIGHT",   -10, 0)
countText:SetJustifyH("LEFT")
countText:SetShadowColor(0, 0, 0, 1)
countText:SetShadowOffset(1, -1)

local closeBtn = CreateFrame("Button", nil, InviteMessageFrame, "UIPanelCloseButton")
closeBtn:SetSize(20, 20)
closeBtn:SetPoint("TOPRIGHT", InviteMessageFrame, "TOPRIGHT", -2, -2)
closeBtn:SetScript("OnClick", function() InviteMessageFrame:Hide() end)

local animGroup = InviteMessageFrame:CreateAnimationGroup()
local fadeIn = animGroup:CreateAnimation("Alpha")
fadeIn:SetDuration(0.3)
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)
fadeIn:SetSmoothing("IN")

InviteMessageFrame:SetScript("OnClick", function()
    InviteMessageFrame:Hide()
    SchlingelInc.OfficerPanel:ShowInvites()
end)

local hideTimer

local function CountPending()
    local n = 0
    for _ in pairs(SchlingelInc.GuildRecruitment.inviteRequests) do n = n + 1 end
    return n
end

function SchlingelInc.GuildInvites:NotifyPendingInvites()
    local n = CountPending()
    if n == 0 then
        InviteMessageFrame:Hide()
        return
    end

    countText:SetText(n == 1 and "1 ausstehende Anfrage" or n .. " ausstehende Anfragen")

    if hideTimer then hideTimer:Cancel() end
    hideTimer = C_Timer.After(8, function() InviteMessageFrame:Hide() end)

    if not InviteMessageFrame:IsShown() then
        InviteMessageFrame:Show()
        animGroup:Stop()
        animGroup:Play()
    end
end

function SchlingelInc.GuildInvites:HideInviteMessage()
    if hideTimer then hideTimer:Cancel() end
    InviteMessageFrame:Hide()
end
