local Songs = require("src.audio.songs")
local Weapons = require("src.data.weapons")
return function(t)
  for _, id in ipairs({ "graveyard_groove", "mall_of_the_dead", "highway_to_hell" }) do
    t.test("song " .. id .. " is valid and covers every weapon track", function()
      local song = dofile("assets/songs/" .. id .. "/song.lua")
      local problems = Songs.validate(song)
      t.eq(#problems, 0, table.concat(problems, "; "))
      for _, w in ipairs(Weapons.POOL) do
        local tr = song.tracks[Weapons[w].track]
        t.truthy(tr, id .. " missing track " .. Weapons[w].track)
        t.truthy(tr.pattern:find("X"), id .. " track " .. Weapons[w].track .. " has no X, so a level 1 weapon never fires")
      end
    end)
  end
  t.test("validate catches a broken pattern", function()
    local p = Songs.validate({ bpm = 100, tracks = { drums = { pattern = "X?" } } })
    t.eq(#p, 1)
  end)
end
