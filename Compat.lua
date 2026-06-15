-- Compat.lua
-- Detects the WoW game edition at load time and exposes edition flags.
-- Must be loaded before all other SchlingelInc files.

SchlingelInc = SchlingelInc or {}

-- WOW_PROJECT_ID constants (defined by Blizzard in all Classic builds):
--   WOW_PROJECT_CLASSIC                   = 2  (Classic Era, Season of Discovery)
--   WOW_PROJECT_BURNING_CRUSADE_CLASSIC   = 5  (TBC Classic)
local projectID = WOW_PROJECT_ID or 0

SchlingelInc.IsTBC         = (projectID == (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5))
SchlingelInc.IsClassicEra  = (projectID == (WOW_PROJECT_CLASSIC or 2))
