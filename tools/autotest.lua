-- Automated smoke test: a bot plays a run and reports what happened.
--   love . --autotest <seconds> [--kills N] [--stage id] [--character id] [--shots] [--menus]
-- Screenshots (with --shots) are written to the LÖVE save directory under autotest/.
local Gamestate = require("src.states.gamestate")
local Input = require("src.core.input")
local Save = require("src.core.save")
local U = require("src.core.util")
local Weapons = require("src.data.weapons")

local A = {}

local opts, elapsed, shotTimes, shotIndex, frames, minFps = nil, 0, {}, 1, 0, math.huge
local stepsSeen, firesSeen = 0, 0
local menuQueue

local function shot(name)
  love.filesystem.createDirectory("autotest")
  love.graphics.captureScreenshot("autotest/" .. name .. ".png")
  print("[autotest] screenshot autotest/" .. name .. ".png")
end

-- Kite: run away from the local crowd, with a slow orbit so we keep collecting gems.
local function botMove()
  local play = Gamestate.states.play
  local w = play.world
  if not w then return 0, 0 end
  local p = w.player
  local fx, fy = 0, 0
  for _, e in ipairs(w.enemies) do
    local dx, dy = p.x - e.x, p.y - e.y
    local d2 = dx * dx + dy * dy
    if d2 < 110 * 110 and d2 > 1 then fx, fy = fx + dx / d2, fy + dy / d2 end
  end
  local ox, oy = -math.sin(elapsed * 0.3), math.cos(elapsed * 0.3)
  local x, y = fx * 200 + ox * 0.3, fy * 200 + oy * 0.3
  -- drift towards the nearest gem when it is safe-ish
  local best, bd = nil, 350 * 350
  for _, g in ipairs(w.gems) do
    local d = U.dist2(g.x, g.y, p.x, p.y)
    if d < bd then best, bd = g, d end
  end
  if best then
    local gx, gy = U.norm(best.x - p.x, best.y - p.y)
    x, y = x + gx * 0.7, y + gy * 0.7
  end
  if w.ruin then
    local rx, ry = U.norm(w.ruin.x - p.x, w.ruin.y - p.y)
    x, y = x + rx * 0.5, y + ry * 0.5
  end
  return U.norm(x, y)
end

function A.start(o)
  opts = o
  A.speed = o.speed or 1
  Save.readonly = true
  Save.data.unlocked.weapon_molotov = true
  Save.data.unlocked.weapon_lightning_mic = true
  Input.override = botMove
  if o.menus then
    menuQueue = {
      { "title" }, { "select" }, { "shop" }, { "achievements" }, { "options", "title" },
    }
  end
  Gamestate.switch("play", { character = o.character or "roadie", stage = o.stage or "graveyard", mode = "normal" })
  local play = Gamestate.states.play
  play.autoEnd = false
  if o.kills then play.world.kills = o.kills; play.world.spawner.nextBoss = (math.floor(o.kills / 1000) + 1) * 1000 end
  local t = o.autotest
  shotTimes = { 3, t * 0.5, t - 0.5 }
  local steps = 0
  local orig = play.world.onStep
  play.world.onStep = function(self, step)
    stepsSeen = stepsSeen + 1
    return orig(self, step)
  end
end

A.speed = 1

function A.update(dt)
  elapsed = elapsed + dt
  frames = frames + 1
  if elapsed > 2 then minFps = math.min(minFps, love.timer.getFPS()) end
  local play = Gamestate.states.play
  if Gamestate.currentName == "play" and play.overlay == "levelup" and opts.shots and not A.levelShot then
    A.levelShot = true
    shot("levelup")
  elseif Gamestate.currentName == "play" and play.overlay == "levelup" then
    -- prefer evolutions, then new weapons, then whatever is first
    local best = 1
    for i, c in ipairs(play.choices) do
      if c.type == "evolve" then best = i break end
      if c.type == "weapon_new" and play.choices[best].type ~= "weapon_new" then best = i end
    end
    play.choiceIndex = best
    play:action("confirm")
  end
  if shotIndex <= #shotTimes and elapsed >= shotTimes[shotIndex] and opts.shots then
    shot(("play_%02d"):format(shotIndex))
    shotIndex = shotIndex + 1
  end
  if elapsed >= opts.autotest and not A.done then
    A.done = true
    local w = play.world
    print("[autotest] ---- report ----")
    print(("[autotest] time %.1fs  kills %d  level %d  hp %.0f/%d  finished=%s")
      :format(w.time, w.kills, w.level, w.player.hp, w.stats.maxHp, tostring(w.finished)))
    print(("[autotest] song clock %.2fs (%s)  steps processed %d  enemies %d  min fps %d")
      :format(w.music:time(), w.music.silent and "silent" or "audio", stepsSeen, #w.enemies, minFps))
    local names = {}
    for _, wp in ipairs(w.weapons) do names[#names + 1] = Weapons[wp.id].name .. " L" .. wp.level end
    print("[autotest] weapons: " .. table.concat(names, ", "))
    local ps = {}
    for id, l in pairs(w.passives) do ps[#ps + 1] = id .. " " .. l end
    print("[autotest] passives: " .. table.concat(ps, ", "))
    local active = {}
    for name, t in pairs(w.music.tracks) do if t.target > 0 then active[#active + 1] = name end end
    table.sort(active)
    print("[autotest] audible tracks: " .. table.concat(active, ", "))
    if menuQueue then A.menuIndex, A.menuT = 1, 0 else A.quitT = 0.3 end
  end
  if A.menuIndex then
    A.menuT = A.menuT + dt
    if A.menuT > 0.4 then
      local m = menuQueue[A.menuIndex]
      if not m then A.menuIndex = nil; A.quitT = 0.3; return end
      if A.shotPending then shot("menu_" .. A.shotPending); A.shotPending = nil; A.menuIndex = A.menuIndex + 1
      else Gamestate.switch(m[1], m[2]); A.shotPending = m[1] end
      A.menuT = 0
    end
  end
  if A.quitT then
    A.quitT = A.quitT - dt
    if A.quitT <= 0 then love.event.quit() end
  end
end

function A.draw() end

return A
