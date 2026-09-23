-- Decides when and where zombies appear. Spawns happen on the beat, so the horde
-- literally arrives in time with the music. Difficulty scales with kill count.
local Enemies = require("src.data.enemies")
local U = require("src.core.util")

local Spawner = {}
Spawner.__index = Spawner

Spawner.MAX_ENEMIES = 450
Spawner.SPAWN_RADIUS = 580     -- just outside the 960x540 view
Spawner.DESPAWN_RADIUS = 900   -- zombies further than this are recycled ahead of the player

function Spawner.new(world, mode)
  return setmetatable({ world = world, mode = mode, nextBoss = Enemies.BOSS_EVERY, bars = 0 }, Spawner)
end

function Spawner:targetCount()
  local k = self.world.kills
  return math.min(Spawner.MAX_ENEMIES, (25 + k * 0.045 + self.world.time * 0.15) * (self.mode.spawn or 1))
end

function Spawner:hpScale()
  return (1 + self.world.kills / 2500) * (self.mode.enemyHp or 1)
end

function Spawner:pickType()
  local k = self.world.kills
  local avail = {}
  for _, id in ipairs(Enemies.ORDER) do
    if k >= Enemies[id].from then avail[#avail + 1] = id end
  end
  return U.weightedPick(avail, function(id) return Enemies[id].weight end)
end

function Spawner:ringPosition(dist)
  local p = self.world.player
  local a = math.random() * math.pi * 2
  local d = dist or (Spawner.SPAWN_RADIUS + math.random() * 80)
  return p.x + math.cos(a) * d, p.y + math.sin(a) * d
end

function Spawner:spawn(typeId, x, y)
  local def = Enemies[typeId]
  local hp = def.hp * self:hpScale()
  if def.boss then hp = hp * (1 + self.world.kills / 5000) end
  local e = {
    type = typeId, def = def, x = x, y = y, hp = hp, maxHp = hp, r = def.radius,
    speed = def.speed * (self.mode.enemySpeed or 1) * (0.9 + math.random() * 0.2),
    damage = def.damage, xp = def.xp, kx = 0, ky = 0, flash = 0, slowT = 0, slowAmt = 0,
    boss = def.boss, bobSeed = math.random() * 10,
  }
  self.world.enemies[#self.world.enemies + 1] = e
  return e
end

-- Called on every beat by the world.
function Spawner:onBeat()
  local world = self.world
  local deficit = self:targetCount() - #world.enemies
  if deficit > 0 then
    local n = math.min(math.ceil(deficit * 0.35), 3 + math.floor(world.kills / 400))
    for _ = 1, n do
      local x, y = self:ringPosition()
      self:spawn(self:pickType(), x, y)
    end
  end
  if world.kills >= self.nextBoss then
    self.nextBoss = self.nextBoss + Enemies.BOSS_EVERY
    local x, y = self:ringPosition()
    self:spawn("big_daddy", x, y)
    world.fx:toast("BIG DADDY is coming!", { 1, 0.4, 0.4 })
  end
end

-- Called on every bar. Every 16 bars (after a warm-up) a ring horde surrounds the player.
function Spawner:onBar()
  self.bars = self.bars + 1
  local world = self.world
  if self.bars % 16 == 0 and world.kills > 150 and #world.enemies < Spawner.MAX_ENEMIES - 40 then
    local n = 24 + math.min(40, math.floor(world.kills / 250))
    local p = world.player
    for i = 1, n do
      local a = (i / n) * math.pi * 2
      self:spawn("shambler", p.x + math.cos(a) * 420, p.y + math.sin(a) * 420)
    end
    world.fx:toast("The horde closes in!", { 0.6, 1, 0.5 })
  end
end

-- Zombies left far behind get moved to the spawn ring so pressure stays on the player.
function Spawner:recycle(e)
  local p = self.world.player
  if U.dist2(e.x, e.y, p.x, p.y) > Spawner.DESPAWN_RADIUS ^ 2 and not e.boss then
    e.x, e.y = self:ringPosition()
  end
end

return Spawner
