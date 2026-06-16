-- GenericPopup.lua
-- Reusable popup framework for displaying notifications

SchlingelInc.Popup = {
	activePopups = {}
}

local function RemovePopup(popupFrame)
	for i, popup in ipairs(SchlingelInc.Popup.activePopups) do
		if popup == popupFrame then
			table.remove(SchlingelInc.Popup.activePopups, i)
			break
		end
	end
	UIFrameFadeRemoveFrame(popupFrame)
	popupFrame:SetAlpha(1)
	popupFrame.fadeTimer = nil
	popupFrame.cleanupTimer = nil
	popupFrame:StopMovingOrSizing()
end

-- Creates and shows a generic popup with skull icon, title, and message
-- @param options table with fields:
--   - title: title text (required)
--   - message: message text (required)
function SchlingelInc.Popup:Show(options)
	if not options or not options.title or not options.message then
		return
	end

	-- Set defaults
	local title = options.title
	local message = options.message
	local titleColor = {1, 0.55, 0.73}
	local messageColor = {1, 1, 1}
	local borderColor = {1, 0.55, 0.73, 0}
	local displayTime = options.displayTime or 3

	-- Create the frame
	local frame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetSize(370, 160)
	frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
	frame:SetBackdrop(SchlingelInc.Constants.BACKDROP)
	frame:SetBackdropColor(0, 0, 0, 0.50)
	frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(false)
	frame:SetMovable(false)
	frame:EnableMouse(false)
	frame:SetScript("OnHide", RemovePopup)

	-- Skull icon
	local iconFrame = CreateFrame("Frame", nil, frame)
	iconFrame:SetSize(40, 40)
	iconFrame:SetPoint("TOP", frame, "TOP", 0, -30)

	local icon = iconFrame:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(iconFrame)
	icon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\SI_Transp_512_x_512_px.tga")
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	-- Title
	local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	titleText:SetPoint("TOP", iconFrame, "BOTTOM", 0, -5)
	titleText:SetText(title)
	titleText:SetTextColor(titleColor[1], titleColor[2], titleColor[3])

	-- Message
	local messageText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	messageText:SetPoint("TOP", titleText, "BOTTOM", 0, -5)
	messageText:SetWidth(320)
	messageText:SetJustifyH("CENTER")
	messageText:SetText(message)
	messageText:SetTextColor(messageColor[1], messageColor[2], messageColor[3])

	-- Show the frame
	frame:SetAlpha(1)
	frame:Show()

	-- Store in active popups
	table.insert(self.activePopups, frame)

	-- Schedule fade out and cleanup
	frame.fadeTimer = C_Timer.NewTimer(displayTime, function()
		UIFrameFadeOut(frame, 1, 1, 0)
		frame.cleanupTimer = C_Timer.After(1, function()
			if frame:IsShown() then
				frame:Hide()
			end
		end)
	end)

	return frame
end

-- Hides all active popups
function SchlingelInc.Popup:HideAll()
	for _, popup in ipairs(self.activePopups) do
		if popup then
			popup:Hide()
		end
	end
	self.activePopups = {}
end
