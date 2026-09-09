import 'dart:async';

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

  /// True while a rewarded ad is actually on screen — blocks a second
  /// [watchRewardedAd] from firing a duplicate request.
  bool _rewardedShowInFlight = false;

  /// One-shot "load then show" handlers. Set by [watchRewardedAd] when no
  /// ad is preloaded; consumed by the next load result.
  VoidCallback? _pendingReward;
  VoidCallback? _pendingUnavailable;
  VoidCallback? _pendingClosed;
  Timer? _rewardedLoadTimeout;

  /// Whether a rewarded ad is preloaded and can be shown immediately.
  bool get isRewardedAdReady => _rewardedAd != null && !_rewardedShowInFlight;

  void loadRewardedAd() {
    // Ads disabled for this build, or web (no rewarded-ad support) — no-op.
    if (!AppConfig.adsEnabled || kIsWeb) return;
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;
    AdLogger.log('Rewarded loading (unit=$_rewardedAdUnitId)');

    try {
      RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            AdLogger.log('Rewarded loaded');
            _rewardedAd = ad;
            _isLoading = false;
            AnalyticsService().logEvent(AnalyticsService.rewardedAdLoaded);
            // A caller is waiting to watch it right now — show immediately.
            if (_pendingReward != null) {
              final onReward = _pendingReward!;
              final onClosed = _pendingClosed!;
              _consumePending();
              _presentRewarded(onReward, onClosed);
            }
          },
          onAdFailedToLoad: (error) {
            AdLogger.logLoadError('Rewarded', error);
            _isLoading = false;
            AnalyticsService().logEvent(
              AnalyticsService.rewardedAdFailed,
              parameters: {'code': error.code, 'reason': error.domain},
            );
            final onUnavailable = _pendingUnavailable;
            _consumePending();
            onUnavailable?.call();
          },
        ),
      );
    } catch (e) {
      AdLogger.log('Rewarded load threw: $e');
      _isLoading = false;
      final onUnavailable = _pendingUnavailable;
      _consumePending();
      onUnavailable?.call();
    }
  }

  void _consumePending() {
    _pendingReward = null;
    _pendingUnavailable = null;
    _pendingClosed = null;
    _rewardedLoadTimeout?.cancel();
    _rewardedLoadTimeout = null;
  }

  /// Attaches the full-screen lifecycle callbacks and shows [_rewardedAd].
  /// [onReward] fires ONLY from `onUserEarnedReward`; [onClosed] fires once
  /// the ad is dismissed or fails to show. The next ad is preloaded after.
  void _presentRewarded(VoidCallback onReward, VoidCallback onClosed) {
    final ad = _rewardedAd;
    if (ad == null) {
      onClosed();
      return;
    }
    _rewardedShowInFlight = true;
    AnalyticsService().logEvent(AnalyticsService.rewardedAdShown);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => AdLogger.log('Rewarded shown'),
      onAdDismissedFullScreenContent: (ad) {
        AdLogger.log('Rewarded dismissed');
        ad.dispose();
        _rewardedAd = null;
        _rewardedShowInFlight = false;
        loadRewardedAd(); // Preload the next one.
        onClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AdLogger.log(
          'Rewarded failed to show: code=${error.code} '
          'domain=${error.domain} message=${error.message}',
        );
        ad.dispose();
        _rewardedAd = null;
        _rewardedShowInFlight = false;
        loadRewardedAd();
        onClosed();
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        AdLogger.log('Rewarded earned (${reward.amount} ${reward.type})');
        AnalyticsService().logEvent(
          AnalyticsService.rewardedAdWatched,
          parameters: {
            'reward_amount': reward.amount,
            'reward_type': reward.type,
          },
        );
        onReward();
      },
    );
  }

  /// Legacy entry point (used by the Puzzle out-of-coins offer): shows a
  /// preloaded rewarded ad, or calls [onAdDismissed] straight away if none
  /// is ready.
  void showRewardedAd({
    required VoidCallback onReward,
    required VoidCallback onAdDismissed,
  }) {
    if (kIsWeb || _rewardedAd == null || _rewardedShowInFlight) {
      onAdDismissed();
      return;
    }
    _presentRewarded(onReward, onAdDismissed);
  }

  /// Shop "Free Coins" entry point. Shows a preloaded rewarded ad
  /// immediately; if none is ready it kicks a load and shows it the moment
  /// it arrives. Exactly one of these happens:
  ///  * [onReward] then [onClosed]  — the user earned the reward
  ///  * [onClosed] alone            — the user dismissed without a reward
  ///  * [onUnavailable]             — no ad could be loaded/shown
  void watchRewardedAd({
    required VoidCallback onReward,
    required VoidCallback onUnavailable,
    required VoidCallback onClosed,
  }) {
    if (!AppConfig.adsEnabled || kIsWeb) {
      onUnavailable();
      return;
    }
    // Already showing, or already waiting on a load — don't stack requests.
    if (_rewardedShowInFlight || _pendingReward != null) {
      onUnavailable();
      return;
    }
    if (isRewardedAdReady) {
      _presentRewarded(onReward, onClosed);
      return;
    }
    // Not ready — load, then show on arrival (with a safety timeout so the
    // caller's button can never stick in "loading" forever).
    _pendingReward = onReward;
    _pendingUnavailable = onUnavailable;
    _pendingClosed = onClosed;
    _rewardedLoadTimeout = Timer(const Duration(seconds: 15), () {
      final onUnavailable = _pendingUnavailable;
      _consumePending();
      onUnavailable?.call();
    });
    loadRewardedAd();
  }
}