-- One run of the game: player, zombies, weapons, pickups and the music that drives it all.
--
-- The rhythm loop, every frame:
--   music:update(dt)                -> smoothed song time from the playing audio
--   conductor:advance(songTime)     -> which 16th-note steps were crossed
--   onStep(step) for each step      -> every weapon checks its track's pattern and fires
local U = require("src.core.util")
local Pattern = require("src.core.pattern")
local Conductor = require("src.core.conductor")
local Input = require("src.core.input")
local Save = require("src.core.save")
local Settings = require("src.core.settings")
local Assets = require("src.core.assets")
local Songs = require("src.audio.songs")
local Music = require("src.audio.music")
local Weapons = require("src.data.weapons")
local Passives = require("src.data.passives")
local Characters = require("src.data.characters")
local Stages = require("src.data.stages")
local Stats = require("src.game.stats")
local LevelUp = require("src.game.levelup")
local Spatial = require("src.game.spatial")
local Spawner = require("src.game.spawner")
local Behaviours = require("src.game.behaviours")
local Fx = require("src.game.fx")

local World = {}
World.__index = World

local TRACK_LABEL = { drums = "Drums", perc = "Hi-hats", bass = "Bass", guitar = "Guitars", keys = "Keys", lead = "Lead" }

-- opts = { stage = id, character = id, mode = id }
function World.new(opts)
  local stage = Stages[opts.stage]
  local mode = Stages.MODES[opts.mode or "normal"]
  local character = Characters[opts.character]
  local song = Songs.load(stage.song)

  local self = setmetatable({
    stageId = opts.stage, stage = stage, modeId = opts.mode or "normal", mode = mode,
    characterId = opts.character, character = character, song = song,
    player = { x = 0, y = 0, r = 12, hp = 1, iframes = 0, faceX = 1, faceY = 0, hurt = 0, moving = false },
    enemies = {}, projectiles = {}, zones = {}, lobs = {}, gems = {}, pickups = {},
    weapons = {}, passives = {},
    kills = 0, time = 0, level = 1, xp = 0, xpBank = 0, pendingLevelUps = 0,
    brains = 0, ruinsFound = 0, evolutions = 0,
    ruin = nil, ruinTimer = 45,
    beatPulse = 0, finished = nil, endingT = 0,
    spatial = Spatial.new(64),
    fx = Fx.new(),
  }, World)

  self.music = Music.load(song)
  self.conductor = Conductor.new(song.bpm, song.stepsPerBeat, song.offset)
  self.conductor.userOffset = (Settings.get("audioOffsetMs") or 0) / 1000
  self.spawner = Spawner.new(self, mode)

  self.weaponPool = {}
  for _, id in ipairs(Weapons.POOL) do
    local locked = (id == "molotov" or id == "lightning_mic") and not Save.isUnlocked("weapon_" .. id)
    if not locked then self.weaponPool[#self.weaponPool + 1] = id end
  end

  self:recomputeStats()
  self.player.hp = self.stats.maxHp
  self:addWeapon(character.weapon)
  self.xpNeed = self:xpForLevel(1)
  self.music:play()
  return self
end

---------------------------------------------------------------------------
-- Progression
---------------------------------------------------------------------------

function World:xpForLevel(l)
  return math.floor(5 + (l - 1) * 8 + (l - 1) ^ 1.6)
end

function World:recomputeStats()
  local old = self.stats
  self.stats = Stats.compute(self.character, Save.data.meta, self.passives)
  if old and self.stats.maxHp > old.maxHp then
    self.player.hp = self.player.hp + (self.stats.maxHp - old.maxHp)
  end
end

function World:addWeapon(id, baseId)
  local def = Weapons[id]
  local w = { id = id, level = 1, baseId = baseId, flip = false }
  w.stats = Weapons.statsAt(id, 1)
  self.weapons[#self.weapons + 1] = w
  if not self.music:hasTrack(def.track) then
    print("[world] song has no '" .. def.track .. "' track; " .. id .. " will follow the drums")
  end
  self.music:setTrackActive(def.track, true)
  self.fx:toast((TRACK_LABEL[def.track] or def.track) .. " join the mix!  (" .. def.name .. ")", def.color)
  return w
end

function World:choiceState()
  return { weapons = self.weapons, passives = self.passives, weaponPool = self.weaponPool, passivePool = Passives.POOL }
end

function World:rollChoices()
  return LevelUp.choices(self:choiceState(), self.stats.luck >= 1.4 and 4 or 3)
end

function World:evolve(index)
  local w = self.weapons[index]
  local into = Weapons[w.id].evolution
  local base = w.baseId or w.id
  self.weapons[index] = { id = into, level = 1, baseId = base, flip = false, stats = Weapons.statsAt(into, 1) }
  self.evolutions = self.evolutions + 1
  self.fx:toast("EVOLUTION: " .. Weapons[into].name .. "!", { 1, 0.9, 0.3 })
  self.fx:addShake(8)
  Assets.playSfx("evolve")
end

function World:applyChoice(opt)
  if opt.type == "evolve" then
    self:evolve(opt.index)
  elseif opt.type == "weapon_new" then
    self:addWeapon(opt.id)
  elseif opt.type == "weapon_up" then
    local w = self.weapons[opt.index]
    w.level = opt.level
    w.stats = Weapons.statsAt(w.id, w.level)
  elseif opt.type == "passive_new" or opt.type == "passive_up" then
    self.passives[opt.id] = opt.level
    self:recomputeStats()
  elseif opt.type == "heal" then
    self.player.hp = math.min(self.stats.maxHp, self.player.hp + 30)
  elseif opt.type == "brains" then
    self.brains = self.brains + 5
  end
  self.pendingLevelUps = math.max(0, self.pendingLevelUps - 1)
end

function World:gainXp(v)
  self.xp = self.xp + v * self.stats.growth + self.xpBank
  self.xpBank = 0
  while self.xp >= self.xpNeed do
    self.xp = self.xp - self.xpNeed
    self.level = self.level + 1
    self.xpNeed = self:xpForLevel(self.level)
    self.pendingLevelUps = self.pendingLevelUps + 1
    Assets.playSfx("levelup")
  end
end

---------------------------------------------------------------------------
-- Spawning helpers used by behaviours
---------------------------------------------------------------------------

function World:spawnProjectile(p)
  p.hit = {}
  self.projectiles[#self.projectiles + 1] = p
end

function World:spawnLob(l) self.lobs[#self.lobs + 1] = l end

function World:enemiesInRadius(x, y, r, fn)
  self.spatial:each(x, y, r + 40, function(e)
    if not e.dead then
      local rr = r + e.r
      if U.dist2(e.x, e.y, x, y) <= rr * rr then fn(e) end
    end
  end)
end

function World:nearestEnemies(n, maxDist)
  local p = self.player
  local out, md2 = {}, maxDist * maxDist
  local cand = {}
  self.spatial:each(p.x, p.y, maxDist, function(e)
    if not e.dead then
      local d = U.dist2(e.x, e.y, p.x, p.y)
      if d <= md2 then cand[#cand + 1] = { e = e, d = d } end
    end
  end)
  table.sort(cand, function(a, b) return a.d < b.d end)
  for i = 1, math.min(n, #cand) do out[i] = cand[i].e end
  return out
end

function World:randomEnemyNear(x, y, r)
  local list = {}
  self:enemiesInRadius(x, y, r, function(e) list[#list + 1] = e end)
  if #list == 0 then return nil end
  return list[math.random(#list)]
end

---------------------------------------------------------------------------
-- Damage & death
---------------------------------------------------------------------------

function World:hitEnemy(e, dmg, dx, dy, knock)
  if e.dead then return end
  e.hp = e.hp - dmg
  e.flash = 0.08
  if knock and knock > 0 and not e.boss then
    e.kx, e.ky = e.kx + dx * knock, e.ky + dy * knock
  end
  self.fx:number(e.x, e.y - e.r - 6, dmg)
  if e.hp <= 0 then self:killEnemy(e) end
end

function World:dropPickup(kind, x, y, value)
  self.pickups[#self.pickups + 1] = { kind = kind, x = x, y = y, value = value, magnet = false, v = 0 }
end

function World:killEnemy(e)
  e.dead = true
  self.kills = self.kills + 1
  self.fx:splat(e.x, e.y, { 0.35, 0.55, 0.2 }, e.boss and 40 or 5)

  if #self.gems < 350 then
    self.gems[#self.gems + 1] = { x = e.x, y = e.y, value = e.xp, magnet = false, v = 0 }
  else
    self.xpBank = self.xpBank + e.xp -- too many gems on the floor: bank it into the next pickup
  end

  local luck = self.stats.luck
  if e.boss then
    self:dropPickup("chest", e.x, e.y)
    self:dropPickup("brain", e.x + 20, e.y, 10)
  elseif math.random() < 0.012 * luck then
    self:dropPickup("brain", e.x, e.y, 1)
  elseif math.random() < 0.004 then
    self:dropPickup("food", e.x, e.y)
  elseif math.random() < 0.0015 * luck then
    self:dropPickup("vinyl", e.x, e.y)
  end

  if self.kills >= Stages.KILLS_TO_WIN and not self.finished then
    self:finish("completed")
  end
end

function World:damagePlayer(amount)
  local p = self.player
  if p.iframes > 0 or self.finished then return end
  local dmg = math.max(1, amount - self.stats.armor)
  p.hp = p.hp - dmg
  p.iframes = 0.4
  p.hurt = 0.2
  self.fx:addShake(3)
  Assets.playSfx("hurt", 0.6)
  if p.hp <= 0 then
    p.hp = 0
    self:finish("died")
  end
end

-- reason: "completed" (10,000 kills -> you become a zombie) or "died"
function World:finish(reason)
  self.finished = reason
  self.endingT = 0
  for name in pairs(self.music.tracks) do
    if name ~= "bed" and name ~= "drums" then self.music:setTrackActive(name, false) end
  end
  if reason == "completed" then
    self.brains = self.brains + math.floor(100 * self.stats.greed)
    self.fx:addShake(10)
  end
end

function World:runSummary()
  return {
    kills = self.kills, stage = self.stageId, mode = self.modeId, character = self.characterId,
    time = self.time, level = self.level, evolutions = self.evolutions, ruins = self.ruinsFound,
    completed = self.finished == "completed",
    brains = math.floor(self.brains * (self.mode.brains or 1)),
  }
end

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------

function World:onStep(step)
  local spb = self.song.stepsPerBeat
  if step % spb == 0 then
    self.beatPulse = 1
    self.spawner:onBeat()
    if step % (spb * 4) == 0 then self.spawner:onBar() end
  end
  if self.finished then return end
  for _, w in ipairs(self.weapons) do
    local def = Weapons[w.id]
    local pattern = self.song.patterns[def.track] or self.song.patterns.drums
    local level = def.evolved and Pattern.EVOLVED_LEVEL or w.level
    local fires, vel = Pattern.fires(pattern, step, level)
    if fires then
      w.pulse = 1
      Behaviours[def.behaviour](self, w, w.stats, vel)
    end
  end
end

-- While a menu is open the song keeps playing but nothing fires or moves.
function World:updatePaused(dt)
  self.music:update(dt)
  self.conductor.lastStep = self.conductor:stepAt(self.music:time())
end

local sepSelf
local function separate(o)
  local e = sepSelf
  if o ~= e and not o.dead then
    local dx, dy = e.x - o.x, e.y - o.y
    local rr = e.r + o.r
    local d2 = dx * dx + dy * dy
    if d2 < rr * rr and d2 > 0.0001 then
      local d = math.sqrt(d2)
      local push = (rr - d) * 0.5
      e.x, e.y = e.x + dx / d * push, e.y + dy / d * push
    end
  end
end

function World:updateEnemies(dt)
  local p = self.player
  local phase = self.conductor:beatPhase(self.music:time())
  local lunge = 0.6 + 0.9 * math.exp(-phase * 5) -- zombies surge forward on every beat
  local decay = math.exp(-8 * dt)
  local contact = 0
  local frozen = self.finished ~= nil

  for _, e in ipairs(self.enemies) do
    if not e.dead then
      if not frozen then
        local dx, dy = p.x - e.x, p.y - e.y
        local d = math.sqrt(dx * dx + dy * dy)
        local sp = e.speed * lunge
        if e.slowT > 0 then e.slowT = e.slowT - dt; sp = sp * (1 - e.slowAmt) end
        if d > 0.001 then e.x, e.y = e.x + dx / d * sp * dt, e.y + dy / d * sp * dt end
        e.faceX = dx < 0 and -1 or 1
        if d < e.r + p.r then contact = math.max(contact, e.damage) end
      end
      e.x, e.y = e.x + e.kx * dt, e.y + e.ky * dt
      e.kx, e.ky = e.kx * decay, e.ky * decay
      e.flash = math.max(0, e.flash - dt)
      sepSelf = e
      self.spatial:each(e.x, e.y, e.r + 24, separate)
      self.spawner:recycle(e)
    end
  end
  if contact > 0 then self:damagePlayer(contact) end
end

function World:updateProjectiles(dt)
  for _, pr in ipairs(self.projectiles) do
    pr.x, pr.y = pr.x + pr.vx * dt, pr.y + pr.vy * dt
    pr.life = pr.life - dt
    if pr.life <= 0 then pr.dead = true end
    if not pr.dead then
      self.spatial:each(pr.x, pr.y, pr.r + 40, function(e)
        if pr.dead or e.dead or pr.hit[e] then return end
        local rr = pr.r + e.r
        if U.dist2(e.x, e.y, pr.x, pr.y) <= rr * rr then
          pr.hit[e] = true
          local dx, dy = U.norm(pr.vx, pr.vy)
          self:hitEnemy(e, pr.damage, dx, dy, pr.knockback)
          pr.pierce = pr.pierce - 1
          if pr.pierce <= 0 then pr.dead = true; return false end
        end
      end)
    end
  end
  U.sweep(self.projectiles, function(pr) return pr.dead end)

  for _, l in ipairs(self.lobs) do
    l.t = l.t + dt
    if l.t >= l.dur then
      l.dead = true
      local z = l.zone
      z.x, z.y, z.timer = l.x1, l.y1, 0
      self.zones[#self.zones + 1] = z
    end
  end
  U.sweep(self.lobs, function(l) return l.dead end)

  for _, z in ipairs(self.zones) do
    z.life = z.life - dt
    z.timer = z.timer - dt
    if z.follow then
      local e = self:randomEnemyNear(z.x, z.y, 200)
      if e then z.x, z.y = U.lerp(z.x, e.x, dt * 1.5), U.lerp(z.y, e.y, dt * 1.5) end
    end
    if z.timer <= 0 then
      z.timer = z.tick
      self:enemiesInRadius(z.x, z.y, z.radius, function(e) self:hitEnemy(e, z.damage, 0, 0, 0) end)
    end
  end
  U.sweep(self.zones, function(z) return z.life <= 0 end)
end

local function pull(obj, p, dt)
  obj.v = math.min(900, obj.v + 1400 * dt)
  local dx, dy = U.norm(p.x - obj.x, p.y - obj.y)
  obj.x, obj.y = obj.x + dx * obj.v * dt, obj.y + dy * obj.v * dt
end

function World:updatePickups(dt)
  local p = self.player
  local mag2 = self.stats.magnet ^ 2
  local grab2 = (p.r + 8) ^ 2
  for _, g in ipairs(self.gems) do
    local d2 = U.dist2(g.x, g.y, p.x, p.y)
    if g.magnet or d2 < mag2 then g.magnet = true; pull(g, p, dt) end
    if d2 < grab2 then
      g.dead = true
      self:gainXp(g.value)
    end
  end
  U.sweep(self.gems, function(g) return g.dead end)

  for _, k in ipairs(self.pickups) do
    local d2 = U.dist2(k.x, k.y, p.x, p.y)
    if k.kind == "brain" and (k.magnet or d2 < mag2) then k.magnet = true; pull(k, p, dt) end
    if d2 < (p.r + 14) ^ 2 then
      k.dead = true
      if k.kind == "brain" then
        self.brains = self.brains + math.max(1, math.floor(k.value * self.stats.greed + 0.5))
        Assets.playSfx("brain", 0.7)
      elseif k.kind == "food" then
        self.player.hp = math.min(self.stats.maxHp, self.player.hp + 30)
        self.fx:toast("Snack! +30 health", { 0.5, 1, 0.5 })
      elseif k.kind == "vinyl" then
        for _, g in ipairs(self.gems) do g.magnet = true end
        self.fx:toast("Vinyl! All XP incoming", { 0.8, 0.8, 1 })
      elseif k.kind == "chest" then
        local ready = LevelUp.evolutionsReady(self.weapons, self.passives)
        if #ready > 0 then self:evolve(ready[1].index)
        else
          self.pendingLevelUps = self.pendingLevelUps + 1
          self.brains = self.brains + 5
          self.fx:toast("Treasure! Free level up", { 1, 0.85, 0.3 })
        end
      end
    end
  end
  U.sweep(self.pickups, function(k) return k.dead end)
end

function World:updateRuins(dt)
  local p = self.player
  if not self.ruin then
    self.ruinTimer = self.ruinTimer - dt
    if self.ruinTimer <= 0 then
      local a = math.random() * math.pi * 2
      local d = 1200 + math.random() * 600
      self.ruin = { x = p.x + math.cos(a) * d, y = p.y + math.sin(a) * d }
      self.fx:toast("A ruin has been sighted...", { 0.9, 0.8, 0.6 })
    end
  elseif U.dist2(self.ruin.x, self.ruin.y, p.x, p.y) < 50 * 50 then
    self.ruin = nil
    self.ruinTimer = 120
    self.ruinsFound = self.ruinsFound + 1
    local reward = math.floor(20 * self.stats.greed)
    self.brains = self.brains + reward
    p.hp = math.min(self.stats.maxHp, p.hp + self.stats.maxHp * 0.3)
    self.fx:toast(("Ancient ruin explored! +%d brains"):format(reward), { 1, 0.85, 0.5 })
  end
end

function World:update(dt)
  dt = math.min(dt, 1 / 20)
  self.music:update(dt)
  local a, b = self.conductor:advance(self.music:time())
  if a then for step = a, b do self:onStep(step) end end
  self.beatPulse = math.max(0, self.beatPulse - dt * 4)
  for _, w in ipairs(self.weapons) do w.pulse = math.max(0, (w.pulse or 0) - dt * 6) end

  local p = self.player
  if self.finished then
    self.endingT = self.endingT + dt
  else
    self.time = self.time + dt
    local mx, my = Input.moveVector()
    p.moving = mx ~= 0 or my ~= 0
    if p.moving then
      p.x, p.y = p.x + mx * self.stats.moveSpeed * dt, p.y + my * self.stats.moveSpeed * dt
      p.faceX, p.faceY = U.norm(mx, my)
    end
    p.iframes = math.max(0, p.iframes - dt)
    p.hurt = math.max(0, p.hurt - dt)
    if self.stats.recovery > 0 then p.hp = math.min(self.stats.maxHp, p.hp + self.stats.recovery * dt) end
  end

  self.spatial:clear()
  for _, e in ipairs(self.enemies) do if not e.dead then self.spatial:insert(e) end end

  self:updateEnemies(dt)
  U.sweep(self.enemies, function(e) return e.dead end)
  self:updateProjectiles(dt)
  if not self.finished then
    self:updatePickups(dt)
    self:updateRuins(dt)
  end
  self.fx:update(dt)
end

function World:destroy()
  self.music:stop()
end

return World
