-- GuildPanel/init.lua
-- Module namespace, layout constants, and shared mutable state.
-- Loaded first; all other GuildPanel files depend on these values.

SchlingelInc.GuildPanel = {}
local GP = SchlingelInc.GuildPanel

GP.PANEL_NAME = "SchlingelGuildPanel"
GP.ROW_H      = 16
GP.TITLE_H    = 26   -- title bar height
GP.COL_H      = 16   -- column label row height

-- Column definitions (mirrors native guild window + addon extras)
GP.COLUMNS = {
    { label = "Name",  width = 120 },
    { label = "Lvl",   width = 26  },
    { label = "Rang",  width = 84  },
    { label = "Zone",  width = 90  },
    { label = "Rolle", width = 55  },
    { label = "Tode",  width = 35  },
}

GP.PAD_X   = 16
GP.FRAME_W = 0    -- computed in Frame.lua before first use
GP.FRAME_H = 420  -- fixed height (~22 visible rows)

-- ── Sort / filter state (mutable, shared across Data, Frame, FilterPanel) ──────
GP.sortCol     = 0      -- 0 = default (online+name); 1-6 = COLUMNS index
GP.sortAsc     = true   -- true = ascending
GP.hideOffline = false
GP.ROLE_ORDER  = { Tank = 1, Heal = 2, DPS = 3 }

GP.filterName  = ""
GP.filterRoles = {}   -- { roleName = true } for each active toggle
GP.filterProf  = nil  -- German profession name, or nil = no filter

-- Returns the sum of all column widths.
function GP.TotalColWidth()
    local w = 0
    for _, c in ipairs(GP.COLUMNS) do w = w + c.width end
    return w
end
