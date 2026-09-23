# CLAUDE.md — Dance Zombies

Rhythm-driven Vampire-Survivors-like in **Lua + LÖVE 11.5** (no external libs). Every weapon
fires on the hits of one stem of the stage's song; picking up a weapon unmutes that stem.
Kill 10,000 zombies → you die and rise as a zombie. The owner makes the real music/art;
everything in the repo is placeholder (synth audio, primitive shapes).

Deeper docs: `docs/GUIDE.md` (human handover: assets, content, shipping) ·
`docs/adr/` (why things are built this way, read before touching core systems) ·
`docs/session-log.md` (creation session).

## Commands

```bash
luajit tests/run.lua                                   # unit tests, must stay green
love .                                                 # play
# Headless (cloud/CI): prefix with  SDL_AUDIODRIVER=dummy xvfb-run -a
love . --autotest 60 --shots                           # bot run + screenshots
love . --autotest 1800 --speed 15                      # full 30-min run fast-forwarded (a few min real time)
love . --autotest 9 --kills 9999 --shots               # the 10k ending
love . --autotest 5 --shots --menus                    # every menu screenshot
#   also: --stage graveyard|mall|highway  --character roadie|bassist|shredder|drummer
```
Screenshots → `~/.local/share/love/dance-zombies/autotest/` (copy to scratchpad, then Read to view).
Autotest never writes the real save (`Save.readonly`) and unlocks all weapons.

## Map

| Path | What |
|---|---|
| `main.lua` | 960x540 virtual screen (letterboxed), input dispatch, CLI flags |
| `src/core/` | `conductor` (time→16th steps), `pattern` (X/x/o), `serialize`, `save`, `settings`, `input`, `assets`, `util` |
| `src/audio/` | `music` (stems + smoothed audio clock), `synth` (placeholder stems from patterns), `songs` (load/validate) |
| `src/data/` | **All content & balance**: weapons, passives, characters, enemies, stages+modes, meta_upgrades, achievements |
| `src/game/` | `world` (owns a run), `behaviours` (bolt/spread/pulse/slash/molotov/lightning), `spawner`, `levelup`, `stats`, `spatial`, `fx`, `render`, `progress` |
| `src/states/` | title, select, shop, achievements, options, calibrate, play, results (`gamestate` = manager) |
| `src/ui/` | `hud` (incl. rhythm lanes), `menu`, `theme` |
| `assets/songs/<id>/song.lua` | bpm, offset, stems (`file`) + firing `pattern` per track |
| `tools/autotest.lua` · `tests/` | bot harness · unit tests (tiny in-repo runner) |

Weapon → track: crossbow→drums, hihat_blades→perc, bass_cannon→bass, shotgun→guitar,
molotov→keys, lightning_mic→lead. `bed` stem is always audible.

## Invariants (don't break)

1. Weapons fire only from the audio clock: `Music:time()` → `Conductor:advance()` → `World:onStep(step)`. No timers for rhythmic things. (ADR-0002)
2. All stems play all the time; locked ones sit at volume 0. Never start/stop a stem to add it. (ADR-0003)
3. Pattern contract: `X` lvl 1+, `x` lvl 3+, `o` lvl 5+, `.` rest; evolved = every hit. (ADR-0004)
4. Evolutions keep their base weapon's track; every song covers every pool track **and each has at least one `X`** (all tested).
5. Keep LÖVE-free: `src/core/{pattern,conductor,serialize,util}`, `src/game/{levelup,stats,spatial}`, `src/audio/songs`, `Synth.renderTrack`.
6. Sprite/sfx/font lookups go through `src/core/assets.lua` with a placeholder fallback. Asset names are a public contract listed in `docs/GUIDE.md` §6–7, so update the guide if you rename one.
7. Saves only via `Save.write()`; decode is sandboxed (empty env).

## Conventions

- Modules return tables; objects use `Thing.new()` + `Thing.__index`. 2-space indent, double quotes, `local` everything, `snake_case` data ids, `camelCase` code.
- Content/balance edits go in `src/data/` or `song.lua`, not logic files.
- New pure logic → unit test. Gameplay change → run the autotest and look at a screenshot.
- Big architectural change → new ADR from `docs/adr/template.md` (+ index in `docs/adr/README.md`).
- Don't put model names in commits/code.

## Environment gotchas

- Cloud container setup: `apt-get install -y love luajit xvfb`. dpkg reports a `love` post-install error (a missing man page), but `/usr/bin/love` works fine.
- No audio device in the container ("Could not open device"): the music clock falls back to `dt`, so audio **sync can't be verified here**. Only the owner can check it by ear (F1/F2 in game). `--speed` fast-forward is only valid without audio.
- `--kills` near 10k with a fresh level-1 character just dies to late-game hordes. Use `--kills 9999` to test the ending.
- The bot kites to within ~110px (so melee starters get kills); it prefers evolutions, then new weapons.

## Status (2026-09-23)

Playable end-to-end: 6 weapons + 6 evolutions, 8 passives, 4 characters, 4 zombie types + a
boss every 1,000 kills, 3 stages/songs, Hyper mode, brain shop, 9 achievements, ruins, and
the 10k ending. 29 unit tests pass. A bot completed a full Graveyard run in ~13.5 min of game time
(level 51, no evolutions).

Known gaps / likely next work:
- Audio sync untested by ear on real hardware. Gamepad untested on hardware.
- Runs are short (~13 min); pacing knobs are `Spawner:targetCount/hpScale` and `World:xpForLevel`.
- Evolutions are rare in practice (the bot never got one). Consider weighting the matching passive or showing evolution hints.
- No sprite animation (idea: frames advanced by the conductor beat), no weapon SFX (by design), no mid-run autosave (ADR-0007).
- Options aren't reachable from the pause menu; no CI workflow; no packaged builds yet.

## Dev keys (in game)

F1 debug overlay · F2 metronome click · `[` `]` audio offset ±5 ms · with F1 on: F3 +1000 kills,
F4 level up, F5 heal · F11 fullscreen.
