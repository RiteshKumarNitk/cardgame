// Unit tests for PuzzleCubit's tile-swap game: loading shuffles the
// board, swapping obeys the locked-cell rules, and solving persists
// through LevelService (marking the level complete and unlocking the
// next one). Pure Dart, backed by an in-memory fake LevelsRepository; no
// widgets, no gestures.
//
// Note: the player's first move starts a repeating Timer (the elapsed-
// time clock), so every test that moves closes the cubit in tearDown to
// cancel it — otherwise it's a leaked pending Timer. Loading a level on
// its own no longer starts the clock (the opening stage is untimed).

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/levels/domain/entities/level.dart';
import 'package:puzzle_cards/features/levels/domain/repositories/levels_repository.dart';
import 'package:puzzle_cards/features/levels/domain/services/chapter_catalog.dart';
import 'package:puzzle_cards/features/levels/domain/services/demo_levels_generator.dart';
import 'package:puzzle_cards/features/levels/domain/services/level_service.dart';
import 'package:puzzle_cards/features/puzzle/domain/tile_swap_engine.dart';
import 'package:puzzle_cards/features/puzzle/presentation/bloc/puzzle_cubit.dart';
import 'package:puzzle_cards/features/puzzle/presentation/bloc/puzzle_state.dart';

// Seeded with the real, full level catalog (not a hand-picked short list):
// LevelService reseeds whenever the repository's stored count doesn't
// match ChapterCatalog.totalLevelCount, so a short fake list would get
// silently replaced on every load. Level 1 is in Chapter 1 ("The
// Beginning", easy, 3 cols x 4 rows = 12 pieces).
class _FakeLevelsRepository implements LevelsRepository {
  List<Level> stored = generateLevelCatalog();

  @override
  Future<List<Level>> loadLevels() async => List.of(stored);

  @override
  Future<void> saveLevels(List<Level> levels) async {
    stored = List.of(levels);
  }
}

/// Performs one swap that locks no new cell (a "stall"), or fails the
/// test if no such swap exists. Used to drive the stuck-shuffle mechanic.
Future<void> _stallOnce(PuzzleCubit cubit) async {
  final state = cubit.state as PuzzleLoaded;
  final n = state.arrangement.length;
  BoardState board = (arrangement: state.arrangement);
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

/// Solves the board by walking its permutation cycles — repeatedly finds
/// the first wrong cell and swaps it with wherever its own correct piece
/// currently sits. That always locks the target cell immediately, so
/// this converges in exactly the minimal number of swaps.
Future<void> _solveOptimally(PuzzleCubit cubit) async {
  while (true) {
    final state = cubit.state as PuzzleLoaded;
    if (state.isSolved) return;

    var wrongCell = -1;
    for (var i = 0; i < state.arrangement.length; i++) {
      if (state.arrangement[i] != i + 1) {
        wrongCell = i;
        break;
      }
    }
    final targetCell = state.arrangement[wrongCell] - 1;
    await cubit.swapPieces(wrongCell, targetCell);
  }
}

void main() {
  late _FakeLevelsRepository repository;
  late PuzzleCubit cubit;

  setUp(() {
    repository = _FakeLevelsRepository();
    cubit = PuzzleCubit(LevelService(repository));
  });

  tearDown(() async {
    await cubit.close();
  });

  test('loadLevel shuffles the board (unsolved) for the requested level', () async {
    await cubit.loadLevel(1);

    final state = cubit.state as PuzzleLoaded;
    expect(state.level.id, 1);
    expect(state.arrangement.toSet(), Set.of(List.generate(12, (i) => i + 1)));
    expect(state.isSolved, isFalse);
    expect(state.moves, 0);
  });

  test('emits an error for an unknown level id', () async {
    await cubit.loadLevel(ChapterCatalog.totalLevelCount + 1);

    expect(cubit.state, isA<PuzzleError>());
  });

  test('swapping two unlocked cells exchanges their pieces and counts a move', () async {
    await cubit.loadLevel(1);
    final before = (cubit.state as PuzzleLoaded).arrangement;

    await cubit.swapPieces(0, 1);

    final state = cubit.state as PuzzleLoaded;
    expect(state.arrangement[0], before[1]);
    expect(state.arrangement[1], before[0]);
    expect(state.moves, 1);
  });

  test('swapping a locked (already-correct) cell is a no-op', () async {
    await cubit.loadLevel(1);

    // Force cell 0 to become locked by swapping piece 1 into it.
    var state = cubit.state as PuzzleLoaded;
    final pieceOneCell = state.arrangement.indexOf(1);
    if (pieceOneCell != 0) {
      await cubit.swapPieces(0, pieceOneCell);
    }
    state = cubit.state as PuzzleLoaded;
    expect(state.arrangement[0], 1, reason: 'cell 0 should now be locked');
    final movesSoFar = state.moves;

    await cubit.swapPieces(0, 1);

    state = cubit.state as PuzzleLoaded;
    expect(
      state.moves,
      movesSoFar,
      reason: 'locked cells cannot be moved, so no new move is counted',
    );
  });

  test(
    'solving optimally awards 3 stars, unlocks the next level, and persists',
    () async {
      await cubit.loadLevel(1);

      await _solveOptimally(cubit);

      final state = cubit.state as PuzzleLoaded;
      expect(state.isSolved, isTrue);
      expect(state.moves, state.minimalSwaps);
      expect(state.stars, 3);
      expect(state.coinsAwarded, 60);

      final saved = repository.stored.firstWhere((l) => l.id == 1);
      expect(saved.isCompleted, isTrue);
      expect(saved.stars, 3);

      final next = repository.stored.firstWhere((l) => l.id == 2);
      expect(next.isUnlocked, isTrue);
    },
  );

  test('nextLevelId points at the following level, then null past the last one', () async {
    await cubit.loadLevel(1);
    expect(cubit.nextLevelId, 2);

    await cubit.loadLevel(ChapterCatalog.totalLevelCount);
    expect(cubit.nextLevelId, isNull, reason: 'this is the last level in the catalog');
  });

  test('setPaused stops the clock and resumes it on unpause', () async {
    await cubit.loadLevel(1);
    expect((cubit.state as PuzzleLoaded).isPaused, isFalse);

    // The elapsed clock only starts on the first move — the opening
    // "beginning stage" is untimed.
    await cubit.swapPieces(0, 1);

    cubit.setPaused(true);
    expect((cubit.state as PuzzleLoaded).isPaused, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(
      (cubit.state as PuzzleLoaded).elapsedSeconds,
      0,
      reason: 'the clock must not tick while the pause menu is up',
    );

    cubit.setPaused(false);
    expect((cubit.state as PuzzleLoaded).isPaused, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(
      (cubit.state as PuzzleLoaded).elapsedSeconds,
      greaterThanOrEqualTo(1),
      reason: 'the clock resumes once unpaused',
    );
  });

  test('setPaused is a no-op before a level is loaded', () {
    cubit.setPaused(true);
    expect(cubit.state, isA<PuzzleInitial>());
    cubit.setPaused(false);
    expect(cubit.state, isA<PuzzleInitial>());
  });

  test('restart deals a fresh shuffle and resets moves and time', () async {
    await cubit.loadLevel(1);
    await cubit.swapPieces(0, 1);
    final before = (cubit.state as PuzzleLoaded).arrangement;

    await cubit.restart();

    final state = cubit.state as PuzzleLoaded;
    expect(state.level.id, 1);
    expect(state.isSolved, isFalse);
    expect(state.moves, 0);
    expect(state.isPaused, isFalse);
    expect(state.arrangement.toSet(), Set.of(List.generate(12, (i) => i + 1)));
    expect(
      state.arrangement,
      isNot(equals(before)),
      reason: 'a restart re-shuffles instead of restoring the old board',
    );
  });

  test('every shuffle bumps shuffleGeneration (drives the deal-in replay)', () async {
    await cubit.loadLevel(1);
    expect((cubit.state as PuzzleLoaded).shuffleGeneration, 1);

    await cubit.restart();
    expect((cubit.state as PuzzleLoaded).shuffleGeneration, 2);

    await cubit.shuffleBoard();
    expect((cubit.state as PuzzleLoaded).shuffleGeneration, 3);
  });

  test('six no-progress moves offer the pity shuffle, which reshuffles free', () async {
    await cubit.loadLevel(1);

    for (var i = 0; i < 6; i++) {
      expect(
        (cubit.state as PuzzleLoaded).stuckShuffleReady,
        isFalse,
        reason: 'not stuck until the threshold is crossed (move ${i + 1})',
      );
      await _stallOnce(cubit);
    }

    final stuck = cubit.state as PuzzleLoaded;
    expect(stuck.stuckShuffleReady, isTrue);
    expect(stuck.moves, 6);

    await cubit.shuffleBoard();

    final after = cubit.state as PuzzleLoaded;
    expect(after.stuckShuffleReady, isFalse);
    expect(after.moves, 0, reason: 'the free shuffle starts a fresh attempt');
    expect(after.shuffleGeneration, 2);
  });

  test('a locking (progress) move resets the stuck streak', () async {
    await cubit.loadLevel(1);

    // Stall twice, then make a progress move (swap piece 1 into its home).
    await _stallOnce(cubit);
    await _stallOnce(cubit);
    var state = cubit.state as PuzzleLoaded;
    final pieceOneCell = state.arrangement.indexOf(1);
    if (pieceOneCell != 0) {
      await cubit.swapPieces(0, pieceOneCell);
    }
    state = cubit.state as PuzzleLoaded;
    expect(state.arrangement[0], 1, reason: 'cell 0 locked by the swap');

    // Five more stalls must NOT trip the threshold (streak was reset).
    for (var i = 0; i < 5; i++) {
      await _stallOnce(cubit);
      expect(
        (cubit.state as PuzzleLoaded).stuckShuffleReady,
        isFalse,
        reason: 'streak restarts after a locking move',
      );
    }
  });
}
