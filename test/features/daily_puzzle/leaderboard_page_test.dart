// Verifies the Leaderboard screen's back button never dead-ends: the page
// is reached via goNamed from the daily challenge (stack replaced), so when
// there is nothing to pop the arrow must fall back to navigating Home.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/router/route_paths.dart';
import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/daily_puzzle/presentation/pages/leaderboard_page.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('back button navigates home when nothing to pop', (
    tester,
  ) async {
    // Mirrors production: Leaderboard is reached via goNamed (stack
    // replaced), so tapping back must not throw "There is nothing to pop".
    final router = GoRouter(
      initialLocation: RoutePaths.leaderboard,
      routes: [
        GoRoute(
          path: RoutePaths.leaderboard,
          name: RouteNames.leaderboard,
          pageBuilder: (context, state) => const MaterialPage(
            child: LeaderboardPage(),
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
      MaterialApp.router(theme: AppTheme.game, routerConfig: router),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(LeaderboardPage), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LeaderboardPage), findsNothing);
    expect(find.text('Home Page'), findsOneWidget);
  });
}