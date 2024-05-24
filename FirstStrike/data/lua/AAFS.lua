-- These pieces of code allow various parts of the mod to function in ways that XML alone can't satisfy.



-- [Defining the Alder name space. The Alderspace? I dunno. Keeps all the mechanical parts from overlapping with other mods.]

mods.alder = {}



-- [Version check for Hyperspace.]

if not (Hyperspace.version and Hyperspace.version.major == 1 and Hyperspace.version.minor >= 11) then
  if not (Hyperspace.version.patch >= 2) then
    error("Incorrect Hyperspace version detected! Alder's Additions: First Strike requires Hyperspace 1.11.2+ to function.")
  end
end

-- [An "iterator for C vectors", it makes the for loops work.]

local vter = mods.multiverse.vter

-- [It keeps things from exploding. It creates an empty table for some things, but... I dunno what things lack and need a table.]

local userdata_table = mods.multiverse.userdata_table

-- [Find the ID of a room at the given location.]

local get_room_at_location = mods.multiverse.get_room_at_location

-- [Returns a table, where the indices are the IDs of all adjacent rooms to the target, and the values are the rooms' coordinates.]

local get_adjacent_rooms = mods.multiverse.get_adjacent_rooms

-- [A function that does nothing.]

function mods.alder.doNothing()
end

-- [Some more compatibility.]

local INT_MAX = 2147483647



-- [Cumulative weapons - Charges damage instead of shot count.]

mods.alder.statChargers = {}
local statChargers = mods.alder.statChargers
statChargers["AA_LASER_CHARGEGUN_DAMAGE"] = {{stat = "iDamage"}}
statChargers["AA_SHOTGUN_CHARGEGUN_DAMAGE"] = {{stat = "iDamage"}}
statChargers["AA_ION_CHARGEGUN_DAMAGE"] = {{stat = "iIonDamage"}}
statChargers["AA_ENERGY_CHARGEGUN_DAMAGE"] = {{stat = "iIonDamage"}}
statChargers["AA_LASER_PARTICLE_CHARGEGUN_DAMAGE"] = {{stat = "iSystemDamage"}}

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

-- [Cooldown charging code.]

mods.alder.cooldownChargers = {}
local cooldownChargers = mods.alder.cooldownChargers
cooldownChargers["AA_ROCKETS_1"] = 1.5

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
    local weapons = nil
    if pcall(function() weapons = ship.weaponSystem.weapons end) and weapons then
        for weapon in vter(weapons) do
            if weapon.chargeLevel ~= 0 and weapon.chargeLevel < weapon.weaponVisual.iChargeLevels then
                local cdBoost = nil
                if pcall(function() cdBoost = cooldownChargers[weapon.blueprint.name] end) and cdBoost then
                    local cdLast = userdata_table(weapon, "mods.alder.weaponStuff").cdLast
                    if cdLast and weapon.cooldown.first > cdLast then
                        -- Calculate the new charge level from number of charges and charge level from last frame
                        local chargeUpdate = weapon.cooldown.first - cdLast
                        local chargeNew = weapon.cooldown.first - chargeUpdate + cdBoost^weapon.chargeLevel*chargeUpdate
                        
                        -- Apply the new charge level
                        if chargeNew >= weapon.cooldown.second then
                            weapon.chargeLevel = weapon.chargeLevel + 1
                            if weapon.chargeLevel == weapon.weaponVisual.iChargeLevels then
                                weapon.cooldown.first = weapon.cooldown.second
                            else
                                weapon.cooldown.first = 0
                            end
                        else
                            weapon.cooldown.first = chargeNew
                        end
                    end
                    userdata_table(weapon, "mods.alder.weaponStuff").cdLast = weapon.cooldown.first
                end
            end
        end
    end
end)



-- [Smash Laser MK 1/MK 2 and Smash Beam - Pop shield without hull damage on collision with shield, and crush when fully drained.]

mods.alder.popWeapons = {}
local popWeapons = mods.alder.popWeapons
popWeapons["AA_LASER_SMASH"] = {
    count = 1, -- This weapon will pop 1 shield layer per shot
    countSuper = 1, -- This weapon will pop 1 energy shield layer per shot
    crush = 1 -- currently used for shield crush layers, will be reworked into the crush intensity value
}
popWeapons["AA_LASER_SMASH_2"] = {
    count = 1,
    countSuper = 1,
    crush = 1
}
popWeapons["AA_DRONE_LASER_SMASH"] = {
    count = 1,
    countSuper = 1,
    crush = 1
}
popWeapons["AA_BEAM_SMASH"] = {
    count = 1,
    countSuper = 1,
    crush = 1
}

-- Apply crush on shield hit
script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(ship, projectile, damage, response)
    local popData = popWeapons[projectile and projectile.extend and projectile.extend.name]
    if popData then
        local shieldPower = ship.shieldSystem.shields.power
        if shieldPower.super.first > 0 then
            if popData.countSuper > 0 then
                ship.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(), true)
                shieldPower.super.first = math.max(0, shieldPower.super.first - popData.countSuper)
            end
        else
            ship.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(), true)
            shieldPower.first = math.max(0, shieldPower.first - popData.count)
            if shieldPower.first == 0 then
                local shieldTracker = userdata_table(ship, "mods.aa.shieldCrush")
                shieldTracker.crush = shieldTracker.crush or 0 + popData.crush
                Hyperspace.Sounds:PlaySoundMix("shield_crush", -1, true)
            end
        end
    end
end)

-- Reduce number of shields crushed when one recharges
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
    local shieldTracker = userdata_table(ship, "mods.aa.shieldCrush")
    shieldTracker.currentShields = ship._targetable:GetShieldPower().first
    if shieldTracker.crush and shieldTracker.crush > 0 and shieldTracker.previousShields and shieldTracker.currentShields > shieldTracker.previousShields then
        shieldTracker.crush = math.max(0, shieldTracker.crush - (shieldTracker.currentShields - shieldTracker.previousShields))
    end
    shieldTracker.previousShields = shieldTracker.currentShields
end)

-- Reduce shield recharge rate by 80% while crushed
script.on_internal_event(Defines.InternalEvents.GET_AUGMENTATION_VALUE, function(ship, augName, augValue)
    if ship and augName == "SHIELD_RECHARGE" then
        local shieldTracker = userdata_table(ship, "mods.aa.shieldCrush")
        if shieldTracker.crush and shieldTracker.crush > 0 then
            augValue = augValue - 0.6
        end
    end
    return Defines.Chain.CONTINUE, augValue
end)



-- [Smash Missile/Smash Bomb - Pop shield without hull damage on collision with room, and crush when fully drained.]

mods.alder.popBallistics = {}
local popBallistics = mods.alder.popBallistics
popBallistics["AA_MISSILES_SMASH"] = {
    count = 4, -- This weapon will pop 4 shield layers per shot
    crush = 8 -- If this weapon reduces shields to 0, apply -12 shield layers
}
popBallistics["AA_MISSILES_SMASH_ENEMY"] = {
    count = 4,
    crush = 8
}
popBallistics["AA_BOMB_SMASH"] = {
    count = 4,
    crush = 8
}
popBallistics["AA_BOMB_SMASH_ENEMY"] = {
    count = 4,
    crush = 8
}

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, 
function(shipManager, projectile, location, damage, shipFriendlyFire)
    local shieldSystem = shipManager.shieldSystem
    local popData = nil
    if shieldSystem and pcall(function() popData = popBallistics[Hyperspace.Get_Projectile_Extend(projectile).name] end) and popData then
        shieldSystem:CollisionReal(location.x, location.y, Hyperspace.Damage(), true)
        shieldSystem.shields.power.first = math.max(0, shieldSystem.shields.power.first - popData.count) 
        
        if shieldSystem.shields.power.first == 0 then
            shieldSystem.shields.power.first = shieldSystem.shields.power.first  - popData.crush
            Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix("shield_crush",1,true)
        end
    end
    return Defines.Chain.CONTINUE
end)



-- [Drone Pointer Antenna - Retargets all active combat drones to the targeted room.]

mods.alder.painters = {}
local painters = mods.alder.painters
painters["AA_POINTER"] = true

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
    local weaponName = nil
    pcall(function() weaponName = Hyperspace.Get_Projectile_Extend(projectile).name end)
    if weaponName then

        if painters[weaponName] then
            for drone in vter(Hyperspace.Global.GetInstance():GetShipManager((shipManager.iShipId + 1)%2).spaceDrones) do
                drone.targetLocation = location
            end
        end
    end
end)



-- [Pinpoint Shotguns - Replace burst projectile with beam.]

local pinpoint1 = Hyperspace.Blueprints:GetWeaponBlueprint("AA_SHOCK_CANNON_PROJECTILE")

local burstsToBeams = {}
burstsToBeams.AA_SHOCK_CANNON = pinpoint1

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local beamReplacement = burstsToBeams[weapon.blueprint.name]
    if beamReplacement then
        local spaceManager = Hyperspace.Global.GetInstance():GetCApp().world.space
        local beam = spaceManager:CreateBeam(
            beamReplacement, projectile.position, projectile.currentSpace, projectile.ownerId,
            projectile.target, Hyperspace.Pointf(projectile.target.x, projectile.target.y + 1),
            projectile.destinationSpace, 1, projectile.heading)
        beam.sub_start.x = 500*math.cos(projectile.entryAngle)
        beam.sub_start.y = 500*math.sin(projectile.entryAngle) 
        projectile:Kill()
    end
end)



-- [Charge Holders - Mass Drivers do not lose charge when unpowered.]

mods.alder.holders = {}
local holders = mods.alder.holders

holders["AA_DRIVER"] = {
    chargeRate = 0.25 -- Rate of usual at which to charge; 1 = normal charge rate
}
holders["AA_DRIVER_BIO"] = {
    chargeRate = 0.25
}
holders["AA_DRIVER_EXPLOSIVE"] = {
    chargeRate = 0.25
}
holders["AA_DRIVER_SHOTGUN"] = {
    chargeRate = 0.25
}
holders["AA_DRIVER_ION"] = {
    chargeRate = 0.25
}
holders["AA_DRIVER_PARTICLE"] = {
    chargeRate = 0.25
}

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    for weapon in vter(shipManager:GetWeaponList()) do
        if (not weapon.powered) and holders[weapon.blueprint.name] then
            weapon.cooldown.first = (math.min(weapon.cooldown.first + (Hyperspace.FPS.SpeedFactor * (6 + (holders[weapon.blueprint.name].chargeRate * weapon.cooldownModifier))) / 16, weapon.cooldown.second - 0.01))
        end
    end
end)



-- [Area-Effect Weapons - A specific weapon's damage bleeds over into other rooms.]

mods.alder.aoeWeapons = {}
local aoeWeapons = mods.alder.aoeWeapons

aoeWeapons["AA_DRIVER_EXPLOSIVE"] = Hyperspace.Damage()
aoeWeapons["AA_DRIVER_EXPLOSIVE"].iSystemDamage = 2

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
    local weaponName = nil
    pcall(function() weaponName = Hyperspace.Get_Projectile_Extend(projectile).name end)
    local aoeDamage = aoeWeapons[weaponName]
    if aoeDamage then
        Hyperspace.Get_Projectile_Extend(projectile).name = ""
        for roomId, roomPos in pairs(get_adjacent_rooms(shipManager.iShipId, get_room_at_location(shipManager, location, false), false)) do
            shipManager:DamageArea(roomPos, aoeDamage, true)
        end
        Hyperspace.Get_Projectile_Extend(projectile).name = weaponName
    end
end)



-- [Sustaining Beams - Set beam speed to 0, drill into the enemy for the occasional periodic hit of damage identical to regular beams. Again, thank you, Vertaal!]

mods.alder.sustainBeams = {}
local sustainBeams = mods.alder.sustainBeams
sustainBeams["AA_BEAM_SUSTAIN"] = {
    baseDamage = 1, -- Base damage of the weapon
    damagePeriod = 4, -- Time between damage pulses
    sabotageRate = 1, -- Rate at which beam sabotages systems
    sound = "sysExplosion", -- Sound that plays every pulse
}

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE,
function(Projectile, Weapon)
    if sustainBeams[Projectile.extend.name] then
        Projectile.speed_magnitude = 0
    end
end)

--TODO: Replace use of Projectile.timer with a Projectile.table member once saving is implemented. 
script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM, --This function runs every time damage is applied by a beam
function(ShipManager, Projectile, Location, Damage, realNewTile, beamHitType)
    local sustainBeam = sustainBeams[Projectile.extend.name]
    if sustainBeam then
        local roomID = ShipManager.ship:GetSelectedRoomId(Location.x, Location.y, true) --The room that the beam is currently damaging
        local system = ShipManager:GetSystemInRoom(roomID) --the system that is being damaged
        local layers = math.max(ShipManager:GetShieldPower().first, 0) --the number of shield layers that the ship currently has (prevent boosted damage from shield crushing)

        local bleed = sustainBeam.baseDamage + Damage.iShieldPiercing - layers --How much damage would bleed through

        if system then 
            system:PartialDamage(sustainBeam.sabotageRate * bleed) --Sabotage system at rate proportional to damage bleed
        end 

        if Projectile.timer > sustainBeam.damagePeriod then --If damagePeriod seconds have passed since the last pulse, apply another one
            local dam = Hyperspace.Damage() --Create a Damage object
            dam.iDamage = bleed --Set iDamage to how much damage would bleed through on a "normal" beam
            dam.iSystemDamage = -dam.iDamage --Cancel system damage (applied via "sabotage" effect)
            local farPoint = Hyperspace.Pointf(-2147483648, -2147483648) --Create a Pointf that is as far away as possible so it will never intersect a room
            local savedName = Projectile.extend.name --Save projectile name for later restoration
            Projectile.extend.name = "" --Blank out the name to prevent recursion (we are calling DamageBeam inside a DamageBeam callback)
            ShipManager:DamageBeam(Location, farPoint, dam) --Apply the damage of the beam to the place where it is (farPoint is where the beam touched last frame so the function can check if it is in a new room or not, we set farPoint such that it will always be in a "new room" and therefore apply damage)
            Projectile.extend.name = savedName --Set name back
            Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix(sustainBeam.sound, 0.5, true) --Play a sound 
            Projectile.timer = 0 --set the timer back to zero
        end
    end
end)

--TODO: Replace use of Projectile.timer with a Projectile.table member once saving is implemented. 
script.on_internal_event(Defines.InternalEvents.PROJECTILE_UPDATE_POST,
function(Projectile, preempt) --Function that runs every tick for a projectile
    local sustainBeam = sustainBeams[Projectile.extend.name]
    if sustainBeam then 
        Projectile.timer = Projectile.timer + Hyperspace.FPS.SpeedFactor / 16 --Increment timer
        local firingShip = Hyperspace.Global.GetInstance():GetShipManager(Projectile.ownerId) --Get ShipManager that is firing the projectile
        local firingWeapon
        if firingShip.weaponSystem then --Weapon system may not exist in edge cases like surges, best to be safe
            for weapon in vter(firingShip.weaponSystem.weapons) do
                if weapon.weaponVisual == Projectile.weapAnimation then --If weapon is firing the projectile then
                    firingWeapon = weapon 
                    break
                end
            end
        end
        --If the firing weapon either 1. Does not exist or 2. Has a projectile queued (attempted retargeting) or 3. Is hacked, then delete the beam projectile
        if not (firingWeapon and firingWeapon.queuedProjectiles:size() == 0 and firingWeapon.iHackLevel < 2) then
            Projectile:Kill()
        end

        local targetedShip = Hyperspace.Global.GetInstance():GetShipManager(1 - Projectile.ownerId) --Get targeted ship
        if Projectile.timer > sustainBeam.damagePeriod and targetedShip.shieldSystem and targetedShip:GetShieldPower().super.first > 0 then --If a cycle has passed and a supershield is up
            Projectile.timer = 0 --Set timer back to 0
            local dam = Hyperspace.Damage() --Create Damage object
            dam.iDamage = sustainBeam.baseDamage --Set the iDamage field
            local pos = Projectile.shield_end --The place at which the beam projectile is terminated by the shield
            targetedShip.shieldSystem:CollisionReal(pos.x, pos.y, dam, true) --Apply damage to that point
        end
    end
end)