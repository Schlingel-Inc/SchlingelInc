-- DiscordHandlePrompt.lua
-- Backend logic for Discord handle and pronouns.
-- UI / login prompts are handled by SetupWizard.lua.

-- Get the account-wide Discord handle
function SchlingelInc:GetDiscordHandle()
    return DiscordHandle
end

-- Set the account-wide Discord handle and clear the guild note
function SchlingelInc:SetDiscordHandle(handle)
    DiscordHandle = handle
    SchlingelInc:ClearGuildNote()
    SchlingelInc.GuildProfiles:Broadcast()
end

-- Set preferred pronouns
function SchlingelInc:SetPreferredPronouns(pronouns)
    Pronouns = pronouns
    SchlingelInc:ClearGuildNote()
end

-- Returns handle with pronouns appended if present: "myhandle (he/him)" or "myhandle"
-- Returns nil if no handle is set
function SchlingelInc:GetFormattedHandle()
    local handle = DiscordHandle or ""
    if handle == "" then return nil end
    local pronouns = Pronouns or ""
    if pronouns ~= "" then
        return string.format("%s (%s)", handle, pronouns)
    end
    return handle
end

-- Wipes the guild note (called once to migrate away from note-based storage).
function SchlingelInc:ClearGuildNote()
    local playerName = UnitName("player")
    if not playerName or not IsInGuild() then return end

    C_Timer.After(2, function()
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local name = GetGuildRosterInfo(i)
            if name then
                local shortName = SchlingelInc:RemoveRealmFromName(name)
                if shortName == playerName then
                    GuildRosterSetPublicNote(i, "")
                    return
                end
            end
        end
    end)
end

-- Legacy: kept so old code referencing UpdateGuildNote doesn't break during migration.
function SchlingelInc:UpdateGuildNote()
    SchlingelInc:ClearGuildNote()
end

-- Parses an old-format guild note and returns handle, pronouns, deaths (or nil).
-- Used only for one-time migration on first login after update.
function SchlingelInc:ParseGuildNote(note)
    if not note or note == "" then return nil end

    local handle, pronouns, deaths = note:match("^(.-)%s+%((.-)%)%s+Tode:%s*(%d+)%s*$")
    if handle and handle ~= "" then
        return handle, pronouns, tonumber(deaths)
    end

    handle, deaths = note:match("^(.-)%s+%(Tode:%s*(%d+)%)%s*$")
    if handle and handle ~= "" then
        return handle, nil, tonumber(deaths)
    end

    return nil
end

-- On login: attempt to restore data from old-format note, then clear it.
function SchlingelInc:MigrateFromGuildNoteIfNeeded()
    if not IsInGuild() then return end
    if DiscordHandle and DiscordHandle ~= "" then
        -- Already have a handle — just ensure note is cleared
        SchlingelInc:ClearGuildNote()
        return
    end

    local playerName = UnitName("player")
    local member = SchlingelInc.GuildCache:GetMemberInfo(playerName)
    if member and member.publicNote and member.publicNote ~= "" then
        local handle, pronouns, deaths = SchlingelInc:ParseGuildNote(member.publicNote)
        if handle then
            DiscordHandle = handle
            if pronouns and pronouns ~= "" then Pronouns = pronouns end
            if deaths then CharacterDeaths = deaths end
            SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
                "Profildaten aus Gildennotiz migriert.|r")
        end
        SchlingelInc:ClearGuildNote()
    end
end

-- Slash commands
function SchlingelInc:InitializeDiscordHandlePrompt()
    SLASH_SETHANDLE1 = '/setHandle'
    SLASH_SETHANDLE2 = '/sethandle'
    SlashCmdList["SETHANDLE"] = function(msg)
        local handle = msg:match("^%s*(.-)%s*$")
        if handle and handle ~= "" then
            SchlingelInc:SetDiscordHandle(handle)
            SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
                "Discord Handle gesetzt: " .. handle .. "|r")
        else
            local current = SchlingelInc:GetDiscordHandle()
            if current and current ~= "" then
                SchlingelInc:Print("Aktueller Discord Handle: " .. current)
            else
                SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING ..
                    "Verwendung: /setHandle <dein Discord Handle>|r")
            end
        end
    end

    SLASH_SETPRONOUNS1 = '/setPronouns'
    SLASH_SETPRONOUNS2 = '/setpronouns'
    SlashCmdList["SETPRONOUNS"] = function(msg)
        local pronouns = msg:match("^%s*(.-)%s*$")
        if pronouns and pronouns ~= "" then
            SchlingelInc:SetPreferredPronouns(pronouns)
            SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
                "Pronomen gesetzt: " .. pronouns .. "|r")
        else
            SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING ..
                "Verwendung: /setPronouns <deine Pronomen>|r")
        end
    end

    SLASH_CLEARPRONOUNS1 = '/clearPronouns'
    SLASH_CLEARPRONOUNS2 = '/clearpronouns'
    SlashCmdList["CLEARPRONOUNS"] = function()
        SchlingelInc:SetPreferredPronouns(nil)
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS .. "Pronomen gelöscht.|r")
    end
end
