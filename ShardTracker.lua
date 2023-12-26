-- ####################################################################
-- ##                              Core                              ##
-- ####################################################################

-- Create the primary addon object.
ShardTracker = LibStub("AceAddon-3.0"):NewAddon("ShardTracker", "AceConsole-3.0", "AceEvent-3.0")

-- ####################################################################
-- ##                           Variables                            ##
-- ####################################################################

-- The short-hand code of the addon.
ShardTracker.addon_code = "ST"

-- Create the frame, such that the position will be saved correctly.
ShardTracker.gui = CreateFrame("Frame", ShardTracker.addon_code, UIParent)

-- NPCs that are banned during shard detection.
-- Player followers sometimes spawn with the wrong zone id.
local banned_NPC_ids = {
    154297, 150202, 154304, 152108, 151300, 151310, 142666, 142668, 69792, 62821, 62822, 32639, 32638, 89715, 89713, 180182, 180181, 180483, 180208, 183143
}

-- Define the default settings.
local defaults = {
    global = {
        debug = {
            enable = false,
        },
        window = {
            hide = false,
            scale = 1.0
        },
        banned_NPC_ids = {}
    },
    profile = {
        minimap = {
            hide = false,
        },
    },
}

-- ####################################################################
-- ##                    Initial Event Handling                      ##
-- ####################################################################

-- Fired when new all rare tracker modules have registered their data to the core.
function ShardTracker:PLAYER_LOGIN()
    -- We no longer need the player login event. Unsubscribe.
    self:UnregisterEvent("PLAYER_LOGIN")
    
    -- There are several npcs that always have to be banned to avoid incorrect shard changes.
    for _, npc_id in pairs(banned_NPC_ids) do
        self.db.global.banned_NPC_ids[npc_id] = true
    end
    
    self:InitializeOptionsMenu()
    self:InitializeShardTrackerLDB()
    
    -- Register the resired chat commands.
    self:RegisterChatCommand("st", "OnChatCommand")
    self:RegisterChatCommand("shardtracker", "OnChatCommand")
    
    -- Initialize the interface.
    self:InitializeInterface()
    
    -- Register all the events that have to be tracked continuously.
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneTransition")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnZoneTransition")
    self:RegisterEvent("ZONE_CHANGED", "OnZoneTransition")
    self:RegisterTrackingEvents()
end

-- ####################################################################
-- ##                     Standard Ace3 Methods                      ##
-- ####################################################################

-- A function that is called when the addon is first loaded.
function ShardTracker:OnInitialize()
    -- Load the database.
    self.db = LibStub("AceDB-3.0"):New("ShardTrackerDB", defaults, true)
    
    -- Wait for the player login event before initializing the rest of the data.
    self:RegisterEvent("PLAYER_LOGIN")
end

-- ####################################################################
-- ##                            Commands                            ##
-- ####################################################################

-- A function that is called when calling a chat command.
function ShardTracker:OnChatCommand(input)
    input = input:trim()
    if not input or input == "" then
        Settings.OpenToCategory("ShardTracker")
    else
        local _, _, cmd, _ = string.find(input, "%s?(%w+)%s?(.*)")
        local zone_id = C_Map.GetBestMapForUnit("player")
        if cmd == "show" then
            self.gui:Show()
            self.db.global.window.hide = false
        elseif cmd == "hide" then
            self.gui:Hide()
            self.db.global.window.hide = true
        end
    end
end

-- ####################################################################
-- ##                        Helper functions                        ##
-- ####################################################################

-- A print function used for debug purposes.
function ShardTracker:Debug(...)
	if self.db and self.db.global.debug.enable then
		print("[Debug.ST]", ...)
	end
end