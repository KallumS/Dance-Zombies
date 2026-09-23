-- In-run HUD: health, XP, kill counter, brains, loadout and the rhythm lanes that show
-- exactly which steps of the current bar each weapon will fire on.
local Assets = require("src.core.assets")
local Pattern = require("src.core.pattern")
local Weapons = require("src.data.weapons")
local Passives = require("src.data.passives")
local Stages = require("src.data.stages")
local U = require("src.core.util")

local Hud = {}
local g = love.graphics

local W, H = 960, 540

local function bar(x, y, w, h, frac, fg, bg)
  g.setColor(bg or { 0, 0, 0, 0.6 })
  g.rectangle("fill", x, y, w, h, 2, 2)
  g.setColor(fg)
  g.rectangle("fill", x, y, w * U.clamp(frac, 0, 1), h, 2, 2)
end

local function drawLanes(world)
  local song, cond = world.song, world.conductor
  local spb = song.stepsPerBeat
  local stepsPerBar = spb * 4
  local cellW, rowH = 12, 11
  local lanesW = stepsPerBar * cellW
  local x0 = W / 2 - lanesW / 2
  local y0 = H - 16 - #world.weapons * rowH
  local t = world.music:time()
  local stepF = cond:localTime(t) / cond:secondsPerStep()
  local barStart = math.floor(stepF / stepsPerBar) * stepsPerBar

  g.setColor(0, 0, 0, 0.75)
  g.rectangle("fill", x0 - 70, y0 - 4, lanesW + 76, #world.weapons * rowH + 8, 4, 4)
  g.setFont(Assets.font(10))
  for i, w in ipairs(world.weapons) do
    local def = Weapons[w.id]
    local pattern = song.patterns[def.track] or song.patterns.drums
    local level = def.evolved and Pattern.EVOLVED_LEVEL or w.level
    local y = y0 + (i - 1) * rowH
    g.setColor(def.color[1], def.color[2], def.color[3], 0.9)
    g.print(def.track, x0 - 64, y - 1)
    for s = 0, stepsPerBar - 1 do
      local need = Pattern.at(pattern, barStart + s)
      local x = x0 + s * cellW
      if s % spb == 0 then g.setColor(1, 1, 1, 0.08); g.rectangle("fill", x, y, cellW - 1, rowH - 1) end
      if need > 0 then
        if level >= need then g.setColor(def.color[1], def.color[2], def.color[3], 0.95)
        else g.setColor(1, 1, 1, 0.15) end
        g.rectangle("fill", x + 2, y + 2, cellW - 5, rowH - 5, 2, 2)
      end
    end
  end
  local px = x0 + (stepF - barStart) * cellW
  g.setColor(1, 1, 1, 0.9)
  g.rectangle("fill", px, y0 - 3, 2, #world.weapons * rowH + 6)

  -- big beat light
  local phase = cond:beatPhase(t)
  g.setColor(1, 1, 1, 0.15 + 0.7 * (1 - phase) ^ 3)
  g.circle("fill", x0 - 82, y0 + #world.weapons * rowH / 2, 7 + 3 * (1 - phase) ^ 3)
end

local function drawLoadout(world)
  local x, y = 10, 52
  for _, w in ipairs(world.weapons) do
    local def = Weapons[w.id]
    local c = def.color
    local grow = (w.pulse or 0) * 3
    if not Assets.drawSprite("icon_" .. w.id, x + 11, y + 11, 22 + grow) then
      g.setColor(c[1], c[2], c[3])
      g.rectangle("fill", x - grow / 2, y - grow / 2, 22 + grow, 22 + grow, 4, 4)
    end
    g.setColor(0, 0, 0)
    g.setFont(Assets.font(10))
    g.print(def.evolved and "EVO" or tostring(w.level), x + 3, y + 6)
    x = x + 26
  end
  x, y = 10, 78
  for _, id in ipairs(Passives.POOL) do
    local lvl = world.passives[id]
    if lvl then
      local c = Passives[id].color
      if not Assets.drawSprite("icon_" .. id, x + 9, y + 9, 18) then
        g.setColor(c[1], c[2], c[3], 0.9)
        g.circle("fill", x + 9, y + 9, 9)
      end
      g.setColor(0, 0, 0)
      g.print(tostring(lvl), x + 6, y + 3)
      x = x + 22
    end
  end
end

local function drawRuinArrow(world)
  local r = world.ruin
  if not r then return end
  local p = world.player
  local dx, dy = r.x - p.x, r.y - p.y
  if math.abs(dx) < W / 2 - 20 and math.abs(dy) < H / 2 - 20 then return end
  local a = math.atan2(dy, dx)
  local ex = U.clamp(W / 2 + math.cos(a) * 1000, 24, W - 24)
  local ey = U.clamp(H / 2 + math.sin(a) * 1000, 24, H - 24)
  g.setColor(1, 0.85, 0.5, 0.9)
  g.push(); g.translate(ex, ey); g.rotate(a)
  g.polygon("fill", 10, 0, -6, -7, -6, 7)
  g.pop()
end

function Hud.draw(world, debug)
  local p = world.player
  -- XP bar across the top
  bar(0, 0, W, 8, world.xp / world.xpNeed, { 0.35, 0.65, 1.0 }, { 0, 0, 0, 0.7 })
  g.setFont(Assets.font(12))
  g.setColor(1, 1, 1)
  g.printf("LV " .. world.level, W - 70, 10, 60, "right")

  -- health + brains
  bar(10, 14, 180, 12, p.hp / world.stats.maxHp, { 0.85, 0.2, 0.25 })
  g.setColor(1, 1, 1)
  g.print(("%d / %d"):format(math.ceil(p.hp), world.stats.maxHp), 14, 13)
  g.setColor(0.95, 0.6, 0.7)
  g.print(("Brains: %d"):format(world.brains), 10, 30)

  -- kill counter (the win condition) + timer
  g.setFont(Assets.font(22))
  g.setColor(1, 1, 1)
  g.printf(U.formatInt(world.kills) .. " / " .. U.formatInt(Stages.KILLS_TO_WIN), 0, 12, W, "center")
  g.setFont(Assets.font(12))
  g.setColor(1, 1, 1, 0.7)
  g.printf(("%02d:%02d   %s - %s"):format(math.floor(world.time / 60), math.floor(world.time % 60), world.song.title, world.song.artist or ""), 0, 38, W, "center")

  drawLoadout(world)
  drawLanes(world)
  drawRuinArrow(world)

  -- toasts
  g.setFont(Assets.font(16))
  for i, t in ipairs(world.fx.toasts) do
    local c = t.color
    g.setColor(c[1], c[2], c[3], math.min(1, t.t))
    g.printf(t.text, 0, 70 + i * 22, W, "center")
  end

  if debug then
    local m = world.music
    g.setFont(Assets.font(12))
    g.setColor(0, 0, 0, 0.7)
    g.rectangle("fill", W - 250, 30, 240, 110)
    g.setColor(0.6, 1, 0.6)
    g.print(table.concat({
      ("FPS %d   enemies %d"):format(love.timer.getFPS(), #world.enemies),
      ("song %.3fs  step %d"):format(m:time(), world.conductor.lastStep),
      ("bpm %d  offset %+dms"):format(world.song.bpm, math.floor(world.conductor.userOffset * 1000 + 0.5)),
      ("loop %.2fs  %s"):format(m.length, m.silent and "SILENT CLOCK" or "audio clock"),
      ("projectiles %d  gems %d"):format(#world.projectiles, #world.gems),
      "F2 metronome click  [ ] offset",
    }, "\n"), W - 244, 34)
  end
end

return Hud
