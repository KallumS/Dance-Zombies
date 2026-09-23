-- Volume, audio latency offset (with a tap-to-calibrate tool), fullscreen, reset.
local Gamestate = require("src.states.gamestate")
local Theme = require("src.ui.theme")
local Menu = require("src.ui.menu")
local Save = require("src.core.save")
local U = require("src.core.util")

local Options = {}

function Options:enter(back)
  self.back = back or "title"
  self.confirmReset = false
  local s = Save.data.settings
  local function vol(key, d) s[key] = U.clamp(math.floor((s[key] + d) * 10 + 0.5) / 10, 0, 1) end
  self.menu = Menu.new({
    { label = function() return ("Music volume: %d%%"):format(s.musicVolume * 100) end,
      left = function() vol("musicVolume", -0.1) end, right = function() vol("musicVolume", 0.1) end },
    { label = function() return ("Effects volume: %d%%"):format(s.sfxVolume * 100) end,
      left = function() vol("sfxVolume", -0.1) end, right = function() vol("sfxVolume", 0.1) end },
    { label = function() return ("Audio offset: %+d ms"):format(s.audioOffsetMs) end,
      left = function() s.audioOffsetMs = s.audioOffsetMs - 5 end,
      right = function() s.audioOffsetMs = s.audioOffsetMs + 5 end,
      hint = "Raise this if attacks feel early compared to the music" },
    { label = "Calibrate offset (tap along)", action = function() Gamestate.switch("calibrate", self.back) end },
    { label = function() return "Fullscreen: " .. (s.fullscreen and "on" or "off") end,
      action = function() s.fullscreen = not s.fullscreen; love.window.setFullscreen(s.fullscreen) end },
    { label = function() return self.confirmReset and "Really erase all progress? (confirm)" or "Reset progress" end,
      action = function()
        if self.confirmReset then Save.reset(); self.confirmReset = false else self.confirmReset = true end
      end },
    { label = "Back", action = function() self:leave() end },
  })
end

function Options:leave()
  Save.write()
  Gamestate.switch(self.back)
end

function Options:action(a)
  if a == "back" then self:leave() return end
  if a ~= "confirm" then self.confirmReset = false end
  self.menu:action(a)
end

function Options:draw()
  love.graphics.clear(Theme.bg)
  Theme.text_("OPTIONS", 0, 40, 30, Theme.accent, Theme.W, "center")
  self.menu:draw(0, 120, Theme.W)
end

return Options
