-- [Beam Cannons - Replace burst projectiles with beams.]

local burstsToBeams = {}
burstsToBeams.AA_SHOCK_CANNON = "AA_SHOCK_CANNON_PROJECTILE"


script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local beamReplacement = Hyperspace.Blueprints:GetWeaponBlueprint(burstsToBeams[weapon.blueprint.name])
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