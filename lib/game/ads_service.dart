import 'package:hive/hive.dart';

import '../core/constants/app_constants.dart';

/// Whether the player has purchased "Remove Ads". An interface (rather
/// than a concrete Hive class used directly) so tests can supply an
/// in-memory fake instead of touching real storage.
///
/// Note: there's no real ad network or payment processor wired up here —
/// no AdMob/store credentials exist for this project. This tracks the
/// *entitlement* so the rest of the app (ad placements, the Shop screen)
/// behaves correctly once real ads/IAP are integrated.
abstract interface class AdsService {
  bool get adsRemoved;
  Future<void> removeAds();
}

class HiveAdsService implements AdsService {
  Box get _box => Hive.box(AppConstants.monetizationBoxName);

  @override
  bool get adsRemoved =>
      (_box.get(AppConstants.adsRemovedKey) as bool?) ?? false;

  @override
  Future<void> removeAds() async {
    await _box.put(AppConstants.adsRemovedKey, true);
  }
}
