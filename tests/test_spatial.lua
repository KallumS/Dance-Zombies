local Spatial = require("src.game.spatial")
return function(t)
  t.test("spatial hash finds nearby objects and clears", function()
    local s = Spatial.new(32)
    local a, b = { x = 10, y = 10 }, { x = 500, y = -300 }
    s:insert(a); s:insert(b)
    local found = {}
    s:each(0, 0, 20, function(o) found[#found + 1] = o end)
    t.eq(#found, 1); t.eq(found[1], a)
    s:clear()
    found = {}
    s:each(0, 0, 1000, function(o) found[#found + 1] = o end)
    t.eq(#found, 0)
  end)
end
