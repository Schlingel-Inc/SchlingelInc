-- GuildPanel/TabAchievements.lua
-- "Erfolge" tab: read-only view of the shared achievement catalog with the local
-- player's own unlock state. Locked entries are shown in a grayish font; unlocked
-- entries show their unlock date. A retired entry only remains visible here if the
-- local player already unlocked it (otherwise it's no longer obtainable and clutters
-- the list for no reason).

local GP = SchlingelInc.GuildPanel

local CARD_GAP = 6
local CARD_PAD = 8

local KIND = SchlingelInc.Achievements.KIND

local LOCKED_COLOR   = { 0.55, 0.55, 0.55 }
local UNLOCKED_COLOR = { 1, 0.82, 0, 1 }

local function FormatDate(timestamp)
    return date("%d.%m.%Y", timestamp)
end

local function CriteriaHint(entry)
    if entry.kind == KIND.LEVEL then
        local threshold = tonumber(entry.critA) or 0
        local requireNoDeath = entry.critB == true or entry.critB == 1 or entry.critB == "1"
        return "Level " .. threshold .. (requireNoDeath and " (ohne zu sterben)" or "")
    elseif entry.kind == KIND.KILL_COUNT then
        return (tonumber(entry.critB) or 0) .. " Kills"
    end
    return "RP-Erfolg"
end

local function VisibleEntries()
    local Progress = SchlingelInc.Achievements.Progress
    local out = {}
    for _, entry in ipairs(SchlingelInc.Achievements.Catalog:GetAll()) do
        if not entry.retired or Progress:IsUnlocked(entry.id) then
            table.insert(out, entry)
        end
    end
    return out
end

local function CreateCard(parent, cardW, entry)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    card:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
    card:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    card:SetWidth(cardW)

    local Progress = SchlingelInc.Achievements.Progress
    local unlocked = Progress:IsUnlocked(entry.id)
    local color = unlocked and UNLOCKED_COLOR or LOCKED_COLOR

    local titleFs = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFs:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -CARD_PAD)
    titleFs:SetWidth(cardW - CARD_PAD * 2 - 60)
    titleFs:SetJustifyH("LEFT")
    titleFs:SetText(SchlingelInc:SanitizeText(entry.name))
    titleFs:SetTextColor(color[1], color[2], color[3], 1)

    local pointsFs = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pointsFs:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PAD, -CARD_PAD)
    pointsFs:SetJustifyH("RIGHT")
    pointsFs:SetText((entry.points or 0) .. " Punkte")
    pointsFs:SetTextColor(color[1], color[2], color[3], 1)

    local descFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descFs:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -3)
    descFs:SetWidth(cardW - CARD_PAD * 2)
    descFs:SetJustifyH("LEFT")
    descFs:SetWordWrap(true)
    descFs:SetText(SchlingelInc:SanitizeText(entry.description ~= "" and entry.description or CriteriaHint(entry)))
    descFs:SetTextColor(color[1] * 0.9, color[2] * 0.9, color[3] * 0.9, 1)

    local height = CARD_PAD + 16 + descFs:GetStringHeight() + CARD_PAD

    if unlocked then
        local dateFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        dateFs:SetPoint("TOPLEFT", descFs, "BOTTOMLEFT", 0, -3)
        dateFs:SetText("|cff44ff44Freigeschaltet am " .. FormatDate(Progress:GetUnlockedAt(entry.id)) .. "|r")
        height = height + 14
    elseif entry.kind == KIND.KILL_COUNT then
        local required = tonumber(entry.critB) or 0
        local progressFs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        progressFs:SetPoint("TOPLEFT", descFs, "BOTTOMLEFT", 0, -3)
        progressFs:SetText("Fortschritt: " .. Progress:GetKillProgress(entry.id) .. "/" .. required)
        progressFs:SetTextColor(LOCKED_COLOR[1], LOCKED_COLOR[2], LOCKED_COLOR[3], 1)
        height = height + 14
    end

    card:SetHeight(height)
    return card
end

local RANK_BAR_H = 54

function GP.BuildAchievementsTab(content)
    -- ── Rank + progress bar ──────────────────────────────────────────────────
    local rankFs = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rankFs:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -2)
    rankFs:SetJustifyH("LEFT")
    rankFs:SetTextColor(1, 0.82, 0, 1)

    local rankBar = CreateFrame("StatusBar", nil, content, "BackdropTemplate")
    rankBar:SetPoint("TOPLEFT", rankFs, "BOTTOMLEFT", 0, -4)
    rankBar:SetPoint("RIGHT", content, "RIGHT", -24, 0)
    rankBar:SetHeight(14)
    rankBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    rankBar:SetStatusBarColor(1, 0.82, 0, 1)
    rankBar:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    rankBar:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    rankBar:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local rankBarFs = rankBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rankBarFs:SetPoint("CENTER", rankBar, "CENTER", 0, 0)

    local function RefreshRank()
        local Progress = SchlingelInc.Achievements.Progress
        local score = Progress:GetScore()
        local current, nextRank = Progress:GetRankForScore(score)

        rankFs:SetText((current and current.name or "Kein Rang") .. "  |cff888888(" .. score .. " Schlingelpunkte)|r")

        if nextRank then
            rankBar:SetMinMaxValues(current and current.minPoints or 0, nextRank.minPoints)
            rankBar:SetValue(score)
            rankBarFs:SetText(score .. " / " .. nextRank.minPoints .. " bis " .. nextRank.name)
        else
            rankBar:SetMinMaxValues(0, 1)
            rankBar:SetValue(1)
            rankBarFs:SetText("Maximaler Rang erreicht")
        end
    end

    local divider = content:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(0.4, 0.4, 0.4, 0.7)
    divider:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -RANK_BAR_H)
    divider:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -RANK_BAR_H)

    local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     content, "TOPLEFT",     0, -(RANK_BAR_H + 6))
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -20, 0)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        sf:SetVerticalScroll(
            math.max(0, math.min(sf:GetVerticalScrollRange(), sf:GetVerticalScroll() - delta * 24))
        )
    end)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    local cards = {}

    local function Refresh()
        RefreshRank()

        for _, c in ipairs(cards) do c:Hide() end
        wipe(cards)

        local cardW = math.max(1, scrollFrame:GetWidth())
        scrollChild:SetWidth(cardW)
        local yOff = 0

        local entries = VisibleEntries()

        if #entries == 0 then
            local msg = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            msg:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, 0)
            msg:SetText("Noch keine Erfolge definiert.")
            msg:SetTextColor(0.6, 0.6, 0.6, 1)
            table.insert(cards, msg)
            yOff = -20
        else
            for _, entry in ipairs(entries) do
                local card = CreateCard(scrollChild, cardW, entry)
                card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOff)
                table.insert(cards, card)
                yOff = yOff - card:GetHeight() - CARD_GAP
            end
        end

        scrollChild:SetHeight(math.max(1, -yOff))
    end

    content.Refresh = Refresh
end
