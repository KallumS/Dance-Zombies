-- Weapon definitions. Balance lives here; behaviour code lives in src/game/behaviours.lua.
--
--   track      which stem of the song this weapon unmutes AND fires on (see song.lua patterns)
--   behaviour  which function in behaviours.lua runs on each hit
--   stats      level 1 stats; `levels[n]` are additive deltas applied when reaching level n
--   evolveWith passive id that, together with max level, lets this weapon evolve
--   evolution  id of the evolved weapon (also defined in this file, with evolved = true)
--
-- Pattern density is automatic: level 3 adds medium hits (x), level 5 adds ghost hits (o).
local W = {}

W.crossbow = {
  name = "Crossbow", track = "drums", behaviour = "bolt", maxLevel = 8,
  desc = "Fires a bolt at the nearest zombie on every drum hit.",
  evolveWith = "echo_pedal", evolution = "drumline_ballista",
  color = { 0.95, 0.85, 0.4 },
  stats = { damage = 10, amount = 1, speed = 620, pierce = 1, size = 5, life = 1.2, knockback = 60 },
  levels = {
    [2] = { text = "+5 damage", damage = 5 },
    [3] = { text = "Also fires on medium drum hits" },
    [4] = { text = "+1 pierce", pierce = 1 },
    [5] = { text = "Also fires on ghost notes" },
    [6] = { text = "+1 bolt", amount = 1 },
    [7] = { text = "+8 damage", damage = 8 },
    [8] = { text = "+1 bolt, +1 pierce", amount = 1, pierce = 1 },
  },
}

W.shotgun = {
  name = "Shotgun", track = "guitar", behaviour = "spread", maxLevel = 8,
  desc = "Blasts a cone of pellets on every guitar stab.",
  evolveWith = "amplifier", evolution = "wall_of_sound",
  color = { 1.0, 0.55, 0.3 },
  stats = { damage = 9, amount = 5, speed = 520, pierce = 1, size = 4, life = 0.35, spread = 0.7, knockback = 90 },
  levels = {
    [2] = { text = "+2 pellets", amount = 2 },
    [3] = { text = "Also fires on medium guitar hits" },
    [4] = { text = "+5 damage", damage = 5 },
    [5] = { text = "Also fires on ghost notes" },
    [6] = { text = "+2 pellets, longer range", amount = 2, life = 0.12 },
    [7] = { text = "+1 pierce", pierce = 1 },
    [8] = { text = "+6 damage", damage = 6 },
  },
}

W.bass_cannon = {
  name = "Bass Cannon", track = "bass", behaviour = "pulse", maxLevel = 8,
  desc = "Every bass note sends a shockwave out around you.",
  evolveWith = "armor_vest", evolution = "sub_drop",
  color = { 0.45, 0.6, 1.0 },
  stats = { damage = 8, radius = 105, knockback = 160 },
  levels = {
    [2] = { text = "+20% radius", radius = 18 },
    [3] = { text = "Also fires on medium bass hits" },
    [4] = { text = "+5 damage", damage = 5 },
    [5] = { text = "Also fires on ghost notes" },
    [6] = { text = "+20% radius", radius = 18 },
    [7] = { text = "+6 damage", damage = 6 },
    [8] = { text = "+25% radius, more knockback", radius = 22, knockback = 80 },
  },
}

W.hihat_blades = {
  name = "Hi-Hat Blades", track = "perc", behaviour = "slash", maxLevel = 8,
  desc = "Quick slashes that alternate sides with the hi-hats.",
  evolveWith = "running_shoes", evolution = "blast_beat",
  color = { 0.8, 0.95, 1.0 },
  stats = { damage = 7, width = 110, height = 36, amount = 1, knockback = 40 },
  levels = {
    [2] = { text = "+3 damage", damage = 3 },
    [3] = { text = "Also fires on every 8th note" },
    [4] = { text = "+25% size", width = 25, height = 8 },
    [5] = { text = "Also fires on every 16th note" },
    [6] = { text = "+4 damage", damage = 4 },
    [7] = { text = "Slashes both sides", amount = 1 },
    [8] = { text = "+5 damage, +25% size", damage = 5, width = 25, height = 8 },
  },
}

W.molotov = {
  name = "Molotov", track = "keys", behaviour = "molotov", maxLevel = 8,
  desc = "Lobs a burning bottle at a zombie on every chord.",
  evolveWith = "protein_shake", evolution = "mosh_pit",
  color = { 1.0, 0.4, 0.2 },
  stats = { damage = 5, amount = 1, radius = 50, duration = 2.5, tick = 0.3 },
  levels = {
    [2] = { text = "+1 bottle", amount = 1 },
    [3] = { text = "Also fires on medium chords" },
    [4] = { text = "+20% radius", radius = 10 },
    [5] = { text = "Also fires on ghost chords" },
    [6] = { text = "+3 damage", damage = 3 },
    [7] = { text = "+1 bottle, burns longer", amount = 1, duration = 1 },
    [8] = { text = "+4 damage, +20% radius", damage = 4, radius = 10 },
  },
}

W.lightning_mic = {
  name = "Lightning Mic", track = "lead", behaviour = "lightning", maxLevel = 8,
  desc = "The lead line calls lightning that chains between zombies.",
  evolveWith = "magnet", evolution = "feedback_storm",
  color = { 0.75, 0.6, 1.0 },
  stats = { damage = 14, amount = 1, chains = 2, chainRange = 140 },
  levels = {
    [2] = { text = "+1 chain", chains = 1 },
    [3] = { text = "Also fires on medium lead notes" },
    [4] = { text = "+8 damage", damage = 8 },
    [5] = { text = "Also fires on ghost notes" },
    [6] = { text = "+1 strike", amount = 1 },
    [7] = { text = "+2 chains", chains = 2 },
    [8] = { text = "+10 damage", damage = 10 },
  },
}

-- Evolutions: fire on every hit of their track regardless of accent.
W.drumline_ballista = {
  name = "Drumline Ballista", track = "drums", behaviour = "bolt", evolved = true,
  desc = "Three piercing bolts per hit. Nothing survives the groove.",
  color = { 1.0, 0.95, 0.5 },
  stats = { damage = 30, amount = 3, speed = 800, pierce = 6, size = 8, life = 1.5, knockback = 90 },
}
W.wall_of_sound = {
  name = "Wall of Sound", track = "guitar", behaviour = "spread", evolved = true,
  desc = "A 360 degree ring of shrapnel on every riff.",
  color = { 1.0, 0.7, 0.3 },
  stats = { damage = 22, amount = 24, speed = 560, pierce = 3, size = 5, life = 0.6, spread = math.pi * 2, knockback = 120 },
}
W.sub_drop = {
  name = "Sub Drop", track = "bass", behaviour = "pulse", evolved = true,
  desc = "Enormous bass waves that slow everything they touch.",
  color = { 0.35, 0.5, 1.0 },
  stats = { damage = 26, radius = 230, knockback = 260, slow = 0.5 },
}
W.blast_beat = {
  name = "Blast Beat", track = "perc", behaviour = "slash", evolved = true,
  desc = "Huge slashes on both sides, every single hi-hat.",
  color = { 0.85, 1.0, 1.0 },
  stats = { damage = 22, width = 220, height = 70, amount = 2, knockback = 80 },
}
W.mosh_pit = {
  name = "Mosh Pit", track = "keys", behaviour = "molotov", evolved = true,
  desc = "Raging fire pits that follow the crowd.",
  color = { 1.0, 0.3, 0.1 },
  stats = { damage = 14, amount = 3, radius = 95, duration = 4, tick = 0.25, follow = true },
}
W.feedback_storm = {
  name = "Feedback Storm", track = "lead", behaviour = "lightning", evolved = true,
  desc = "Screaming feedback arcs through the whole horde.",
  color = { 0.85, 0.7, 1.0 },
  stats = { damage = 36, amount = 3, chains = 8, chainRange = 220 },
}

-- Weapons offered in level-up choices when unlocked (evolutions are never offered directly).
W.POOL = { "crossbow", "shotgun", "bass_cannon", "hihat_blades", "molotov", "lightning_mic" }

-- Stats of a weapon at a given level (pure).
function W.statsAt(id, level)
  local def = W[id]
  local s = {}
  for k, v in pairs(def.stats) do s[k] = v end
  if def.levels then
    for l = 2, level do
      local d = def.levels[l]
      if d then
        for k, v in pairs(d) do
          if k ~= "text" then s[k] = (s[k] or 0) + v end
        end
      end
    end
  end
  return s
end

return W
