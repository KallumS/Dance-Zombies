# ADR-0002: Weapons are driven by an audio-derived clock through a Conductor

- Status: Accepted
- Date: 2026-09-23

## Context
The core promise is that attacks happen *in time with the music the player hears*. Game
timers (`dt` accumulation) drift away from the audio over a few minutes, and they ignore
hitches, loop points and audio-device latency.

## Decision
- `Music:time()` (src/audio/music.lua) is the single source of truth for song time. It is
  derived from the master stem's `Source:tell()`, loop-counted to stay monotonic, and
  **smoothed**: each frame we predict `clock + dt` and blend 10% towards the reported audio
  position (snapping if the error is over 150 ms). It never runs backwards.
- `Conductor` (src/core/conductor.lua, pure Lua) converts time to a 16th-note step index using
  `bpm`, `stepsPerBeat`, the song's `offset` and the user's calibrated `audioOffsetMs`.
  `advance(t)` returns every step crossed since the last frame (at most 4, so a long stall
  doesn't unload a burst of attacks).
- `World:onStep(step)` asks each weapon's pattern whether it fires on that step.
- Zombie lunges, the beat pulse and spawn waves also key off the conductor.
- An **Options → Calibrate** tap test measures output latency (Bluetooth can add 100 ms+).

## Alternatives considered
- Pure `dt` timers with the BPM: simple, but drift is guaranteed.
- Scheduling attacks ahead of time (look-ahead like WebAudio): unnecessary. Attacks are
  visual/gameplay events and ~1 frame of latency is imperceptible.

## Consequences
- If there's no audio device the clock falls back to `dt`, so the game still runs (used by
  the headless autotest).
- Attacks happen on the frame the step is crossed: up to ~16 ms late at 60 fps, which is
  inaudible.
- Anything rhythmic should use the conductor, never its own timer.
