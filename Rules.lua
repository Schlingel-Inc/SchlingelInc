-- Global table for rules
SchlingelInc.Rules = {}

SchlingelInc.InfoRules = {
    mailRule = 1,
    auctionHouseRule = 1,
    tradeRule = 1,
    groupingRule = 1
}

-- Current level cap (fetched from guild info)
SchlingelInc.Rules.CurrentCap = 0

function SchlingelInc.Rules:GetRules(callback)
    local text = GetGuildInfoText()
    if text == nil or text == "" then
        if callback then
            C_Timer.After(2, function()
                SchlingelInc.Rules:GetRules(callback)
            end)
            return nil
        else
            C_Timer.After(2, function()
                SchlingelInc.Rules:GetRules()
            end)
            return nil
        end
    end

    if callback then
        callback(text)
        return nil
    end

    return text
end

function SchlingelInc.Rules:LoadFromGuildInfo()
    SchlingelInc.Rules:GetRules(function(text)
        if not text then
            return
        end

        local mailRule,auctionHouseRule,tradeRule,groupingRule = text:match("Schlingel:%s*(%d+)%s*,?%s*(%d+)%s*,?%s*(%d+)%s*,?%s*(%d+)")
        mailRule,auctionHouseRule,tradeRule,groupingRule = tonumber(mailRule), tonumber(auctionHouseRule), tonumber(tradeRule), tonumber(groupingRule)

        SchlingelInc.InfoRules.mailRule = mailRule
        SchlingelInc.InfoRules.auctionHouseRule = auctionHouseRule
        SchlingelInc.InfoRules.tradeRule = tradeRule
        SchlingelInc.InfoRules.groupingRule = groupingRule

        -- Extract and store CurrentCap from guild info
        local currentCap = text:match("Aktuelles Bracket:.-Level%s*(%d+)")
        if currentCap then
            SchlingelInc.Rules.CurrentCap = tonumber(currentCap)
            SchlingelInc.LevelUps:CheckForCap(UnitLevel("player"))
        end

        SchlingelInc:Print("Regeln geladen")
    end)
end

-- Rule: Completely prohibit mailbox usage
function SchlingelInc.Rules:ProhibitMailboxUsage()
    CloseMail()
    SchlingelInc.Popup:Show({
        title = "Briefkasten gesperrt!",
        message = "Die Nutzung des Briefkastens ist nicht erlaubt."
    })
end

-- Rule: Prohibit auction house usage
function SchlingelInc.Rules:ProhibitAuctionhouseUsage()
    if tonumber(SchlingelInc.InfoRules.auctionHouseRule) == 0 then
        return
    end

    if CloseAuctionHouse then
        CloseAuctionHouse()
    end
    if AuctionFrame and AuctionFrame:IsShown() then
        AuctionFrame:Hide()
    end
    SchlingelInc.Popup:Show({
        title = "Auktionshaus gesperrt!",
        message = "Die Nutzung des Auktionshauses ist nicht erlaubt."
    })
end

-- Rule: Prohibit trading with players outside the guild
function SchlingelInc.Rules:ProhibitTradeWithNonGuildMembers()
    if tonumber(SchlingelInc.InfoRules.tradeRule) == 0 then
        return
    end

    local inPvP = SchlingelInc:IsInBattleground() or SchlingelInc:IsInRaid() or SchlingelInc:IsInArena()
    if inPvP then return end

    local tradePartner = UnitName("NPC")
    if tradePartner then
        local isInGuild = C_GuildInfo.MemberExistsByName(tradePartner)
        if not isInGuild then
            CancelTrade()
            SchlingelInc.Popup:Show({
                title = "Handel blockiert!",
                message = "Du kannst nur mit Gildenmitgliedern handeln."
            })
        end
    end
end

-- Rule: Prohibit grouping with players outside the guild
function SchlingelInc.Rules:ProhibitGroupingWithNonGuildMembers()
   if tonumber(SchlingelInc.InfoRules.groupingRule) == 0 then
        return
    end
    -- Request fresh guild roster data
    C_GuildInfo.GuildRoster()

    -- Build list of all guild members
    local guildMembers = {}
    local numTotalGuildMembers = GetNumGuildMembers()
    for i = 1, numTotalGuildMembers do
        local name = GetGuildRosterInfo(i)
        if name then
            table.insert(guildMembers, SchlingelInc:RemoveRealmFromName(name))
        end
    end

    -- Check all group members
    local numGroupMembers = GetNumGroupMembers()
    for i = 1, numGroupMembers do
        local unit = "party" .. i
        if not UnitExists(unit) then
            unit = "raid" .. i
        end

        -- Skip disconnected players - they'll be checked again when they reconnect
        if UnitExists(unit) and not UnitIsConnected(unit) then
            -- Player is offline/disconnected, don't kick them
        else
            local memberName = UnitName(unit)
            -- Skip if name is not yet available (loading state)
            if memberName and memberName ~= UNKNOWNOBJECT and memberName ~= "" then
                local shortMemberName = SchlingelInc:RemoveRealmFromName(memberName)
                local isInGuild = tContains(guildMembers, shortMemberName)

                if not isInGuild then
                    LeaveParty()
                    SchlingelInc.Popup:Show({
                        title = "Gruppe verlassen!",
                        message = "Du kannst nur mit Gildenmitgliedern in einer Gruppe sein.",
                        displayTime = 3
                    })
                    return
                end
            end
        end
    end
end

function SchlingelInc.Rules:AutoDeclineDuels()
	if(not SchlingelOptionsDB.auto_decline_duels) then
		return
	end

	CancelDuel()
end

-- Initialize rules
function SchlingelInc.Rules:Initialize()
    SchlingelInc.Rules:LoadFromGuildInfo()

    if tonumber(SchlingelInc.InfoRules.mailRule) == 1 or #SchlingelInc.MailHandler:MailboxAddonActive() > 0 then
        SchlingelInc.MailHandler:HideMinimapMail()
        SchlingelInc.EventManager:RegisterHandler("MAIL_SHOW", function()
            SchlingelInc.Rules:ProhibitMailboxUsage()
            end, 0, "RuleMailbox")
    end


	SchlingelInc.EventManager:RegisterHandler("AUCTION_HOUSE_SHOW",
		function()
			SchlingelInc.Rules:ProhibitAuctionhouseUsage()
		end, 0, "RuleAuctionHouse")

	SchlingelInc.EventManager:RegisterHandler("TRADE_SHOW",
		function()
			SchlingelInc.Rules:ProhibitTradeWithNonGuildMembers()
		end, 0, "RuleTrade")

	-- Instantly decline party invites from non-guild members
	SchlingelInc.EventManager:RegisterHandler("PARTY_INVITE_REQUEST",
		function(event, sender)
            if tonumber(SchlingelInc.InfoRules.groupingRule) == 0 then
                return
            end

			local isInGuild = SchlingelInc.GuildCache:IsGuildMember(sender)
			if not isInGuild then
				StaticPopup_Hide("PARTY_INVITE")
				DeclineGroup()
			end
		end, 0, "PartyInviteCheck")

	-- Check group members on roster updates
	SchlingelInc.EventManager:RegisterHandler("GROUP_ROSTER_UPDATE",
		function()
			SchlingelInc.Rules:ProhibitGroupingWithNonGuildMembers()
		end, 0, "GroupRosterCheck")

	SchlingelInc.EventManager:RegisterHandler("RAID_ROSTER_UPDATE",
		function()
			SchlingelInc.Rules:ProhibitGroupingWithNonGuildMembers()
		end, 0, "RaidRosterCheck")

    SchlingelInc.EventManager:RegisterHandler("DUEL_REQUESTED",
		function()
			SchlingelInc.Rules:AutoDeclineDuels()
		end, 0, "DuelAutoDecline")
end