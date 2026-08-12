import 'dart:convert';

/// Audio scene identifiers — one per family of screens. Each scene maps to
/// a music track (see [AudioResolver.musicPath]). Scene keys are stable
/// snake_case strings so the manifest and the drop-in file convention
/// (`audio/music/<scene>.wav`) can reference them.
enum AudioScene {
  defaultScene('default'),
  home('home'),
  levels('levels'),
  puzzle('puzzle'),
  photoPuzzle('photo_puzzle'),
  shop('shop'),
  gallery('gallery'),
  victory('victory');

  const AudioScene(this.key);

  /// Stable identifier used by `manifest.json` and the asset convention.
  final String key;
}

/// Ducking behaviour: when an impactful SFX plays, music volume drops to
/// `level` × its normal volume for `recovery`, then fades back.
class DuckConfig {
  const DuckConfig({
    this.enabled = true,
    this.level = 0.25,
    this.recovery = const Duration(milliseconds: 400),
  });

  final bool enabled;
  final double level;
  final Duration recovery;

  factory DuckConfig.fromJson(Map<String, dynamic> json) => DuckConfig(
    enabled: json['enabled'] as bool? ?? true,
    level: (json['level'] as num?)?.toDouble() ?? 0.25,
    recovery: Duration(
      milliseconds: (json['recoveryMs'] as num?)?.toInt() ?? 400,
    ),
  );
}

/// Parsed `assets/audio/manifest.json`. Entries are optional — missing keys
/// fall back to the folder conventions in [AudioResolver].
class AudioManifest {
  const AudioManifest({
    this.sfx = const {},
    this.music = const {},
    this.duck = const DuckConfig(),
  });

  /// Logical sound name -> asset path (e.g. `"tap": "audio/sfx/tap.wav"`).
  final Map<String, String> sfx;

  /// Scene key -> asset path (e.g. `"home": "audio/music/home_loop.wav"`).
  final Map<String, String> music;

  final DuckConfig duck;

  factory AudioManifest.fromJsonString(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const AudioManifest();
    }
    if (decoded is! Map<String, dynamic>) return const AudioManifest();
    return AudioManifest.fromJson(decoded);
  }

  factory AudioManifest.fromJson(Map<String, dynamic> json) {
    Map<String, String> stringMap(Object? value) {
      if (value is! Map<String, dynamic>) return const {};
      return value.map(
        (key, entry) => MapEntry(key, entry is String ? entry : key),
      );
    }

    return AudioManifest(
      sfx: stringMap(json['sfx']),
      music: stringMap(json['music']),
      duck: json['duck'] is Map<String, dynamic>
          ? DuckConfig.fromJson(json['duck'] as Map<String, dynamic>)
          : const DuckConfig(),
    );
  }
}

/// Resolves logical sound/scene names to concrete asset paths.
///
/// Resolution order, from most to least specific:
///  * an explicit entry in the loaded [AudioManifest];
///  * the drop-in file convention (`audio/sfx/<name>.wav` for SFX,
///    `audio/music/<scene>.wav` for music — the latter only when that asset
///    actually exists in the bundle);
///  * the manifest `default` music track, else `audio/music/bgm_loop.wav`.
class AudioResolver {
  const AudioResolver({this.manifest, this.availableAssets});

  final AudioManifest? manifest;
  final Set<String>? availableAssets;

  static const fallbackMusicPath = 'audio/music/bgm_loop.wav';

  String sfxPath(String name) =>
      manifest?.sfx[name] ?? 'audio/sfx/$name.wav';

  String musicPath(AudioScene scene) {
    final explicit = manifest?.music[scene.key];
    if (explicit != null) return explicit;

    final conventional = 'audio/music/${scene.key}.wav';
    if (availableAssets?.contains(conventional) ?? false) return conventional;

    return manifest?.music[AudioScene.defaultScene.key] ?? fallbackMusicPath;
  }
}
