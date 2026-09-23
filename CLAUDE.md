# CLAUDE.md — Dance Zombies

Rhythm-driven Vampire-Survivors-like. Every weapon attack is synced to a stem of the
stage's song; picking up a weapon unmutes that stem. Kill 10,000 zombies to "win" (you die
and become a zombie). Built with **Lua + LÖVE 11.5**.

## Commands

```bash
love .                                   # play (needs LÖVE 11.x installed)
luajit tests/run.lua                     # unit tests for pure modules (must stay green)
SDL_AUDIODRIVER=dummy xvfb-run -a love . --autotest 60 --shots     # headless bot smoke test
SDL_AUDIODRIVER=dummy xvfb-run -a love . --autotest 600 --speed 10 # fast-forward 10 min
SDL_AUDIODRIVER=dummy xvfb-run -a love . --autotest 9 --kills 9999 --shots   # test the ending
SDL_AUDIODRIVER=dummy xvfb-run -a love . --autotest 5 --shots --menus        # menu screenshots
```
Autotest screenshots land in `~/.local/share/love/dance-zombies/autotest/` (Linux save dir).
The autotest never writes the real save file (`Save.readonly`).

## Layout

| Path | What |
|---|---|
| `main.lua`, `conf.lua` | Entry point, 960x540 virtual screen letterboxed, input dispatch, CLI flags |
| `src/core/` | Engine-agnostic pieces: `conductor` (time -> steps), `pattern` (X/x/o parser), `serialize`, `save`, `settings`, `input`, `assets`, `util` |
| `src/audio/` | `music` (layered stems + audio-driven clock), `synth` (placeholder stem generator), `songs` (loader/validator) |
| `src/data/` | **All balance/content tables**: weapons, passives, characters, enemies, stages+modes, meta upgrades, achievements |
| `src/game/` | Run simulation: `world` (owns a run), `behaviours` (what each weapon does), `spawner`, `levelup` (choices/evolution rules), `stats`, `spatial` hash, `fx`, `render`, `progress` (run end -> save) |
| `src/states/` | Screens: title, select, shop, achievements, options, calibrate, play, results |
| `src/ui/` | `hud` (incl. rhythm lanes), `menu` widget, `theme` |
| `assets/songs/<id>/song.lua` | One folder per stage song: BPM, stems, firing patterns |
| `assets/sprites`, `assets/sfx`, `assets/fonts` | Optional art/audio; everything falls back to placeholders |
| `tools/autotest.lua` | Headless bot used by `--autotest` |
| `tests/` | `luajit tests/run.lua` |
| `docs/adr/` | Architecture decision records — read before changing core systems |
| `docs/GUIDE.md` | Human handover guide: adding songs, sprites, weapons, stages |

## Core invariants (don't break these)

1. **Weapons fire from the audio clock, never from timers.** `Music:time()` → `Conductor:advance()` → `World:onStep(step)`. See ADR-0002.
2. **All stems play all the time**; locked ones are at volume 0. Never start/stop a stem to "add" it. ADR-0003.
3. **The pattern string is the contract** between audio and gameplay: `X` level 1+, `x` level 3+, `o` level 5+, `.` rest; evolved weapons use every hit. ADR-0004.
4. Each weapon has a `track`; evolutions keep the same track (tested). Songs must provide every track used by `Weapons.POOL` (tested).
5. Modules in `src/core/pattern|conductor|serialize|util`, `src/game/levelup|stats|spatial`, `src/audio/songs` and `Synth.renderTrack` must stay **LÖVE-free** so tests run under plain LuaJIT.
6. Assets are optional: every sprite/sfx lookup goes through `src/core/assets.lua` and must have a placeholder fallback.
7. Save writes go through `Save.write()`; the save is sandboxed Lua (`serialize.decode` uses an empty env).

## Conventions

- Plain Lua modules returning tables; `Thing.new()` + `Thing.__index` for objects. No external libs.
- 2-space indent, double quotes, `local` everything, `snake_case` ids in data, `camelCase` fields/functions.
- Content changes go in `src/data/*.lua` or `song.lua`, not in logic files.
- Add a unit test for any new pure logic; run the autotest after gameplay changes.
- Record significant architecture changes as a new ADR in `docs/adr/` (copy `template.md`).

## Useful in-game dev keys

F1 debug overlay (FPS, song clock, step, offset) · F2 metronome click · `[` / `]` nudge audio offset ±5 ms ·
with F1 on: F3 +1000 kills, F4 instant level up, F5 full heal · F11 fullscreen.
