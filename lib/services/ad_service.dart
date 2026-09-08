import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';

import '../core/config/ad_config.dart';
import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import 'ad_logger.dart';
import 'analytics_service.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  /// All ad unit IDs come from [AdConfig] — test IDs in debug, real IDs
  /// (injected via --dart-define) in release. See that class for details.
  String get _rewardedAdUnitId => AdConfig.rewardedAdUnitId;

  String get _interstitialAdUnitId => AdConfig.interstitialAdUnitId;

  // ── Interstitial ads ──

  /// Max interstitials per day — enough to monetize without being hostile.
  static const int _maxInterstitialsPerDay = 4;
  static const String _interstitialCountKey = 'interstitialCount';
  static const String _interstitialDateKey = 'interstitialDate';

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;

  void loadInterstitial() {
    if (!AppConfig.adsEnabled || kIsWeb) return;
    if (_isLoadingInterstitial || _interstitialAd != null) return;
    _isLoadingInterstitial = true;
    AdLogger.log('Interstitial loading (unit=$_interstitialAdUnitId)');
    try {
      InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            AdLogger.log('Interstitial loaded');
            _interstitialAd = ad;
            _isLoadingInterstitial = false;
          },
          onAdFailedToLoad: (error) {
            AdLogger.logLoadError('Interstitial', error);
            _isLoadingInterstitial = false;
          },
        ),
      );
    } catch (e) {
      AdLogger.log('Interstitial load threw: $e');
      _isLoadingInterstitial = false;
    }
  }

  /// Shows the loaded interstitial, then always calls [onClosed]. Respects
  /// the daily cap; without a loaded ad (or on web/tests) it closes
  /// immediately so gameplay never blocks on ads.
  void showInterstitial({required VoidCallback onClosed}) {
    if (kIsWeb ||
        _interstitialAd == null ||
        !_interstitialAllowedToday()) {
      onClosed();
      return;
    }

    _recordInterstitialShown();
    AnalyticsService().logEvent(AnalyticsService.interstitialShown);

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial(); // Load the next one
        onClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
        onClosed();
      },
    );
    _interstitialAd!.show();
  }

  /// True while the player is still under today's interstitial cap. Falls
  /// back to allowing when storage is unavailable (dev/tests).
  bool _interstitialAllowedToday() {
    try {
      final box = Hive.box(AppConstants.monetizationBoxName);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final date = box.get(_interstitialDateKey) as String?;
      final count = box.get(_interstitialCountKey) as int? ?? 0;
      if (date != today) {
        box.put(_interstitialDateKey, today);
        box.put(_interstitialCountKey, 0);
        return true;
      }
      return count < _maxInterstitialsPerDay;
    } catch (_) {
      return true;
    }
  }

  void _recordInterstitialShown() {
    try {
      final box = Hive.box(AppConstants.monetizationBoxName);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final count = box.get(_interstitialCountKey) as int? ?? 0;
      box.put(_interstitialDateKey, today);
      box.put(_interstitialCountKey, count + 1);
    } catch (_) {}
  }

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  void loadRewardedAd() {
    // Ads disabled for this build, or web (no rewarded-ad support) — no-op.
    if (!AppConfig.adsEnabled || kIsWeb) return;
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;
    AdLogger.log('Rewarded loading (unit=$_rewardedAdUnitId)');

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          AdLogger.log('Rewarded loaded');
          _rewardedAd = ad;
          _isLoading = false;
          AnalyticsService().logEvent(AnalyticsService.rewardedAdLoaded);
        },
        onAdFailedToLoad: (error) {
          AdLogger.logLoadError('Rewarded', error);
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