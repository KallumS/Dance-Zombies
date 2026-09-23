-- End-of-run summary: kills, time, brains and any achievements/unlocks earned.
local Gamestate = require("src.states.gamestate")
local Theme = require("src.ui.theme")
local Save = require("src.core.save")
local U = require("src.core.util")

local Results = {}

function Results:enter(summary, result, opts)
  self.summary, self.result, self.opts = summary, result, opts
end

function Results:action(a)
  if a == "confirm" then Gamestate.switch("title")
  elseif a == "back" then Gamestate.switch("select") end
end

function Results:draw()
  love.graphics.clear(Theme.bg)
  local s = self.summary
  Theme.text_(s.completed and "YOU JOINED THE HORDE" or "RUN OVER", 0, 50, 32, s.completed and Theme.accent or Theme.warn, Theme.W, "center")
  local lines = {
    ("Zombies killed:  %s"):format(U.formatInt(s.kills)),
    ("Time survived:  %02d:%02d"):format(math.floor(s.time / 60), math.floor(s.time % 60)),
    ("Level reached:  %d"):format(s.level),
    ("Evolutions:  %d     Ruins found:  %d"):format(s.evolutions, s.ruins),
    ("Rotting brains earned:  %d"):format(self.result.brains),
  }
  for i, l in ipairs(lines) do Theme.text_(l, 0, 110 + i * 28, 18, Theme.text, Theme.W, "center") end
  local y = 290
  for _, a in ipairs(self.result.achievements) do
    local unlocks = a.unlocks and (" - unlocked " .. table.concat(a.unlocks, ", ")) or ""
    Theme.text_("Achievement: " .. a.name .. unlocks, 0, y, 15, { 1, 0.85, 0.3 }, Theme.W, "center")
    y = y + 24
  end
  Theme.text_("Enter: main menu     Esc: play again", 0, Theme.H - 50, 14, Theme.dim, Theme.W, "center")
  Theme.brains(Save.data.brains)
end

return Results
