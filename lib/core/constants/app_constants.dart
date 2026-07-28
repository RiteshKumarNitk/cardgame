/// App-wide constants shared across features.
abstract final class AppConstants {
  static const String appName = 'Puzzle Cards';

  // Hive box names — kept here so every feature reads/writes the same
  // box identifiers instead of re-typing string literals.
  static const String levelsBoxName = 'levels_box';
  static const String progressBoxName = 'progress_box';
  static const String settingsBoxName = 'settings_box';
}
