-- GuildCache.lua
SchlingelInc.GuildCache = {
	members = {},           -- name -> true for fast lookup
	fullRoster = {},
	lastUpdate = 0,
	isUpdating = false
}

function SchlingelInc.GuildCache:IsValid()
	local now = GetTime()
	local age = now - self.lastUpdate
	return age < SchlingelInc.Constants.COOLDOWNS.GUILD_ROSTER_CACHE
end

-- RequestUpdate sets isUpdating so GUILD_ROSTER_UPDATE doesn't pile up
function SchlingelInc.GuildCache:RequestUpdate()
	if self.isUpdating then
		return false
	end

	self.isUpdating = true
	C_GuildInfo.GuildRoster()
	return true
end

function SchlingelInc.GuildCache:ProcessRosterData()
	wipe(self.members)
	wipe(self.fullRoster)

	local numTotalMembers = GetNumGuildMembers()

	for i = 1, numTotalMembers do
		local name, rankName, rankIndex, level, classDisplayName, zone,
			  publicNote, officerNote, isOnline, status, class = GetGuildRosterInfo(i)

		if name then
			local shortName = SchlingelInc:RemoveRealmFromName(name)
			self.members[shortName] = true

			local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)
			yearsOffline = yearsOffline or 0
			monthsOffline = monthsOffline or 0
			daysOffline = daysOffline or 0
			hoursOffline = hoursOffline or 0

			local totalDaysOffline = (yearsOffline * 365) + (monthsOffline * 30) + daysOffline + (hoursOffline / 24)

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

function SchlingelInc.GuildCache:GetFullRoster()
	return self.fullRoster
end

function SchlingelInc.GuildCache:IsGuildMember(playerName)
	if not playerName then return false end
	local shortName = SchlingelInc:RemoveRealmFromName(playerName)
	return self.members[shortName] == true
end

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

function SchlingelInc.GuildCache:ForceRefresh()
	return self:RequestUpdate()
end

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

function SchlingelInc.GuildCache:Initialize()
	SchlingelInc.EventManager:RegisterHandler("GUILD_ROSTER_UPDATE",
		function()
			SchlingelInc.GuildCache:ProcessRosterData()
		end, 100, "GuildCacheAutoUpdate")

	SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
		function()
			C_Timer.After(2, function()
				SchlingelInc.GuildCache:RequestUpdate()
			end)
		end, 90, "GuildCacheInit")

	-- Refresh roster when the player joins or leaves a guild mid-session.
	SchlingelInc.EventManager:RegisterHandler("PLAYER_GUILD_UPDATE",
		function()
			C_Timer.After(1, function()
				SchlingelInc.GuildCache:RequestUpdate()
			end)
		end, 90, "GuildCacheGuildUpdate")
end
