-- Tiny state machine. A state is a table with optional enter/exit/update/draw/action/keypressed.
local Gamestate = { current = nil, states = {} }

function Gamestate.register(name, state) Gamestate.states[name] = state end

function Gamestate.switch(name, ...)
  local nxt = assert(Gamestate.states[name], "unknown state " .. tostring(name))
  if Gamestate.current and Gamestate.current.exit then Gamestate.current:exit() end
  Gamestate.current = nxt
  Gamestate.currentName = name
  if nxt.enter then nxt:enter(...) end
end

local function call(fn, ...)
  local s = Gamestate.current
  if s and s[fn] then return s[fn](s, ...) end
end

function Gamestate.update(dt) call("update", dt) end
function Gamestate.draw() call("draw") end
function Gamestate.action(a) call("action", a) end
function Gamestate.keypressed(k) call("keypressed", k) end

return Gamestate
