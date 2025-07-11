-- [Regenerative Hull - Augments that heal hull on jump. Extremely tiny, yet shockingly effective. Written by me!]

-- Logic
script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(ship) -- only player ships trigger JUMP_ARRIVE
    if ship:HasAugmentation("AA_TECH_JUMP_REPAIR") ~= 0 then -- ship has aug
        local regen = ship:GetAugmentationValue("AA_TECH_JUMP_REPAIR")
        ship:DamageHull(-regen, true)
    end
end)

script.on_internal_event(Defines.InternalEvents.ON_WAIT, function(ship) -- similar
    if ship:HasAugmentation("AA_TECH_JUMP_REPAIR") ~= 0 then
        local regen = ship:GetAugmentationValue("AA_TECH_JUMP_REPAIR")
        ship:DamageHull(-regen, true)
    end
end)