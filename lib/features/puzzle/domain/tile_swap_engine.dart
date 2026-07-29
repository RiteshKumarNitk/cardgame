import 'dart:math';

/// The full rules of the "swap tiles on the grid" mechanic, shared by
/// regular Puzzle levels and the Daily Challenge — pure and
/// framework-agnostic so it's trivial to test in isolation.
///
/// An arrangement is a `List<int>` where `arrangement[cell]` is the
/// 1-based piece index currently sitting in that (0-based) `cell`. A cell
/// is "solved"/locked when `arrangement[cell] == cell + 1`.
abstract final class TileSwapEngine {
  /// A shuffled arrangement of `size * size` pieces — deterministic for a
  /// given [seed], and guaranteed not to already be solved.
  static List<int> shuffledArrangement({required int size, required int seed}) {
    final total = size * size;
    var attempt = seed;
    var arrangement = List.generate(total, (i) => i + 1);
    do {
      arrangement = List.generate(total, (i) => i + 1)
        ..shuffle(Random(attempt));
      attempt++;
    } while (isSolved(arrangement));
    return arrangement;
  }

  static bool isSolved(List<int> arrangement) {
    for (var i = 0; i < arrangement.length; i++) {
      if (arrangement[i] != i + 1) return false;
    }
    return true;
  }

  static bool isCellLocked(List<int> arrangement, int cell) =>
      arrangement[cell] == cell + 1;

  /// Swaps the pieces at [fromCell] and [toCell]. A no-op (returns the
  /// same list) if either cell is already locked, or the cells are equal.
  static List<int> swap(List<int> arrangement, int fromCell, int toCell) {
    if (fromCell == toCell) return arrangement;
    if (isCellLocked(arrangement, fromCell) ||
        isCellLocked(arrangement, toCell)) {
      return arrangement;
    }
    final updated = List<int>.of(arrangement);
    final temp = updated[fromCell];
    updated[fromCell] = updated[toCell];
    updated[toCell] = temp;
    return updated;
  }

  /// The fewest swaps that could solve [arrangement] from here, via cycle
  /// decomposition (swaps needed = elements - cycles). Used as the
  /// baseline for star ratings — playing at this count is a perfect run.
  static int minimalSwaps(List<int> arrangement) {
    final visited = List.filled(arrangement.length, false);
    var swaps = 0;
    for (var i = 0; i < arrangement.length; i++) {
      if (visited[i]) continue;
      var cycleLength = 0;
      var j = i;
      while (!visited[j]) {
        visited[j] = true;
        j = arrangement[j] - 1;
        cycleLength++;
      }
      if (cycleLength > 1) swaps += cycleLength - 1;
    }
    return swaps;
  }
}
