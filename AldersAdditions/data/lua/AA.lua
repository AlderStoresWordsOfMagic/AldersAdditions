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




-- [ /// WEAPONRY /// ] --


-- [Cumulative weapons - Charges damage instead of shot count.]

mods.alder.statChargers = {}
local statChargers = mods.alder.statChargers

statChargers["AA_LASER_CHARGEGUN_DAMAGE"] = {{stat = "iDamage"}, {stat = "iDamage"}}
statChargers["AA_SHOTGUN_CHARGEGUN_DAMAGE"] = {{stat = "iDamage"}, {stat = "iDamage"}}
statChargers["AA_ION_CHARGEGUN_DAMAGE"] = {{stat = "iIonDamage"}, {stat = "iIonDamage"}}
statChargers["AA_ENERGY_CHARGEGUN_DAMAGE"] = {{stat = "iIonDamage"}}

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


-- [Smash Laser MK 1/MK 2 and Smash Beam - Pop shield without hull damage on collision with shield, and crush when fully drained.]

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
    crush = 8,
    reduction = 0.6,
    onHit = true
}
popWeapons["AA_MISSILES_SMASH_ENEMY"] = {
    count = 4,
    countSuper = 4,
    crush = 8,
    reduction = 0.6,
    onHit = true
}
popWeapons["AA_BOMB_SMASH"] = {
    count = 4,
    countSuper = 4,
    crush = 8,
    reduction = 0.6,
    onHit = true
}
popWeapons["AA_BOMB_SMASH_ENEMY"] = {
    count = 4,
    countSuper = 4,
    crush = 8,
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


-- [Sustaining Beam - Set beam speed to 0, drill into the enemy for the occasional periodic hit of damage identical to regular beams. Credit to Vertaal and Pepson.]

mods.alder.sustainBeams = {}
local userdata_table = mods.multiverse.userdata_table
local sustainBeams = mods.alder.sustainBeams

sustainBeams["AA_BEAM_SUSTAIN"] = {
    baseDamage = 1, -- Base damage of the weapon
    damagePeriod = 4, -- Time between damage pulses
    sabotageRate = 1, -- Rate at which beam sabotages systems
    damageScaling = 1, -- Damage scaling for each pulse
    periodScaling = 0.5, -- Period between pulse scaling for each pulse, 1.1 would be 10% faster each pulse
    loopCap = 8, -- Maximum number of scaling
    sound = "sustain", -- Sound that plays every successful pulse
}
mods.alder.projectileToWeapon = {}
local projectileToWeapon = mods.alder.projectileToWeapon

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE,
function(Projectile, Weapon)
    if sustainBeams[Projectile.extend.name] then
        Projectile.speed_magnitude = 0
    end
    projectileToWeapon[Projectile.extend.name] = Weapon
end)

--TODO: Replace use of Projectile.timer with a Projectile.table member once saving is implemented. 
script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM, --This function runs every time damage is applied by a beam
function(ShipManager, Projectile, Location, Damage, realNewTile, beamHitType)
    local sustainBeam = sustainBeams[Projectile.extend.name]
    if sustainBeam then
        local weapon = projectileToWeapon[Projectile.extend.name]
        local beamFactory = userdata_table(weapon, "mods.alder.beamFactory")
        beamFactory.loop = beamFactory.loop or 1
        local roomID = ShipManager.ship:GetSelectedRoomId(Location.x, Location.y, true) --The room that the beam is currently damaging
        local system = ShipManager:GetSystemInRoom(roomID) --the system that is being damaged
        local layers = math.max(ShipManager:GetShieldPower().first, 0) --the number of shield layers that the ship currently has (prevent boosted damage from shield crushing)

        local bleed = sustainBeam.baseDamage + Damage.iShieldPiercing - layers --How much damage would bleed through

        if system then 
            system:PartialDamage(sustainBeam.sabotageRate * bleed * beamFactory.loop * sustainBeam.damageScaling) --Sabotage system at rate proportional to damage bleed
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
            beamFactory.loop = beamFactory.loop + 1 --increment the loop counter
            if beamFactory.loop > sustainBeam.loopCap then --If the loop counter cannot go greater than the loop cap, set it back to the loop cap
                beamFactory.loop = sustainBeam.loopCap
            end
        end
    end
end)

--TODO: Replace use of Projectile.timer with a Projectile.table member once saving is implemented. 
script.on_internal_event(Defines.InternalEvents.PROJECTILE_UPDATE_POST,
function(Projectile, preempt) --Function that runs every tick for a projectile
    local sustainBeam = sustainBeams[Projectile.extend.name]
    if sustainBeam then 
        local weapon = projectileToWeapon[Projectile.extend.name]
        local beamFactory = userdata_table(weapon, "mods.alder.beamFactory")
        beamFactory.loop = beamFactory.loop or 1
        Projectile.timer = Projectile.timer + Hyperspace.FPS.SpeedFactor / 16 * beamFactory.loop * sustainBeam.periodScaling --Increment timer
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
        local targetedShip = Hyperspace.Global.GetInstance():GetShipManager(1 - Projectile.ownerId) --Get targeted ship

        --If the firing weapon either 1. Does not exist or 2. Has a projectile queued (attempted retargeting) or 3. Is hacked, then delete the beam projectile
        if not (firingWeapon and firingWeapon.queuedProjectiles:size() == 0 and firingWeapon.iHackLevel < 2 and targetedShip.ship.hullIntegrity.first > 0) then
            Projectile:Kill()
        end
        
        if Projectile.timer > sustainBeam.damagePeriod and targetedShip.shieldSystem and targetedShip:GetShieldPower().super.first > 0 then --If a cycle has passed and a supershield is up
            Projectile.timer = 0 --Set timer back to 0
            beamFactory.loop = 1 --Set loop back to 0
            local dam = Hyperspace.Damage() --Create Damage object
            dam.iDamage = sustainBeam.baseDamage --Set the iDamage field
            local pos = Projectile.shield_end --The place at which the beam projectile is terminated by the shield
            targetedShip.shieldSystem:CollisionReal(pos.x, pos.y, dam, true) --Apply damage to that point
        end
    end
end)




-- [ /// AUGMENTS /// ] --


-- [Particle Shield - An energy shield that regenerates some time after taking damage.]

mods.alder.particleShields = {}

local particleShields = mods.alder.particleShields
particleShields["AA_PARTICLE_SHIELD"] = {
    max = 1,
    regen = 1,
    time = 10,
    color = Graphics.GL_Color(1.0, 0.47, 0.0, 1.0)
}

-- Logic
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
    local shieldSys = nil
    if pcall(function() shieldSys = ship.shieldSystem end) and shieldSys then
        local partShieldData = nil
        local mostShields = 0
        for partShieldName, data in pairs(particleShields) do
            if ship:HasAugmentation(partShieldName) ~= 0 and data.max > mostShields then
                partShieldData = data
                mostShields = data.max
            end
        end
        if partShieldData and shieldSys.shields.power.super.first < partShieldData.max then
            local timer = userdata_table(ship, "mods.alder.partShieldTimer")
            if not timer.time then
                timer.time = 0
            end
            timer.time = timer.time + Hyperspace.FPS.SpeedFactor/16
            if timer.time >= partShieldData.time then
                timer.time = 0
                for i = 1, math.min(partShieldData.max - shieldSys.shields.power.super.first, partShieldData.regen) do
                    shieldSys:AddSuperShield(shieldSys.center)
                    Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix("particle_shield",0.3,true)
                end
            end
            timer.progress = timer.time/partShieldData.time
            timer.color = partShieldData.color
        end
    end
end)

-- Charge bar
local outlineColor = Graphics.GL_Color(1.0, 1.0, 1.0, 1.0) -- Color for the outline of the charge bar (White).
local function render_part_shield_charge(ship, width, x, y)
    local timer = userdata_table(ship, "mods.alder.partShieldTimer")
    local progress = timer.progress
    if progress and progress > 0 and not ship.ship.bDestroyed then
        Graphics.CSurface.GL_DrawRectOutline(x, y, width, 6, outlineColor, 1)
        Graphics.CSurface.GL_DrawRect(2 + x, 2 + y, (width - 4)*progress, 2, timer.color)
    end
end
script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, mods.alder.doNothing, function()
    if Hyperspace.ships.player then render_part_shield_charge(Hyperspace.ships.player, 98, 30, 89) end
    if Hyperspace.ships.enemy then
        if Hyperspace.Global.GetInstance():GetCApp().gui.combatControl.boss_visual then
            render_part_shield_charge(Hyperspace.ships.enemy, 60, 767, 113)
        else
            render_part_shield_charge(Hyperspace.ships.enemy, 60, 892, 157)
        end
    end
end)