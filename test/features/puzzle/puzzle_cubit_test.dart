// Unit tests for PuzzleCubit's tile-swap game: loading shuffles the
// board, swapping obeys the locked-cell rules, and solving persists
// through LevelService (marking the level complete and unlocking the
// next one). Pure Dart, backed by an in-memory fake LevelsRepository; no
// widgets, no gestures.
//
// Note: loading a level starts a repeating Timer (the elapsed-time
// clock), so every test closes the cubit in tearDown to cancel it —
// otherwise it's a leaked pending Timer.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/levels/domain/entities/level.dart';
import 'package:puzzle_cards/features/levels/domain/repositories/levels_repository.dart';
import 'package:puzzle_cards/features/levels/domain/services/chapter_catalog.dart';
import 'package:puzzle_cards/features/levels/domain/services/demo_levels_generator.dart';
import 'package:puzzle_cards/features/levels/domain/services/level_service.dart';
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
}
