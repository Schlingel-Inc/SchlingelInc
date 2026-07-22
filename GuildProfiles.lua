-- GuildProfiles.lua
-- Syncs player profiles (role, professions) via addon messages.
-- Own profile lives in SchlingelOwnProfile (SavedVariablesPerCharacter).
-- Received profiles are cached in SchlingelGuildProfileCache (SavedVariables, account-wide).

SchlingelInc.GuildProfiles = {}

-- Ensure SavedVariables are initialized
SchlingelGuildProfileCache = SchlingelGuildProfileCache or {}
SchlingelOwnProfile        = SchlingelOwnProfile        or {}

-- Message prefix for profile payloads
local MSG_PROFILE = "PROFILE2"
local PROFILE_REQUEST_BROADCAST_COOLDOWN = 30
local PROFILE_REQUEST_RESPONSE_COOLDOWN = 20
local PROFILE_REQUEST_DELAY_MIN = 0.5
local PROFILE_REQUEST_DELAY_MAX = 2.5
local PROFILE_RESPONSE_DELAY_MIN = 0.4
local PROFILE_RESPONSE_DELAY_MAX = 1.8

local lastProfileRequestBroadcastAt = 0
local lastProfileRequestResponseAt = 0
local profileResponseQueued = false

local function RandomDelay(minSeconds, maxSeconds)
    return minSeconds + (math.random() * (maxSeconds - minSeconds))
end

local function SendProfileRequestWithCooldown()
    if not IsInGuild() then return end
    local now = time()
    if (now - lastProfileRequestBroadcastAt) < PROFILE_REQUEST_BROADCAST_COOLDOWN then
        return
    end

    lastProfileRequestBroadcastAt = now
    ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, "PROFILE_REQUEST", "GUILD", nil, "SchlingelInc-Profile")
end

local function QueueProfileResponse()
    if profileResponseQueued then return end

    local now = time()
    if (now - lastProfileRequestResponseAt) < PROFILE_REQUEST_RESPONSE_COOLDOWN then
        return
    end

    profileResponseQueued = true
    C_Timer.After(RandomDelay(PROFILE_RESPONSE_DELAY_MIN, PROFILE_RESPONSE_DELAY_MAX), function()
        profileResponseQueued = false
        if not IsInGuild() then return end
        SchlingelInc.GuildProfiles:Broadcast()
        lastProfileRequestResponseAt = time()
    end)
end

-- Serialise own profile into a single addon message string.
-- Format: PROFILE2|role|prof1name|prof1rank|prof2name|prof2rank|discord|deaths|pronouns|achievementScore
local function Serialize()
    local p      = SchlingelOwnProfile
    local handle = DiscordHandle or ""
    local deaths = tostring(CharacterDeaths or 0)
    local achievementScore = tostring(SchlingelInc.Achievements and SchlingelInc.Achievements.Progress:GetScore() or 0)
    return table.concat({
        MSG_PROFILE,
        p.role    or "",
        p.prof1   or "",
        p.prof1rank and tostring(p.prof1rank) or "",
        p.prof2   or "",
        p.prof2rank and tostring(p.prof2rank) or "",
        handle,
        deaths,
        Pronouns or "",
        achievementScore,
    }, "|")
end

-- Deserialise a received payload into a profile table (returns nil on bad format).
local function Deserialize(payload)
    local parts = SchlingelInc:ParsePipeMessage(payload)
    -- parts[1] = MSG_PROFILE tag, already stripped by caller
    if #parts < 7 then return nil end
    return {
        role      = parts[1] ~= "" and parts[1] or nil,
        prof1     = parts[2] ~= "" and parts[2] or nil,
        prof1rank = parts[3] ~= "" and tonumber(parts[3]) or nil,
        prof2     = parts[4] ~= "" and parts[4] or nil,
        prof2rank = parts[5] ~= "" and tonumber(parts[5]) or nil,
        discord   = parts[6] ~= "" and parts[6] or nil,
        deaths    = parts[7] ~= "" and tonumber(parts[7]) or nil,
        pronouns  = parts[8] and parts[8] ~= "" and parts[8] or nil,
        achievementScore = parts[9] and tonumber(parts[9]) or 0,
        lastSeen  = time(),
    }
end

-- Broadcast own profile to the guild channel.
-- Also writes directly to the local cache because GUILD addon messages
-- do not loop back to the sender in WoW Classic.
function SchlingelInc.GuildProfiles:Broadcast()
    if not IsInGuild() then return end
    local payload = Serialize()
    ChatThrottleLib:SendAddonMessage("NORMAL", SchlingelInc.prefix, payload, "GUILD", nil, "SchlingelInc-Profile")
    local ownProfile = Deserialize(payload:sub(#MSG_PROFILE + 2))
    local selfName = UnitName("player")
    if ownProfile and selfName then
        SchlingelGuildProfileCache[selfName] = ownProfile
    end
end

-- Save a field on the own profile and re-broadcast.
function SchlingelInc.GuildProfiles:SetOwn(key, value)
    SchlingelOwnProfile[key] = value
    SchlingelInc.GuildProfiles:Broadcast()
end

-- Returns the cached profile for a player name (short, no realm).
function SchlingelInc.GuildProfiles:Get(name)
    return SchlingelGuildProfileCache[name]
end

-- Translates a profession name to German if an English equivalent is known.
local function TranslateProfession(name)
    if not name then return name end
    return SchlingelInc.Constants.PROFESSION_NAMES_DE[name] or name
end

-- Detect primary trade professions and return up to two tables {name, rank, maxRank}.
-- Uses GetSkillLineInfo, the API available on Classic Era (SoD); GetProfessions()
-- is a later-expansion backport and isn't available on this client.
-- isAbandonable=true identifies primary trade professions only — secondary professions
-- (cooking, fishing, first aid) and combat skills are not abandoable.
function SchlingelInc.GuildProfiles:DetectProfessions()
    local result = {}
    local n = GetNumSkillLines()
    for i = 1, n do
        local name, isHeader, _, rank, _, _, maxRank, isAbandonable = GetSkillLineInfo(i)
        if not isHeader and isAbandonable and name and name ~= "" then
            table.insert(result, { name = TranslateProfession(name), rank = rank, maxRank = maxRank })
            if #result >= 2 then break end
        end
    end
    return result
end

-- Handle incoming PROFILE2 addon messages (wired in from Global.lua handler).
function SchlingelInc.GuildProfiles:HandleMessage(sender, message)
    -- Respond to profile requests from freshly-logged-in guild members.
    if message == "PROFILE_REQUEST" then
        QueueProfileResponse()
        return true
    end

    local tag = message:match("^([^|]+)")
    if tag ~= MSG_PROFILE then return false end

    local payload = message:sub(#MSG_PROFILE + 2) -- strip "PROFILE2|"
    local profile = Deserialize(payload)
    if not profile then return true end

    local shortName = SchlingelInc:RemoveRealmFromName(sender)
    SchlingelGuildProfileCache[shortName] = profile
    return true
end

function SchlingelInc.GuildProfiles:Initialize()
    -- Broadcast own profile on login and request profiles from already-online members.
    SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
        function()
            C_Timer.After(6 + RandomDelay(0, 1.2), function()
                SchlingelInc.GuildProfiles:Broadcast()
                if IsInGuild() then
                    C_Timer.After(RandomDelay(PROFILE_REQUEST_DELAY_MIN, PROFILE_REQUEST_DELAY_MAX), SendProfileRequestWithCooldown)
                end
            end)
        end, 90, "GuildProfilesBroadcast")

    -- Broadcast profile when joining the guild mid-session.
    SchlingelInc.EventManager:RegisterHandler("PLAYER_GUILD_UPDATE",
        function()
            if IsInGuild() then
                C_Timer.After(3 + RandomDelay(0, 1), function()
                    SchlingelInc.GuildProfiles:Broadcast()
                    C_Timer.After(RandomDelay(PROFILE_REQUEST_DELAY_MIN, PROFILE_REQUEST_DELAY_MAX), SendProfileRequestWithCooldown)
                end)
            end
        end, 0, "GuildProfilesGuildUpdate")

    -- Update profession ranks whenever the player skills up anything.
    -- DetectProfessions() filters to primary tradeskills (isAbandonable=true) only,
    -- so weapon/secondary skill-ups produce no change and trigger no broadcast.
    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_SKILL",
        function()
            local detected = SchlingelInc.GuildProfiles:DetectProfessions()
            local changed = false

            for slot = 1, 2 do
                local d = detected[slot]
                local newName = d and d.name or nil
                local newRank = d and d.rank or nil

                if SchlingelOwnProfile["prof"..slot] ~= newName then
                    SchlingelOwnProfile["prof"..slot] = newName
                    changed = true
                end
                if SchlingelOwnProfile["prof"..slot.."rank"] ~= newRank then
                    SchlingelOwnProfile["prof"..slot.."rank"] = newRank
                    changed = true
                end
            end

            if changed then
                SchlingelInc.GuildProfiles:Broadcast()
            end
        end, 0, "GuildProfilesSkillUp")

    SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
        function(_, prefix, message, _, sender)
            if prefix ~= SchlingelInc.prefix then return end
            SchlingelInc.GuildProfiles:HandleMessage(sender, message)
        end, 0, "GuildProfilesAddonMessage")
end
