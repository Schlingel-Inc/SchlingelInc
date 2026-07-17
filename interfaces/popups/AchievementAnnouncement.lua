-- interfaces/popups/AchievementAnnouncement.lua
-- Compact, icon-less achievement-unlock notification: same size/style as the small
-- death frame (SmallDeathFrame in DeathAnnouncement.lua). A proper custom design for
-- these compact popups is planned as a follow-up, so this deliberately stays minimal.

SchlingelInc.AchievementAnnouncement = {}

local Frame = CreateFrame("Frame", "SchlingelAchievementAnnouncementFrame", UIParent, "BackdropTemplate")
Frame:SetSize(220, 40)
Frame:SetFrameStrata("FULLSCREEN_DIALOG")
Frame:SetFrameLevel(1000)
Frame:SetMovable(true)
Frame:EnableMouse(true)
Frame:RegisterForDrag("LeftButton")
Frame:SetScript("OnDragStart", Frame.StartMoving)
Frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	SchlingelInc:SaveFramePosition(self, "achievementannouncement_position")
end)
SchlingelInc:RestoreFramePosition(Frame, "achievementannouncement_position", "TOPRIGHT", -20, -260)
Frame:Hide()

Frame:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
Frame:SetBackdropColor(0.12, 0.09, 0, 0.85)
Frame:SetBackdropBorderColor(unpack(SchlingelInc.Constants.FORM_COLORS.TITLE))

Frame.text = Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
Frame.text:SetPoint("TOPLEFT",     Frame, "TOPLEFT",     8, -6)
Frame.text:SetPoint("BOTTOMRIGHT", Frame, "BOTTOMRIGHT", -8,  6)
Frame.text:SetJustifyH("CENTER")
Frame.text:SetJustifyV("MIDDLE")
Frame.text:SetTextColor(1, 0.82, 0, 1)

local animGroup = Frame:CreateAnimationGroup()

local fadeIn = animGroup:CreateAnimation("Alpha")
fadeIn:SetDuration(0.3)
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)

local fadeOut = animGroup:CreateAnimation("Alpha")
fadeOut:SetStartDelay(2.5)
fadeOut:SetDuration(0.7)
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0)

animGroup:SetScript("OnFinished", function()
	Frame:Hide()
	SchlingelInc.AnnouncementQueue:Finished()
end)

function SchlingelInc.AchievementAnnouncement:Show(name)
	if not SchlingelOptionsDB["achievementmessages"] then
		return
	end
	SchlingelInc.AnnouncementQueue:Push(function()
		Frame.text:SetText("Erfolg freigeschaltet: " .. SchlingelInc:SanitizeText(name))
		Frame:SetAlpha(0)
		Frame:Show()
		animGroup:Stop()
		animGroup:Play()
		if SchlingelOptionsDB["achievementmessages_sound"] then
			SchlingelInc:PlayAnnouncementSound(SchlingelInc.Constants.SOUNDS.ACHIEVEMENT_ANNOUNCEMENT_STANDARD, nil)
		end
	end)
end
