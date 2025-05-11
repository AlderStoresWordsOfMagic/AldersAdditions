local vter = mods.multiverse.vter
local userdata_table = mods.multiverse.userdata_table

-- [Fear Behavior - Crew can run from threats when not controlled. Actually written mostly by me!]

mods.alder.behaviorFear = {}
local behaviorFear = mods.alder.behaviorFear

behaviorFear["aa_dustworm"] = { -- aa_dustworm

    flee = true, -- Will try to flee from danger sources such as enemy crew.
    flee_exceptions = {"zoltan_monk"}, -- Will not treat these crew types as threats.

}

local function func(str, x)
    print(str, x)
    return x
end

local function check_crew_enemies(crew1, crew2)
    if crew1.bMindControlled ~= crew2.bMindControlled then
        return crew1.iShipId == crew2.iShipId end
    return crew1.iShipId ~= crew2.iShipId
end

local function check_crew_room_threat(crew, behaviorTable)
    for otherCrew in vter(Hyperspace.ships(crew.currentShipId).vCrewList) do
        local threat = crew.iRoomId == otherCrew.iRoomId and check_crew_enemies(crew, otherCrew) and otherCrew:AtGoal() and otherCrew:ReadyToFight() and not behaviorTable.flee_exceptions[otherCrew:GetSpecies()]
        if threat then return true end
    end
    return false
end

script.on_internal_event(Defines.InternalEvents.CREW_LOOP, function(crew)
    if behaviorFear[crew:GetSpecies()] then -- Test if crew has fear behavior
        local userTable = userdata_table(crew, "mods.alder.fear")
        if userTable.fearRoom and crew:AtGoal() then
            userdata_table(crew, "mods.alder.fear").fearRoom = nil
        elseif userTable.fearRoom then
            crew:MoveToRoom(userTable.fearRoom, 0, true)
        elseif not userTable.fearRoom then -- Crew should only update fear behavior when not already fleeing
            if check_crew_room_threat(crew, behaviorFear[crew:GetSpecies()]) then -- If the crew should flee
                local shipManager = Hyperspace.ships(crew.currentShipId)
                local roomTable = {0}
                -- for room in vter(shipManager.ship.vRoomList) do
                --     print("ADDED ROOM "..room.iRoomId)
                --     table.insert(roomTable, room.iRoomId)
                -- end
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