import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../data/scenes.dart';
import '../engine/spot_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/spot_themes.dart';

const String _storeUrl =
    'https://play.google.com/store/apps/details?id=com.gameswajiha.findthedifference';

void _drawEmoji(Canvas c, String e, Offset o, double size) {
  if (e.isEmpty) return;
  final tp = TextPainter(
      text: TextSpan(text: e, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr)
    ..layout();
  tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
}

/// Paints one picture of the scene pair: left = original, right = changed.
/// Found differences get green rings; the newest find animates an expanding
/// reveal ring driven by [revealT] (never instant); hints pulse gold.
class ScenePainter extends CustomPainter {
  final SpotScene scene;
  final bool right;
  final List<int> activeDiffs;
  final Set<int> found;
  final int hintIdx;
  final double pulse;
  final int lastFound;
  final double revealT;
  final Offset? missPos; // normalized
  final double missAge; // seconds since the miss

  ScenePainter({
    required this.scene,
    required this.right,
    required this.activeDiffs,
    required this.found,
    required this.hintIdx,
    required this.pulse,
    required this.lastFound,
    required this.revealT,
    this.missPos,
    required this.missAge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(14));
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRRect(
        r,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [scene.skyA, scene.skyB])
              .createShader(Offset.zero & size));
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.68, size.width, size.height * 0.32),
        Paint()..color = scene.ground);
    Offset p(double x, double y) => Offset(x * size.width, y * size.height);
    final scale = size.width / 340;
    for (final it in scene.common) {
      _drawEmoji(canvas, it.emoji, p(it.x, it.y), it.size * scale);
    }
    for (final di in activeDiffs) {
      final df = scene.diffs[di];
      if (right) {
        if (df.kind == 1) continue;
        final pos = (df.kind == 0 && df.x2 >= 0) ? p(df.x2, df.y2) : p(df.x, df.y);
        _drawEmoji(canvas, df.kind == 2 ? (df.alt ?? df.emoji) : df.emoji,
            pos, df.size * scale);
      } else {
        _drawEmoji(canvas, df.emoji, p(df.x, df.y), df.size * scale);
      }
    }
    // Permanent found rings.
    for (final di in found) {
      final df = scene.diffs[di];
      for (final pos in _ringPos(df, p)) {
        canvas.drawCircle(
            pos,
            20 * scale,
            Paint()
              ..color = const Color(0xFF7ED957)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4);
      }
    }
    // Animated reveal ring for the newest find (expands, never pops in).
    if (lastFound >= 0 && revealT > 0 && revealT < 1) {
      final df = scene.diffs[lastFound];
      final ease = (revealT * revealT * (3 - 2 * revealT)); // smoothstep
      for (final pos in _ringPos(df, p)) {
        canvas.drawCircle(
            pos,
            (8 + 34 * ease) * scale,
            Paint()
              ..color = Color.lerp(const Color(0xFFFFC93C),
                  const Color(0xFF7ED957), ease)!
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5);
      }
    }
    // Pulsing hint ring.
    if (hintIdx >= 0 && !found.contains(hintIdx)) {
      final df = scene.diffs[hintIdx];
      for (final pos in _ringPos(df, p)) {
        canvas.drawCircle(
            pos,
            (16 + 8 * pulse) * scale,
            Paint()
              ..color = const Color(0xFFFFC93C)
                  .withValues(alpha: 0.9 - 0.5 * pulse)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5);
      }
    }
    // Miss flash: fading red X at the tap point.
    if (missPos != null && missAge < 0.45) {
      final a = 1 - missAge / 0.45;
      final pos = Offset(missPos!.dx * size.width, missPos!.dy * size.height);
      final paint = Paint()
        ..color = Colors.redAccent.withValues(alpha: a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final d = 14 * scale;
      canvas.drawLine(pos + Offset(-d, -d), pos + Offset(d, d), paint);
      canvas.drawLine(pos + Offset(-d, d), pos + Offset(d, -d), paint);
    }
    canvas.restore();
  }

  List<Offset> _ringPos(SpotDiff df, Offset Function(double, double) p) {
    if (!right) return [p(df.x, df.y)];
    if (df.kind == 1) return [];
    if (df.kind == 0 && df.x2 >= 0) return [p(df.x2, df.y2)];
    return [p(df.x, df.y)];
  }

  @override
  bool shouldRepaint(covariant ScenePainter o) => true;
}

/// Physical beveled frame around each picture, from the chosen frame style.
class FramedPanel extends StatelessWidget {
  final Widget child;
  final FrameStyleDef frame;
  final String badge;
  const FramedPanel(
      {super.key, required this.child, required this.frame, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [frame.hi, frame.lo],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.12),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(7),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: child,
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final SpotAudio audio;
  final SpotSettings settings;
  final GameMode mode;
  final DifficultyDef difficulty;
  final String? dailyKey; // 'YYYY-MM-DD' for daily mode

  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.mode,
    required this.difficulty,
    this.dailyKey,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final SpotEngine engine;
  late final AnimationController _pulse;
  Offset? _missPos;
  DateTime? _missTime;
  bool _resultShown = false;
  SpotPhase _prevPhase = SpotPhase.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    final seed = widget.dailyKey == null
        ? null
        : int.tryParse(widget.dailyKey!.replaceAll('-', ''));
    engine = SpotEngine(
        mode: widget.mode, difficulty: widget.difficulty, seed: seed);
    engine.addListener(_onEngine);
    engine.start();
    widget.audio.startGameMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    engine.removeListener(_onEngine);
    engine.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      engine.pause();
    } else if (state == AppLifecycleState.resumed) {
      // Resume only if the pause came from the lifecycle, not the pause menu.
      // The pause menu keeps the engine paused until the user taps resume.
      if (_pauseMenuOpen) return;
      engine.resume();
    }
  }

  bool _pauseMenuOpen = false;

  void _onEngine() {
    // React to phase transitions: sounds + result handling.
    if (engine.phase != _prevPhase) {
      final was = _prevPhase;
      _prevPhase = engine.phase;
      if (engine.phase == SpotPhase.transitioning &&
          was == SpotPhase.revealing) {
        // Scene fully cleared.
        widget.audio.sceneDone();
      } else if (engine.phase == SpotPhase.transitioning &&
          was == SpotPhase.playing) {
        // Time ran out.
        widget.audio.lose();
      } else if (engine.phase == SpotPhase.finished) {
        _onFinished();
      }
    }
  }

  Future<void> _onFinished() async {
    if (_resultShown) return;
    _resultShown = true;
    final won = engine.stars >= 1;
    if (won) {
      widget.audio.win();
    } else {
      widget.audio.lose();
    }
    await widget.settings
        .recordGame(score: engine.score, won: won);
    if (widget.dailyKey != null) {
      await widget.settings.recordDaily(widget.dailyKey!, engine.score);
    }
    if (!mounted) return;
    _showResult(won);
    // In-app review at a sensible moment: every 3rd win, best effort.
    if (won && widget.settings.wins % 3 == 0) {
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        }
      } catch (_) {}
    }
  }

  void _tapPanel(TapDownDetails det, Size sz) {
    if (engine.phase != SpotPhase.playing) return;
    final nx = det.localPosition.dx / sz.width;
    final ny = det.localPosition.dy / sz.height;
    final res = engine.tap(nx, ny);
    if (res.hit) {
      widget.audio.found();
    } else {
      widget.audio.miss();
      setState(() {
        _missPos = Offset(nx, ny);
        _missTime = DateTime.now();
      });
    }
  }

  void _useHint() {
    if (!engine.canHint) return;
    engine.useHint();
    widget.audio.hint();
  }

  Future<void> _openPauseMenu() async {
    engine.pause();
    widget.audio.pauseSnd();
    _pauseMenuOpen = true;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final theme = _theme();
        return AlertDialog(
          backgroundColor: theme.card,
          title: Text('Paused', style: TextStyle(color: theme.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menuBtn('▶  Resume', () {
                Navigator.of(context).pop();
                _pauseMenuOpen = false;
                engine.resume();
                widget.audio.click();
              }),
              _menuBtn('🔁  Restart scene', () {
                Navigator.of(context).pop();
                _pauseMenuOpen = false;
                _restart();
              }),
              _menuBtn('⏭  Skip scene', () {
                Navigator.of(context).pop();
                _pauseMenuOpen = false;
                engine.resume();
                engine.skipScene();
                widget.audio.click();
              }),
              _menuBtn('🏠  Quit to menu', () {
                Navigator.of(context).pop();
                _pauseMenuOpen = false;
                engine.quit();
                widget.audio.click();
                widget.audio.startMenuMusic();
                Navigator.of(context).pop();
              }),
            ],
          ),
        );
      },
    );
  }

  void _restart() {
    final mode = widget.mode;
    final diff = widget.difficulty;
    final dailyKey = widget.dailyKey;
    engine.quit();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: widget.settings,
          mode: mode,
          difficulty: diff,
          dailyKey: dailyKey,
        ),
      ),
    );
  }

  SpotThemeDef _theme() => SpotThemes.byId(widget.settings.themeId,
      custom: widget.settings.customTheme);

  Widget _menuBtn(String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _theme().accent,
              foregroundColor: Colors.black87,
            ),
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      );

  void _showResult(bool won) {
    final theme = _theme();
    final stars = engine.stars;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: theme.card,
        title: Text(
          won ? 'Case Closed! 🔎' : 'Out of Time',
          style: TextStyle(color: theme.text, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⭐' * (stars == 0 ? 1 : stars) + '☆' * (3 - (stars == 0 ? 1 : stars)),
                style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text('Score: ${engine.score}',
                style: TextStyle(
                    color: theme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            Text('Differences found: ${engine.totalFound}',
                style: TextStyle(color: theme.textDim)),
            Text('Misses: ${engine.misses}',
                style: TextStyle(color: theme.textDim)),
            if (engine.isPassPlay)
              Text(
                '${widget.settings.names['p1']}: ${engine.playerScores[0]}  •  '
                '${widget.settings.names['p2']}: ${engine.playerScores[1]}',
                style: TextStyle(
                    color: theme.accent, fontWeight: FontWeight.w700),
              ),
            if (engine.score >= widget.settings.bestScore &&
                engine.score > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('🏆 New best score!',
                    style: TextStyle(
                        color: theme.accent, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.audio.click();
              Share.share(
                  'I just spotted ${engine.totalFound} differences and scored ${engine.score} in Find the Difference! Can you beat me? $_storeUrl');
            },
            child: Text('Share', style: TextStyle(color: theme.accent)),
          ),
          TextButton(
            onPressed: () {
              widget.audio.click();
              widget.audio.startMenuMusic();
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pop(); // game screen
            },
            child: Text('Menu', style: TextStyle(color: theme.accent)),
          ),
          ElevatedButton(
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
              _restart();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.accent,
                foregroundColor: Colors.black87),
            child: const Text('Play Again',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme();
    final frame = FrameStyles.byIndex(widget.settings.frameStyle);
    return ListenableBuilder(
      listenable: engine,
      builder: (_, _) {
        final missAge = _missTime == null
            ? 99.0
            : DateTime.now().difference(_missTime!).inMilliseconds / 1000;
        Widget panel(bool right) => Expanded(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final sz =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  return FramedPanel(
                    frame: frame,
                    badge: right ? 'CHANGED' : 'ORIGINAL',
                    child: GestureDetector(
                      onTapDown: (det) => _tapPanel(det, sz),
                      child: CustomPaint(
                        painter: ScenePainter(
                          scene: engine.scene,
                          right: right,
                          activeDiffs: engine.activeDiffs,
                          found: engine.found,
                          hintIdx: engine.hintIdx,
                          pulse: _pulse.value,
                          lastFound: engine.lastFound,
                          revealT: engine.revealT,
                          missPos: _missPos,
                          missAge: missAge,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  );
                },
              ),
            );

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.pageTop, theme.pageBottom],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _hud(theme),
                    const SizedBox(height: 8),
                    _sceneTitle(theme),
                    const SizedBox(height: 8),
                    panel(false),
                    const SizedBox(height: 10),
                    panel(true),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _hud(SpotThemeDef theme) {
    final e = engine;
    return Row(
      children: [
        _stat(theme, '⏱️', e.isZen ? '∞' : '${e.timeLeft.ceil()}s',
            !e.isZen && e.lastTickWarned),
        const SizedBox(width: 8),
        _stat(theme, '🎯', '${e.foundCount}/${e.activeDiffs.length}', false),
        const SizedBox(width: 8),
        _stat(theme, '⭐',
            e.isPassPlay ? '${e.playerScores[e.currentPlayer]}' : '${e.score}',
            false),
        const Spacer(),
        if (e.isPassPlay)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '👀 ${widget.settings.names[e.currentPlayer == 0 ? 'p1' : 'p2']}',
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.w800),
            ),
          ),
        GestureDetector(
          onTap: _useHint,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: e.canHint ? theme.accent : theme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.cardEdge),
            ),
            child: Text('💡 ${e.hintsLeft}',
                style: TextStyle(
                    color: e.canHint ? Colors.black87 : theme.textDim,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _openPauseMenu,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.cardEdge),
            ),
            child: Text('⏸', style: TextStyle(color: theme.text)),
          ),
        ),
      ],
    );
  }

  Widget _sceneTitle(SpotThemeDef theme) {
    final e = engine;
    var label = 'Scene ${e.sceneIdx + 1}/${e.sceneCount} — ${e.scene.name}';
    if (e.phase == SpotPhase.showing) label = 'Get ready… 🔎';
    if (e.phase == SpotPhase.transitioning) {
      label = e.foundCount >= e.activeDiffs.length
          ? 'Scene cleared! 🎉'
          : 'Time! The rest stay hidden…';
    }
    return Text(label,
        style: TextStyle(
            color: theme.text, fontWeight: FontWeight.bold, fontSize: 15));
  }

  Widget _stat(SpotThemeDef theme, String emoji, String text, bool danger) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.cardEdge),
        ),
        child: Text('$emoji $text',
            style: TextStyle(
                color: danger ? Colors.redAccent : theme.text,
                fontWeight: FontWeight.bold)),
      );
}
