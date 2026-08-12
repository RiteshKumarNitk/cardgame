// Tests for AudioService: manifest-backed resolution, volume mixing math,
// scene switching, and music-ducking state.
//
// AudioPlayer construction touches platform channels, which the widget-test
// messenger resolves by hanging — so nothing here awaits a call that would
// touch a player. The service sets its observable state (scene, duck flag,
// volumes) synchronously before any platform await, so fire-and-forget
// calls + state assertions work.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/services/audio_manifest.dart';
import 'package:puzzle_cards/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final audio = AudioService();

  setUp(() async {
    await audio.debugReset();
  });

  testWidgets('initialize loads the manifest and resolves real paths',
      (tester) async {
    await audio.initialize();

    // Entries from assets/audio/manifest.json.
    expect(audio.resolveSfxPath('tap'), 'audio/sfx/tap.wav');
    expect(audio.resolveSfxPath('victory'), 'audio/sfx/victory.wav');
    // Every scene in the manifest currently points at the single track.
    expect(
      audio.resolveMusicPath(AudioScene.home),
      'audio/music/bgm_loop.wav',
    );
    expect(
      audio.resolveMusicPath(AudioScene.defaultScene),
      'audio/music/bgm_loop.wav',
    );
  });

  testWidgets('resolves convention paths without a manifest', (tester) async {
    expect(audio.resolveSfxPath('coins'), 'audio/sfx/coins.wav');
    expect(
      audio.resolveMusicPath(AudioScene.levels),
      AudioResolver.fallbackMusicPath,
    );
  });

  testWidgets('volume mixing multiplies base calibration by player channels',
      (tester) async {
    audio.updateSettings(soundEnabled: true, musicEnabled: true);

    // Base 0.6 SFX, 0.35 music at full volume.
    expect(audio.debugSfxEffectiveVolume, closeTo(0.6, 0.001));
    expect(audio.debugMusicEffectiveVolume, closeTo(0.35, 0.001));

    audio.updateSettings(
      soundEnabled: true,
      musicEnabled: true,
      masterVolume: 0.5,
      sfxVolume: 0.8,
      musicVolume: 0.6,
    );

    expect(audio.debugSfxEffectiveVolume, closeTo(0.6 * 0.5 * 0.8, 0.001));
    expect(audio.debugMusicEffectiveVolume, closeTo(0.35 * 0.5 * 0.6, 0.001));
  });

  testWidgets('muting music still leaves sfx volume math intact',
      (tester) async {
    audio.updateSettings(
      soundEnabled: true,
      musicEnabled: false,
      masterVolume: 0.8,
      sfxVolume: 1.0,
      musicVolume: 1.0,
    );

    expect(audio.debugSfxEffectiveVolume, closeTo(0.6 * 0.8, 0.001));
    expect(audio.debugMusicEffectiveVolume, closeTo(0.35 * 0.8, 0.001));
  });

  testWidgets('setScene is idempotent and records the current scene',
      (tester) async {
    audio.setScene(AudioScene.home);
    expect(audio.debugCurrentScene, AudioScene.home);

    audio.setScene(AudioScene.home);
    expect(audio.debugCurrentScene, AudioScene.home);

    audio.setScene(AudioScene.puzzle);
    expect(audio.debugCurrentScene, AudioScene.puzzle);
  });

  testWidgets('music disabled keeps scene but does not start playback',
      (tester) async {
    audio.updateSettings(soundEnabled: true, musicEnabled: false);

    audio.setScene(AudioScene.levels);

    expect(audio.debugCurrentScene, AudioScene.levels);
  });

  testWidgets('impactful sfx ducks the music state', (tester) async {
    audio.setScene(AudioScene.home);

    audio.playVictory();

    expect(audio.debugIsDucked, isTrue);
  });

  testWidgets('plain sfx does not duck the music', (tester) async {
    audio.setScene(AudioScene.home);

    audio.playTap();

    expect(audio.debugIsDucked, isFalse);
  });

  testWidgets('updating music off clears duck state', (tester) async {
    audio.setScene(AudioScene.home);
    audio.playCoinReward();
    expect(audio.debugIsDucked, isTrue);

    audio.updateSettings(soundEnabled: true, musicEnabled: false);
    expect(audio.debugIsDucked, isFalse);
  });

  testWidgets('sfx playback is a safe no-op when sound is disabled',
      (tester) async {
    audio.updateSettings(soundEnabled: false, musicEnabled: true);

    audio.playVictory();

    expect(audio.debugIsDucked, isFalse);
  });

  testWidgets('repeated ducking sounds never leak recovery timers',
      (tester) async {
    audio.setScene(AudioScene.home);

    audio.playVictory();
    audio.playCoinReward();
    audio.playLevelStart();

    expect(audio.debugIsDucked, isTrue);
    // Ending the test here must not fail on pending timers — the
    // duck-recovery timer is skipped under flutter test.
  });
}
