-- DeathAnnouncement.lua
-- Displays animated death announcements when guild members die

SchlingelInc.DeathAnnouncement = {}

local DeathMessageFrame = CreateFrame("Frame", "DeathMessageFrame", UIParent, "BackdropTemplate")
DeathMessageFrame:SetSize(380, 200)
DeathMessageFrame:SetFrameStrata("FULLSCREEN_DIALOG")
DeathMessageFrame:SetFrameLevel(1000)
DeathMessageFrame:SetMovable(true)
DeathMessageFrame:EnableMouse(true)
DeathMessageFrame:RegisterForDrag("LeftButton")
DeathMessageFrame:SetScript("OnDragStart", DeathMessageFrame.StartMoving)
DeathMessageFrame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	SchlingelInc:SaveFramePosition(self, "deathannouncement_position")
end)
SchlingelInc:RestoreFramePosition(DeathMessageFrame, "deathannouncement_position", "TOP", 0, 0)
DeathMessageFrame:Hide()

DeathMessageFrame:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
DeathMessageFrame:SetBackdropColor(0.12, 0, 0, 0.85)
DeathMessageFrame:SetBackdropBorderColor(1, 0.15, 0.15, 1)

-- Icon
local icon = DeathMessageFrame:CreateTexture(nil, "ARTWORK")
icon:SetSize(96, 96)
icon:SetPoint("TOP", DeathMessageFrame, "TOP", 0, -14)
icon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\Wappenrock.tga")

-- Header
local header = DeathMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOP", icon, "BOTTOM", 0, -20)
header:SetText("Schande!")
header:SetTextColor(1, 0.2, 0.2, 1)

-- Body text anchored just below the header
DeathMessageFrame.text = DeathMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
DeathMessageFrame.text:SetPoint("TOP", header, "BOTTOM", 0, -8)
DeathMessageFrame.text:SetPoint("LEFT", DeathMessageFrame, "LEFT", 12, 0)
DeathMessageFrame.text:SetPoint("RIGHT", DeathMessageFrame, "RIGHT", -12, 0)
DeathMessageFrame.text:SetJustifyH("CENTER")
DeathMessageFrame.text:SetJustifyV("TOP")
DeathMessageFrame.text:SetTextColor(1, 0.1, 0.1, 1)
DeathMessageFrame.text:SetShadowColor(0, 0, 0, 1)
DeathMessageFrame.text:SetShadowOffset(1, -1)

-- Animation (~5 seconds total)
local animGroup = DeathMessageFrame:CreateAnimationGroup()

local moveDown = animGroup:CreateAnimation("Translation")
moveDown:SetDuration(0.6)
moveDown:SetOffset(0, -50)
moveDown:SetSmoothing("OUT")

local moveDownAgain = animGroup:CreateAnimation("Translation")
moveDownAgain:SetStartDelay(3.5)
moveDownAgain:SetDuration(0.8)
moveDownAgain:SetOffset(0, -50)
moveDownAgain:SetSmoothing("IN")

local fadeIn = animGroup:CreateAnimation("Alpha")
fadeIn:SetDuration(0.5)
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)
fadeIn:SetSmoothing("IN")

local fadeOut = animGroup:CreateAnimation("Alpha")
fadeOut:SetStartDelay(3.5)
fadeOut:SetDuration(1.5)
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0)
fadeOut:SetSmoothing("OUT")

-- Notify queue when animation completes
animGroup:SetScript("OnFinished", function()
	DeathMessageFrame:Hide()
	SchlingelInc.AnnouncementQueue:Finished()
end)

-- Shows the death message with animation (routed through the announcement queue)
function SchlingelInc.DeathAnnouncement:ShowDeathMessage(message)
	if not SchlingelOptionsDB["deathmessages"] then
		return
	end
	SchlingelInc.AnnouncementQueue:Push(function()
		DeathMessageFrame.text:SetText(SchlingelInc:SanitizeText(message))
		DeathMessageFrame:SetAlpha(0)
		DeathMessageFrame:Show()
		animGroup:Stop()
		animGroup:Play()
		if SchlingelOptionsDB["deathmessages_sound"] then
			SchlingelInc:PlayAnnouncementSound(SchlingelInc.Constants.SOUNDS.DEATH_ANNOUNCEMENT,
				SchlingelInc.Constants.SOUNDS.TORRO_DEATH)
		end
	end)
end

-- Compact death notification for when the local player is in an instance.
-- Shown top-right, small frame, short text: "NAME ist gestorben."
local SmallDeathFrame = CreateFrame("Frame", "SchlingelSmallDeathFrame", UIParent, "BackdropTemplate")
SmallDeathFrame:SetSize(220, 40)
SmallDeathFrame:SetFrameStrata("FULLSCREEN_DIALOG")
SmallDeathFrame:SetFrameLevel(1000)
SmallDeathFrame:SetMovable(true)
SmallDeathFrame:EnableMouse(true)
SmallDeathFrame:RegisterForDrag("LeftButton")
SmallDeathFrame:SetScript("OnDragStart", SmallDeathFrame.StartMoving)
SmallDeathFrame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	SchlingelInc:SaveFramePosition(self, "smalldeathannouncement_position")
end)
SchlingelInc:RestoreFramePosition(SmallDeathFrame, "smalldeathannouncement_position", "TOPRIGHT", -20, -200)
SmallDeathFrame:Hide()

SmallDeathFrame:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
SmallDeathFrame:SetBackdropColor(0.12, 0, 0, 0.85)
SmallDeathFrame:SetBackdropBorderColor(1, 0.15, 0.15, 1)

SmallDeathFrame.text = SmallDeathFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
SmallDeathFrame.text:SetPoint("TOPLEFT",     SmallDeathFrame, "TOPLEFT",     8, -6)
SmallDeathFrame.text:SetPoint("BOTTOMRIGHT", SmallDeathFrame, "BOTTOMRIGHT", -8,  6)
SmallDeathFrame.text:SetJustifyH("CENTER")
SmallDeathFrame.text:SetJustifyV("MIDDLE")
SmallDeathFrame.text:SetTextColor(1, 0.3, 0.3, 1)

local smallAnimGroup = SmallDeathFrame:CreateAnimationGroup()

local smallFadeIn = smallAnimGroup:CreateAnimation("Alpha")
smallFadeIn:SetDuration(0.3)
smallFadeIn:SetFromAlpha(0)
smallFadeIn:SetToAlpha(1)

local smallFadeOut = smallAnimGroup:CreateAnimation("Alpha")
smallFadeOut:SetStartDelay(2.5)
smallFadeOut:SetDuration(0.7)
smallFadeOut:SetFromAlpha(1)
smallFadeOut:SetToAlpha(0)

smallAnimGroup:SetScript("OnFinished", function()
	SmallDeathFrame:Hide()
	SchlingelInc.AnnouncementQueue:Finished()
end)

function SchlingelInc.DeathAnnouncement:ShowSmallDeathMessage(name)
	if not SchlingelOptionsDB["deathmessages"] then
		return
	end
	SchlingelInc.AnnouncementQueue:Push(function()
		SmallDeathFrame.text:SetText(SchlingelInc:SanitizeText(name) .. " ist gestorben.")
		SmallDeathFrame:SetAlpha(0)
		SmallDeathFrame:Show()
		smallAnimGroup:Stop()
		smallAnimGroup:Play()
	end)
end
