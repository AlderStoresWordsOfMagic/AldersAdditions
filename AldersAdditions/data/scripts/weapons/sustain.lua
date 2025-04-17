local vter = mods.multiverse.vter
local userdata_table = mods.multiverse.userdata_table

-- [Sustaining Beam - Set beam speed to 0, drill into the enemy for the occasional periodic hit of damage identical to regular beams. Credit to Vertaal and Pepson.]

mods.alder.sustainBeams = {}
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