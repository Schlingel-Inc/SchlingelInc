-- GuildPanel/TabSchande.lua
-- "Schande" tab: read-only view of the player's own Schande history.
-- There is no roster of other players' Schande here — see Schande.lua for why.
-- Card rendering is shared with the officer's Schande viewer popup via
-- SchlingelInc.Shared.BuildSchandeList (interfaces/SchandeList.lua).

local GP = SchlingelInc.GuildPanel

function GP.BuildSchandeTab(content)
    local statusLbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    statusLbl:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -10)
    statusLbl:SetJustifyH("LEFT")

    local listHeaderLbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listHeaderLbl:SetPoint("TOPLEFT", statusLbl, "BOTTOMLEFT", 0, -14)
    listHeaderLbl:SetText("Verlauf:")
    listHeaderLbl:SetTextColor(1, 0.82, 0, 1)

    local divider = content:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(unpack(SchlingelInc.Constants.FORM_COLORS.DIVIDER))
    divider:SetPoint("TOPLEFT",  listHeaderLbl, "BOTTOMLEFT", 0, -4)
    divider:SetPoint("RIGHT",    content, "RIGHT", -8, 0)

    local body = CreateFrame("Frame", nil, content)
    body:SetPoint("TOPLEFT",     divider, "BOTTOMLEFT", 0, -6)
    body:SetPoint("BOTTOMRIGHT", content,  "BOTTOMRIGHT", 0, 4)

    local list = SchlingelInc.Shared.BuildSchandeList(body)

    local function Refresh()
        local entries = SchlingelInc.Schande:GetOwn().entries

        if SchlingelInc.Schande:IsActive() then
            statusLbl:SetText("Du bist in Schande.")
            statusLbl:SetTextColor(1, 0.2, 0.2, 1)
        elseif #entries > 0 then
            statusLbl:SetText("Deine Schande ist aufgehoben.")
            statusLbl:SetTextColor(0.4, 1, 0.4, 1)
        else
            statusLbl:SetText("Keine Schande.")
            statusLbl:SetTextColor(0.6, 0.6, 0.6, 1)
        end

        list.Refresh(entries)
    end

    content.Refresh = Refresh
    Refresh()
end
