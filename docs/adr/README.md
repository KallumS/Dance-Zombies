# Architecture Decision Records

Each file records one significant decision: the context, what was decided, and the
consequences. When you change one of these decisions, don't edit history. Add a new ADR that
supersedes the old one and set the old one's status to "Superseded by ADR-XXXX".

| # | Decision | Status |
|---|---|---|
| [0001](0001-engine-lua-love2d.md) | Lua + LÖVE 11.5 as the engine | Accepted |
| [0002](0002-audio-clock-conductor.md) | Weapons are driven by an audio-derived clock through a Conductor | Accepted |
| [0003](0003-layered-stems-always-playing.md) | Songs are layered stems that always play; weapons unmute them | Accepted |
| [0004](0004-authored-patterns-with-accent-levels.md) | Authored rhythm patterns (X/x/o) instead of beat detection; weapon level unlocks accents | Accepted |
| [0005](0005-placeholder-assets-and-fallbacks.md) | Placeholder synth + primitive shapes with drop-in asset fallbacks | Accepted |
| [0006](0006-data-driven-content.md) | Content and balance live in plain Lua data tables | Accepted |
| [0007](0007-save-format.md) | Save file is sandboxed serialized Lua, written at run end | Accepted |
| [0008](0008-virtual-resolution.md) | Fixed 960x540 virtual resolution, letterboxed | Accepted |
| [0009](0009-progression-rules.md) | Kill-count win condition, evolutions, brains and unlocks | Accepted |
| [0010](0010-testing-strategy.md) | Pure-Lua unit tests + headless autotest bot | Accepted |

Use [template.md](template.md) for new records.
