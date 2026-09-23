-- Title screen. Plays the first stage's song (pad + drums) behind the menu.
local Gamestate = require("src.states.gamestate")
local Theme = require("src.ui.theme")
local Menu = require("src.ui.menu")
local Save = require("src.core.save")
local Songs = require("src.audio.songs")
local Music = require("src.audio.music")
local Conductor = require("src.core.conductor")

local Title = {}

function Title:enter()
  if not self.music then
    local song = Songs.load("graveyard_groove")
    self.music = Music.load(song)
    self.conductor = Conductor.new(song.bpm, song.stepsPerBeat, song.offset)
    self.music:setTrackActive("drums", true)
    for _, t in pairs(self.music.tracks) do t.current = t.target end
  end
  self.music:play()
  self.menu = Menu.new({
    { label = "Play", action = function() Gamestate.switch("select") end },
    { label = "Brain Shop", action = function() Gamestate.switch("shop") end, hint = "Spend rotting brains on permanent upgrades" },
    { label = "Achievements", action = function() Gamestate.switch("achievements") end },
    { label = "Options", action = function() Gamestate.switch("options", "title") end },
    { label = "Quit", action = function() love.event.quit() end },
  })
end

function Title:exit() self.music:stop() end

function Title:update(dt) self.music:update(dt) end

function Title:action(a) self.menu:action(a) end

function Title:draw()
  love.graphics.clear(Theme.bg)
  local phase = self.conductor:beatPhase(self.music:time())
  local pulse = (1 - phase) ^ 4
  Theme.title("DANCE ZOMBIES", 90, pulse)
  Theme.text_("Every shot lands on the beat. Kill 10,000. Then join them.", 0, 150, 15, Theme.dim, Theme.W, "center")
  self.menu:draw(0, 230, Theme.W)
  local st = Save.data.stats
  Theme.text_(("Best run: %d kills   Runs: %d"):format(st.bestKills, st.runs), 10, Theme.H - 30, 14, Theme.dim)
  Theme.brains(Save.data.brains)
end

return Title
