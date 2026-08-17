local addonLoadedFrame = CreateFrame("Frame", "SchlingelIncAddonLoadedFrame")
addonLoadedFrame:RegisterEvent("ADDON_LOADED")
addonLoadedFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "SchlingelInc_Achievements" then
        SchlingelInc.Achievements:Initialize()

        SchlingelInc.GuildPanel:AddTab({
            id = "achievements",
            label = "Erfolge",
            onSelected = function()
                SchlingelInc.Achievements.Catalog:RequestSync()
                SchlingelInc.GuildPanel:RefreshAchievements()
            end,
        }, SchlingelInc.GuildPanel.BuildAchievementsTab)

        SchlingelInc.OfficerPanel:AddTab({
            id = "achievements",
            label = "Erfolge",
            canSelect = function()
                if not SchlingelInc.OfficerPanel.IsOfficer() then
                    SchlingelInc:Print("Erfolge sind nur für Offiziere verwaltbar.")
                    return false
                end
            end,
            onSelected = function() SchlingelInc.OfficerPanel:RefreshAchievements() end,
        }, SchlingelInc.OfficerPanel.BuildAchievementsTab)
    end
end)
