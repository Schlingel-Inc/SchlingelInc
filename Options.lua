-- Options.lua
-- Manages addon settings via AceConfig-3.0

SchlingelOptionsDB = SchlingelOptionsDB or {}

local AceConfig       = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Generic getter/setter: arg key must match the SchlingelOptionsDB key
local function get(info) return SchlingelOptionsDB[info[#info]] end
local function set(info, val) SchlingelOptionsDB[info[#info]] = val end

local options = {
    name = "Schlingel Inc",
    type = "group",
    childGroups = "tab",
    args = {
        allgemein = {
            name  = "Allgemein",
            type  = "group",
            order = 1,
            args  = {
                show_version = {
                    type  = "toggle",
                    name  = "Version anzeigen",
                    desc  = "Zeigt die Versionen der Spieler:innen im Gildenchat an",
                    order = 1,
                    width = "full",
                    get   = get,
                    set   = set,
                },
                auto_decline_duels = {
                    type  = "toggle",
                    name  = "Duelle Ablehnen",
                    desc  = "Lehnt automatisch alle Duell-Anfragen ab",
                    order = 2,
                    width = "full",
                    get   = get,
                    set   = set,
                },
                show_discord_handle = {
                    type  = "toggle",
                    name  = "Discord Handle im Gildenchat anzeigen",
                    desc  = "Zeigt deinen Discord Handle im Gildenchat an",
                    order = 3,
                    width = "full",
                    get   = get,
                    set   = set,
                },
            },
        },
        benachrichtigungen = {
            name  = "Benachrichtigungen",
            type  = "group",
            order = 2,
            args  = {
                pvp = {
                    type   = "group",
                    name   = "PVP Warnung",
                    inline = true,
                    order  = 1,
                    args   = {
                        pvp_alert = {
                            type  = "toggle",
                            name  = "Aktiviert",
                            desc  = "Aktiviert die PVP Warnung",
                            order = 1,
                            get   = get,
                            set   = set,
                        },
                        pvp_alert_sound = {
                            type  = "toggle",
                            name  = "Ton",
                            desc  = "Aktiviert den Ton für die PVP Warnung",
                            order = 2,
                            get   = get,
                            set   = set,
                        },
                    },
                },
                death = {
                    type   = "group",
                    name   = "Todesmeldungen",
                    inline = true,
                    order  = 2,
                    args   = {
                        deathmessages = {
                            type  = "toggle",
                            name  = "Aktiviert",
                            desc  = "Aktiviert die Todesmeldungen",
                            order = 1,
                            get   = get,
                            set   = set,
                        },
                        deathmessages_sound = {
                            type  = "toggle",
                            name  = "Ton",
                            desc  = "Aktiviert den Ton für die Todesmeldungen",
                            order = 2,
                            get   = get,
                            set   = set,
                        },
                        deathframe_always_small = {
                            type  = "toggle",
                            name  = "Kompakte Ansicht",
                            desc  = "Zeigt Todesmeldungen anderer immer als kompaktes Fenster an, nicht nur in Instanzen",
                            order = 3,
                            get   = get,
                            set   = set,
                        },
                    },
                },
                levelup = {
                    type   = "group",
                    name   = "Level-Up Meldungen",
                    inline = true,
                    order  = 3,
                    args   = {
                        levelmessages = {
                            type  = "toggle",
                            name  = "Aktiviert",
                            desc  = "Aktiviert die Level-Up Meldungen",
                            order = 1,
                            get   = get,
                            set   = set,
                        },
                        levelmessages_sound = {
                            type  = "toggle",
                            name  = "Ton",
                            desc  = "Aktiviert den Ton für die Level-Up Meldungen",
                            order = 2,
                            get   = get,
                            set   = set,
                        },
                    },
                },
                cap = {
                    type   = "group",
                    name   = "Cap-Meldungen",
                    inline = true,
                    order  = 4,
                    args   = {
                        capmessages = {
                            type  = "toggle",
                            name  = "Aktiviert",
                            desc  = "Aktiviert die Level-Cap Meldungen",
                            order = 1,
                            get   = get,
                            set   = set,
                        },
                        capmessages_sound = {
                            type  = "toggle",
                            name  = "Ton",
                            desc  = "Aktiviert den Ton für die Level-Cap Meldungen",
                            order = 2,
                            get   = get,
                            set   = set,
                        },
                    },
                },
            },
        },
        sound = {
            name  = "Sound",
            type  = "group",
            order = 3,
            args  = {
                sound_pack = {
                    type   = "select",
                    name   = "Soundpaket",
                    desc   = "Wähle zwischen Standard WoW Sounds und coolen Torro Sounds",
                    order  = 1,
                    values = { standard = "Standard", torro = "Coole Torro Sounds" },
                    get    = get,
                    set    = set,
                },
                spacer = {
                    type  = "description",
                    name  = "",
                    order = 2,
                    width = "full",
                },
                sound_channel = {
                    type   = "select",
                    name   = "Soundkanal",
                    desc   = "Wähle über welchen ingame Regler du die Schlingel Sounds regulieren möchtest",
                    order  = 3,
                    values = {
                        Master   = "Master Regler",
                        SFX      = "Effekte Regler",
                        Ambience = "Umgebungs Regler",
                        Music    = "Musik Regler",
                    },
                    get    = get,
                    set    = set,
                },
            },
        },
    },
}

AceConfig:RegisterOptionsTable("SchlingelInc", options)
AceConfigDialog:AddToBlizOptions("SchlingelInc", "Schlingel Inc")

function SchlingelInc:InitializeOptionsDB()
    local defaults = {
        show_version        = false,
        auto_decline_duels  = false,
        show_discord_handle = false,
        pvp_alert           = true,
        pvp_alert_sound     = true,
        deathmessages       = true,
        deathmessages_sound = true,
        deathframe_always_small = false,
        levelmessages       = true,
        levelmessages_sound = true,
        capmessages         = true,
        capmessages_sound   = true,
        sound_pack          = "standard",
        sound_channel       = "Master",
    }
    for key, value in pairs(defaults) do
        if SchlingelOptionsDB[key] == nil then
            SchlingelOptionsDB[key] = value
        end
    end
end
