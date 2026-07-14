BINDING_NAME_SCHLINGELINC_TOGGLE_GUILDPANEL = "Mitglieder-Interface"
BINDING_NAME_SCHLINGELINC_TOGGLE_OFFICERPANEL = "Offizier-Interface"

function SchlingelInc_Binding_ToggleGuildPanel()
    SchlingelInc.GuildPanel:Toggle()
end

function SchlingelInc_Binding_ToggleOfficerPanel()
    if not CanGuildInvite() then return end
    SchlingelInc.OfficerPanel:Toggle()
end
