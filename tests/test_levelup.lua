local LevelUp = require("src.game.levelup")
local Weapons = require("src.data.weapons")
local Passives = require("src.data.passives")
return function(t)
  local function state(weapons, passives)
    return { weapons = weapons, passives = passives or {}, weaponPool = Weapons.POOL, passivePool = Passives.POOL }
  end
  t.test("every weapon has a valid evolution", function()
    for _, id in ipairs(Weapons.POOL) do
      local d = Weapons[id]
      t.truthy(Weapons[d.evolution] and Weapons[d.evolution].evolved, id .. " evolution missing")
      t.truthy(Passives[d.evolveWith], id .. " evolveWith missing")
      t.eq(Weapons[d.evolution].track, d.track, id .. " evolution must keep its track")
    end
  end)
  t.test("statsAt applies level deltas", function()
    local s1 = Weapons.statsAt("crossbow", 1)
    local s8 = Weapons.statsAt("crossbow", 8)
    t.eq(s1.damage, 10); t.eq(s8.damage, 23); t.eq(s8.amount, 3); t.eq(s8.pierce, 3)
  end)
  t.test("evolution requires max level and passive", function()
    local ws = { { id = "crossbow", level = 8 } }
    t.eq(#LevelUp.evolutionsReady(ws, {}), 0)
    t.eq(#LevelUp.evolutionsReady({ { id = "crossbow", level = 7 } }, { echo_pedal = 1 }), 0)
    local r = LevelUp.evolutionsReady(ws, { echo_pedal = 1 })
    t.eq(#r, 1); t.eq(r[1].into, "drumline_ballista")
  end)
  t.test("choices put evolution first and never repeat", function()
    local opts = LevelUp.choices(state({ { id = "crossbow", level = 8 } }, { echo_pedal = 1 }), 3, t.rng(7))
    t.eq(opts[1].type, "evolve")
    local seen = {}
    for _, o in ipairs(opts) do
      local k = o.type .. (o.id or "")
      t.truthy(not seen[k], "duplicate " .. k)
      seen[k] = true
    end
  end)
  t.test("owned or evolved weapons are not offered as new", function()
    local ws = { { id = "drumline_ballista", level = 1, baseId = "crossbow" } }
    for seed = 1, 30 do
      for _, o in ipairs(LevelUp.choices(state(ws), 3, t.rng(seed))) do
        t.truthy(not (o.type == "weapon_new" and o.id == "crossbow"), "offered evolved base")
        t.truthy(o.type ~= "weapon_up" or o.id ~= "drumline_ballista", "offered evolved upgrade")
      end
    end
  end)
  t.test("falls back to heal/brains when everything is maxed", function()
    local ws, ps = {}, {}
    for _, id in ipairs(Weapons.POOL) do ws[#ws + 1] = { id = Weapons[id].evolution, level = 1, baseId = id } end
    for i = 1, 6 do local id = Passives.POOL[i]; ps[id] = Passives[id].maxLevel end
    local opts = LevelUp.choices(state(ws, ps), 3, t.rng(3))
    t.eq(opts[1].type, "heal")
  end)
end
