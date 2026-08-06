import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// Central audio service for all game sounds. Plays SFX (tap, snap,
/// victory, coins, etc.) and a looping BGM track. Respects the player's
/// sound/music toggles; call [updateSettings] whenever they change.
///
/// Singleton because multiple screens need access without DI plumbing
/// for now — the service itself is stateless (settings live externally).
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  // ── Constants ──

  static const _sfxVolume = 0.6;
  static const _bgmVolume = 0.35;

  // ── State ──

  bool _soundEnabled = true;
  bool _musicEnabled = true;

  // A pool of one-shot players so a second tap doesn't interrupt the
  // first. 3 is enough for our heaviest concurrent use (confetti +
  // victory + coins on the victory screen).
  final List<AudioPlayer> _sfxPlayers = List.generate(
    5,
    (_) => AudioPlayer(),
  );
  int _nextSfxIndex = 0;

  AudioPlayer? _bgmPlayer;

  // ── Settings sync ──

  /// Call this from [SettingsCubit]'s load/toggle methods — or from any
  /// BlocListener that watches settings changes — so the service stays
  /// in sync.
  void updateSettings({required bool soundEnabled, required bool musicEnabled}) {
    _soundEnabled = soundEnabled;
    _musicEnabled = musicEnabled;
    if (!_musicEnabled) stopBgm();
  }

  // ── SFX ──

  Future<void> playTap() async {
    HapticFeedback.selectionClick();
    return _playSfx('tap.wav');
  }

  Future<void> playPieceSnap() async {
    HapticFeedback.lightImpact();
    return _playSfx('piece_snap.wav');
  }

  Future<void> playVictory() async {
    HapticFeedback.vibrate();
    return _playSfx('victory.wav');
  }

  Future<void> playChapterComplete() async {
    HapticFeedback.vibrate();
    return _playSfx('chapter_complete.wav');
  }

  Future<void> playCoinReward() async {
    HapticFeedback.mediumImpact();
    return _playSfx('coins.wav');
  }

  Future<void> playButtonHover() async {
    HapticFeedback.selectionClick();
    return _playSfx('hover.wav');
  }

  Future<void> playLevelStart() => _playSfx('level_start.wav');
  
  Future<void> playTick() async {
    HapticFeedback.selectionClick(); // Soft tick feel
    return _playSfx('tick.wav');
  }

  Future<void> playError() async {
    HapticFeedback.heavyImpact();
    return _playSfx('error.wav');
  }

  // ── BGM ──

  /// Start looping background music — safe to call repeatedly (only
  /// starts if no BGM is currently playing).
  Future<void> startBgm() async {
    if (!_musicEnabled || _bgmPlayer != null) return;
    final player = AudioPlayer();
    _bgmPlayer = player;
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('audio/music/bgm_loop.wav'), volume: _bgmVolume);
    } catch (e) {
      print('BGM ERROR: $e');
    }
  }

  /// Stop and release the BGM player.
  Future<void> stopBgm() async {
    await _bgmPlayer?.stop();
    await _bgmPlayer?.dispose();
    _bgmPlayer = null;
  }

  // ── Internal ──

  Future<void> _playSfx(String filename) async {
    if (!_soundEnabled) return;
    final player = _sfxPlayers[_nextSfxIndex];
    _nextSfxIndex = (_nextSfxIndex + 1) % _sfxPlayers.length;

    try {
      await player.play(AssetSource('audio/sfx/$filename'), volume: _sfxVolume);
    } catch (e) {
      print('SFX ERROR ($filename): $e');
    }
  }

  /// Dispose all players (call from app lifecycle handler).
  Future<void> dispose() async {
    await stopBgm();
    for (final p in _sfxPlayers) {
      await p.dispose();
    }
  }
}
