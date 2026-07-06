SchlingelInc.DeathSlashCommands = SchlingelInc.DeathSlashCommands or {}

function SchlingelInc.DeathSlashCommands:Initialize()
    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
        function(_, prefix, message, _, _)
            if prefix ~= SchlingelInc.prefix then return end
            local valueStr = message:match("^DEATHSET|(.+)$")
            if not valueStr then return end
            local value = tonumber(valueStr)
            if value and value >= 0 and value <= 999999 then
                CharacterDeaths = value
                SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS .. "Deathcounter auf " .. CharacterDeaths .. " gesetzt.|r")
            end
        end, 0, "DeathSetReceive")
end

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