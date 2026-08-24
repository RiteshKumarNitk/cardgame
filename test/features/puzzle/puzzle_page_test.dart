// Verifies the Puzzle screen shell renders for a valid level: difficulty
// badge and a fully-populated portrait board (every cell holds a piece
// from the start — there's no separate tray). The top bar is a single
// compact row (see PuzzleTopBar) that doesn't show the level title, to
// leave more screen space for the board.
//
// Uses an in-memory fake LevelsRepository (via LevelService) rather than
// real Hive — same reasoning as the Levels feature tests.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/router/route_paths.dart';
import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';
import '../../helpers/fake_wallet_service.dart';
import 'package:puzzle_cards/features/levels/domain/entities/level.dart';
import 'package:puzzle_cards/features/levels/domain/repositories/levels_repository.dart';
import 'package:puzzle_cards/features/levels/domain/services/chapter_catalog.dart';
import 'package:puzzle_cards/features/levels/domain/services/demo_levels_generator.dart';
import 'package:puzzle_cards/features/levels/domain/services/level_service.dart';
import 'package:puzzle_cards/features/puzzle/domain/tile_swap_engine.dart';
import 'package:puzzle_cards/features/puzzle/presentation/bloc/puzzle_cubit.dart';
import 'package:puzzle_cards/features/puzzle/presentation/bloc/puzzle_state.dart';
import 'package:puzzle_cards/features/puzzle/presentation/pages/puzzle_page.dart';
import 'package:puzzle_cards/features/puzzle/presentation/widgets/puzzle_image_tile.dart';

// Seeded with the real, full level catalog: LevelService reseeds whenever
// the repository's stored count doesn't match
// ChapterCatalog.totalLevelCount, so a short fake list would get silently
// replaced on every load.
class _FakeLevelsRepository implements LevelsRepository {
  List<Level> stored = generateLevelCatalog();

  @override
  Future<List<Level>> loadLevels() async => List.of(stored);

  @override
  Future<void> saveLevels(List<Level> levels) async {
    stored = List.of(levels);
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  /// Performs one swap that locks no new cell (a "stall"), or fails the
  /// test if no such swap exists. Drives the stuck-shuffle mechanic.
  Future<void> _stallOnce(PuzzleCubit cubit) async {
    final state = cubit.state as PuzzleLoaded;
    final n = state.arrangement.length;
    BoardState board = (
      arrangement: state.arrangement,
    );
    bool isCorrect(List<int> arr, int cell) => arr[cell] == cell + 1;
    final lockedBefore = List.generate(n, (k) => k)
        .where((k) => isCorrect(board.arrangement, k))
        .length;

    for (var i = 0; i < n; i++) {
      if (isCorrect(board.arrangement, i)) continue;
      for (var j = i + 1; j < n; j++) {
        if (isCorrect(board.arrangement, j)) continue;
        final swapped = TileSwapEngine.swap(board, i, j);
        final lockedAfter = List.generate(n, (k) => k)
            .where((k) => isCorrect(swapped.arrangement, k))
            .length;
        if (lockedAfter == lockedBefore) {
          await cubit.swapPieces(i, j);
          return;
        }
      }
    }
    fail('no stalling swap found on this board');
  }

  testWidgets('shows difficulty and a fully-populated portrait board', (
    tester,
  ) async {
    final levelService = LevelService(_FakeLevelsRepository());

    await tester.pumpWidget(
      BlocProvider<WalletCubit>(
        create: (_) => WalletCubit(FakeWalletService()),
        child: MaterialApp(
          theme: AppTheme.game,
          home: PuzzlePage(levelId: '1', levelService: levelService),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Easy'), findsOneWidget);

    // The reference preview now lives in a bottom sheet (opened from the
    // top bar's eye icon) instead of an always-visible card, so the board
    // itself gets the full screen — locked by default (unlockable with
    // coins).
    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Preview locked'), findsOneWidget);
    Navigator.of(tester.element(find.text('Preview locked'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // A 3x4 (portrait) board for easy = 12 pieces; every cell always
    // renders a piece (locked or not), but exactly how many start locked
    // depends on the shuffle, so only the total tile count is asserted
    // exactly.
    expect(find.byType(PuzzleImageTile), findsNWidgets(12));
    // At least the not-yet-correct cells should be interactive.
    expect(find.byType(DragTarget<int>), findsWidgets);

    // A loaded puzzle starts a repeating Timer (the elapsed-time clock).
    // Unmount to dispose the cubit (cancelling it) before the test ends —
    // otherwise flutter_test flags it as a leaked pending Timer.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows a live star-target countdown in the top bar', (
    tester,
  ) async {
    final levelService = LevelService(_FakeLevelsRepository());

    await tester.pumpWidget(
      BlocProvider<WalletCubit>(
        create: (_) => WalletCubit(FakeWalletService()),
        child: MaterialApp(
          theme: AppTheme.game,
          home: PuzzlePage(levelId: '1', levelService: levelService),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Moves are 0 and minimalSwaps > 0, so the 3-star countdown shows.
    expect(find.textContaining('3★ in'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('offers a free shuffle when stuck and reshuffles on tap', (
    tester,
  ) async {
    final cubit = PuzzleCubit(LevelService(_FakeLevelsRepository()));
    await cubit.loadLevel(1);
    for (var i = 0; i < 6; i++) {
      await _stallOnce(cubit);
    }
    expect((cubit.state as PuzzleLoaded).stuckShuffleReady, isTrue);

    await tester.pumpWidget(
      BlocProvider<WalletCubit>(
        create: (_) => WalletCubit(FakeWalletService()),
        child: MaterialApp(
          theme: AppTheme.game,
          home: PuzzlePage(levelId: '1', cubit: cubit),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Stuck? Free Shuffle'), findsOneWidget);

    await tester.tap(find.text('Stuck? Free Shuffle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Stuck? Free Shuffle'), findsNothing);
    final state = cubit.state as PuzzleLoaded;
    expect(state.moves, 0, reason: 'the free shuffle starts a fresh attempt');
    expect(state.shuffleGeneration, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets('shows an error message for an unknown level id', (
    tester,
  ) async {
    final levelService = LevelService(_FakeLevelsRepository());
    final unknownLevelId = ChapterCatalog.totalLevelCount + 1;

    await tester.pumpWidget(
      BlocProvider<WalletCubit>(
        create: (_) => WalletCubit(FakeWalletService()),
        child: MaterialApp(
          theme: AppTheme.game,
          home: PuzzlePage(levelId: '$unknownLevelId', levelService: levelService),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Failed to load level'), findsOneWidget);
  });

  testWidgets('pause opens the pause menu; Resume closes it', (tester) async {
    final levelService = LevelService(_FakeLevelsRepository());

    await tester.pumpWidget(
      BlocProvider<WalletCubit>(
        create: (_) => WalletCubit(FakeWalletService()),
        child: MaterialApp(
          theme: AppTheme.game,
          home: PuzzlePage(levelId: '1', levelService: levelService),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
    expect(find.text('Give Up'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Paused'), findsNothing);
    expect(find.byType(PuzzleImageTile), findsNWidgets(12));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('system back toggles pause instead of leaving mid-puzzle', (
    tester,
  ) async {
    final levelService = LevelService(_FakeLevelsRepository());

    await tester.pumpWidget(
      BlocProvider<WalletCubit>(
        create: (_) => WalletCubit(FakeWalletService()),
        child: MaterialApp(
          theme: AppTheme.game,
          home: PuzzlePage(levelId: '1', levelService: levelService),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Android-style back: must open the pause menu, never exit.
    final dynamic widgetsApp = tester.state(find.byType(WidgetsApp));
    await widgetsApp.didPopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Paused'), findsOneWidget);

    // A second back resumes play.
    await widgetsApp.didPopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Paused'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Restart from the pause menu re-shuffles the board', (
    tester,
  ) async {
    final levelService = LevelService(_FakeLevelsRepository());

    await tester.pumpWidget(
      BlocProvider<WalletCubit>(
        create: (_) => WalletCubit(FakeWalletService()),
        child: MaterialApp(
          theme: AppTheme.game,
          home: PuzzlePage(levelId: '1', levelService: levelService),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Restart'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Paused'), findsNothing);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.byType(PuzzleImageTile), findsNWidgets(12));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Give Up from the pause menu returns Home', (tester) async {
    final levelService = LevelService(_FakeLevelsRepository());
    final router = GoRouter(
      initialLocation: RoutePaths.puzzleWithId('1'),
      routes: [
        GoRoute(
          path: RoutePaths.puzzle,
          name: RouteNames.puzzle,
          pageBuilder: (context, state) => MaterialPage(
            child: PuzzlePage(
              levelId: state.pathParameters['levelId']!,
              levelService: levelService,
            ),
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
        child: MaterialApp.router(
          theme: AppTheme.game,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Give Up'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PuzzlePage), findsNothing);
    expect(find.text('Home Page'), findsOneWidget);
  });
}
