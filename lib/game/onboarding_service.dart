import 'package:hive/hive.dart';

import '../core/constants/app_constants.dart';

/// Tracks whether the first-run puzzle tutorial has been shown, so it
/// appears exactly once per install.
///
/// Reads the flag from the settings box. When Hive isn't available
/// (widget tests), it behaves as "already seen" so the tutorial never
/// blocks or intercepts tests.
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._();
  factory OnboardingService() => _instance;
  OnboardingService._();

  Box? get _box {
    try {
      return Hive.box(AppConstants.settingsBoxName);
    } catch (_) {
      return null;
    }
  }

  /// True on the very first loaded puzzle; false afterwards (and whenever
  /// the flag cannot be read).
  bool shouldShowTutorial() {
    final box = _box;
    if (box == null) return false;
    final seen = (box.get(AppConstants.onboardingSeenKey) as bool?) ?? false;
    return !seen;
  }

  Future<void> markTutorialSeen() async {
    final box = _box;
    if (box == null) return;
    await box.put(AppConstants.onboardingSeenKey, true);
  }
}
