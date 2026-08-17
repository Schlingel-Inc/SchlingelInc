-- interfaces/popups/AchievementRevokeForm.lua
-- Small officer popup to remove a previously unlocked `manual`-kind (RP),
-- `level`-kind, or `kill_count` achievement from a specific target, opened via
-- "Erfolg entziehen" in MemberContextMenu.lua.

SchlingelInc.Popup = SchlingelInc.Popup or {}

local actionForm = SchlingelInc.Popup.CreateAchievementActionForm({
    popupKey          = "achievementRevokeForm",
    frameName         = "SchlingelAchievementRevokeForm",
    positionKey       = "achievementrevokeform_position",
    confirmDialogKey  = "SCHLINGEL_ACHIEVEMENT_REVOKE_CONFIRM",
    confirmText       = "Erfolg \"%s\" von %s entfernen?",
    confirmButton     = "Entfernen",
    titlePrefix       = "Erfolg entziehen: ",
    getEntries        = function() return SchlingelInc.Achievements.Catalog:GetAll() end,
    eligibleSetField  = "reachedSet",
    -- Show nothing until the real "reached" set arrives — can't assume someone
    -- has unlocked something before confirmed.
    isEligible        = function(f, entry) return f.reachedSet and f.reachedSet[entry.id] end,
    emptyWithSet      = "Spieler hat keine entziehbaren Erfolge.",
    emptyNoSet        = "Keine entziehbaren Erfolge vorhanden.",
    requestEligibility = function(targetName) SchlingelInc.Achievements.Progress:RequestReached(targetName) end,
    performAction     = function(targetName, id) SchlingelInc.Achievements.ManualGrant:Revoke(targetName, id) end,
})

function SchlingelInc.Popup:ShowAchievementRevokeForm(targetName)
    actionForm.Show(targetName)
end

function SchlingelInc.Popup:OnReachedReceived(senderShort, chunkIndex, totalChunks, ids)
    actionForm.OnReceived(senderShort, chunkIndex, totalChunks, ids)
end
