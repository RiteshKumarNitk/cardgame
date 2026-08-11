import 'package:puzzle_cards/features/shop/domain/coin_pack.dart';
import 'package:puzzle_cards/services/purchase_service.dart';

/// Configurable in-memory [PurchaseService] fake. Tests flip the outcome
/// fields to exercise every branch of the shop/settings purchase flows
/// without touching the RevenueCat SDK.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService({
    this.available = true,
    this.coinPackOutcome = PurchaseOutcome.success,
    this.removeAdsOutcome = PurchaseOutcome.success,
    this.restoreOutcome = PurchaseOutcome.success,
    this.restoredRemoveAds = false,
  });

  bool available;
  PurchaseOutcome coinPackOutcome;
  PurchaseOutcome removeAdsOutcome;
  PurchaseOutcome restoreOutcome;
  bool restoredRemoveAds;

  /// Which packs were purchased (in order) — lets tests assert the exact
  /// store transaction that ran.
  final List<String> purchasedCoinPackIds = [];
  bool removeAdsPurchased = false;
  bool restoreCalled = false;

  @override
  Future<bool> get isAvailable async => available;

  @override
  Future<PurchaseResult> purchaseCoinPack(CoinPack pack) async {
    purchasedCoinPackIds.add(pack.id);
    return switch (coinPackOutcome) {
      PurchaseOutcome.success => const PurchaseResult.success(),
      PurchaseOutcome.cancelled => const PurchaseResult.cancelled(),
      PurchaseOutcome.unavailable => const PurchaseResult.unavailable(),
      PurchaseOutcome.failed => const PurchaseResult.failed('boom'),
    };
  }

  @override
  Future<PurchaseResult> purchaseRemoveAds() async {
    removeAdsPurchased = true;
    return switch (removeAdsOutcome) {
      PurchaseOutcome.success => const PurchaseResult.success(),
      PurchaseOutcome.cancelled => const PurchaseResult.cancelled(),
      PurchaseOutcome.unavailable => const PurchaseResult.unavailable(),
      PurchaseOutcome.failed => const PurchaseResult.failed('boom'),
    };
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    restoreCalled = true;
    return switch (restoreOutcome) {
      PurchaseOutcome.success => PurchaseResult.success(
        restoredRemoveAds: restoredRemoveAds,
      ),
      PurchaseOutcome.cancelled => const PurchaseResult.cancelled(),
      PurchaseOutcome.unavailable => const PurchaseResult.unavailable(),
      PurchaseOutcome.failed => const PurchaseResult.failed('boom'),
    };
  }

  @override
  Future<void> syncEntitlements() async {}
}
