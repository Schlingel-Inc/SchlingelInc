-- interfaces/popups/AchievementAnnouncement.lua
-- Compact, icon-less achievement-unlock notification: same size/style as the small
-- death frame (SmallDeathFrame in DeathAnnouncement.lua). A proper custom design for
-- these compact popups is planned as a follow-up, so this deliberately stays minimal.

SchlingelInc.AchievementAnnouncement = {}

local Frame = SchlingelInc.Shared.CreateStandardFrame({
	name         = "SchlingelAchievementAnnouncementFrame",
	width        = 220,
	height       = 40,
	strata       = "FULLSCREEN_DIALOG",
	backdrop     = SchlingelInc.Constants.POPUPBACKDROP,
	bgColor      = { 0.12, 0.09, 0, 0.85 },
	borderColor  = SchlingelInc.Constants.FORM_COLORS.TITLE,
	positionKey  = "achievementannouncement_position",
	defaultPoint = "TOPRIGHT",
	defaultX     = -20,
	defaultY     = -260,
})
Frame:SetFrameLevel(1000)

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
