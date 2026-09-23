-- LÖVE configuration. See https://love2d.org/wiki/Config_Files
function love.conf(t)
  t.identity = "dance-zombies"      -- save directory name
  t.version = "11.5"
  t.window.title = "Dance Zombies"
  t.window.width = 1280
  t.window.height = 720
  t.window.resizable = true
  t.window.minwidth = 640
  t.window.minheight = 360
  t.window.vsync = 1
  t.modules.physics = false         -- we do our own lightweight collision
  t.modules.video = false
end
