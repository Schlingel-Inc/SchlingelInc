-- GuildJoinPrompt.lua
-- Simple prompt shown when the player has a complete profile but isn't in the guild yet.
-- Just one button to send the join request, no wizard flow needed.

local promptFrame

local function BuildPrompt()
    local f = CreateFrame("Frame", "SchlingelGuildJoinPrompt", UIParent, "BackdropTemplate")
    f:SetSize(300, 130)
    f:SetBackdrop(SchlingelInc.Constants.BACKDROP)
    f:SetBackdropColor(0, 0, 0, 0.85)
    f:SetBackdropBorderColor(1, 0.55, 0.73, 1)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SchlingelInc:SaveFramePosition(self, "guildjoinprompt_position")
    end)
    SchlingelInc:RestoreFramePosition(f, "guildjoinprompt_position", "CENTER", 0, 0)
    SchlingelInc:RegisterFrameForEscape(f)

    local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOP", f, "TOP", 0, -22)
    lbl:SetText("Du bist noch nicht in der Gilde!")
    lbl:SetTextColor(1, 0.55, 0.73)

    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetSize(210, 28)
    btn:SetPoint("TOP", lbl, "BOTTOM", 0, -14)
    btn:SetText("Beitrittsanfrage senden")
    btn:SetScript("OnClick", function()
        SchlingelInc.GuildRecruitment:SendGuildRequest()
        f:Hide()
    end)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOP", btn, "BOTTOM", 0, -10)
    hint:SetText("Keine Mods zum Einladen verfügbar")
    hint:SetTextColor(1, 0.3, 0.3)
    f.hint = hint

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    return f
end

function SchlingelInc:ShowGuildJoinPrompt()
    promptFrame = promptFrame or BuildPrompt()
    promptFrame.hint:SetText("Keine Mods zum Einladen verfügbar")
    promptFrame.hint:SetTextColor(1, 0.3, 0.3)
    if not promptFrame:IsShown() then
        promptFrame:Show()
    end
    SchlingelInc.GuildRecruitment:CheckOfficersOnline()
end

-- Refreshes the join prompt's availability hint from the officer list
-- GuildRecruitment maintains via /who, without revealing who exactly is
-- online. Registered below priority 0 so it runs after GuildRecruitment's
-- own WHO_LIST_UPDATE handler (priority 10) has rebuilt that list.
function SchlingelInc:InitializeGuildJoinPrompt()
    SchlingelInc.EventManager:RegisterHandler("WHO_LIST_UPDATE", function()
        if not promptFrame or not promptFrame:IsShown() then return end
        if #SchlingelInc.GuildRecruitment:GetOnlineOfficers() > 0 then
            promptFrame.hint:SetText("Mods sind zum Einladen verfügbar")
            promptFrame.hint:SetTextColor(0.3, 1, 0.3)
        else
            promptFrame.hint:SetText("Keine Mods zum Einladen verfügbar")
            promptFrame.hint:SetTextColor(1, 0.3, 0.3)
        end
    end, 0, "GuildJoinPromptOfficerCheck")
end
