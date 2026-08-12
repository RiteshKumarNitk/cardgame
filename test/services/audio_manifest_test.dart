// Unit tests for the audio manifest model + path resolution: parsing,
// the drop-in file conventions, explicit overrides, and the default track
// fallback.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/services/audio_manifest.dart';

void main() {
  group('AudioManifest parsing', () {
    test('parses sfx, music and duck config', () {
      final manifest = AudioManifest.fromJsonString('''
      {
        "version": 1,
        "sfx": { "tap": "audio/sfx/tap.wav", "victory": "audio/sfx/pro/victory.mp3" },
        "music": { "home": "audio/music/home_loop.mp3" },
        "duck": { "enabled": false, "level": 0.1, "recoveryMs": 250 }
      }
      ''');

      expect(manifest.sfx['tap'], 'audio/sfx/tap.wav');
      expect(manifest.sfx['victory'], 'audio/sfx/pro/victory.mp3');
      expect(manifest.music['home'], 'audio/music/home_loop.mp3');
      expect(manifest.duck.enabled, isFalse);
      expect(manifest.duck.level, 0.1);
      expect(manifest.duck.recovery, const Duration(milliseconds: 250));
    });

    test('defaults gracefully on missing sections and malformed JSON', () {
      final manifest = AudioManifest.fromJsonString('{}');
      expect(manifest.sfx, isEmpty);
      expect(manifest.music, isEmpty);
      expect(manifest.duck.enabled, isTrue);

      final malformed = AudioManifest.fromJsonString('not json');
      expect(malformed.sfx, isEmpty);
      expect(malformed.duck.recovery, const Duration(milliseconds: 400));
    });
  });

  group('AudioResolver sfx resolution', () {
    test('uses the folder convention when the manifest has no entry', () {
      const resolver = AudioResolver();
      expect(resolver.sfxPath('tap'), 'audio/sfx/tap.wav');
    });

    test('prefers an explicit manifest override', () {
      final resolver = AudioResolver(
        manifest: AudioManifest(
          sfx: const {'tap': 'audio/sfx/master/tap_alt.wav'},
        ),
      );
      expect(resolver.sfxPath('tap'), 'audio/sfx/master/tap_alt.wav');
      expect(resolver.sfxPath('unknown'), 'audio/sfx/unknown.wav');
    });
  });

  group('AudioResolver music resolution', () {
    test('prefers an explicit manifest entry', () {
      final resolver = AudioResolver(
        manifest: AudioManifest(music: const {'home': 'audio/music/hub.mp3'}),
      );
      expect(resolver.musicPath(AudioScene.home), 'audio/music/hub.mp3');
    });

    test(
      'uses the drop-in convention when the asset exists in the bundle',
      () {
        final resolver = AudioResolver(
          availableAssets: const {'audio/music/levels.wav'},
        );
        expect(resolver.musicPath(AudioScene.levels), 'audio/music/levels.wav');
      },
    );

    test('falls back to the manifest default, then bgm_loop', () {
      const noTrack = AudioResolver();
      expect(
        noTrack.musicPath(AudioScene.shop),
        AudioResolver.fallbackMusicPath,
      );

      final withDefault = AudioResolver(
        manifest: AudioManifest(music: const {'default': 'audio/music/menu.mp3'}),
      );
      expect(withDefault.musicPath(AudioScene.shop), 'audio/music/menu.mp3');
    });
  });

  group('AudioScene', () {
    test('keys are stable snake_case identifiers', () {
      expect(AudioScene.photoPuzzle.key, 'photo_puzzle');
      expect(AudioScene.defaultScene.key, 'default');
      expect(AudioScene.victory.key, 'victory');
    });
  });
}
