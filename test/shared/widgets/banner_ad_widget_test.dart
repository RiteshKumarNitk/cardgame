// Widget tests for BannerAdWidget. The AdMob platform channel is not
// available under `flutter test`, so a banner never actually loads here —
// these tests verify the safe-degradation contract:
//   * Remove Ads collapses the widget to nothing (no ad request at all).
//   * Without the entitlement the widget still renders harmlessly (the
//     load failure is swallowed, no exception reaches the tester).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:puzzle_cards/game/ads_cubit.dart';
import 'package:puzzle_cards/shared/widgets/banner_ad_widget.dart';

import '../../helpers/fake_ads_service.dart';

Widget _host({required bool adsRemoved}) {
  return MaterialApp(
    home: BlocProvider<AdsCubit>(
      create: (_) => AdsCubit(FakeAdsService(adsRemoved)),
      child: const Scaffold(body: BannerAdWidget()),
    ),
  );
}

void main() {
  testWidgets('collapses to nothing when Remove Ads is owned', (tester) async {
    await tester.pumpWidget(_host(adsRemoved: true));
    await tester.pump();

    expect(find.byType(AdWidget), findsNothing);
    final box = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(BannerAdWidget),
        matching: find.byType(SizedBox),
      ),
    );
    expect(box.width, 0);
    expect(box.height, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without throwing when ads are not removed', (
    tester,
  ) async {
    await tester.pumpWidget(_host(adsRemoved: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // No ad loads in the test environment; the widget stays a no-op box
    // and the load failure must not surface as an exception.
    expect(find.byType(AdWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
