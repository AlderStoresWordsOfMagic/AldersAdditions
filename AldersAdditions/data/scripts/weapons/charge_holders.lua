local vter = mods.multiverse.vter

-- [Charge Holders - Mass Drivers do not lose charge when unpowered.]

mods.alder.holders = {}
local holders = mods.alder.holders

holders["AA_DRIVER"] = {chargeRate = 0.25} -- Rate of usual at which to charge; 1 = normal charge rate
holders["AA_DRIVER_BIO"] = {chargeRate = 0.25}
holders["AA_DRIVER_EXPLOSIVE"] = {chargeRate = 0.25}
holders["AA_DRIVER_SHOTGUN"] = {chargeRate = 0.25}
holders["AA_DRIVER_ION"] = {chargeRate = 0.25}
holders["AA_DRIVER_PARTICLE"] = {chargeRate = 0.25}

holders["AA_RAILGUN"] = {chargeRate = 0.25}

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    for weapon in vter(shipManager:GetWeaponList()) do
        if (not weapon.powered) and holders[weapon.blueprint.name] then
            weapon.cooldown.first = (math.min(weapon.cooldown.first + (Hyperspace.FPS.SpeedFactor * (6 + (holders[weapon.blueprint.name].chargeRate * weapon.cooldownModifier))) / 16, weapon.cooldown.second - 0.01))
        end
    end
end)