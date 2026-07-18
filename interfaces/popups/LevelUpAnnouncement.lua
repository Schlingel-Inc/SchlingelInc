-- LevelUpAnnouncement.lua
-- Displays animated level-up and cap announcements when guild members reach milestones.
-- Routes through AnnouncementQueue so it never overrides death or other announcements.

SchlingelInc.LevelUpAnnouncement = {}

local LevelUpFrame = SchlingelInc.Shared.CreateStandardFrame({
	name         = "LevelUpFrame",
	width        = 380,
	height       = 200,
	strata       = "FULLSCREEN_DIALOG",
	backdrop     = SchlingelInc.Constants.POPUPBACKDROP,
	positionKey  = "levelupannouncement_position",
	defaultPoint = "TOP",
	defaultX     = 0,
	defaultY     = 0,
})
LevelUpFrame:SetFrameLevel(999)

-- Icon
local icon = LevelUpFrame:CreateTexture(nil, "ARTWORK")
icon:SetSize(96, 96)
icon:SetPoint("TOP", LevelUpFrame, "TOP", 0, -14)
icon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\Wappenrock.tga")

-- Header
local header = LevelUpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOP", icon, "BOTTOM", 0, -20)

-- Body text anchored just below the header
LevelUpFrame.text = LevelUpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
LevelUpFrame.text:SetPoint("TOP", header, "BOTTOM", 0, -8)
LevelUpFrame.text:SetPoint("LEFT", LevelUpFrame, "LEFT", 12, 0)
LevelUpFrame.text:SetPoint("RIGHT", LevelUpFrame, "RIGHT", -12, 0)
LevelUpFrame.text:SetJustifyH("CENTER")
LevelUpFrame.text:SetJustifyV("TOP")
LevelUpFrame.text:SetShadowColor(0, 0, 0, 1)
LevelUpFrame.text:SetShadowOffset(1, -1)

-- Shared animation group; delays are set dynamically per announcement type in ShowDirect
local animGroup = LevelUpFrame:CreateAnimationGroup()

local moveDown = animGroup:CreateAnimation("Translation")
moveDown:SetDuration(0.6)
moveDown:SetOffset(0, -50)
moveDown:SetSmoothing("OUT")

local moveDownAgain = animGroup:CreateAnimation("Translation")
moveDownAgain:SetDuration(0.8)
moveDownAgain:SetOffset(0, -50)
moveDownAgain:SetSmoothing("IN")

local fadeIn = animGroup:CreateAnimation("Alpha")
fadeIn:SetDuration(0.5)
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)
fadeIn:SetSmoothing("IN")

local fadeOut = animGroup:CreateAnimation("Alpha")
fadeOut:SetDuration(1.5)
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0)
fadeOut:SetSmoothing("OUT")

animGroup:SetScript("OnFinished", function()
	LevelUpFrame:Hide()
	SchlingelInc.AnnouncementQueue:Finished()
end)

-- Internal: actually show the frame (called from inside a queue slot)
-- levelup: ~6s total (delay 4.5), cap: ~9s total (delay 7.5)
local function ShowDirect(name, level, isCap)
	if isCap then
		moveDownAgain:SetStartDelay(7.5)
		fadeOut:SetStartDelay(7.5)
		LevelUpFrame:SetBackdropColor(0, 0.06, 0.12, 0.92)
		LevelUpFrame:SetBackdropBorderColor(0.4, 1, 1, 1)
		header:SetText("Level Cap erreicht!")
		header:SetTextColor(0.4, 1, 1, 1)
		LevelUpFrame.text:SetTextColor(0.4, 1, 1, 1)
	else
		moveDownAgain:SetStartDelay(4.5)
		fadeOut:SetStartDelay(4.5)
		LevelUpFrame:SetBackdropColor(0.1, 0.07, 0, 0.92)
		LevelUpFrame:SetBackdropBorderColor(1, 0.84, 0, 1)
		header:SetText("Schlingel! Schlingel!")
		header:SetTextColor(1, 0.84, 0, 1)
		LevelUpFrame.text:SetTextColor(1, 0.84, 0, 1)
	end
	LevelUpFrame.text:SetText(SchlingelInc:SanitizeText(name) .. " hat Level " .. level .. " erreicht!")
	LevelUpFrame:SetAlpha(0)
	LevelUpFrame:Show()
	animGroup:Stop()
	animGroup:Play()
end

-- Public: queue a milestone level-up announcement (gold theme, ~6s)
function SchlingelInc.LevelUpAnnouncement:ShowMessage(name, level)
	if not SchlingelOptionsDB["levelmessages"] then return end
	SchlingelInc.AnnouncementQueue:Push(function()
		ShowDirect(name, level, false)
		if SchlingelOptionsDB["levelmessages_sound"] then
			SchlingelInc:PlayAnnouncementSound(SchlingelInc.Constants.SOUNDS.LEVELUP_ANNOUNCEMENT,
				SchlingelInc.Constants.SOUNDS.TORRO_LEVELUP)
		end
	end)
end

-- Public: queue a cap announcement (cyan theme, ~9s)
function SchlingelInc.LevelUpAnnouncement:ShowCap(name, level)
	if not SchlingelOptionsDB["capmessages"] then return end
	SchlingelInc.AnnouncementQueue:Push(function()
		ShowDirect(name, level, true)
		if SchlingelOptionsDB["capmessages_sound"] then
			SchlingelInc:PlayAnnouncementSound(SchlingelInc.Constants.SOUNDS.CAP_ANNOUNCEMENT_STANDARD,
				SchlingelInc.Constants.SOUNDS.TORRO_CAP)
		end
	end)
end
