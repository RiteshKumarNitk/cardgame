import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'analytics_service.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  /// Real ad unit IDs are injected at build time with --dart-define:
  ///   flutter build --dart-define=REWARDED_AD_UNIT_ID_ANDROID=...
  ///   flutter build --dart-define=REWARDED_AD_UNIT_ID_IOS=...
  /// Without them, the well-known Google test IDs are used, so the app
  /// runs in development without any AdMob account.
  static const String _rewardedAndroidUnitId = String.fromEnvironment(
    'REWARDED_AD_UNIT_ID_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );
  static const String _rewardedIosUnitId = String.fromEnvironment(
    'REWARDED_AD_UNIT_ID_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  );

  String get _rewardedAdUnitId => defaultTargetPlatform == TargetPlatform.android
      ? _rewardedAndroidUnitId
      : _rewardedIosUnitId;

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  void loadRewardedAd() {
    // google_mobile_ads has no rewarded-ad support on web — no-op there.
    if (kIsWeb) return;
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          AnalyticsService().logEvent(AnalyticsService.rewardedAdLoaded);
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _isLoading = false;
          AnalyticsService().logEvent(
            AnalyticsService.rewardedAdFailed,
            parameters: {'code': error.code, 'reason': error.domain},
          );
        },
      ),
    );
  }

  /// Shows the loaded rewarded ad. If not loaded, returns false immediately.
  /// The [onReward] callback is invoked if the user fully watches the ad.
  void showRewardedAd({required VoidCallback onReward, required VoidCallback onAdDismissed}) {
    if (kIsWeb || _rewardedAd == null) {
      onAdDismissed();
      return;
    }

    AnalyticsService().logEvent(AnalyticsService.rewardedAdShown);

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Load the next one
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onAdDismissed();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        AnalyticsService().logEvent(
          AnalyticsService.rewardedAdWatched,
          parameters: {'reward_amount': reward.amount, 'reward_type': reward.type},
        );
        onReward();
      },
    );
  }
}