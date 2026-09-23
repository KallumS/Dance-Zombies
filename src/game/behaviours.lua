-- What each weapon does when its track hits. Called by World:onStep.
--   world    the World
--   w        the weapon instance { id, level, stats, flip, ... }
--   s        w.stats (see data/weapons.lua)
--   vel      hit velocity 0..1 (strong beats hit harder)
local U = require("src.core.util")
local Weapons = require("src.data.weapons")

local B = {}

local function damageOf(world, s, vel)
  return s.damage * world.stats.might * (0.6 + 0.4 * vel)
end

-- Crossbow: bolts at the nearest zombies.
function B.bolt(world, w, s, vel)
  local p = world.player
  local n = s.amount + world.stats.amount
  local targets = world:nearestEnemies(n, 650)
  local color = Weapons[w.id].color
  for i = 1, n do
    local t = targets[((i - 1) % math.max(1, #targets)) + 1]
    local dx, dy
    if t then dx, dy = U.norm(t.x - p.x, t.y - p.y) else dx, dy = p.faceX, p.faceY end
    if not t or #targets < i then
      local a = math.atan2(dy, dx) + (i - 1) * 0.15 * ((i % 2 == 0) and 1 or -1)
      dx, dy = math.cos(a), math.sin(a)
    end
    world:spawnProjectile({
      x = p.x, y = p.y, vx = dx * s.speed, vy = dy * s.speed, damage = damageOf(world, s, vel),
      pierce = s.pierce, r = s.size * world.stats.area, life = s.life, knockback = s.knockback,
      color = color, kind = "bolt",
    })
  end
end

-- Shotgun: a cone of pellets towards the nearest zombie (or facing direction).
function B.spread(world, w, s, vel)
  local p = world.player
  local t = world:nearestEnemies(1, 380)[1]
  local base
  if t then base = math.atan2(t.y - p.y, t.x - p.x) else base = math.atan2(p.faceY, p.faceX) end
  local n = s.amount + world.stats.amount * 2
  local full = s.spread >= math.pi * 2 - 0.01
  local color = Weapons[w.id].color
  for i = 1, n do
    local a
    if full then a = base + (i / n) * math.pi * 2
    else a = base - s.spread / 2 + s.spread * ((i - 0.5) / n) + (math.random() - 0.5) * 0.08 end
    local sp = s.speed * (0.85 + math.random() * 0.3)
    world:spawnProjectile({
      x = p.x, y = p.y, vx = math.cos(a) * sp, vy = math.sin(a) * sp, damage = damageOf(world, s, vel),
      pierce = s.pierce, r = s.size * world.stats.area, life = s.life, knockback = s.knockback,
      color = color, kind = "pellet",
    })
  end
  world.fx:addShake(1.5)
end

-- Bass Cannon: shockwave around the player.
function B.pulse(world, w, s, vel)
  local p = world.player
  local radius = s.radius * world.stats.area
  local dmg = damageOf(world, s, vel)
  world:enemiesInRadius(p.x, p.y, radius, function(e)
    local dx, dy = U.norm(e.x - p.x, e.y - p.y)
    world:hitEnemy(e, dmg, dx, dy, s.knockback)
    if s.slow then e.slowT, e.slowAmt = 1.5, s.slow end
  end)
  world.fx:ring(p.x, p.y, radius, Weapons[w.id].color, true)
  if s.slow then world.fx:addShake(3) end
end

-- Hi-Hat Blades: horizontal slash, alternating sides.
function B.slash(world, w, s, vel)
  local p = world.player
  local width, height = s.width * world.stats.area, s.height * world.stats.area
  local dmg = damageOf(world, s, vel)
  w.flip = not w.flip
  local sides
  if s.amount + world.stats.amount >= 2 then sides = { 1, -1 }
  else sides = { (w.flip and -1 or 1) * (p.faceX < 0 and -1 or 1) } end
  for _, dir in ipairs(sides) do
    local cx = p.x + dir * (width / 2 + 8)
    local cy = p.y
    world:enemiesInRadius(cx, cy, width / 2 + 40, function(e)
      if math.abs(e.x - cx) < width / 2 + e.r and math.abs(e.y - cy) < height / 2 + e.r then
        world:hitEnemy(e, dmg, dir, 0, s.knockback)
      end
    end)
    world.fx:slash(cx, cy, width, height, dir, Weapons[w.id].color)
  end
end

-- Molotov: lob bottles at random zombies; they burst into fire zones.
function B.molotov(world, w, s, vel)
  local p = world.player
  local n = s.amount + world.stats.amount
  for _ = 1, n do
    local e = world:randomEnemyNear(p.x, p.y, 380)
    local tx, ty
    if e then tx, ty = e.x, e.y
    else
      local a = math.random() * math.pi * 2
      tx, ty = p.x + math.cos(a) * 150, p.y + math.sin(a) * 150
    end
    world:spawnLob({
      x0 = p.x, y0 = p.y, x1 = tx, y1 = ty, t = 0, dur = 0.35,
      zone = {
        radius = s.radius * world.stats.area, life = s.duration, tick = s.tick,
        damage = damageOf(world, s, vel), follow = s.follow, color = Weapons[w.id].color,
      },
    })
  end
end

-- Lightning Mic: strike a zombie and chain to neighbours.
function B.lightning(world, w, s, vel)
  local p = world.player
  local n = s.amount + world.stats.amount
  local dmg = damageOf(world, s, vel)
  local color = Weapons[w.id].color
  for _ = 1, n do
    local e = world:randomEnemyNear(p.x, p.y, 420)
    if not e then return end
    local hit = { [e] = true }
    local pts = { e.x, e.y - 400, e.x, e.y }
    world:hitEnemy(e, dmg, 0, 0, 0)
    local cur = e
    for _ = 1, s.chains do
      local best, bestD = nil, (s.chainRange * world.stats.area) ^ 2
      world:enemiesInRadius(cur.x, cur.y, s.chainRange * world.stats.area, function(o)
        if not hit[o] and not o.dead then
          local d = U.dist2(o.x, o.y, cur.x, cur.y)
          if d < bestD then best, bestD = o, d end
        end
      end)
      if not best then break end
      hit[best] = true
      pts[#pts + 1] = best.x; pts[#pts + 1] = best.y
      world:hitEnemy(best, dmg * 0.8, 0, 0, 0)
      cur = best
    end
    world.fx:bolt(pts, color)
  end
end

return B
