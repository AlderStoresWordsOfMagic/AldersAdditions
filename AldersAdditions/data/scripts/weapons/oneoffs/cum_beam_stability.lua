-- Cumulative Beam 'Woldo' is named differently based on stability value
local needsNameGenerated = true

script.on_game_event("START_BEACON", false, function() needsNameGenerated = true end)
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if needsNameGenerated then
        local stability = Hyperspace.playerVariables.stability
        local shortDesc = stability > 100 and "'Woldo'" or "Cum. Beam"
        local blueprint = Hyperspace.Blueprints:GetWeaponBlueprint("AA_BEAM_CHARGEGUN_DAMAGE")
        blueprint.desc.shortTitle.data = shortDesc
        needsNameGenerated = false
    end
end)