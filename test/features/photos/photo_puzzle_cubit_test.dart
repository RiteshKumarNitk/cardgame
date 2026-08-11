// Verifies the Photo Puzzle engine: loading a photo shuffles a 4x5 board
// with rotation, moves/rotations increment the counter, solving scores
// stars (moves vs. minimal swaps) and pays coins exactly once per photo,
// and best stars persist.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/photos/domain/photo_puzzle.dart';
import 'package:puzzle_cards/features/photos/presentation/bloc/photo_puzzle_cubit.dart';
import 'package:puzzle_cards/features/puzzle/domain/tile_swap_engine.dart';

import '../../helpers/fake_photo_progress_service.dart';

const _photo = PhotoPuzzle(
  id: 'beach',
  title: 'Beach',
  imagePath: 'assets/images/photos/beach.jpg',
);

void main() {
  late FakePhotoProgressService progress;

  setUp(() {
    progress = FakePhotoProgressService();
  });

  Future<PhotoPuzzleCubit> loadCubit() async {
    final cubit = PhotoPuzzleCubit(progress);
    await cubit.load(_photo);
    addTearDown(cubit.close);
    return cubit;
  }

  /// Drives the board to a solved state with legal moves (the same greedy
  /// strategy as a human: put each piece in its home, rotating as needed).
  Future<void> solve(PhotoPuzzleCubit cubit) async {
    while (true) {
      final state = cubit.state as PhotoPuzzleReady;
      if (state.isSolved) return;
      final board = (arrangement: state.arrangement, rotations: state.rotations);
      var acted = false;
      for (var i = 0; i < board.arrangement.length; i++) {
        if (TileSwapEngine.isCellLocked(board, i)) continue;
        if (board.arrangement[i] != i + 1) {
          final j = board.arrangement.indexOf(i + 1);
          expect(j, isNot(i));
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

  test('load shuffles a 4x5 board with rotation enabled', () async {
    final cubit = await loadCubit();
    final state = cubit.state as PhotoPuzzleReady;

    expect(state.photo, _photo);
    expect(state.arrangement, hasLength(20));
    expect(state.rotations, hasLength(20));
    expect(state.minimalSwaps, greaterThan(0));
    expect(state.moves, 0);
    expect(state.elapsedSeconds, 0);
    expect(state.isSolved, isFalse);
    expect(state.bestStars, 0);
  });

  test('swap and rotate increment moves', () async {
    final cubit = await loadCubit();
    var state = cubit.state as PhotoPuzzleReady;

    // First legal swap: bring a misplaced piece home.
    final i = state.arrangement.indexed
        .firstWhere((e) => e.$2 != e.$1 + 1)
        .$1;
    final j = state.arrangement.indexOf(i + 1);
    await cubit.swapPieces(i, j);

    state = cubit.state as PhotoPuzzleReady;
    expect(state.moves, 1);

    // Rotate a cell whose piece is at home but rotated, or any unlocked
    // cell otherwise.
    final board = (arrangement: state.arrangement, rotations: state.rotations);
    final cell = List.generate(board.arrangement.length, (k) => k).firstWhere(
      (k) => !TileSwapEngine.isCellLocked(board, k),
    );
    await cubit.rotatePiece(cell);
    state = cubit.state as PhotoPuzzleReady;
    expect(state.moves, 2);
  });

  test('solve awards stars and coins on the first completion only', () async {
    final cubit = await loadCubit();
    await solve(cubit);

    var state = cubit.state as PhotoPuzzleReady;
    expect(state.isSolved, isTrue);
    expect(state.stars, inInclusiveRange(1, 3));
    expect(state.firstCompletion, isTrue);
    expect(state.isNewBest, isTrue);
    expect(state.coinsAwarded, state.stars * 20);
    expect(progress.bestStars[_photo.id], state.stars);
    expect(progress.saveCount, 1);
    final firstStars = state.stars;

    // Replay: fresh shuffle (stars reset), best-stars remembered, and the
    // second completion pays nothing.
    await cubit.restart();
    state = cubit.state as PhotoPuzzleReady;
    expect(state.moves, 0);
    expect(state.isSolved, isFalse);
    expect(state.stars, 0);
    expect(state.bestStars, firstStars);

    await solve(cubit);
    state = cubit.state as PhotoPuzzleReady;
    expect(state.firstCompletion, isFalse);
    expect(state.coinsAwarded, 0);
    expect(progress.saveCount, 1, reason: 'no new best on replay');
  });

  test('star rating follows the moves-vs-minimal rule', () {
    expect(PhotoPuzzleCubit.starsFor(10, 10), 3); // minimal + 0
    expect(PhotoPuzzleCubit.starsFor(11, 10), 3); // minimal + 1
    expect(PhotoPuzzleCubit.starsFor(12, 10), 2); // minimal + 2
    expect(PhotoPuzzleCubit.starsFor(22, 10), 2); // 2*minimal + 2
    expect(PhotoPuzzleCubit.starsFor(23, 10), 1); // worse than 2x
    expect(PhotoPuzzleCubit.starsFor(50, 10), 1);
  });

  test('a replay that does not improve keeps the saved best', () async {
    progress.bestStars[_photo.id] = 1; // previously solved with 1 star
    final cubit = await loadCubit();

    await solve(cubit);
    final state = cubit.state as PhotoPuzzleReady;
    expect(state.firstCompletion, isFalse);
    expect(state.isNewBest, isFalse);
    expect(state.bestStars, 1, reason: 'worse or equal scores never downgrade');
    expect(state.coinsAwarded, 0);
    expect(progress.saveCount, 0, reason: 'no new best to persist');
    expect(progress.bestStars[_photo.id], 1);
  });

  test('elapsed time advances while unsolved and stops on solve', () async {
    final cubit = await loadCubit();

    // Wait just past one tick of the real 1s periodic timer.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect((cubit.state as PhotoPuzzleReady).elapsedSeconds, 1);

    await solve(cubit);
    final before = (cubit.state as PhotoPuzzleReady).elapsedSeconds;
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect((cubit.state as PhotoPuzzleReady).elapsedSeconds, before);
  });
}
