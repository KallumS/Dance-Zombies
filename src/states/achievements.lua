-- Lists achievements and what they unlock.
local Gamestate = require("src.states.gamestate")
local Theme = require("src.ui.theme")
local Save = require("src.core.save")
local Achievements = require("src.data.achievements")

local A = {}

function A:action(a)
  if a == "back" or a == "confirm" then Gamestate.switch("title") end
end

function A:draw()
  love.graphics.clear(Theme.bg)
  Theme.text_("ACHIEVEMENTS", 0, 30, 30, Theme.accent, Theme.W, "center")
  local y = 90
  for _, a in ipairs(Achievements.LIST) do
    local done = Save.data.achievements[a.id]
    Theme.text_((done and "[X] " or "[ ] ") .. a.name, 120, y, 16, done and Theme.accent or Theme.text)
    local extra = {}
    if a.unlocks then extra[#extra + 1] = "unlocks " .. table.concat(a.unlocks, ", ") end
    if a.reward and a.reward > 0 then extra[#extra + 1] = "+" .. a.reward .. " brains" end
    Theme.text_(a.desc .. (#extra > 0 and ("   (" .. table.concat(extra, "; ") .. ")") or ""), 340, y + 2, 13, Theme.dim)
    y = y + 44
  end
  Theme.text_("Press Esc to go back", 0, Theme.H - 30, 13, Theme.dim, Theme.W, "center")
end

return A
