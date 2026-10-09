import 'package:flutter/material.dart';

/// One ambiance theme for Find the Difference.
/// Themes dress the menu, frames and panels — the scenes themselves keep
/// their own painted skies (each scene is a unique picture).
class SpotThemeDef {
  final String id;
  final String name;
  final bool pro;
  final Color pageTop;
  final Color pageBottom;
  final Color card;
  final Color cardEdge;
  final Color accent;
  final Color accentSoft;
  final Color text;
  final Color textDim;
  final Color found; // ring color for found differences
  const SpotThemeDef({
    required this.id,
    required this.name,
    this.pro = false,
    required this.pageTop,
    required this.pageBottom,
    required this.card,
    required this.cardEdge,
    required this.accent,
    required this.accentSoft,
    required this.text,
    required this.textDim,
    required this.found,
  });
}

/// 12 themes. First 6 are free, the rest are Pro.
class SpotThemes {
  static const List<SpotThemeDef> all = [
    SpotThemeDef(
      id: 'oak',
      name: 'Oak Study',
      pageTop: Color(0xFF3B2A1A),
      pageBottom: Color(0xFF1E140C),
      card: Color(0xFF5A4128),
      cardEdge: Color(0xFF7A5C36),
      accent: Color(0xFFE8B64C),
      accentSoft: Color(0x66442200),
      text: Color(0xFFFFF3DD),
      textDim: Color(0xFFC9AE84),
      found: Color(0xFF8FD14F),
    ),
    SpotThemeDef(
      id: 'seaside',
      name: 'Seaside',
      pageTop: Color(0xFF2E6E8E),
      pageBottom: Color(0xFF12303F),
      card: Color(0xFF3A7E9C),
      cardEdge: Color(0xFF5CA3BE),
      accent: Color(0xFFFFC35C),
      accentSoft: Color(0x66442200),
      text: Color(0xFFFFF8EA),
      textDim: Color(0xFFBBD9E4),
      found: Color(0xFF9BE15D),
    ),
    SpotThemeDef(
      id: 'meadow',
      name: 'Meadow',
      pageTop: Color(0xFF4E7A3A),
      pageBottom: Color(0xFF243A1C),
      card: Color(0xFF5E8B46),
      cardEdge: Color(0xFF7FAD66),
      accent: Color(0xFFFFD166),
      accentSoft: Color(0x66554400),
      text: Color(0xFFFFFBEF),
      textDim: Color(0xFFD6E8C4),
      found: Color(0xFF7EE081),
    ),
    SpotThemeDef(
      id: 'cherry',
      name: 'Cherry Wood',
      pageTop: Color(0xFF6B3226),
      pageBottom: Color(0xFF331712),
      card: Color(0xFF7D4230),
      cardEdge: Color(0xFF9C5B44),
      accent: Color(0xFFFFC978),
      accentSoft: Color(0x66552200),
      text: Color(0xFFFFF1DF),
      textDim: Color(0xFFE3BFA4),
      found: Color(0xFFA8E05F),
    ),
    SpotThemeDef(
      id: 'slate',
      name: 'Slate',
      pageTop: Color(0xFF3C4A5A),
      pageBottom: Color(0xFF1A212B),
      card: Color(0xFF4B5B6E),
      cardEdge: Color(0xFF65788D),
      accent: Color(0xFFFFB347),
      accentSoft: Color(0x66552200),
      text: Color(0xFFF4F7FB),
      textDim: Color(0xFFB9C6D4),
      found: Color(0xFF8FD14F),
    ),
    SpotThemeDef(
      id: 'sand',
      name: 'Desert Sand',
      pageTop: Color(0xFFB0803C),
      pageBottom: Color(0xFF5E3F18),
      card: Color(0xFFC0904A),
      cardEdge: Color(0xFFDCB271),
      accent: Color(0xFF3E7CB1),
      accentSoft: Color(0x44003366),
      text: Color(0xFFFFF6E6),
      textDim: Color(0xFFEBD3A8),
      found: Color(0xFF6BCB77),
    ),
    // ---- Pro themes ----
    SpotThemeDef(
      id: 'mahogany',
      name: 'Mahogany Hall',
      pro: true,
      pageTop: Color(0xFF5A1F1F),
      pageBottom: Color(0xFF2A0D0D),
      card: Color(0xFF6E2A2A),
      cardEdge: Color(0xFF8F3D3D),
      accent: Color(0xFFF4D35E),
      accentSoft: Color(0x66554400),
      text: Color(0xFFFFF2E0),
      textDim: Color(0xFFE0B9A0),
      found: Color(0xFF9BE15D),
    ),
    SpotThemeDef(
      id: 'midnight',
      name: 'Midnight Library',
      pro: true,
      pageTop: Color(0xFF23233F),
      pageBottom: Color(0xFF0F0F1C),
      card: Color(0xFF32324E),
      cardEdge: Color(0xFF48486A),
      accent: Color(0xFFEE964B),
      accentSoft: Color(0x66330000),
      text: Color(0xFFF3F0FF),
      textDim: Color(0xFFB8B8D4),
      found: Color(0xFF7EE081),
    ),
    SpotThemeDef(
      id: 'forest',
      name: 'Deep Forest',
      pro: true,
      pageTop: Color(0xFF1F4D2E),
      pageBottom: Color(0xFF0D2415),
      card: Color(0xFF2C5F3B),
      cardEdge: Color(0xFF427A4F),
      accent: Color(0xFFF6D743),
      accentSoft: Color(0x66554400),
      text: Color(0xFFF6FFF0),
      textDim: Color(0xFFBFD8B4),
      found: Color(0xFFC8F169),
    ),
    SpotThemeDef(
      id: 'royal',
      name: 'Royal Velvet',
      pro: true,
      pageTop: Color(0xFF4B2A6B),
      pageBottom: Color(0xFF231237),
      card: Color(0xFF5D3A82),
      cardEdge: Color(0xFF7A549E),
      accent: Color(0xFFFFD166),
      accentSoft: Color(0x66554400),
      text: Color(0xFFF9F0FF),
      textDim: Color(0xFFD3BEE8),
      found: Color(0xFF9BE15D),
    ),
    SpotThemeDef(
      id: 'harbor',
      name: 'Old Harbor',
      pro: true,
      pageTop: Color(0xFF264653),
      pageBottom: Color(0xFF0F1F26),
      card: Color(0xFF33565F),
      cardEdge: Color(0xFF4A6E78),
      accent: Color(0xFFE9C46A),
      accentSoft: Color(0x66554400),
      text: Color(0xFFF0F7F4),
      textDim: Color(0xFFAECBD0),
      found: Color(0xFF7EE081),
    ),
    SpotThemeDef(
      id: 'copper',
      name: 'Copper Workshop',
      pro: true,
      pageTop: Color(0xFF6B4423),
      pageBottom: Color(0xFF2E1D0E),
      card: Color(0xFF7D5230),
      cardEdge: Color(0xFF9C6E44),
      accent: Color(0xFF7ED0D8),
      accentSoft: Color(0x44006666),
      text: Color(0xFFFFF4E6),
      textDim: Color(0xFFE0C3A0),
      found: Color(0xFFA8E05F),
    ),
  ];

  static SpotThemeDef byId(String id, {SpotThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static bool isProTheme(String id) =>
      all.any((t) => t.id == id && t.pro);
}

/// A physical frame style for the scene panels (8 styles).
/// Each style gives the two inner colors used for the beveled frame ring.
class FrameStyleDef {
  final String name;
  final Color hi;
  final Color lo;
  final Color shadow;
  const FrameStyleDef(this.name, this.hi, this.lo, this.shadow);
}

class FrameStyles {
  static const List<FrameStyleDef> all = [
    FrameStyleDef('Oak Wood', Color(0xFF8A5A2E), Color(0xFF4A2C12), Color(0xFF000000)),
    FrameStyleDef('Brass', Color(0xFFE8C96A), Color(0xFF8A6D1A), Color(0xFF000000)),
    FrameStyleDef('Bamboo', Color(0xFFD9B84A), Color(0xFF8A6F22), Color(0xFF1A1206)),
    FrameStyleDef('Stone', Color(0xFF9AA3AD), Color(0xFF4E565E), Color(0xFF000000)),
    FrameStyleDef('Paper', Color(0xFFF6F0DC), Color(0xFFC9BFA3), Color(0xFF3A2E1A)),
    FrameStyleDef('Copper', Color(0xFFD98E5F), Color(0xFF7A4222), Color(0xFF000000)),
    FrameStyleDef('Leather', Color(0xFF7A4A2E), Color(0xFF3B2010), Color(0xFF000000)),
    FrameStyleDef('Ceramic', Color(0xFFEAF2F6), Color(0xFF8FA3B0), Color(0xFF22303A)),
  ];

  static FrameStyleDef byIndex(int i) => all[i.clamp(0, all.length - 1)];
}

/// Difficulty parameters.
class DifficultyDef {
  final String name;
  final int diffCount;
  final int secondsPerScene;
  final double tapRadius; // normalized units
  final int hints;
  final bool locked; // Pro only
  const DifficultyDef({
    required this.name,
    required this.diffCount,
    required this.secondsPerScene,
    required this.tapRadius,
    required this.hints,
    this.locked = false,
  });
}

class Difficulties {
  static const easy =
      DifficultyDef(name: 'Easy', diffCount: 4, secondsPerScene: 120, tapRadius: 0.095, hints: 3);
  static const medium =
      DifficultyDef(name: 'Medium', diffCount: 6, secondsPerScene: 90, tapRadius: 0.08, hints: 2);
  static const hard = DifficultyDef(
      name: 'Hard', diffCount: 8, secondsPerScene: 75, tapRadius: 0.065, hints: 1, locked: true);

  static const List<DifficultyDef> all = [easy, medium, hard];
  static DifficultyDef byIndex(int i) => all[i.clamp(0, all.length - 1)];
}

/// Game modes.
class GameMode {
  final String id;
  final String name;
  final String blurb;
  final String emoji;
  const GameMode(this.id, this.name, this.blurb, this.emoji);

  static const classic = GameMode('classic', 'Classic', 'Beat the clock, scene by scene', '⏱️');
  static const zen = GameMode('zen', 'Zen', 'No timer. Just look and breathe', '🍃');
  static const blitz = GameMode('blitz', 'Blitz', '60 seconds per scene, double points', '⚡');
  static const daily =
      GameMode('daily', 'Daily Puzzle', 'One seeded puzzle a day — same for everyone', '📅');
  static const passplay =
      GameMode('passplay', 'Pass & Play', 'Two detectives, one phone, take turns', '🤝');

  static const List<GameMode> all = [classic, zen, blitz, daily, passplay];
  static GameMode byId(String id) =>
      all.firstWhere((m) => m.id == id, orElse: () => classic);
}
