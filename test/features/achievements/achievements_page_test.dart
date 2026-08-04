// Verifies the Achievements screen renders the catalog with progress and
// that its back button always returns Home (never a dead end — the page is
// reached via goNamed which replaces the navigation stack).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/router/route_paths.dart';
import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/achievements/domain/services/achievement_catalog.dart';
import 'package:puzzle_cards/features/achievements/presentation/bloc/achievements_cubit.dart';
import 'package:puzzle_cards/features/achievements/presentation/pages/achievements_page.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';

import '../../helpers/fake_achievements_repository.dart';
import '../../helpers/fake_wallet_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders every achievement with progress and rewards', (
    tester,
  ) async {
    final repository = FakeAchievementsRepository()
      ..counters = {AchievementCatalog.counterPuzzles: 5};

    await tester.pumpWidget(
      BlocProvider<WalletCubit>(
        create: (_) => WalletCubit(FakeWalletService()),
        child: BlocProvider<AchievementsCubit>(
          create: (_) => AchievementsCubit(repository)..load(),
          child: MaterialApp(
            theme: AppTheme.game,
            home: const AchievementsPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Achievements'), findsOneWidget);
    // "First Steps" unlocked (5 >= 1 goal)...
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('Unlocked · +25 coins'), findsOneWidget);
    // ...while "Getting Started" is still in progress (5/10).
    expect(find.textContaining('5 / 10 · +50 coins'), findsOneWidget);
    expect(find.text('Puzzle Pro'), findsOneWidget);
    // Items below the fold are reached by scrolling the list.
    await tester.scrollUntilVisible(find.text('Speed Demon'), 200);
    expect(find.text('Speed Demon'), findsOneWidget);
    // Back button present.
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('back button navigates home when nothing to pop', (
    tester,
  ) async {
    // Mirrors production: the page is reached via goNamed (stack replaced),
    // so the back button must fall back to navigating Home itself.
    final router = GoRouter(
      initialLocation: RoutePaths.achievements,
      routes: [
        GoRoute(
          path: RoutePaths.achievements,
          name: RouteNames.achievements,
          pageBuilder: (context, state) => const MaterialPage(
            child: AchievementsPage(),
          ),
        ),
        GoRoute(
          path: RoutePaths.home,
          name: RouteNames.home,
          pageBuilder: (context, state) => const MaterialPage(
            child: Scaffold(body: Center(child: Text('Home Page'))),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider<WalletCubit>(
        create: (_) => WalletCubit(FakeWalletService()),
        child: BlocProvider<AchievementsCubit>(
          create: (_) => AchievementsCubit(FakeAchievementsRepository())..load(),
          child: MaterialApp.router(
            theme: AppTheme.game,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AchievementsPage), findsOneWidget);

    // No route below (stack replaced by goNamed in production) — tapping
    // back must not crash and must not leave a dead end.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AchievementsPage), findsNothing);
    expect(find.text('Home Page'), findsOneWidget);
  });
}