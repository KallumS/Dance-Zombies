-- Unit tests for the pure-Lua modules. Run from the repo root:
--   luajit tests/run.lua        (or: lua5.1 tests/run.lua)
package.path = "./?.lua;./?/init.lua;" .. package.path

local passed, failed = 0, 0
local current = ""

local function test(name, fn)
  current = name
  local ok, err = pcall(fn)
  if ok then passed = passed + 1
  else failed = failed + 1; print("FAIL  " .. name .. "\n      " .. tostring(err)) end
end

local function eq(a, b, msg)
  if a ~= b then error((msg or "") .. " expected " .. tostring(b) .. ", got " .. tostring(a), 2) end
end
local function near(a, b, eps, msg)
  if math.abs(a - b) > (eps or 1e-6) then error((msg or "") .. " expected ~" .. b .. ", got " .. a, 2) end
end
local function truthy(v, msg) if not v then error(msg or "expected truthy", 2) end end

-- A deterministic rng so choice tests are stable.
local function rng(seed)
  local s = seed or 1
  return function(a, b)
    s = (s * 16807) % 2147483647
    local f = s / 2147483647
    if a then return a + math.floor(f * (b - a + 1)) end
    return f
  end
end

for _, file in ipairs({ "pattern", "conductor", "serialize", "levelup", "stats", "songs", "synth", "spatial" }) do
  local suite = require("tests.test_" .. file)
  suite({ test = test, eq = eq, near = near, truthy = truthy, rng = rng })
end

print(("%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
