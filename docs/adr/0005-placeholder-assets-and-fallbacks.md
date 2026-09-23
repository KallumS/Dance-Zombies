# ADR-0005: Placeholder synth + primitive shapes with drop-in asset fallbacks

- Status: Accepted
- Date: 2026-09-23

## Context
The owner will make the final songs and art. The build must be fully playable now, and
swapping in real assets should need no code changes.

## Decision
- **Music**: if a stem's `file` is missing from the song folder, `src/audio/synth.lua` renders
  a placeholder from the pattern and the song's `synth.chords` (22.05 kHz mono, cached per
  session).
- **Graphics**: every draw call first tries `Assets.drawSprite(name, ...)`, which loads
  `assets/sprites/<name>.png` if it exists. Otherwise primitive shapes are drawn.
- **SFX**: `Assets.playSfx(name)` plays `assets/sfx/<name>.(ogg|wav|mp3)` if it exists,
  otherwise nothing.
- **Font**: `assets/fonts/main.ttf` replaces the default font if it exists.

## Consequences
- Assets can be added one at a time, and a missing asset never crashes the game.
- Sprite names are a public contract, listed in docs/GUIDE.md. Renaming one in code means
  updating the guide.
- Sprites are drawn centered and scaled to the gameplay size, so any source resolution works
  (square images look best).
