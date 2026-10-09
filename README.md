# Find the Difference

A cozy spot-the-difference puzzle game by WAJIHA.
Package: `com.gameswajiha.findthedifference`

## What it is

Two pictures side by side — ORIGINAL and CHANGED. Tap every difference
before the scene timer runs out. Taps work on EITHER picture.

- 8 hand-built scenes, 8 differences each
- 3 difficulty tiers (Easy / Medium / Hard — Hard is Pro)
- 5 modes: Classic (timed), Zen (relaxed, no timer), Blitz (fast, double
  points), Daily Puzzle (one seeded puzzle per day), Pass & Play (two humans,
  turn passes on a miss)
- Hints, animated find reveals, miss flashes, scene timers, star ratings
- 12 cozy themes + custom theme creator (Pro), 8 physical picture frames
- Renameable detective profiles (persisted as ONE order-preserving JSON
  string — never `setStringList`)
- Synthesized menu + gameplay music and full SFX, with toggles and volume
- Pro unlock + tip jar via real Play Billing:
  `findthedifferencepro`, `findthedifferencecoffee`,
  `findthedifferencechocolate` (create these in Play Console)

## Architecture

- `lib/engine/spot_engine.dart` — engine-owned phase state machine
  (idle → showing → playing → revealing → transitioning → finished, +
  paused) on a single 100ms tick; a watchdog budget forces every phase
  forward, so stuck states are impossible by construction. Deterministic:
  seeded random shuffles scene order and difference selection.
- `lib/data/scenes.dart` — the 8 hand-built scenes.
- `lib/theme/spot_themes.dart` — 12 themes, 8 frame styles, difficulties,
  game modes.
- `lib/screens/` — splash (company → game), menu, game, settings,
  custom theme creator, Pro.
- `lib/services/` — audio (cached synthesized WAVs, busy-guard, lifecycle
  pause/resume), settings/persistence, store (in_app_purchase).
- `RULES.md` — the authoritative game rules (13 sections).

## Build

Standard Flutter app. Android `applicationId` / `namespace`:
`com.gameswajiha.findthedifference`. `flutter analyze` must be clean and
`flutter test` must pass before push.

Credits: WAJIHA
