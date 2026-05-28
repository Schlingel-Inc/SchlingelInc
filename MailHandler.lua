SchlingelInc.MailHandler = {}

local mailboxAddons = {
        "TradeSkillMaster",
        "Postal"
}

function SchlingelInc.MailHandler:HideMinimapMail()
	local mail = MiniMapMailFrame or MiniMapMailIcon
	if not mail then return end

	-- Stop Blizzard from updating/showing it
	if mail.UnregisterAllEvents then
		mail:UnregisterAllEvents()
	end

	-- Hide it now
	mail:Hide()

	-- Make it non-interactive
	mail:SetAlpha(0)
	mail:SetScript("OnEnter", nil)
	mail:SetScript("OnLeave", nil)

	-- Prevent future :Show() calls
	if mail.Show then
		mail.Show = function() end
	end
end

-- Check for active mailbox addons
function SchlingelInc.MailHandler:MailboxAddonActive()
    local detectedAddons = {}
    for _, addonName in ipairs(mailboxAddons) do
        if C_AddOns.IsAddOnLoaded(addonName) then
            table.insert(detectedAddons, addonName)
        end
    end

    return detectedAddons
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("MAIL_INBOX_UPDATE")

-- Returns true if the mail at index is safe to leave in the inbox (self, guild member, system, or already read).
local function IsSafeSender(index)
    -- indices: 3=sender, 9=wasRead, 12=canReply, 13=isGM
    local _, _, sender, _, _, _, _, _, wasRead, _, _, canReply, isGM = GetInboxHeaderInfo(index)

    if isGM then return true end          -- official Blizzard mail
    if not canReply then return true end  -- system mail (AH, postmaster, NPCs)
    if not sender or sender == "" then return true end
    if sender == UnitName("player") then return true end
    if wasRead then return true end
    if SchlingelInc.GuildCache:IsGuildMember(sender) then return true end

    return false
end

-- Eigenes Warn-Popup, wenn man auf eine "fremde" Mail klickt
StaticPopupDialogs["CONFIRM_DELETE_NON_GUILD_MAIL"] = {
    text = "|cffff0000HINWEIS:|r Post von Nicht-Gildenmitglied!\n\nDiese Post muss entfernt werden.",
    button1 = "Entfernen",
    button2 = "Abbrechen",
    OnAccept = function(_, data)
        if data and data.slot then
            if InboxItemCanDelete(data.slot) then
                DeleteInboxItem(data.slot)
            else
                ReturnInboxItem(data.slot)
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- Macht "Alle öffnen"-Buttons unbrauchbar, um Unfälle zu vermeiden
local function KillButton(btn)
    if not btn or btn.isDead then return end
    btn:Disable()
    btn:SetAlpha(0.3)

    -- Wir legen einen unsichtbaren Blocker drüber, damit auch andere Addons nicht drankommen
    local blocker = CreateFrame("Button", nil, btn)
    blocker:SetAllPoints()
    blocker:SetFrameLevel(btn:GetFrameLevel() + 2)
    blocker:EnableMouse(true)
    blocker:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("|cffff0000Dieser Button ist gesperrt!", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    blocker:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Verhindert, dass der Button wieder aktiviert wird
    hooksecurefunc(btn, "Enable", function() btn:Disable() end)
    btn.isDead = true
end

local sendMailGuard

local function IsAllowedRecipient()
    local recipient = SendMailNameEditBox and SendMailNameEditBox:GetText() or ""
    recipient = recipient:gsub("^%s+", ""):gsub("%s+$", "")

    if recipient == "" then return false end

    if recipient:find("-", 1, true) then
        local normalizedRecipient = string.lower(recipient)
        for _, member in ipairs(SchlingelInc.GuildCache:GetFullRoster() or {}) do
            if member.fullName and string.lower(member.fullName) == normalizedRecipient then
                return true
            end
        end
        return false
    end

    return SchlingelInc.GuildCache:IsGuildMember(recipient)
end

local function UpdateSendMailGuard()
    if not SendMailMailButton then return end

    if not sendMailGuard then
        sendMailGuard = CreateFrame("Button", nil, SendMailMailButton)
        sendMailGuard:SetAllPoints()
        sendMailGuard:SetFrameLevel(SendMailMailButton:GetFrameLevel() + 10)
        sendMailGuard:EnableMouse(true)
        sendMailGuard:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("|cffff0000Post darf nur an Gildenmitglieder gesendet werden.|r", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        sendMailGuard:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    if tonumber(SchlingelInc.InfoRules.mailRule) == 2 and not IsAllowedRecipient() then
        sendMailGuard:Show()
    else
        sendMailGuard:Hide()
    end
end

-- Geht die aktuelle Post-Seite durch
local function UniversalScan()
    if not MailFrame:IsVisible() then return end

    UpdateSendMailGuard()

    if tonumber(SchlingelInc.InfoRules.mailRule) ~= 2 then
        local itemsPerPage = INBOXITEMS_TO_DISPLAY or 7
        for i = 1, itemsPerPage do
            local button = _G["MailItem"..i.."Button"]
            if button and button.mailGuard then button.mailGuard:Hide() end
        end
        return
    end

    -- Wie viele Items sind insgesamt da?
    local numItems = GetInboxNumItems()
    
    -- Wie viele Items werden pro Seite angezeigt? (Standard ist 7)
    local itemsPerPage = INBOXITEMS_TO_DISPLAY

    -- Aktuelle Seite berechnen (Blizzard speichert das in InboxFrame.pageNum)
    local currentPage = InboxFrame.pageNum or 1

    -- Wir loopen NUR über die 7 sichtbaren Buttons
    for i = 1, itemsPerPage do
        local mailIndex = ((currentPage - 1) * itemsPerPage) + i
        
        -- Nur fortfahren, wenn der berechnete Index nicht über der Gesamtzahl liegt
        if mailIndex <= numItems then
            local item = _G["MailItem"..i]
            local senderText = _G["MailItem"..i.."Sender"]
            local button = _G["MailItem"..i.."Button"]

            if item and button then
                local _, _, _, subject, _, _, _, itemCount = GetInboxHeaderInfo(mailIndex)
                
                if not IsSafeSender(mailIndex) then
                    -- Fremder Absender: Name wird rot
                    if senderText then senderText:SetTextColor(1, 0, 0) end

                    if not button.mailGuard then
                        button.mailGuard = CreateFrame("Button", nil, button)
                        button.mailGuard:SetAllPoints()
                        button.mailGuard:SetFrameLevel(button:GetFrameLevel() + 10)
                        button.mailGuard:EnableMouse(true)
                    end

                    button.mailGuard:SetScript("OnClick", function()
                        local d = StaticPopup_Show("CONFIRM_DELETE_NON_GUILD_MAIL")
                        if d then d.data = {slot = mailIndex, itemCount = itemCount} end
                    end)
                    button.mailGuard:Show()
                else
                    -- Sicherer Absender
                    if senderText then senderText:SetTextColor(1, 0.8, 0) end
                    if button.mailGuard then button.mailGuard:Hide() end
                end
            end
        else
            -- Falls weniger als 7 Briefe auf der aktuellen Seite sind (z.B. letzte Seite)
            -- müssen wir die Guards der leeren Zeilen verstecken
            local button = _G["MailItem"..i.."Button"]
            if button and button.mailGuard then button.mailGuard:Hide() end
        end
    end

    -- Sucht nach "Open All" Buttons (nur im Mailbox-Bereich) und deaktiviert sie
    if MailFrame and MailFrame:IsVisible() then
        -- Check known mail addon buttons
        local mailButtons = {
            "OpenAllMail",              -- Common addon button
            "AutoLootMailButton"
        }

        for _, btnName in ipairs(mailButtons) do
            local btn = _G[btnName]
            if btn and btn:IsVisible() then
                KillButton(btn)
            end
        end

        -- Scan only frames that are children of MailFrame
        local f = MailFrame:GetChildren()
        if f then
            for i = 1, select("#", MailFrame:GetChildren()) do
                local child = select(i, MailFrame:GetChildren())
                if child and child:IsObjectType("Button") and child:IsVisible() then
                    local txt = child.GetText and child:GetText()
                    local name = child.GetName and child:GetName() or ""
                    if txt and (txt:find("Open All") or txt:find("Alle öffnen")) or
                       name:find("OpenAll") then
                        if not name:find("MailItem") then
                            KillButton(child)
                        end
                    end
                end
            end
        end
    end
end

-- Delayed Scan
local function DelayedScan()
    C_Timer.After(0.05, UniversalScan)
end

-- Event-Handler
frame:SetScript("OnEvent", function(_, event)
    if event == "MAIL_INBOX_UPDATE" then
        DelayedScan()
    end
end)

-- Hook auf das MailFrame
MailFrame:HookScript("OnShow", DelayedScan)

-- Diese Funktion wird von Blizzard jedes Mal aufgerufen, wenn die Inbox sich optisch aktualisiert
hooksecurefunc("InboxFrame_Update", function()
    DelayedScan()
end)

-- Falls irgendein Addon noch was macht
if MailFrameTab1 then
    MailFrameTab1:HookScript("OnClick", DelayedScan)
end

if MailFrameTab2 then
    MailFrameTab2:HookScript("OnClick", function()
        C_Timer.After(0.05, UpdateSendMailGuard)
    end)
end

if SendMailFrame then
    SendMailFrame:HookScript("OnShow", UpdateSendMailGuard)
end

if SendMailNameEditBox then
    SendMailNameEditBox:HookScript("OnTextChanged", UpdateSendMailGuard)
end

local errorListener = CreateFrame("Frame")
errorListener:RegisterEvent("UI_ERROR_MESSAGE")
errorListener:SetScript("OnEvent", function(_, _, messageType, msg)
    if msg == ERR_MAIL_TARGET_NOT_FOUND then
        if UIErrorsFrame then UIErrorsFrame:Clear() end
        
        SchlingelInc:Print("Diese Mail kann nicht gelöscht werden, da sie bereits geöffnet war und der Charakter mittlerweile gelöscht wurde! Ein Bezug zur Gilde ist nicht mehr nachvollziehbar")
    end
end)