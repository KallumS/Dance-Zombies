-- Short-lived visual effects: damage numbers, gore particles, shockwave rings, lightning,
-- slashes, screen shake and toast messages. Purely cosmetic.
local U = require("src.core.util")
local Assets = require("src.core.assets")

local Fx = {}
Fx.__index = Fx

local MAX_NUMBERS, MAX_PARTICLES = 120, 400

function Fx.new()
  return setmetatable({ numbers = {}, particles = {}, rings = {}, bolts = {}, slashes = {}, toasts = {}, shake = 0 }, Fx)
end

function Fx:number(x, y, value, color)
  if #self.numbers >= MAX_NUMBERS then table.remove(self.numbers, 1) end
  self.numbers[#self.numbers + 1] = { x = x + math.random(-6, 6), y = y, v = math.floor(value + 0.5), t = 0.6, color = color }
end

function Fx:splat(x, y, color, n)
  for _ = 1, n or 6 do
    if #self.particles >= MAX_PARTICLES then break end
    local a, s = math.random() * math.pi * 2, 40 + math.random() * 140
    self.particles[#self.particles + 1] = {
      x = x, y = y, vx = math.cos(a) * s, vy = math.sin(a) * s, t = 0.35 + math.random() * 0.3,
      size = 2 + math.random() * 3, color = color,
    }
  end
end

function Fx:ring(x, y, radius, color, follow)
  self.rings[#self.rings + 1] = { x = x, y = y, r = radius, t = 0, dur = 0.3, color = color, follow = follow }
end

function Fx:bolt(points, color)
  self.bolts[#self.bolts + 1] = { points = points, t = 0.18, color = color }
end

function Fx:slash(x, y, w, h, dir, color)
  self.slashes[#self.slashes + 1] = { x = x, y = y, w = w, h = h, dir = dir, t = 0.14, color = color }
end

function Fx:toast(text, color)
  self.toasts[#self.toasts + 1] = { text = text, t = 3.0, color = color or { 1, 1, 1 } }
  if #self.toasts > 4 then table.remove(self.toasts, 1) end
end

function Fx:addShake(amount) self.shake = math.max(self.shake, amount) end

function Fx:update(dt)
  for _, n in ipairs(self.numbers) do n.t = n.t - dt; n.y = n.y - 30 * dt end
  for _, p in ipairs(self.particles) do
    p.t = p.t - dt; p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
    p.vx = p.vx * (1 - 4 * dt); p.vy = p.vy * (1 - 4 * dt)
  end
  for _, r in ipairs(self.rings) do r.t = r.t + dt end
  for _, b in ipairs(self.bolts) do b.t = b.t - dt end
  for _, s in ipairs(self.slashes) do s.t = s.t - dt end
  for _, t in ipairs(self.toasts) do t.t = t.t - dt end
  U.sweep(self.numbers, function(n) return n.t <= 0 end)
  U.sweep(self.particles, function(p) return p.t <= 0 end)
  U.sweep(self.rings, function(r) return r.t >= r.dur end)
  U.sweep(self.bolts, function(b) return b.t <= 0 end)
  U.sweep(self.slashes, function(s) return s.t <= 0 end)
  for i = #self.toasts, 1, -1 do if self.toasts[i].t <= 0 then table.remove(self.toasts, i) end end
  self.shake = math.max(0, self.shake - dt * 30)
end

function Fx:shakeOffset()
  if self.shake <= 0 then return 0, 0 end
  return (math.random() * 2 - 1) * self.shake, (math.random() * 2 - 1) * self.shake
end

-- World-space effects (drawn under the camera transform).
function Fx:drawWorld(player)
  local g = love.graphics
  for _, p in ipairs(self.particles) do
    local c = p.color
    g.setColor(c[1], c[2], c[3], math.min(1, p.t * 3))
    g.rectangle("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
  end
  for _, r in ipairs(self.rings) do
    local k = r.t / r.dur
    local x, y = r.x, r.y
    if r.follow then x, y = player.x, player.y end
    g.setColor(r.color[1], r.color[2], r.color[3], 0.7 * (1 - k))
    g.setLineWidth(6 * (1 - k) + 1)
    g.circle("line", x, y, r.r * (0.3 + 0.7 * k))
  end
  for _, s in ipairs(self.slashes) do
    local a = s.t / 0.14
    g.setColor(s.color[1], s.color[2], s.color[3], 0.8 * a)
    if not Assets.drawSprite("fx_slash", s.x, s.y, s.w, 0, s.dir < 0, 0.8 * a) then
      g.ellipse("fill", s.x, s.y, s.w / 2, s.h / 2 * a)
    end
  end
  g.setLineWidth(2)
  for _, b in ipairs(self.bolts) do
    g.setColor(b.color[1], b.color[2], b.color[3], b.t / 0.18)
    if #b.points >= 4 then g.line(b.points) end
  end
  g.setLineWidth(1)
  local font = Assets.font(12)
  g.setFont(font)
  for _, n in ipairs(self.numbers) do
    local c = n.color or { 1, 1, 1 }
    g.setColor(c[1], c[2], c[3], math.min(1, n.t * 3))
    g.print(n.v, n.x - 6, n.y)
  end
end

return Fx
