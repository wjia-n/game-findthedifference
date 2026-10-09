import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'theme/spot_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = SpotSettings();
  await settings.load();
  final audio = SpotAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(SpotApp(settings: settings, audio: audio));
}

class SpotApp extends StatefulWidget {
  final SpotSettings settings;
  final SpotAudio audio;
  const SpotApp({super.key, required this.settings, required this.audio});

  @override
  State<SpotApp> createState() => _SpotAppState();
}

class _SpotAppState extends State<SpotApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; the game screen additionally pauses its engine.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final theme = SpotThemes.byId(widget.settings.themeId,
            custom: widget.settings.customTheme);
        return MaterialApp(
          title: 'Find the Difference',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.accent,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: theme.pageBottom,
            textTheme: const TextTheme().apply(
              bodyColor: theme.text,
              displayColor: theme.text,
            ),
          ),
          home: SplashScreen(audio: widget.audio, settings: widget.settings),
        );
      },
    );
  }
}
