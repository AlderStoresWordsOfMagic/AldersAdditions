local vter = mods.multiverse.vter

-- XML parsing imports
local string_replace = mods.multiverse.string_replace
local node_get_number_default = mods.multiverse.node_get_number_default
local weaponTagParsers = mods.multiverse.weaponTagParsers

-- [Charge Holders - Mass Drivers continue to charge when unpowered.]

-- Add Lua statistics to every weapon with the <aa-chargeHolder> tag
mods.alder.holders = {}
local holders = mods.alder.holders

table.insert(weaponTagParsers, function(weaponNode)
    local holderNode = weaponNode:first_node("aa-chargeHolder")
    if holderNode then
        local holderStats = {}
        holderStats.chargeRate = (node_get_number_default(holderNode:first_node("rate"), 0) / 10)
        holders[weaponNode:first_attribute("name"):value()] = holderStats -- Akin to vanilla behavior; 1 in the tag equals 10% reduction
    end
end)


-- Manually charge weapon over time
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    for weapon in vter(shipManager:GetWeaponList()) do
        if (not weapon.powered) and holders[weapon.blueprint.name] then
            weapon.cooldown.first = (math.min(weapon.cooldown.first + (Hyperspace.FPS.SpeedFactor * (6 + (holders[weapon.blueprint.name].chargeRate * weapon.cooldownModifier))) / 16, weapon.cooldown.second - 0.01))
        end
    end
end)


-- Add info to stats
script.on_internal_event(Defines.InternalEvents.WEAPON_STATBOX, function(bp, stats)
    if holders[bp.name] then
        return Defines.Chain.CONTINUE, stats.."\n\n"..string_replace(Hyperspace.Text:GetText("aa_stat_holder"), "\\1", (holders[bp.name].chargeRate * 100))
    -- Muffle VSCode warning
    ---@diagnostic disable-next-line: missing-return
    end
end)