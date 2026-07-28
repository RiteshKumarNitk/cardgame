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
  static const String settings = '/settings';
  static const String dailyPuzzle = '/daily-puzzle';
  static const String achievements = '/achievements';
  static const String shop = '/shop';

  static String puzzleWithId(String levelId) => '/puzzle/$levelId';
}

abstract final class RouteNames {
  static const String splash = 'splash';
  static const String home = 'home';
  static const String levels = 'levels';
  static const String puzzle = 'puzzle';
  static const String victory = 'victory';
  static const String settings = 'settings';
  static const String dailyPuzzle = 'dailyPuzzle';
  static const String achievements = 'achievements';
  static const String shop = 'shop';
}
