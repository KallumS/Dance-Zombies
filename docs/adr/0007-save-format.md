# ADR-0007: Save file is sandboxed serialized Lua, written at run end

- Status: Accepted
- Date: 2026-09-23

## Decision
- A single `save.lua` in LÖVE's save directory holds brains, meta upgrade ranks, unlocks,
  achievements, lifetime stats and settings.
- It's written with `src/core/serialize.lua` and read back with an **empty environment**,
  so a tampered file can't run code.
- On load, missing keys are filled from defaults, so adding a field needs no migration.
  `version` exists for future breaking changes.
- Run results are applied once, at run end (`src/game/progress.lua`), including when the
  player gives up from the pause menu. Shop purchases and settings save immediately.

## Consequences
- Quitting the app mid-run loses that run's brains (like Vampire Survivors). A mid-run
  autosave would be a new ADR.
- Save locations: Windows `%APPDATA%/LOVE/dance-zombies`, macOS
  `~/Library/Application Support/LOVE/dance-zombies`, Linux `~/.local/share/love/dance-zombies`.
