import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/pages/achievements_page.dart';
import '../../features/daily_puzzle/presentation/pages/daily_puzzle_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/levels/presentation/pages/levels_page.dart';
import '../../features/puzzle/presentation/pages/puzzle_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shop/presentation/pages/shop_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/victory/domain/entities/victory_result.dart';
import '../../features/victory/presentation/pages/victory_page.dart';
import '../design_system/app_animations.dart';
import 'route_paths.dart';

/// App-wide [GoRouter] instance.
///
/// Every screen transition goes through here. Individual features never
/// build their own [MaterialPageRoute]s — this keeps navigation, deep
/// linking, and transition styling in one place.
final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  routes: [
    GoRoute(
      path: RoutePaths.splash,
      name: RouteNames.splash,
      pageBuilder: (context, state) => _fadePage(state, const SplashPage()),
    ),
    GoRoute(
      path: RoutePaths.home,
      name: RouteNames.home,
      pageBuilder: (context, state) => _fadePage(state, const HomePage()),
    ),
    GoRoute(
      path: RoutePaths.levels,
      name: RouteNames.levels,
      pageBuilder: (context, state) => _fadePage(state, const LevelsPage()),
    ),
    GoRoute(
      path: RoutePaths.puzzle,
      name: RouteNames.puzzle,
      pageBuilder: (context, state) => _fadePage(
        state,
        PuzzlePage(levelId: state.pathParameters['levelId'] ?? '1'),
      ),
    ),
    GoRoute(
      path: RoutePaths.victory,
      name: RouteNames.victory,
      pageBuilder: (context, state) => _fadePage(
        state,
        VictoryPage(result: state.extra as VictoryResult?),
      ),
    ),
    GoRoute(
      path: RoutePaths.settings,
      name: RouteNames.settings,
      pageBuilder: (context, state) => _fadePage(state, const SettingsPage()),
    ),
    GoRoute(
      path: RoutePaths.dailyPuzzle,
      name: RouteNames.dailyPuzzle,
      pageBuilder: (context, state) =>
          _fadePage(state, const DailyPuzzlePage()),
    ),
    GoRoute(
      path: RoutePaths.achievements,
      name: RouteNames.achievements,
      pageBuilder: (context, state) =>
          _fadePage(state, const AchievementsPage()),
    ),
    GoRoute(
      path: RoutePaths.shop,
      name: RouteNames.shop,
      pageBuilder: (context, state) => _fadePage(state, const ShopPage()),
    ),
  ],
);

/// Shared fade + slight scale transition so every screen change feels
/// consistent, instead of each route picking its own animation.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppAnimations.pageTransition,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppAnimations.pageCurve);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
