-- These pieces of code allow various parts of the mod to function in ways that XML alone can't satisfy.
-- Kudos to Chrono, Vertaal, and Julk for helping me figure this out!
-- For a list of stuff this code refers to, check https://github.com/FTL-Hyperspace/FTL-Hyperspace/blob/develop/FTLGameWin32.h
-- Hit CTRL + F in your browser and search.



-- [Version check for Hyperspace.]

if not (Hyperspace.version and Hyperspace.version.major == 1 and Hyperspace.version.minor >= 5) then
  if not (Hyperspace.version.patch >= 2) then
    error("Incorrect Hyperspace version detected! Alder's Additions: Trilogy Topper requires Hyperspace 1.5.2+ to function.")
  end
end

-- [Presence check for Inferno-Core.]
if not mods.inferno then
  error("Inferno-Core is missing! Alder's Additions: Trilogy Topper requires Inferno-Core to function.")
end

-- [Importing the iterator from Alder's Additions: First Strike.]

local vter = mods.alder.vter

-- [Some more compatibility.]

local INT_MAX = 2147483647



-- [Particle Shields.]

local particleShields = mods.alder.particleShields
particleShields["AA_SUPER_PARTICLE_SHIELD"] = {
    max = 5,
    regen = 5,
    time = 10,
    color = Graphics.GL_Color(1, 0, 1.0, 0.4156)
}