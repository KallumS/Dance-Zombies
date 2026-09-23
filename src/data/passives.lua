-- Passive items. Each level adds `per` to the named stat (see src/game/stats.lua).
local P = {}

P.protein_shake = { name = "Protein Shake", desc = "+10% damage", stat = "might", per = 0.10, maxLevel = 5, color = { 0.9, 0.4, 0.4 } }
P.running_shoes = { name = "Running Shoes", desc = "+8% move speed", stat = "moveSpeed", per = 0.08, maxLevel = 5, color = { 0.4, 0.9, 0.5 } }
P.magnet = { name = "Magnet", desc = "+30% pickup range", stat = "magnet", per = 0.30, maxLevel = 5, color = { 0.6, 0.6, 1.0 } }
P.amplifier = { name = "Amplifier", desc = "+10% attack area", stat = "area", per = 0.10, maxLevel = 5, color = { 1.0, 0.8, 0.3 } }
P.armor_vest = { name = "Armor Vest", desc = "-1 damage taken", stat = "armor", per = 1, maxLevel = 5, color = { 0.6, 0.6, 0.6 } }
P.echo_pedal = { name = "Echo Pedal", desc = "+1 projectile / strike", stat = "amount", per = 1, maxLevel = 2, color = { 0.4, 0.9, 0.9 } }
P.heart = { name = "Beating Heart", desc = "+20 max health", stat = "maxHp", per = 20, maxLevel = 5, color = { 1.0, 0.3, 0.4 } }
P.lucky_pick = { name = "Lucky Pick", desc = "+20% luck (more brains)", stat = "luck", per = 0.20, maxLevel = 5, color = { 0.3, 1.0, 0.6 } }

P.POOL = { "protein_shake", "running_shoes", "magnet", "amplifier", "armor_vest", "echo_pedal", "heart", "lucky_pick" }

return P
