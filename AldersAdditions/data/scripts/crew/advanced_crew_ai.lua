local vter = mods.multiverse.vter

-- [Complex Behaviors - Gives crew AI unique behaviors when not controlled by the player. Actually written mostly by me!]

mods.alder.complexCrew = {}
local complexCrew = mods.alder.complexCrew

complexCrew["alder_crew"] = {

  flee = true, -- Will try to flee from danger sources such as enemy crew. Pathing implemented, buggy (changes target on every frame)
  flee_hazards = false, -- Fires and breaches are included as threats.
  flee_exceptions = {}, -- Will not treat these crew types as threats.

  follow_targets = {} -- Will try to follow the closest instance of these crew types. Unimplemented.

}

local function check_crew_enemies(crew1, crew2)
    if crew1.bMindControlled ~= crew2.bMindControlled then
        return crew1.iShipId == crew2.iShipId end
    return crew1.iShipId ~= crew2.iShipId
end

local function check_crew_room_threat(crew, behaviorTable) -- check for threats (enemies, hazards) in the room
    for otherCrew in vter(Hyperspace.ships(crew.currentShipId).vCrewList) do
        local threat = crew.iRoomId == otherCrew.iRoomId and check_crew_enemies(crew, otherCrew) and not behaviorTable.flee_exceptions[otherCrew:GetSpecies()]
        if threat then return true end
    end
    return false
end

script.on_internal_event(Defines.InternalEvents.CREW_LOOP, function(crew)
    if complexCrew[crew:GetSpecies()] then -- Test if crew has complex behavior
        if check_crew_room_threat(crew, complexCrew[crew:GetSpecies()]) then -- Flee behavior
            local ship = Hyperspace.ships(crew.currentShipId)
            local random_room = math.random(0, ship.ship.vRoomList:size() - 1)
            crew:MoveToRoom(random_room, 0, true)
        end
    end
end)