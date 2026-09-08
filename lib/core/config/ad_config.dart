import 'package:flutter/foundation.dart';

/// Single source of truth for every AdMob identifier the app uses.
///
/// There are two *different* kinds of AdMob identifier and they must never
/// be swapped:
///
///  * **App ID** — one per platform, lives in the native config
///    (`AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`,
///    iOS `Info.plist` → `GADApplicationIdentifier`). Format contains a
///    `~`: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`. It is **not** used
///    from Dart — it is documented here only so the values stay together.
///  * **Ad unit ID** — one per placement (banner / interstitial / rewarded),
///    passed to `BannerAd` / `InterstitialAd.load` / `RewardedAd.load`.
///    Format contains a `/`: `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`.
///
/// ## Test vs production
///
/// Debug/profile builds always use Google's official **test** ad unit IDs
/// (below) so no AdMob account is needed to develop, and Google never
/// flags the account for invalid traffic.
///
/// Release builds use the real ad unit IDs **only if** they are injected
/// at build time with `--dart-define`; otherwise they fall back to the
/// test IDs (a release build with test ads is safe — it just earns
/// nothing). Wire real IDs like this:
///
/// ```
/// flutter build appbundle --release \
///   --dart-define=BANNER_AD_UNIT_ID_ANDROID=ca-app-pub-.../... \
///   --dart-define=INTERSTITIAL_AD_UNIT_ID_ANDROID=ca-app-pub-.../... \
///   --dart-define=REWARDED_AD_UNIT_ID_ANDROID=ca-app-pub-.../...
/// ```
///
/// (`_IOS` variants exist for each.) You must also replace the sample
/// **App ID** in `AndroidManifest.xml` / iOS `Info.plist` with your real
/// one before shipping real ads.
abstract final class AdConfig {
  const AdConfig._();

  // ── Google sample App IDs (native config only — see class doc) ──
  static const String sampleAndroidAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String sampleIosAppId =
      'ca-app-pub-3940256099942544~1458002511';

  // ── Google official test ad unit IDs ──
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';

  // ── Real ad unit IDs, injected at build time (empty by default) ──
  static const String _bannerAndroid =
      String.fromEnvironment('BANNER_AD_UNIT_ID_ANDROID');
  static const String _bannerIos =
      String.fromEnvironment('BANNER_AD_UNIT_ID_IOS');
  static const String _interstitialAndroid =
      String.fromEnvironment('INTERSTITIAL_AD_UNIT_ID_ANDROID');
  static const String _interstitialIos =
      String.fromEnvironment('INTERSTITIAL_AD_UNIT_ID_IOS');
  static const String _rewardedAndroid =
      String.fromEnvironment('REWARDED_AD_UNIT_ID_ANDROID');
  static const String _rewardedIos =
      String.fromEnvironment('REWARDED_AD_UNIT_ID_IOS');

  static bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android;

  /// In debug/profile we force the test IDs; in release we use a real ID
  /// when one was supplied, else fall back to the test ID.
  static String _resolve({
    required String real,
    required String testId,
  }) {
    if (kReleaseMode && real.isNotEmpty) return real;
    return testId;
  }

  static String get bannerAdUnitId => _resolve(
        real: _isAndroid ? _bannerAndroid : _bannerIos,
        testId: _isAndroid ? _testBannerAndroid : _testBannerIos,
      );

  static String get interstitialAdUnitId => _resolve(
        real: _isAndroid ? _interstitialAndroid : _interstitialIos,
        testId: _isAndroid ? _testInterstitialAndroid : _testInterstitialIos,
      );

  static String get rewardedAdUnitId => _resolve(
        real: _isAndroid ? _rewardedAndroid : _rewardedIos,
        testId: _isAndroid ? _testRewardedAndroid : _testRewardedIos,
      );

  /// True when this build would serve *real* (revenue-earning) ads — i.e.
  /// a release build with at least one real unit ID injected. Handy for
  /// startup diagnostics.
  static bool get usingProductionIds {
    if (!kReleaseMode) return false;
    final ids = _isAndroid
        ? [_bannerAndroid, _interstitialAndroid, _rewardedAndroid]
        : [_bannerIos, _interstitialIos, _rewardedIos];
    return ids.any((id) => id.isNotEmpty);
  }
}
