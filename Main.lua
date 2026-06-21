-- SchlingelInc:OnLoad() function - executes when the addon is loaded.
function SchlingelInc:OnLoad()
    -- Initialize EventManager first
    SchlingelInc.EventManager:Initialize()

    -- Initialize core addon modules.
    SchlingelInc.Global:Initialize()
    SchlingelInc.GuildCache:Initialize()
    SchlingelInc.Death:Initialize()
    SchlingelInc.Rules:Initialize()
    SchlingelInc.LevelUps:Initialize()
    SchlingelInc.GuildRecruitment:Initialize()
    SchlingelInc.Debug:Initialize()
    SchlingelInc.GuildProfiles:Initialize()
    SchlingelInc:InitializeDiscordHandlePrompt()
    SchlingelInc:InitializeSetupWizard()
    SchlingelInc.GuildPanel:Initialize()

    SchlingelInc:InitializeOptionsDB()

    -- Create and initialize the PvP warning frame.
    SchlingelInc:CreatePvPWarningFrame()

    -- Initialize minimap icon functionality.
    SchlingelInc:InitMinimapIcon()
end

-- --- Event registrations via the central EventManager ---

-- ADDON_LOADED is still handled manually since EventManager is initialized after it
local addonLoadedFrame = CreateFrame("Frame", "SchlingelIncAddonLoadedFrame")
addonLoadedFrame:RegisterEvent("ADDON_LOADED")
addonLoadedFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == SchlingelInc.name then
        SchlingelInc:OnLoad()
    end
end)
