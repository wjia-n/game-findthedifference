import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/spot_themes.dart';

/// Custom theme creator (Pro feature): pick your own palette colors.
class CustomThemeScreen extends StatelessWidget {
  final SpotAudio audio;
  final SpotSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  static const _labels = {
    'pageTop': 'Background top',
    'pageBottom': 'Background bottom',
    'card': 'Card',
    'cardEdge': 'Card edge',
    'accent': 'Accent',
    'text': 'Text',
    'found': 'Found rings',
  };

  static const _swatches = [
    0xFF3B2A1A,
    0xFF5A4128,
    0xFFE8B64C,
    0xFF2E6E8E,
    0xFF12303F,
    0xFFFFC35C,
    0xFF4E7A3A,
    0xFF243A1C,
    0xFFFFD166,
    0xFF6B3226,
    0xFF331712,
    0xFFFFC978,
    0xFF3C4A5A,
    0xFF1A212B,
    0xFFFFB347,
    0xFF23233F,
    0xFF0F0F1C,
    0xFFEE964B,
    0xFF4B2A6B,
    0xFF231237,
    0xFFF6D743,
    0xFF1F4D2E,
    0xFF0D2415,
    0xFF7ED957,
    0xFFFFFFFF,
    0xFF000000,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = SpotThemes.byId(settings.themeId,
        custom: settings.customTheme);
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          title: const Text('My Creation — custom theme'),
          backgroundColor: Colors.transparent,
          foregroundColor: theme.text,
          actions: [
            TextButton(
              onPressed: () {
                audio.click();
                settings.resetCustomColors();
              },
              child: Text('Reset',
                  style: TextStyle(color: theme.accent)),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                settings.customTheme.pageTop,
                settings.customTheme.pageBottom
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              for (final key in _labels.keys)
                _colorRow(context, key, _labels[key]!),
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    audio.click();
                    settings.setTheme('custom');
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Use this theme',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorRow(BuildContext context, String key, String label) {
    final current = settings.customColors[key] ?? 0xFF000000;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Color(current),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in _swatches)
                GestureDetector(
                  onTap: () {
                    audio.click();
                    settings.setCustomColor(key, s);
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(s),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: s == current
                            ? Colors.white
                            : Colors.white24,
                        width: s == current ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
