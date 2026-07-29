/// App-wide constants shared across features.
abstract final class AppConstants {
  static const String appName = 'Puzzle Cards';

  // Hive box names — kept here so every feature reads/writes the same
  // box identifiers instead of re-typing string literals.
  static const String levelsBoxName = 'levels_box';
  static const String progressBoxName = 'progress_box';
  static const String settingsBoxName = 'settings_box';
  static const String walletBoxName = 'wallet_box';
  static const String walletCoinsKey = 'coins';
  static const String dailyChallengeBoxName = 'daily_challenge_box';
  static const String dailyChallengeLastCompletedKey = 'lastCompletedDate';
  static const String dailyChallengeStreakKey = 'streak';
  static const String monetizationBoxName = 'monetization_box';
  static const String adsRemovedKey = 'adsRemoved';
}
