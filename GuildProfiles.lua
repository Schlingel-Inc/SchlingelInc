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

-- Serialise own profile into a single addon message string.
-- Format: PROFILE2|role|prof1name|prof1rank|prof2name|prof2rank|discord|deaths
local function Serialize()
    local p      = SchlingelOwnProfile
    local handle = DiscordHandle or ""
    local deaths = tostring(CharacterDeaths or 0)
    return table.concat({
        MSG_PROFILE,
        p.role    or "",
        p.prof1   or "",
        p.prof1rank and tostring(p.prof1rank) or "",
        p.prof2   or "",
        p.prof2rank and tostring(p.prof2rank) or "",
        handle,
        deaths,
    }, "|")
end

-- Deserialise a received payload into a profile table (returns nil on bad format).
local function Deserialize(payload)
    local parts = {}
    for part in (payload .. "|"):gmatch("([^|]*)|") do
        table.insert(parts, part)
    end
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
        lastSeen  = time(),
    }
end

-- Broadcast own profile to the guild channel.
function SchlingelInc.GuildProfiles:Broadcast()
    if not IsInGuild() then return end
    C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, Serialize(), "GUILD")
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
-- Uses GetSkillLineInfo (vanilla-era API, always available in TBC Classic) instead of
-- GetProfessions() which is a Cataclysm backport and can return nil in TBC Classic
-- when profession data hasn't been loaded in the current session frame.
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
    -- Broadcast own profile on login (after guild cache is ready).
    SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
        function()
            C_Timer.After(6, function()
                SchlingelInc.GuildProfiles:Broadcast()
            end)
        end, 90, "GuildProfilesBroadcast")
end
