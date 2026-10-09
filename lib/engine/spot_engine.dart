import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/scenes.dart';
import '../theme/spot_themes.dart';

/// Engine-owned phases. The UI never drives transitions with its own timers —
/// every phase is entered AND settled by the engine on its own tick, and a
/// watchdog forces progress if any phase overruns. Stuck states are
/// impossible by construction.
enum SpotPhase {
  /// Boot phase before the first scene is laid out.
  idle,

  /// A quick "get ready" beat before the timer starts.
  showing,

  /// Player may tap the pictures.
  playing,

  /// A found difference is animating its reveal ring (never instant).
  revealing,

  /// Scene complete / time up — brief beat before the next scene.
  transitioning,

  /// Paused from the pause button or app lifecycle.
  paused,

  /// All scenes done (or quit). Holds the final score.
  finished,
}

/// Result of a tap, delivered to the UI for animation/sound.
class TapResult {
  final bool hit;
  final bool wasHinted;
  const TapResult({required this.hit, this.wasHinted = false});
}

/// The full state of one spot-the-difference session.
///
/// Deterministic: the scene order and the chosen differences are shuffled
/// with a seeded [Random], so daily challenges and replays are reproducible.
/// The engine owns the tick timer; the UI only renders and forwards taps.
class SpotEngine extends ChangeNotifier {
  SpotEngine({
    required this.mode,
    required this.difficulty,
    int? seed,
  }) : _rand = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  final GameMode mode;
  final DifficultyDef difficulty;
  final Random _rand;

  // ---- configuration derived from mode/difficulty ----
  late final int _diffCount =
      mode.id == 'daily' ? 5 : difficulty.diffCount;
  late final int _secondsPerScene =
      mode.id == 'zen' ? 0 : mode.id == 'blitz' ? 60 : difficulty.secondsPerScene;
  late final double _tapRadius =
      mode.id == 'daily' ? Difficulties.medium.tapRadius : difficulty.tapRadius;
  late final int _hintsPerScene =
      mode.id == 'daily' ? 2 : difficulty.hints;

  // ---- run state ----
  final List<SpotScene> _queue = [];
  final List<List<int>> _diffOrder = []; // per scene: chosen diff indices
  int sceneIdx = 0;
  final Set<int> found = {};

  /// The diff index currently animating its reveal (-1 = none).
  int lastFound = -1;
  SpotPhase phase = SpotPhase.idle;

  /// Animated reveal progress for the most recent find (0..1).
  double revealT = 0;

  /// Currently hinted diff index (-1 = none).
  int hintIdx = -1;

  /// Seconds left on the scene clock (0 = untimed/zen).
  double timeLeft = 0;
  int hintsLeft = 0;
  int score = 0;
  int totalFound = 0;
  int misses = 0;
  bool lastTickWarned = false;

  // pass & play
  int currentPlayer = 0; // 0 / 1
  final List<int> playerScores = [0, 0];

  // ---- engine-owned timer ----
  Timer? _tick;
  final Stopwatch _phaseClock = Stopwatch();

  int get sceneCount => _queue.length;
  SpotScene get scene => _queue[sceneIdx];
  List<int> get activeDiffs => _diffOrder[sceneIdx];
  int get foundCount => found.length;
  bool get isZen => mode.id == 'zen';
  bool get isPassPlay => mode.id == 'passplay';
  bool get timedOut => !isZen && timeLeft <= 0;

  // ---------------------------------------------------------------- start

  /// Builds the scene queue and enters the showing phase. Safe to call once.
  void start() {
    if (phase != SpotPhase.idle) return;
    _queue.addAll(_shuffledScenes());
    for (final s in _queue) {
      final idxs = [for (int i = 0; i < s.diffs.length; i++) i];
      idxs.shuffle(_rand);
      _diffOrder.add(idxs.take(_diffCount).toList()..sort());
    }
    _enterPhase(SpotPhase.showing);
    _startTick();
  }

  List<SpotScene> _shuffledScenes() {
    final scenes = List<SpotScene>.of(spotScenes)..shuffle(_rand);
    // Daily puzzle: a fixed 3-scene set. Blitz: 5. Others: all 8.
    final n = mode.id == 'daily' ? 3 : mode.id == 'blitz' ? 5 : spotScenes.length;
    return scenes.take(n).toList();
  }

  void _enterPhase(SpotPhase p) {
    phase = p;
    _phaseClock
      ..reset()
      ..start();
    notifyListeners();
  }

  // ---------------------------------------------------------------- tick

  /// The single engine-owned timer. All countdowns, animation progress and
  /// phase settlements happen here — never in UI timers.
  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick100());
  }

  void _tick100() {
    if (phase == SpotPhase.paused || phase == SpotPhase.finished || phase == SpotPhase.idle) {
      return;
    }
    // --- watchdog: no phase may overrun its budget ---
    final elapsed = _phaseClock.elapsedMilliseconds;
    switch (phase) {
      case SpotPhase.showing:
        if (elapsed >= 900) _beginPlay();
        return;
      case SpotPhase.revealing:
        revealT = (elapsed / 650).clamp(0.0, 1.0);
        if (elapsed >= 700) _settleReveal();
        notifyListeners();
        return;
      case SpotPhase.transitioning:
        if (elapsed >= 1100) _advanceScene();
        return;
      case SpotPhase.playing:
        break;
      default:
        return;
    }
    // --- playing: countdown + watchdog invariants ---
    if (!isZen) {
      timeLeft -= 0.1;
      lastTickWarned = timeLeft <= 10 && timeLeft > 0;
      if (timeLeft <= 0) {
        timeLeft = 0;
        _onTimeUp();
        return;
      }
    }
    // Hint auto-clears after 3 seconds.
    if (hintIdx >= 0 && _hintClock.elapsedMilliseconds > 3000) {
      hintIdx = -1;
    }
    notifyListeners();
  }

  final Stopwatch _hintClock = Stopwatch();

  void _beginPlay() {
    found.clear();
    hintIdx = -1;
    lastFound = -1;
    revealT = 0;
    timeLeft = _secondsPerScene.toDouble();
    hintsLeft = _hintsPerScene;
    _enterPhase(SpotPhase.playing);
  }

  // ---------------------------------------------------------------- taps

  /// A tap at normalized (0..1) coordinates on either panel.
  /// Both pictures accept taps — the player may tap the difference on the
  /// left OR the right picture.
  TapResult tap(double nx, double ny) {
    if (phase != SpotPhase.playing) return const TapResult(hit: false);
    final order = activeDiffs;
    for (final di in order) {
      if (found.contains(di)) continue;
      final df = scene.diffs[di];
      if (_hits(df, nx, ny)) {
        found.add(di);
        lastFound = di;
        totalFound++;
        hintIdx = -1;
        final pts = _pointsForFind();
        score += pts;
        if (isPassPlay) playerScores[currentPlayer] += pts;
        _enterPhase(SpotPhase.revealing);
        return TapResult(hit: true, wasHinted: false);
      }
    }
    // Miss.
    misses++;
    score = (score - 25).clamp(0, 1 << 30);
    if (isPassPlay) {
      currentPlayer = 1 - currentPlayer; // turn passes on a miss
    }
    notifyListeners();
    return const TapResult(hit: false);
  }

  bool _hits(SpotDiff df, double nx, double ny) {
    bool near(double x, double y) {
      final dx = x - nx, dy = y - ny;
      return dx * dx + dy * dy <= _tapRadius * _tapRadius;
    }

    if (near(df.x, df.y)) return true;
    if (df.kind == 0 && df.x2 >= 0 && near(df.x2, df.y2)) return true;
    return false;
  }

  int _pointsForFind() {
    if (isZen) return 100;
    final bonus = mode.id == 'blitz' ? 2 : 1;
    return (100 + timeLeft.round()) * bonus;
  }

  /// Settle the reveal animation: back to play, or complete the scene.
  /// Also the watchdog target — called early only by the watchdog.
  void _settleReveal() {
    if (phase != SpotPhase.revealing) return;
    revealT = 1;
    if (found.length >= activeDiffs.length) {
      if (!isZen) score += (timeLeft * 5).round();
      _enterPhase(SpotPhase.transitioning);
    } else {
      _enterPhase(SpotPhase.playing);
    }
  }

  // ---------------------------------------------------------------- hint

  bool get canHint => phase == SpotPhase.playing && hintsLeft > 0;

  void useHint() {
    if (!canHint) return;
    for (final di in activeDiffs) {
      if (!found.contains(di)) {
        hintIdx = di;
        hintsLeft--;
        _hintClock
          ..reset()
          ..start();
        notifyListeners();
        return;
      }
    }
  }

  // ---------------------------------------------------------------- flow

  void _onTimeUp() {
    _enterPhase(SpotPhase.transitioning);
  }

  void _advanceScene() {
    if (phase != SpotPhase.transitioning) return; // watchdog-safe
    if (sceneIdx + 1 >= _queue.length) {
      _enterPhase(SpotPhase.finished);
      _tick?.cancel();
      return;
    }
    sceneIdx++;
    _enterPhase(SpotPhase.showing);
  }

  /// Skip to the next scene (player gives up on this one).
  void skipScene() {
    if (phase != SpotPhase.playing && phase != SpotPhase.paused) return;
    if (phase == SpotPhase.paused) return;
    misses += activeDiffs.length - found.length;
    _enterPhase(SpotPhase.transitioning);
  }

  void pause() {
    if (phase == SpotPhase.playing) _enterPhase(SpotPhase.paused);
  }

  void resume() {
    if (phase == SpotPhase.paused) _enterPhase(SpotPhase.playing);
  }

  void quit() {
    _tick?.cancel();
    _enterPhase(SpotPhase.finished);
  }

  /// Stars earned (0..3) based on found ratio and misses.
  int get stars {
    final total = _diffOrder.fold<int>(0, (a, b) => a + b.length);
    if (total == 0) return 0;
    final ratio = totalFound / total;
    if (ratio >= 0.95 && misses <= total ~/ 4) return 3;
    if (ratio >= 0.7) return 2;
    if (ratio >= 0.4) return 1;
    return 0;
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}
