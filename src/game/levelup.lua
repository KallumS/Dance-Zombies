-- Level-up choice generation and evolution rules. Pure (takes an rng), unit tested.
local Weapons = require("src.data.weapons")
local Passives = require("src.data.passives")
local U = require("src.core.util")

local LevelUp = {}

LevelUp.MAX_WEAPONS = 6
LevelUp.MAX_PASSIVES = 6

-- weapons: array of { id, level, baseId }; passives: { id = level }
-- A weapon can evolve when it is at max level and the matching passive is owned.
function LevelUp.evolutionsReady(weapons, passives)
  local ready = {}
  for i, w in ipairs(weapons) do
    local def = Weapons[w.id]
    if not def.evolved and def.evolution and w.level >= def.maxLevel and (passives[def.evolveWith] or 0) > 0 then
      ready[#ready + 1] = { type = "evolve", index = i, id = w.id, into = def.evolution }
    end
  end
  return ready
end

local function ownsBase(weapons, id)
  for _, w in ipairs(weapons) do
    if w.id == id or w.baseId == id then return true end
  end
  return false
end

-- state = { weapons, passives, weaponPool = {ids}, passivePool = {ids} }
-- Returns up to `count` options. Evolutions are always offered first when ready.
function LevelUp.choices(state, count, rand)
  rand = rand or math.random
  count = count or 3
  local weapons, passives = state.weapons, state.passives
  local out = {}

  for _, evo in ipairs(LevelUp.evolutionsReady(weapons, passives)) do
    if #out < count then out[#out + 1] = evo end
  end

  local candidates = {}
  for i, w in ipairs(weapons) do
    local def = Weapons[w.id]
    if not def.evolved and w.level < def.maxLevel then
      candidates[#candidates + 1] = { type = "weapon_up", index = i, id = w.id, level = w.level + 1, weight = 3 }
    end
  end
  if #weapons < LevelUp.MAX_WEAPONS then
    for _, id in ipairs(state.weaponPool) do
      if not ownsBase(weapons, id) then
        candidates[#candidates + 1] = { type = "weapon_new", id = id, level = 1, weight = 2 }
      end
    end
  end
  local passiveCount = 0
  for _ in pairs(passives) do passiveCount = passiveCount + 1 end
  for _, id in ipairs(state.passivePool) do
    local lvl = passives[id]
    if lvl then
      if lvl < Passives[id].maxLevel then
        candidates[#candidates + 1] = { type = "passive_up", id = id, level = lvl + 1, weight = 2 }
      end
    elseif passiveCount < LevelUp.MAX_PASSIVES then
      candidates[#candidates + 1] = { type = "passive_new", id = id, level = 1, weight = 1.5 }
    end
  end

  while #out < count and #candidates > 0 do
    local pick = U.weightedPick(candidates, function(c) return c.weight end, rand)
    for i, c in ipairs(candidates) do
      if c == pick then table.remove(candidates, i) break end
    end
    out[#out + 1] = pick
  end

  if #out == 0 then
    out[1] = { type = "heal" }
    out[2] = { type = "brains" }
  end
  return out
end

-- Human readable title + description for an option.
function LevelUp.describe(opt)
  if opt.type == "evolve" then
    local into = Weapons[opt.into]
    return "EVOLVE: " .. into.name, into.desc
  elseif opt.type == "weapon_new" then
    local d = Weapons[opt.id]
    return d.name .. "  (new, " .. d.track .. ")", d.desc
  elseif opt.type == "weapon_up" then
    local d = Weapons[opt.id]
    local lv = d.levels[opt.level]
    return d.name .. "  Lv " .. opt.level, lv and lv.text or ""
  elseif opt.type == "passive_new" or opt.type == "passive_up" then
    local d = Passives[opt.id]
    return d.name .. "  Lv " .. opt.level, d.desc
  elseif opt.type == "heal" then
    return "Snack", "Restore 30 health"
  elseif opt.type == "brains" then
    return "Brain Stash", "+5 rotting brains"
  end
  return "?", ""
end

return LevelUp
