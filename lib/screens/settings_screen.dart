import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/spot_themes.dart';
import 'custom_theme_screen.dart';
import 'name_field.dart';
import 'pro_screen.dart';

/// Settings: audio, renameable profiles, theme + frame pickers.
class SettingsScreen extends StatelessWidget {
  final SpotAudio audio;
  final SpotSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  SpotThemeDef _theme() => SpotThemes.byId(settings.themeId,
      custom: settings.customTheme);

  void _syncAudio() {
    audio.configure(
        musicOn: settings.musicOn,
        sfxOn: settings.sfxOn,
        volume: settings.volume);
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme();
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.transparent,
          foregroundColor: theme.text,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.pageTop, theme.pageBottom],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _section(theme, '🔊 Sound & music', [
                SwitchListTile(
                  title: Text('Music', style: TextStyle(color: theme.text)),
                  value: settings.musicOn,
                  activeColor: theme.accent,
                  onChanged: (v) {
                    audio.click();
                    settings.setMusic(v);
                    _syncAudio();
                    if (v) audio.startMenuMusic();
                  },
                ),
                SwitchListTile(
                  title: Text('Sound effects',
                      style: TextStyle(color: theme.text)),
                  value: settings.sfxOn,
                  activeColor: theme.accent,
                  onChanged: (v) {
                    settings.setSfx(v);
                    _syncAudio();
                    audio.click();
                  },
                ),
                ListTile(
                  title: Text('Volume',
                      style: TextStyle(color: theme.text)),
                  subtitle: Slider(
                    value: settings.volume,
                    activeColor: theme.accent,
                    onChanged: (v) {
                      settings.setVolume(v);
                      _syncAudio();
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              _section(theme, '🕵️ Detective names', [
                _nameTile(theme, 'Your detective name', 'solo'),
                _nameTile(theme, 'Pass & Play — player 1', 'p1'),
                _nameTile(theme, 'Pass & Play — player 2', 'p2'),
              ]),
              const SizedBox(height: 14),
              _section(theme, '🎨 Theme (12)', [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in SpotThemes.all)
                      _themeChip(context, theme, t),
                    _customChip(context, theme),
                  ],
                ),
              ]),
              const SizedBox(height: 14),
              _section(theme, '🖼️ Picture frame (8)', [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0;
                        i < FrameStyles.all.length;
                        i++)
                      _frameChip(theme, i),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'v1.0.0 • Find the Difference • Credits: WAJIHA',
                  style: TextStyle(color: theme.textDim, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(SpotThemeDef theme, String title, List<Widget> kids) =>
      Container(
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.cardEdge),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
            const SizedBox(height: 4),
            ...kids,
          ],
        ),
      );

  Widget _nameTile(SpotThemeDef theme, String label, String key) {
    return ListTile(
      title: Text(label, style: TextStyle(color: theme.text, fontSize: 14)),
      subtitle: NameField(
        audio: audio,
        theme: theme,
        label: label,
        initial: settings.names[key] ?? '',
        onSave: (v) => settings.setName(key, v),
      ),
    );
  }

  Widget _themeChip(
      BuildContext context, SpotThemeDef theme, SpotThemeDef t) {
    final locked = t.pro && !settings.isPro;
    final selected = settings.themeId == t.id;
    return GestureDetector(
      onTap: () {
        audio.click();
        if (locked) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  ProScreen(audio: audio, settings: settings)));
          return;
        }
        settings.setTheme(t.id);
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [t.pageTop, t.pageBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.accent : t.cardEdge,
            width: selected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 26,
              decoration: BoxDecoration(
                color: t.accent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${locked ? '🔒 ' : ''}${t.name}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: t.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customChip(BuildContext context, SpotThemeDef theme) {
    final selected = settings.themeId == 'custom';
    final locked = !settings.isPro;
    return GestureDetector(
      onTap: () {
        audio.click();
        if (locked) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  ProScreen(audio: audio, settings: settings)));
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CustomThemeScreen(
                audio: audio, settings: settings)));
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.accent : theme.cardEdge,
            width: selected ? 3 : 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(colors: [
                  Colors.red,
                  Colors.orange,
                  Colors.green,
                  Colors.blue,
                  Colors.purple
                ]),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${locked ? '🔒 ' : ''}My Creation',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: theme.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _frameChip(SpotThemeDef theme, int i) {
    final f = FrameStyles.byIndex(i);
    final selected = settings.frameStyle == i;
    return GestureDetector(
      onTap: () {
        audio.click();
        settings.setFrameStyle(i);
      },
      child: Container(
        width: 76,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [f.hi, f.lo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? theme.accent : Colors.transparent,
            width: selected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 30,
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                  child: Text('🖼️',
                      style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(height: 4),
            Text(f.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
