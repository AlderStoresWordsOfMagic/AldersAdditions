-- [VSCode won't shut up about Hyperspace's defs not being defined, so these are the ball gags that keep it in its place.]

mods = mods or {}
Hyperspace = Hyperspace or {}
script = script or {}
Defines = Defines or {}
Graphics = Graphics or {}

-- [Defining the Alder name space. The Alderspace? I dunno. Keeps all the mechanical parts from overlapping with other mods.]

mods.alder = {}


-- [Checks for requisite mods.]

if not (Hyperspace.version and Hyperspace.version.major == 1 and Hyperspace.version.minor >= 15) then
  if not (Hyperspace.version.patch >= 0) then
    error("Incorrect Hyperspace version detected! Alder's Additions requires Hyperspace 1.15+ to function.")
  end
end

if not mods.multiverse then
    error("Couldn't find Multiverse! Alder's Additions is an addon for Multiverse; make sure it is above Alder's Additions in Slipstream's load order.")
end

if not mods or not mods.fusion then
    error("Couldn't find Fusion! Make sure it's above Alder's Additions, but below Multiverse, in Slipstream's load order.")
end


-- [Importing critical Multiverse Lua functions.]

local vter = mods.multiverse.vter
local userdata_table = mods.multiverse.userdata_table
local get_room_at_location = mods.multiverse.get_room_at_location
local get_adjacent_rooms = mods.multiverse.get_adjacent_rooms
local INT_MAX = mods.multiverse.INT_MAX


-- [A function that does nothing.]

function mods.alder.doNothing()
end



-- [ The following code is silly stuff, code that is not part of the mod but which has been saved for usage later by any party. ]

-- [Silksteel Hull - Add temporary HP upon ship repair completion (thanks Arc)]
-- [FUSION DEPENDENCY]

-- local systemIntegrityTable = {}
-- local systemIntegrityTableEnemy = {}

-- script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function()
--     systemIntegrityTableEnemy = {}
-- end)

-- -- combat healing, takes the enemy into account
-- script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
--     if ship:HasAugmentation("AA_TECH_TEMP_HP_REPAIR") ~= 0 then -- do we have the aug?
--         local cApp = Hyperspace.Global.GetInstance():GetCApp()
--         local combatControl = cApp.gui.combatControl
--         if not Hyperspace.ships.enemy._targetable.hostile then return end -- if not in combat, return early and disregard this logic entirely

--         for system in vter(ship.vSystemList) do -- get every system in the table
--             if ship.iShipId == 0 then
--                 if systemIntegrityTable[system.name] and system.healthState.first == system.healthState.second and systemIntegrityTable[system.name] ~= system.healthState.first and mods.fusion.tempHp < 15 then -- if the system exists
--                     mods.fusion.tempHp = mods.fusion.tempHp + 1
--                     Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix("temp_hull",-1,true)
--                 end
--                 systemIntegrityTable[system.name] = system.healthState.first -- set the table entry's health to the current integrity of the system
--             else
--                 if systemIntegrityTableEnemy[system.name] and system.healthState.first == system.healthState.second and systemIntegrityTableEnemy[system.name] ~= system.healthState.first and mods.fusion.enemytempHp < 15 then -- if the system exists
--                     mods.fusion.enemytempHp = mods.fusion.enemytempHp + 1
--                     Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix("temp_hull",-1,true)
--                 end
--                 systemIntegrityTableEnemy[system.name] = system.healthState.first -- set the table entry's health to the current integrity of the system
--             end
--         end
--     end
-- end)

-- -- out-of-combat healing, only involves the player (NONFUNCTIONAL SO FAR)
-- script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
--     if ship:HasAugmentation("AA_TECH_TEMP_HP_REPAIR") ~= 0 then -- do we have the aug?
--         local cApp = Hyperspace.Global.GetInstance():GetCApp()
--         local combatControl = cApp.gui.combatControl
--         if Hyperspace.ships.enemy._targetable.hostile then return end -- if in combat, disregard this logic

--         for system in vter(ship.vSystemList) do -- get every system in the table
--             if systemIntegrityTable[system.name] and system.healthState.first == system.healthState.second and systemIntegrityTable[system.name] ~= system.healthState.first and mods.fusion.tempHp < 15 then -- if the system exists
--                 mods.fusion.tempHp = mods.fusion.tempHp + 1
--                 Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix("temp_hull",-1,true)
--             end
--             systemIntegrityTable[system.name] = system.healthState.first -- set the table entry's health to the current integrity of the system
--         end
--     end
-- end)