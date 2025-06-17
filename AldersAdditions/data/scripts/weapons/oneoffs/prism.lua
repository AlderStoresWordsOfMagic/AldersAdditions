-- [Prismatic Ion - Copied code from TRC that allows each projectile to have a different sprite. Why isn't this base MV?]

mods.alder.burstSpriteFixes = {}
local burstSpriteFixes = mods.alder.burstSpriteFixes
burstSpriteFixes["AA_ION_RAINBOW"] = true

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local isFake = projectile.death_animation.fScale == 0.25
    if burstSpriteFixes[weapon and weapon.blueprint and weapon.blueprint.name] and not isFake then
        projectile:Initialize(Hyperspace.Blueprints:GetWeaponBlueprint(projectile.extend.name))
    end
end)