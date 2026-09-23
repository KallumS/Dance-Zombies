# ADR-0001: Lua + LÖVE 11.5 as the engine

- Status: Accepted
- Date: 2026-09-23

## Context
The game is fully 2D, has hundreds of on-screen enemies, needs tight audio timing, and will
be taken over by one person (the project owner) who makes the music and art. They proposed
Lua with LÖVE (Love2D) and asked for advice on alternatives.

## Decision
Use **LÖVE 11.5** with plain Lua (LuaJIT). No third-party Lua libraries.

## Alternatives considered
- **Godot 4**: excellent 2D tooling, an editor, and built-in `AudioStreamSynchronized` for
  stems. It's heavier to hand over as plain text, scenes are harder to review in git, and
  the owner asked for Lua.
- **Unity / FMOD**: best-in-class adaptive audio, but heavyweight, licensing overhead, and
  overkill for 2D primitives.
- **Defold** (Lua): good, but editor-centric and a smaller community for this genre.
- **Web (Phaser + WebAudio)**: sample-accurate scheduling is possible, but browser audio
  latency varies a lot and packaging for desktop/Steam is clunkier.

LÖVE gives us LuaJIT speed (hundreds of enemies are fine), `Source:tell()` for the audio
position (all the sync design needs), simple cross-platform packaging (`.love`, Windows exe,
macOS app), and a codebase that's just text files.

## Consequences
- No visual editor: levels are procedural, so this barely matters.
- Audio timing relies on `Source:tell()`, which updates in buffer-sized chunks. We smooth it
  (ADR-0002).
- Mobile builds are possible but fiddly with LÖVE. If mobile becomes a priority, revisit
  this (Godot would be the likely move).
