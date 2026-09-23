-- Zombie types. `from` is the kill count at which a type starts spawning; `weight` is its
-- relative spawn chance once available. HP scales further with kills (see spawner.lua).
local E = {}

E.shambler = { name = "Shambler", hp = 10, speed = 42, damage = 6, radius = 11, xp = 1, from = 0, weight = 10, color = { 0.45, 0.7, 0.35 } }
E.runner = { name = "Runner", hp = 7, speed = 92, damage = 5, radius = 9, xp = 1, from = 250, weight = 5, color = { 0.65, 0.8, 0.3 } }
E.bloater = { name = "Bloater", hp = 45, speed = 32, damage = 10, radius = 17, xp = 5, from = 1200, weight = 2, color = { 0.55, 0.6, 0.25 } }
E.brute = { name = "Brute", hp = 130, speed = 50, damage = 16, radius = 21, xp = 20, from = 3500, weight = 1, color = { 0.35, 0.5, 0.3 } }

-- Spawned every BOSS_EVERY kills; drops a treasure chest.
E.big_daddy = { name = "Big Daddy", hp = 1200, speed = 58, damage = 25, radius = 38, xp = 100, boss = true, color = { 0.6, 0.25, 0.3 } }

E.ORDER = { "shambler", "runner", "bloater", "brute" }
E.BOSS_EVERY = 1000

return E
