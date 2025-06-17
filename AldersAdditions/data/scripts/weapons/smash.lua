local userdata_table = mods.multiverse.userdata_table

-- XML parsing imports
local string_replace = mods.multiverse.string_replace
local node_get_number_default = mods.multiverse.node_get_number_default
local node_get_bool_default = mods.multiverse.node_get_bool_default
local weaponTagParsers = mods.multiverse.weaponTagParsers

-- [Smash Weapons - Pop shield without hull damage on collision with shield, and crush when fully drained.]

-- Add Lua statistics to every weapon with the <aa-shieldSmash> tag
mods.alder.popWeapons = {}
local popWeapons = mods.alder.popWeapons

table.insert(weaponTagParsers, function(weaponNode)
    local smashNode = weaponNode:first_node("aa-shieldSmash")
    if smashNode then
        local smashStats = {}
        smashStats.count = node_get_number_default(smashNode:first_node("count"), 0)
        smashStats.countSuper = node_get_number_default(smashNode:first_node("countSuper"), 0)
        smashStats.crush = node_get_number_default(smashNode:first_node("crush"), 0)
        smashStats.reduction = (node_get_number_default(smashNode:first_node("reduction"), 0) / 10) -- Akin to vanilla behavior; 1 in the tag equals 10% reduction
        smashStats.onHit = node_get_bool_default(smashNode:first_node("onHit"), false)
        popWeapons[weaponNode:first_attribute("name"):value()] = smashStats
    end
end)


-- Apply crush on shield hit
local function crush_shield(popData, ship, x, y)
    local shieldPower = ship.shieldSystem.shields.power
    if shieldPower.super.first > 0 then -- Handle energy shields
        if popData.countSuper > 0 then
            ship.shieldSystem:CollisionReal(x, y, Hyperspace.Damage(), true)
            shieldPower.super.first = math.max(0, shieldPower.super.first - popData.countSuper)
        end
    else
        ship.shieldSystem:CollisionReal(x, y, Hyperspace.Damage(), true)
        shieldPower.first = math.max(0, shieldPower.first - popData.count)
        if shieldPower.first == 0 then
            local shieldTracker = userdata_table(ship, "mods.aa.shieldCrush")
            if not shieldTracker.crush then shieldTracker.crush = {} end
            for i = 1, popData.crush do
                table.insert(shieldTracker.crush, 1, popData.reduction)
            end
            Hyperspace.Sounds:PlaySoundMix("shield_crush", -1, true)
        end
    end
end
script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(ship, projectile, location, damage, shipFriendlyFire)
    local popData = popWeapons[projectile and projectile.extend and projectile.extend.name]
    if popData and popData.onHit then
        crush_shield(popData, ship, location.x, location.y)
    end
end)
script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(ship, projectile, damage, response)
    local popData = popWeapons[projectile and projectile.extend and projectile.extend.name]
    if popData and not popData.onHit then
        crush_shield(popData, ship, projectile.position.x, projectile.position.y)
    end
end)

-- Reduce number of shields crushed when one recharges
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
    local shieldTracker = userdata_table(ship, "mods.aa.shieldCrush")
    shieldTracker.currentShields = ship._targetable:GetShieldPower().first
    if shieldTracker.crush and shieldTracker.previousShields then
        local crushesToEnd = shieldTracker.currentShields - shieldTracker.previousShields
        while crushesToEnd > 0 and #shieldTracker.crush > 0 do
            shieldTracker.crush[#shieldTracker.crush] = nil
            crushesToEnd = crushesToEnd - 1
        end
    end
    shieldTracker.previousShields = shieldTracker.currentShields
end)

-- Reduce shield recharge rate while crushed
script.on_internal_event(Defines.InternalEvents.GET_AUGMENTATION_VALUE, function(ship, augName, augValue)
    if ship and augName == "SHIELD_RECHARGE" then
        local shieldTracker = userdata_table(ship, "mods.aa.shieldCrush")
        if shieldTracker.crush and #shieldTracker.crush > 0 then
            augValue = augValue - shieldTracker.crush[#shieldTracker.crush]
        end
    end
    return Defines.Chain.CONTINUE, augValue
end)


-- Render a graphic over shield bubble icons to represent crushed layers
local crushIcon = Hyperspace.Resources:GetImageId("statusUI/top_shieldsquare_crushed_full.png")
local function render_crush_bubbles(ship, x, y)
    local crushTable = userdata_table(ship, "mods.aa.shieldCrush").crush
    local crushCount = crushTable and #crushTable or 0 -- "#" means length of the table, and the length of the table is the number of shields crushed
    for i = 1, crushCount do
        Graphics.CSurface.GL_BlitImage(crushIcon, x + (23 * i), y, 30, 30, 0, Graphics.GL_Color(1.0, 1.0, 1.0, 0.6), false)
    end
end
script.on_render_event(Defines.RenderEvents.SHIP_STATUS, mods.alder.doNothing, function()
    if Hyperspace.ships.player then render_crush_bubbles(Hyperspace.ships.player, 7, 47) end
    if Hyperspace.ships.enemy and not Hyperspace.ships.enemy.bDestroyed then
        if Hyperspace.Global.GetInstance():GetCApp().gui.combatControl.boss_visual then
            render_crush_bubbles(Hyperspace.ships.enemy, 740, 71) -- Boss box has different shield counter position
        else
            render_crush_bubbles(Hyperspace.ships.enemy, 865, 114)
        end
    end
end)


-- Add info to stats
script.on_internal_event(Defines.InternalEvents.WEAPON_STATBOX, function(bp, stats)
    local smash = popWeapons[bp.name]
    if smash then
        stats = stats.."\n\n"..string_replace(Hyperspace.Text:GetText("stat_pop"), "\\1", smash.count)
        if smash.countSuper > 0 and smash.countSuper ~= smash.count then
            stats = stats.."\n"..string_replace(Hyperspace.Text:GetText("stat_pop_super"), "\\1", smash.countSuper)
        end
        if smash.crush > 0 then
            stats = stats.."\n"..string_replace(Hyperspace.Text:GetText("aa_stat_smash_crush"), "\\1", smash.crush)
        end
        if smash.reduction > 0 then
            stats = stats.."\n"..string_replace(Hyperspace.Text:GetText("aa_stat_smash_reduction"), "\\1", (smash.reduction * 100))
        end
        if smash.onHit then
            stats = stats.."\n"..Hyperspace.Text:GetText("aa_stat_smash_onhit")
        end
        return Defines.Chain.CONTINUE, stats
    -- Muffle VSCode warning
    ---@diagnostic disable-next-line: missing-return
    end
end)