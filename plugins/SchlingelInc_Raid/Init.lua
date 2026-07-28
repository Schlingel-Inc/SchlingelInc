local addonLoadedFrame = CreateFrame("Frame", "SchlingelIncAddonLoadedFrame")
addonLoadedFrame:RegisterEvent("ADDON_LOADED")
addonLoadedFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "SchlingelInc_Raid" then
        SchlingelInc.Raid:Initialize()
        SchlingelInc.GuildPanel:RegisterTabInFrame()
    end
end)