-- Plays a song as a set of layered stems that all start together and loop together.
--
-- Every stem is always playing; locked stems are just at volume 0. That keeps them
-- sample-aligned so a weapon's track can fade in on the beat without re-syncing.
--
-- Music:time() returns a smoothed, monotonic song time derived from the playing audio.
-- That clock drives the Conductor, so attacks follow what the player *hears*.
local Synth = require("src.audio.synth")
local Settings = require("src.core.settings")

local Music = {}
Music.__index = Music

local FADE_SPEED = 2.5      -- volume units per second when a track turns on/off
local RESYNC_EVERY = 2.0    -- seconds between drift checks
local RESYNC_TOLERANCE = 0.03

local function fileExists(path) return love.filesystem.getInfo(path, "file") ~= nil end

-- Synthesised placeholder stems are cached so re-entering a stage is instant.
local synthCache = {}

-- song: the table returned by assets/songs/<id>/song.lua (with .dir set by the loader)
function Music.load(song)
  local self = setmetatable({
    song = song,
    tracks = {},       -- name -> { source, volume, target, current }
    order = {},
    clock = 0,
    loops = 0,
    lastRaw = 0,
    playing = false,
    resyncTimer = 0,
    silent = false,
  }, Music)

  local names = {}
  for name in pairs(song.tracks) do names[#names + 1] = name end
  table.sort(names, function(a, b) return (a == "bed") and b ~= "bed" or (a < b and b ~= "bed") end)

  for _, name in ipairs(names) do
    local def = song.tracks[name]
    local source
    local path = def.file and (song.dir .. "/" .. def.file)
    local ok, err = pcall(function()
      if path and fileExists(path) then
        source = love.audio.newSource(path, "stream")
      elseif def.pattern or name == "bed" then
        local key = (song.id or song.title) .. ":" .. name
        if not synthCache[key] then synthCache[key] = Synth.toSoundData(Synth.renderTrack(song, name, def)) end
        source = love.audio.newSource(synthCache[key], "static")
      end
    end)
    if not ok then
      print("[music] could not create track " .. name .. ": " .. tostring(err))
      self.silent = true
    end
    if source then source:setLooping(true) end
    self.tracks[name] = {
      source = source,
      volume = def.volume or 1,
      target = (name == "bed") and 1 or 0,
      current = (name == "bed") and 1 or 0,
    }
    self.order[#self.order + 1] = name
  end

  self.master = self.tracks[self.order[1]] and self.tracks[self.order[1]].source
  if not self.master then self.silent = true end
  self.length = song.loopLength
  if not self.length and self.master then self.length = self.master:getDuration() end
  if not self.length or self.length <= 0 then
    self.length = (song.bars or 4) * 4 * 60 / song.bpm
  end
  return self
end

function Music:applyVolumes()
  local mv = Settings.get("musicVolume")
  for _, t in pairs(self.tracks) do
    if t.source then t.source:setVolume(t.current * t.volume * mv) end
  end
end

function Music:play()
  self.clock, self.loops, self.lastRaw = 0, 0, 0
  self:applyVolumes()
  local all = {}
  for _, name in ipairs(self.order) do
    local s = self.tracks[name].source
    if s then all[#all + 1] = s end
  end
  if #all > 0 then love.audio.play(all) end -- starts every stem in the same call
  self.playing = true
end

function Music:pause()
  for _, t in pairs(self.tracks) do if t.source then t.source:pause() end end
  self.playing = false
end

function Music:resume()
  local all = {}
  for _, t in pairs(self.tracks) do if t.source then all[#all + 1] = t.source end end
  if #all > 0 then love.audio.play(all) end
  self.playing = true
end

function Music:stop()
  for _, t in pairs(self.tracks) do if t.source then t.source:stop() end end
  self.playing = false
end

function Music:setTrackActive(name, on)
  local t = self.tracks[name]
  if t then t.target = on and 1 or 0 end
end

function Music:hasTrack(name) return self.tracks[name] ~= nil end

function Music:time() return self.clock end

local function masterPosition(self)
  local raw = self.master:tell("seconds")
  if raw < self.lastRaw - self.length * 0.5 then self.loops = self.loops + 1 end
  self.lastRaw = raw
  return self.loops * self.length + raw, raw
end

function Music:update(dt)
  -- fades
  for _, t in pairs(self.tracks) do
    if t.current < t.target then t.current = math.min(t.target, t.current + FADE_SPEED * dt)
    elseif t.current > t.target then t.current = math.max(t.target, t.current - FADE_SPEED * dt) end
  end
  self:applyVolumes()

  if not self.playing then return end
  local predicted = self.clock + dt
  if self.silent or not self.master or not self.master:isPlaying() then
    self.clock = predicted
    return
  end

  -- tell() advances in audio-buffer sized jumps, so blend towards it instead of snapping.
  local pos, raw = masterPosition(self)
  local err = pos - predicted
  if math.abs(err) > 0.15 then
    self.clock = math.max(self.clock, pos)
  else
    self.clock = math.max(self.clock, predicted + err * 0.1)
  end

  -- keep other stems aligned with the master
  self.resyncTimer = self.resyncTimer + dt
  if self.resyncTimer >= RESYNC_EVERY then
    self.resyncTimer = 0
    if raw > 0.2 and raw < self.length - 0.2 then
      for _, t in pairs(self.tracks) do
        local s = t.source
        if s and s ~= self.master and math.abs(s:tell("seconds") - raw) > RESYNC_TOLERANCE then
          s:seek(raw, "seconds")
        end
      end
    end
  end
end

return Music
