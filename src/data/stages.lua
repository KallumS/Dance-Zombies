-- Stages. Each stage is one song (folder under assets/songs/). `unlock` is the unlock id
-- required (nil = available from the start).
local S = {}

S.graveyard = {
  name = "Graveyard Groove", song = "graveyard_groove",
  desc = "Where it all begins. Mind the headstones.",
  ground = { 0.13, 0.15, 0.12 }, detail = { 0.19, 0.22, 0.17 },
}
S.mall = {
  name = "Mall of the Dead", song = "mall_of_the_dead", unlock = "stage_mall",
  desc = "Retail therapy for the recently deceased. Faster tempo.",
  ground = { 0.16, 0.14, 0.18 }, detail = { 0.24, 0.2, 0.27 },
}
S.highway = {
  name = "Highway to Hell", song = "highway_to_hell", unlock = "stage_highway",
  desc = "150 BPM of pure panic.",
  ground = { 0.18, 0.12, 0.11 }, detail = { 0.28, 0.16, 0.14 },
}

S.ORDER = { "graveyard", "mall", "highway" }

-- Game modes (multipliers applied in spawner/stats).
S.MODES = {
  normal = { name = "Normal", desc = "Kill 10,000 zombies.", enemyHp = 1, spawn = 1, brains = 1 },
  hyper = { name = "Hyper", unlock = "mode_hyper", desc = "Faster, meaner hordes. +50% brains.", enemyHp = 1.25, spawn = 1.5, enemySpeed = 1.25, brains = 1.5 },
}
S.MODE_ORDER = { "normal", "hyper" }

S.KILLS_TO_WIN = 10000

return S
