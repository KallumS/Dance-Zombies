-- Player stat calculation: base + character bonus + meta upgrades + passive items. Pure.
local Passives = require("src.data.passives")
local Meta = require("src.data.meta_upgrades")

local Stats = {}

Stats.BASE = {
  maxHp = 100, armor = 0, moveSpeed = 150, might = 1, area = 1, amount = 0,
  magnet = 60, growth = 1, greed = 1, luck = 1, recovery = 0,
}

-- Bonuses to these are percentages of the base value rather than flat additions.
Stats.PERCENT = { moveSpeed = true, magnet = true }

-- character: entry from data/characters.lua (may be nil)
-- metaRanks: { upgradeId = rank }, passiveLevels: { passiveId = level }
function Stats.compute(character, metaRanks, passiveLevels)
  local s, pct = {}, {}
  for k, v in pairs(Stats.BASE) do s[k] = v; pct[k] = 0 end

  local function add(stat, value)
    if Stats.PERCENT[stat] then pct[stat] = pct[stat] + value else s[stat] = s[stat] + value end
  end

  if character and character.bonus then
    for stat, v in pairs(character.bonus) do add(stat, v) end
  end
  for id, rank in pairs(metaRanks or {}) do
    local m = Meta[id]
    if m and rank > 0 then add(m.stat, m.per * rank) end
  end
  for id, level in pairs(passiveLevels or {}) do
    local p = Passives[id]
    if p and level > 0 then add(p.stat, p.per * level) end
  end
  for stat in pairs(Stats.PERCENT) do s[stat] = Stats.BASE[stat] * (1 + pct[stat]) end
  s.maxHp = math.max(1, s.maxHp)
  return s
end

return Stats
