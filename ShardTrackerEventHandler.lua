-- ####################################################################
-- ##                          Event Variables                       ##
-- ####################################################################

-- The last zone id that was encountered.
ShardTracker.zone_id = nil

-- The current shard id.
ShardTracker.shard_id = nil

-- A flag used to detect guardians or pets.
local companion_type_mask = bit.bor(
    COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_OBJECT
)

-- For some reason... the Sha of Anger is a... vehicle?
local valid_unit_types = {
    ["Creature"] = true,
    ["Vehicle"] = true
}

-- ####################################################################
-- ##                           Event Handlers                       ##
-- ####################################################################

-- Called whenever the user changes to a new zone or area.
function ShardTracker:OnZoneTransition()
    -- The zone the player is in.
    local zone_id = C_Map.GetBestMapForUnit("player")
    
    -- The map id may not always be available. See bug #2 in the Dragonflight module.
    if not zone_id then return end
    
    -- Update the zone id and keep the last id.
    local last_zone_id = self.zone_id
    self.zone_id = zone_id
    
    -- Check if the zone id changed. If so, reset the shard id.
    if self.zone_id ~= last_zone_id then
        self:ChangeZone()
    end
end

-- Fetch the new list of rares and ensure that these rares are properly displayed.
function ShardTracker:ChangeZone()
    -- Reset the shard id
    self:ChangeShard(nil)
    self:Debug("Changing zone to", C_Map.GetBestMapForUnit("player"))
end

-- Transfer to a new shard, reset current data and join the appropriate channel.
function ShardTracker:ChangeShard(zone_uid)
    -- Set the new shard id.
    self.shard_id = zone_uid
    
    -- Update the shard number in the display.
    self:UpdateShardNumber()
end

-- Check whether the user has changed shards and proceed accordingly.
-- Return true if the shard changed, false otherwise.
function ShardTracker:CheckForShardChange(zone_uid)
    if self.shard_id ~= zone_uid and zone_uid ~= nil then
        print("<ST> Moving to shard "..zone_uid..".")
        self:ChangeShard(zone_uid)
        return true
    end
    return false
end

-- This event is fired whenever the player's target is changed, including when the target is lost.
function ShardTracker:PLAYER_TARGET_CHANGED()
    self:OnHealthDetection("target", "PLAYER_TARGET_CHANGED")
end

-- Fired when the mouseover object needs to be updated. 
function ShardTracker:UPDATE_MOUSEOVER_UNIT()
    self:OnHealthDetection("mouseover", "UPDATE_MOUSEOVER_UNIT")
end

-- Fired whenever a unit's health is affected.
function ShardTracker:UNIT_HEALTH(_, unit)
    if unit == "target" or unit:find("nameplate") then
        self:OnHealthDetection(unit, "UNIT_HEALTH")
    end
end

function ShardTracker:OnHealthDetection(unit, event_id)
    -- Get information about the target.
    local guid = UnitGUID(unit)
    
    if guid and not UnitPlayerControlled(unit) then
        -- unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid
        local unittype, _, _, _, zone_uid, npc_id, spawn_uid = strsplit("-", guid)
        npc_id = tonumber(npc_id)
        
        -- It might occur that the NPC id is nil. Do not proceed in such a case.
        if not npc_id then return end
        
        -- Certain entities retain their zone_uid even after moving shards. Ignore them.
        if not self.db.global.banned_NPC_ids[npc_id] then
            if self:CheckForShardChange(zone_uid) then
                self:Debug(event_id, unit, guid)
            end
        end
    end
end

-- Fires for combat events such as a player casting a spell or an NPC taking damage.
function ShardTracker:COMBAT_LOG_EVENT_UNFILTERED()
    -- The event does not have a payload (8.0 change). Use CombatLogGetCurrentEventInfo() instead.
    -- timestamp, subevent, zero, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
    -- destGUID, destName, destFlags, destRaidFlags
    local _, subevent, _, sourceGUID, _, _, _, destGUID, _, destFlags, _ = CombatLogGetCurrentEventInfo()
    
    -- unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid
    local unittype, _, _, _, zone_uid, npc_id, spawn_uid = strsplit("-", destGUID)
    npc_id = tonumber(npc_id)
    
    -- It might occur that the NPC id is nil. Do not proceed in such a case.
    if not npc_id or not destFlags then return end
    
    -- Blacklist the entity.
    if not self.db.global.banned_NPC_ids[npc_id] and bit.band(destFlags, companion_type_mask) > 0 then
        self.db.global.banned_NPC_ids[npc_id] = true
    end
    
    -- We can always check for a shard change.
    -- We only take fights between creatures, since they seem to be the only reliable option.
    -- We exclude all pets and guardians, since they might have retained their old shard change.
    if valid_unit_types[unittype] and not self.db.global.banned_NPC_ids[npc_id] and bit.band(destFlags, companion_type_mask) == 0 then
        if self:CheckForShardChange(zone_uid) then
            self:Debug("[COMBAT_LOG_EVENT_UNFILTERED]", sourceGUID, destGUID)
        end
    end
end

-- Fired whenever a vignette appears or disappears in the minimap.
function ShardTracker:VIGNETTE_MINIMAP_UPDATED(_, vignetteGUID, _)
    local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
    local uiMapID = C_Map.GetBestMapForUnit("player")
    
    -- The map id may not always be available. See bug #2 in the Dragonflight module.
    if not uiMapID then return end
    
    local vignetteLocation, _ = C_VignetteInfo.GetVignettePosition(vignetteGUID, uiMapID)

    if vignetteInfo and vignetteLocation then
        -- Report the entity.
        -- unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid
        local unittype, _, _, _, zone_uid, npc_id, spawn_uid = strsplit("-", vignetteInfo.objectGUID)
        npc_id = tonumber(npc_id)
    
        -- It might occur that the NPC id is nil. Do not proceed in such a case.
        if not npc_id then return end
        
        if valid_unit_types[unittype] then
            if not self.db.global.banned_NPC_ids[npc_id] then
                if self:CheckForShardChange(zone_uid) then
                    self:Debug("[VIGNETTE_MINIMAP_UPDATED]", vignetteInfo.objectGUID)
                end
            end
        end
    end
end

-- ####################################################################
-- ##                   Event Handler Helper Functions               ##
-- ####################################################################

-- Register the events that are needed for the proper tracking of rares.
function ShardTracker:RegisterTrackingEvents()
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
end