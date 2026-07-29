// Verifies the Shop screen: renders its three sections, buying a coin
// pack credits the wallet, purchasing Remove Ads flips it to "Owned", and
// watching the simulated ad awards coins after its delay.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/shop/presentation/pages/shop_page.dart';
import 'package:puzzle_cards/game/ads_cubit.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';

import '../../helpers/fake_ads_service.dart';
import '../../helpers/fake_wallet_service.dart';

Widget _wrap(Widget child, {WalletCubit? walletCubit, AdsCubit? adsCubit}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<WalletCubit>(
        create: (_) => walletCubit ?? WalletCubit(FakeWalletService()),
      ),
      BlocProvider<AdsCubit>(
        create: (_) => adsCubit ?? AdsCubit(FakeAdsService()),
      ),
    ],
    child: MaterialApp(theme: AppTheme.game, home: child),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows coin packs, free coins, and remove ads sections', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const ShopPage()));
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

  testWidgets('buying a coin pack credits the wallet', (tester) async {
    final walletCubit = WalletCubit(FakeWalletService());
    await tester.pumpWidget(
      _wrap(const ShopPage(), walletCubit: walletCubit),
    );
    await tester.pump();

    await tester.tap(find.text(r'$0.99'));
    await tester.pump();

    expect(walletCubit.state, 100);
  });

  testWidgets('purchasing remove ads shows the Owned badge', (tester) async {
    final adsCubit = AdsCubit(FakeAdsService());
    await tester.pumpWidget(_wrap(const ShopPage(), adsCubit: adsCubit));
    await tester.pump();

    // The Remove Ads card sits below the fold in the scrollable content.
    await tester.ensureVisible(find.text(r'$2.99'));
    await tester.pump();
    await tester.tap(find.text(r'$2.99'));
    await tester.pump();

    expect(adsCubit.state, isTrue);
    expect(find.text('Owned'), findsOneWidget);
    expect(find.text(r'$2.99'), findsNothing);
  });

  testWidgets('watching an ad awards coins after the simulated delay', (
    tester,
  ) async {
    final walletCubit = WalletCubit(FakeWalletService());
    await tester.pumpWidget(
      _wrap(const ShopPage(), walletCubit: walletCubit),
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
