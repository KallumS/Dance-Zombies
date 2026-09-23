-- Placeholder music generator.
--
-- When a song's stem has no audio file, we synthesise one from the *same* rhythm
-- pattern the weapons fire on, so the placeholder audio is always perfectly in time
-- with the attacks. Replace these by dropping real .ogg/.wav stems next to song.lua
-- (see docs/GUIDE.md).
--
-- The DSP is deliberately simple: enveloped oscillators and noise written into a
-- Lua array, then copied into a SoundData. Pure Lua except `Synth.toSoundData`.
local Pattern = require("src.core.pattern")

local Synth = {}

Synth.RATE = 22050

local TAU = math.pi * 2
local sin, floor, exp, abs = math.sin, math.floor, math.exp, math.abs

local NOTE = { C = -9, ["C#"] = -8, Db = -8, D = -7, ["D#"] = -6, Eb = -6, E = -5, F = -4,
  ["F#"] = -3, Gb = -3, G = -2, ["G#"] = -1, Ab = -1, A = 0, ["A#"] = 1, Bb = 1, B = 2 }

-- "Am" -> { root = semitones from A4, minor = true }
function Synth.parseChord(name)
  local root, rest = name:match("^([A-G][#b]?)(.*)$")
  assert(root and NOTE[root], "bad chord " .. tostring(name))
  return { root = NOTE[root], minor = rest:sub(1, 1) == "m" }
end

local function freq(semisFromA4) return 440 * 2 ^ (semisFromA4 / 12) end

-- Deterministic noise so placeholder songs sound identical every run.
local seed = 12345
local function noise()
  seed = (seed * 1103515245 + 12345) % 2147483648
  return seed / 1073741824 - 1
end

local function saw(ph) return 2 * (ph - floor(ph + 0.5)) end
local function square(ph) return (ph - floor(ph)) < 0.5 and 1 or -1 end
local function tri(ph) local p = ph - floor(ph) return 4 * abs(p - 0.5) - 1 end

-- Add a voice into buf starting at sample `at`, for `dur` seconds.
-- gen(t, i) returns a sample for time t (seconds since note start).
local function addVoice(buf, n, at, dur, gen)
  local count = floor(dur * Synth.RATE)
  for i = 0, count - 1 do
    local idx = ((at + i) % n) + 1 -- wrap around so loop tails spill into the start
    buf[idx] = buf[idx] + gen(i / Synth.RATE)
  end
end

local INSTRUMENTS = {}

function INSTRUMENTS.kick(buf, n, at, vel)
  local ph = 0
  addVoice(buf, n, at, 0.35, function(t)
    local f = 45 + 110 * exp(-t * 30)
    ph = ph + f / Synth.RATE
    return sin(ph * TAU) * exp(-t * 9) * vel * 0.9
  end)
end

function INSTRUMENTS.snare(buf, n, at, vel)
  addVoice(buf, n, at, 0.22, function(t)
    return (noise() * 0.6 + sin(t * 185 * TAU) * 0.4) * exp(-t * 18) * vel * 0.6
  end)
end

function INSTRUMENTS.hat(buf, n, at, vel)
  local last = 0
  addVoice(buf, n, at, 0.06, function(t)
    local x = noise()
    local hp = x - last
    last = x
    return hp * exp(-t * 70) * vel * 0.25
  end)
end

function INSTRUMENTS.bass(buf, n, at, vel, chord, dur)
  local f = freq(chord.root - 36)
  local lp = 0
  addVoice(buf, n, at, dur, function(t)
    local x = saw(t * f)
    lp = lp + (x - lp) * 0.12
    local env = math.min(1, t * 200) * exp(-t * 3)
    return lp * env * vel * 0.55
  end)
end

function INSTRUMENTS.guitar(buf, n, at, vel, chord, dur)
  local f1 = freq(chord.root - 24)
  local f2 = f1 * 1.4983 -- fifth
  local f3 = f1 * 2
  addVoice(buf, n, at, dur, function(t)
    local x = saw(t * f1) + saw(t * f2 * 1.002) + saw(t * f3 * 0.998) * 0.7
    x = x * 2.5
    x = x / (1 + abs(x)) -- soft clip "distortion"
    local env = math.min(1, t * 300) * exp(-t * 4)
    return x * env * vel * 0.28
  end)
end

function INSTRUMENTS.keys(buf, n, at, vel, chord, dur)
  local third = chord.minor and 3 or 4
  local fs = { freq(chord.root - 12), freq(chord.root - 12 + third), freq(chord.root - 12 + 7) }
  addVoice(buf, n, at, dur * 2, function(t)
    local x = (tri(t * fs[1]) + tri(t * fs[2]) + tri(t * fs[3])) / 3
    return x * exp(-t * 4) * vel * 0.35
  end)
end

function INSTRUMENTS.lead(buf, n, at, vel, chord, dur, step)
  local third = chord.minor and 3 or 4
  local arp = { 0, third, 7, 12, 7, third }
  local semis = chord.root + arp[(step % #arp) + 1]
  local f = freq(semis)
  addVoice(buf, n, at, dur, function(t)
    local vib = 1 + 0.004 * sin(t * 6 * TAU)
    local env = math.min(1, t * 150) * exp(-t * 5)
    return square(t * f * vib) * env * vel * 0.12
  end)
end

-- Continuous chord pad for the always-on "bed" track.
function INSTRUMENTS.pad(buf, n, at, vel, chord, dur)
  local third = chord.minor and 3 or 4
  local fs = { freq(chord.root - 24), freq(chord.root - 12 + third), freq(chord.root - 12 + 7), freq(chord.root - 12) }
  addVoice(buf, n, at, dur, function(t)
    local x = 0
    for i = 1, 4 do x = x + sin(t * fs[i] * TAU) end
    local env = math.min(1, t * 2) * math.min(1, (dur - t) * 3)
    return x * 0.25 * env * vel * 0.3
  end)
end

-- Which instrument plays a given track. Tracks not listed use `instrument` from the song file.
Synth.DEFAULT_INSTRUMENT = {
  drums = "drums", perc = "hat", bass = "bass", guitar = "guitar",
  keys = "keys", lead = "lead", bed = "pad",
}

-- Render one track to an array of floats. Returns buf, sampleCount.
-- song: { bpm, stepsPerBeat, bars, synth = { chords = {...} } }
-- track: { pattern = "...", instrument = optional }
function Synth.renderTrack(song, trackName, track)
  local spb = song.stepsPerBeat or 4
  local stepDur = 60 / song.bpm / spb
  local stepsPerBar = spb * 4
  local bars = song.bars or 4
  local totalSteps = stepsPerBar * bars
  local n = floor(totalSteps * stepDur * Synth.RATE)
  local buf = {}
  for i = 1, n do buf[i] = 0 end

  local chords = {}
  for i, c in ipairs((song.synth and song.synth.chords) or { "Am" }) do chords[i] = Synth.parseChord(c) end
  local function chordAt(step) return chords[(floor(step / stepsPerBar) % #chords) + 1] end

  local inst = track.instrument or Synth.DEFAULT_INSTRUMENT[trackName] or "keys"
  seed = 12345 + #trackName * 7919

  if inst == "pad" then
    for bar = 0, bars - 1 do
      local at = floor(bar * stepsPerBar * stepDur * Synth.RATE)
      INSTRUMENTS.pad(buf, n, at, 1, chordAt(bar * stepsPerBar), stepsPerBar * stepDur)
    end
    return buf, n
  end

  local p = Pattern.parse(track.pattern)
  for step = 0, totalSteps - 1 do
    local need = Pattern.at(p, step)
    if need > 0 then
      local vel = Pattern.VELOCITY[need]
      local at = floor(step * stepDur * Synth.RATE)
      if inst == "drums" then
        local inBar = step % stepsPerBar
        local backbeat = inBar == spb or inBar == spb * 3
        if backbeat or need == 5 then
          INSTRUMENTS.snare(buf, n, at, vel)
        else
          INSTRUMENTS.kick(buf, n, at, vel)
        end
      else
        INSTRUMENTS[inst](buf, n, at, vel, chordAt(step), stepDur * 2, step)
      end
    end
  end
  return buf, n
end

-- A short click for the metronome / calibration screen.
function Synth.click(pitch)
  local n = floor(0.03 * Synth.RATE)
  local buf = {}
  for i = 1, n do
    local t = (i - 1) / Synth.RATE
    buf[i] = sin(t * (pitch or 1500) * TAU) * exp(-t * 150) * 0.6
  end
  return buf, n
end

-- Copy a rendered buffer into a LÖVE SoundData (mono, 16 bit).
function Synth.toSoundData(buf, n)
  local sd = love.sound.newSoundData(n, Synth.RATE, 16, 1)
  for i = 1, n do
    local x = buf[i]
    if x > 1 then x = 1 elseif x < -1 then x = -1 end
    sd:setSample(i - 1, x)
  end
  return sd
end

return Synth
