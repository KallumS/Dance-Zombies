-- Applies the result of a run to the save file: brains, lifetime stats, achievements, unlocks.
local Save = require("src.core.save")
local Achievements = require("src.data.achievements")
local Characters = require("src.data.characters")
local Stages = require("src.data.stages")

local Progress = {}

function Progress.characterUnlocked(id)
  return Characters[id].unlocked or Save.isUnlocked("character_" .. id)
end

function Progress.stageUnlocked(id)
  local s = Stages[id]
  return not s.unlock or Save.isUnlocked(s.unlock)
end

function Progress.modeUnlocked(id)
  local m = Stages.MODES[id]
  return not m.unlock or Save.isUnlocked(m.unlock)
end

-- Hint text for how to unlock something, from the achievement that grants it.
function Progress.unlockHint(unlockId)
  for _, a in ipairs(Achievements.LIST) do
    for _, u in ipairs(a.unlocks or {}) do
      if u == unlockId then return a.desc end
    end
  end
  return "???"
end

-- summary: World:runSummary(). Returns { brains = earned, achievements = { newly earned defs } }
function Progress.finishRun(summary)
  local d = Save.data
  local st = d.stats
  d.brains = d.brains + summary.brains
  st.brainsEarned = st.brainsEarned + summary.brains
  st.totalKills = st.totalKills + summary.kills
  st.bestKills = math.max(st.bestKills, summary.kills)
  st.runs = st.runs + 1
  st.ruinsFound = st.ruinsFound + summary.ruins
  st.evolutions = st.evolutions + summary.evolutions
  if summary.completed then st.completions = st.completions + 1 end

  local earned = {}
  local ctx = { run = summary, stats = st }
  for _, a in ipairs(Achievements.LIST) do
    if not d.achievements[a.id] and a.test(ctx) then
      d.achievements[a.id] = true
      d.brains = d.brains + (a.reward or 0)
      for _, u in ipairs(a.unlocks or {}) do Save.unlock(u) end
      earned[#earned + 1] = a
    end
  end
  Save.write()
  return { brains = summary.brains, achievements = earned }
end

return Progress
