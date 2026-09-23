-- Shared colours and text helpers for menus.
local Assets = require("src.core.assets")

local Theme = {}
local g = love.graphics

Theme.W, Theme.H = 960, 540
Theme.bg = { 0.07, 0.08, 0.07 }
Theme.accent = { 0.55, 0.95, 0.4 }
Theme.text = { 0.92, 0.92, 0.88 }
Theme.dim = { 0.55, 0.55, 0.52 }
Theme.warn = { 1.0, 0.45, 0.45 }
Theme.brain = { 0.95, 0.6, 0.7 }

function Theme.title(text, y, pulse)
  g.setFont(Assets.font(44))
  local s = 1 + (pulse or 0) * 0.06
  g.push()
  g.translate(Theme.W / 2, y + 22)
  g.scale(s, s)
  g.setColor(0.1, 0.25, 0.08)
  g.printf(text, -Theme.W / 2 + 3, -22 + 3, Theme.W, "center")
  g.setColor(Theme.accent)
  g.printf(text, -Theme.W / 2, -22, Theme.W, "center")
  g.pop()
end

function Theme.text_(text, x, y, size, color, width, align)
  g.setFont(Assets.font(size or 14))
  g.setColor(color or Theme.text)
  if width then g.printf(text, x, y, width, align or "left") else g.print(text, x, y) end
end

function Theme.panel(x, y, w, h)
  g.setColor(0, 0, 0, 0.55)
  g.rectangle("fill", x, y, w, h, 6, 6)
  g.setColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.35)
  g.rectangle("line", x, y, w, h, 6, 6)
end

function Theme.brains(count)
  Theme.text_("Rotting brains: " .. count, 0, Theme.H - 30, 14, Theme.brain, Theme.W - 20, "right")
end

return Theme
