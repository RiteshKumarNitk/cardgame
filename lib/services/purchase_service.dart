import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../features/shop/domain/coin_pack.dart';
import '../game/ads_service.dart';
import 'analytics_service.dart';

/// Outcome of an attempted purchase/restore.
enum PurchaseOutcome { success, cancelled, unavailable, failed }

/// A purchase attempt's result. [restoredRemoveAds] is only meaningful for
/// restore flows — whether the Remove Ads entitlement was found.
class PurchaseResult {
  const PurchaseResult.success({this.restoredRemoveAds = false})
    : outcome = PurchaseOutcome.success,
      message = null;

  const PurchaseResult.cancelled()
    : outcome = PurchaseOutcome.cancelled,
      message = null,
      restoredRemoveAds = false;

  const PurchaseResult.unavailable([this.message])
    : outcome = PurchaseOutcome.unavailable,
      restoredRemoveAds = false;

  const PurchaseResult.failed([this.message])
    : outcome = PurchaseOutcome.failed,
      restoredRemoveAds = false;

  final PurchaseOutcome outcome;
  final String? message;
  final bool restoredRemoveAds;

  bool get isSuccess => outcome == PurchaseOutcome.success;
}

/// All store transactions go through this facade instead of touching
/// RevenueCat's SDK directly, so pages can be tested with fakes and the
/// "not configured" (dev/web/test) story lives in exactly one file.
///
/// When RevenueCat is *not* configured (no `REVENUECAT_*_KEY` dart-define,
/// web, or widget tests), every method degrades to [PurchaseOutcome.unavailable]
/// — callers decide whether to fall back to a local simulation. See
/// [RevenueCatPurchaseService] for the package/entitlement conventions.
abstract interface class PurchaseService {
  /// True only when RevenueCat was configured at startup. Async because
  /// the SDK reports configuration through a platform channel.
  Future<bool> get isAvailable;

  /// Purchases the package mapped to [pack]. Success means the store
  /// completed a real transaction — the caller grants the coins exactly
  /// once, right after this returns.
  Future<PurchaseResult> purchaseCoinPack(CoinPack pack);

  /// Purchases the Remove Ads (non-consumable) entitlement. Success means
  /// the entitlement is active; the caller then mirrors it into local
  /// state so ad placements respect it.
  Future<PurchaseResult> purchaseRemoveAds();

  /// Runs the platform restore-purchases flow and reports whether the
  /// Remove Ads entitlement was restored.
  Future<PurchaseResult> restorePurchases();

  /// Mirrors already-owned entitlements (e.g. a reinstall or a purchase
  /// made on another device) into local state. Safe to call at startup.
  Future<void> syncEntitlements();
}

/// RevenueCat-backed [PurchaseService].
///
/// Dashboard conventions this code expects:
///  - The Remove Ads non-consumable maps to entitlement `remove_ads` and
///    a package identified `remove_ads`.
///  - Each coin pack maps to a package whose identifier (or underlying
///    store product identifier) equals the pack's `id` (`pack_small`,
///    `pack_medium`, `pack_large`).
class RevenueCatPurchaseService implements PurchaseService {
  RevenueCatPurchaseService._();

  static final RevenueCatPurchaseService _instance =
      RevenueCatPurchaseService._();
  factory RevenueCatPurchaseService() => _instance;

  /// Entitlement identifier for Remove Ads — must match the RevenueCat
  /// dashboard (and the existing settings restore flow).
  static const String removeAdsEntitlement = 'remove_ads';

  @override
  Future<bool> get isAvailable async {
    if (kIsWeb) return false;
    try {
      return await Purchases.isConfigured;
    } catch (_) {
      // MissingPluginException in tests, failed init, etc.
      return false;
    }
  }

  @override
  Future<PurchaseResult> purchaseCoinPack(CoinPack pack) async {
    if (!await isAvailable) return const PurchaseResult.unavailable();
    try {
      final pkg = await _packageFor(pack.id);
      if (pkg == null) {
        return PurchaseResult.unavailable(
          'No store product configured for ${pack.id}',
        );
      }
      await Purchases.purchasePackage(pkg);
      return const PurchaseResult.success();
    } on PlatformException catch (e) {
      return _mapError(e, alreadyOwnedIsSuccess: false);
    }
  }

  @override
  Future<PurchaseResult> purchaseRemoveAds() async {
    if (!await isAvailable) return const PurchaseResult.unavailable();
    try {
      // Already owned (reinstall, other device, previous restore)?
      if (await _hasRemoveAdsEntitlement()) {
        return const PurchaseResult.success();
      }

      final pkg = await _packageFor(removeAdsEntitlement);
      if (pkg == null) {
        return const PurchaseResult.unavailable(
          'No store product configured for remove_ads',
        );
      }

      await Purchases.purchasePackage(pkg);
      if (await _hasRemoveAdsEntitlement()) {
        return const PurchaseResult.success();
      }
      return const PurchaseResult.failed('Entitlement was not granted');
    } on PlatformException catch (e) {
      // A non-consumable reported as already purchased means it's owned
      // but not yet synced locally — treat it as a success.
      return _mapError(e, alreadyOwnedIsSuccess: true);
    }
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    if (!await isAvailable) return const PurchaseResult.unavailable();
    try {
      final info = await Purchases.restorePurchases();
      final restored = _hasRemoveAds(info);
      return PurchaseResult.success(restoredRemoveAds: restored);
    } on PlatformException catch (e) {
      return _mapError(e, alreadyOwnedIsSuccess: true);
    }
  }

  @override
  Future<void> syncEntitlements() async {
    if (!await isAvailable) return;
    try {
      if (await _hasRemoveAdsEntitlement()) {
        await HiveAdsService().removeAds();
      }
    } catch (e) {
      debugPrint('PurchaseService syncEntitlements failed: $e');
    }
  }

  /// Finds the [Package] for [identifier]: first by package identifier,
  /// then by the underlying store product identifier (in case the
  /// dashboard names packages differently from the SKUs).
  Future<Package?> _packageFor(String identifier) async {
    final offerings = await Purchases.getOfferings();
    final offering =
        offerings.current ?? offerings.all.values.firstOrNull;
    if (offering == null) return null;

    final byPackage = offering.getPackage(identifier);
    if (byPackage != null) return byPackage;

    for (final package in offering.availablePackages) {
      if (package.storeProduct.identifier == identifier) return package;
    }
    return null;
  }

  Future<bool> _hasRemoveAdsEntitlement() async {
    final info = await Purchases.getCustomerInfo();
    return _hasRemoveAds(info);
  }

  bool _hasRemoveAds(CustomerInfo info) =>
      info.entitlements.active[removeAdsEntitlement]?.isActive ?? false;

  PurchaseResult _mapError(
    PlatformException e, {
    required bool alreadyOwnedIsSuccess,
  }) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    switch (code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return const PurchaseResult.cancelled();
      case PurchasesErrorCode.productAlreadyPurchasedError:
        if (alreadyOwnedIsSuccess) return const PurchaseResult.success();
        return const PurchaseResult.failed('Product already purchased');
      case PurchasesErrorCode.purchaseNotAllowedError:
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
      case PurchasesErrorCode.configurationError:
        return PurchaseResult.unavailable(e.message);
      default:
        debugPrint('RevenueCat purchase error: $e');
        AnalyticsService().recordError(
          e,
          StackTrace.current,
          reason: 'Store purchase failed (${e.code})',
        );
        return PurchaseResult.failed(e.message);
    }
  }
}
