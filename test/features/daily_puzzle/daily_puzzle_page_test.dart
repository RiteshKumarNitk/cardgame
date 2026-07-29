// Verifies the Daily Challenge screen: shows the board when today hasn't
// been completed, and the streak/countdown card when it has.
//
// Note: the completed-card path renders a CountdownTimer, which owns a
// repeating Timer — each test involving it unmounts before ending so the
// Timer gets cancelled (otherwise: leaked pending Timer).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/daily_puzzle/domain/repositories/daily_challenge_repository.dart';
import 'package:puzzle_cards/features/daily_puzzle/domain/services/daily_challenge_service.dart';
import 'package:puzzle_cards/features/daily_puzzle/presentation/pages/daily_puzzle_page.dart';
import 'package:puzzle_cards/features/puzzle/presentation/widgets/puzzle_image_tile.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';

import '../../helpers/fake_wallet_service.dart';

class _FakeDailyChallengeRepository implements DailyChallengeRepository {
  String? lastCompletedDate;
  int streak = 0;

  @override
  Future<String?> loadLastCompletedDate() async => lastCompletedDate;

  @override
  Future<int> loadStreak() async => streak;

  @override
  Future<void> save({
    required String lastCompletedDate,
    required int streak,
  }) async {
    this.lastCompletedDate = lastCompletedDate;
    this.streak = streak;
  }
}

Widget _wrap(Widget child) => BlocProvider<WalletCubit>(
  create: (_) => WalletCubit(FakeWalletService()),
  child: MaterialApp(theme: AppTheme.game, home: child),
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows the board when not yet completed today', (
    tester,
  ) async {
    final service = DailyChallengeService(_FakeDailyChallengeRepository());

    await tester.pumpWidget(_wrap(DailyPuzzlePage(service: service)));
    await tester.pump();
    await tester.pump();

    expect(find.text('Daily Challenge'), findsOneWidget);
    // Medium difficulty = 4x4 = 16 pieces; every cell always renders a
    // tile (locked or not — how many start locked depends on the
    // shuffle), and the board is a fixed non-scrolling grid so all 16
    // build.
    expect(find.byType(PuzzleImageTile), findsNWidgets(16));
    expect(find.byType(DragTarget<int>), findsWidgets);
  });

  testWidgets(
    'shows the come-back-tomorrow card when already completed today',
    (tester) async {
      final todayKey = DailyChallengeService.dateKeyFor(DateTime.now());
      final repository = _FakeDailyChallengeRepository()
        ..lastCompletedDate = todayKey
        ..streak = 3;
      final service = DailyChallengeService(repository);

      await tester.pumpWidget(_wrap(DailyPuzzlePage(service: service)));
      await tester.pump();
      await tester.pump();

      expect(find.text('Come back tomorrow!'), findsOneWidget);
      expect(find.text('3 day streak'), findsOneWidget);

      // Dispose the CountdownTimer's repeating Timer before the test ends.
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
