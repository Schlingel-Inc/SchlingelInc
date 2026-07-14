-- achievements/AchievementList.lua
-- Level-milestone achievements, seeded into the catalog on first load. These are the
-- only built-ins; everything else is created by officers in-game. Catalog:Edit/Retire
-- reject entries with createdBy == "builtin", so this stays the sole way to add to
-- this list going forward.

local KIND = SchlingelInc.Achievements.KIND

SchlingelInc.Achievements.AchievementList = {}
local AchievementList = SchlingelInc.Achievements.AchievementList

-- ── Default achievement definitions ────────────────────────────────────────────
local DEFAULTS = {
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
        points      = 30,
        critA       = 40,
        critB       = 1,
        isGlobal    = false,
    },
    {
        id          = "builtin004",
        kind        = KIND.LEVEL,
        name        = "LEVEL 10 UNBROKEN",
        description = "Erreiche Level 10, ohne ein einziges Mal zu sterben.",
        points      = 8,
        critA       = 10,
        critB       = 1,
        isGlobal    = false,
    },
    {
        id          = "builtin005",
        kind        = KIND.LEVEL,
        name        = "LEVEL 20",
        description = "Erreiche Level 20.",
        points      = 10,
        critA       = 20,
        critB       = nil,
        isGlobal    = false,
    },
    {
        id          = "builtin006",
        kind        = KIND.LEVEL,
        name        = "LEVEL 20 UNBROKEN",
        description = "Erreiche Level 20, ohne ein einziges Mal zu sterben.",
        points      = 15,
        critA       = 20,
        critB       = 1,
        isGlobal    = false,
    },
    {
        id          = "builtin007",
        kind        = KIND.LEVEL,
        name        = "LEVEL 25",
        description = "Erreiche Level 25.",
        points      = 13,
        critA       = 25,
        critB       = nil,
        isGlobal    = false,
    },
    {
        id          = "builtin008",
        kind        = KIND.LEVEL,
        name        = "LEVEL 25 UNBROKEN",
        description = "Erreiche Level 25, ohne ein einziges Mal zu sterben.",
        points      = 20,
        critA       = 25,
        critB       = 1,
        isGlobal    = false,
    },
    {
        id          = "builtin009",
        kind        = KIND.LEVEL,
        name        = "LEVEL 30",
        description = "Erreiche Level 30.",
        points      = 15,
        critA       = 30,
        critB       = nil,
        isGlobal    = false,
    },
    {
        id          = "builtin010",
        kind        = KIND.LEVEL,
        name        = "LEVEL 30 UNBROKEN",
        description = "Erreiche Level 30, ohne ein einziges Mal zu sterben.",
        points      = 23,
        critA       = 30,
        critB       = 1,
        isGlobal    = false,
    },
    {
        id          = "builtin011",
        kind        = KIND.LEVEL,
        name        = "LEVEL 40",
        description = "Erreiche Level 40.",
        points      = 20,
        critA       = 40,
        critB       = nil,
        isGlobal    = false,
    },
    {
        id          = "builtin012",
        kind        = KIND.LEVEL,
        name        = "LEVEL 50",
        description = "Erreiche Level 50.",
        points      = 25,
        critA       = 50,
        critB       = nil,
        isGlobal    = false,
    },
    {
        id          = "builtin013",
        kind        = KIND.LEVEL,
        name        = "LEVEL 50 UNBROKEN",
        description = "Erreiche Level 50, ohne ein einziges Mal zu sterben.",
        points      = 38,
        critA       = 50,
        critB       = 1,
        isGlobal    = false,
    },
    {
        id          = "builtin014",
        kind        = KIND.LEVEL,
        name        = "LEVEL 60",
        description = "Erreiche Level 60.",
        points      = 30,
        critA       = 60,
        critB       = nil,
        isGlobal    = false,
    },
    {
        id          = "builtin015",
        kind        = KIND.LEVEL,
        name        = "LEVEL 60 UNBROKEN",
        description = "Erreiche Level 60, ohne ein einziges Mal zu sterben.",
        points      = 45,
        critA       = 60,
        critB       = 1,
        isGlobal    = false,
    },
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
