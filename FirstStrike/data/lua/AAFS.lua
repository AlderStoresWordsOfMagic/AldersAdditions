-- These pieces of code allow various parts of the mod to function in ways that XML alone can't satisfy.
-- Kudos to Chrono, Vertaal, and Julk for helping me figure this out!
-- For a list of stuff this code refers to, check https://github.com/FTL-Hyperspace/FTL-Hyperspace/blob/develop/FTLGameWin32.h
-- Hit CTRL + F in your browser and search.



-- [Defining the Alder name space. The Alderspace? I dunno. Keeps all the mechanical parts from overlapping with other mods.]

mods.alder = {}



-- [Version check for Hyperspace.]

if not (Hyperspace.version and Hyperspace.version.major == 1 and Hyperspace.version.minor >= 5) then
  if not (Hyperspace.version.patch >= 2) then
    error("Incorrect Hyperspace version detected! Alder's Additions: First Strike requires Hyperspace 1.5.2+ to function.")
  end
end

-- [This piece gets angry if someone patches First Strike before Inferno-Core.]

local infernoInstalled = false
if mods.inferno then infernoInstalled = true end
script.on_load(function()
  if not infernoInstalled and mods.inferno then
    Hyperspace.ErrorMessage("Incorrect mod order detected! Inferno-Core must be patched before Alder's Addition: First Strike.")
  end
end)

-- [An "iterator for C vectors", it makes the for loops work.]

function mods.alder.vter(cvec)
  local i = -1
  local n = cvec:size()
  return function()
      i = i + 1
      if i < n then return cvec[i] end
  end
end
local vter = mods.alder.vter

-- [It keeps things from exploding. I don't know what it does, but it keeps this machine cooled.]

function mods.alder.userdata_table(userdata, tableName)
  if not userdata.table[tableName] then userdata.table[tableName] = {} end
  return userdata.table[tableName]
end
local userdata_table = mods.alder.userdata_table

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
    local statBoosts = nil
    if pcall(function() statBoosts = statChargers[weapon.blueprint.name] end) and statBoosts then
        local boost = weapon.queuedProjectiles:size() -- Gets how many projectiles are charged up (doesn't include the one that was already shot)
        weapon.queuedProjectiles:clear() -- Delete all other projectiles
        for _, statBoost in ipairs(statBoosts) do -- Apply all stat boosts
            if statBoost.calc then
                projectile.damage[statBoost.stat] = statBoost.calc(boost, projectile.damage[statBoost.stat])
            else
                projectile.damage[statBoost.stat] = boost + projectile.damage[statBoost.stat]
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
    crush = 12 -- If this weapon reduces shields to 0, apply -12 shield layers
}
popWeapons["AA_LASER_SMASH_2"] = {
    count = 1,
    countSuper = 1,
    crush = 12
}
popWeapons["AA_DRONE_LASER_SMASH"] = {
    count = 1,
    countSuper = 1,
    crush = 12
}
popWeapons["AA_BEAM_SMASH"] = {
    count = 1,
    countSuper = 1,
    crush = 12
}

script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(shipManager, projectile, damage, response)
    if projectile.bDamageSuperShield == nil or projectile.bDamageSuperShield then
        local shieldPower = shipManager.shieldSystem.shields.power
        local popData = nil
        if pcall(function() popData = popWeapons[Hyperspace.Get_Projectile_Extend(projectile).name] end) and popData then
            if shieldPower.super.first > 0 then
                if popData.countSuper > 0 then
                    shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(), true)
                    shieldPower.super.first = math.max(0, shieldPower.super.first - popData.countSuper)
                end
            else
                shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(), true)
                shieldPower.first = math.max(0, shieldPower.first - popData.count)
                if shieldPower.first == 0 then
                    shieldPower.first = shieldPower.first - popData.crush
                    Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix("shield_crush",1,true)
                end
            end
        end
    end
end)

-- [Smash Missile/Smash Bomb - Pop shield without hull damage on collision with room, and crush when fully drained.]

mods.alder.popBallistics = {}
local popBallistics = mods.alder.popBallistics
popBallistics["AA_MISSILES_SMASH"] = {
    count = 4, -- This weapon will pop 4 shield layers per shot
    crush = 12 -- If this weapon reduces shields to 0, apply -12 shield layers
}
popBallistics["AA_MISSILES_SMASH_ENEMY"] = {
    count = 4,
    crush = 12
}
popBallistics["AA_BOMB_SMASH"] = {
    count = 4,
    crush = 12
}
popBallistics["AA_BOMB_SMASH_ENEMY"] = {
    count = 4,
    crush = 12
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


local sustainBeams = {
    AA_BEAM_SUSTAIN = {
        baseDamage = 1, --Base damage of the weapon
        damagePeriod = 4, --Time between damage pulses
        sabotageRate = 1, --Rate at which beam sabotages systems
        sound = "sysExplosion", --Sound that plays every pulse
    }
}

-- ["Sovnya" Sustaining Beam - Set beam speed to 0, drill into the enemy for the occasional periodic hit of damage identical to regular beams. Again, thank you, Vertaal!]

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
            dam.iDamage = bleed --Set iDamage to how much damage would pleed through on a "normal" beam
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
  




-- [Particle Shield - An energy shield that regenerates some time after taking damage.]

mods.alder.particleShields = {}
local particleShields = mods.alder.particleShields
particleShields["AA_PARTICLE_SHIELD"] = {
    max = 1,
    regen = 1,
    time = 10,
    color = Graphics.GL_Color(1.0, 0.47, 0.0, 1.0),
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
    if progress and progress > 0 and not ship.bDestroyed then
        Graphics.CSurface.GL_DrawRectOutline(x, y, width, 6, outlineColor, 1)
        Graphics.CSurface.GL_DrawRect(2 + x, 2 + y, (width - 4)*progress, 2, timer.color)
    end
end
script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, mods.multiverse.doNothingFunction, function()
    if Hyperspace.ships.player then render_part_shield_charge(Hyperspace.ships.player, 98, 30, 89) end
    if Hyperspace.ships.enemy then
        if Hyperspace.Global.GetInstance():GetCApp().gui.combatControl.boss_visual then
            render_part_shield_charge(Hyperspace.ships.enemy, 60, 767, 113)
        else
            render_part_shield_charge(Hyperspace.ships.enemy, 60, 892, 157)
        end
    end
end)