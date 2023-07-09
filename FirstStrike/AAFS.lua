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



-- [Cumulative Laser/Flak - Charges damage instead of shot count.]

script.on_fire_event(Defines.FireEvents.WEAPON_FIRE, function(ship, weapon, projectile)
  if weapon.blueprint.name == "AA_LASER_CHARGEGUN_DAMAGE" then
    local boost = weapon.queuedProjectiles:size()
    projectile.damage.iDamage = projectile.damage.iDamage + boost
    weapon.queuedProjectiles:clear()
  end
end)

script.on_fire_event(Defines.FireEvents.WEAPON_FIRE, function(ship, weapon, projectile)
  if weapon.blueprint.name == "AA_SHOTGUN_CHARGEGUN_DAMAGE" then
    local boost = weapon.queuedProjectiles:size()
    projectile.damage.iDamage = projectile.damage.iDamage + boost
    weapon.queuedProjectiles:clear()
  end
end)

-- [Cumulative Ion - Charges damage instead of shot count.]

script.on_fire_event(Defines.FireEvents.WEAPON_FIRE, function(ship, weapon, projectile)
  if weapon.blueprint.name == "AA_ION_CHARGEGUN_DAMAGE" then
    local boost = weapon.queuedProjectiles:size()
    projectile.damage.iIonDamage = projectile.damage.iIonDamage + boost
    weapon.queuedProjectiles:clear()
  end
end)

-- [Cumulative Energy - Charges damage instead of shot count.]

script.on_fire_event(Defines.FireEvents.WEAPON_FIRE, function(ship, weapon, projectile)
  if weapon.blueprint.name == "AA_ENERGY_CHARGEGUN_DAMAGE" then
    local boost = weapon.queuedProjectiles:size()
    projectile.damage.iIonDamage = projectile.damage.iIonDamage + boost
    weapon.queuedProjectiles:clear()
  end
end)

-- [Cumulative Particle - Charges damage instead of shot count.]

script.on_fire_event(Defines.FireEvents.WEAPON_FIRE, function(ship, weapon, projectile)
  if weapon.blueprint.name == "AA_LASER_PARTICLE_CHARGEGUN_DAMAGE" then
    local boost = weapon.queuedProjectiles:size()
    projectile.damage.iSystemDamage = projectile.damage.iSystemDamage + boost
    weapon.queuedProjectiles:clear()
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



-- ["Sovnya" Sustaining Beam - Set beam speed to 0, drill into the enemy for the occasional periodic hit of damage identical to regular beams. Again, thank you, Vertaal!]

do
  --These values are used in both callbacks, so we define them as variables here so that they only need to be changed in one place.
  local baseDamage = 1 --The base damage of the weapon, normal damage
  local damagePeriod = 4 --How long between damage pulses (in seconds)
  local sabotageRate = 1 --The rate at which the beam sabotages systems (unsure of what this translates to in terms of crew sabotage damage)
  
  script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM, --This function runs every time damage is applied by a beam
  function(ShipManager, Projectile, Location, Damage, realNewTile, beamHitType)
    if Hyperspace.Get_Projectile_Extend(Projectile).name == "AA_BEAM_SUSTAIN" then --If the projectile came from a weapon with ID "SUSTAIN"
  
      local baseDamage = baseDamage --not really a reason to do these assignments unless these values were changed in this function
      local damagePeriod = damagePeriod
      local sabotageRate = sabotageRate
  
  
      Projectile.speed_magnitude=0 --set the beam speed to 0
      local roomID = ShipManager.ship:GetSelectedRoomId(Location.x,Location.y, true) --The room that the beam is currently damaging
      local system = ShipManager:GetSystemInRoom(roomID) --the system that is being damaged
      local layers = ShipManager:GetShieldPower().first --the number of shield layers that the ship currently has
  
  
      if system then system:PartialDamage(sabotageRate*math.max(baseDamage-layers,0)) end --if the system exists, do sabotage damage to it at a rate proportional to how much damage would bleed through the shields (not accounting for any pierce)
    
    
      if Projectile.timer>damagePeriod then --if damagePeriod seconds have passed since the last pulse, apply another one
        local dam = Hyperspace.Damage() --Create a Damage object
        dam.iDamage = math.max(baseDamage-layers,0) --set the iDamage field equal to the baseDamage of the weapon minus the number of shield layers up
        dam.iSystemDamage = -math.max(baseDamage-layers,0) --set iSystemDamage to cancel iDamage (system damage is applied via "sabotage")
        local farPoint = Hyperspace.Pointf(-2147483648, -2147483648) --create a Pointf that is as far away as possible so it will never intersect a room
        Hyperspace.Get_Projectile_Extend(Projectile).name = "" --blank out the name to prevent recursion (we are calling DamageBeam inside a DamageBeam callback)
        ShipManager:DamageBeam(Location,farPoint,dam) --Apply the damage of the beam to the place where it is (farPoint is where the beam touched last frame so the function can check if it is in a new room or not, we set farPoint such that it will always be in a "new room" and therefore apply damage)
        Hyperspace.Get_Projectile_Extend(Projectile).name = "AA_BEAM_SUSTAIN" --Set name back
        Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix("sysExplosion",0.5,true) --Play a sound 
        Projectile.timer = 0 --set the timer back to zero
      end
    end
  end)
  
  script.on_internal_event(Defines.InternalEvents.PROJECTILE_UPDATE_POST,
  function(Projectile,preempt) --function that runs every tick for a projectile
    if Hyperspace.Get_Projectile_Extend(Projectile).name == "AA_BEAM_SUSTAIN" then --check the name of the projectile
      local baseDamage = baseDamage --again, superfluous
      local damagePeriod = damagePeriod
  
    
      Projectile.speed_magnitude = 0 --set beam speed to 0, might not be necessary to set it to 0 every tick
      Projectile.timer = Projectile.timer + Hyperspace.FPS.SpeedFactor/16 --increment timer (should use another mechanism to associate a variable with the projectile but this was the quick way)
  
      local firingWeapon --declare a variable firingWeapon within the global scope
      pcall(function() 
        local firingShipManager = Hyperspace.Global.GetInstance():GetShipManager(Projectile.ownerId)
        for weapon in vter(firingShipManager.weaponSystem.weapons) do
          if weapon.weaponVisual == Projectile.weapAnimation then
            firingWeapon = weapon break --find the weapon that is firing the projectile
          end
        end
      end)
      --if the weapon either 1. does not exist 2. has a projectile queued 3. is hacked then delete the beam projectile
      if not (firingWeapon and firingWeapon.queuedProjectiles:size() == 0 and firingWeapon.iHackLevel < 2) then
        Projectile:Kill()
      end
      --weapAnimation seems to be voided on save and load
      --Projectile.weapAnimation.anim:SetProgress(((2 * Projectile.timer)/damagePeriod)%1)
  
      local ShipManager = Hyperspace.Global.GetInstance():GetShipManager((Projectile.ownerId + 1) % 2) --get the ship that the projectile is targeting
      pcall(function() 
        if Projectile.timer>damagePeriod and ShipManager:GetShieldPower().super.first > 0 then --if the ship that the projectile is damaging has a super shield and a cycle has passed
          Projectile.timer = 0 --set timer back to 0
          local dam = Hyperspace.Damage() --create Damage object
          dam.iDamage = baseDamage --set the iDamage field
          local pos = Projectile.shield_end --The place at which the beam projectile is terminated by the shield
          ShipManager.shieldSystem:CollisionReal(pos.x,pos.y,dam,true) --apply damage to that point
        end
      end)
  

    end
  end)
  
end



-- [Particle Shield - An energy shield that regenerates some time after taking damage.]

mods.alder.particleShields = {}
local particleShields = mods.alder.particleShields
particleShields["AA_PARTICLE_SHIELD"] = {
    max = 1,
    regen = 1,
    time = 10,
    color = Graphics.GL_Color(1.0, 0.47, 0.0, 1.0),
    boss = false
}

mods.alder.particleShields = {}
local particleShields = mods.alder.particleShields
particleShields["AA_PARTICLE_SHIELD_BOSS"] = {
    max = 1,
    regen = 1,
    time = 10,
    color = Graphics.GL_Color(1.0, 0.47, 0.0, 1.0),
    boss = true
}

-- Logic
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
    local shieldSys = nil
    if pcall(function() shieldSys = ship.shieldSystem end) and shieldSys then
        for partShieldName, partShieldData in pairs(particleShields) do
            if ship:HasAugmentation(partShieldName) ~= 0 then
                if shieldSys.shields.power.super.first < partShieldData.max then
                    local timer = userdata_table(ship, "mods.alder.partShieldTimer")
                    if not timer.time then
                        timer.time = 0
                        timer.color = partShieldData.color
                        timer.boss = partShieldData.boss
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
                end
                break -- Ships should only have one particle shield
            end
        end
    end
end)

-- Charge bar
local outlineColor = Graphics.GL_Color(1.0, 1.0, 1.0, 1.0) -- Color for the outline of the charge bar (White).
local function render_part_shield_charge(ship, width, x, y)
    local timer = userdata_table(ship, "mods.alder.partShieldTimer")
    local progress = timer.progress
    if progress and progress > 0 then
        if timer.boss then
            x = x - 125
            y = y - 44
        end
        Graphics.CSurface.GL_DrawRectOutline(x, y, width, 6, outlineColor, 1)
        Graphics.CSurface.GL_DrawRect(2 + x, 2 + y, (width - 4)*progress, 2, timer.color)
    end
end
script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, mods.multiverse.doNothingFunction, function()
    if Hyperspace.ships.player then render_part_shield_charge(Hyperspace.ships.player, 98, 30, 89) end
    if Hyperspace.ships.enemy then render_part_shield_charge(Hyperspace.ships.enemy, 60, 892, 157) end
end)