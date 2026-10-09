# Find the Difference — RULES.md

**Authoritative rules for `com.gameswajiha.findthedifference`.**
This document is the source of truth. The engine (`lib/engine/spot_engine.dart`)
enforces it exactly. If the implementation ever conflicts with this document,
fix the implementation.

---

## 1. Objective

Two pictures are shown side by side: the ORIGINAL and the CHANGED one.
Spot every difference hidden in the CHANGED picture before the scene timer
runs out. Tap the difference on EITHER picture — a tap anywhere on a real
difference (left or right panel) counts.

A run is a series of scenes. The player wins a run by finding differences
fast and accurately enough to earn at least 1 star.

## 2. Setup

- 8 hand-built scenes (Sunny Beach, City Night, Happy Farm, and 5 more),
  each with exactly 8 planted differences.
- A run builds a queue of scenes: Classic / Zen / Pass & Play use all 8
  (shuffled); Blitz uses 5; Daily Puzzle uses a fixed 3-scene set.
- The differences to find in a scene are chosen by difficulty (see §7) and
  shuffled with a seeded random — Daily Puzzle uses the date as the seed so
  everyone gets the same puzzle.
- Player picks a mode (Classic, Zen, Blitz, Daily Puzzle, Pass & Play) and a
  difficulty (Easy, Medium, Hard) before the run. Hard is a Pro feature.

## 3. Turn order

- Solo modes (Classic, Zen, Blitz, Daily): the single detective plays every
  scene.
- Pass & Play: two detectives share the phone. Player 1 starts each scene;
  on every MISS the turn passes to the other player; on a HIT the same
  player continues. Each player has their own score.

## 4. Legal moves

- Tap a real difference on EITHER the ORIGINAL or the CHANGED panel.
- Use a hint (💡) while in the `playing` phase and hints remain — the
  engine pulses a gold ring around one un-found difference for 3 seconds.
- Open the pause menu at any time during play: Resume, Restart scene,
  Skip scene, Quit to menu.
- Pause is also entered automatically when the app is backgrounded.

## 5. Illegal moves

- Taps are only accepted in the `playing` phase. Taps during `showing`
  (get-ready), `revealing` (a find is animating), `transitioning`,
  `paused` or `finished` are ignored.
- A hint cannot be used when no hints remain, or outside the `playing` phase.

## 6. Captures

Not applicable — this is a spotting game, not a capturing game.
Found differences are permanently circled with a green ring so they are
never counted twice. Tapping an already-found difference does nothing.

## 7. Special rules

- **Difference kinds:** a difference is one of (a) *moved* — drawn at a
  different spot on the right; (b) *missing* — drawn only on the left;
  (c) *changed* — drawn with a different look on the right.
- **Difficulty tiers:**
  - Easy: 4 differences per scene, 120s per scene, generous tap radius, 3 hints.
  - Medium: 6 differences per scene, 90s per scene, normal tap radius, 2 hints.
  - Hard (Pro): 8 differences per scene, 75s per scene, tight tap radius, 1 hint.
- **Modes:**
  - Classic: timed scenes, medium rules from the chosen difficulty.
  - Zen: NO timer — relax and look. Scoring is a flat 100 points per find.
  - Blitz: 60s per scene, 5 scenes, double points.
  - Daily Puzzle: fixed seeded 3-scene puzzle, Medium rules, 5 differences,
    2 hints — one shared puzzle per calendar day, best score saved per day.
  - Pass & Play: two humans, turn passes on a miss (see §3).
- **Hints:** a hinted difference still counts when found — no penalty
  beyond the spent hint.
- **Animated reveals:** a found difference never pops in instantly — a
  reveal ring expands over ~0.7s (smoothstep easing) before play continues.
- **Stuck states are impossible:** the engine owns its phases
  (idle → showing → playing → revealing → transitioning → finished, plus
  paused) on a single 100ms tick; a watchdog budget forces every phase
  forward. No phase can overrun.
- **Pause:** the pause button and app backgrounding both pause the engine;
  the scene timer halts. Resuming returns to the `playing` phase.

## 8. Scoring

- A found difference: `100 + seconds remaining` (×2 in Blitz). Zen: flat 100.
- A miss (tap on empty picture): −25 points, never below 0; miss counter +1.
- Scene fully cleared before the timer ends: time bonus `+5 × seconds left`.
- Skip scene: every unfound difference counts as a miss.

## 9. Winning conditions

- Stars (0–3) are computed from the whole run:
  - 3 stars: found ≥ 95% of differences AND misses ≤ 25% of differences.
  - 2 stars: found ≥ 70%.
  - 1 star: found ≥ 40%.
- 0 stars = the run was a loss. A run with ≥ 1 star counts as a win:
  the "Case Closed" result screen, stats recorded, victory sound.

## 10. Draw conditions

Not applicable — single-session scoring puzzle; every run ends won or lost.

## 11. AI strategy

There is no AI: Classic/Zen/Blitz/Daily are solo human play, Pass & Play
is two local humans taking turns. No bot moves are ever auto-played.

## 12. Edge cases

- A tap lands within the tap radius of two differences: the first matching
  difference in the active list counts (a tap is never a double hit).
- All differences found exactly as the timer hits zero: the reveal settles
  first — the clear counts, time bonus uses 0s left.
- Time runs out mid-reveal: reveal completes before the timeout settles.
- Last scene ends the run → `finished`; engine timer cancelled.
- Quitting from the pause menu ends the run immediately with current score.
- A hint active when a difference is found is cleared instantly.
- Miss flash (red X) fades after 0.45s and never blocks play.
- App backgrounded during `revealing`/`transitioning`/`showing`: phases
  settle on their own timers; only `playing` pauses.

## 13. Test cases

Covered in `test/spot_engine_test.dart` (CI runs them):

1. Engine starts `idle` → `start()` → `showing` → auto-advances to `playing`.
2. Tapping the exact spot of an active difference returns a hit, adds it to
   `found`, and enters `revealing` (never instant).
3. After the reveal animation settles (~0.7s) with differences remaining,
   the engine returns to `playing` — the game never gets stuck.
4. Tapping empty picture registers a miss: score −25 (floored at 0),
   misses +1, phase stays `playing`.
5. Hint: `useHint()` marks an un-found difference and spends one hint.
6. Same seed → same scene order and difference selection (deterministic).
7. `skipScene()` advances the queue and marks unfound diffs as misses.
8. Profile names survive an encode/decode round-trip in exact slot order
   (`test/settings_names_test.dart`) — regression for the Android
   `setStringList` order-scrambling bug; names are stored as ONE
   order-preserving JSON string via `setString`, key
   `findthedifference_player_names_json`.

Persistence keys (for reference): audio toggles `spot_music_on` /
`spot_sfx_on` / `spot_volume`; names as above; `spot_theme_id`,
`spot_frame_style`, `spot_difficulty`, `spot_mode`, `spot_is_pro`,
stats `spot_wins` / `spot_games_played` / `spot_best_score`,
daily bests `spot_daily_best_YYYY-MM-DD`, custom theme colors
`spot_custom_<slot>`.
