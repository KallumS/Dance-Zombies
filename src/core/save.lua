-- Persistent profile: rotting brains, meta upgrades, unlocks, lifetime stats, settings.
-- Stored as save.lua in the LÖVE save directory (love.filesystem.getSaveDirectory()).
local Serialize = require("src.core.serialize")
local U = require("src.core.util")

local Save = {}

local FILE = "save.lua"
local VERSION = 1

local DEFAULT = {
  version = VERSION,
  brains = 0,
  meta = {},            -- upgrade id -> rank
  unlocked = {},        -- unlock id -> true (characters, stages, weapons, modes)
  achievements = {},    -- achievement id -> true
  stats = { totalKills = 0, bestKills = 0, runs = 0, brainsEarned = 0, ruinsFound = 0, evolutions = 0, completions = 0 },
  settings = { musicVolume = 0.8, sfxVolume = 0.8, audioOffsetMs = 0, fullscreen = false, showBeatGrid = false },
}

Save.data = U.deepcopy(DEFAULT)

-- Fill any keys missing from an older save with defaults.
local function merge(into, defaults)
  for k, v in pairs(defaults) do
    if into[k] == nil then into[k] = U.deepcopy(v)
    elseif type(v) == "table" and type(into[k]) == "table" then merge(into[k], v) end
  end
end

function Save.load()
  if love.filesystem.getInfo(FILE) then
    local src = love.filesystem.read(FILE)
    local data = src and Serialize.decode(src)
    if type(data) == "table" then
      merge(data, DEFAULT)
      Save.data = data
      return
    end
    print("[save] save file unreadable, starting fresh")
  end
  Save.data = U.deepcopy(DEFAULT)
end

Save.readonly = false -- set by the autotest so bots never touch the real save

function Save.write()
  if Save.readonly then return end
  local ok, err = love.filesystem.write(FILE, Serialize.encode(Save.data))
  if not ok then print("[save] write failed: " .. tostring(err)) end
end

function Save.reset()
  local settings = Save.data.settings
  Save.data = U.deepcopy(DEFAULT)
  Save.data.settings = settings
  Save.write()
end

function Save.isUnlocked(id) return Save.data.unlocked[id] == true end
function Save.unlock(id) Save.data.unlocked[id] = true end
function Save.metaRank(id) return Save.data.meta[id] or 0 end

return Save
