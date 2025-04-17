local vter = mods.multiverse.vter

-- [Drone Pointer Antenna - Retargets all active combat drones to the targeted room.]

mods.alder.painters = {}
local painters = mods.alder.painters

painters["AA_POINTER"] = true

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
    local weaponName = nil
    pcall(function() weaponName = Hyperspace.Get_Projectile_Extend(projectile).name end)
    if weaponName then
        if painters[weaponName] then
            for drone in vter(Hyperspace.Global.GetInstance():GetShipManager((shipManager.iShipId + 1)%2).spaceDrones) do
                drone.targetLocation = location
            end
        end
    end
end)