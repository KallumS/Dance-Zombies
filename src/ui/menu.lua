-- Minimal vertical menu driven by abstract input actions (keyboard or gamepad).
-- items: { label = string|fn, action = fn, left = fn, right = fn, disabled = fn, hint = string|fn }
local Theme = require("src.ui.theme")
local Assets = require("src.core.assets")

local Menu = {}
Menu.__index = Menu

function Menu.new(items, opts)
  opts = opts or {}
  return setmetatable({ items = items, index = 1, size = opts.size or 18, spacing = opts.spacing or 32 }, Menu)
end

local function val(v, ...) if type(v) == "function" then return v(...) end return v end

function Menu:current() return self.items[self.index] end

function Menu:action(a)
  local it = self:current()
  if a == "up" then self.index = (self.index - 2) % #self.items + 1; Assets.playSfx("menu_move", 0.5)
  elseif a == "down" then self.index = self.index % #self.items + 1; Assets.playSfx("menu_move", 0.5)
  elseif a == "left" and it.left then it.left()
  elseif a == "right" and it.right then it.right()
  elseif a == "confirm" and it.action and not val(it.disabled) then Assets.playSfx("menu_select", 0.6); it.action()
  else return false end
  return true
end

function Menu:draw(x, y, w)
  for i, it in ipairs(self.items) do
    local sel = i == self.index
    local disabled = val(it.disabled)
    local color = disabled and Theme.dim or (sel and Theme.accent or Theme.text)
    local label = val(it.label)
    if sel then label = "> " .. label .. " <" end
    Theme.text_(label, x, y + (i - 1) * self.spacing, self.size, color, w, "center")
  end
  local hint = val(self:current().hint)
  if hint then Theme.text_(hint, x, y + #self.items * self.spacing + 10, 13, Theme.dim, w, "center") end
end

return Menu
