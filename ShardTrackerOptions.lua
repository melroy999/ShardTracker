-- ####################################################################
-- ##                        Helper Functions                        ##
-- ####################################################################

-- Get an incremental order index to enforce the ordering of options.
ShardTracker.current_order_index = 0
function ShardTracker:GetOrder()
    self.current_order_index = self.current_order_index + 1
    return self.current_order_index
end

-- Refresh the option menu.
function ShardTracker.NotifyOptionsChange()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("ShardTracker")
end

-- ####################################################################
-- ##                             Options                            ##
-- ####################################################################

-- Initialize the minimap button.
function ShardTracker:InitializeShardTrackerLDB()
    self.ldb_data = {
        type = "data source",
        text = "ST",
        icon = "Interface\\AddOns\\ShardTracker\\Icons\\ShardTrackerIcon",
        OnClick = function(_, button)
            if button == "LeftButton" then
                if self.db.global.window.hide then
                    self.gui:Show()
                    self.db.global.window.hide = false
                else
                    self.gui:Hide()
                    self.db.global.window.hide = true
                end
            else
                Settings.OpenToCategory("ShardTracker")
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText("ShardTracker")
            tooltip:Show()
        end
    }
    self.ldb = LibStub("LibDataBroker-1.1"):NewDataObject("ShardTracker", self.ldb_data)
    
    -- Register the icon.
    self.icon = LibStub("LibDBIcon-1.0")
    self.icon:Register("ShardTrackerIcon", self.ldb, self.db.profile.minimap)
    if self.db.profile.minimap.hide then
        self.icon:Hide("ShardTrackerIcon")
    end
end

-- Initialize the options menu for the addon.
function ShardTracker:InitializeOptionsMenu()
    self.options_table = {
        name = "ShardTracker (ST)",
        handler = ShardTracker,
        type = 'group',
        childGroups = "tree",
        order = self:GetOrder(),
        args = {
            general = {
                type = "group",
                name = "Options",
                order = self:GetOrder(),
                inline = true,
                args = {
                    minimap = {
                        type = "toggle",
                        name = "Show minimap icon",
                        desc = "Show/hide the ST minimap icon.",
                        width = "full",
                        order = self:GetOrder(),
                        get = function()
                            return not self.db.profile.minimap.hide
                        end,
                        set = function(_, val)
                            self.db.profile.minimap.hide = not val
                            if self.db.profile.minimap.hide then
                                self.icon:Hide("ShardTrackerIcon")
                            else
                                self.icon:Show("ShardTrackerIcon")
                            end
                        end
                    },
                    debug = {
                        type = "toggle",
                        name = "Enable debug mode",
                        desc = "Show ST debug output in the chat.",
                        width = "full",
                        order = self:GetOrder(),
                        get = function()
                            return self.db.global.debug.enable
                        end,
                        set = function(_, val)
                            self.db.global.debug.enable = val
                        end
                    },
                    window_scale = {
                        type = "range",
                        name = "Rare window scale",
                        desc = "Set the scale of the rare window.",
                        min = 0.5,
                        max = 2,
                        step = 0.05,
                        isPercent = true,
                        order = self:GetOrder(),
                        width = 1.2,
                        get = function()
                            return self.db.global.window.scale
                        end,
                        set = function(_, val)
                            self.db.global.window.scale = val
                            self.gui:SetScale(val)
                        end
                    }
                }
            }
        }
    }
    
    -- Register the options.
    LibStub("AceConfig-3.0"):RegisterOptionsTable("ShardTracker", self.options_table)
    self.options_frame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ShardTracker", "ShardTracker")
end