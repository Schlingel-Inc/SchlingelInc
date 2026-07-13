-- Constants.lua
-- Central constants for the SchlingelInc addon

SchlingelInc.Constants = {}

-- ============================================================
-- == GUILD CONFIGURATION =====================================
-- Officers configure rules via the in-game Officer Panel.
-- ============================================================

-- Key used in guild info to encode the current level cap.
-- Officers put this in the guild description: e.g. "SchlingelCap:40"
SchlingelInc.Constants.RULES_CAP_KEY = "SchlingelCap"

-- Separator line written before the SchlingelInc block in guild info.
SchlingelInc.Constants.GUILD_INFO_SEPARATOR = "--- SchlingelInc ---"

-- Key used in the guild info text to encode rules.
-- Officers put this in the guild description: e.g. "Schlingel:11111"
-- Digits control: mail, auction house, trade, grouping, blocked SoD traders.
SchlingelInc.Constants.RULES_KEY = "Schlingel"

-- Maximum level for Season of Discovery
SchlingelInc.Constants.MAX_LEVEL = 60

-- Level milestones for announcements
SchlingelInc.Constants.LEVEL_MILESTONES = {10, 20, 25, 30, 40, 50, 60}

-- Max length for the Discord handle. Keeps guild-chat announcements that embed
-- the handle (death/levelup messages) safely under WoW's ~255 byte chat message
-- limit, which errors instead of truncating when exceeded.
SchlingelInc.Constants.DISCORD_HANDLE_MAX_LENGTH = 50

-- Instance types
SchlingelInc.Constants.INSTANCE_TYPES = {
	PVP = "pvp",
	RAID = "raid",
	DUNGEON = "party"
}

-- Sound IDs
SchlingelInc.Constants.SOUNDS = {
	-- Standard WoW sounds (sound_pack = "standard")
	PVP_ALERT = 8174,
	DEATH_ANNOUNCEMENT = 8192,
	LEVELUP_ANNOUNCEMENT = 888,
	CAP_ANNOUNCEMENT_STANDARD = 8574,  -- Achievement sound
	-- Torro custom sound files (sound_pack = "torro")
	TORRO_DEATH = {
		"Interface\\AddOns\\SchlingelInc\\media\\sounds\\schandenschlingel.wav",
		"Interface\\AddOns\\SchlingelInc\\media\\sounds\\tausendTode.wav",
	},
	TORRO_LEVELUP = "Interface\\AddOns\\SchlingelInc\\media\\sounds\\ehrenschlingel.wav",
	TORRO_CAP = "Interface\\AddOns\\SchlingelInc\\media\\sounds\\cap_announcement.wav",
}

-- Colors for messages
SchlingelInc.Constants.COLORS = {
	ADDON_PREFIX = "|cFFF48CBA",
	ERROR = "|cffff0000",
	SUCCESS = "|cff00ff00",
	WARNING = "|cffffaa00",
	INFO = "|cff88ccff"
}

-- Cooldowns (in seconds)
SchlingelInc.Constants.COOLDOWNS = {
	PVP_ALERT = 10,
	INVITE_REQUEST = 300,  -- 5 minutes
	GUILD_ROSTER_CACHE = 60,  -- 1 minute
	DEATH_ANNOUNCEMENT = 10,
	PROGRESS_BROADCAST = 75
}

-- Pronouns for genders (German articles)
SchlingelInc.Constants.PRONOUNS = {
	[2] = "der",  -- Male
	[3] = "die"   -- Female
}

-- In-game guild name, used for /who lookups from players who aren't guild members yet
SchlingelInc.Constants.GUILD_NAME = "Schlingel Inc"

-- Guild ranks with invite permissions (for Guild Recruitment)
SchlingelInc.Constants.OFFICER_RANKS = {
	"Oberschlingel",
	"Lootwichtel",
	"Devschlingel",
	"Großschlingel",
}

-- Fallback officer character names for players outside the guild
-- Used when the player is not yet in the guild (Level 1 requests)
SchlingelInc.Constants.FALLBACK_OFFICERS = {
	"Hausgeist",
	"Devschlingel",
	"Cricksu",
	"Triplinette",
	"Kurtibrown",
	"Totanka",
	"Twotanka",
	"Syluni",
	"Sylunì",
	"Tinaswift",
	"Wurzelwuppi",
	"Siegdirty",
	"Rohanta",
	"Pennga",
	"Tinazwift",
	"Untanka",
	"Kurti",
	"Eulkrampf",
	"Soulswift",
	"Knusbi",
	"Tinatrifft",
	"Pfeilkrampf",
	"Elemetina",
	"Trork",
	"Magentatefau",
}

-- UI Backdrop Settings
SchlingelInc.Constants.BACKDROP = {
	bgFile = "Interface\\BUTTONS\\WHITE8X8",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 }
}

-- Popup Backdrop Settings
SchlingelInc.Constants.POPUPBACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

-- Inactivity threshold (days)
SchlingelInc.Constants.INACTIVE_DAYS_THRESHOLD = 10

-- SoD-specific NPC IDs that players are not allowed to trade with (Classic Era only)
SchlingelInc.Constants.SOD_BLOCKED_TRADERS = {
    [233335] = true,
    [233428] = true,
}

-- Guild member roles
SchlingelInc.Constants.ROLES = { "Tank", "Heal", "DPS" }

-- Selectable raid instances for the Raid-Panel LFG-light feature, in SoD progression order.
SchlingelInc.Constants.RAID_INSTANCES = {
    "Blackfathom-Tiefe / Blackfathom Deeps (BFD)",
    "Gnomeregan (GNO)",
    "Versunkener Tempel / Sunken Temple (ST)",
    "Geschmolzener Kern / Molten Core (MC)",
    "Onyxias Hort / Onyxia's Lair (ONY)",
    "Pechschwingenhort / Blackwing Lair (BWL)",
    "Zul'Gurub (ZG)",
    "Ruinen von Ahn'Qiraj / Ruins of Ahn'Qiraj (AQ20)",
    "Tempel von Ahn'Qiraj / Temple of Ahn'Qiraj (AQ40)",
    "Naxxramas (Naxx)",
    "Scharlachrote Enklave / Scarlet Enclave (SE)",
}

-- Profession name normalisation: maps English client names → German display names.
-- GetSkillLineInfo returns localised strings, so English-client players end up with
-- English profession names in their profile.  This table is used to normalise them
-- to German at both save-time (DetectProfessions) and render-time (GuildPanel).
SchlingelInc.Constants.PROFESSION_NAMES_DE = {
    -- Primary trade professions
    ["Alchemy"]        = "Alchemie",
    ["Blacksmithing"]  = "Schmiedekunst",
    ["Enchanting"]     = "Verzauberung",
    ["Engineering"]    = "Ingenieurskunst",
    ["Herbalism"]      = "Kräuterkunde",
    ["Jewelcrafting"]  = nil, -- not available in SoD
    ["Leatherworking"] = "Lederverarbeitung",
    ["Mining"]         = "Bergbau",
    ["Skinning"]       = "Kürschnerei",
    ["Tailoring"]      = "Schneiderei",
}
