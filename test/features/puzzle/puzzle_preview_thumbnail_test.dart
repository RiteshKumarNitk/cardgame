// Verifies PuzzlePreviewThumbnail's coin-gated unlock: starts locked,
// spending enough coins reveals the photo, and an insufficient balance
// leaves it locked with a "not enough coins" message.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/puzzle/presentation/widgets/puzzle_preview_thumbnail.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';

import '../../helpers/fake_wallet_service.dart';

Widget _wrap(Widget child, WalletCubit walletCubit) {
  return BlocProvider<WalletCubit>.value(
    value: walletCubit,
    child: MaterialApp(theme: AppTheme.game, home: Scaffold(body: child)),
  );
}

const _imageUrl = 'https://picsum.photos/seed/test/200/200';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('starts locked and shows the unlock cost', (tester) async {
    final walletCubit = WalletCubit(FakeWalletService(100));

    await tester.pumpWidget(
      _wrap(
        const PuzzlePreviewThumbnail(imageUrl: _imageUrl, unlockCost: 15),
        walletCubit,
      ),
    );
    await tester.pump();

    expect(find.text('Preview locked'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });

  testWidgets('unlocks and spends coins when the balance is sufficient', (
    tester,
  ) async {
    final walletCubit = WalletCubit(FakeWalletService(100));

    await tester.pumpWidget(
      _wrap(
        const PuzzlePreviewThumbnail(imageUrl: _imageUrl, unlockCost: 15),
        walletCubit,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('15'));
    await tester.pump();
    await tester.pump();

    expect(walletCubit.state, 85);
    expect(find.text('Reassemble this photo'), findsOneWidget);
    expect(find.text('Preview locked'), findsNothing);
  });

  testWidgets(
    'shows a snackbar and stays locked when the balance is insufficient',
    (tester) async {
      final walletCubit = WalletCubit(FakeWalletService(5));

      await tester.pumpWidget(
        _wrap(
          const PuzzlePreviewThumbnail(imageUrl: _imageUrl, unlockCost: 15),
          walletCubit,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('15'));
      await tester.pump();
      await tester.pump();

      expect(walletCubit.state, 5);
      expect(find.text('Preview locked'), findsOneWidget);
      expect(find.text('Not enough coins'), findsOneWidget);
    },
  );
}
