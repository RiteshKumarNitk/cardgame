// Verifies the upgraded splash: the branded puzzle-piece loader, the
// staged bootstrap status line, and auto-navigation to Home once the
// minimum display time elapses (tests never start a real bootstrap, so
// the 2s fallback path is what runs).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/router/route_paths.dart';
import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/splash/presentation/pages/splash_page.dart';
import 'package:puzzle_cards/shared/widgets/puzzle_piece_loader.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows logo, title, piece loader and staged status', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(PuzzlePieceLoader), findsOneWidget);
    expect(find.text('Puzzle Cards'), findsOneWidget);
    // Bootstrap never runs in tests, so the preparing message shows.
    expect(find.text('Shuffling the deck…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    // Flush the 2s navigation timer (and the page transition) so no
    // timers leak past the end of the test.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('navigates to Home after the minimum display time', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('HOME'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    // Let the page transition finish (300ms) so the splash is removed.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SplashPage), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });
}

Widget _buildApp() {
  final router = GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('HOME'))),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    theme: AppTheme.game,
    debugShowCheckedModeBanner: false,
  );
}
