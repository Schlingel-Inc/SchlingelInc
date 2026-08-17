-- interfaces/popups/AchievementGrantForm.lua
-- Small officer popup to manually grant a `manual`-kind (RP), `level`-kind, or
-- `kill_count` achievement to a specific target, opened via "Erfolg verleihen" in
-- MemberContextMenu.lua.
-- Card list mirrors OfficerPanel/TabAchievements.lua's catalog view.

SchlingelInc.Popup = SchlingelInc.Popup or {}

local actionForm = SchlingelInc.Popup.CreateAchievementActionForm({
    popupKey          = "achievementGrantForm",
    frameName         = "SchlingelAchievementGrantForm",
    positionKey       = "achievementgrantform_position",
    confirmDialogKey  = "SCHLINGEL_ACHIEVEMENT_GRANT_CONFIRM",
    confirmText       = "Erfolg \"%s\" an %s verleihen?",
    confirmButton     = "Verleihen",
    titlePrefix       = "Erfolg verleihen: ",
    getEntries        = function() return SchlingelInc.Achievements.Catalog:GetActive() end,
    eligibleSetField  = "unreachedSet",
    -- Show everything grantable while we're still waiting on the real "unreached"
    -- set, then narrow down once it arrives.
    isEligible        = function(f, entry) return not f.unreachedSet or f.unreachedSet[entry.id] end,
    emptyWithSet      = "Spieler hat bereits alle verleihbaren Erfolge.",
    emptyNoSet        = "Keine verleihbaren Erfolge vorhanden.",
    requestEligibility = function(targetName) SchlingelInc.Achievements.Progress:RequestUnreached(targetName) end,
    performAction     = function(targetName, id) SchlingelInc.Achievements.ManualGrant:Grant(targetName, id) end,
})

function SchlingelInc.Popup:ShowAchievementGrantForm(targetName)
    actionForm.Show(targetName)
end

function SchlingelInc.Popup:OnUnreachedReceived(senderShort, chunkIndex, totalChunks, ids)
    actionForm.OnReceived(senderShort, chunkIndex, totalChunks, ids)
end
