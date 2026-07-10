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

function SchlingelInc.Death:SetRemote(targetName, valueStr)
	if not CanGuildInvite() then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Keine Berechtigung für diesen Befehl.|r")
		return
	end

	if not targetName or targetName == "" then return end

	local value = tonumber(valueStr)
	if not value then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Ungültige Zahl: " .. tostring(valueStr) .. "|r")
		return
	end

	if value < 0 or value > 999999 then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Wert muss zwischen 0 und 999999 liegen.|r")
		return
	end

	ChatThrottleLib:SendAddonMessage("ALERT", SchlingelInc.prefix, "DEATHSET|" .. tostring(value), "WHISPER", targetName, "SchlingelInc-Schande")
	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS .. "Deathset-Nachricht an " .. targetName .. " gesendet.|r")
end