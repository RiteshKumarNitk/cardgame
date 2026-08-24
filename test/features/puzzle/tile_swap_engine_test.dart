// Unit tests for TileSwapEngine: shuffles are never pre-solved, swapping
// obeys the locked-cell rules, and minimalSwaps matches hand-computed
// cycle decompositions. Pure Dart, no widgets.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/puzzle/domain/tile_swap_engine.dart';

void main() {
  group('shuffledArrangement', () {
    test('contains every piece exactly once and is never pre-solved', () {
      for (var seed = 0; seed < 50; seed++) {
        final state = TileSwapEngine.shuffledArrangement(
          pieceCount: 9,
          seed: seed,
        );
        expect(state.arrangement.toSet(), {1, 2, 3, 4, 5, 6, 7, 8, 9});
        expect(TileSwapEngine.isSolved(state), isFalse);
      }
    });
  });

  group('isSolved', () {
    test('true only when every cell holds its own piece', () {
      const solved = (arrangement: [1, 2, 3, 4]);
      expect(TileSwapEngine.isSolved(solved), isTrue);

      const misplaced = (arrangement: [1, 2, 4, 3]);
      expect(TileSwapEngine.isSolved(misplaced), isFalse);
    });
  });

  group('swap', () {
    test('swaps two unlocked cells', () {
      final result = TileSwapEngine.swap(
        (arrangement: [2, 1, 3, 4]),
        0,
        1,
      );
      expect(result.arrangement, [1, 2, 3, 4]);
    });

    test('is a no-op when either cell is already locked', () {
      // Cell 0 already holds piece 1 (locked).
      final state = (arrangement: [1, 3, 2, 4]);
      final result = TileSwapEngine.swap(state, 0, 1);
      expect(result, same(state));
      expect(result.arrangement, [1, 3, 2, 4]);
    });

    test('is a no-op when swapping a cell with itself', () {
      final state = (arrangement: [2, 1, 3, 4]);
      final result = TileSwapEngine.swap(state, 0, 0);
      expect(result, same(state));
    });

    test('does not mutate the original state', () {
      final state = (arrangement: [2, 1, 3, 4]);
      TileSwapEngine.swap(state, 0, 1);
      expect(state.arrangement, [2, 1, 3, 4]);
    });
  });

  group('minimalSwaps', () {
    test('a solved arrangement needs zero swaps', () {
      expect(TileSwapEngine.minimalSwaps([1, 2, 3, 4]), 0);
    });

    test('a single transposition needs one swap', () {
      expect(TileSwapEngine.minimalSwaps([2, 1, 3, 4]), 1);
    });

    test('a single 4-cycle needs three swaps', () {
      // 1->2->3->4->1: piece 4 sits in cell 0, piece 1 in cell 1, etc.
      expect(TileSwapEngine.minimalSwaps([4, 1, 2, 3]), 3);
    });

    test('two independent transpositions need two swaps total', () {
      expect(TileSwapEngine.minimalSwaps([2, 1, 4, 3]), 2);
    });
  });
}
