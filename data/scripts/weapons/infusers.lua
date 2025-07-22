local vter = mods.multiverse.vter
local userdata_table = mods.multiverse.userdata_table
local get_room_at_location = mods.multiverse.get_room_at_location
local get_ship_crew_point = mods.multiverse.get_ship_crew_point
local is_first_shot = mods.multiverse.is_first_shot
local INT_MAX = mods.multiverse.INT_MAX

-- XML parsing imports
local weaponTagParsers = mods.multiverse.weaponTagParsers

-- [Infusers - Weapons that do not fire, but provide effects and stat bonuses to the weapon to their right.]


-- Take the stats of the infuser itself and add them to the target weapon, up to specific maximums, by XML tag
local infuserIDs = {}
table.insert(weaponTagParsers, function(weaponNode)
    if weaponNode:first_node("aa-infuser") then
        infuserIDs[weaponNode:first_attribute("name"):value()] = true
    end
end)


-- Prevent infusers from being selectable, only need to do this for the player
script.on_internal_event(Defines.InternalEvents.SELECT_ARMAMENT_PRE, function(armamentSlot)
    local weapon = Hyperspace.ships.player.weaponSystem.weapons[armamentSlot]
    if weapon.powered and infuserIDs[weapon.blueprint.name] ~= nil then
        return Defines.Chain.PREEMPT, armamentSlot
    end
    return Defines.Chain.CONTINUE, armamentSlot
end)


-- Stat application logic, by sillysandvich
script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local weapons = Hyperspace.ships(weapon.iShipId).weaponSystem.weapons
    local weaponIdx = -1 -- Helps avoid erroneous error messages involving combat drones

    for i = 0, weapons:size() - 1 do -- Find index of firing weapon
        if weapons[i] == weapon then
            weaponIdx = i
            break
        end
    end
    -- Iterate backwards over all adjacent infusers
    for i = weaponIdx - 1, 0, -1 do
        local infuserWeapon = weapons[i]
        if infuserIDs[infuserWeapon.blueprint.name] ~= nil and infuserWeapon.powered and (is_first_shot(weapon, true) or projectile:GetType() == 5) then
            if infuserWeapon.chargeLevel > 0 then
                -- CORE EFFECTS

                -- Get the damage stats that can be modified
                local damageProperties = {
                    "iDamage", "iSystemDamage", "iPersDamage", "iIonDamage",
                    "fireChance", "breachChance", "stunChance", "iStun"
                }

                -- Get and apply the "custom" (HS-exclusive) damage stats that can be modified. TODO: Change when CustomWeaponManager is exposed, current workaround for getting a blueprint's CustomDamage
                local dummyProj = Hyperspace.App.world.space:CreateLaserBlast(infuserWeapon.blueprint, Hyperspace.Pointf(INT_MAX, INT_MAX), 0, -1, Hyperspace.Pointf(INT_MAX, INT_MAX), 0, -1) -- Create a dummy projectile to store the infuser's stats
                local projTable = userdata_table(projectile, "mods.alder.infusers") -- Create a userdata table to store the properties of the shot projectile
                table.insert(projTable, dummyProj.extend.customDamage.def) -- Shove the ENTIRETY of customDamage into projTable

                -- Add the base damage properties to the projectile
                for _, v in ipairs(damageProperties) do
                    projectile.damage[v] = projectile.damage[v] + infuserWeapon.blueprint.damage[v]
                end

                for queuedProj in vter(weapon.queuedProjectiles) do
                    for _, v in ipairs(damageProperties) do
                        queuedProj.damage[v] = queuedProj.damage[v] + infuserWeapon.blueprint.damage[v]
                    end
                end

                Hyperspace.Sounds:PlaySoundMix(infuserWeapon.blueprint.effects.launchSounds[0], -1, false)
                dummyProj:Kill() -- Delete the now-purposeless dummy to avoid projectile buildup
                -- Prevent infusers on their final charge from immediately gaining it back
                if infuserWeapon.chargeLevel == infuserWeapon.blueprint.chargeLevels then
                    infuserWeapon.cooldown.first = 0
                end
                infuserWeapon.chargeLevel = infuserWeapon.chargeLevel - 1
            end
        else
            break
        end
    end
end)

-- Handle beam ion damage through a reimplementation of ionBeamFix's general strategy
local blockIon = false

script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION_PRE, function(ship, projectile, damage, response)
    blockIon = projectile:GetType() == 5 and not projectile and Hyperspace.Blueprints:GetWeaponBlueprint(projectile.extend.name).damage.iIonDamage == 0
    return Defines.Chain.CONTINUE -- Weird comment silences an ambiguous weapon typing warning from VSCode already handled by condition 1
end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_SYSTEM, function(ship, projectile, roomId, damage)
    if blockIon then
        damage.iIonDamage = 0
        blockIon = false
    end
    return Defines.Chain.CONTINUE
end)


-- Apply statboosts from the infuser
local function apply_additional_boosts_to_crew(projectile, crew)
    local tab = userdata_table(projectile, "mods.alder.infusers")
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

-- Add info to stats
script.on_internal_event(Defines.InternalEvents.WEAPON_STATBOX, function(bp, stats)
    if infuserIDs[bp.name] then
        return Defines.Chain.CONTINUE, stats.."\n\n"..Hyperspace.Text:GetText("aa_stat_infuser")
    -- Muffle VSCode warning
    ---@diagnostic disable-next-line: missing-return
    end
end)