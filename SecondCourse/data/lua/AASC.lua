-- These pieces of code allow various parts of the mod to function in ways that XML alone can't satisfy.
-- Kudos to Chrono, Vertaal, and Julk for helping me figure this out!
-- For a list of stuff this code refers to, check https://github.com/FTL-Hyperspace/FTL-Hyperspace/blob/develop/FTLGameWin32.h
-- Hit CTRL + F in your browser and search.



-- [Version check for Hyperspace.]

if not (Hyperspace.version and Hyperspace.version.major == 1 and Hyperspace.version.minor >= 5) then
  if not (Hyperspace.version.patch >= 2) then
    error("Incorrect Hyperspace version detected! Alder's Additions: Second Course requires Hyperspace 1.5.2+ to function.")
  end
end

-- [Presence check for Inferno-Core.]
if not mods.inferno then
  error("Inferno-Core is missing! Alder's Additions: Second Course requires Inferno-Core to function.")
end

-- [Importing the iterator from Alder's Additions: First Strike.]

local vter = mods.alder.vter

-- [Some more compatibility.]

local INT_MAX = 2147483647



-- [Spring and Lock - Fires a multitude of bombs across an area.]

mods.alder.shotgunBombs = {}
local shotgunBombs = mods.alder.shotgunBombs
shotgunBombs["AA_LOOT_RENEGADE_TONY_BIO"] = {
    blueprint = Hyperspace.Global.GetInstance():GetBlueprints():GetWeaponBlueprint("AA_LOOT_RENEGADE_TONY_BIO_BOMB"),
    count = 3
}

shotgunBombs["AA_LOOT_RENEGADE_TONY_STUN"] = {
    blueprint = Hyperspace.Global.GetInstance():GetBlueprints():GetWeaponBlueprint("AA_LOOT_RENEGADE_TONY_STUN_BOMB"),
    count = 3
}

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local shotgunBomb = shotgunBombs[weapon.blueprint.name]
    if shotgunBomb then
        local targetCenter = nil
        if pcall(function() targetCenter = weapon.lastTargets[0] end) and targetCenter then
        
            -- Find all room tiles within the weapon's radius
            local targetShipGraph = Hyperspace.ShipGraph.GetShipInfo(projectile.destinationSpace)
            local validTargets = {}
            local horzMult = 1
            local vertMult = 1
            local checkRadius = weapon.radius
            if targetCenter.x%35 > 0 then horzMult = 0 end
            if targetCenter.y%35 > 0 then vertMult = 0 end
            if checkRadius%35 > 0 then checkRadius = checkRadius - checkRadius%35 + 35 end
            for targetY = targetCenter.y - checkRadius + vertMult*17, targetCenter.y + checkRadius - vertMult*18, 35 do
                for targetX = targetCenter.x - checkRadius + horzMult*17, targetCenter.x + checkRadius - horzMult*18, 35 do
                    if (targetX - targetCenter.x)^2 + (targetY - targetCenter.y)^2 <= weapon.radius^2 and targetShipGraph:GetSelectedRoom(targetX, targetY, false) > -1 then
                        table.insert(validTargets, Hyperspace.Pointf(targetX, targetY))
                    end
                end
            end
            
            -- Fire 4 bombs randomly at found tiles
            local spaceManager = Hyperspace.Global.GetInstance():GetCApp().world.space
            local bombsCreated = 0
            while #validTargets > 0 and bombsCreated < shotgunBomb.count do
                local targetIndex = Hyperspace.random32()%#validTargets + 1
                target = validTargets[targetIndex]
                table.remove(validTargets, targetIndex)
                spaceManager:CreateBomb(shotgunBomb.blueprint, projectile.ownerId, target, projectile.destinationSpace)
                bombsCreated = bombsCreated + 1
            end
            
            projectile:Kill()
        end
    end
end, INT_MAX)



-- [Particle Shields - More of them here than just the stock one in FS.]

particleShields["AA_INTEGRAL_PARTICLE_SHIELD"] = {
    max = 3,
    regen = 3,
    time = 10,
    color = Graphics.GL_Color(0.05, 0.25, 1.0, 1.0),
}