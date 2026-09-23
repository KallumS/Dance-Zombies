-- Playable characters. `bonus` is added on top of the base stats in src/game/stats.lua.
local C = {}

C.roadie = {
  name = "The Roadie", desc = "Knows every setlist. Starts with the Crossbow.",
  weapon = "crossbow", bonus = {}, color = { 0.95, 0.85, 0.6 }, unlocked = true,
}
C.bassist = {
  name = "The Bassist", desc = "Starts with the Bass Cannon. +20 max health.",
  weapon = "bass_cannon", bonus = { maxHp = 20 }, color = { 0.5, 0.65, 1.0 },
}
C.shredder = {
  name = "The Shredder", desc = "Starts with the Shotgun. +15% damage, -10 max health.",
  weapon = "shotgun", bonus = { might = 0.15, maxHp = -10 }, color = { 1.0, 0.55, 0.35 },
}
C.drummer = {
  name = "The Drummer", desc = "Starts with Hi-Hat Blades. +10% move speed.",
  weapon = "hihat_blades", bonus = { moveSpeed = 0.10 }, color = { 0.8, 0.95, 1.0 },
}

C.ORDER = { "roadie", "bassist", "shredder", "drummer" }

return C
