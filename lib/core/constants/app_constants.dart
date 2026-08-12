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
  static const String dailyRewardBoxName = 'daily_reward_box';
  static const String dailyRewardLastClaimedKey = 'lastClaimedDate';
  static const String monetizationBoxName = 'monetization_box';
  static const String adsRemovedKey = 'adsRemoved';
  static const String soundEnabledKey = 'soundEnabled';
  static const String musicEnabledKey = 'musicEnabled';
  static const String onboardingSeenKey = 'onboardingSeen';
  static const String achievementsBoxName = 'achievements_box';
  static const String achievementsCountersKey = 'counters';
  static const String achievementsUnlockedKey = 'unlocked';
  static const String photosBoxName = 'photos_box';
  static const String photosBestStarsKey = 'bestStars';
  static const String profileBoxName = 'profile_box';
  static const String profileNameKey = 'name';
  static const String cosmeticsBoxName = 'cosmetics_box';
  static const String cosmeticsOwnedFramesKey = 'ownedFrames';
  static const String cosmeticsOwnedPieceStylesKey = 'ownedPieceStyles';
  static const String cosmeticsOwnedAvatarsKey = 'ownedAvatars';
  static const String cosmeticsEquippedFrameKey = 'equippedFrame';
  static const String cosmeticsEquippedPieceStyleKey = 'equippedPieceStyle';
  static const String cosmeticsEquippedAvatarKey = 'equippedAvatar';
}
