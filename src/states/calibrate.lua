-- Tap along to a click track; the average error becomes the audio offset setting.
-- This compensates for audio output latency (Bluetooth headphones can add 100ms+).
local Gamestate = require("src.states.gamestate")
local Theme = require("src.ui.theme")
local Save = require("src.core.save")
local Synth = require("src.audio.synth")
local Settings = require("src.core.settings")

local Calibrate = {}

local BPM = 100
local TAPS = 12

function Calibrate:enter(back)
  self.back = back or "options"
  local beat = 60 / BPM
  local n = math.floor(beat * Synth.RATE)
  local click, cn = Synth.click(1200)
  local buf = {}
  for i = 1, n do buf[i] = click[i] or 0 end
  self.source = love.audio.newSource(Synth.toSoundData(buf, n), "static")
  self.source:setLooping(true)
  self.source:setVolume(Settings.get("sfxVolume") or 1)
  self.source:play()
  self.clock, self.lastRaw, self.loops = 0, 0, 0
  self.errors = {}
  self.result = nil
end

function Calibrate:exit() self.source:stop() end

function Calibrate:update(dt)
  local beat = 60 / BPM
  local raw = self.source:tell("seconds")
  if raw < self.lastRaw - beat / 2 then self.loops = self.loops + 1 end
  self.lastRaw = raw
  local pos = self.loops * beat + raw
  local predicted = self.clock + dt
  self.clock = math.abs(pos - predicted) > 0.1 and pos or predicted + (pos - predicted) * 0.1
end

function Calibrate:action(a)
  if a == "back" then Gamestate.switch("options", self.back) return end
  if a == "confirm" then
    if self.result then
      Save.data.settings.audioOffsetMs = self.result
      Save.write()
      Gamestate.switch("options", self.back)
      return
    end
    local beat = 60 / BPM
    local phase = self.clock / beat
    local err = (phase - math.floor(phase + 0.5)) * beat -- seconds late (+) or early (-)
    self.errors[#self.errors + 1] = err
    if #self.errors >= TAPS then
      table.sort(self.errors)
      local sum, cnt = 0, 0
      for i = 3, #self.errors - 2 do sum = sum + self.errors[i]; cnt = cnt + 1 end -- drop outliers
      self.result = math.floor(sum / cnt * 1000 + 0.5)
    end
  end
end

function Calibrate:draw()
  love.graphics.clear(Theme.bg)
  Theme.text_("CALIBRATE", 0, 40, 30, Theme.accent, Theme.W, "center")
  local beat = 60 / BPM
  local phase = (self.clock / beat) % 1
  love.graphics.setColor(1, 1, 1, 0.2 + 0.8 * (1 - phase) ^ 4)
  love.graphics.circle("fill", Theme.W / 2, 240, 30 + 20 * (1 - phase) ^ 4)
  if self.result then
    Theme.text_(("Measured offset: %+d ms"):format(self.result), 0, 330, 20, Theme.text, Theme.W, "center")
    Theme.text_("Enter to save, Esc to cancel", 0, 370, 14, Theme.dim, Theme.W, "center")
  else
    Theme.text_("Listen to the clicks and press Enter / Space / A exactly on each one.", 0, 330, 15, Theme.text, Theme.W, "center")
    Theme.text_(("%d / %d taps"):format(#self.errors, TAPS), 0, 360, 14, Theme.dim, Theme.W, "center")
  end
end

return Calibrate
