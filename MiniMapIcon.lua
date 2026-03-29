-- MiniMapIcon.lua
-- Creates and manages the minimap icon for the addon

-- Load required libraries for the minimap icon. 'true' suppresses errors if not found.
local LDB = LibStub("LibDataBroker-1.1", true)
local DBIcon = LibStub("LibDBIcon-1.0", true)

-- Data object for the minimap icon
if LDB then -- Only proceeds if LibDataBroker is available
    SchlingelInc.minimapDataObject = LDB:NewDataObject(SchlingelInc.name, {
        type = "launcher",                                                 -- LDB object type: Launches a UI or function
        label = SchlingelInc.name,                                         -- Text next to icon (often only visible in LDB display addons)
        icon = "Interface\\AddOns\\SchlingelInc\\media\\graphics\\icon-minimap.tga", -- Path to icon
        OnClick = function(clickedFrame, button)
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    SchlingelInc:ToggleDeathLogWindow()
                else
                    SchlingelInc.GuildPanel:Toggle()
                end
            elseif button == "RightButton" then
                if CanGuildInvite() then
                    if SchlingelInc.ToggleInactivityWindow then
                        SchlingelInc:ToggleInactivityWindow()
                    end
                else
                    -- Not in guild - show guild join prompt
                    SchlingelInc:ShowGuildJoinPrompt()
                end
            end
        end,

        -- Tooltip shown when hovering over the icon
        OnEnter = function(selfFrame)
            GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")
            GameTooltip:AddLine(SchlingelInc.name, 1, 0.7, 0.9)
            GameTooltip:AddLine("Version: " .. (SchlingelInc.version or "Unknown"), 1, 1, 1)
            GameTooltip:AddLine("Linksklick: Gilde anzeigen", 1, 1, 1)
            GameTooltip:AddLine("Shift+Linksklick: Tode anzeigen", 0.8, 0.8, 0.8)
            if CanGuildInvite() then
                GameTooltip:AddLine("Rechtsklick: Inaktive Mitglieder", 0.8, 0.8, 0.8)
            elseif not IsInGuild() then
                GameTooltip:AddLine("Rechtsklick: Gilde beitreten", 1, 1, 1)
            end
            GameTooltip:Show()
        end,
        OnLeave = function()
            GameTooltip:Hide()
        end
    })
else
    -- Output message if LibDataBroker was not found
end

-- Initializes the minimap icon
function SchlingelInc:InitMinimapIcon()
    -- Abort if LibDBIcon or the LDB data object are not available
    if not DBIcon or not SchlingelInc.minimapDataObject then
        return
    end

    -- Register the icon only once
    if not SchlingelInc.minimapRegistered then
        -- Initialize the database for minimap settings if not present
        SchlingelInc.db = SchlingelInc.db or {}
        SchlingelInc.db.minimap = SchlingelInc.db.minimap or { hide = false } -- Not hidden by default

        -- Register the icon with LibDBIcon
        DBIcon:Register(SchlingelInc.name, SchlingelInc.minimapDataObject, SchlingelInc.db.minimap)
        SchlingelInc.minimapRegistered = true -- Mark icon as registered
    end
end