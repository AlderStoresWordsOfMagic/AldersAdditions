-- [Imaginator - Fusion's bombBeams do not hit rooms, only tiles, so this was written to reduce the number of bombs generated. Thanks, Arc.]

-- Find ID of a room at the given location
local function get_room_at_location(shipManager, location, includeWalls)
    return Hyperspace.ShipGraph.GetShipInfo(shipManager.iShipId):GetSelectedRoom(location.x, location.y, includeWalls)
end

script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM, function(shipManager, projectile, location, damage, realNewTile, beamHitType)
    if projectile and projectile.extend.name == "AA_BEAM_IMAGINE" and beamHitType == Defines.BeamHit.NEW_ROOM then
        local blueprint = Hyperspace.Blueprints:GetWeaponBlueprint("AA_LIST_WEAPON_IMAGINATOR_BLASTS")
        local roomLoc = shipManager:GetRoomCenter(get_room_at_location(shipManager, location, true))
        local spaceManager = Hyperspace.App.world.space
        if get_room_at_location(shipManager, location, true) ~= -1 then -- Fixes a bug where passing over empty rooms would make bombs appear in the top left
            spaceManager:CreateBomb(blueprint, projectile.ownerId, roomLoc, shipManager.iShipId)
        end
    end
    return Defines.Chain.CONTINUE, beamHitType
end)