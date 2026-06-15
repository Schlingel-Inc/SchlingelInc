-- Debug.lua
-- Central debug module for developers
-- All debug commands are only available for players with the guild rank "Devschlingel"

SchlingelInc.Debug = {}

-- Checks if the player has debug permission
function SchlingelInc.Debug:HasPermission()
	local _, rank = GetGuildInfo("player")
	return rank == "DevSchlingel" or rank == "Devschlingel"
end

-- Shows a permission error message
local function ShowPermissionError()
	SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR ..
		"Der Debugmodus ist den Devschlingeln vorbehalten.|r")
end

-- Initializes the debug module
function SchlingelInc.Debug:Initialize()
	-- Debug mode toggle
	SchlingelInc.Debug.enabled = false

	-- Main command: /schlingeldebug
	SLASH_SCHLINGELDEBUG1 = '/schlingeldebug'
	SlashCmdList["SCHLINGELDEBUG"] = function(msg)
		if not SchlingelInc.Debug:HasPermission() then
			ShowPermissionError()
			return
		end

		local args = {}
		for word in msg:gmatch("%S+") do
			table.insert(args, word)
		end

		local command = args[1] or "help"

		if command == "help" then
			SchlingelInc.Debug:ShowHelp()
		elseif command == "rules" then
			SchlingelInc.Debug:ShowRules()
		elseif command == "toggle" then
			SchlingelInc.Debug:ToggleDebugMode()
		elseif command == "eventdebug" then
			SchlingelInc.EventManager:DebugInfo()
		elseif command == "deathframe" then
			SchlingelInc.Debug:TestDeathFrame()
		elseif command == "levelup" then
			SchlingelInc.Debug:TestLevelUpFrame()
		elseif command == "cap" then
			SchlingelInc.Debug:TestCapFrame()
		elseif command == "deathset" then
			local value = tonumber(args[2])
			if value then
				SchlingelInc.Debug:SetDeathCount(value)
			else
				SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR ..
					"Invalid number. Use: /schlingeldebug deathset <number>|r")
			end
		elseif command == "guildrequest" then
			SchlingelInc.Debug:TestGuildRequest(args[2])
		elseif command == "events" then
			local sub = args[2] or "start"
			if sub == "start" then
				SchlingelInc.Debug:StartEventTracking()
			elseif sub == "stop" then
				SchlingelInc.Debug:StopEventTracking()
			else
				SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Usage: /schlingeldebug events [start|stop]|r")
			end
		elseif command == "cachestats" then
			SchlingelInc.Debug:ShowCacheStats()
		elseif command == "cacherefresh" then
			SchlingelInc.GuildCache:ForceRefresh()
			SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS .. "Guild cache refresh forced|r")
		else
			SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING ..
				"Unknown command. Use /schlingeldebug help for help.|r")
		end
	end

	-- Alias: /sdebug
	SLASH_SDEBUG1 = '/sdebug'
	SlashCmdList["SDEBUG"] = SlashCmdList["SCHLINGELDEBUG"]
end

-- Shows debug help
function SchlingelInc.Debug:ShowHelp()
	print(SchlingelInc.Constants.COLORS.INFO .. "=== SchlingelInc Debug Commands ===" .. "|r")
	print(SchlingelInc.colorCode .. "/schlingeldebug help" .. "|r - Shows this help")
	print(SchlingelInc.colorCode .. "/schlingeldebug toggle" .. "|r - Enables/Disables debug mode")
	print(SchlingelInc.colorCode .. "/schlingeldebug eventdebug" .. "|r - Shows EventManager debug info")
	print(SchlingelInc.colorCode .. "/schlingeldebug deathframe" .. "|r - Test death announcement frame")
	print(SchlingelInc.colorCode .. "/schlingeldebug levelup" .. "|r - Test level-up announcement frame")
	print(SchlingelInc.colorCode .. "/schlingeldebug cap" .. "|r - Test cap announcement frame")
	print(SchlingelInc.colorCode .. "/schlingeldebug deathset <number>" .. "|r - Sets the death counter")
	print(SchlingelInc.colorCode .. "/schlingeldebug guildrequest <name>" .. "|r - Tests guild request to an officer")
	print(SchlingelInc.colorCode .. "/schlingeldebug events [start|stop]" .. "|r - Track all fired WoW events in chat")
	print(SchlingelInc.colorCode .. "/schlingeldebug cachestats" .. "|r - Shows guild cache statistics")
	print(SchlingelInc.colorCode .. "/schlingeldebug cacherefresh" .. "|r - Forces guild cache refresh")
	print(SchlingelInc.Constants.COLORS.WARNING .. "Alias: /sdebug <command>" .. "|r")
end

-- Shows active rules
function SchlingelInc.Debug:ShowRules()
	print(SchlingelInc.Constants.COLORS.INFO .. "=== SchlingelInc Rules ===" .. "|r")
	print(SchlingelInc.colorCode .. "Mailbox Rule: " .. SchlingelInc.InfoRules.mailRule .. "|r")
	print(SchlingelInc.colorCode .. "Auction House Rule: " .. SchlingelInc.InfoRules.auctionHouseRule .. "|r")
	print(SchlingelInc.colorCode .. "Trade Rule: " .. SchlingelInc.InfoRules.tradeRule .. "|r")
	print(SchlingelInc.colorCode .. "Grouping Rule: " .. SchlingelInc.InfoRules.groupingRule .. "|r")
	print(SchlingelInc.colorCode .. "Blocked Trader Rule: " .. SchlingelInc.InfoRules.blockedTraderRule .. "|r")
end

-- Enables/Disables debug mode
function SchlingelInc.Debug:ToggleDebugMode()
	SchlingelInc.Debug.enabled = not SchlingelInc.Debug.enabled
	local status = SchlingelInc.Debug.enabled and "enabled" or "disabled"
	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
		"Debug mode " .. status .. "|r")
end

-- Tests the death announcement frame
function SchlingelInc.Debug:TestDeathFrame()
	local testNames = {"Pudidev", "Cricksumage", "Totanka", "Kurtibrown"}
	local testClasses = {"Krieger", "Magier", "Schamane", "Jäger"}
	local testZones = {"Durotar", "Brachland", "Mulgore", "Tirisfal"}

	local name = testNames[math.random(#testNames)]
	local class = testClasses[math.random(#testClasses)]
	local level = math.random(1, SchlingelInc.Constants.MAX_LEVEL)
	local zone = testZones[math.random(#testZones)]

	SchlingelInc.DeathAnnouncement:ShowDeathMessage(
		string.format("%s der %s ist mit Level %s in %s gestorben.", name, class, level, zone))

	-- Add to death log (insert at position 1 so newest is first)
	SchlingelInc.DeathLogData = SchlingelInc.DeathLogData or {}
	table.insert(SchlingelInc.DeathLogData, 1, {
		name = name,
		class = class,
		level = level,
		zone = zone,
		cause = "Test-Eber"
	})
	SchlingelInc:UpdateMiniDeathLog()

	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
		"Test death frame shown for " .. name .. "|r")
end

-- Tests the level-up announcement frame
function SchlingelInc.Debug:TestLevelUpFrame()
	local testNames = {"Pudidev", "Cricksumage", "Totanka", "Kurtibrown"}
	local name = testNames[math.random(#testNames)]
	local level = SchlingelInc.Constants.LEVEL_MILESTONES[math.random(#SchlingelInc.Constants.LEVEL_MILESTONES - 1)]

	SchlingelInc.LevelUpAnnouncement:ShowMessage(name, level)

	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
		"Test level-up frame shown for " .. name .. " (Level " .. level .. ")|r")
end

-- Tests the cap announcement frame
function SchlingelInc.Debug:TestCapFrame()
	local testNames = {"Pudidev", "Cricksumage", "Totanka", "Kurtibrown"}
	local name = testNames[math.random(#testNames)]

	SchlingelInc.LevelUpAnnouncement:ShowCap(name, SchlingelInc.Constants.MAX_LEVEL)

	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
		"Test cap frame shown for " .. name .. "|r")
end

-- Sets the death counter
function SchlingelInc.Debug:SetDeathCount(value)
	if value < 0 or value > 999999 then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR ..
			"Value must be between 0 and 999999|r")
		return
	end

	CharacterDeaths = value
	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
		"Death counter set to " .. CharacterDeaths .. "|r")
end

-- Tests guild request
function SchlingelInc.Debug:TestGuildRequest(targetName)
	if not targetName then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR ..
			"Please provide a target name: /schlingeldebug guildrequest <name>|r")
		return
	end

	local playerName = UnitName("player")
	local playerLevel = UnitLevel("player")
	local playerExp = UnitXP("player")
	local zone = SchlingelInc.GuildRecruitment:GetPlayerZone()

	local message = string.format("INVITE_REQUEST:%s:%d:%d:%s",
		playerName, playerLevel, playerExp, zone)

	C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", targetName)

	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
		"Test guild request sent to " .. targetName .. "|r")
end

-- Shows guild cache statistics
function SchlingelInc.Debug:ShowCacheStats()
	local stats = SchlingelInc.GuildCache:GetStats()

	print(SchlingelInc.Constants.COLORS.INFO .. "=== Guild Cache Statistics ===" .. "|r")
	print(string.format("Members in cache: %d", stats.memberCount))
	print(string.format("Last update: %.1f seconds ago", stats.age))
	print(string.format("Cache valid: %s", stats.isValid and "Yes" or "No"))

	if stats.isValid then
		print(string.format("Cache expires in: %.1f seconds", stats.expiresIn))
	else
		print(SchlingelInc.Constants.COLORS.WARNING .. "Cache expired and will be updated on next access" .. "|r")
	end

	-- Show some online members as example
	local onlineMembers = SchlingelInc.GuildCache:GetOnlineMembers()
	print(string.format("Online members: %d", #onlineMembers))

	print("=======================================")
end

-- Debug print function (only when debug mode is enabled)
function SchlingelInc.Debug:Print(message)
	if SchlingelInc.Debug.enabled then
		print(SchlingelInc.Constants.COLORS.WARNING .. "[DEBUG]|r " .. message)
	end
end

-- Event tracker: hooks all WoW events and prints them to chat
local eventTrackerFrame
function SchlingelInc.Debug:StartEventTracking()
	if eventTrackerFrame then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING .. "Event tracking is already running. Use /schlingeldebug events stop to stop.|r")
		return
	end
	eventTrackerFrame = CreateFrame("Frame", "SchlingelIncEventTracker")
	eventTrackerFrame:RegisterAllEvents()
	eventTrackerFrame:SetScript("OnEvent", function(_, event, ...)
		print(SchlingelInc.Constants.COLORS.INFO .. "[EVENT]|r " .. event)
	end)
	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS .. "Event tracking started. Use /schlingeldebug events stop to stop.|r")
end

function SchlingelInc.Debug:StopEventTracking()
	if not eventTrackerFrame then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING .. "Event tracking is not running.|r")
		return
	end
	eventTrackerFrame:UnregisterAllEvents()
	eventTrackerFrame = nil
	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS .. "Event tracking stopped.|r")
end
