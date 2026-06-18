-- GuildInvites.lua
-- Displays popup for incoming guild invite requests (for officers)

SchlingelInc.GuildInvites = {}

local InviteMessageFrame = CreateFrame("Frame", "InviteMessageFrame", UIParent, "BackdropTemplate")
InviteMessageFrame:SetSize(350, 130)
InviteMessageFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -60, -200)
InviteMessageFrame:SetFrameStrata("FULLSCREEN_DIALOG")
InviteMessageFrame:SetFrameLevel(1000)
InviteMessageFrame:Hide()

InviteMessageFrame:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
InviteMessageFrame:SetBackdropColor(0, 0, 0, 0.85)
InviteMessageFrame:SetBackdropBorderColor(1, 0.55, 0.73, 1)

-- Icon — inside frame, top-left
local icon = InviteMessageFrame:CreateTexture(nil, "ARTWORK")
icon:SetSize(28, 28)
icon:SetPoint("TOPLEFT", InviteMessageFrame, "TOPLEFT", 10, -8)
icon:SetTexture("Interface\\Icons\\inv_letter_18")

-- Header text next to icon
local header = InviteMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOPLEFT", icon, "TOPRIGHT", 6, 0)
header:SetPoint("RIGHT", InviteMessageFrame, "RIGHT", -10, 0)
header:SetJustifyH("LEFT")
header:SetText("Neue Gildenanfrage!")
header:SetTextColor(1, 0.82, 0, 1)

-- Divider below icon/header row
local div = InviteMessageFrame:CreateTexture(nil, "ARTWORK")
div:SetHeight(1)
div:SetColorTexture(0.4, 0.4, 0.4, 0.7)
div:SetPoint("TOPLEFT",  InviteMessageFrame, "TOPLEFT",  8, -42)
div:SetPoint("TOPRIGHT", InviteMessageFrame, "TOPRIGHT", -8, -42)

-- Message text
InviteMessageFrame.text = InviteMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
InviteMessageFrame.text:SetPoint("TOPLEFT", InviteMessageFrame, "TOPLEFT", 10, -48)
InviteMessageFrame.text:SetPoint("RIGHT",   InviteMessageFrame, "RIGHT",   -10, 0)
InviteMessageFrame.text:SetJustifyH("LEFT")
InviteMessageFrame.text:SetJustifyV("TOP")
InviteMessageFrame.text:SetShadowColor(0, 0, 0, 1)
InviteMessageFrame.text:SetShadowOffset(1, -1)

-- Buttons anchored to BOTTOMLEFT for predictable placement
local function HandleAcceptClick()
    SchlingelInc.GuildRecruitment:HandleAcceptRequest(InviteMessageFrame.playerName)
    SchlingelInc.GuildInvites:HideInviteMessage()
end
local acceptBtn = CreateFrame("Button", nil, InviteMessageFrame, "UIPanelButtonTemplate")
acceptBtn:SetSize(75, 25)
acceptBtn:SetPoint("BOTTOMLEFT", InviteMessageFrame, "BOTTOMLEFT", 10, 8)
acceptBtn:SetText("Annehmen")
acceptBtn:SetScript("OnClick", HandleAcceptClick)

local function HandleDeclineClick()
    SchlingelInc.GuildRecruitment:HandleDeclineRequest(InviteMessageFrame.playerName)
    SchlingelInc.GuildInvites:HideInviteMessage()
end
local declineBtn = CreateFrame("Button", nil, InviteMessageFrame, "UIPanelButtonTemplate")
declineBtn:SetSize(75, 25)
declineBtn:SetPoint("BOTTOMLEFT", InviteMessageFrame, "BOTTOMLEFT", 95, 8)
declineBtn:SetText("Ablehnen")
declineBtn:SetScript("OnClick", HandleDeclineClick)

-- Fade-in animation
local animGroup = InviteMessageFrame:CreateAnimationGroup()
local fadeIn = animGroup:CreateAnimation("Alpha")
fadeIn:SetDuration(0.3)
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)
fadeIn:SetSmoothing("IN")

function SchlingelInc.GuildInvites:ShowInviteMessage(message, requestData)
    if InviteMessageFrame:IsShown() then return end
    InviteMessageFrame.playerName = requestData["name"]
    InviteMessageFrame.text:SetText(message)
    InviteMessageFrame:Show()
    animGroup:Stop()
    animGroup:Play()
end

function SchlingelInc.GuildInvites:HideInviteMessage()
    InviteMessageFrame:Hide()
end
