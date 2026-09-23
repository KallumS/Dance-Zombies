# ADR-0008: Fixed 960x540 virtual resolution, letterboxed

- Status: Accepted
- Date: 2026-09-23

## Decision
All game and UI code draws in a 960x540 coordinate space. `main.lua` scales it uniformly to
the window and letterboxes the rest. The camera shows exactly 960x540 world pixels, so spawn
distances (just outside the view) are the same on every monitor.

## Consequences
- Ultrawide players don't see more of the field (fair, and simpler to balance).
- Pixel art should be authored for this scale. Scaling uses nearest-neighbour filtering.
