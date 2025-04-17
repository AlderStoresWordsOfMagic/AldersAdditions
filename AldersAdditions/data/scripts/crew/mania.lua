local vter = mods.multiverse.vter
local get_room_at_location = mods.multiverse.get_room_at_location

-- [Mania - Status effect/crew trait that causes them to repair enemy systems and/or disable system bars on repair. Framework by Arc, actual effect was a joint effort.]

local maniaTablePlayer = {}
local maniaTableEnemy = {}
local maniaTable = {maniaTablePlayer, maniaTableEnemy}

mods.alder.maniaWeapons = {}
local maniaWeapons = mods.alder.maniaWeapons
maniaWeapons["WEAPON_ONE"] = 30
maniaWeapons["WEAPON_TWO"] = 90

mods.alder.maniaCrew = {}
local maniaCrew = mods.alder.maniaCrew
maniaCrew["crew_one"] = true
maniaCrew["crew_two"] = true

local function applyMania(crewmem) -- how tf is this gonna work
end

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    local mania = maniaTable[shipManager.iShipId]
    for crewmem in vter(shipManager.vCrewList) do
        if mania[crewmem.iRoomId] then
            applyMania(crewmem)
        end
    end
end)

script.on_internal_event(Defines.InternalEvents.CREW_LOOP, function(crewmem)
    if maniaCrew[crewmem.type] then
        applyMania(crewmem)
    end
end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
    if maniaWeapons[projectile.extend.name] then
        local room = get_room_at_location(shipManager, location, true)
        maniaTable[shipManager.iShipId][room] = math.max(maniaTable[shipManager.iShipId][room], maniaWeapons[projectile.extend.name])
    end
end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM, function(shipManager, projectile, location, damage, realNewTile, beamHitType)
    if maniaWeapons[projectile.extend.name] and beamHitType == Defines.BeamHit.NEW_ROOM then
        local room = get_room_at_location(shipManager, location, true)
        maniaTable[shipManager.iShipId][room] = math.max(maniaTable[shipManager.iShipId][room], maniaWeapons[projectile.extend.name])
    end
end)