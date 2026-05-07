-- GuildCache.lua
-- Caching system for guild roster data for performance optimization
-- Reduces API calls through intelligent caching with 60 second lifetime

SchlingelInc.GuildCache = {
	members = {},           -- Cached guild member list (name -> true)
	fullRoster = {},        -- Full roster data with details
	lastUpdate = 0,         -- Timestamp of last cache update
	isUpdating = false      -- Flag to prevent concurrent updates
}

-- Checks if the cache is still valid
function SchlingelInc.GuildCache:IsValid()
	local now = GetTime()
	local age = now - self.lastUpdate
	return age < SchlingelInc.Constants.COOLDOWNS.GUILD_ROSTER_CACHE
end

-- Requests a roster update from the server
-- Data is automatically processed via the GUILD_ROSTER_UPDATE handler
function SchlingelInc.GuildCache:RequestUpdate()
	if self.isUpdating then
		return false
	end

	self.isUpdating = true
	C_GuildInfo.GuildRoster()
	return true
end

-- Processes roster data and fills the cache
function SchlingelInc.GuildCache:ProcessRosterData()
	-- Clear old data
	wipe(self.members)
	wipe(self.fullRoster)

	local numTotalMembers = GetNumGuildMembers()

	for i = 1, numTotalMembers do
		local name, rankName, rankIndex, level, classDisplayName, zone,
			  publicNote, officerNote, isOnline, status, class = GetGuildRosterInfo(i)

		if name then
			-- Remove realm name for easier comparison
			local shortName = SchlingelInc:RemoveRealmFromName(name)

			-- Store in fast lookup table
			self.members[shortName] = true

			-- Calculate last online data
			local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)
			yearsOffline = yearsOffline or 0
			monthsOffline = monthsOffline or 0
			daysOffline = daysOffline or 0
			hoursOffline = hoursOffline or 0

			local totalDaysOffline = (yearsOffline * 365) + (monthsOffline * 30) + daysOffline + (hoursOffline / 24)

			-- Store complete data
			table.insert(self.fullRoster, {
				name = shortName,
				fullName = name,
				rank = rankName,
				rankIndex = rankIndex,
				level = level,
				class = class,
				classDisplayName = classDisplayName,
				zone = zone,
				publicNote = publicNote,
				officerNote = officerNote,
				isOnline = isOnline,
				status = status,
				yearsOffline = yearsOffline,
				monthsOffline = monthsOffline,
				daysOffline = daysOffline,
				hoursOffline = hoursOffline,
				totalDaysOffline = totalDaysOffline
			})
		end
	end

	self.lastUpdate = GetTime()
	self.isUpdating = false
end

-- Returns the full roster list (as array with all details)
-- @return table Array with complete member data
function SchlingelInc.GuildCache:GetFullRoster()
	return self.fullRoster
end

-- Quickly checks if a player is in the guild
-- @param playerName string The player's name (with or without realm)
-- @return boolean true if player is in the guild
function SchlingelInc.GuildCache:IsGuildMember(playerName)
	if not playerName then return false end

	-- Remove realm name if present
	local shortName = SchlingelInc:RemoveRealmFromName(playerName)

	-- Check directly in cache
	return self.members[shortName] == true
end

-- Returns detailed information about a guild member
-- @param playerName string The player's name
-- @return table|nil Member data or nil if not found
function SchlingelInc.GuildCache:GetMemberInfo(playerName)
	if not playerName then return nil end

	local shortName = SchlingelInc:RemoveRealmFromName(playerName)
	local roster = self:GetFullRoster()

	for _, member in ipairs(roster) do
		if member.name == shortName then
			return member
		end
	end

	return nil
end

-- Returns all members with a specific rank
-- @param rankName string The rank name (e.g. "Devschlingel")
-- @return table Array with members of this rank
function SchlingelInc.GuildCache:GetMembersByRank(rankName)
	local roster = self:GetFullRoster()
	local result = {}

	for _, member in ipairs(roster) do
		if member.rank == rankName then
			table.insert(result, member)
		end
	end

	return result
end

-- Returns all online members
-- @return table Array with online members
function SchlingelInc.GuildCache:GetOnlineMembers()
	local roster = self:GetFullRoster()
	local result = {}

	for _, member in ipairs(roster) do
		if member.isOnline then
			table.insert(result, member)
		end
	end

	return result
end

-- Forces a cache refresh
function SchlingelInc.GuildCache:ForceRefresh()
	return self:RequestUpdate()
end

-- Returns cache statistics
-- @return table Statistics about the cache
function SchlingelInc.GuildCache:GetStats()
	local now = GetTime()
	local age = now - self.lastUpdate
	local isValid = self:IsValid()

	return {
		memberCount = #self.fullRoster,
		lastUpdate = self.lastUpdate,
		age = age,
		isValid = isValid,
		expiresIn = math.max(0, SchlingelInc.Constants.COOLDOWNS.GUILD_ROSTER_CACHE - age)
	}
end

-- Initializes the GuildCache module
function SchlingelInc.GuildCache:Initialize()
	-- Update on guild roster updates (fires automatically on login)
	-- Processes roster data whenever the event fires - keeps cache always up to date
	SchlingelInc.EventManager:RegisterHandler("GUILD_ROSTER_UPDATE",
		function()
			SchlingelInc.GuildCache:ProcessRosterData()
		end, 100, "GuildCacheAutoUpdate")

	-- Initial update on login
	SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
		function()
			-- Wait briefly after login, then request roster
			C_Timer.After(2, function()
				SchlingelInc.GuildCache:RequestUpdate()
			end)
		end, 90, "GuildCacheInit")
end
