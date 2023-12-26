-- Width and height variables used to customize the window.
local shard_id_frame_height = 16
local shard_id_frame_width = 150
local frame_padding = 4

-- Values for the opacity of the background and foreground.
local background_opacity = 0.0
local foreground_opacity = 0.6

-- ####################################################################
-- ##                        Interface Control                       ##
-- ####################################################################

-- Show the shard id on the screen.
function ShardTracker:OpenWindow()
    -- Show the window if it is not hidden.
    if not self.db.global.window.hide then
        self.gui:Show()
    end
end

-- Close the window.
function ShardTracker:CloseWindow()
    -- Simply hide the interface.
    self.gui:Hide()
end

-- Update the shard number in the shard number display.
function ShardTracker:UpdateShardNumber()
    if self.shard_id then
        self.gui.shard_id_frame.status_text:SetText(string.format("Shard ID: %s", self.shard_id))
    else
        self.gui.shard_id_frame.status_text:SetText(string.format("Shard ID: %s", "Unknown"))
    end
end

-- ####################################################################
-- ##                          Initialization                        ##
-- ####################################################################

-- Create the current shard number frame.
function ShardTracker.InitializeShardNumberFrame(parent)
    local f = CreateFrame("Frame", "ST.shard_id_frame", parent)
    local width = shard_id_frame_width + 2 * frame_padding
    local height = shard_id_frame_height + 2 * frame_padding
    f:SetSize(width, height)
    f:SetPoint("TOPLEFT", parent, 0, 0)
  
    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetColorTexture(0, 0, 0, foreground_opacity)
    f.texture:SetAllPoints(f)
    
    f.status_text = f:CreateFontString(nil, nil, "GameFontNormal")
    f.status_text:SetPoint("TOPLEFT", frame_padding, -frame_padding - 1.5)
    f.status_text:SetText(string.format("Shard ID: %s", "Unknown"))
    
    parent.shard_id_frame = f
end

-- Initialize the addon's entity frame.
function ShardTracker:InitializeInterface()
    local f = self.gui
    
    f:SetSize(
        shard_id_frame_width + 2 * frame_padding,
        shard_id_frame_height + 2 * frame_padding
    )
    if self.db.global.window.position then
        local anchor, x, y = unpack(self.db.global.window.position)
        f:SetPoint(anchor, x, y)
    else
        f:SetPoint("CENTER")
    end
            
    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetColorTexture(0, 0, 0, background_opacity)
    f.texture:SetAllPoints(f)
    
    -- Create a sub-frame for the entity names.
    self.InitializeShardNumberFrame(f)
    
    -- Make the window moveable and ensure that the window stays where the user puts it.
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:EnableMouse(true)
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(_f)
        _f:StopMovingOrSizing()
        local _, _, anchor, x, y = _f:GetPoint()
        self.db.global.window.position = {anchor, x, y}
        self:Debug("New frame position", anchor, x, y)
    end)
    
    -- Enforce the user-defined scale of the window.
    f:SetScale(self.db.global.window.scale)
    
    -- Show based on the state of the window.
    if self.db.global.window.hide then
        self.gui:Hide()
    else
        self.gui:Show()
    end
end