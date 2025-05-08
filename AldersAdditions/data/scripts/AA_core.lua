-- [The core Lua file Alder's Additions uses.]


-- [VSCode won't shut up about Hyperspace's defs not being defined, so these statements satisfy its complaints.]

mods = mods or {}
Hyperspace = Hyperspace or {}
script = script or {}
Defines = Defines or {}
Graphics = Graphics or {}

-- [Defining the Alder name space. The Alderspace? I dunno. Keeps all the mechanical parts from overlapping with other mods.]

mods.alder = {}


-- [Checks for requisite mods.]

if not (Hyperspace.version and Hyperspace.version.major == 1 and Hyperspace.version.minor >= 19) then
    if not (Hyperspace.version.patch >= 0) then
        error("Incorrect Hyperspace version detected! Alder's Additions requires Hyperspace 1.19+ to function properly.")
    end
end

if not mods.multiverse then
    error("Couldn't find Multiverse! Alder's Additions is an addon for Multiverse; make sure it is above Alder's Additions in Slipstream's load order.")
end

if not mods or not mods.fusion then
    error("Couldn't find Fusion! Make sure it's above Alder's Additions, but below Multiverse, in Slipstream's load order.")
end


-- [A function that does nothing. Used to fill space in certain other functions.]

function mods.alder.doNothing()
end