import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Procedural audio for Find the Difference — all sounds synthesized in code
/// as WAV bytes. No asset files. Warm, curious, detective-like sounds.
///
/// Reliability design (every call is safe to repeat and safe to overlap):
/// - Music clips are synthesized ONCE and cached; starting music never blocks
///   the UI thread after the first build.
/// - A [_musicGen] generation counter serializes track changes: every
///   start/stop bumps the generation, in-flight work from an older request
///   aborts, and the LATEST request always wins. Overlapping calls (menu
///   in/out, pause/resume, toggles) can never swallow a start or leave the
///   player half-started — music is app-scoped and never silently dies.
/// - Lifecycle uses pause()/resume() so an interruption (call, backgrounding)
///   resumes exactly where it left off instead of restarting or dying.
/// - Every public method catches player errors; audio can never crash the app.
class SpotAudio {
  static const int _rate = 22050;
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;

  // Cache synthesized clips so we only build them once.
  final Map<String, Uint8List> _cache = {};

  // Music state machine. [_musicGen] is bumped by every start/stop request;
  // async work checks it still owns the latest generation before touching
  // the player, so overlapping requests can never desync the music.
  int _musicGen = 0;
  bool _musicBusy = false;
  String? _currentTrack; // 'menu' | 'game' | null
  bool _pausedByLifecycle = false;
  bool _disposed = false;

  SpotAudio() {
    // Fire-and-forget is fine here: configure() runs before any play.
    _music.setReleaseMode(ReleaseMode.loop);
  }

  void configure(
      {required bool musicOn, required bool sfxOn, required double volume}) {
    this.musicOn = musicOn;
    this.sfxOn = sfxOn;
    volume = volume.clamp(0.0, 1.0);
    this.volume = volume;
    _music.setVolume(musicOn ? volume * 0.5 : 0.0);
    _sfx.setVolume(sfxOn ? volume : 0.0);
    if (!musicOn) {
      stopMusic();
    }
  }

  /// Pre-build music clips off the critical path. Safe to call any time.
  Future<void> prewarm() async {
    if (_disposed) return;
    await Future(() {});
    _menuBytes();
    _gameBytes();
  }

  // ---------------------------------------------------------- WAV synthesis
  Uint8List _wav(List<double> samples) {
    final n = samples.length;
    final data = ByteData(44 + n * 2);
    void writeStr(int o, String s) {
      for (int i = 0; i < s.length; i++) {
        data.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, _rate, Endian.little);
    data.setUint32(28, _rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeStr(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (int i = 0; i < n; i++) {
      final v = samples[i].clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  double _env(int i, int n, {double attack = 0.02}) {
    final t = i / n;
    final a = (t / attack).clamp(0.0, 1.0);
    final d = pow(1 - t, 2.2).toDouble();
    return a * d;
  }

  List<double> _tone(double freq, double secs,
      {double freqEnd = 0, double attack = 0.02, double harmonics = 0.25}) {
    final n = (_rate * secs).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final f = freqEnd > 0 ? freq + (freqEnd - freq) * (i / n) : freq;
      final ph = 2 * pi * f * t;
      out[i] = _env(i, n, attack: attack) *
          (sin(ph) + harmonics * sin(2 * ph) + harmonics * 0.5 * sin(3 * ph));
    }
    return out;
  }

  /// Soft wooden tap (a tap on empty picture).
  List<double> _tapSnd() {
    final n = (_rate * 0.09).round();
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      out[i] = exp(-t * 60) *
          (sin(2 * pi * 420 * t) * 0.5 + sin(2 * pi * 840 * t) * 0.25);
    }
    return out;
  }

  /// Muffled thud for a miss.
  List<double> _thud() {
    final n = (_rate * 0.18).round();
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      out[i] = exp(-t * 28) *
          (sin(2 * pi * 140 * t) * 0.7 + sin(2 * pi * 210 * t) * 0.3);
    }
    return out;
  }

  List<double> _arp(List<double> freqs, double noteSecs, double gapSecs) {
    final noteN = (_rate * noteSecs).round();
    final gapN = (_rate * gapSecs).round();
    final total = freqs.length * (noteN + gapN);
    final out = List<double>.filled(total, 0.0);
    for (int k = 0; k < freqs.length; k++) {
      final tone = _tone(freqs[k], noteSecs, harmonics: 0.3);
      final base = k * (noteN + gapN);
      for (int i = 0; i < noteN && base + i < total; i++) {
        out[base + i] += tone[i] * 0.8;
      }
    }
    return out;
  }

  /// Happy chime for a found difference (two-note "aha!").
  List<double> _foundSnd() {
    final a = _tone(880, 0.16, harmonics: 0.3);
    final b = _tone(1174.66, 0.24, harmonics: 0.3);
    final out = List<double>.filled(a.length + b.length, 0.0);
    for (int i = 0; i < a.length; i++) {
      out[i] += a[i] * 0.8;
    }
    for (int i = 0; i < b.length; i++) {
      out[a.length + i] += b[i] * 0.8;
    }
    return out;
  }

  /// Sparkle sweep for hints.
  List<double> _sparkle() {
    final n = (_rate * 0.4).round();
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final f = 1200 + 2400 * (i / n);
      out[i] = _env(i, n, attack: 0.1) * sin(2 * pi * f * t) * 0.5;
    }
    return out;
  }

  Uint8List _clip(String key, List<double> Function() build) {
    return _cache.putIfAbsent(key, () => _wav(build()));
  }

  // -------------------------------------------------------------- music
  Uint8List _menuBytes() => _clip('music_menu', () {
        // Gentle curiosity: slow marimba-like arpeggio, C major-ish.
        final notes = <double>[
          261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 293.66, 329.63
        ];
        final noteN = (_rate * 0.42).round();
        final total = noteN * notes.length;
        final out = List<double>.filled(total, 0.0);
        for (int k = 0; k < notes.length; k++) {
          final tone = _tone(notes[k], 0.42, harmonics: 0.35);
          for (int i = 0; i < noteN && k * noteN + i < total; i++) {
            out[k * noteN + i] += tone[i] * 0.42;
          }
        }
        // Soft low pad underneath.
        final pad = _tone(130.81, notes.length * 0.42,
            attack: 0.4, harmonics: 0.15);
        for (int i = 0; i < total && i < pad.length; i++) {
          out[i] += pad[i] * 0.18;
        }
        return out;
      });

  Uint8List _gameBytes() => _clip('music_game', () {
        // Focused detective loop: steady pizzicato-ish plucks, minor feel.
        final notes = <double>[
          220.0, 261.63, 293.66, 261.63, 220.0, 196.0, 220.0, 246.94
        ];
        final noteN = (_rate * 0.32).round();
        final total = noteN * notes.length;
        final out = List<double>.filled(total, 0.0);
        for (int k = 0; k < notes.length; k++) {
          final tone = _tone(notes[k], 0.32, harmonics: 0.3);
          for (int i = 0; i < noteN && k * noteN + i < total; i++) {
            out[k * noteN + i] += tone[i] * 0.36;
          }
        }
        return out;
      });

  Future<void> _play(Uint8List bytes) async {
    if (_disposed || !sfxOn) return;
    try {
      // A fresh per-play call on the same player is serialized by the
      // plugin; short clips never overlap destructively.
      await _sfx.play(BytesSource(bytes));
    } catch (_) {
      // Audio must never crash the app.
    }
  }

  // ---------------------------------------------------------------- SFX
  Future<void> click() => _play(_clip('click', () => _tone(1150, 0.06)));
  Future<void> tapSnd() => _play(_clip('tap', _tapSnd));
  Future<void> miss() => _play(_clip('miss', _thud));
  Future<void> found() => _play(_clip('found', _foundSnd));
  Future<void> hint() => _play(_clip('hint', _sparkle));
  Future<void> gameStart() =>
      _play(_clip('start', () => _arp([523.25, 659.25, 783.99], 0.14, 0.03)));
  Future<void> sceneDone() =>
      _play(_clip('scenedone', () => _arp([659.25, 783.99, 1046.5], 0.13, 0.02)));
  Future<void> win() => _play(
      _clip('win', () => _arp([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.18, 0.04)));
  Future<void> lose() =>
      _play(_clip('lose', () => _arp([392.0, 329.63, 261.63, 196.0], 0.22, 0.04)));
  Future<void> pauseSnd() => _play(_clip('pause', () => _tone(660, 0.12, freqEnd: 330)));

  // ------------------------------------------------------ music control
  Future<void> _startTrack(String track, Uint8List Function() bytes) async {
    final gen = ++_musicGen;
    if (_musicBusy) {
      // A transition is already in flight; the generation bump above means
      // the in-flight work will abort and this call owns the outcome.
    }
    _musicBusy = true;
    try {
      if (_currentTrack == track) {
        // Already on this track — nothing to do, but the generation bump
        // above cancelled any in-flight stop for it.
        return;
      }
      if (!musicOn || _disposed) {
        _currentTrack = null;
        return;
      }
      final data = bytes(); // cached after first build
      if (gen != _musicGen || _disposed) return; // superseded
      await _music.stop();
      if (gen != _musicGen || _disposed) return;
      await _music.play(BytesSource(data));
      if (gen != _musicGen || _disposed) {
        await _music.stop().catchError((_) {});
        return;
      }
      _currentTrack = track;
    } catch (_) {
      // Never crash on audio.
    } finally {
      if (gen == _musicGen) _musicBusy = false;
    }
  }

  Future<void> startMenuMusic() => _startTrack('menu', _menuBytes);
  Future<void> startGameMusic() => _startTrack('game', _gameBytes);

  Future<void> stopMusic() async {
    ++_musicGen;
    _currentTrack = null;
    try {
      await _music.stop();
    } catch (_) {}
    _musicBusy = false;
  }

  /// Lifecycle: pause (not stop) so we resume exactly where we left off.
  Future<void> onAppPaused() async {
    if (_disposed) return;
    try {
      if (_currentTrack != null) {
        await _music.pause();
        _pausedByLifecycle = true;
      }
    } catch (_) {}
  }

  Future<void> onAppResumed() async {
    if (_disposed || !_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    try {
      if (musicOn && _currentTrack != null) {
        await _music.resume();
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    _disposed = true;
    ++_musicGen;
    try {
      await _sfx.dispose();
    } catch (_) {}
    try {
      await _music.dispose();
    } catch (_) {}
  }
}
