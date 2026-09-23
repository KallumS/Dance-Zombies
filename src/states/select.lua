-- Choose character, stage and mode before a run.
local Gamestate = require("src.states.gamestate")
local Theme = require("src.ui.theme")
local Menu = require("src.ui.menu")
local Characters = require("src.data.characters")
local Stages = require("src.data.stages")
local Weapons = require("src.data.weapons")
local Progress = require("src.game.progress")

local Select = {}

local function cycle(list, i, d) return (i - 1 + d) % #list + 1 end

function Select:enter()
  self.char = self.char or 1
  self.stage = self.stage or 1
  self.mode = self.mode or 1
  local function charId() return Characters.ORDER[self.char] end
  local function stageId() return Stages.ORDER[self.stage] end
  local function modeId() return Stages.MODE_ORDER[self.mode] end
  self.ids = { char = charId, stage = stageId, mode = modeId }

  local function locked()
    return not (Progress.characterUnlocked(charId()) and Progress.stageUnlocked(stageId()) and Progress.modeUnlocked(modeId()))
  end

  self.menu = Menu.new({
    { label = function()
        local id = charId()
        return "Character:  " .. (Progress.characterUnlocked(id) and Characters[id].name or "LOCKED")
      end,
      left = function() self.char = cycle(Characters.ORDER, self.char, -1) end,
      right = function() self.char = cycle(Characters.ORDER, self.char, 1) end,
      hint = "Left / right to change" },
    { label = function()
        local id = stageId()
        return "Stage:  " .. (Progress.stageUnlocked(id) and Stages[id].name or "LOCKED")
      end,
      left = function() self.stage = cycle(Stages.ORDER, self.stage, -1) end,
      right = function() self.stage = cycle(Stages.ORDER, self.stage, 1) end,
      hint = "Each stage is a different song" },
    { label = function()
        local id = modeId()
        return "Mode:  " .. (Progress.modeUnlocked(id) and Stages.MODES[id].name or "LOCKED")
      end,
      left = function() self.mode = cycle(Stages.MODE_ORDER, self.mode, -1) end,
      right = function() self.mode = cycle(Stages.MODE_ORDER, self.mode, 1) end },
    { label = "START", disabled = locked,
      action = function() Gamestate.switch("play", { character = charId(), stage = stageId(), mode = modeId() }) end,
      hint = function() return locked() and "Something here is still locked" or "Let's dance" end },
    { label = "Back", action = function() Gamestate.switch("title") end },
  })
end

function Select:action(a)
  if a == "back" then Gamestate.switch("title") return end
  self.menu:action(a)
end

local function infoBox(x, title, body, unlocked, hint)
  Theme.panel(x, 330, 290, 150)
  Theme.text_(title, x + 12, 340, 16, unlocked and Theme.accent or Theme.dim)
  Theme.text_(unlocked and body or ("Locked - " .. hint), x + 12, 366, 13, unlocked and Theme.text or Theme.warn, 266)
end

function Select:draw()
  love.graphics.clear(Theme.bg)
  Theme.text_("CHOOSE YOUR SET", 0, 40, 30, Theme.accent, Theme.W, "center")
  self.menu:draw(0, 110, Theme.W)

  local c, s, m = self.ids.char(), self.ids.stage(), self.ids.mode()
  local cd = Characters[c]
  infoBox(20, cd.name, cd.desc .. "\n\nStarting weapon: " .. Weapons[cd.weapon].name .. " (" .. Weapons[cd.weapon].track .. ")",
    Progress.characterUnlocked(c), Progress.unlockHint("character_" .. c))
  local sd = Stages[s]
  infoBox(335, sd.name, sd.desc, Progress.stageUnlocked(s), Progress.unlockHint(sd.unlock or ""))
  local md = Stages.MODES[m]
  infoBox(650, md.name, md.desc, Progress.modeUnlocked(m), Progress.unlockHint(md.unlock or ""))
end

return Select
