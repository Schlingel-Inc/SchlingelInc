-- Define slash command
SLASH_DEATHSET1 = '/deathset'
SlashCmdList["DEATHSET"] = function(msg)
	if not CanGuildInvite() then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Keine Berechtigung für diesen Befehl.|r")
		return
	end

	local targetName, valueStr = msg:match("^(%S+)%s+(%S+)$")
	if not targetName or not valueStr then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Verwendung: /deathset <Spielername> <Zahl>|r")
		return
	end

	local inputValue = tonumber(valueStr)
	if not inputValue then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Ungültige Zahl: " .. valueStr .. "|r")
		return
	end

	if inputValue < 0 or inputValue > 999999 then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Wert muss zwischen 0 und 999999 liegen.|r")
		return
	end

	C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "DEATHSET|" .. tostring(inputValue), "WHISPER", targetName)
	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS .. "Deathset-Nachricht an " .. targetName .. " gesendet.|r")
end