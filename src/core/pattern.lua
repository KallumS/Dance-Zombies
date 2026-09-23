-- Rhythm patterns: the contract between a song's audio and the weapons.
--
-- A pattern is a string with one character per step (a 16th note by default):
--   X  strong hit  - fires for weapon level 1+
--   x  medium hit  - fires for weapon level 3+
--   o  ghost hit   - fires for weapon level 5+
--   .  rest
-- Spaces and '|' are ignored so patterns can be written bar by bar:
--   "X...x...X...x... | X...x...X.x.x..."
-- Evolved weapons fire on every hit regardless of level.
--
-- Pure Lua (no LÖVE) so it can be unit tested.
local Pattern = {}

Pattern.MIN_LEVEL = { X = 1, x = 3, o = 5 }
Pattern.VELOCITY = { [1] = 1.0, [3] = 0.7, [5] = 0.45 }
Pattern.EVOLVED_LEVEL = 99

function Pattern.parse(str)
  assert(type(str) == "string", "pattern must be a string")
  local steps = {}
  for c in str:gmatch(".") do
    if c == " " or c == "|" or c == "\n" or c == "\t" then
      -- separator
    elseif c == "." or c == "-" then
      steps[#steps + 1] = 0
    elseif Pattern.MIN_LEVEL[c] then
      steps[#steps + 1] = Pattern.MIN_LEVEL[c]
    else
      error(("invalid pattern character %q in %q"):format(c, str))
    end
  end
  assert(#steps > 0, "pattern is empty")
  return steps
end

-- Minimum weapon level for a step (0 = rest). `step` is an absolute step index (0-based, may exceed length).
function Pattern.at(p, step)
  return p[(step % #p) + 1]
end

-- Does a weapon of `level` fire on `step`? Returns fires, velocity (0..1).
function Pattern.fires(p, step, level)
  local need = Pattern.at(p, step)
  if need == 0 or level < need then return false, 0 end
  return true, Pattern.VELOCITY[need]
end

-- Count how many times a weapon of `level` fires over one loop of the pattern.
function Pattern.density(p, level)
  local n = 0
  for i = 1, #p do
    if p[i] > 0 and level >= p[i] then n = n + 1 end
  end
  return n
end

return Pattern
