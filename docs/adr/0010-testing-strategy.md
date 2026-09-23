# ADR-0010: Pure-Lua unit tests + headless autotest bot

- Status: Accepted
- Date: 2026-09-23

## Decision
- Timing, patterns, level-up rules, stats, serialization, song validation and the synth are
  pure Lua with no LÖVE dependency, and are unit-tested with `luajit tests/run.lua` (a tiny
  in-repo runner, no dependencies).
- Everything else is covered by `love . --autotest N`: a bot plays a real run, auto-picks
  level-ups, optionally fast-forwards (`--speed`), takes screenshots (`--shots`, `--menus`),
  and prints a report (kills, level, weapons, audible tracks, song clock). It runs headless
  with `SDL_AUDIODRIVER=dummy xvfb-run -a`.

## Consequences
- Keep new logic out of LÖVE-dependent files where you can, so it stays testable.
- The autotest can't judge "does it *sound* in time". That's a human check with F1/F2 in game.
