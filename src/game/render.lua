-- Draws the world. Every object first tries a sprite from assets/sprites/ (via Assets.drawSprite)
-- and falls back to simple placeholder shapes, so art can be dropped in one file at a time.
local Assets = require("src.core.assets")
local Weapons = require("src.data.weapons")
local U = require("src.core.util")

local Render = {}

Render.VIEW_W, Render.VIEW_H = 960, 540

local g = love.graphics

local function hash(x, y)
  local h = (x * 374761393 + y * 668265263) % 2147483647
  h = (h * 1274126177) % 2147483647
  return h / 2147483647
end

local function drawGround(world, camX, camY)
  local st = world.stage
  local pulse = world.beatPulse * 0.04
  g.clear(st.ground[1] + pulse, st.ground[2] + pulse, st.ground[3] + pulse)
  local cell = 96
  local x0, y0 = math.floor((camX - Render.VIEW_W / 2) / cell) - 1, math.floor((camY - Render.VIEW_H / 2) / cell) - 1
  local x1, y1 = x0 + math.ceil(Render.VIEW_W / cell) + 2, y0 + math.ceil(Render.VIEW_H / cell) + 2
  local d = st.detail
  for cx = x0, x1 do
    for cy = y0, y1 do
      local h = hash(cx, cy)
      local px, py = cx * cell + (h * 60), cy * cell + ((h * 7) % 1) * 60
      if h < 0.10 then
        if not Assets.drawSprite("decor_" .. world.stageId, px, py, 32) then
          g.setColor(d[1] + 0.08, d[2] + 0.08, d[3] + 0.08)
          g.rectangle("fill", px - 9, py - 14, 18, 24, 6, 6)
          g.setColor(d[1], d[2], d[3])
          g.rectangle("fill", px - 9, py + 8, 18, 4)
        end
      elseif h < 0.45 then
        g.setColor(d[1], d[2], d[3], 0.6)
        g.circle("fill", px, py, 2 + h * 6)
      end
    end
  end
end

local GEM_COLORS = { { 0.3, 0.6, 1.0 }, { 0.3, 1.0, 0.5 }, { 1.0, 0.3, 0.35 } }

local function drawGem(gm)
  local tier = gm.value >= 20 and 3 or (gm.value >= 5 and 2 or 1)
  local names = { "gem_small", "gem_medium", "gem_large" }
  local s = 4 + tier * 1.5
  if Assets.drawSprite(names[tier], gm.x, gm.y, s * 2.4) then return end
  local c = GEM_COLORS[tier]
  g.setColor(c[1], c[2], c[3])
  g.polygon("fill", gm.x, gm.y - s, gm.x + s * 0.7, gm.y, gm.x, gm.y + s, gm.x - s * 0.7, gm.y)
end

local PICKUP_DRAW = {
  brain = function(k)
    g.setColor(0.95, 0.55, 0.65); g.circle("fill", k.x - 3, k.y, 6); g.circle("fill", k.x + 3, k.y, 6)
    g.setColor(0.7, 0.3, 0.4); g.line(k.x, k.y - 5, k.x, k.y + 5)
  end,
  food = function(k)
    g.setColor(0.9, 0.6, 0.2); g.ellipse("fill", k.x, k.y, 10, 6)
    g.setColor(0.4, 0.8, 0.3); g.rectangle("fill", k.x - 8, k.y - 2, 16, 2)
  end,
  vinyl = function(k)
    g.setColor(0.08, 0.08, 0.1); g.circle("fill", k.x, k.y, 10)
    g.setColor(0.9, 0.3, 0.3); g.circle("fill", k.x, k.y, 3)
  end,
  chest = function(k)
    g.setColor(0.6, 0.4, 0.15); g.rectangle("fill", k.x - 14, k.y - 10, 28, 20, 3, 3)
    g.setColor(1, 0.85, 0.3); g.rectangle("fill", k.x - 3, k.y - 4, 6, 8)
  end,
}

local function drawEnemy(world, e, phase)
  local bob = (1 - phase) ^ 3 * 4
  local x, y = e.x, e.y - bob
  local face = e.faceX or 1
  if Assets.drawSprite("zombie_" .. e.type, x, y, e.r * 2.6, 0, face < 0) then
    if e.flash > 0 then
      g.setBlendMode("add"); Assets.drawSprite("zombie_" .. e.type, x, y, e.r * 2.6, 0, face < 0, 0.6); g.setBlendMode("alpha")
    end
  else
    local c = e.def.color
    if e.flash > 0 then g.setColor(1, 1, 1) else g.setColor(c[1], c[2], c[3]) end
    -- arms reaching for the player
    g.setLineWidth(math.max(2, e.r * 0.3))
    g.line(x, y - e.r * 0.2, x + face * e.r * 1.4, y - e.r * 0.4 + bob * 0.5)
    g.line(x, y + e.r * 0.2, x + face * e.r * 1.4, y + e.r * 0.1 + bob * 0.5)
    g.setLineWidth(1)
    g.circle("fill", x, y, e.r)
    g.setColor(0.9, 0.2, 0.15)
    g.circle("fill", x + face * e.r * 0.35, y - e.r * 0.25, math.max(1.5, e.r * 0.15))
  end
  if e.boss then
    g.setColor(0, 0, 0, 0.6); g.rectangle("fill", e.x - 30, e.y - e.r - 14, 60, 5)
    g.setColor(0.9, 0.2, 0.2); g.rectangle("fill", e.x - 30, e.y - e.r - 14, 60 * math.max(0, e.hp / e.maxHp), 5)
  end
end

local function drawPlayer(world)
  local p = world.player
  local c = world.character.color
  local rot, zombify = 0, 0
  if world.finished == "completed" then
    local t = world.endingT
    rot = math.min(1, math.max(0, (t - 1.0) / 0.6)) * (math.pi / 2)
    if t > 2.4 then rot = math.max(0, rot - (t - 2.4) / 0.6 * (math.pi / 2)) end
    zombify = math.min(1, math.max(0, (t - 1.6) / 1.0))
  elseif world.finished == "died" then
    rot = math.min(1, world.endingT / 0.5) * (math.pi / 2)
  end
  local scale = 1 + world.beatPulse * 0.12
  local r = p.r * scale
  local zc = { 0.45, 0.7, 0.35 }
  local col = { U.lerp(c[1], zc[1], zombify), U.lerp(c[2], zc[2], zombify), U.lerp(c[3], zc[3], zombify) }
  local blink = p.iframes > 0 and (math.floor(p.iframes * 30) % 2 == 0)
  local sprite = zombify > 0.5 and "player_zombie" or ("player_" .. world.characterId)
  g.push()
  g.translate(p.x, p.y)
  g.rotate(rot)
  if not (Assets.drawSprite(sprite, 0, 0, r * 2.8, 0, p.faceX < 0, blink and 0.4 or 1)
      or Assets.drawSprite("player", 0, 0, r * 2.8, 0, p.faceX < 0, blink and 0.4 or 1)) then
    if p.hurt > 0 then g.setColor(1, 0.3, 0.3) else g.setColor(col[1], col[2], col[3], blink and 0.5 or 1) end
    g.circle("fill", 0, 0, r)
    g.setColor(0.1, 0.1, 0.1)
    g.circle("fill", p.faceX * r * 0.45 - p.faceY * 3, p.faceY * r * 0.45 - 3, 2.5)
    g.circle("fill", p.faceX * r * 0.45 + p.faceY * 3, p.faceY * r * 0.45 + 1, 2.5)
    -- headphones, because of course
    g.setColor(0.15, 0.15, 0.2)
    g.setLineWidth(3)
    g.arc("line", "open", 0, 0, r + 2, math.pi * 1.1, math.pi * 1.9)
    g.setLineWidth(1)
  end
  g.pop()
end

function Render.draw(world)
  local p = world.player
  local sx, sy = world.fx:shakeOffset()
  local camX, camY = p.x, p.y
  local phase = world.conductor:beatPhase(world.music:time())

  g.push()
  g.translate(math.floor(Render.VIEW_W / 2 - camX + sx), math.floor(Render.VIEW_H / 2 - camY + sy))
  drawGround(world, camX, camY)

  if world.ruin then
    local r = world.ruin
    if not Assets.drawSprite("ruin", r.x, r.y, 80) then
      g.setColor(0.6, 0.55, 0.45)
      for i = -1, 1 do g.rectangle("fill", r.x + i * 22 - 6, r.y - 30 + math.abs(i) * 8, 12, 40 - math.abs(i) * 8) end
      g.rectangle("fill", r.x - 34, r.y + 10, 68, 8)
    end
  end

  for _, z in ipairs(world.zones) do
    local flick = 0.8 + math.random() * 0.2
    if not Assets.drawSprite("fx_fire", z.x, z.y, z.radius * 2, 0, false, 0.8) then
      g.setColor(z.color[1], z.color[2] * flick, z.color[3], 0.35)
      g.circle("fill", z.x, z.y, z.radius * flick)
      g.setColor(1, 0.8, 0.2, 0.3)
      g.circle("fill", z.x, z.y, z.radius * 0.5 * flick)
    end
  end

  for _, gm in ipairs(world.gems) do drawGem(gm) end
  for _, k in ipairs(world.pickups) do
    if not Assets.drawSprite("pickup_" .. k.kind, k.x, k.y, k.kind == "chest" and 32 or 20) then PICKUP_DRAW[k.kind](k) end
  end

  for _, e in ipairs(world.enemies) do drawEnemy(world, e, phase) end
  drawPlayer(world)

  for _, pr in ipairs(world.projectiles) do
    local c = pr.color
    g.setColor(c[1], c[2], c[3])
    if pr.kind == "bolt" then
      local dx, dy = U.norm(pr.vx, pr.vy)
      if not Assets.drawSprite("proj_bolt", pr.x, pr.y, pr.r * 5, math.atan2(dy, dx)) then
        g.setLineWidth(pr.r * 0.8)
        g.line(pr.x - dx * pr.r * 3, pr.y - dy * pr.r * 3, pr.x + dx * pr.r, pr.y + dy * pr.r)
        g.setLineWidth(1)
      end
    elseif not Assets.drawSprite("proj_" .. pr.kind, pr.x, pr.y, pr.r * 2.5) then
      g.circle("fill", pr.x, pr.y, pr.r)
    end
  end

  for _, l in ipairs(world.lobs) do
    local k = l.t / l.dur
    local x, y = U.lerp(l.x0, l.x1, k), U.lerp(l.y0, l.y1, k) - math.sin(k * math.pi) * 60
    if not Assets.drawSprite("proj_molotov", x, y, 14, k * 10) then
      g.setColor(0.4, 0.8, 0.4); g.rectangle("fill", x - 3, y - 6, 6, 12)
      g.setColor(1, 0.6, 0.2); g.circle("fill", x, y - 7, 3)
    end
  end

  world.fx:drawWorld(p)
  g.pop()
end

return Render
