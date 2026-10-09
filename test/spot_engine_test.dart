import 'package:flutter_test/flutter_test.dart';
import 'package:findthedifference/engine/spot_engine.dart';
import 'package:findthedifference/theme/spot_themes.dart';

/// RULES.md §13 test cases for the SpotEngine state machine.
///
/// The engine owns a single 100ms tick; tests drive the public API and wait
/// out the (short) phase durations. Fixed seeds make everything deterministic.
SpotEngine makeEngine({int seed = 42}) {
  return SpotEngine(mode: GameMode.classic, difficulty: Difficulties.easy, seed: seed);
}

Future<void> waitForPhase(SpotEngine e, SpotPhase p,
    {Duration timeout = const Duration(seconds: 5)}) async {
  final end = DateTime.now().add(timeout);
  while (e.phase != p) {
    if (DateTime.now().isAfter(end)) break;
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  test('1. start: idle -> showing -> playing (watchdog advances phases)',
      () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    expect(e.phase, SpotPhase.idle);
    e.start();
    expect(e.phase, SpotPhase.showing);
    await waitForPhase(e, SpotPhase.playing);
    expect(e.phase, SpotPhase.playing);
    expect(e.timeLeft, greaterThan(0));
  });

  test('2. tap on an active difference: hit, found, reveal phase (never instant)',
      () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.start();
    await waitForPhase(e, SpotPhase.playing);
    final di = e.activeDiffs.first;
    final df = e.scene.diffs[di];
    final res = e.tap(df.x, df.y);
    expect(res.hit, isTrue);
    expect(e.found, contains(di));
    expect(e.phase, SpotPhase.revealing);
    expect(e.lastFound, di);
    // The reveal settles on the engine's own timer — no UI help needed.
    await waitForPhase(e, SpotPhase.playing);
    expect(e.phase, SpotPhase.playing); // differences remain: back to play
  });

  test('3. tap on empty picture: miss, -25 points (floored at 0)',
      () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.start();
    await waitForPhase(e, SpotPhase.playing);
    final before = e.misses;
    final res = e.tap(0.99, 0.01); // corner: no difference there
    expect(res.hit, isFalse);
    expect(e.misses, before + 1);
    expect(e.score, 0); // clamped, never negative
    expect(e.phase, SpotPhase.playing); // never stuck
  });

  test('4. hint marks an unfound difference and spends one hint', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.start();
    await waitForPhase(e, SpotPhase.playing);
    final hintsBefore = e.hintsLeft;
    expect(hintsBefore, greaterThan(0));
    e.useHint();
    expect(e.hintIdx, greaterThanOrEqualTo(0));
    expect(e.found, isNot(contains(e.hintIdx)));
    expect(e.hintsLeft, hintsBefore - 1);
  });

  test('5. same seed -> same scene queue and difference selection', () {
    final a = makeEngine(seed: 7);
    final b = makeEngine(seed: 7);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    a.start();
    b.start();
    expect(a.sceneCount, b.sceneCount);
    expect(a.activeDiffs, orderedEquals(b.activeDiffs));
  });

  test('6. skipScene advances and counts unfound diffs as misses', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.start();
    await waitForPhase(e, SpotPhase.playing);
    final missesBefore = e.misses;
    e.skipScene();
    expect(e.phase, SpotPhase.transitioning);
    await waitForPhase(e, SpotPhase.playing);
    expect(e.phase, SpotPhase.playing);
    expect(e.sceneIdx, 1);
    expect(e.misses, greaterThan(missesBefore));
  });

  test('7. quit finishes the run with a legal final state', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.start();
    await waitForPhase(e, SpotPhase.playing);
    e.quit();
    expect(e.phase, SpotPhase.finished);
    expect(e.stars, 0);
  });

  test('8. taps are ignored outside the playing phase', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.start(); // showing phase: taps must be ignored
    final res = e.tap(0.5, 0.5);
    expect(res.hit, isFalse);
    expect(e.misses, 0);
  });
}
