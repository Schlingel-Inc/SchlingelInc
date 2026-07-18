-- GuildJoinPrompt.lua
-- Simple prompt shown when the player has a complete profile but isn't in the guild yet.
-- Just one button to send the join request, no wizard flow needed.

local promptFrame

local function BuildPrompt()
    local f = SchlingelInc.Shared.CreateStandardFrame({
        name          = "SchlingelGuildJoinPrompt",
        width         = 300,
        height        = 130,
        strata        = "DIALOG",
        positionKey   = "guildjoinprompt_position",
        defaultPoint  = "CENTER",
        defaultX      = 0,
        defaultY      = 0,
        registerEscape = true,
        closeButton   = true,
    })

    local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOP", f, "TOP", 0, -22)
    lbl:SetText("Du bist noch nicht in der Gilde!")
    lbl:SetTextColor(unpack(SchlingelInc.Constants.FORM_COLORS.TITLE))

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
    hint:SetTextColor(unpack(SchlingelInc.Constants.FORM_COLORS.ERROR))
    f.hint = hint

    return f
end

function SchlingelInc:ShowGuildJoinPrompt()
    promptFrame = promptFrame or BuildPrompt()
    promptFrame.hint:SetText("Keine Mods zum Einladen verfügbar")
    promptFrame.hint:SetTextColor(unpack(SchlingelInc.Constants.FORM_COLORS.ERROR))
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
            promptFrame.hint:SetTextColor(unpack(SchlingelInc.Constants.FORM_COLORS.ERROR))
        end
    end, 0, "GuildJoinPromptOfficerCheck")
end
