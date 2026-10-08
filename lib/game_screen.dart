import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

class _Spot {
  final double x, y, s;
  final String e;
  const _Spot(this.x, this.y, this.e, [this.s = 30]);
}

// kind: 0 moved (x2,y2 on right), 1 missing on right, 2 alt emoji on right
class _Diff {
  final double x, y, x2, y2, s;
  final String e;
  final String? alt;
  final int kind;
  const _Diff(this.x, this.y, this.e,
      {this.x2 = -1, this.y2 = -1, this.alt, this.kind = 0, this.s = 30});
}

class _Scene {
  final String name;
  final Color skyA, skyB, ground;
  final List<_Spot> common;
  final List<_Diff> diffs;
  const _Scene(this.name, this.skyA, this.skyB, this.ground, this.common, this.diffs);
}

_Spot _s(double x, double y, String e, [double sz = 30]) => _Spot(x, y, e, sz);
_Diff _d(double x, double y, String e, {double x2 = -1, double y2 = -1, String? alt, int kind = 0, double sz = 30}) =>
    _Diff(x, y, e, x2: x2, y2: y2, alt: alt, kind: kind, s: sz);

final List<_Scene> _scenes = [
  _Scene('Sunny Beach', Color(0xFF7EC8E3), Color(0xFFFFF3C4), Color(0xFFF2D998), [
    _s(.85, .14, '☀️', 44), _s(.2, .16, '☁️', 42), _s(.6, .1, '☁️', 32),
    _s(.12, .86, '🐚', 26), _s(.9, .88, '🐚', 24), _s(.5, .45, '🌊', 60),
  ], [
    _d(.32, .28, '🕊️', kind: 1),                       // seagull gone
    _d(.55, .72, '⛱️', x2: .72, y2: .68, sz: 40),        // umbrella moved
    _d(.25, .68, '🏐', alt: '⚽', sz: 34),                 // ball changed
    _d(.82, .62, '🦀', kind: 1),                          // crab gone
    _d(.68, .3, '⛵', kind: 1),                          // sailboat gone
  ]),
  _Scene('City Night', Color(0xFF1B2340), Color(0xFF3A2E5D), Color(0xFF2A2F45), [
    _s(.8, .15, '🌕', 46), _s(.15, .3, '🏙️', 70), _s(.5, .32, '🏙️', 60), _s(.85, .35, '🏙️', 66),
    _s(.3, .85, '🚕', 36), _s(.7, .85, '🚗', 34),
  ], [
    _d(.45, .12, '⭐', kind: 1),                          // star gone
    _d(.3, .85, '🚕', x2: .42, y2: .85, sz: 36),          // taxi moved
    _d(.62, .55, '🚦', alt: '🚥', sz: 34),                 // light changed
    _d(.15, .26, '🐈', kind: 1),                          // rooftop cat gone
    _d(.55, .6, '💡', kind: 1),                           // lamp glow gone
  ]),
  _Scene('Happy Farm', Color(0xFF9ADCFF), Color(0xFFE8F9FF), Color(0xFF9BDD6E), [
    _s(.15, .15, '☀️', 44), _s(.8, .12, '☁️', 40), _s(.3, .45, '🚜', 46),
    _s(.75, .5, '🐄', 44), _s(.1, .8, '🌻', 30), _s(.9, .82, '🌻', 30),
  ], [
    _d(.5, .2, '🐔', kind: 1),                            // chicken gone
    _d(.62, .78, '🌾', x2: .48, y2: .8, sz: 34),          // hay moved
    _d(.3, .45, '🚪', alt: '🪟', sz: 30),                  // door changed
    _d(.85, .68, '🐑', kind: 1, sz: 36),                  // sheep gone
    _d(.12, .4, '🏚️', kind: 1, sz: 40),                   // shed gone
  ]),
  _Scene('Outer Space', Color(0xFF0B0E2A), Color(0xFF2B1B4D), Color(0xFF141433), [
    _s(.2, .2, '🪐', 52), _s(.7, .6, '🌎', 44), _s(.4, .7, '🚀', 40),
    _s(.85, .15, '⭐', 24), _s(.5, .35, '⭐', 20),
  ], [
    _d(.1, .55, '⭐', kind: 1, sz: 22),                   // star gone
    _d(.2, .2, '🪐', x2: .28, y2: .3, sz: 52),            // planet moved
    _d(.4, .7, '🔥', alt: '💨', sz: 28),                   // flame changed
    _d(.62, .2, '🛸', kind: 1, sz: 40),                   // UFO gone
    _d(.88, .75, '🛰️', kind: 1, sz: 34),                 // satellite gone
  ]),
  _Scene('Deep Jungle', Color(0xFF7FDB8B), Color(0xFFD8F7B0), Color(0xFF4E9B47), [
    _s(.15, .4, '🌴', 64), _s(.85, .42, '🌴', 64), _s(.5, .7, '🐒', 44),
    _s(.3, .85, '🌺', 30), _s(.7, .85, '🌺', 30),
  ], [
    _d(.6, .25, '🦜', kind: 1, sz: 36),                   // parrot gone
    _d(.5, .7, '🐒', x2: .62, y2: .62, sz: 44),           // monkey moved
    _d(.3, .85, '🌺', alt: '🌸', sz: 30),                  // flower changed
    _d(.82, .78, '🐸', kind: 1, sz: 30),                  // frog gone
    _d(.45, .4, '🍌', kind: 1, sz: 30),                   // banana gone
  ]),
  _Scene('Snowy Peaks', Color(0xFFBFE3FF), Color(0xFFFFFFFF), Color(0xFFEDF4FF), [
    _s(.25, .5, '🏔️', 90), _s(.75, .55, '🏔️', 80), _s(.5, .8, '⛄', 52),
    _s(.12, .75, '🌲', 44), _s(.88, .78, '🌲', 44),
  ], [
    _d(.5, .72, '🧣', kind: 1, sz: 28),                   // scarf gone
    _d(.12, .75, '🌲', x2: .2, y2: .8, sz: 44),           // pine moved
    _d(.5, .66, '🎩', alt: '🧢', sz: 30),                  // hat changed
    _d(.68, .85, '🐧', kind: 1, sz: 34),                  // penguin gone
    _d(.82, .15, '☁️', kind: 1, sz: 38),                  // cloud gone
  ]),
  _Scene('Sunny Desert', Color(0xFFFFD98E), Color(0xFFFFF3C9), Color(0xFFF0C46C), [
    _s(.85, .18, '☀️', 48), _s(.3, .55, '🌵', 56), _s(.7, .6, '🐪', 52),
    _s(.15, .6, '🔺', 60), _s(.5, .85, '🦂', 28),
  ], [
    _d(.55, .15, '🦅', kind: 1, sz: 32),                  // vulture gone
    _d(.3, .55, '🌵', x2: .42, y2: .6, sz: 56),          // cactus moved
    _d(.15, .6, '🚪', alt: '🕳️', sz: 28),                 // pyramid door changed
    _d(.88, .8, '🌪️', kind: 1, sz: 32),                  // tumbleweed gone
    _d(.62, .32, '🌴', kind: 1, sz: 40),                  // palm gone
  ]),
  _Scene('Under the Sea', Color(0xFF2E9BD6), Color(0xFF9FE0F5), Color(0xFF1E7FB5), [
    _s(.2, .3, '🐠', 36), _s(.7, .4, '🐟', 34), _s(.45, .75, '🪸', 52),
    _s(.85, .7, '🐙', 44), _s(.12, .78, '🦀', 32),
  ], [
    _d(.35, .5, '🫧', kind: 1, sz: 26),                   // bubbles gone
    _d(.6, .85, '⭐', x2: .72, y2: .82, sz: 30),          // starfish moved
    _d(.45, .75, '🪸', alt: '🪷', sz: 52),                 // coral changed
    _d(.78, .25, '🐴', kind: 1, sz: 34),                  // seahorse gone
    _d(.28, .88, '⚓', kind: 1, sz: 36),                  // anchor gone
  ]),
];

void _drawEmoji(Canvas c, String e, Offset o, double size) {
  if (e.isEmpty) return;
  final tp = TextPainter(
      text: TextSpan(text: e, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr)
    ..layout();
  tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
}

class _ScenePainter extends CustomPainter {
  final _Scene scene;
  final bool right;
  final Set<int> found;
  final int hintIdx;
  final double pulse;
  _ScenePainter(this.scene, this.right, this.found, this.hintIdx, this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16));
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
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.68, size.width, size.height * 0.32),
        Paint()..color = scene.ground);
    Offset p(double x, double y) => Offset(x * size.width, y * size.height);
    for (final it in scene.common) {
      _drawEmoji(canvas, it.e, p(it.x, it.y), it.s * size.width / 340);
    }
    for (int i = 0; i < scene.diffs.length; i++) {
      final df = scene.diffs[i];
      if (right) {
        if (df.kind == 1) continue;
        final pos = (df.kind == 0 && df.x2 >= 0) ? p(df.x2, df.y2) : p(df.x, df.y);
        _drawEmoji(canvas, df.kind == 2 ? (df.alt ?? df.e) : df.e,
            pos, df.s * size.width / 340);
      } else {
        _drawEmoji(canvas, df.e, p(df.x, df.y), df.s * size.width / 340);
      }
    }
    // found rings
    for (final i in found) {
      final df = scene.diffs[i];
      for (final pos in _ringPos(df, p)) {
        canvas.drawCircle(pos, 22, Paint()..color = const Color(0xFF4CAF50)..style = PaintingStyle.stroke..strokeWidth = 4);
      }
    }
    // hint pulse
    if (hintIdx >= 0 && !found.contains(hintIdx)) {
      final df = scene.diffs[hintIdx];
      for (final pos in _ringPos(df, p)) {
        canvas.drawCircle(
            pos,
            18 + 8 * pulse,
            Paint()
              ..color = const Color(0xFFFFC107).withValues(alpha: 0.9 - 0.5 * pulse)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5);
      }
    }
    canvas.restore();
  }

  List<Offset> _ringPos(_Diff df, Offset Function(double, double) p) {
    if (!right) return [p(df.x, df.y)];
    if (df.kind == 1) return [];
    if (df.kind == 0 && df.x2 >= 0) return [p(df.x2, df.y2)];
    return [p(df.x, df.y)];
  }

  @override
  bool shouldRepaint(covariant _ScenePainter o) =>
      o.found != found || o.hintIdx != hintIdx || o.pulse != pulse;
}

class FindTheDifferenceScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const FindTheDifferenceScreen({super.key, required this.players, required this.callbacks});

  @override
  State<FindTheDifferenceScreen> createState() => _FindTheDifferenceScreenState();
}

class _FindTheDifferenceScreenState extends State<FindTheDifferenceScreen>
    with SingleTickerProviderStateMixin {
  int sceneIdx = 0;
  final found = <int>{};
  int timeLeft = 90;
  int hintsLeft = 2;
  int hintIdx = -1;
  int score = 0;
  int totalFound = 0;
  bool over = false;
  bool advancing = false;
  Timer? timer;
  late AnimationController pulseCtl;

  _Scene get scene => _scenes[sceneIdx];

  @override
  void initState() {
    super.initState();
    pulseCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    pulseCtl.addListener(() => setState(() {}));
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || over) return;
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) _nextScene(ranOut: true);
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    pulseCtl.dispose();
    super.dispose();
  }

  void _tapPanel(TapDownDetails det, Size sz) {
    if (over || advancing) return;
    final nx = det.localPosition.dx / sz.width;
    final ny = det.localPosition.dy / sz.height;
    for (int i = 0; i < scene.diffs.length; i++) {
      if (found.contains(i)) continue;
      final df = scene.diffs[i];
      final spots = [Offset(df.x, df.y)];
      if (df.kind == 0 && df.x2 >= 0) spots.add(Offset(df.x2, df.y2));
      for (final sp in spots) {
        if ((sp - Offset(nx, ny)).distance < 0.09) {
          setState(() {
            found.add(i);
            totalFound++;
            score += 100 + timeLeft;
            hintIdx = -1;
          });
          Sfx.move();
          if (found.length == scene.diffs.length) {
            score += timeLeft * 10;
            Sfx.win();
            _nextScene();
          }
          return;
        }
      }
    }
    Sfx.tap();
  }

  void _useHint() {
    if (hintsLeft <= 0 || over || advancing) return;
    final next = List.generate(scene.diffs.length, (i) => i)
        .firstWhere((i) => !found.contains(i), orElse: () => -1);
    if (next < 0) return;
    setState(() {
      hintsLeft--;
      hintIdx = next;
    });
    Sfx.click();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => hintIdx = -1);
    });
  }

  void _nextScene({bool ranOut = false}) {
    if (over) return;
    if (sceneIdx + 1 >= _scenes.length) {
      over = true;
      timer?.cancel();
      widget.players.first.score = score;
      widget.callbacks.finish(
          headline: 'You spotted $totalFound/40 differences!',
          subline: 'Score: $score — ${totalFound >= 35 ? 'eagle eyes! 🦅' : totalFound >= 20 ? 'sharp! 👀' : 'keep practicing! 🔍'}');
      return;
    }
    advancing = true;
    if (ranOut) Sfx.lose();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        sceneIdx++;
        found.clear();
        timeLeft = 90;
        hintsLeft = 2;
        hintIdx = -1;
        advancing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context).theme;
    Widget panel(bool right) => Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final sz = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onTapDown: (det) => _tapPanel(det, sz),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(
                    painter: _ScenePainter(
                        scene, right, found, hintIdx, pulseCtl.value),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _stat(theme, '⏱️', '$timeLeft s', timeLeft <= 10),
                const SizedBox(width: 8),
                _stat(theme, '🎯', '${found.length}/5', false),
                const SizedBox(width: 8),
                _stat(theme, '⭐', '$score', false),
                const Spacer(),
                GestureDetector(
                  onTap: hintsLeft > 0 ? _useHint : () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: hintsLeft > 0 ? theme.accent : theme.surface,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('💡 $hintsLeft',
                        style: TextStyle(
                            color: theme.text, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Scene ${sceneIdx + 1}/8 — ${scene.name}',
                style: TextStyle(
                    color: theme.text, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            panel(false),
            const SizedBox(height: 8),
            panel(true),
          ],
        ),
      ),
    );
  }

  Widget _stat(GameTheme theme, String emoji, String text, bool danger) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: theme.surface, borderRadius: BorderRadius.circular(12)),
        child: Text('$emoji $text',
            style: TextStyle(
                color: danger ? Colors.red : theme.text,
                fontWeight: FontWeight.bold)),
      );
}
