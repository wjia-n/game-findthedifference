import 'package:flutter/material.dart';

/// A decorative item that is identical in both pictures.
class SpotItem {
  final double x, y, size;
  final String emoji;
  const SpotItem(this.x, this.y, this.emoji, [this.size = 30]);
}

/// A difference between the left (original) and right (changed) picture.
///
/// kind 0: the item moved (drawn at x,y on the left; at x2,y2 on the right).
/// kind 1: the item is missing on the right (drawn only on the left).
/// kind 2: the item changed (drawn as [emoji] on the left, [alt] on the right).
class SpotDiff {
  final double x, y, x2, y2, size;
  final String emoji;
  final String? alt;
  final int kind;
  const SpotDiff(this.x, this.y, this.emoji,
      {this.x2 = -1, this.y2 = -1, this.alt, this.kind = 0, this.size = 30});
}

/// One scene = a pair of pictures with [diffs] differences.
class SpotScene {
  final String name;
  final Color skyA, skyB, ground;
  final List<SpotItem> common;
  final List<SpotDiff> diffs;
  const SpotScene(this.name, this.skyA, this.skyB, this.ground, this.common,
      this.diffs);
}

SpotItem _s(double x, double y, String e, [double sz = 30]) =>
    SpotItem(x, y, e, sz);

SpotDiff _d(double x, double y, String e,
        {double x2 = -1,
        double y2 = -1,
        String? alt,
        int kind = 0,
        double sz = 30}) =>
    SpotDiff(x, y, e,
        x2: x2, y2: y2, alt: alt, kind: kind, size: sz);

/// 8 hand-built scenes, 8 differences each.
/// Easy uses the first 4, Medium the first 6, Hard all 8 —
/// chosen by difficulty, shuffled by the engine with a seed.
final List<SpotScene> spotScenes = [
  SpotScene('Sunny Beach', const Color(0xFF7EC8E3), const Color(0xFFFFF3C4),
      const Color(0xFFF2D998), [
    _s(.85, .14, '☀️', 44),
    _s(.2, .16, '☁️', 42),
    _s(.6, .1, '☁️', 32),
    _s(.12, .86, '🐚', 26),
    _s(.9, .88, '🐚', 24),
    _s(.5, .45, '🌊', 60),
  ], [
    _d(.32, .28, '🕊️', kind: 1), // seagull gone
    _d(.55, .72, '⛱️', x2: .72, y2: .68, sz: 40), // umbrella moved
    _d(.25, .68, '🏐', alt: '⚽', sz: 34), // ball changed
    _d(.82, .62, '🦀', kind: 1), // crab gone
    _d(.68, .3, '⛵', kind: 1), // sailboat gone
    _d(.6, .1, '☁️', kind: 1, sz: 32), // small cloud gone
    _d(.7, .2, '🪂', kind: 1, sz: 30), // parachuter gone
    _d(.5, .45, '🌊', alt: '🌀', sz: 60), // wave turned whirlpool
  ]),
  SpotScene('City Night', const Color(0xFF1B2340), const Color(0xFF3A2E5D),
      const Color(0xFF2A2F45), [
    _s(.8, .15, '🌕', 46),
    _s(.15, .3, '🏙️', 70),
    _s(.5, .32, '🏙️', 60),
    _s(.85, .35, '🏙️', 66),
    _s(.3, .85, '🚕', 36),
    _s(.7, .85, '🚗', 34),
  ], [
    _d(.45, .12, '⭐', kind: 1), // star gone
    _d(.3, .85, '🚕', x2: .42, y2: .85, sz: 36), // taxi moved
    _d(.62, .55, '🚦', alt: '🚥', sz: 34), // traffic light changed
    _d(.15, .26, '🐈', kind: 1), // rooftop cat gone
    _d(.55, .6, '💡', kind: 1), // lamp glow gone
    _d(.8, .15, '🌕', alt: '🌖', sz: 46), // moon phase changed
    _d(.7, .85, '🚗', kind: 1, sz: 34), // car gone
    _d(.2, .5, '🕊️', x2: .28, y2: .44, sz: 24), // bird moved
  ]),
  SpotScene('Happy Farm', const Color(0xFF9ADCFF), const Color(0xFFE8F9FF),
      const Color(0xFF9BDD6E), [
    _s(.15, .15, '☀️', 44),
    _s(.8, .12, '☁️', 40),
    _s(.3, .45, '🚜', 46),
    _s(.75, .5, '🐄', 44),
    _s(.1, .8, '🌻', 30),
    _s(.9, .82, '🌻', 30),
  ], [
    _d(.5, .2, '🐔', kind: 1), // chicken gone
    _d(.62, .78, '🌾', x2: .48, y2: .8, sz: 34), // hay moved
    _d(.3, .45, '🚪', alt: '🪟', sz: 30), // tractor door changed
    _d(.85, .68, '🐑', kind: 1, sz: 36), // sheep gone
    _d(.12, .4, '🏚️', kind: 1, sz: 40), // shed gone
    _d(.8, .12, '☁️', alt: '🌧️', sz: 40), // cloud turned rainy
    _d(.75, .5, '🐄', x2: .63, y2: .56, sz: 44), // cow moved
    _d(.9, .82, '🌻', kind: 1, sz: 30), // sunflower gone
  ]),
  SpotScene('Outer Space', const Color(0xFF0B0E2A), const Color(0xFF2B1B4D),
      const Color(0xFF141433), [
    _s(.2, .2, '🪐', 52),
    _s(.7, .6, '🌎', 44),
    _s(.4, .7, '🚀', 40),
    _s(.85, .15, '⭐', 24),
    _s(.5, .35, '⭐', 20),
  ], [
    _d(.1, .55, '⭐', kind: 1, sz: 22), // star gone
    _d(.2, .2, '🪐', x2: .28, y2: .3, sz: 52), // planet moved
    _d(.4, .7, '🔥', alt: '💨', sz: 28), // flame changed
    _d(.62, .2, '🛸', kind: 1, sz: 40), // UFO gone
    _d(.88, .75, '🛰️', kind: 1, sz: 34), // satellite gone
    _d(.7, .6, '🌎', alt: '🌍', sz: 44), // earth spun
    _d(.5, .35, '⭐', x2: .58, y2: .3, sz: 20), // small star moved
    _d(.4, .7, '🚀', kind: 1, sz: 40), // rocket gone
  ]),
  SpotScene('Deep Jungle', const Color(0xFF7FDB8B), const Color(0xFFD8F7B0),
      const Color(0xFF4E9B47), [
    _s(.15, .4, '🌴', 64),
    _s(.85, .42, '🌴', 64),
    _s(.5, .7, '🐒', 44),
    _s(.3, .85, '🌺', 30),
    _s(.7, .85, '🌺', 30),
  ], [
    _d(.6, .25, '🦜', kind: 1, sz: 36), // parrot gone
    _d(.5, .7, '🐒', x2: .62, y2: .62, sz: 44), // monkey moved
    _d(.3, .85, '🌺', alt: '🌸', sz: 30), // flower changed
    _d(.82, .78, '🐸', kind: 1, sz: 30), // frog gone
    _d(.45, .4, '🍌', kind: 1, sz: 30), // banana gone
    _d(.15, .4, '🌴', x2: .24, y2: .46, sz: 64), // palm moved
    _d(.5, .7, '🐒', alt: '🦍', sz: 44), // monkey changed
    _d(.7, .85, '🌺', kind: 1, sz: 30), // flower gone
  ]),
  SpotScene('Snowy Peaks', const Color(0xFFBFE3FF), const Color(0xFFFFFFFF),
      const Color(0xFFEDF4FF), [
    _s(.25, .5, '🏔️', 90),
    _s(.75, .55, '🏔️', 80),
    _s(.5, .8, '⛄', 52),
    _s(.12, .75, '🌲', 44),
    _s(.88, .78, '🌲', 44),
  ], [
    _d(.5, .72, '🧣', kind: 1, sz: 28), // scarf gone
    _d(.12, .75, '🌲', x2: .2, y2: .8, sz: 44), // pine moved
    _d(.5, .66, '🎩', alt: '🧢', sz: 30), // hat changed
    _d(.68, .85, '🐧', kind: 1, sz: 34), // penguin gone
    _d(.82, .15, '☁️', kind: 1, sz: 38), // cloud gone
    _d(.25, .5, '🏔️', alt: '⛰️', sz: 90), // mountain changed
    _d(.88, .78, '🌲', kind: 1, sz: 44), // pine gone
    _d(.5, .8, '⛄', x2: .58, y2: .82, sz: 52), // snowman moved
  ]),
  SpotScene('Sunny Desert', const Color(0xFFFFD98E), const Color(0xFFFFF3C9),
      const Color(0xFFF0C46C), [
    _s(.85, .18, '☀️', 48),
    _s(.3, .55, '🌵', 56),
    _s(.7, .6, '🐪', 52),
    _s(.15, .6, '🔺', 60),
    _s(.5, .85, '🦂', 28),
  ], [
    _d(.55, .15, '🦅', kind: 1, sz: 32), // vulture gone
    _d(.3, .55, '🌵', x2: .42, y2: .6, sz: 56), // cactus moved
    _d(.15, .6, '🚪', alt: '🕳️', sz: 28), // pyramid door changed
    _d(.88, .8, '🌪️', kind: 1, sz: 32), // tumbleweed gone
    _d(.62, .32, '🌴', kind: 1, sz: 40), // palm gone
    _d(.85, .18, '☀️', alt: '🌤️', sz: 48), // sun softened
    _d(.7, .6, '🐪', x2: .6, y2: .66, sz: 52), // camel moved
    _d(.5, .85, '🦂', kind: 1, sz: 28), // scorpion gone
  ]),
  SpotScene('Under the Sea', const Color(0xFF2E9BD6), const Color(0xFF9FE0F5),
      const Color(0xFF1E7FB5), [
    _s(.2, .3, '🐠', 36),
    _s(.7, .4, '🐟', 34),
    _s(.45, .75, '🪸', 52),
    _s(.85, .7, '🐙', 44),
    _s(.12, .78, '🦀', 32),
  ], [
    _d(.35, .5, '🫧', kind: 1, sz: 26), // bubbles gone
    _d(.6, .85, '⭐', x2: .72, y2: .82, sz: 30), // starfish moved
    _d(.45, .75, '🪸', alt: '🪷', sz: 52), // coral changed
    _d(.78, .25, '🐴', kind: 1, sz: 34), // seahorse gone
    _d(.28, .88, '⚓', kind: 1, sz: 36), // anchor gone
    _d(.2, .3, '🐠', x2: .28, y2: .36, sz: 36), // fish moved
    _d(.85, .7, '🐙', alt: '🦑', sz: 44), // octopus changed
    _d(.12, .78, '🦀', kind: 1, sz: 32), // crab gone
  ]),
];
