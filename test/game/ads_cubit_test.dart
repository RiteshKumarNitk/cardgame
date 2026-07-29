// Unit tests for AdsCubit: starts at the service's entitlement, persists
// and emits true on purchase, and purchasing again is a no-op.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/game/ads_cubit.dart';

import '../helpers/fake_ads_service.dart';

void main() {
  test('starts at the underlying service entitlement', () {
    expect(AdsCubit(FakeAdsService()).state, isFalse);
    expect(AdsCubit(FakeAdsService(true)).state, isTrue);
  });

  test('purchaseRemoveAds persists and emits true', () async {
    final service = FakeAdsService();
    final cubit = AdsCubit(service);

    await cubit.purchaseRemoveAds();

    expect(cubit.state, isTrue);
    expect(service.adsRemoved, isTrue);
  });

  test('purchasing again is a no-op', () async {
    final cubit = AdsCubit(FakeAdsService(true));

    await cubit.purchaseRemoveAds();

    expect(cubit.state, isTrue);
  });
}
