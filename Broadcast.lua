-- Broadcast.lua
-- Officer command to broadcast a message to all guildmembers

SchlingelInc.Broadcast = SchlingelInc.Broadcast or {}

function SchlingelInc.Broadcast:Initialize()
    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
        function(_, prefix, message, _, _)
            if prefix ~= SchlingelInc.prefix then return end
            local valueStr = message:match("^BROADCAST|(.+)$")
            if not valueStr then return end
            -- Chat message
            SchlingelInc:Print(valueStr .. "|r")
            -- Onscreen message
            RaidNotice_AddMessage(RaidWarningFrame, valueStr, {r = 0.96, g = 0.55, b = 0.73}, 10)
        end, 0, "BroadcastReceive")
end

function SchlingelInc.Broadcast:Send(message)
    if not CanGuildInvite() then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Keine Berechtigung für diesen Befehl.|r")
        return
    end

    if not message or message == "" then return end

    SchlingelInc:SendAddonMessage("ALERT", "BROADCAST|" .. message, "GUILD", nil, "SchlingelInc-Broadcast")
    SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS .. "Broadcast-Nachricht an die Gilde gesendet.|r")
end

SLASH_SI1 = "/si"
SlashCmdList["SI"] = function(msg)
    local subcmd, rest = msg:match("^(%S+)%s*(.*)")
    if subcmd and subcmd:lower() == "broadcast" then
        SchlingelInc.Broadcast:Send(rest)
    end
end

SLASH_SIB1 = "/sib"
SlashCmdList["SIB"] = function(msg)
    SchlingelInc.Broadcast:Send(msg)
end