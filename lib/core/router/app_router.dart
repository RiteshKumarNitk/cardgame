import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/pages/achievements_page.dart';
import '../../features/collections/presentation/pages/collections_page.dart';
import '../../features/cosmetics/presentation/pages/cosmetics_page.dart';
import '../../features/daily_puzzle/presentation/pages/daily_puzzle_page.dart';
import '../../features/daily_puzzle/presentation/pages/leaderboard_page.dart';
import '../../features/gallery/presentation/pages/gallery_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/levels/domain/entities/chapter_complete_result.dart';
import '../../features/levels/domain/entities/section_complete_result.dart';
import '../../features/levels/presentation/pages/chapter_complete_page.dart';
import '../../features/levels/presentation/pages/levels_page.dart';
import '../../features/levels/presentation/pages/section_complete_page.dart';
import '../../features/puzzle/presentation/pages/puzzle_page.dart';
import '../../features/photos/presentation/pages/photo_puzzle_page.dart';
import '../../features/photos/presentation/pages/photo_puzzles_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/privacy_policy_page.dart';
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
      path: RoutePaths.chapterComplete,
      name: RouteNames.chapterComplete,
      pageBuilder: (context, state) => _fadePage(
        state,
        ChapterCompletePage(result: state.extra as ChapterCompleteResult?),
      ),
    ),
    GoRoute(
      path: RoutePaths.sectionComplete,
      name: RouteNames.sectionComplete,
      pageBuilder: (context, state) => _fadePage(
        state,
        SectionCompletePage(result: state.extra as SectionCompleteResult?),
      ),
    ),
    GoRoute(
      path: RoutePaths.settings,
      name: RouteNames.settings,
      pageBuilder: (context, state) => _fadePage(state, const SettingsPage()),
    ),
    GoRoute(
      path: RoutePaths.privacyPolicy,
      name: RouteNames.privacyPolicy,
      pageBuilder: (context, state) =>
          _fadePage(state, const PrivacyPolicyPage()),
    ),
    GoRoute(
      path: RoutePaths.dailyPuzzle,
      name: RouteNames.dailyPuzzle,
      pageBuilder: (context, state) =>
          _fadePage(state, const DailyPuzzlePage()),
    ),
    GoRoute(
      path: RoutePaths.leaderboard,
      name: RouteNames.leaderboard,
      pageBuilder: (context, state) =>
          _fadePage(state, const LeaderboardPage()),
    ),
    GoRoute(
      path: RoutePaths.achievements,
      name: RouteNames.achievements,
      pageBuilder: (context, state) =>
          _fadePage(state, const AchievementsPage()),
    ),
    GoRoute(
      path: RoutePaths.gallery,
      name: RouteNames.gallery,
      pageBuilder: (context, state) => _fadePage(state, const GalleryPage()),
    ),
    GoRoute(
      path: RoutePaths.shop,
      name: RouteNames.shop,
      pageBuilder: (context, state) => _fadePage(state, const ShopPage()),
    ),
    GoRoute(
      path: RoutePaths.cosmetics,
      name: RouteNames.cosmetics,
      pageBuilder: (context, state) => _fadePage(
        state,
        const CosmeticsPage(),
      ),
    ),
    GoRoute(
      path: RoutePaths.collections,
      name: RouteNames.collections,
      pageBuilder: (context, state) =>
          _fadePage(state, const CollectionsPage()),
    ),
    GoRoute(
      path: RoutePaths.photoPuzzles,
      name: RouteNames.photoPuzzles,
      pageBuilder: (context, state) =>
          _fadePage(state, const PhotoPuzzlesPage()),
    ),
    GoRoute(
      path: RoutePaths.photoPuzzle,
      name: RouteNames.photoPuzzle,
      pageBuilder: (context, state) => _fadePage(
        state,
        const PhotoPuzzlePage(),
      ),
    ),
    GoRoute(
      path: RoutePaths.cosmeticsCategory,
      name: '${RouteNames.cosmetics}Category',
      pageBuilder: (context, state) => _fadePage(
        state,
        CosmeticsPage(
          initialCategory: CosmeticsCategory.fromRoute(
            state.pathParameters['category'],
          ),
        ),
      ),
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
