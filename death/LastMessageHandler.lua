SchlingelInc.LastMessageHandler = SchlingelInc.LastMessageHandler or {}

SchlingelInc.LastMessageHandler.LastWords = ""

local function IsOwnSender(sender)
	local name = UnitName("player")
	if not name then return false end
	return sender == name or sender:match("^" .. name .. "%-") ~= nil
end

SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_SAY", function(_, msg, sender)
	if IsOwnSender(sender) then
		SchlingelInc.LastMessageHandler.LastWords = msg
	end
end, 0, "LastWordsSay")

SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_GUILD", function(_, msg, sender)
	local senderBase = sender:match("^([^-]+)") or sender
	local name = UnitName("player")
	if name and senderBase == name then
		SchlingelInc.LastMessageHandler.LastWords = msg
	end
end, 0, "LastWordsGuild")

SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_PARTY", function(_, msg, sender)
	if IsOwnSender(sender) then
		SchlingelInc.LastMessageHandler.LastWords = msg
	end
end, 0, "LastWordsParty")

SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_RAID", function(_, msg, sender)
	if IsOwnSender(sender) then
		SchlingelInc.LastMessageHandler.LastWords = msg
	end
end, 0, "LastWordsRaid")