local vter = mods.multiverse.vter

-- [Missile Drones - Balancing methods for drones that fire missiles.] --

mods.alder.missileDrones = {}
local missileDrones = mods.alder.missileDrones

local deployedMissileDrones = {}

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
    for drone in vter(ship.spaceDrones) do
        local missileDeployCost = missileDrones[drone.blueprint.name]
        if missileDeployCost then
            if drone.deployed then
                if not deployedMissileDrones[drone.selfId] then
                    deployedMissileDrones[drone.selfId] = true
                    if ship:GetMissileCount() >= missileDeployCost then
                        ship:ModifyMissileCount(-missileDeployCost)
                    else
                        drone:SetDestroyed(true, false)
                        ship:ModifyDroneCount(1)
                    end
                end
            else
                deployedMissileDrones[drone.selfId] = nil
            end
        end
    end
end)