# Dance Zombies

A Vampire Survivors-style horde shooter where **every attack lands on the beat**.

- Pick up a **Crossbow** and it fires on the drum hits. Grab a **Shotgun** and the guitars
  join the song, and the shotgun fires on the guitar stabs.
- Six weapons, six instruments: drums, hi-hats, bass, guitar, keys and lead.
- Level weapons up and they fire on more of the notes (medium hits at level 3, ghost notes at
  level 5). Max a weapon, own its matching passive, and it **evolves**.
- There's no timer. Kill **10,000 zombies** and the run ends: you die, and rise as one of them.
- Rotting brains carry over between runs and buy permanent upgrades. Achievements unlock
  characters, weapons, stages (each stage is a different song) and Hyper mode.

All art and music in this repo are placeholders (primitive shapes and a built-in synth).
See **[docs/GUIDE.md](docs/GUIDE.md)** to add your own.

## Running

1. Install [LÖVE 11.5](https://love2d.org/).
2. From this folder: `love .`

Controls: WASD / arrow keys / gamepad stick to move. Enter/Space/A to confirm, Esc/B to go
back or pause. F11 toggles fullscreen.

## Development

```bash
luajit tests/run.lua                                        # unit tests
SDL_AUDIODRIVER=dummy xvfb-run -a love . --autotest 60      # headless bot run (Linux)
```

- [CLAUDE.md](CLAUDE.md): project map and rules for AI assistants (also a handy quick reference)
- [docs/GUIDE.md](docs/GUIDE.md): handover guide for adding assets and content
- [docs/adr/](docs/adr/): architecture decision records
- [docs/session-log.md](docs/session-log.md): log of the session that created the project

Licensed under GPL-3.0 (see LICENSE).
