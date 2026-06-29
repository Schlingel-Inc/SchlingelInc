-- InactivityWindow.lua
SchlingelInc = SchlingelInc or {}

function SchlingelInc:CreateInactivityWindow()
	if self.InactivityWindow then return end

	local trashFrame = CreateFrame("Frame")
	trashFrame:Hide()

	local inactiveFrame = CreateFrame("Frame", "SchlingelIncInactivityWindow", UIParent, "BackdropTemplate")
	inactiveFrame:SetSize(650, 450)
	inactiveFrame:SetPoint("CENTER")
	inactiveFrame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    inactiveFrame:SetBackdropColor(0, 0, 0, 0.8)
	inactiveFrame:SetMovable(true)
	inactiveFrame:EnableMouse(true)
	inactiveFrame:RegisterForDrag("LeftButton")
	inactiveFrame:SetScript("OnDragStart", inactiveFrame.StartMoving)
	inactiveFrame:SetScript("OnDragStop", inactiveFrame.StopMovingOrSizing)
	inactiveFrame:Hide()
	SchlingelInc:RegisterFrameForEscape(inactiveFrame)

	-- Header
	local header = inactiveFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	header:SetPoint("TOP", inactiveFrame, "TOP", 0, -15)
	header:SetText(string.format("Inaktive Mitglieder (> %d Tage)", SchlingelInc.Constants.INACTIVE_DAYS_THRESHOLD))

	-- Close Button
	local closeBtn = CreateFrame("Button", nil, inactiveFrame, "UIPanelCloseButton")
	closeBtn:SetSize(22, 22)
	closeBtn:SetPoint("TOPRIGHT", inactiveFrame, "TOPRIGHT", -7, -7)
	closeBtn:SetScript("OnClick", function() inactiveFrame:Hide() end)

	-- Create scroll frame
	local scrollFrame = CreateFrame("ScrollFrame", nil, inactiveFrame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", inactiveFrame, "TOPLEFT", 15, -50)
	scrollFrame:SetPoint("BOTTOMRIGHT", inactiveFrame, "BOTTOMRIGHT", -30, 15)

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetWidth(scrollFrame:GetWidth() - 20)
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)

	-- Table headers
	local yOffset = -10
	local headerFrame = CreateFrame("Frame", nil, scrollChild)
	headerFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
	headerFrame:SetWidth(scrollChild:GetWidth() - 20)
	headerFrame:SetHeight(20)

	local nameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	nameHeader:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 0, 0)
	nameHeader:SetWidth(150)
	nameHeader:SetJustifyH("LEFT")
	nameHeader:SetText("Name")

	local levelHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	levelHeader:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 160, 0)
	levelHeader:SetWidth(40)
	levelHeader:SetJustifyH("CENTER")
	levelHeader:SetText("Level")

	local rankHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	rankHeader:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 210, 0)
	rankHeader:SetWidth(120)
	rankHeader:SetJustifyH("LEFT")
	rankHeader:SetText("Rang")

	local offlineHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	offlineHeader:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 340, 0)
	offlineHeader:SetWidth(80)
	offlineHeader:SetJustifyH("LEFT")
	offlineHeader:SetText("Offline Seit")

	yOffset = yOffset - 25

	-- Container for inactive member rows
	inactiveFrame.inactiveContainer = CreateFrame("Frame", nil, scrollChild)
	inactiveFrame.inactiveContainer:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
	inactiveFrame.inactiveContainer:SetWidth(scrollChild:GetWidth() - 20)
	inactiveFrame.inactiveContainer:SetHeight(1)

	inactiveFrame.inactiveRows = {}

	local function UpdateInactivityWindow()
		for _, row in ipairs(inactiveFrame.inactiveRows) do
			row:Hide()
			row:SetParent(trashFrame)
		end
		wipe(inactiveFrame.inactiveRows)

		if not IsInGuild() then
			return
		end

		local totalGuildMembers, _ = GetNumGuildMembers()
		totalGuildMembers = totalGuildMembers or 0

		local inactiveMembers = {}

		if totalGuildMembers > 0 then
			for i = 1, totalGuildMembers do
				local name, rankName, _, level, _, _, _, _, isOnline = GetGuildRosterInfo(i)

				if name and not isOnline then
					local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)
					yearsOffline = yearsOffline or 0
					monthsOffline = monthsOffline or 0
					daysOffline = daysOffline or 0
					hoursOffline = hoursOffline or 0

					local totalDays = (yearsOffline * 365) + (monthsOffline * 30) + daysOffline + (hoursOffline / 24)
					local isInactive = false
					local displayDuration = "Unbekannt"

					if yearsOffline > 0 then
						isInactive = true
						displayDuration = string.format("%d J", yearsOffline)
					elseif monthsOffline > 0 then
						isInactive = true
						displayDuration = string.format("%d M", monthsOffline)
					elseif daysOffline >= SchlingelInc.Constants.INACTIVE_DAYS_THRESHOLD then
						isInactive = true
						displayDuration = string.format("%d T", daysOffline)
					end

					if isInactive then
						local displayName = name
						if SchlingelInc and SchlingelInc.RemoveRealmFromName then
							displayName = SchlingelInc:RemoveRealmFromName(name)
						end
						table.insert(inactiveMembers, {
							name = displayName,
							fullName = name,
							level = level or 0,
							rank = rankName or "Unbekannt",
							displayDuration = displayDuration,
							sortableDays = totalDays
						})
					end
				end
			end
		end

		table.sort(inactiveMembers, function(a, b)
			if a.sortableDays == b.sortableDays then
				return (a.level or 0) > (b.level or 0)
			end
			return a.sortableDays > b.sortableDays
		end)

		local rowYOffset = 0
		local rowHeight = 20

		if #inactiveMembers > 0 then
			for i, member in ipairs(inactiveMembers) do
				local rowFrame = CreateFrame("Frame", nil, inactiveFrame.inactiveContainer)
				rowFrame:SetSize(inactiveFrame.inactiveContainer:GetWidth(), rowHeight)
				rowFrame:SetPoint("TOPLEFT", 0, rowYOffset)

				-- Name
				local nameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				nameText:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 0, 0)
				nameText:SetWidth(150)
				nameText:SetJustifyH("LEFT")
				nameText:SetText(member.name)

				-- Level
				local levelText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				levelText:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 160, 0)
				levelText:SetWidth(40)
				levelText:SetJustifyH("CENTER")
				levelText:SetText(member.level)

				-- Rank
				local rankText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				rankText:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 210, 0)
				rankText:SetWidth(120)
				rankText:SetJustifyH("LEFT")
				rankText:SetText(member.rank)

				-- Offline Duration
				local durationText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				durationText:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 340, 0)
				durationText:SetWidth(80)
				durationText:SetJustifyH("LEFT")
				durationText:SetText(member.displayDuration)

				-- Kick button (if player has permission)
				if CanGuildInvite() then
					local kickBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
					kickBtn:SetSize(80, rowHeight - 2)
					kickBtn:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 430, 0)
					kickBtn:SetText("Entfernen")
					kickBtn:SetScript("OnClick", function()
						-- Recheck permission at click time in case it changed
						if not CanGuildInvite() then
							SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR ..
								"Du hast keine Berechtigung mehr, Spieler zu entfernen.|r")
							return
						end
						StaticPopup_Show("CONFIRM_GUILD_KICK", member.fullName, nil, { memberName = member.fullName })
					end)
				end

				table.insert(inactiveFrame.inactiveRows, rowFrame)
				rowYOffset = rowYOffset - rowHeight
			end
			inactiveFrame.inactiveContainer:SetHeight(math.max(1, #inactiveMembers * rowHeight))
		else
			local noInactiveText = inactiveFrame.inactiveContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			noInactiveText:SetPoint("TOP", inactiveFrame.inactiveContainer, "TOP", 0, 0)
			noInactiveText:SetText("Keine inaktiven Mitglieder gefunden.")
			table.insert(inactiveFrame.inactiveRows, noInactiveText)
			inactiveFrame.inactiveContainer:SetHeight(20)
		end

		local totalHeight = math.abs(rowYOffset) + 50
		scrollChild:SetHeight(math.max(scrollFrame:GetHeight(), totalHeight))
		scrollFrame:SetVerticalScroll(0)
	end

	inactiveFrame.Update = UpdateInactivityWindow

	self.InactivityWindow = inactiveFrame
end

function SchlingelInc:ToggleInactivityWindow()
	if not self.InactivityWindow then
		self:CreateInactivityWindow()
	end

	-- Should not happen, but guard against nil
	if not self.InactivityWindow then
		return
	end

	if self.InactivityWindow:IsShown() then
		self.InactivityWindow:Hide()
	else
		self.InactivityWindow:Show()
		if self.InactivityWindow.Update then
			self.InactivityWindow:Update()
		end
	end
end
