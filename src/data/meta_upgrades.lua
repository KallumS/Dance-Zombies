-- Permanent upgrades bought with rotting brains in the main menu.
-- cost(rank) = base * (rank + 1)   where rank is the number already bought.
local M = {}

M.might = { name = "Might", desc = "+5% damage per rank", stat = "might", per = 0.05, maxRank = 5, base = 20 }
M.vitality = { name = "Vitality", desc = "+10 max health per rank", stat = "maxHp", per = 10, maxRank = 5, base = 15 }
M.swiftness = { name = "Swiftness", desc = "+4% move speed per rank", stat = "moveSpeed", per = 0.04, maxRank = 5, base = 20 }
M.toughness = { name = "Toughness", desc = "-1 damage taken per rank", stat = "armor", per = 1, maxRank = 3, base = 40 }
M.attraction = { name = "Attraction", desc = "+15% pickup range per rank", stat = "magnet", per = 0.15, maxRank = 4, base = 12 }
M.growth = { name = "Growth", desc = "+5% XP per rank", stat = "growth", per = 0.05, maxRank = 5, base = 25 }
M.greed = { name = "Greed", desc = "+10% brains per rank", stat = "greed", per = 0.10, maxRank = 5, base = 30 }
M.recovery = { name = "Recovery", desc = "+0.2 HP/s regen per rank", stat = "recovery", per = 0.2, maxRank = 5, base = 30 }

M.ORDER = { "might", "vitality", "swiftness", "toughness", "attraction", "growth", "greed", "recovery" }

function M.cost(id, rank) return M[id].base * (rank + 1) end

return M
