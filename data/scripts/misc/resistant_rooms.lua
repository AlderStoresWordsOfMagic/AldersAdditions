local vter = mods.multiverse.vter
local fires = mods.fusion.custom_fires.fires -- Silly wrote a library in Fusion that allows fires to be manipulated through Lua more easily.
local get_fire_extend = mods.fusion.custom_fires.get_fire_extend
local FIRE_STAT_APPLICATION_PRIORITY = mods.fusion.custom_fires.constants.FIRE_STAT_APPLICATION_PRIORITY

-- [Advanced Room Resistances - Allows for the creation of unhackable and non-flammable rooms.]

mods.alder.firewallShips = { -- List of room IDs for each ship that uses firewalled rooms
    AA_MVBOSS_HACKER_CRUISER_NORMAL = {15, 5}, -- shields, teleporter
    AA_MVBOSS_HACKER_CRUISER_CHALLENGE = {15, 5}, -- shields, teleporter
    AA_MVBOSS_HACKER_CRUISER_EXTREME = {15, 5, 11}, -- shields, teleporter, temporal
    AA_MVBOSS_HACKER_CRUISER_CHAOS = {15, 14, 5, 11}, -- shields, weapons, drones, temporal
}

mods.alder.encasedShips = { -- List of room IDs for each ship that uses encased rooms
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

            -- Handle power drain
            system.extend.additionalPowerLoss = 0

            -- Handle hacking effects and drones in the room
            if system.iHackEffect == 2 and system.bUnderAttack then
                system:StopHacking()
                system.iHackEffect = 0
                Hyperspace.Sounds:PlaySoundMix("hack_resist", -1, false) -- Fun sound effect
            end
            if enemyHacking and enemyHacking.drone.arrived and enemyHacking.currentSystem == system then
                enemyHacking:BlowHackingDrone() -- Destroy the hacking drone not owned by the room owner
                enemyHacking.currentSystem = nil -- Experimental
                system:StopHacking()
                system.iHackEffect = 0
            end
        end
    end
end)


-- Encased logic, sabo is handled by statboost via augment
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    local encasedRooms = mods.alder.encasedShips[shipManager.myBlueprint.blueprintName]
    if encasedRooms ~= nil then
        for _, room in ipairs(encasedRooms) do
            for fire in fires(shipManager.ship.vRoomList[room], shipManager) do

                -- Reduce fire damage to 0
                get_fire_extend(fire).systemDamageMultiplier = 0
            end
        end
    end
end, FIRE_STAT_APPLICATION_PRIORITY + 1) -- Set priority to a really low value to ensure it runs after all other events