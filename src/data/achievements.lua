-- Achievements and what they unlock. `test(ctx)` receives:
--   ctx.run   = current run summary { kills, stage, evolutions, ruins, completed, mode }
--   ctx.stats = lifetime stats from the save file
-- `unlocks` ids: character_<id>, weapon_<id>, stage_<id>, mode_<id>.
local A = {}

A.LIST = {
  { id = "first_blood", name = "First Blood", desc = "Kill 100 zombies in one run.",
    reward = 10, test = function(c) return c.run.kills >= 100 end },
  { id = "headbanger", name = "Headbanger", desc = "Kill 1,000 zombies in one run.",
    unlocks = { "weapon_molotov" }, reward = 25, test = function(c) return c.run.kills >= 1000 end },
  { id = "crowd_surfer", name = "Crowd Surfer", desc = "Kill 2,500 zombies in one run.",
    unlocks = { "character_shredder" }, reward = 40, test = function(c) return c.run.kills >= 2500 end },
  { id = "encore", name = "Encore", desc = "Kill 3,000 zombies in one run.",
    unlocks = { "stage_mall" }, reward = 50, test = function(c) return c.run.kills >= 3000 end },
  { id = "archaeologist", name = "Archaeologist", desc = "Find a ruin.",
    unlocks = { "weapon_lightning_mic" }, reward = 15, test = function(c) return c.run.ruins >= 1 end },
  { id = "remix", name = "Remix", desc = "Evolve a weapon.",
    unlocks = { "character_drummer" }, reward = 30, test = function(c) return c.run.evolutions >= 1 end },
  { id = "brain_food", name = "Brain Food", desc = "Earn 100 rotting brains in total.",
    unlocks = { "character_bassist" }, reward = 0, test = function(c) return c.stats.brainsEarned >= 100 end },
  { id = "last_dance", name = "The Last Dance", desc = "Kill 10,000 zombies and join them.",
    unlocks = { "stage_highway", "mode_hyper" }, reward = 100, test = function(c) return c.run.completed end },
  { id = "headliner", name = "Headliner", desc = "Complete Highway to Hell.",
    reward = 250, test = function(c) return c.run.completed and c.run.stage == "highway" end },
}

return A
