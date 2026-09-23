-- Loads and validates song definitions from assets/songs/<id>/song.lua.
local Pattern = require("src.core.pattern")

local Songs = {}

Songs.TRACKS = { "bed", "drums", "perc", "bass", "guitar", "keys", "lead" }

-- Returns a list of problems (empty if valid). Pure, used by tests.
function Songs.validate(song)
  local problems = {}
  local function bad(msg) problems[#problems + 1] = msg end
  if type(song) ~= "table" then return { "song.lua must return a table" } end
  if type(song.bpm) ~= "number" or song.bpm <= 0 then bad("bpm must be a positive number") end
  if type(song.tracks) ~= "table" then bad("tracks table missing") return problems end
  for name, t in pairs(song.tracks) do
    if name ~= "bed" then
      if type(t.pattern) ~= "string" then
        bad(("track %s needs a pattern"):format(name))
      else
        local ok, err = pcall(Pattern.parse, t.pattern)
        if not ok then bad(("track %s: %s"):format(name, err)) end
      end
    end
  end
  return problems
end

function Songs.load(id)
  local dir = "assets/songs/" .. id
  local chunk, err = love.filesystem.load(dir .. "/song.lua")
  if not chunk then error("could not load song " .. id .. ": " .. tostring(err)) end
  local song = chunk()
  local problems = Songs.validate(song)
  if #problems > 0 then error("song " .. id .. " is invalid:\n  " .. table.concat(problems, "\n  ")) end
  song.id = id
  song.dir = dir
  song.stepsPerBeat = song.stepsPerBeat or 4
  song.offset = song.offset or 0
  song.patterns = {}
  for name, t in pairs(song.tracks) do
    if t.pattern then song.patterns[name] = Pattern.parse(t.pattern) end
  end
  return song
end

return Songs
