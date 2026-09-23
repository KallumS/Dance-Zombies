-- Spend rotting brains on permanent stat upgrades.
local Gamestate = require("src.states.gamestate")
local Theme = require("src.ui.theme")
local Menu = require("src.ui.menu")
local Save = require("src.core.save")
local Meta = require("src.data.meta_upgrades")

local Shop = {}

function Shop:enter()
  local items = {}
  for _, id in ipairs(Meta.ORDER) do
    local m = Meta[id]
    items[#items + 1] = {
      label = function()
        local r = Save.metaRank(id)
        local cost = r >= m.maxRank and "MAX" or (Meta.cost(id, r) .. " brains")
        return ("%s  [%d/%d]  -  %s"):format(m.name, r, m.maxRank, cost)
      end,
      disabled = function()
        local r = Save.metaRank(id)
        return r >= m.maxRank or Save.data.brains < Meta.cost(id, r)
      end,
      action = function()
        local r = Save.metaRank(id)
        Save.data.brains = Save.data.brains - Meta.cost(id, r)
        Save.data.meta[id] = r + 1
        Save.write()
      end,
      hint = m.desc,
    }
  end
  items[#items + 1] = { label = "Back", action = function() Gamestate.switch("title") end }
  self.menu = Menu.new(items, { size = 16, spacing = 30 })
end

function Shop:action(a)
  if a == "back" then Gamestate.switch("title") return end
  self.menu:action(a)
end

function Shop:draw()
  love.graphics.clear(Theme.bg)
  Theme.text_("BRAIN SHOP", 0, 30, 30, Theme.accent, Theme.W, "center")
  self.menu:draw(0, 90, Theme.W)
  Theme.brains(Save.data.brains)
end

return Shop
