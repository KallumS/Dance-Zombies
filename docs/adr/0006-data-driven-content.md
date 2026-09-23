# ADR-0006: Content and balance live in plain Lua data tables

- Status: Accepted
- Date: 2026-09-23

## Context
Weapons, passives, zombies, stages, upgrades and achievements will be tuned constantly by a
non-specialist.

## Decision
All content lives in `src/data/*.lua` (and `assets/songs/*/song.lua`) as plain tables with
comments. Logic files only read them. Weapon behaviours are a small set of named functions
(`bolt`, `spread`, `pulse`, `slash`, `molotov`, `lightning`) that data refers to by name, so
a new weapon is often just a data entry reusing a behaviour.

## Alternatives considered
JSON/CSV files are friendlier to spreadsheets, but they lose comments and functions (e.g.
achievement tests), and you'd need a parser. Lua tables are already the natural format in LÖVE.

## Consequences
- Tests (`tests/test_levelup.lua`, `tests/test_songs.lua`) validate cross-references
  (evolution ids, tracks), so data typos are caught early.
- Achievement conditions are Lua functions, which is flexible but means they're code.
