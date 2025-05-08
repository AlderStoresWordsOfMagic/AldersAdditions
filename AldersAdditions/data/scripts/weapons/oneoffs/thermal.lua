local get_room_at_location = mods.multiverse.get_room_at_location

local fires = mods.fusion.fires

-- [Thermal Crusher - Turn all fires into breaches, +1 damage per converted fire]

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA, function(shipManager, projectile, location, damage, forceHit, shipFriendlyFire)
    if projectile and projectile.extend.name == "AA_LASER_STRAIN" then
        local fireCount = shipManager:GetFireCount(get_room_at_location(shipManager, location, true))
        damage.iDamage = damage.iDamage + fireCount  
    end

    return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
    if projectile and projectile.extend.name == "AA_LASER_STRAIN" then
        for fire in fires(shipManager.ship.vRoomList[get_room_at_location(shipManager, location, true)], shipManager) do -- Need the room object to run this properly
            fire.fDamage = 0
            shipManager.ship:BreachSpecificHull(fire.pLoc.x / 35, fire.pLoc.y / 35)
        end
    end
end)