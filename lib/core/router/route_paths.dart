/// Centralized route path/name constants.
///
/// Screens and blocs should navigate via these constants instead of
/// hard-coded strings so a path change only ever touches this file.
abstract final class RoutePaths {
  static const String splash = '/';
  static const String home = '/home';
  static const String levels = '/levels';
  static const String puzzle = '/puzzle/:levelId';
  static const String victory = '/victory';
  static const String chapterComplete = '/chapter-complete';
  static const String sectionComplete = '/section-complete';
  static const String settings = '/settings';
  static const String privacyPolicy = '/privacy-policy';
  static const String dailyPuzzle = '/daily-puzzle';
  static const String leaderboard = '/leaderboard';
  static const String achievements = '/achievements';
  static const String shop = '/shop';
  static const String gallery = '/gallery';

  static String puzzleWithId(String levelId) => '/puzzle/$levelId';
}

abstract final class RouteNames {
  static const String splash = 'splash';
  static const String home = 'home';
  static const String levels = 'levels';
  static const String puzzle = 'puzzle';
  static const String victory = 'victory';
  static const String chapterComplete = 'chapterComplete';
  static const String sectionComplete = 'sectionComplete';
  static const String settings = 'settings';
  static const String privacyPolicy = 'privacyPolicy';
  static const String dailyPuzzle = 'dailyPuzzle';
  static const String leaderboard = 'leaderboard';
  static const String achievements = 'achievements';
  static const String shop = 'shop';
  static const String gallery = 'gallery';
}
