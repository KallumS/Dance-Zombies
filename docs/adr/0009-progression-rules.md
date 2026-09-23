# ADR-0009: Kill-count win condition, evolutions, brains and unlocks

- Status: Accepted
- Date: 2026-09-23

## Decision
- **No timer.** A run ends at `Stages.KILLS_TO_WIN = 10000` kills. The player collapses and
  rises as a zombie (ending sequence), earns a +100 brain bonus, and the completion
  achievement unlocks Highway to Hell and Hyper mode. Dying earlier ends the run normally.
- **Difficulty scales with kills**, not time: spawn target, zombie types (`from` in
  data/enemies.lua), HP multiplier, and a Big Daddy boss every 1,000 kills. Every 16 bars a
  ring horde surrounds the player. Spawns happen on beats, so the horde pulses with the song.
- **XP gems** drop from every zombie. Over 350 on the floor, extra XP is banked into the next
  gem you collect.
- **Level-ups** offer 3 choices (4 with high luck). Evolutions are always listed first when
  ready. **Evolution rule**: weapon at max level (8) and its `evolveWith` passive owned. Boss
  chests evolve an eligible weapon automatically, or otherwise give a free level-up.
- **Rotting brains** drop rarely (luck-scaled), come from ruins and achievements, and are
  spent in the Brain Shop on permanent stat ranks.
- **Ruins** spawn 1.2–1.8k px away (arrow on the HUD edge). Exploring one gives brains, heals,
  and counts towards the Archaeologist achievement.
- **Unlocks** come only from achievements (data/achievements.lua): characters, the Molotov and
  Lightning Mic weapons, stages and Hyper mode.

## Consequences
- Run length is set by kill speed. With the placeholder balance a strong run takes roughly
  25–35 minutes. Tune `Spawner` numbers and `xpForLevel` for pacing.
- New unlockable content = data entry + an achievement that grants its unlock id.
