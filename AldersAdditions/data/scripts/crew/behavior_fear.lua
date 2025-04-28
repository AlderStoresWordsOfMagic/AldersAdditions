local vter = mods.multiverse.vter
local userdata_table = mods.multiverse.userdata_table

-- [Fear Behavior - Crew can run from threats when not controlled. Actually written mostly by me!]

mods.alder.behaviorFear = {}
local behaviorFear = mods.alder.behaviorFear

behaviorFear["aa_dustworm"] = {

  flee = true, -- Will try to flee from danger sources such as enemy crew. Pathing implemented, buggy (changes target on every frame)
  flee_exceptions = {}, -- Will not treat these crew types as threats.

  -- follow_targets = {} -- Will try to follow the closest instance of these crew types. Unimplemented.
  
}

local function func(str, x)
    print(str, x)
    return x
end

local function check_crew_enemies(crew1, crew2)
    print("CHECK_CREW_ENEMIES")
    if crew1.bMindControlled ~= crew2.bMindControlled then
        return crew1.iShipId == crew2.iShipId end
    return crew1.iShipId ~= crew2.iShipId
end

local function check_crew_room_threat(crew, behaviorTable) -- check for enemies in the room
    print("CHECK_CREW_ROOM_THREAT: room: "..crew.iRoomId..", race: "..crew.type..", name: "..crew:GetName())
    for otherCrew in vter(Hyperspace.ships(crew.currentShipId).vCrewList) do
        print("race: "..otherCrew.type..", Functional(): "..tostring(otherCrew:Functional())..", ReadyToFight(): "..tostring(otherCrew:ReadyToFight()))
        local threat = func("Other crew on ship: "..otherCrew:GetSpecies()..", "..otherCrew.iRoomId, crew.iRoomId == otherCrew.iRoomId) and func("Other crew is an enemy", check_crew_enemies(crew, otherCrew)) and func("Other crew is standing still", otherCrew:AtGoal()) and not behaviorTable.flee_exceptions[otherCrew:GetSpecies()]
        if threat then return true end
    end
    return false
end

script.on_internal_event(Defines.InternalEvents.CREW_LOOP, function(crew)
    if behaviorFear[crew:GetSpecies()] then -- Test if crew has complex behavior
        if check_crew_room_threat(crew, behaviorFear[crew:GetSpecies()]) then -- Flee behavior
            local userTable = userdata_table(crew, "mods.alder.fear")
            if userTable.fearRoom and crew:AtGoal() then
                --print("AT TARGET, RESUMING NORMAL BEHAVIOR")
                userdata_table(crew, "mods.alder.fear").fearRoom = nil
            elseif userTable.fearRoom and crew.currentSlot.roomId ~= userTable.fearRoom then
                --print("MOVING TO TARGET")
                crew:MoveToRoom(userTable.fearRoom, 0, true)
            elseif not userTable.fearRoom then
                --print("NO LIST OF ROOMS FOUND, CREATING...")
                local shipManager = Hyperspace.ships(crew.currentShipId)
                local roomTable = {}
                for room in vter(shipManager.ship.vRoomList) do
                    --print("ADDED ROOM "..room.iRoomId)
                    table.insert(roomTable, room.iRoomId)
                end
                --print("THREAT DETECTED, EVACUATING")
                userTable.fearRoom = roomTable[math.random(#roomTable)]
                crew:MoveToRoom(userTable.fearRoom, 0, true)
            end
        end
    end
end)

-- script.on_render_event(Defines.RenderEvents.CREW_MEMBER_HEALTH, function(crew)
--     local userTable = userdata_table(crew, "mods.alder.fear")
--     if userTable.fearRoom then
--         --Render something here
--     end
-- end, function() end)