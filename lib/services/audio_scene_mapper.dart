import 'audio_manifest.dart';

/// Maps route paths to [AudioScene]s.
///
/// Screens get their ambience track purely from navigation: no per-page
/// wiring, and dropping a `music/<scene>.wav` file in is all that's needed
/// to give a screen its own track. Paths are matched by first segment
/// (template params like `:levelId` never participate).
abstract final class AudioSceneMapper {
  /// Returns the scene for [path], or `null` to keep whatever is playing
  /// (used for transient screens like settings/profile/leaderboard).
  static AudioScene? sceneForPath(String path) {
    final first =
        path.split('/').where((s) => s.isNotEmpty).firstOrNull ?? '';
    switch (first) {
      case '': // splash root — treated as the home hub
      case 'home':
      case 'splash':
        return AudioScene.home;
      case 'levels':
      case 'collections':
        return AudioScene.levels;
      case 'puzzle':
      case 'daily-puzzle':
      case 'photo-puzzles':
      case 'photo-puzzle':
        return AudioScene.puzzle;
      case 'shop':
      case 'cosmetics':
        return AudioScene.shop;
      case 'gallery':
        return AudioScene.gallery;
      case 'victory':
      case 'chapter-complete':
      case 'section-complete':
        return AudioScene.victory;
      default:
        return null;
    }
  }
}
