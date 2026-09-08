import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Tiny, debug-only logger for the AdMob lifecycle.
///
/// Every line is prefixed `[AdMob]` so real-device logs can be filtered
/// with `adb logcat | grep AdMob`. Silent in release builds so it never
/// spams production logs, and it never swallows a failure — load errors
/// are printed with their full `code` / `message` / `domain` so a
/// "no ad" state is always diagnosable.
abstract final class AdLogger {
  const AdLogger._();

  static void log(String message) {
    if (kReleaseMode) return;
    debugPrint('[AdMob] $message');
  }

  /// Logs a `LoadAdError` (banner / interstitial / rewarded failure) with
  /// every field that helps explain *why* the ad did not load.
  static void logLoadError(String label, LoadAdError error) {
    if (kReleaseMode) return;
    debugPrint(
      '[AdMob] $label failed: code=${error.code} '
      'domain=${error.domain} message=${error.message}',
    );
    final response = error.responseInfo;
    if (response != null) {
      debugPrint('[AdMob] $label responseInfo: $response');
    }
  }
}
