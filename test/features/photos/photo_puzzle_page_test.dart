// Verifies the Photo Puzzle gameplay screen: a fully-populated 4x5 board
// with title/coins/timer/moves, the solve celebration (coin payout +
// victory dialog with stars), a one-time coin grant per photo, and the
// Replay flow. The page is driven by an injected PhotoPuzzleCubit so the
// board can be solved deterministically.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/router/route_paths.dart';
import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/photos/domain/photo_puzzle.dart';
import 'package:puzzle_cards/features/photos/presentation/bloc/photo_puzzle_cubit.dart';
import 'package:puzzle_cards/features/photos/presentation/pages/photo_puzzle_page.dart';
import 'package:puzzle_cards/features/photos/presentation/pages/photo_puzzles_page.dart';
import 'package:puzzle_cards/features/puzzle/domain/tile_swap_engine.dart';
import 'package:puzzle_cards/features/puzzle/presentation/widgets/puzzle_image_tile.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';

import '../../helpers/fake_photo_progress_service.dart';
import '../../helpers/fake_wallet_service.dart';

const _photo = PhotoPuzzle(
  id: 'beach',
  title: 'Beach',
  imagePath: 'assets/images/photos/beach.jpg',
);

/// Drives the cubit to a solved state with legal moves (greedy: put each
/// piece home, rotating as needed).
Future<void> solveCubit(PhotoPuzzleCubit cubit) async {
  while (true) {
    final state = cubit.state as PhotoPuzzleReady;
    if (state.isSolved) return;
    final board = (
      arrangement: state.arrangement,
      rotations: state.rotations,
    );
    var acted = false;
    for (var i = 0; i < board.arrangement.length; i++) {
      if (TileSwapEngine.isCellLocked(board, i)) continue;
      if (board.arrangement[i] != i + 1) {
        final j = board.arrangement.indexOf(i + 1);
        await cubit.swapPieces(i, j);
        acted = true;
        break;
      }
      if (board.rotations[i] != 0) {
        await cubit.rotatePiece(i);
        acted = true;
        break;
      }
    }
    expect(acted, isTrue, reason: 'the solve loop must always progress');
  }
}

Future<PhotoPuzzleCubit> _loadedCubit(FakePhotoProgressService progress) async {
  final cubit = PhotoPuzzleCubit(progress);
  await cubit.load(_photo);
  return cubit;
}

Widget _wrap({
  required PhotoPuzzleCubit cubit,
  required WalletCubit walletCubit,
}) {
  return BlocProvider<WalletCubit>(
    create: (_) => walletCubit,
    child: MaterialApp(
      theme: AppTheme.game,
      home: PhotoPuzzlePage(
        photo: _photo,
        cubit: cubit,
        progressService: FakePhotoProgressService(),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows title and a fully-populated 4x5 board', (tester) async {
    final cubit = await _loadedCubit(FakePhotoProgressService());
    final walletCubit = WalletCubit(FakeWalletService());

    await tester.pumpWidget(_wrap(cubit: cubit, walletCubit: walletCubit));
    await tester.pump();
    await tester.pump();

    expect(find.text('Beach'), findsOneWidget);
    expect(find.text('0'), findsWidgets); // timer and moves chips
    expect(find.byType(PuzzleImageTile), findsNWidgets(20));

    // Unmount then close the cubit so its 1s timer doesn't leak.
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets('solving celebrates, pays coins once, and supports replay', (
    tester,
  ) async {
    final progress = FakePhotoProgressService();
    final cubit = await _loadedCubit(progress);
    final walletCubit = WalletCubit(FakeWalletService());

    await tester.pumpWidget(_wrap(cubit: cubit, walletCubit: walletCubit));
    await tester.pump();
    await tester.pump();

    // Solve the board through the cubit (the UI follows via BlocConsumer).
    await solveCubit(cubit);
    await tester.pump(); // deliver the solved state to the listener

    // Celebration delay, then the victory dialog pops in.
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Photo Complete!'), findsOneWidget);
    expect(find.text('New Best!'), findsOneWidget);

    final solved = cubit.state as PhotoPuzzleReady;
    expect(find.textContaining('+${solved.coinsAwarded} Coins'), findsOneWidget);
    expect(walletCubit.state, solved.coinsAwarded);

    // Let the coin flight finish, then replay.
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Replay'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Photo Complete!'), findsNothing);
    final restarted = cubit.state as PhotoPuzzleReady;
    expect(restarted.isSolved, isFalse);
    expect(restarted.moves, 0);
    expect(find.byType(PuzzleImageTile), findsNWidgets(20));

    // Second completion: no coins, no new-best banner.
    await solveCubit(cubit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Photo Complete!'), findsOneWidget);
    expect(find.text('New Best!'), findsNothing);
    expect(
      find.text('Coins already collected for this photo'),
      findsOneWidget,
    );
    expect(
      walletCubit.state,
      solved.coinsAwarded,
      reason: 'replays must not re-pay',
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets('Done returns to the photo grid', (tester) async {
    final cubit = await _loadedCubit(FakePhotoProgressService());
    final walletCubit = WalletCubit(FakeWalletService());

    final router = GoRouter(
      initialLocation: RoutePaths.photoPuzzle,
      routes: [
        GoRoute(
          path: RoutePaths.photoPuzzle,
          name: RouteNames.photoPuzzle,
          pageBuilder: (context, state) => MaterialPage(
            child: BlocProvider<WalletCubit>(
              create: (_) => walletCubit,
              child: PhotoPuzzlePage(
                photo: _photo,
                cubit: cubit,
                progressService: FakePhotoProgressService(),
              ),
            ),
          ),
        ),
        GoRoute(
          path: RoutePaths.photoPuzzles,
          name: RouteNames.photoPuzzles,
          pageBuilder: (context, state) => MaterialPage(
            child: PhotoPuzzlesPage(
              loadPhotos: _emptyLoad,
              progressService: FakePhotoProgressService(),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.game, routerConfig: router),
    );
    await tester.pump();
    await tester.pump();

    await solveCubit(cubit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PhotoPuzzlePage), findsNothing);
    expect(find.byType(PhotoPuzzlesPage), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await cubit.close();
  });
}

Future<List<PhotoPuzzle>> _emptyLoad() async => const [];
