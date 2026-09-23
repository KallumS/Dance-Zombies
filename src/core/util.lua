-- Small, dependency-free helpers. Safe to require from tests (no LÖVE).
local U = {}

function U.clamp(x, a, b) if x < a then return a elseif x > b then return b end return x end
function U.lerp(a, b, t) return a + (b - a) * t end
function U.len(x, y) return math.sqrt(x * x + y * y) end
function U.dist2(ax, ay, bx, by) local dx, dy = ax - bx, ay - by return dx * dx + dy * dy end

function U.norm(x, y)
  local l = math.sqrt(x * x + y * y)
  if l < 1e-9 then return 0, 0 end
  return x / l, y / l
end

function U.shuffle(t, rand)
  rand = rand or math.random
  for i = #t, 2, -1 do
    local j = rand(1, i)
    t[i], t[j] = t[j], t[i]
  end
  return t
end

-- items: array; weight(item) -> number >= 0
function U.weightedPick(items, weight, rand)
  rand = rand or math.random
  local total = 0
  for _, it in ipairs(items) do total = total + weight(it) end
  if total <= 0 then return nil end
  local r = rand() * total
  for _, it in ipairs(items) do
    r = r - weight(it)
    if r <= 0 then return it end
  end
  return items[#items]
end

function U.deepcopy(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do out[k] = U.deepcopy(x) end
  return out
end

-- Remove items flagged dead from an array in place (order not preserved; O(n)).
function U.sweep(list, isDead)
  local i, n = 1, #list
  while i <= n do
    if isDead(list[i]) then
      list[i] = list[n]
      list[n] = nil
      n = n - 1
    else
      i = i + 1
    end
  end
end

function U.formatInt(n)
  local s = tostring(math.floor(n))
  local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
  return (out:gsub("^,", ""))
end

return U
