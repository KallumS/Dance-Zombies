-- The in-run state: runs the World, and layers the level-up, pause and ending screens on top.
local Gamestate = require("src.states.gamestate")
local Theme = require("src.ui.theme")
local Menu = require("src.ui.menu")
local World = require("src.game.world")
local Render = require("src.game.render")
local Hud = require("src.ui.hud")
local LevelUp = require("src.game.levelup")
local Progress = require("src.game.progress")
local Synth = require("src.audio.synth")
local Weapons = require("src.data.weapons")
local Passives = require("src.data.passives")
local Save = require("src.core.save")
local U = require("src.core.util")

local Play = {}

local ENDING_WAIT = { completed = 4.5, died = 2.0 }

function Play:enter(opts)
  self.opts = opts
  self.world = World.new(opts)
  self.overlay = nil
  self.debug = Save.data.settings.showBeatGrid
  self.metronome = false
  self.lastBeat = nil
  if not self.click then
    local ok, sd = pcall(function() return Synth.toSoundData(Synth.click(1800)) end)
    if ok then self.click = love.audio.newSource(sd, "static") end
  end
end

function Play:exit()
  if self.world then self.world:destroy() end
end

function Play:openLevelUp()
  self.overlay = "levelup"
  self.choices = self.world:rollChoices()
  self.choiceIndex = 1
end

function Play:openPause()
  self.overlay = "pause"
  self.world.music:pause()
  self.pauseMenu = Menu.new({
    { label = "Resume", action = function() self:closePause() end },
    { label = "Give up (keep brains)", action = function() self:endRun() end },
  })
end

function Play:closePause()
  self.overlay = nil
  self.world.music:resume()
end

function Play:endRun()
  local summary = self.world:runSummary()
  local result = Progress.finishRun(summary)
  Gamestate.switch("results", summary, result, self.opts)
end

function Play:update(dt)
  local w = self.world
  if self.overlay == "pause" then return end
  if self.overlay == "levelup" then
    w:updatePaused(dt)
    return
  end
  w:update(dt)

  if self.metronome and self.click then
    local beat = math.floor(w.conductor.lastStep / w.song.stepsPerBeat)
    if beat ~= self.lastBeat then self.lastBeat = beat; self.click:stop(); self.click:play() end
  end

  if w.finished then
    if self.autoEnd and w.endingT > ENDING_WAIT[w.finished] then self:endRun() end
    return
  end
  if w.pendingLevelUps > 0 then self:openLevelUp() end
end

function Play:action(a)
  local w = self.world
  if self.overlay == "levelup" then
    if a == "up" or a == "left" then self.choiceIndex = (self.choiceIndex - 2) % #self.choices + 1
    elseif a == "down" or a == "right" then self.choiceIndex = self.choiceIndex % #self.choices + 1
    elseif a == "confirm" then
      w:applyChoice(self.choices[self.choiceIndex])
      if w.pendingLevelUps > 0 then self:openLevelUp() else self.overlay = nil end
    end
    return
  end
  if self.overlay == "pause" then
    if a == "back" or a == "pause" then self:closePause() else self.pauseMenu:action(a) end
    return
  end
  if w.finished then
    if a == "confirm" and w.endingT > ENDING_WAIT[w.finished] then self:endRun() end
    return
  end
  if a == "pause" or a == "back" then self:openPause()
  elseif a == "debug" then self.debug = not self.debug end
end

-- Developer keys (only while the debug overlay is visible). Documented in docs/GUIDE.md.
function Play:keypressed(key)
  local w = self.world
  if key == "f2" then self.metronome = not self.metronome end
  if key == "[" then w.conductor.userOffset = w.conductor.userOffset - 0.005 end
  if key == "]" then w.conductor.userOffset = w.conductor.userOffset + 0.005 end
  if not self.debug or w.finished then return end
  if key == "f3" then w.kills = w.kills + 1000; if w.kills >= 10000 then w:finish("completed") end end
  if key == "f4" then w:gainXp(w.xpNeed) end
  if key == "f5" then w.player.hp = w.stats.maxHp end
end

local function drawLevelUp(self)
  local g = love.graphics
  g.setColor(0, 0, 0, 0.6)
  g.rectangle("fill", 0, 0, Theme.W, Theme.H)
  Theme.text_("LEVEL UP!", 0, 90, 30, Theme.accent, Theme.W, "center")
  Theme.text_("New weapons add their instrument to the song.", 0, 128, 13, Theme.dim, Theme.W, "center")
  local cardW, cardH = 560, 62
  for i, opt in ipairs(self.choices) do
    local title, desc = LevelUp.describe(opt)
    local x, y = Theme.W / 2 - cardW / 2, 160 + (i - 1) * (cardH + 12)
    local sel = i == self.choiceIndex
    local def = Weapons[opt.into or opt.id] or Passives[opt.id]
    local c = def and def.color or Theme.accent
    g.setColor(0.08, 0.1, 0.08, 0.95)
    g.rectangle("fill", x, y, cardW, cardH, 6, 6)
    g.setColor(c[1], c[2], c[3], sel and 1 or 0.35)
    g.setLineWidth(sel and 3 or 1)
    g.rectangle("line", x, y, cardW, cardH, 6, 6)
    g.setLineWidth(1)
    g.rectangle("fill", x + 12, y + 14, 34, 34, 4, 4)
    Theme.text_(title, x + 60, y + 10, 17, opt.type == "evolve" and { 1, 0.9, 0.3 } or Theme.text)
    Theme.text_(desc, x + 60, y + 34, 13, Theme.dim, cardW - 72)
  end
end

local function drawEnding(self)
  local w = self.world
  local t = w.endingT
  local g = love.graphics
  if w.finished == "completed" then
    g.setColor(0.2, 0.45, 0.15, U.clamp((t - 1.5) / 2, 0, 0.45))
    g.rectangle("fill", 0, 0, Theme.W, Theme.H)
    if t > 0.5 then Theme.text_("10,000 ZOMBIES DOWN", 0, 120, 34, Theme.text, Theme.W, "center") end
    if t > 2.8 then
      Theme.text_("...but the beat got into your brain.", 0, 170, 18, Theme.text, Theme.W, "center")
      Theme.text_("You died, and rose again as one of them.", 0, 196, 18, Theme.accent, Theme.W, "center")
    end
  else
    g.setColor(0.4, 0, 0, U.clamp(t / 1.5, 0, 0.5))
    g.rectangle("fill", 0, 0, Theme.W, Theme.H)
    Theme.text_("YOU WERE DEVOURED", 0, 150, 34, Theme.warn, Theme.W, "center")
  end
  if t > ENDING_WAIT[w.finished] then
    Theme.text_("Press Enter / A to continue", 0, 380, 15, Theme.dim, Theme.W, "center")
  end
end

function Play:draw()
  Render.draw(self.world)
  Hud.draw(self.world, self.debug)
  if self.world.finished then drawEnding(self) end
  if self.overlay == "levelup" then drawLevelUp(self)
  elseif self.overlay == "pause" then
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, Theme.W, Theme.H)
    Theme.text_("PAUSED", 0, 150, 30, Theme.accent, Theme.W, "center")
    self.pauseMenu:draw(0, 220, Theme.W)
  end
end

return Play
