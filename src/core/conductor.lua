-- The Conductor turns "song time" (seconds) into musical steps.
--
-- It is fed a monotonic time each frame (see audio/music.lua for how that time is
-- derived from the playing audio) and reports which steps were crossed since the last
-- frame, so weapons can fire exactly on the grid even if a frame is long.
--
-- Pure Lua (no LÖVE) so it can be unit tested.
local Conductor = {}
Conductor.__index = Conductor

-- Never fire more than this many steps in one frame (e.g. after a window drag stall).
Conductor.MAX_CATCHUP = 4

function Conductor.new(bpm, stepsPerBeat, offset)
  assert(bpm and bpm > 0, "bpm required")
  return setmetatable({
    bpm = bpm,
    stepsPerBeat = stepsPerBeat or 4,
    offset = offset or 0,     -- seconds before beat 1 in the audio file
    userOffset = 0,           -- latency calibration from settings (seconds)
    time = 0,
    lastStep = -1,
  }, Conductor)
end

function Conductor:secondsPerBeat() return 60 / self.bpm end
function Conductor:secondsPerStep() return 60 / self.bpm / self.stepsPerBeat end

function Conductor:localTime(t)
  return (t or self.time) - self.offset - self.userOffset
end

function Conductor:stepAt(t)
  return math.floor(self:localTime(t) / self:secondsPerStep())
end

-- Beats elapsed as a float (negative before the first beat).
function Conductor:beat(t)
  return self:localTime(t) / self:secondsPerBeat()
end

-- 0 at the start of a beat rising to 1 just before the next one. Handy for visual pulses.
function Conductor:beatPhase(t)
  local b = self:beat(t)
  return b - math.floor(b)
end

-- Advance to time `t`. Returns firstStep, lastStep of the steps crossed, or nil if none.
function Conductor:advance(t)
  self.time = t
  local s = self:stepAt(t)
  local first = self.lastStep + 1
  if s < first then return nil end
  if s - first >= Conductor.MAX_CATCHUP then first = s - Conductor.MAX_CATCHUP + 1 end
  self.lastStep = s
  return first, s
end

return Conductor
