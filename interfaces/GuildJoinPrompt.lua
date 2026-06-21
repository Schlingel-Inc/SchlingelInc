-- GuildJoinPrompt.lua
-- Simple prompt shown when the player has a complete profile but isn't in the guild yet.
-- Just one button to send the join request, no wizard flow needed.

local promptFrame

local function BuildPrompt()
    local f = CreateFrame("Frame", "SchlingelGuildJoinPrompt", UIParent, "BackdropTemplate")
    f:SetSize(300, 110)
    f:SetPoint("CENTER")
    f:SetBackdrop(SchlingelInc.Constants.BACKDROP)
    f:SetBackdropColor(0, 0, 0, 0.85)
    f:SetBackdropBorderColor(1, 0.55, 0.73, 1)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
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

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    return f
end

function SchlingelInc:ShowGuildJoinPrompt()
    promptFrame = promptFrame or BuildPrompt()
    if not promptFrame:IsShown() then
        promptFrame:SetPoint("CENTER")
        promptFrame:Show()
    end
end
