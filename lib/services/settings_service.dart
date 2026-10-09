import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/spot_themes.dart';

/// Persisted settings + stats for Find the Difference. Survives app restarts.
///
/// Stores: audio toggles, player profile names (one JSON string),
/// theme/frame choices (incl. custom theme colors), difficulty + mode,
/// Pro unlock state, and lifetime stats.
class SpotSettings extends ChangeNotifier {
  static const _kMusic = 'spot_music_on';
  static const _kSfx = 'spot_sfx_on';
  static const _kVolume = 'spot_volume';
  static const _kDifficulty = 'spot_difficulty'; // 0 easy, 1 medium, 2 hard
  static const _kMode = 'spot_mode';

  /// Order-safe profile storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so a
  /// StringList would scramble name order on every restart. NEVER use a
  /// StringList (or setStringList) for ordered data on Android.
  static const _kNamesJson = 'findthedifference_player_names_json';

  // Legacy keys migrated once: the earlier exemplar key, plus the very
  // first shell-based release's keys.
  static const _kLegacyJson = 'spot_profile_names_json';
  static const _kLegacyNames = 'spot_player_names';
  static const _kLegacyName = 'spot_player_name';

  static const _kTheme = 'spot_theme_id';
  static const _kFrame = 'spot_frame_style';
  static const _kWins = 'spot_wins';
  static const _kGames = 'spot_games_played';
  static const _kBestScore = 'spot_best_score';
  static const _kIsPro = 'spot_is_pro';
  static const _kCustomPrefix = 'spot_custom_';
  static const _kDailyPrefix = 'spot_daily_best_';

  static const defaultNames = {'solo': 'Detective', 'p1': 'Detective 1', 'p2': 'Detective 2'};

  /// Encode the profile names as one JSON string (order-preserving).
  static String encodeNames(Map<String, String> names) => jsonEncode(names);

  static Map<String, String> decodeNames(String? raw) {
    final out = Map<String, String>.of(defaultNames);
    if (raw == null) return out;
    try {
      final d = jsonDecode(raw);
      if (d is Map) {
        for (final k in out.keys) {
          final v = d[k];
          if (v is String && v.trim().isNotEmpty) out[k] = v.trim();
        }
      }
    } catch (_) {}
    return out;
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int difficulty = 1; // medium default
  String modeId = 'classic';
  Map<String, String> names = Map.of(defaultNames);
  String themeId = 'oak';
  int frameStyle = 0;
  int wins = 0;
  int gamesPlayed = 0;
  int bestScore = 0;
  bool isPro = false;

  /// Custom theme colors (ARGB ints).
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'pageTop': 0xFF3B2A1A,
    'pageBottom': 0xFF1E140C,
    'card': 0xFF5A4128,
    'cardEdge': 0xFF7A5C36,
    'accent': 0xFFE8B64C,
    'text': 0xFFFFF3DD,
    'found': 0xFF8FD14F,
  };

  SpotThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return SpotThemeDef(
      id: 'custom',
      name: 'My Creation',
      pageTop: c('pageTop'),
      pageBottom: c('pageBottom'),
      card: c('card'),
      cardEdge: c('cardEdge'),
      accent: c('accent'),
      accentSoft: c('accent').withValues(alpha: 0.4),
      text: c('text'),
      textDim: c('text').withValues(alpha: 0.7),
      found: c('found'),
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    modeId = p.getString(_kMode) ?? 'classic';

    // Profile names: prefer the order-safe JSON key; migrate legacy keys once.
    final namesRaw = p.getString(_kNamesJson) ?? p.getString(_kLegacyJson);
    if (namesRaw != null) {
      names = decodeNames(namesRaw);
    } else {
      names = Map.of(defaultNames);
      final legacyList = p.getStringList(_kLegacyNames);
      final legacyOne = p.getString(_kLegacyName);
      if (legacyList != null && legacyList.isNotEmpty) {
        if (legacyList.first.trim().isNotEmpty) names['solo'] = legacyList.first.trim();
      } else if (legacyOne != null && legacyOne.trim().isNotEmpty) {
        names['solo'] = legacyOne.trim();
      }
    }

    themeId = p.getString(_kTheme) ?? 'oak';
    frameStyle = (p.getInt(_kFrame) ?? 0).clamp(0, FrameStyles.all.length - 1);
    wins = p.getInt(_kWins) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    bestScore = p.getInt(_kBestScore) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kDifficulty, difficulty);
    await p.setString(_kMode, modeId);
    await p.setString(_kNamesJson, encodeNames(names));
    await p.remove(_kLegacyJson); // drop legacy keys for good
    await p.remove(_kLegacyNames);
    await p.remove(_kLegacyName);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kFrame, frameStyle);
    await p.setInt(_kWins, wins);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kBestScore, bestScore);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || SpotThemes.isProTheme(themeId)) {
      themeId = 'oak';
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    if (!isPro && v > 1) return; // Hard is a Pro feature
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setMode(String id) async {
    modeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setName(String key, String name) async {
    if (!defaultNames.containsKey(key)) return;
    final clean = name.trim();
    names[key] = clean.isEmpty ? defaultNames[key]! : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || SpotThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setFrameStyle(int v) async {
    frameStyle = v.clamp(0, FrameStyles.all.length - 1);
    notifyListeners();
    await _save();
  }

  /// Record a finished game.
  Future<void> recordGame({required int score, required bool won}) async {
    gamesPlayed++;
    if (score > bestScore) bestScore = score;
    if (won) wins++;
    notifyListeners();
    await _save();
  }

  /// Daily-challenge best for a date key like '2026-10-09'.
  Future<void> recordDaily(String dateKey, int score) async {
    final key = '$_kDailyPrefix$dateKey';
    final p = _prefs;
    if (p == null) return;
    final prev = p.getInt(key) ?? 0;
    if (score > prev) await p.setInt(key, score);
  }

  int dailyBest(String dateKey) => _prefs?.getInt('$_kDailyPrefix$dateKey') ?? 0;
}
