-- These pieces of code allow various parts of the mod to function in ways that XML alone can't satisfy.
-- Kudos to Chrono, Vertaal, and Julk for helping me figure this out!
-- For a list of stuff this code refers to, check https://github.com/FTL-Hyperspace/FTL-Hyperspace/blob/develop/FTLGameWin32.h
-- Hit CTRL + F in your browser and search.



-- [Version check for Hyperspace.]

if not (Hyperspace.version and Hyperspace.version.major == 1 and Hyperspace.version.minor >= 5) then
  if not (Hyperspace.version.patch >= 2) then
    error("Incorrect Hyperspace version detected! Alder's Additions: Second Course requires Hyperspace 1.5.2+ to function.")
  end
end

-- [Presence check for Inferno-Core.]
if not mods.inferno then
  error("Inferno-Core is missing! Alder's Additions: Second Course requires Inferno-Core to function.")
end

-- [Importing the iterator from Alder's Additions: First Strike.]

local vter = mods.alder.vter

-- [Some more compatibility.]

local INT_MAX = 2147483647



-- [Particle Shields - More of them here than just the stock one in FS.]

local particleShields = mods.alder.particleShields
particleShields["AA_INTEGRAL_PARTICLE_SHIELD"] = {
    max = 3,
    regen = 3,
    time = 10,
    color = Graphics.GL_Color(0.05, 0.25, 1.0, 1.0)
}



-- [Complex crew AI - Gives crew AI unique behaviors. Actually written mostly by me!]

mods.alder.complexCrew = {}
local complexCrew = mods.alder.complexCrew

complexCrew["aa_dustworm"] = {

  flee = true, -- Will try to flee from danger sources such as enemy crew.
  flee_hazards = false, -- Fires and breaches are included as threats.
  flee_exceptions = {}, -- Will not treat these crew types as threats.

  follow_targets = {} -- Will try to follow the closest instance of these crew types.

}

-- Logic

local function check_crew_enemies(crew1, crew2) -- check for enemies in the room
  if crew1.bMindControlled ~= crew2.bMindControlled then return crew1.iShipId == crew2.iShipId end
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