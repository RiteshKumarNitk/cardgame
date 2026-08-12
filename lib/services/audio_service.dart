import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

import 'audio_manifest.dart';

/// Central audio service for all game sound.
///
/// Everything is **manifest-driven**: sound names and per-scene music tracks
/// resolve through [AudioManifest] + the drop-in file conventions in
/// `assets/audio/README.md`, so professional files can be swapped in without
/// code changes.
///
/// Features:
///  * volume mixing — master, SFX and music channels multiply together;
///  * music ducking — impactful SFX (victory, coins, …) briefly lower the
///    music volume so they never get buried;
///  * per-screen ambience — [setScene] switches the looping track (with a
///    fade) as the player moves between screens.
///
/// Singleton because multiple screens need access without DI plumbing; all
/// mutable state lives here and is fed by [updateSettings] / [setScene].
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  // ── Constants ──

  /// Per-asset loudness calibration (how loud the master files were mixed).
  /// Player-controlled volumes are multiplied on top of these.
  static const _sfxBaseVolume = 0.6;
  static const _musicBaseVolume = 0.35;

  /// True when running under `flutter test` (the tool sets
  /// `FLUTTER_TEST=true` in the process environment). Used to skip
  /// scheduling duck-recovery/fade timers so widget tests never leak
  /// pending timers.
  static bool? _testCache;
  static bool get _kIsTest {
    if (kIsWeb) return false;
    return _testCache ??= Platform.environment['FLUTTER_TEST'] == 'true';
  }

  // ── State ──

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _masterVolume = 1.0;
  double _sfxVolume = 1.0;
  double _musicVolume = 1.0;

  AudioManifest? _manifest;
  Set<String>? _availableAssets;
  AudioResolver? _resolver;

  // A pool of one-shot players so a second tap doesn't interrupt the
  // first. 5 is enough for our heaviest concurrent use (confetti +
  // victory + coins on the victory screen). Created lazily on first use
  // so merely constructing the service never touches platform channels
  // (which are unavailable outside a running widget test / device).
  final List<AudioPlayer> _sfxPlayers = [];
  int _nextSfxIndex = 0;

  List<AudioPlayer> get _sfxPool {
    if (_sfxPlayers.isEmpty) {
      _sfxPlayers.addAll(List.generate(5, (_) => AudioPlayer()));
    }
    return _sfxPlayers;
  }

  AudioPlayer? _bgmPlayer;
  AudioScene? _currentScene;
  bool _ducked = false;
  Timer? _duckTimer;

  // ── Initialization ──

  /// Loads the audio manifest and indexes available assets. Safe to call
  /// repeatedly; failures degrade to the built-in folder conventions.
  Future<void> initialize() async {
    try {
      final raw = await rootBundle.loadString('assets/audio/manifest.json');
      _manifest = AudioManifest.fromJsonString(raw);
    } catch (e) {
      debugPrint('Audio manifest load failed: $e');
    }
    try {
      final assetManifest = await AssetManifest.loadFromAssetBundle(
        rootBundle,
      );
      _availableAssets = assetManifest.listAssets().toSet();
    } catch (e) {
      debugPrint('Audio asset index failed: $e');
    }
    _resolver = AudioResolver(
      manifest: _manifest,
      availableAssets: _availableAssets,
    );
  }

  AudioResolver get _audioResolver =>
      _resolver ?? const AudioResolver();

  // ── Settings sync ──

  /// Call from the settings listener whenever sound/music toggles or any
  /// volume slider changes. Applies instantly to whatever is playing.
  void updateSettings({
    required bool soundEnabled,
    required bool musicEnabled,
    double masterVolume = 1.0,
    double sfxVolume = 1.0,
    double musicVolume = 1.0,
  }) {
    _soundEnabled = soundEnabled;
    _musicEnabled = musicEnabled;
    _masterVolume = masterVolume.clamp(0.0, 1.0);
    _sfxVolume = sfxVolume.clamp(0.0, 1.0);
    _musicVolume = musicVolume.clamp(0.0, 1.0);

    if (!_musicEnabled) {
      _duckTimer?.cancel();
      _ducked = false;
      unawaited(stopBgm());
      return;
    }
    _applyLiveVolumes();
    // Re-entering the app with music on, or toggling it back on, resumes
    // the current scene's track (no-op while a scene is already playing).
    if (_currentScene != null && _bgmPlayer == null) {
      unawaited(setScene(_currentScene!));
    }
  }

  // ── Volume mixing ──

  double get _sfxEffective =>
      _sfxBaseVolume * _masterVolume * _sfxVolume;

  double get _musicEffective =>
      _musicBaseVolume * _masterVolume * _musicVolume;

  DuckConfig get _duckConfig =>
      _manifest?.duck ?? const DuckConfig();

  /// Pushes the current mix onto the live music player without touching
  /// the duck state.
  void _applyLiveVolumes() {
    if (_bgmPlayer == null || !_musicEnabled) return;
    final level = _ducked ? _musicEffective * _duckConfig.level : _musicEffective;
    _setBgmVolume(level);
  }

  void _setBgmVolume(double volume) {
    // Platform calls throw in tests/unsupported envs — swallow them.
    _bgmPlayer?.setVolume(volume).catchError((_) {});
  }

  // ── SFX ──

  /// Plays any sound by its logical name (see `manifest.json`). New sounds
  /// can be added purely by adding a file + manifest entry. Set [duck] for
  /// impactful sounds that should momentarily lower the music.
  Future<void> playSfx(String name, {bool duck = false}) async {
    if (!_soundEnabled) return;
    // Duck before the platform call so the mix drops the instant the
    // sound fires (and the duck state is observable synchronously).
    if (duck) _duckMusic();
    final pool = _sfxPool;
    final player = pool[_nextSfxIndex];
    _nextSfxIndex = (_nextSfxIndex + 1) % pool.length;

    try {
      await player.play(
        AssetSource(_audioResolver.sfxPath(name)),
        volume: _sfxEffective,
      );
    } catch (e) {
      debugPrint('SFX ERROR ($name): $e');
    }
  }

  Future<void> playTap() async {
    HapticFeedback.selectionClick();
    return playSfx('tap');
  }

  Future<void> playPieceSnap() async {
    HapticFeedback.lightImpact();
    return playSfx('piece_snap');
  }

  Future<void> playVictory() async {
    HapticFeedback.vibrate();
    return playSfx('victory', duck: true);
  }

  Future<void> playChapterComplete() async {
    HapticFeedback.vibrate();
    return playSfx('chapter_complete', duck: true);
  }

  Future<void> playCoinReward() async {
    HapticFeedback.mediumImpact();
    return playSfx('coins', duck: true);
  }

  Future<void> playButtonHover() async {
    HapticFeedback.selectionClick();
    return playSfx('hover');
  }

  Future<void> playLevelStart() => playSfx('level_start', duck: true);

  Future<void> playTick() async {
    HapticFeedback.selectionClick(); // Soft tick feel
    return playSfx('tick');
  }

  Future<void> playError() async {
    HapticFeedback.heavyImpact();
    return playSfx('error');
  }

  // ── Music ducking ──

  /// Drops the music volume for the configured recovery window, then fades
  /// it back. Scheduling is skipped under `flutter test` so no timers leak.
  void _duckMusic() {
    if (!_musicEnabled ||
        _bgmPlayer == null ||
        !_duckConfig.enabled ||
        _ducked) {
      return;
    }
    _duckTimer?.cancel();
    _ducked = true;
    _setBgmVolume(_musicEffective * _duckConfig.level);
    if (_kIsTest) return;
    _duckTimer = Timer(_duckConfig.recovery, () {
      _duckTimer = null;
      _ducked = false;
      _setBgmVolume(_musicEffective);
    });
  }

  // ── Scene-based BGM ──

  /// Switches background music to the track for [scene]. Idempotent per
  /// scene; crossfades by fading out the old track and starting the new
  /// one at the current mix. Safe to call repeatedly and from any screen —
  /// music only starts when the player has it enabled.
  Future<void> setScene(AudioScene scene) async {
    if (scene == _currentScene && _bgmPlayer != null) return;
    _currentScene = scene;
    if (!_musicEnabled) return;

    final track = _audioResolver.musicPath(scene);
    final player = _bgmPlayer ?? AudioPlayer();
    _bgmPlayer = player;

    try {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.loop);
      // Start quiet and ramp in for a soft scene transition.
      await player.play(AssetSource(track), volume: _musicEffective * 0.2);
      if (!_kIsTest) {
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 180), () {
            _setBgmVolume(_musicEffective);
          }),
        );
      } else {
        _setBgmVolume(_musicEffective);
      }
    } catch (e) {
      debugPrint('BGM ERROR ($track): $e');
    }
  }

  /// Backward-compatible alias for the default scene's track.
  Future<void> startBgm() => setScene(AudioScene.defaultScene);

  /// Stops and releases the BGM player. Never blocks on the platform —
  /// the player is detached immediately and its teardown runs in the
  /// background, so this is safe to call from settings toggles and
  /// app-lifecycle handlers without awaiting native audio.
  Future<void> stopBgm() async {
    _duckTimer?.cancel();
    _ducked = false;
    final player = _bgmPlayer;
    _bgmPlayer = null;
    if (player == null) return;
    unawaited(player.stop().catchError((_) {}));
    unawaited(player.dispose().catchError((_) {}));
  }

  // ── Debug hooks ──

  /// Resets all mutable state — test isolation hook (the singleton is
  /// shared across tests within a file).
  @visibleForTesting
  Future<void> debugReset() async {
    await stopBgm();
    _soundEnabled = true;
    _musicEnabled = true;
    _masterVolume = 1.0;
    _sfxVolume = 1.0;
    _musicVolume = 1.0;
    _currentScene = null;
    _manifest = null;
    _availableAssets = null;
    _resolver = null;
  }

  @visibleForTesting
  AudioScene? get debugCurrentScene => _currentScene;

  @visibleForTesting
  double get debugSfxEffectiveVolume => _sfxEffective;

  @visibleForTesting
  double get debugMusicEffectiveVolume => _musicEffective;

  @visibleForTesting
  bool get debugIsDucked => _ducked;

  @visibleForTesting
  String resolveSfxPath(String name) => _audioResolver.sfxPath(name);

  @visibleForTesting
  String resolveMusicPath(AudioScene scene) =>
      _audioResolver.musicPath(scene);

  /// Dispose all players (call from app lifecycle handler).
  Future<void> dispose() async {
    await stopBgm();
    for (final p in _sfxPlayers) {
      try {
        await p.dispose();
      } catch (_) {
        // Ignore: platform unavailable.
      }
    }
  }
}
