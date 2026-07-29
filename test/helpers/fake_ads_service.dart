import 'package:puzzle_cards/game/ads_service.dart';

/// In-memory [AdsService] fake shared by tests that render a widget
/// depending on the "ads removed" entitlement — avoids touching real Hive.
class FakeAdsService implements AdsService {
  FakeAdsService([this._adsRemoved = false]);

  bool _adsRemoved;

  @override
  bool get adsRemoved => _adsRemoved;

  @override
  Future<void> removeAds() async {
    _adsRemoved = true;
  }
}
