-- Keyboard + gamepad input. Movement is analogue (stick) or digital (WASD / arrows / d-pad).
-- Menus use abstract actions: up, down, left, right, confirm, back, pause, debug.
local Input = {}

local KEY_ACTIONS = {
  up = "up", w = "up", down = "down", s = "down", left = "left", a = "left", right = "right", d = "right",
  ["return"] = "confirm", kpenter = "confirm", space = "confirm", z = "confirm",
  escape = "back", backspace = "back", x = "back",
  p = "pause", f1 = "debug",
}

local PAD_ACTIONS = {
  dpup = "up", dpdown = "down", dpleft = "left", dpright = "right",
  a = "confirm", b = "back", start = "pause", back = "debug",
}

local DEADZONE = 0.2

function Input.fromKey(key) return KEY_ACTIONS[key] end
function Input.fromButton(button) return PAD_ACTIONS[button] end

-- Unit-or-shorter movement vector.
function Input.moveVector()
  local x, y = 0, 0
  local kb = love.keyboard.isDown
  if kb("a", "left") then x = x - 1 end
  if kb("d", "right") then x = x + 1 end
  if kb("w", "up") then y = y - 1 end
  if kb("s", "down") then y = y + 1 end

  for _, js in ipairs(love.joystick.getJoysticks()) do
    if js:isGamepad() then
      local ax, ay = js:getGamepadAxis("leftx"), js:getGamepadAxis("lefty")
      if ax * ax + ay * ay > DEADZONE * DEADZONE then x, y = x + ax, y + ay end
      if js:isGamepadDown("dpleft") then x = x - 1 end
      if js:isGamepadDown("dpright") then x = x + 1 end
      if js:isGamepadDown("dpup") then y = y - 1 end
      if js:isGamepadDown("dpdown") then y = y + 1 end
    end
  end

  local l = math.sqrt(x * x + y * y)
  if l > 1 then x, y = x / l, y / l end
  return x, y
end

-- Scripted input for the automated smoke test (main.lua --autotest).
Input.override = nil
local rawMove = Input.moveVector
function Input.moveVector()
  if Input.override then return Input.override() end
  return rawMove()
end

return Input
