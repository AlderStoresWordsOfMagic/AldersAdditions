local userdata_table = mods.multiverse.userdata_table

-- [Particle Shield - An energy shield that regenerates some time after taking damage.]

mods.alder.regenShields = {}

local regenShields = mods.alder.regenShields
regenShields["AA_PARTICLE_SHIELD"] = {
    max = 1,
    regen = 1,
    time = 10,
    color = Graphics.GL_Color(1.0, 0.47, 0.0, 1.0)
}

-- Logic
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
    local shieldSys = nil
    if pcall(function() shieldSys = ship.shieldSystem end) and shieldSys then
        local regenShieldData = nil
        local mostShields = 0
        for regenShieldName, data in pairs(regenShields) do
            if ship:HasAugmentation(regenShieldName) ~= 0 and data.max > mostShields then
                regenShieldData = data
                mostShields = data.max
            end
        end
        if regenShieldData and shieldSys.shields.power.super.first < regenShieldData.max then
            local timer = userdata_table(ship, "mods.alder.regenShieldTimer")
            if not timer.time then
                timer.time = 0
            end
            timer.time = timer.time + Hyperspace.FPS.SpeedFactor/16
            if timer.time >= regenShieldData.time then
                timer.time = 0
                for i = 1, math.min(regenShieldData.max - shieldSys.shields.power.super.first, regenShieldData.regen) do
                    shieldSys:AddSuperShield(shieldSys.center)
                    Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix("particle_shield", -1, true)
                end
            end
            timer.progress = timer.time/regenShieldData.time
            timer.color = regenShieldData.color
        end
    end
end)

-- Charge bar
local outlineColor = Graphics.GL_Color(1.0, 1.0, 1.0, 1.0) -- Color for the outline of the charge bar (White).
local function render_part_shield_charge(ship, width, x, y)
    local timer = userdata_table(ship, "mods.alder.regenShieldTimer")
    local progress = timer.progress
    if progress and progress > 0 and not ship.ship.bDestroyed then
        Graphics.CSurface.GL_DrawRectOutline(x, y, width, 6, outlineColor, 1)
        Graphics.CSurface.GL_DrawRect(2 + x, 2 + y, (width - 4)*progress, 2, timer.color)
    end
end
script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, mods.alder.doNothing, function()
    if Hyperspace.ships.player then render_part_shield_charge(Hyperspace.ships.player, 98, 30, 89) end
    if Hyperspace.ships.enemy then
        if Hyperspace.Global.GetInstance():GetCApp().gui.combatControl.boss_visual then
            render_part_shield_charge(Hyperspace.ships.enemy, 60, 767, 113)
        else
            render_part_shield_charge(Hyperspace.ships.enemy, 60, 892, 157)
        end
    end
end)