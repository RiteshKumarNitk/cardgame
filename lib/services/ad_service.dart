import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  /// Test ad unit IDs — replace with real ones before release.
  String get _rewardedAdUnitId => defaultTargetPlatform == TargetPlatform.android
      ? 'ca-app-pub-3940256099942544/5224354917' // Android Test Rewarded ID
      : 'ca-app-pub-3940256099942544/1712485313'; // iOS Test Rewarded ID

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
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _isLoading = false;
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
        onReward();
      },
    );
  }
}