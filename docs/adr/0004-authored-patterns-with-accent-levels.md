# ADR-0004: Authored rhythm patterns (X/x/o) instead of beat detection

- Status: Accepted
- Date: 2026-09-23

## Context
Weapons must fire when their instrument plays. We could detect onsets in the audio, or have
the song author write down where the hits are.

## Decision
Each stem in `song.lua` has a **pattern string**, one character per 16th note, looping:

| char | meaning |
|---|---|
| `X` | strong hit, fires for weapon level 1+ |
| `x` | medium hit, fires for weapon level 3+ |
| `o` | ghost hit, fires for weapon level 5+ |
| `.` | rest |

Spaces and `|` are ignored, so patterns can be written bar by bar. Evolved weapons fire on
every hit. Hit strength also scales damage (X = 100%, x ≈ 88%, o ≈ 78%).

The placeholder synth renders its audio **from these same patterns**, so the placeholders are
in sync by construction. With real stems, the author writes the pattern to match their audio.

## Alternatives considered
- **Runtime onset/beat detection**: unreliable on dense mixes, adds latency, and makes game
  balance depend on the mix.
- **Offline analysis tool generating patterns**: possible later as a helper to draft
  patterns, but the authored pattern stays the source of truth.
- **MIDI files per stem**: more precise (arbitrary timing) but heavier tooling. Could be a
  future ADR if we need triplets/swing beyond a 16th grid (set `stepsPerBeat = 3` or `6` for
  triplet feels today).

## Consequences
- Balance is fully in the designer's hands: denser patterns make a stronger weapon.
- The music creator must keep the pattern and the audio consistent. The in-game F1/F2 tools
  (debug overlay + metronome) and the HUD rhythm lanes help check this.
- Leveling a weapon feels musical: it literally starts playing along with more of the notes.
