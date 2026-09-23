-- Serialise plain Lua tables (strings, numbers, booleans, nested tables) to Lua source.
-- Pure Lua, used by the save system and unit tests.
local S = {}

local function isIdent(k) return type(k) == "string" and k:match("^[%a_][%w_]*$") ~= nil end

local function write(v, indent, out)
  local t = type(v)
  if t == "string" then out[#out + 1] = string.format("%q", v)
  elseif t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then out[#out + 1] = "0"
    elseif v == math.floor(v) and math.abs(v) < 2 ^ 53 then out[#out + 1] = string.format("%d", v)
    else out[#out + 1] = string.format("%.17g", v) end
  elseif t == "boolean" then out[#out + 1] = tostring(v)
  elseif t == "table" then
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
      if type(a) == type(b) then return a < b end
      return type(a) == "number"
    end)
    out[#out + 1] = "{\n"
    local pad = indent .. "  "
    for _, k in ipairs(keys) do
      out[#out + 1] = pad
      if isIdent(k) then out[#out + 1] = k
      else out[#out + 1] = "["; write(k, pad, out); out[#out + 1] = "]" end
      out[#out + 1] = " = "
      write(v[k], pad, out)
      out[#out + 1] = ",\n"
    end
    out[#out + 1] = indent .. "}"
  else
    out[#out + 1] = "nil"
  end
end

function S.encode(v)
  local out = {}
  write(v, "", out)
  return "return " .. table.concat(out)
end

-- Decode with an empty environment so a tampered save cannot run code.
function S.decode(src)
  local chunk, err = (loadstring or load)(src, "save", "t", {})
  if not chunk then return nil, err end
  if setfenv then setfenv(chunk, {}) end
  local ok, res = pcall(chunk)
  if not ok then return nil, res end
  return res
end

return S
