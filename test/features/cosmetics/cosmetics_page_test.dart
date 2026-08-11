// Widget tests for the cosmetics shop: renders the category tabs and
// item grid, buying spends coins and equips the item, switching tabs
// shows the right category, and a short wallet produces a friendly
// "Not enough coins" message instead of buying.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/cosmetics/domain/services/cosmetics_catalog.dart';
import 'package:puzzle_cards/features/cosmetics/presentation/bloc/cosmetics_cubit.dart';
import 'package:puzzle_cards/features/cosmetics/presentation/pages/cosmetics_page.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';

import '../../helpers/fake_cosmetics_repository.dart';
import '../../helpers/fake_wallet_service.dart';

Widget _wrap({
  required WalletCubit walletCubit,
  required CosmeticsCubit cosmeticsCubit,
  CosmeticsCategory? initialCategory,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<WalletCubit>(create: (_) => walletCubit),
      BlocProvider<CosmeticsCubit>(create: (_) => cosmeticsCubit),
    ],
    child: MaterialApp(
      theme: AppTheme.game,
      home: CosmeticsPage(initialCategory: initialCategory),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows the three category tabs and the default frames grid', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        walletCubit: WalletCubit(FakeWalletService(1000)),
        cosmeticsCubit: CosmeticsCubit(FakeCosmeticsRepository()),
      ),
    );
    await tester.pump();

    expect(find.text('Cosmetics'), findsOneWidget);
    expect(find.text('Board Frames'), findsOneWidget);
    expect(find.text('Piece Styles'), findsOneWidget);
    expect(find.text('Avatars'), findsOneWidget);

    // Frames tab is selected by default.
    expect(find.text('Golden'), findsOneWidget);
    expect(find.text('Equipped'), findsOneWidget); // Classic is equipped.
  });

  testWidgets('switching tabs shows that category\'s items', (tester) async {
    await tester.pumpWidget(
      _wrap(
        walletCubit: WalletCubit(FakeWalletService(1000)),
        cosmeticsCubit: CosmeticsCubit(FakeCosmeticsRepository()),
        initialCategory: CosmeticsCategory.avatars,
      ),
    );
    await tester.pump();

    // The grid builds lazily: the first item is visible, later ones
    // require scrolling.
    expect(find.text('Paw'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Gem'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Gem'), findsOneWidget);
  });

  testWidgets('buying an item spends coins and equips it', (tester) async {
    final walletCubit = WalletCubit(FakeWalletService(1000));
    await tester.pumpWidget(
      _wrap(
        walletCubit: walletCubit,
        cosmeticsCubit: CosmeticsCubit(FakeCosmeticsRepository()),
      ),
    );
    await tester.pump();

    // Golden frame costs 450. Tap its price button.
    await tester.ensureVisible(find.text('450'));
    await tester.pump();
    await tester.tap(find.text('450'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(walletCubit.state, 550);
    // Buying equips immediately: Golden shows the Equipped badge.
    expect(find.text('Equipped'), findsNWidgets(1));
  });

  testWidgets('a short wallet shows a snackbar and does not buy', (
    tester,
  ) async {
    final walletCubit = WalletCubit(FakeWalletService(100));
    await tester.pumpWidget(
      _wrap(
        walletCubit: walletCubit,
        cosmeticsCubit: CosmeticsCubit(FakeCosmeticsRepository()),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('450'));
    await tester.pump();
    await tester.tap(find.text('450'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(walletCubit.state, 100); // untouched
    expect(find.text('Not enough coins'), findsOneWidget);
    // Still not owned: Golden keeps showing its price.
    expect(find.text('450'), findsOneWidget);
  });

  testWidgets('equipping an owned item switches the Equipped badge', (
    tester,
  ) async {
    final cosmeticsCubit = CosmeticsCubit(FakeCosmeticsRepository());
    // Buy the Paw, then switch back to the default avatar so the Paw is
    // owned but not equipped — its button should read Equip.
    final paw = CosmeticsCatalog.avatars.firstWhere((a) => a.id == 'paw');
    await cosmeticsCubit.buy(paw, (amount) async => true);
    await cosmeticsCubit.equip(CosmeticsCatalog.avatars.first);

    await tester.pumpWidget(
      _wrap(
        walletCubit: WalletCubit(FakeWalletService(1000)),
        cosmeticsCubit: cosmeticsCubit,
        initialCategory: CosmeticsCategory.avatars,
      ),
    );
    await tester.pump();

    // Paw (owned, not equipped) → Equip. Default avatar → Equipped.
    await tester.ensureVisible(find.text('Equip'));
    await tester.pump();
    await tester.tap(find.text('Equip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(cosmeticsCubit.state.equippedAvatar, 'paw');
    // Paw shows the Equipped badge; the default avatar (now unequipped)
    // switches to showing Equip in its place.
    expect(find.text('Equipped'), findsOneWidget);
    expect(find.text('Equip'), findsOneWidget);
  });
}
