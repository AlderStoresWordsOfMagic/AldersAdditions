local vter = mods.multiverse.vter

local fires = mods.fusion.fires
local get_fire_extend = mods.fusion.get_fire_extend

-- [Advanced Room Resistances - Allows for the creation of unhackable rooms. Fire/sabo-resistant rooms are handled through Fusion and XML statboosts.]

mods.alder.firewallShips = { -- List of room IDs for each ship that uses it
    AA_MVBOSS_HACKER_CRUISER_NORMAL = {15, 5}, -- shields, teleporter
    AA_MVBOSS_HACKER_CRUISER_CHALLENGE = {15, 5}, -- shields, teleporter
    AA_MVBOSS_HACKER_CRUISER_EXTREME = {15, 5, 11}, -- shields, teleporter, temporal
    AA_MVBOSS_HACKER_CRUISER_CHAOS = {15, 11}, -- shields, temporal
}

mods.alder.encasedShips = { -- List of room IDs for each ship that uses it
    AA_MVBOSS_STEALTH_CRUISER_CHALLENGE = {16}, -- cloaking
    AA_MVBOSS_STEALTH_CRUISER_EXTREME = {16, 15}, -- cloaking, drones
    AA_MVBOSS_STEALTH_CRUISER_CHAOS = {16, 15} -- cloaking, drones
}


-- Firewall logic
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    local firewalledRooms = mods.alder.firewallShips[shipManager.myBlueprint.blueprintName]
    local otherShip = Hyperspace.ships(1 - shipManager.iShipId)
    local enemyHacking = nil
    if otherShip then
        enemyHacking = otherShip.hackingSystem
    end
    if firewalledRooms ~= nil then
        for _, room in ipairs(firewalledRooms) do
            local system = shipManager:GetSystemInRoom(room)
            system:StopHacking() -- Unhack system
            if enemyHacking and enemyHacking.drone.arrived and enemyHacking.currentSystem == system then
                enemyHacking:BlowHackingDrone() -- Destroy the hacking drone not owned by the room owner
            end
        end
    end
end)


-- Encased logic, sabo is handled by statboost in room itself
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    local encasedRooms = mods.alder.encasedShips[shipManager.myBlueprint.blueprintName]
    if encasedRooms ~= nil then
        for _, room in ipairs(encasedRooms) do
            for fire in fires(shipManager.ship.vRoomList[room], shipManager) do
                mods.fusion.get_fire_extend(fire).systemDamageMultiplier = 0
            end
        end
    end
end, -9999) -- Set priority to a really low value to ensure it runs after all other events