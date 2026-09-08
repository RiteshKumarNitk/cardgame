import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/config/ad_config.dart';
import '../../core/config/app_config.dart';
import '../../game/ads_cubit.dart';
import '../../services/ad_logger.dart';
import '../utils/context_read_or_null.dart';

/// The single real AdMob banner placement used across the app.
///
/// Behaviour:
///  * No-op (renders nothing) when ads are compiled out, on web, or once
///    the player owns **Remove Ads** ([AdsCubit] state `true`).
///  * Requests an *anchored adaptive* banner sized to the width of its
///    parent (falls back to the fixed 320×50 banner if the adaptive size
///    can't be resolved), so it never overflows its container.
///  * Loads exactly once — a normal rebuild never triggers a
///    reload/dispose churn.
///  * On load failure it collapses to zero height (no broken empty box)
///    but the failure is always logged with code/message/domain.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _loadRequested = false;

  bool get _adsRemoved => context.watchOrNull<AdsCubit>()?.state ?? false;

  /// Kicks off a single load for the given container [width]. Repeated
  /// calls (from LayoutBuilder rebuilds) are ignored.
  void _ensureLoad(int width) {
    if (_loadRequested) return;
    if (!AppConfig.adsEnabled || kIsWeb) return;
    if (_adsRemoved) return; // Never request an ad for an entitled player.
    _loadRequested = true;
    _loadAd(width);
  }

  Future<void> _loadAd(int width) async {
    final AdSize size;
    try {
      size = await AdSize.getAnchoredAdaptiveBannerAdSize(
            Orientation.portrait,
            width,
          ) ??
          AdSize.banner;
    } catch (e) {
      // Platform channel unavailable (widget tests) — bail cleanly.
      AdLogger.log('Banner size resolution threw: $e');
      return;
    }

    if (!mounted) return;

    AdLogger.log(
      'Banner loading (${size.width}x${size.height}, '
      'unit=${AdConfig.bannerAdUnitId})',
    );

    final banner = BannerAd(
      size: size,
      adUnitId: AdConfig.bannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          AdLogger.log('Banner loaded');
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          AdLogger.logLoadError('Banner', error);
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
            });
          }
        },
        onAdImpression: (_) => AdLogger.log('Banner impression'),
        onAdOpened: (_) => AdLogger.log('Banner opened'),
        onAdClosed: (_) => AdLogger.log('Banner closed'),
      ),
    );

    try {
      await banner.load();
    } catch (e) {
      // Platform channel unavailable (widget tests) or a native failure
      // before the listener fires — collapse cleanly, never rethrow.
      AdLogger.log('Banner load threw: $e');
      banner.dispose();
    }
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.adsEnabled || kIsWeb || _adsRemoved) {
      // Release the native ad if Remove Ads was purchased while mounted.
      if (_bannerAd != null) _disposeAd();
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.maybeOf(context)?.size.width ?? 360;
        _ensureLoad(width.truncate());

        final ad = _bannerAd;
        if (ad == null || !_isLoaded) return const SizedBox.shrink();

        return SafeArea(
          top: false,
          child: SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        );
      },
    );
  }
}
