import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Central analytics + crash-reporting facade.
///
/// Every feature reports through here instead of touching the Firebase
/// SDKs directly, so:
///  - platforms where Firebase was never bootstrapped (web, widget tests,
///    failed init) are safe no-ops — nothing throws, nothing crashes;
///  - event names stay in one place and are typo-checked;
///  - adding a reporting backend later is a one-file change.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  /// True only when a Firebase App has actually been initialized. Guards
  /// every call so the service is a safe no-op where Firebase is absent.
  static bool get _firebaseReady {
    if (kIsWeb) return false;
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAnalytics? get _analytics => _firebaseReady ? FirebaseAnalytics.instance : null;
  FirebaseCrashlytics? get _crashlytics =>
      _firebaseReady ? FirebaseCrashlytics.instance : null;

  /// Wires Flutter's uncaught-error hooks into Crashlytics. Call once in
  /// `main()` after Firebase initialization succeeds.
  void enableCrashReporting() {
    if (!_firebaseReady) return;
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _crashlytics?.recordError(
        details.exception,
        details.stack ?? StackTrace.current,
        reason: details.context?.toString(),
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics?.recordError(error, stack);
      return true;
    };
  }

  /// Fires a named event with optional parameters. No-op unless Firebase
  /// is ready; failures are swallowed (analytics must never break play).
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Swallow — reporting is best-effort.
    }
  }

  /// Records a non-fatal error against the current user's session.
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    String? reason,
  }) async {
    final crashlytics = _crashlytics;
    if (crashlytics == null) return;
    try {
      await crashlytics.recordError(
        error,
        stack,
        reason: reason ?? error.toString(),
      );
    } catch (_) {
      // Swallow — reporting is best-effort.
    }
  }

  /// Tags the current user so analytics/crashes can be correlated. Pass
  /// `null` when the user signs out.
  Future<void> setUserId(String? userId) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      if (userId == null) {
        await analytics.setUserId();
      } else {
        await analytics.setUserId(id: userId);
      }
    } catch (_) {}
  }

  // ── Canonical event names ──

  static const String appLaunch = 'app_launch';

  static const String levelStart = 'level_start';
  static const String levelComplete = 'level_complete';
  static const String hintUsed = 'hint_used';

  static const String dailyChallengeStarted = 'daily_challenge_started';
  static const String dailyChallengeComplete = 'daily_challenge_complete';
  static const String dailyChallengeFailed = 'daily_challenge_failed';

  static const String coinsEarned = 'coins_earned';
  static const String coinsSpent = 'coins_spent';
  static const String dailyRewardClaimed = 'daily_reward_claimed';

  static const String rewardedAdLoaded = 'rewarded_ad_loaded';
  static const String rewardedAdFailed = 'rewarded_ad_failed';
  static const String rewardedAdShown = 'rewarded_ad_shown';
  static const String rewardedAdWatched = 'rewarded_ad_watched';

  static const String removeAdsPurchased = 'remove_ads_purchased';
  static const String coinPackPurchased = 'coin_pack_purchased';
  static const String purchasesRestored = 'purchases_restored';

  static const String achievementRewarded = 'achievement_rewarded';
  static const String authSignedIn = 'auth_signed_in';

  static const String cosmeticPurchased = 'cosmetic_purchased';
  static const String cosmeticEquipped = 'cosmetic_equipped';
}
