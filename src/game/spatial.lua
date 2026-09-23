-- Uniform-grid spatial hash for fast "which zombies are near here?" queries. Pure.
local Spatial = {}
Spatial.__index = Spatial

local floor = math.floor

function Spatial.new(cellSize)
  return setmetatable({ cell = cellSize or 64, cells = {}, used = {} }, Spatial)
end

local function key(cx, cy) return (cx + 32768) * 65536 + (cy + 32768) end

function Spatial:clear()
  for i = 1, #self.used do
    self.used[i].n = 0
    self.used[i] = nil
  end
end

function Spatial:insert(obj)
  local k = key(floor(obj.x / self.cell), floor(obj.y / self.cell))
  local c = self.cells[k]
  if not c then c = { n = 0 }; self.cells[k] = c end
  if c.n == 0 then self.used[#self.used + 1] = c end
  c.n = c.n + 1
  c[c.n] = obj
end

-- Calls fn(obj) for every object in cells overlapping the circle (x, y, r).
-- Callers still need their own exact distance test.
function Spatial:each(x, y, r, fn)
  local cs = self.cell
  local x0, x1 = floor((x - r) / cs), floor((x + r) / cs)
  local y0, y1 = floor((y - r) / cs), floor((y + r) / cs)
  for cx = x0, x1 do
    for cy = y0, y1 do
      local c = self.cells[key(cx, cy)]
      if c then
        for i = 1, c.n do
          if fn(c[i]) == false then return end
        end
      end
    end
  end
end

return Spatial
