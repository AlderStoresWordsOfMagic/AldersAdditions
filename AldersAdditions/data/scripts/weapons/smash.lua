local userdata_table = mods.multiverse.userdata_table

-- [Smash Weapons - Pop shield without hull damage on collision with shield, and crush when fully drained.]

mods.alder.popWeapons = {}
local popWeapons = mods.alder.popWeapons

popWeapons["AA_LASER_SMASH"] = {
    count = 1, -- Number of shield layers to pop
    countSuper = 1, -- Number of super shield layers to pop
    crush = 1, -- If this weapon reduces shields to 0, apply this many layers of crushed shields
    reduction = 0.6, -- Percentage to reduce shield recharge rate by while crushed
    onHit = false -- If true, the weapon pops and crushes when it hits the hull instead of when it hits shields
}
popWeapons["AA_LASER_SMASH_2"] = {
    count = 1,
    countSuper = 1,
    crush = 1,
    reduction = 0.6,
    onHit = false
}
popWeapons["AA_DRONE_LASER_SMASH"] = {
    count = 1,
    countSuper = 1,
    crush = 1,
    reduction = 0.6,
    onHit = false
}
popWeapons["AA_BEAM_SMASH"] = {
    count = 2,
    countSuper = 2,
    crush = 1,
    reduction = 0.6,
    onHit = false
}
popWeapons["AA_MISSILES_SMASH"] = {
    count = 4,
    countSuper = 4,
    crush = 1,
    reduction = 0.6,
    onHit = true
}
popWeapons["AA_MISSILES_SMASH_ENEMY"] = {
    count = 4,
    countSuper = 4,
    crush = 1,
    reduction = 0.6,
    onHit = true
}
popWeapons["AA_BOMB_SMASH"] = {
    count = 4,
    countSuper = 4,
    crush = 1,
    reduction = 0.6,
    onHit = true
}
popWeapons["AA_BOMB_SMASH_ENEMY"] = {
    count = 4,
    countSuper = 4,
    crush = 1,
    reduction = 0.6,
    onHit = true
}

-- Apply crush on shield hit
local function crush_shield(popData, ship, x, y)
    local shieldPower = ship.shieldSystem.shields.power
    if shieldPower.super.first > 0 then
        if popData.countSuper > 0 then
            ship.shieldSystem:CollisionReal(x, y, Hyperspace.Damage(), true)
            shieldPower.super.first = math.max(0, shieldPower.super.first - popData.countSuper)
        end
    else
        ship.shieldSystem:CollisionReal(x, y, Hyperspace.Damage(), true)
        shieldPower.first = math.max(0, shieldPower.first - popData.count)
        if shieldPower.first == 0 then
            local shieldTracker = userdata_table(ship, "mods.aa.shieldCrush")
            if not shieldTracker.crush then shieldTracker.crush = {} end
            for i = 1, popData.crush do
                table.insert(shieldTracker.crush, 1, popData.reduction)
            end
            Hyperspace.Sounds:PlaySoundMix("shield_crush", -1, true)
        end
    end
end
script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(ship, projectile, location, damage, shipFriendlyFire)
    local popData = popWeapons[projectile and projectile.extend and projectile.extend.name]
    if popData and popData.onHit then
        crush_shield(popData, ship, location.x, location.y)
    end
end)
script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(ship, projectile, damage, response)
    local popData = popWeapons[projectile and projectile.extend and projectile.extend.name]
    if popData and not popData.onHit then
        crush_shield(popData, ship, projectile.position.x, projectile.position.y)
    end
end)

-- Reduce number of shields crushed when one recharges
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
    local shieldTracker = userdata_table(ship, "mods.aa.shieldCrush")
    shieldTracker.currentShields = ship._targetable:GetShieldPower().first
    if shieldTracker.crush and shieldTracker.previousShields then
        local crushesToEnd = shieldTracker.currentShields - shieldTracker.previousShields
        while crushesToEnd > 0 and #shieldTracker.crush > 0 do
            shieldTracker.crush[#shieldTracker.crush] = nil
            crushesToEnd = crushesToEnd - 1
        end
    end
    shieldTracker.previousShields = shieldTracker.currentShields
end)

-- Reduce shield recharge rate while crushed
script.on_internal_event(Defines.InternalEvents.GET_AUGMENTATION_VALUE, function(ship, augName, augValue)
    if ship and augName == "SHIELD_RECHARGE" then
        local shieldTracker = userdata_table(ship, "mods.aa.shieldCrush")
        if shieldTracker.crush and #shieldTracker.crush > 0 then
            augValue = augValue - shieldTracker.crush[#shieldTracker.crush]
        end
    end
    return Defines.Chain.CONTINUE, augValue
end)