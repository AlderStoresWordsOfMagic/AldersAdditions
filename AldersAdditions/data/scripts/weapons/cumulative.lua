-- [Cumulative Weapons - Charges damage instead of shot count.]

mods.alder.statChargers = {}
local statChargers = mods.alder.statChargers

statChargers["AA_LASER_CHARGEGUN_DAMAGE"] = {iDamage = 2}
statChargers["AA_SHOTGUN_CHARGEGUN_DAMAGE"] = {iDamage = 2}
statChargers["AA_ION_CHARGEGUN_DAMAGE"] = {iIonDamage = 2}
statChargers["AA_ENERGY_CHARGEGUN_DAMAGE"] = {iIonDamage = 1}
statChargers["AA_BEAM_CHARGEGUN_DAMAGE"] = {iDamage = 1}

local needsNameGenerated = true -- For later

-- Change damage based on charge count, and destroy excess projectiles
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

-- Change short name based on stability
script.on_game_event("START_BEACON", false, function() needsNameGenerated = true end)
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if needsNameGenerated then
        local stability = Hyperspace.playerVariables.stability

        -- Set up weapon data
        local shortDescLaser = stability >= 200 and "Laser Acc." or "Cum. Laser"
        local blueprintLaser = Hyperspace.Blueprints:GetWeaponBlueprint("AA_LASER_CHARGEGUN_DAMAGE")
        local shortDescShotgun = stability >= 200 and "Flak Acc." or "Cum. Flak"
        local blueprintShotgun = Hyperspace.Blueprints:GetWeaponBlueprint("AA_SHOTGUN_CHARGEGUN_DAMAGE")
        local shortDescIon = stability >= 200 and "Ion Acc." or "Cum. Ion"
        local blueprintIon = Hyperspace.Blueprints:GetWeaponBlueprint("AA_ION_CHARGEGUN_DAMAGE")
        local shortDescEnergy = stability >= 200 and "Energy Acc." or "Cum. Energy"
        local blueprintEnergy = Hyperspace.Blueprints:GetWeaponBlueprint("AA_ENERGY_CHARGEGUN_DAMAGE")
        local shortDescBeam = stability >= 200 and "'Woldo'" or "Cum. Beam"
        local blueprintBeam = Hyperspace.Blueprints:GetWeaponBlueprint("AA_BEAM_CHARGEGUN_DAMAGE")

        -- Change the name
        blueprintLaser.desc.shortTitle.data = shortDescLaser
        blueprintShotgun.desc.shortTitle.data = shortDescShotgun
        blueprintIon.desc.shortTitle.data = shortDescIon
        blueprintEnergy.desc.shortTitle.data = shortDescEnergy
        blueprintBeam.desc.shortTitle.data = shortDescBeam

        -- Don't change name until another run is started
        needsNameGenerated = false
    end
end)