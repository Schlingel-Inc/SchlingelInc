-- achievements/AchievementList.lua
-- A set of default achievements that are seeded into the catalog on first load. These are built-in and cannot be edited or retired.

local KIND = SchlingelInc.Achievements.KIND

SchlingelInc.Achievements.AchievementList = {}
local AchievementList = SchlingelInc.Achievements.AchievementList

-- ── Default achievement definitions ────────────────────────────────────────────
local DEFAULTS = {
    -- ── Leveling ───────────────────────────────────────────────────────────────
    {
        id          = "builtin001",
        kind        = KIND.LEVEL,
        name        = "LEVEL 10",
        description = "Erreiche Level 10.",
        points      = 5,
        critA       = 10,
        critB       = nil,
        isGlobal    = false,
    },
    {
        id          = "builtin002",
        kind        = KIND.LEVEL,
        name        = "LEVEL 40 UNBROKEN",
        description = "Erreiche Level 40, ohne ein einziges Mal zu sterben.",
        points      = 20,
        critA       = 40,
        critB       = 1,
        isGlobal    = false,
    },

    -- ── Dungeon kills ─────────────────────────────────────────────────────────────
    {
        id          = "builtin003",
        kind        = KIND.KILL_COUNT,
        name        = "RFC: BAZZALAN",
        description = "Besiege Bazzalan im Ragefireabgrund.",
        points      = 10,
        critA       = 11519,
        critB       = 1,
        isGlobal    = false,
    }
}

-- ── Seeding ─────────────────────────────────────────────────────────────────────
-- Writes the achievement definitions to the catalog if they don't already exist.
function AchievementList:Seed()
    SchlingelAchievementDB.entries = SchlingelAchievementDB.entries or {}
    for _, def in ipairs(DEFAULTS) do
        if not SchlingelAchievementDB.entries[def.id] then
            SchlingelAchievementDB.entries[def.id] = {
                id          = def.id,
                kind        = def.kind,
                name        = def.name,
                description = def.description,
                points      = def.points,
                critA       = def.critA,
                critB       = def.critB,
                createdBy   = "builtin",
                createdAt   = 0,
                updatedAt   = 0,
                retired     = false,
                isGlobal    = def.isGlobal,
            }
        end
    end
end

function AchievementList:Initialize()
    AchievementList:Seed()
end
