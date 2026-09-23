# Dance Zombies: Handover Guide

This guide is for whoever picks up the project next (probably you, with your own music and
art). It assumes no prior knowledge of the codebase.

- [1. Get it running](#1-get-it-running)
- [2. Tour of the project](#2-tour-of-the-project)
- [3. How the music drives the game](#3-how-the-music-drives-the-game)
- [4. Adding your own song](#4-adding-your-own-song)
- [5. Adding a new stage](#5-adding-a-new-stage)
- [6. Adding art (sprites)](#6-adding-art-sprites)
- [7. Adding sound effects and a font](#7-adding-sound-effects-and-a-font)
- [8. Adding and tuning content](#8-adding-and-tuning-content)
- [9. Testing your changes](#9-testing-your-changes)
- [10. Shipping a build](#10-shipping-a-build)
- [11. Working with Claude Code on this project](#11-working-with-claude-code-on-this-project)
- [12. Troubleshooting](#12-troubleshooting)

---

## 1. Get it running

1. Install **LÖVE 11.5** from https://love2d.org (Windows installer, macOS app, or
   `sudo apt install love` / your package manager on Linux).
2. Clone the repo and run it from the project folder:
   ```bash
   love .
   ```
   On Windows you can also drag the project folder onto `love.exe`.
3. Optional, for running the unit tests: install **LuaJIT** (`brew install luajit`,
   `apt install luajit`, or use `lua5.1`), then run `luajit tests/run.lua`.

A good editor setup is VS Code with the "Lua" extension (sumneko) and the "Love2D Support"
extension.

## 2. Tour of the project

```
main.lua / conf.lua     entry point and window config
src/core/               clock (conductor), patterns, save, input, asset loader
src/audio/              music player, placeholder synth, song loader
src/data/               <- ALL the numbers: weapons, zombies, stages, upgrades, achievements
src/game/               the simulation (world, weapon behaviours, spawner, rendering)
src/states/             screens: title, select, shop, options, play, results...
src/ui/                 HUD and menus
assets/songs/<id>/      one folder per song: song.lua + your audio stems
assets/sprites/         your PNGs (optional, placeholders are used when missing)
assets/sfx/             your sound effects (optional)
assets/fonts/main.ttf   your font (optional)
docs/adr/               why things are built the way they are
tests/                  unit tests
tools/autotest.lua      a bot that plays the game for automated checks
```

Most of your day-to-day changes will be in **`assets/`** and **`src/data/`**.

## 3. How the music drives the game

The one idea to understand before changing anything:

1. Every stage has **one song**, split into **stems**: `bed` (always audible), `drums`,
   `perc` (hi-hats), `bass`, `guitar`, `keys` and `lead`.
2. All stems start together and loop forever. Stems for weapons you don't have yet are
   playing **at volume 0**.
3. Each weapon is tied to one stem:

   | Weapon | Track | Evolves with | Evolution |
   |---|---|---|---|
   | Crossbow | drums | Echo Pedal | Drumline Ballista |
   | Hi-Hat Blades | perc | Running Shoes | Blast Beat |
   | Bass Cannon | bass | Armor Vest | Sub Drop |
   | Shotgun | guitar | Amplifier | Wall of Sound |
   | Molotov | keys | Protein Shake | Mosh Pit |
   | Lightning Mic | lead | Magnet | Feedback Storm |

4. When you pick up a weapon, its stem fades in. **That's the "new track joins the song"
   moment.**
5. Each stem has a **pattern** in `song.lua` that says where its hits are. The weapon fires
   on those hits. The game reads the time from the audio that's actually playing, so the
   attacks stay locked to what you hear.

In a run, the panel at the bottom of the screen (the "rhythm lanes") shows each weapon's
pattern for the current bar. Bright cells are hits it fires on, dim cells are hits it will
unlock at higher levels, and the white line is the playhead.

## 4. Adding your own song

### 4.1 Make the stems

In your DAW:

1. Write the song at a **constant BPM** (no tempo changes).
2. Make a section that **loops seamlessly**. The whole song can be the loop (a 2–3 minute
   loop is great), or it can be shorter.
3. Export each instrument group as its own stem. **Every stem must have exactly the same
   length and start at exactly the same time**, so export them all from bar 1 to the loop end
   in one go. Stems you don't need can be silent files.

   | Stem file | What goes in it | Plays when |
   |---|---|---|
   | `bed.ogg` | pads/ambience/anything that should always play | always |
   | `drums.ogg` | kick + snare | player has the Crossbow |
   | `perc.ogg` | hi-hats, shakers | Hi-Hat Blades |
   | `bass.ogg` | bass | Bass Cannon |
   | `guitar.ogg` | guitars | Shotgun |
   | `keys.ogg` | keys/chords/organ | Molotov |
   | `lead.ogg` | lead synth / vocal hook | Lightning Mic |

4. Format: **Ogg Vorbis (`.ogg`)** is best (small, streams well). `.wav`, `.mp3` and
   `.flac` also work. 44.1 kHz stereo is fine.
5. Keep the first downbeat at the very start of the file. If it's not (e.g. a pickup note),
   set `offset` in song.lua to the number of seconds before beat 1.
6. Mix tip: with 0 weapons the player only hears `bed`, and every weapon adds one stem, so
   make sure each partial combination still sounds good. Starting characters bring their
   stem in immediately (the Roadie starts with drums).

### 4.2 Create the song folder

Copy an existing folder, e.g. `assets/songs/graveyard_groove/`, to
`assets/songs/my_song/`, put your `.ogg` stems in it, and edit `song.lua`:

```lua
return {
  title = "My Song",
  artist = "Me",
  bpm = 124,             -- must match your DAW exactly (decimals are fine, e.g. 123.5)
  stepsPerBeat = 4,      -- 4 = 16th-note grid. Use 3 or 6 for triplet/shuffle feels.
  offset = 0.0,          -- seconds before beat 1 in the files
  bars = 4,              -- only used by the placeholder synth

  synth = { chords = { "Am", "F", "C", "G" } },  -- only used for missing stems

  tracks = {
    bed    = { file = "bed.ogg", volume = 0.7 },
    drums  = { file = "drums.ogg",  pattern = "X...x...X...x..." },
    perc   = { file = "perc.ogg",   pattern = "x.X.x.X.x.X.x.X." },
    bass   = { file = "bass.ogg",   pattern = "X.....x...X....." },
    guitar = { file = "guitar.ogg", pattern = "X.......X..x...." },
    keys   = { file = "keys.ogg",   pattern = "X...............|........x......." },
    lead   = { file = "lead.ogg",   pattern = "..X...x...X..o.." },
  },
}
```

You can swap stems in one at a time. Any stem whose `file` doesn't exist is still generated
by the placeholder synth.

### 4.3 Write the patterns

A pattern is one character per 16th note (with `stepsPerBeat = 4`), so **16 characters =
one bar of 4/4**. Spaces and `|` are ignored, so use them to separate bars.

| Char | Meaning |
|---|---|
| `X` | Strong hit. The weapon fires here from **level 1**. |
| `x` | Medium hit. Fires from **level 3**. |
| `o` | Ghost hit. Fires from **level 5**. |
| `.` | Rest. |

Evolved weapons fire on **every** `X`, `x` and `o`.

The pattern loops, so it can be any length: 1 bar, 2 bars, or the whole song. For a
3-minute song with a varied part, writing the full pattern gives the best feel. A 1–4 bar
repeating pattern is fine for a loop-based track.

Guidelines:

- Put the defining hits of the part on `X`. They're what the player feels at level 1.
- Use `x` and `o` for fills and ghost notes, so levelling up makes the weapon "play more of
  the part".
- Pattern density is weapon power. Two to four `X` per bar is a good start for single-target
  weapons. The Bass Cannon hits everything around you, so keep it sparser.
- Counting positions: in `"X...x...X...x..."` the characters are 1 e & a 2 e & a 3 e & a 4 e & a.

### 4.4 Check the sync in game

1. Start a run on your stage and press **F1** for the debug overlay (song time, step, offset).
2. Press **F2** to turn on a metronome click on every beat. It should sit exactly on your kick.
3. If the clicks are off, check `bpm` and `offset` in song.lua.
4. If clicks and music agree but the attacks feel early or late, that's your audio output
   latency. Use **Options → Calibrate** (tap along), or nudge with **`[`** and **`]`**
   during a run (±5 ms, not saved), then set the value in Options.
5. Use **F4** (with F1 on) to level up quickly and check each weapon's pattern.

## 5. Adding a new stage

1. Add the song folder (section 4).
2. Add an entry in `src/data/stages.lua`:
   ```lua
   S.subway = {
     name = "Subway Stomp", song = "my_song", unlock = "stage_subway",
     desc = "Mind the gap.",
     ground = { 0.12, 0.12, 0.14 }, detail = { 0.2, 0.2, 0.24 },
   }
   ```
   and add `"subway"` to `S.ORDER`.
3. Make it unlockable by adding `"stage_subway"` to some achievement's `unlocks` list in
   `src/data/achievements.lua`, or leave `unlock` out to make it available from the start.
4. Optional: `assets/sprites/decor_subway.png` replaces the scattered ground decorations.

## 6. Adding art (sprites)

Drop PNG files into `assets/sprites/` with the names below. There's no code to change. Any
file that's missing falls back to the placeholder shape.

- **Sprites are drawn centred** and scaled to the size given below, so the source resolution
  doesn't matter. Keep it consistent: square canvases, e.g. 32x32 or 64x64.
- Scaling uses nearest-neighbour filtering (crisp pixel art). For smooth, painted art, change
  `setFilter("nearest", "nearest")` to `"linear"` in `src/core/assets.lua`.
- Characters and zombies should **face right**. They're flipped automatically when facing left.
- Projectile sprites should **point right**. They're rotated to their direction of travel.

| File name | What | Drawn size (px, in a 960x540 view) |
|---|---|---|
| `player.png` | fallback for all characters | ~34 |
| `player_roadie.png`, `player_bassist.png`, `player_shredder.png`, `player_drummer.png` | per-character | ~34 |
| `player_zombie.png` | the player after the 10,000-kill ending | ~34 |
| `zombie_shambler.png` | basic zombie | ~29 |
| `zombie_runner.png` | fast zombie | ~23 |
| `zombie_bloater.png` | fat zombie | ~44 |
| `zombie_brute.png` | tank zombie | ~55 |
| `zombie_big_daddy.png` | boss (every 1,000 kills) | ~99 |
| `gem_small.png`, `gem_medium.png`, `gem_large.png` | XP gems (1 / 5 / 20+ xp) | 13 / 17 / 20 |
| `pickup_brain.png` | rotting brain (meta currency) | 20 |
| `pickup_food.png` | heal item | 20 |
| `pickup_vinyl.png` | vacuums every XP gem | 20 |
| `pickup_chest.png` | boss treasure | 32 |
| `proj_bolt.png` | crossbow bolt (points right) | ~25 |
| `proj_pellet.png` | shotgun pellet | ~10 |
| `proj_molotov.png` | thrown bottle (spins) | 14 |
| `fx_slash.png` | hi-hat blade slash (faces right) | the slash width |
| `fx_fire.png` | molotov fire pool | the pool diameter |
| `ruin.png` | explorable ruin | 80 |
| `decor_graveyard.png`, `decor_mall.png`, `decor_highway.png` | ground decorations per stage | 32 |
| `icon_<weapon id>.png` | HUD weapon icons, e.g. `icon_crossbow.png`, `icon_drumline_ballista.png` | 22 |
| `icon_<passive id>.png` | HUD passive icons, e.g. `icon_magnet.png` | 18 |

Weapon ids: `crossbow shotgun bass_cannon hihat_blades molotov lightning_mic` and evolutions
`drumline_ballista wall_of_sound sub_drop blast_beat mosh_pit feedback_storm`.
Passive ids: `protein_shake running_shoes magnet amplifier armor_vest echo_pedal heart lucky_pick`.

If you want to adjust a size, the numbers are in `src/game/render.lua` (look for
`Assets.drawSprite`). Want animation? The simplest route is a sprite sheet with a
`love.graphics.newQuad` per frame, advanced by the conductor's beat, so zombies can
literally dance on the beat. Add it in `Assets` and keep the fallback.

## 7. Adding sound effects and a font

Put files in `assets/sfx/` as `.ogg`, `.wav` or `.mp3`:

| Name | When |
|---|---|
| `levelup` | player levels up |
| `evolve` | a weapon evolves |
| `hurt` | player takes damage |
| `brain` | rotting brain collected |
| `menu_move` / `menu_select` | menu navigation |

Weapons deliberately have **no SFX**: the music *is* the weapon sound. If you add hit
sounds, keep them short and quiet, and ideally tuned to the song's key.

For a custom font, put a TrueType file at `assets/fonts/main.ttf`.

## 8. Adding and tuning content

All in `src/data/`. Every file is commented.

- **Balance a weapon**: `weapons.lua` → `stats` (level 1) and `levels[n]` (what each level adds).
- **New weapon**: copy an entry, give it a `track`, reuse a `behaviour` (`bolt`, `spread`,
  `pulse`, `slash`, `molotov`, `lightning`), and add its id to `W.POOL`. For a new behaviour,
  add a function to `src/game/behaviours.lua`. If it needs a new track, add that stem and
  pattern to every song (the tests check this).
- **New passive**: `passives.lua`. The `stat` must be one of the keys in
  `src/game/stats.lua` `BASE`.
- **New character**: `characters.lua` plus an unlock (`character_<id>`) in an achievement.
- **New zombie**: `enemies.lua` (`from` = kill count it starts appearing at, `weight` = how
  common it is), add it to `E.ORDER`, and optionally add a `zombie_<id>.png` sprite.
- **Pacing / difficulty**: `src/game/spawner.lua` (`targetCount`, `hpScale`, horde frequency)
  and `World:xpForLevel` in `src/game/world.lua`.
- **Kill target**: `Stages.KILLS_TO_WIN` in `stages.lua`.
- **Shop upgrades**: `meta_upgrades.lua` (cost = `base * (rank + 1)`).
- **Achievements and unlocks**: `achievements.lua`. `test(ctx)` gets `ctx.run` (this run) and
  `ctx.stats` (lifetime). Unlock ids are `character_<id>`, `weapon_<id>` (only Molotov and
  Lightning Mic are locked by default, see `World.new`), `stage_<id>` and `mode_<id>`.

## 9. Testing your changes

```bash
luajit tests/run.lua    # checks songs, patterns, evolutions, stats, save format...
```

On Linux (or WSL) you can run the game with a bot:

```bash
love . --autotest 60 --shots                  # 60 s bot run with screenshots
love . --autotest 600 --speed 10              # fast-forward 10 minutes (works when there's no audio device)
love . --autotest 9 --kills 9999 --shots      # see the ending
love . --autotest 5 --shots --menus           # screenshots of every menu
```

Screenshots go to the LÖVE save folder (see below) under `autotest/`. The bot never touches
your real save.

In-game developer keys: **F1** debug overlay; with it on, **F3** +1000 kills, **F4** level
up, **F5** full heal. **F2** metronome, **`[` / `]`** audio offset, **F11** fullscreen.

Save file location (delete it to reset, or use Options → Reset progress):
- Windows: `%APPDATA%\LOVE\dance-zombies\save.lua`
- macOS: `~/Library/Application Support/LOVE/dance-zombies/save.lua`
- Linux: `~/.local/share/love/dance-zombies/save.lua`

## 10. Shipping a build

A `.love` file is just a zip of the project:

```bash
zip -9 -r DanceZombies.love . -x ".git/*" "docs/*" "tests/*" "tools/*"
```

(`tools/autotest.lua` is only loaded with `--autotest`, so it's safe to leave out.)

- **Windows**: `copy /b love.exe+DanceZombies.love DanceZombies.exe`, then ship it with the
  DLLs from the LÖVE folder.
- **macOS**: put the `.love` inside `love.app/Contents/Resources/` and edit `Info.plist`.
- Full instructions: https://love2d.org/wiki/Game_Distribution. The
  [love-release](https://github.com/MisterDA/love-release) tool or
  [makelove](https://github.com/pfirsich/makelove) can automate this.

Before release: change `t.identity` in `conf.lua` only if you want a fresh save folder, and
make sure you have the rights to every asset you ship.

## 11. Working with Claude Code on this project

`CLAUDE.md` at the repo root is loaded automatically by Claude Code. It holds the project map,
commands and the rules that keep the rhythm system intact. Useful habits:

- Ask for changes in terms of the data files ("make the shotgun weaker at level 1", "add a
  new zombie that spawns after 6,000 kills").
- Ask Claude to run `luajit tests/run.lua` and the autotest after changes.
- For big design changes, ask for a new ADR in `docs/adr/` (there's a template).
- Keep `CLAUDE.md` up to date when you add folders or conventions.

## 12. Troubleshooting

| Problem | Fix |
|---|---|
| "song X is invalid" error on start | A pattern has a character other than `X x o . \| space`, or a track is missing its pattern. The message says which. |
| Attacks drift out of time after a while | `bpm` in song.lua doesn't exactly match the audio. Check the DAW tempo, including decimals. |
| Everything is consistently early/late | Output latency. Use Options → Calibrate, or set `offset` if the file has lead-in silence. |
| New stem comes in out of sync | Stems aren't the same length or weren't exported from the same start point. |
| A weapon never fires | Its track's pattern has no `X`, or the song has no stem for its track (it then falls back to the drums pattern; see the console). |
| Game runs but no sound | Check the OS output device and the Options volumes. The game keeps working on an internal clock without audio. |
| Sprite doesn't show | The file name must match exactly (lowercase, `.png`) and be in `assets/sprites/`. |
