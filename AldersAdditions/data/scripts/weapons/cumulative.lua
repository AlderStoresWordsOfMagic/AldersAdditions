-- [Cumulative weapons - Charges damage instead of shot count.]

mods.alder.statChargers = {}
local statChargers = mods.alder.statChargers

statChargers["AA_LASER_CHARGEGUN_DAMAGE"] = {{stat = "iDamage"}, {stat = "iDamage"}}
statChargers["AA_SHOTGUN_CHARGEGUN_DAMAGE"] = {{stat = "iDamage"}, {stat = "iDamage"}}
statChargers["AA_ION_CHARGEGUN_DAMAGE"] = {{stat = "iIonDamage"}, {stat = "iIonDamage"}}
statChargers["AA_ENERGY_CHARGEGUN_DAMAGE"] = {{stat = "iIonDamage"}}
statChargers["AA_BEAM_CHARGEGUN_DAMAGE"] = {{stat = "iDamage"}} -- nonfunctional, not present rigth now

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local statBoosts = statChargers[weapon.blueprint.name]
    if statBoosts then
        local shotsPerCharge = weapon.blueprint.miniProjectiles:size() --How many shots per charge (projectiles defined in <projectiles>)
        if shotsPerCharge == 0 then 
            shotsPerCharge = 1 --Adjust for non-flak weapons
        end
        local queuedProjectiles = weapon.queuedProjectiles:size() -- Gets how many projectiles are charged up (doesn't include the one that was already shot)
        local boost = queuedProjectiles // shotsPerCharge -- Gets how many charges are full
        if queuedProjectiles % shotsPerCharge == 0 then --If all projectiles in a charge have been fired
             weapon.queuedProjectiles:clear() -- Delete all other projectiles
        end
        if projectile.death_animation.fScale ~= 0.25 then --If projectile is not fake then
            for _, statBoost in ipairs(statBoosts) do -- Apply all stat boosts
                if statBoost.calc then
                    projectile.damage[statBoost.stat] = statBoost.calc(boost, projectile.damage[statBoost.stat])
                else
                    projectile.damage[statBoost.stat] = boost + projectile.damage[statBoost.stat]
                end
            end
        end
    end
end)