-- [Cumulative Weapons - Charges damage instead of shot count.]

mods.alder.statChargers = {}
local statChargers = mods.alder.statChargers

statChargers["AA_LASER_CHARGEGUN_DAMAGE"] = {iDamage = 2}
statChargers["AA_SHOTGUN_CHARGEGUN_DAMAGE"] = {iDamage = 2}
statChargers["AA_ION_CHARGEGUN_DAMAGE"] = {iIonDamage = 2}
statChargers["AA_ENERGY_CHARGEGUN_DAMAGE"] = {iIonDamage = 1}
statChargers["AA_BEAM_CHARGEGUN_DAMAGE"] = {iDamage = 1} -- nonfunctional, not present right now

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local statBoosts = statChargers[weapon.blueprint.name]
    if statBoosts then
        local shotsPerCharge = weapon.blueprint.miniProjectiles:size() --How many shots per charge (projectiles defined in <projectiles>)
        if shotsPerCharge == 0 then
            shotsPerCharge = 1 -- Adjust for non-flak weapons
        end
        local boost = weapon.weaponVisual.boostLevel -- Gets how many charges are full
        if weapon.queuedProjectiles:size() % shotsPerCharge == 0 then -- If all projectiles in a charge have been fired
             weapon.queuedProjectiles:clear() -- Delete all other projectiles
        end
        if projectile.death_animation.fScale ~= 0.25 then -- If projectile is not fake then
            for stat, amount in pairs(statBoosts) do -- Apply all stat boosts
                projectile.damage[stat] = (amount * boost) + projectile.damage[stat]
            end
        end
    end
end)