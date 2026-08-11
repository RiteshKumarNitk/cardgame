// Verifies the Shop screen: renders its sections, coin packs and Remove
// Ads go through the purchase service (real transaction → grant exactly
// once; cancelled/failed → nothing), and the simulated ad awards coins.
// When no purchase service is injected, the page's dev fallback simulates
// purchases locally (the pre-RevenueCat behavior).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/shop/presentation/pages/shop_page.dart';
import 'package:puzzle_cards/game/ads_cubit.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';
import 'package:puzzle_cards/services/purchase_service.dart';

import '../../helpers/fake_ads_service.dart';
import '../../helpers/fake_purchase_service.dart';
import '../../helpers/fake_wallet_service.dart';

Widget _wrap({
  WalletCubit? walletCubit,
  AdsCubit? adsCubit,
  PurchaseService? purchaseService,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<WalletCubit>(
        create: (_) => walletCubit ?? WalletCubit(FakeWalletService()),
      ),
      BlocProvider<AdsCubit>(
        create: (_) => adsCubit ?? AdsCubit(FakeAdsService()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.game,
      home: ShopPage(purchaseService: purchaseService),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows coin packs, free coins, and remove ads sections', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();

    expect(find.text('Shop'), findsOneWidget);
    // Each section header and its card's own title use the same words.
    expect(find.text('Free Coins'), findsNWidgets(2));
    expect(find.text('Coin Packs'), findsOneWidget);
    expect(find.text('Remove Ads'), findsNWidgets(2));
    expect(find.text('100 Coins'), findsOneWidget);
    expect(find.text('BEST VALUE'), findsOneWidget);
    expect(find.text(r'$2.99'), findsOneWidget);
  });

  testWidgets('buying a coin pack credits the wallet (dev fallback)', (
    tester,
  ) async {
    final walletCubit = WalletCubit(FakeWalletService());
    // A service reporting "not available" triggers the page's dev
    // fallback — the same branch an unconfigured RevenueCat takes.
    final purchaseService = FakePurchaseService(available: false);
    await tester.pumpWidget(
      _wrap(walletCubit: walletCubit, purchaseService: purchaseService),
    );
    await tester.pump();

    await tester.tap(find.text(r'$0.99'));
    await tester.pump();
    // The success path plays the coin-flight animation and opens the
    // confirmation dialog, so pump through those (and their timers).
    await tester.pump(const Duration(seconds: 2));

    expect(walletCubit.state, 100);
    // No store transaction ran.
    expect(purchaseService.purchasedCoinPackIds, isEmpty);
    // Celebration still shows for the simulated purchase.
    expect(find.text('Purchase Complete!'), findsOneWidget);
    await tester.tap(find.text('Awesome!'));
    // Let the dialog's exit transition finish.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Purchase Complete!'), findsNothing);
  });

  testWidgets('coin pack purchase runs through the store and grants once', (
    tester,
  ) async {
    final walletCubit = WalletCubit(FakeWalletService());
    final purchaseService = FakePurchaseService();
    await tester.pumpWidget(
      _wrap(
        walletCubit: walletCubit,
        purchaseService: purchaseService,
      ),
    );
    await tester.pump();

    await tester.tap(find.text(r'$0.99'));
    await tester.pump();
    // The success path plays the coin-flight animation and opens the
    // confirmation dialog, so pump through those (and their timers).
    await tester.pump(const Duration(seconds: 2));

    expect(purchaseService.purchasedCoinPackIds, ['pack_small']);
    expect(walletCubit.state, 100);
    expect(find.text('Purchase Complete!'), findsOneWidget);
    expect(find.text('+100 Coins'), findsOneWidget);
    await tester.tap(find.text('Awesome!'));
    // Let the dialog's exit transition finish.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Purchase Complete!'), findsNothing);
  });

  testWidgets('a cancelled coin pack purchase grants nothing', (tester) async {
    final walletCubit = WalletCubit(FakeWalletService());
    final purchaseService = FakePurchaseService(
      coinPackOutcome: PurchaseOutcome.cancelled,
    );
    await tester.pumpWidget(
      _wrap(
        walletCubit: walletCubit,
        purchaseService: purchaseService,
      ),
    );
    await tester.pump();

    await tester.tap(find.text(r'$0.99'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(purchaseService.purchasedCoinPackIds, ['pack_small']);
    expect(walletCubit.state, 0); // no credit
  });

  testWidgets('a failed coin pack purchase shows an error and grants nothing', (
    tester,
  ) async {
    final walletCubit = WalletCubit(FakeWalletService());
    final purchaseService = FakePurchaseService(
      coinPackOutcome: PurchaseOutcome.failed,
    );
    await tester.pumpWidget(
      _wrap(
        walletCubit: walletCubit,
        purchaseService: purchaseService,
      ),
    );
    await tester.pump();

    await tester.tap(find.text(r'$0.99'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(walletCubit.state, 0);
    expect(find.text('Could not complete purchase — try again'), findsOneWidget);
  });

  testWidgets('purchasing remove ads shows the Owned badge (dev fallback)', (
    tester,
  ) async {
    final adsCubit = AdsCubit(FakeAdsService());
    final purchaseService = FakePurchaseService(available: false);
    await tester.pumpWidget(
      _wrap(adsCubit: adsCubit, purchaseService: purchaseService),
    );
    await tester.pump();

    // The Remove Ads card sits below the fold in the scrollable content.
    await tester.ensureVisible(find.text(r'$2.99'));
    await tester.pump();
    await tester.tap(find.text(r'$2.99'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(adsCubit.state, isTrue);
    expect(purchaseService.removeAdsPurchased, isFalse);
    expect(find.text('Owned'), findsOneWidget);
    expect(find.text(r'$2.99'), findsNothing);
  });

  testWidgets('remove ads purchase runs through the store and activates', (
    tester,
  ) async {
    final adsCubit = AdsCubit(FakeAdsService());
    final purchaseService = FakePurchaseService();
    await tester.pumpWidget(
      _wrap(
        adsCubit: adsCubit,
        purchaseService: purchaseService,
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text(r'$2.99'));
    await tester.pump();
    await tester.tap(find.text(r'$2.99'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(purchaseService.removeAdsPurchased, isTrue);
    expect(adsCubit.state, isTrue);
    expect(find.text('Owned'), findsOneWidget);
  });

  testWidgets('a failed remove ads purchase does not activate ads removed', (
    tester,
  ) async {
    final adsCubit = AdsCubit(FakeAdsService());
    final purchaseService = FakePurchaseService(
      removeAdsOutcome: PurchaseOutcome.failed,
    );
    await tester.pumpWidget(
      _wrap(
        adsCubit: adsCubit,
        purchaseService: purchaseService,
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text(r'$2.99'));
    await tester.pump();
    await tester.tap(find.text(r'$2.99'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(adsCubit.state, isFalse);
    expect(find.text('Could not complete purchase — try again'), findsOneWidget);
  });

  testWidgets('watching an ad awards coins after the simulated delay', (
    tester,
  ) async {
    final walletCubit = WalletCubit(FakeWalletService());
    await tester.pumpWidget(
      _wrap(walletCubit: walletCubit),
    );
    await tester.pump();

    await tester.tap(find.text('Watch Ad'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(walletCubit.state, 25);
  });
}
