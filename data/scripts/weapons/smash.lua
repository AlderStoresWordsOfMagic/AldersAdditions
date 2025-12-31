local userdata_table = mods.multiverse.userdata_table

-- XML parsing imports
local string_replace = mods.multiverse.string_replace
local node_get_number_default = mods.multiverse.node_get_number_default
local node_get_bool_default = mods.multiverse.node_get_bool_default
local weaponTagParsers = mods.multiverse.weaponTagParsers

-- [Smash Weapons - Pop shield without hull damage on collision with shield, and "crush" when fully drained.]

-- Add Lua statistics to every weapon with the <aa-shieldSmash> tag
mods.alder.smashWeapons = {}
local smashWeapons = mods.alder.smashWeapons

table.insert(weaponTagParsers, function(weaponNode)
    local smashNode = weaponNode:first_node("aa-shieldSmash")
    if smashNode then
        smashWeapons[weaponNode:first_attribute("name"):value()] = {
            count = node_get_number_default(smashNode:first_node("count"), 1),
            countSuper = node_get_number_default(smashNode:first_node("countSuper"), 0),
            ion = node_get_number_default(smashNode:first_node("ion"), 0)
        }
    end
end)


-- Apply crush on shield hit
local function crush_shield(smashData, ship, x, y)
    local shieldPower = ship.shieldSystem.shields.power
    if shieldPower.super.first > 0 then -- Handle energy shields
        if smashData.countSuper > 0 then
            ship.shieldSystem:CollisionReal(x, y, Hyperspace.Damage(), true)
            shieldPower.super.first = math.max(0, shieldPower.super.first - smashData.countSuper)
        end
    else
        ship.shieldSystem:CollisionReal(x, y, Hyperspace.Damage(), true)
        shieldPower.first = math.max(0, shieldPower.first - smashData.count)
        if shieldPower.first == 0 then
            local damage = Hyperspace.Damage()
            damage.iIonDamage = smashData.ion
            ship:DamageArea(ship.shieldSystem.location, damage, true)
            Hyperspace.Sounds:PlaySoundMix("shield_crush", -1, true)
        end
    end
end
-- script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(ship, projectile, location, damage, shipFriendlyFire)
--     local smashData = smashWeapons[projectile and projectile.extend and projectile.extend.name]
--     if smashData and damage.iShieldPiercing > 0 then
--         crush_shield(smashData, ship, location.x, location.y)
--     end
-- end)
script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(ship, projectile, damage, response)
    local smashData = smashWeapons[projectile and projectile.extend and projectile.extend.name]
    if smashData then
        crush_shield(smashData, ship, projectile.position.x, projectile.position.y)
    end
end)
-- Need to find a way to make it work with beams


-- Add info to stats
script.on_internal_event(Defines.InternalEvents.WEAPON_STATBOX, function(bp, stats)
    local smashData = smashWeapons[bp.name]
    if smashData then
        stats = stats.."\n\n"..string_replace(Hyperspace.Text:GetText("stat_pop"), "\\1", smashData.count)
        if smashData.countSuper then
            stats = stats.."\n"..string_replace(Hyperspace.Text:GetText("stat_pop_super"), "\\1", smashData.countSuper)
        end
        if smashData.ion then
            stats = stats.."\n\n"..string_replace(Hyperspace.Text:GetText("aa_stat_smash"), "\\1", smashData.ion)
        end
        return Defines.Chain.CONTINUE, stats
    ---@diagnostic disable-next-line: missing-return
    end
end)