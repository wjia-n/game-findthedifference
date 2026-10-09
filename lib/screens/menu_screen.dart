import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/spot_themes.dart';
import 'game_screen.dart';
import 'name_field.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

const String _storeUrl =
    'https://play.google.com/store/apps/details?id=com.gameswajiha.findthedifference';

/// Main menu: profile, mode + difficulty pickers, daily puzzle card, play.
class MenuScreen extends StatefulWidget {
  final SpotAudio audio;
  final SpotSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
  }

  SpotThemeDef _theme() => SpotThemes.byId(widget.settings.themeId,
      custom: widget.settings.customTheme);

  void _play(GameMode mode) {
    widget.audio.gameStart();
    String? dailyKey;
    if (mode.id == 'daily') {
      final now = DateTime.now();
      dailyKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: widget.settings,
          mode: mode,
          difficulty:
              Difficulties.byIndex(widget.settings.difficulty),
          dailyKey: dailyKey,
        ),
      ),
    );
  }

  Future<void> _askReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.openStoreListing(appStoreId: null);
      } else {
        await Share.share('Find the Difference — spot every change! $_storeUrl');
      }
    } catch (_) {
      await Share.share('Find the Difference — spot every change! $_storeUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme();
    final settings = widget.settings;
    final diff = Difficulties.byIndex(settings.difficulty);
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
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // Header: logo + name.
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: theme.accent, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                        'assets/findthedifference_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Find the Difference',
                            style: TextStyle(
                                color: theme.text,
                                fontSize: 24,
                                fontWeight: FontWeight.w900)),
                        Text('A cozy detective puzzle',
                            style: TextStyle(
                                color: theme.textDim, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      widget.audio.click();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                              audio: widget.audio, settings: settings),
                        ),
                      );
                    },
                    icon: Icon(Icons.settings,
                        color: theme.text, size: 28),
                    tooltip: 'Settings',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detective profile card (renameable).
              _card(theme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🕵️ Detective profile',
                          style: TextStyle(
                              color: theme.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _nameField(
                                theme,
                                'Your name',
                                settings.names['solo']!,
                                (v) => settings.setName('solo', v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Best score ${settings.bestScore} • ${settings.wins} cases closed • ${settings.gamesPlayed} played',
                        style: TextStyle(
                            color: theme.textDim, fontSize: 12),
                      ),
                    ],
                  )),
              const SizedBox(height: 14),

              // Daily puzzle card.
              Builder(builder: (_) {
                final now = DateTime.now();
                final key =
                    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                final best = settings.dailyBest(key);
                return _card(theme,
                    child: InkWell(
                      onTap: () => _play(GameMode.daily),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text('📅',
                                style: TextStyle(fontSize: 30)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Daily Puzzle',
                                      style: TextStyle(
                                          color: theme.text,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16)),
                                  Text(
                                    best > 0
                                        ? 'Today\'s best: $best — beat it!'
                                        : 'Same puzzle for everyone today',
                                    style: TextStyle(
                                        color: theme.textDim,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.play_circle_fill,
                                color: theme.accent, size: 40),
                          ],
                        ),
                      ),
                    ));
              }),
              const SizedBox(height: 14),

              // Mode picker.
              Text('Choose your case',
                  style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.55,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: GameMode.all
                    .where((m) => m.id != 'daily')
                    .length,
                itemBuilder: (_, i) {
                  final mode = GameMode.all
                      .where((m) => m.id != 'daily')
                      .toList()[i];
                  final selected = settings.modeId == mode.id;
                  return GestureDetector(
                    onTap: () {
                      widget.audio.click();
                      settings.setMode(mode.id);
                    },
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.accent
                            : theme.card,
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? theme.accent
                              : theme.cardEdge,
                          width: 2,
                        ),
                      ),
                      padding:
                          const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(mode.emoji,
                              style: const TextStyle(
                                  fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(mode.name,
                              style: TextStyle(
                                  color: selected
                                      ? Colors.black87
                                      : theme.text,
                                  fontWeight:
                                      FontWeight.w800,
                                  fontSize: 14)),
                          Text(mode.blurb,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: selected
                                      ? Colors.black54
                                      : theme.textDim,
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Difficulty picker.
              Text('Difficulty',
                  style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (int i = 0;
                      i < Difficulties.all.length;
                      i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: i < 2 ? 8 : 0),
                        child: _difficultyBtn(
                            theme,
                            Difficulties.all[i],
                            i,
                            settings),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // Big play button.
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: () =>
                      _play(GameMode.byId(settings.modeId)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                    elevation: 6,
                  ),
                  child: Text(
                    '🔎  START — ${GameMode.byId(settings.modeId).name} • ${diff.name}'
                        .toUpperCase(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Pro / share / review row.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        widget.audio.click();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProScreen(
                                audio: widget.audio,
                                settings: settings),
                          ),
                        );
                      },
                      icon: Icon(Icons.star,
                          color: settings.isPro
                              ? Colors.amber
                              : theme.accent),
                      label: Text(
                          settings.isPro
                              ? 'PRO ✓'
                              : 'Go PRO',
                          style: TextStyle(
                              color: theme.text,
                              fontWeight:
                                  FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: theme.cardEdge),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        widget.audio.click();
                        Share.share(
                            'Find the Difference — spot every change! $_storeUrl');
                      },
                      icon: Icon(Icons.share,
                          color: theme.accent),
                      label: Text('Share',
                          style: TextStyle(
                              color: theme.text,
                              fontWeight:
                                  FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: theme.cardEdge),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        widget.audio.click();
                        _askReview();
                      },
                      icon: Icon(Icons.rate_review,
                          color: theme.accent),
                      label: Text('Rate',
                          style: TextStyle(
                              color: theme.text,
                              fontWeight:
                                  FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: theme.cardEdge),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/wajiha_logo.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain),
                    const SizedBox(width: 8),
                    Text('Credits: WAJIHA',
                        style: TextStyle(
                            color: theme.textDim,
                            fontSize: 12,
                            letterSpacing: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(SpotThemeDef theme, {required Widget child}) => Container(
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.cardEdge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: child,
      );

  Widget _nameField(SpotThemeDef theme, String label, String value,
      Future<void> Function(String) onSave) {
    return NameField(
      audio: widget.audio,
      theme: theme,
      label: label,
      initial: value,
      onSave: onSave,
    );
  }

  Widget _difficultyBtn(SpotThemeDef theme, DifficultyDef d, int i,
      SpotSettings settings) {
    final locked = d.locked && !settings.isPro;
    final selected = settings.difficulty == i;
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        if (locked) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ProScreen(audio: widget.audio, settings: settings),
            ),
          );
          return;
        }
        settings.setDifficulty(i);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.accent : theme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? theme.accent : theme.cardEdge, width: 2),
        ),
        child: Column(
          children: [
            Text(locked ? '🔒' : ['🌱', '🌿', '🌵'][i],
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(d.name,
                style: TextStyle(
                    color: selected ? Colors.black87 : theme.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
            Text(
                '${d.diffCount} diffs • ${d.secondsPerScene}s',
                style: TextStyle(
                    color:
                        selected ? Colors.black54 : theme.textDim,
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
