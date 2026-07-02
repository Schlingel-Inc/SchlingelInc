-- PvPFrame.lua
-- Displays PvP warning popup when targeting PvP-flagged players

-- Checks if the current target is PvP-flagged and shows a warning
function SchlingelInc:CheckTargetPvP()
    local unit = "target"
    if not UnitExists(unit) or not UnitIsPVP(unit) then return end

    local targetFaction = UnitFactionGroup(unit)
    local name = UnitName(unit) or "Unbekannt"

    if targetFaction == "Allianz" and not UnitIsPlayer(unit) then
        SchlingelInc:ShowPvPWarning(name .. " (Allianz-NPC)")
        return
    end

    if not UnitIsPlayer(unit) then return end

    if not SchlingelInc.lastPvPAlert then
        SchlingelInc.lastPvPAlert = {}
    end

    local now = GetTime()
    local lastAlert = SchlingelInc.lastPvPAlert[name] or 0

    if (now - lastAlert) > SchlingelInc.Constants.COOLDOWNS.PVP_ALERT then
        SchlingelInc.lastPvPAlert[name] = now
        SchlingelInc:ShowPvPWarning(name .. " ist PvP-aktiv!")
    end
end

-- Shows the PvP warning popup with the given text
function SchlingelInc:ShowPvPWarning(text)
    if not SchlingelInc.pvpWarningFrame then
        SchlingelInc:CreatePvPWarningFrame()
    end

    if not SchlingelInc.pvpWarningFrame then return end

    SchlingelInc.pvpWarningText:SetText("Obacht Schlingel!")
    SchlingelInc.pvpWarningName:SetText(text)
    SchlingelInc.pvpWarningFrame:SetAlpha(1)
    SchlingelInc.pvpWarningFrame:Show()

    if SchlingelOptionsDB["pvp_alert_sound"] then
        PlaySound(SchlingelInc.Constants.SOUNDS.PVP_ALERT)
    end

    C_Timer.After(1, function()
        if SchlingelInc.pvpWarningFrame then
            UIFrameFadeOut(SchlingelInc.pvpWarningFrame, 1, 1, 0)
            C_Timer.After(1, function()
                if SchlingelInc.pvpWarningFrame then
                    SchlingelInc.pvpWarningFrame:Hide()
                end
            end)
        end
    end)
end

-- Creates the PvP warning frame
function SchlingelInc:CreatePvPWarningFrame()
    if SchlingelInc.pvpWarningFrame and SchlingelInc.pvpWarningFrame:IsObjectType("Frame") then
        return
    end

    local pvpFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    pvpFrame:SetSize(320, 110)
    pvpFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    pvpFrame:SetBackdropBorderColor(1, 0.55, 0.73, 1)
    pvpFrame:SetBackdropColor(0, 0, 0, 0.30)
    pvpFrame:SetMovable(true)
    pvpFrame:EnableMouse(true)
    pvpFrame:RegisterForDrag("LeftButton")
    pvpFrame:SetScript("OnDragStart", pvpFrame.StartMoving)
    pvpFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SchlingelInc:SaveFramePosition(self, "pvpwarning_position")
    end)
    SchlingelInc:RestoreFramePosition(pvpFrame, "pvpwarning_position", "CENTER", 0, 0)
    pvpFrame:Hide()

    local text = pvpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("TOP", pvpFrame, "TOP", 0, -20)
    text:SetTextColor(1, 0.55, 0.73)

    local nameText = pvpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("BOTTOM", pvpFrame, "BOTTOM", 0, 25)
    nameText:SetTextColor(1, 0.82, 0)

    SchlingelInc.pvpWarningFrame = pvpFrame
    SchlingelInc.pvpWarningText = text
    SchlingelInc.pvpWarningName = nameText
end
