-- Dance Zombies - entry point.
-- Renders to a fixed 960x540 virtual screen, letterboxed to the window.
--
-- Command line (for development / CI):
--   love .                          play normally
--   love . --autotest 60            bot plays 60s of Graveyard, prints a report, quits
--   love . --autotest 30 --kills 9990 --shots
--                                   start near the win condition and save screenshots
--   love . --autotest 600 --speed 8 fast-forward (fixed 1/60 steps, 8 per frame)
local Gamestate = require("src.states.gamestate")
local Input = require("src.core.input")
local Save = require("src.core.save")

local VW, VH = 960, 540
local view = { scale = 1, ox = 0, oy = 0 }

local function updateView()
  local w, h = love.graphics.getDimensions()
  view.scale = math.min(w / VW, h / VH)
  view.ox = math.floor((w - VW * view.scale) / 2)
  view.oy = math.floor((h - VH * view.scale) / 2)
end

local autotest

local function parseArgs(args)
  local opts = {}
  local i = 1
  while i <= #args do
    local a = args[i]
    if a == "--autotest" then opts.autotest = tonumber(args[i + 1]) or 30; i = i + 1
    elseif a == "--kills" then opts.kills = tonumber(args[i + 1]); i = i + 1
    elseif a == "--stage" then opts.stage = args[i + 1]; i = i + 1
    elseif a == "--character" then opts.character = args[i + 1]; i = i + 1
    elseif a == "--speed" then opts.speed = tonumber(args[i + 1]); i = i + 1
    elseif a == "--shots" then opts.shots = true
    elseif a == "--menus" then opts.menus = true end
    i = i + 1
  end
  return opts
end

function love.load(args)
  love.graphics.setDefaultFilter("nearest", "nearest")
  math.randomseed(os.time())
  Save.load()
  if Save.data.settings.fullscreen then love.window.setFullscreen(true) end
  updateView()

  for _, name in ipairs({ "title", "select", "shop", "achievements", "options", "calibrate", "play", "results" }) do
    Gamestate.register(name, require("src.states." .. name))
  end

  local opts = parseArgs(args or {})
  if opts.autotest then
    autotest = require("tools.autotest")
    autotest.start(opts)
  else
    Gamestate.switch("title")
  end
end

function love.resize() updateView() end

function love.update(dt)
  if autotest then
    -- fixed-step fast-forward for headless testing (only meaningful without an audio device)
    for _ = 1, autotest.speed do
      Gamestate.update(1 / 60)
      autotest.update(1 / 60)
    end
    return
  end
  Gamestate.update(dt)
end

function love.draw()
  love.graphics.push()
  love.graphics.translate(view.ox, view.oy)
  love.graphics.scale(view.scale)
  love.graphics.setScissor(view.ox, view.oy, VW * view.scale, VH * view.scale)
  Gamestate.draw()
  love.graphics.setScissor()
  love.graphics.pop()
  if autotest then autotest.draw() end
end

function love.keypressed(key)
  if key == "f11" then
    local fs = not love.window.getFullscreen()
    love.window.setFullscreen(fs)
    Save.data.settings.fullscreen = fs
    updateView()
    return
  end
  Gamestate.keypressed(key)
  local action = Input.fromKey(key)
  if action then Gamestate.action(action) end
end

function love.gamepadpressed(_, button)
  local action = Input.fromButton(button)
  if action then Gamestate.action(action) end
end

-- Left stick flicks navigate menus too.
local stickHeld = false
function love.gamepadaxis(_, axis, value)
  if axis ~= "lefty" and axis ~= "leftx" then return end
  if math.abs(value) < 0.6 then stickHeld = false return end
  if stickHeld then return end
  stickHeld = true
  if axis == "lefty" then Gamestate.action(value < 0 and "up" or "down")
  else Gamestate.action(value < 0 and "left" or "right") end
end

function love.quit()
  Save.write()
end
