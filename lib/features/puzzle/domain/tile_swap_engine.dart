import 'dart:math';

/// A record representing the full physical state of the board.
typedef BoardState = ({List<int> arrangement, List<int> rotations});

/// The full rules of the "swap tiles on the grid" mechanic.
abstract final class TileSwapEngine {
  /// A shuffled arrangement. Pieces may optionally spawn randomly rotated
  /// (by 90-degree increments) if [withRotation] is true.
  static BoardState shuffledArrangement({
    required int pieceCount,
    required int seed,
    required bool withRotation,
  }) {
    var attempt = seed;
    var arrangement = List.generate(pieceCount, (i) => i + 1);
    var rotations = List.filled(pieceCount, 0);
    
    do {
      final random = Random(attempt);
      arrangement = List.generate(pieceCount, (i) => i + 1)
        ..shuffle(random);
      
      rotations = List.generate(
        pieceCount,
        (_) => withRotation ? random.nextInt(4) : 0,
      );
      
      attempt++;
    } while (isSolved((arrangement: arrangement, rotations: rotations)));
    return (arrangement: arrangement, rotations: rotations);
  }

  static bool isSolved(BoardState state) {
    for (var i = 0; i < state.arrangement.length; i++) {
      if (state.arrangement[i] != i + 1) return false;
      if (state.rotations[i] != 0) return false;
    }
    return true;
  }

  static bool isCellLocked(BoardState state, int cell) =>
      state.arrangement[cell] == cell + 1 && state.rotations[cell] == 0;

  /// Swaps the pieces at [fromCell] and [toCell], including their rotations.
  static BoardState swap(BoardState state, int fromCell, int toCell) {
    if (fromCell == toCell) return state;
    if (isCellLocked(state, fromCell) || isCellLocked(state, toCell)) {
      return state;
    }
    final newArr = List<int>.of(state.arrangement);
    final newRot = List<int>.of(state.rotations);

    final tempArr = newArr[fromCell];
    newArr[fromCell] = newArr[toCell];
    newArr[toCell] = tempArr;

    final tempRot = newRot[fromCell];
    newRot[fromCell] = newRot[toCell];
    newRot[toCell] = tempRot;

    return (arrangement: newArr, rotations: newRot);
  }

  /// Calculates minimal swaps needed (not accounting for rotations, as rotations
  /// don't count towards the 'move' count stringency in the same way, or you can
  /// just treat each rotation as a move). For simplicity, we keep the cycle decomposition
  /// for positional swaps.
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
