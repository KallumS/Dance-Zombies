-- Optional art/sound loader. Every lookup falls back gracefully so the game runs with
-- zero asset files (placeholder shapes are drawn instead). Drop files in:
--   assets/sprites/<name>.png   e.g. player.png, zombie_shambler.png, gem_small.png
--   assets/sfx/<name>.wav|ogg   e.g. levelup.ogg, pickup.wav, hurt.wav
--   assets/fonts/main.ttf       replaces the default font
-- See docs/GUIDE.md for the full list of names.
local Settings = require("src.core.settings")

local Assets = {}

local images, sounds, fonts = {}, {}, {}
local MISSING = false

local function exists(path) return love.filesystem.getInfo(path, "file") ~= nil end

function Assets.image(name)
  local img = images[name]
  if img == nil then
    local path = "assets/sprites/" .. name .. ".png"
    img = exists(path) and love.graphics.newImage(path) or MISSING
    if img ~= MISSING then img:setFilter("nearest", "nearest") end
    images[name] = img
  end
  return img or nil
end

-- Draw a sprite centred at x,y scaled to `size` pixels wide. Returns false if no sprite exists.
function Assets.drawSprite(name, x, y, size, rot, flipX, alpha)
  local img = Assets.image(name)
  if not img then return false end
  local w, h = img:getDimensions()
  local s = size / w
  love.graphics.setColor(1, 1, 1, alpha or 1)
  love.graphics.draw(img, x, y, rot or 0, flipX and -s or s, s, w / 2, h / 2)
  return true
end

function Assets.playSfx(name, volume)
  local src = sounds[name]
  if src == nil then
    src = MISSING
    for _, ext in ipairs({ ".ogg", ".wav", ".mp3" }) do
      local path = "assets/sfx/" .. name .. ext
      if exists(path) then src = love.audio.newSource(path, "static") break end
    end
    sounds[name] = src
  end
  if src then
    local s = src:clone()
    s:setVolume((volume or 1) * (Settings.get("sfxVolume") or 1))
    s:play()
  end
end

function Assets.font(size)
  local f = fonts[size]
  if not f then
    if exists("assets/fonts/main.ttf") then f = love.graphics.newFont("assets/fonts/main.ttf", size)
    else f = love.graphics.newFont(size) end
    fonts[size] = f
  end
  return f
end

return Assets
