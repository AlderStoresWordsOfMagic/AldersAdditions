local vter = mods.multiverse.vter
local userdata_table = mods.multiverse.userdata_table
local get_room_at_location = mods.multiverse.get_room_at_location
local get_ship_crew_point = mods.multiverse.get_ship_crew_point
local INT_MAX = mods.multiverse.INT_MAX

-- [Cores - Weapons that do not fire, but provide effects and stat bonuses to the weapon to their right.]

mods.alder.cores = {}
local cores = mods.alder.cores

-- Take the stats of the core itself and add them to the target weapon, up to specific maximums
local coreIDs = {}
coreIDs.AA_CORE_PARTICLE = true
coreIDs.AA_CORE_BIO = true
coreIDs.AA_CORE_ION = true
coreIDs.AA_CORE_FIRE = true
coreIDs.AA_CORE_BREACH = true
coreIDs.AA_CORE_STUN = true
coreIDs.AA_CORE_MADNESS = true
coreIDs.POWER_CORE = true -- Allows MV's own power core to chain with other cores.


-- Stat application logic, by sillysandvich
script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local weapons = Hyperspace.ships(weapon.iShipId).weaponSystem.weapons
    local weaponIdx
    
    for i = 0, weapons:size() - 1 do -- Find index of firing weapon
        if weapons[i] == weapon then
            weaponIdx = i
            break
        end
    end
    -- Iterate backwards over all adjacent cores
    for i = weaponIdx - 1, 0, -1 do
        local coreWeapon = weapons[i]
        if coreIDs[coreWeapon.blueprint.name] ~= nil and coreWeapon.powered then
            -- CORE EFFECTS

            -- Get the damage stats that can be modified
            local damageProperties = {
                "iDamage", "iSystemDamage", "iPersDamage", "iIonDamage",
                "fireChance", "breachChance", "stunChance", "iStun"
            }

            -- Get and apply the "custom" (HS-exclusive) damage stats that can be modified. TODO: Change when CustomWeaponManager is exposed, current workaround for getting a blueprint's CustomDamage
            local dummyProj = Hyperspace.App.world.space:CreateLaserBlast(coreWeapon.blueprint, Hyperspace.Pointf(INT_MAX, INT_MAX), 0, -1, Hyperspace.Pointf(INT_MAX, INT_MAX), 0, -1) -- Create a dummy projectile to store the core's stats
            local projTable = userdata_table(projectile, "mods.alder.cores") -- Create a userdata table to store the properties of the shot projectile
            table.insert(projTable, dummyProj.extend.customDamage.def) -- Shove the ENTIRETY of customDamage into projTable

            -- Add the base damage properties to the projectile
            local oldIonDamage = projectile.damage.iIonDamage
            for _, v in ipairs(damageProperties) do
                projectile.damage[v] = projectile.damage[v] + coreWeapon.blueprint.damage[v]
            end
            if projectile:GetType() == 5 then -- Reset ion damage of beams to original. Due to implementation difficulties, ion damage cannot be added to beams.
                projectile.damage.iIonDamage = oldIonDamage
            end

            dummyProj:Kill() -- Delete the now-purposeless dummy to avoid projectile buildup
        else
            break
        end
    end
end)

local function apply_additional_boosts_to_crew(projectile, crew)
    local tab = userdata_table(projectile, "mods.alder.cores")
    for _, def in ipairs(tab) do
        for boost in vter(def.statBoosts) do
            Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(boost), crew)
        end
    end
end

script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM, function(shipManager, projectile, location, damage, realNewTile, beamHitType)
    if beamHitType == Defines.BeamHit.NEW_TILE or beamHitType == Defines.BeamHit.NEW_ROOM then
        for _, crew in ipairs(get_ship_crew_point(shipManager, location.x, location.y)) do
            apply_additional_boosts_to_crew(projectile, crew)
        end
    end
    return Defines.Chain.CONTINUE, beamHitType
end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
    if projectile then
        local roomId = get_room_at_location(shipManager, location, true)
        for crew in vter(shipManager.vCrewList) do
            local doBoost = crew.iRoomId == roomId
            if doBoost then
                apply_additional_boosts_to_crew(projectile, crew)
            end
        end
    end
    return Defines.Chain.CONTINUE
end)