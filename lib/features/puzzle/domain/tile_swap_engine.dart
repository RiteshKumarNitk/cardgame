import 'dart:math';

import 'puzzle_group.dart';

/// A record representing the full physical state of the board.
typedef BoardState = ({List<int> arrangement});

/// The full rules of the "swap tiles on the grid" mechanic.
///
/// Supports both individual cell swapping (Easy/Medium) and group-aware
/// movement (Hard/Expert/Master). Groups form dynamically from correct
/// adjacencies — they are NOT pre-defined and are NEVER locked.
///
/// The arrangement is always a flat list of piece indices. Groups define
/// which cells move together.
abstract final class TileSwapEngine {
  // ─── Individual Cell Swap (Easy/Medium) ───────────────────────────

  /// A shuffled arrangement. Pieces start in random positions but always
  /// in their original orientation (no rotation).
  static BoardState shuffledArrangement({
    required int pieceCount,
    required int seed,
  }) {
    var attempt = seed;
    var arrangement = List.generate(pieceCount, (i) => i + 1);

    do {
      final random = Random(attempt);
      arrangement = List.generate(pieceCount, (i) => i + 1)
        ..shuffle(random);
      attempt++;
    } while (isSolved((arrangement: arrangement)));
    return (arrangement: arrangement);
  }

  /// Whether the puzzle is fully solved.
  static bool isSolved(BoardState state) {
    for (var i = 0; i < state.arrangement.length; i++) {
      if (state.arrangement[i] != i + 1) return false;
    }
    return true;
  }

  /// Swaps the pieces at [fromCell] and [toCell].
  ///
  /// Any cell can be swapped — there are no locked cells. The only
  /// restriction is that the puzzle must not already be solved.
  static BoardState swap(BoardState state, int fromCell, int toCell) {
    if (fromCell == toCell) return state;
    final newArr = List<int>.of(state.arrangement);

    final tempArr = newArr[fromCell];
    newArr[fromCell] = newArr[toCell];
    newArr[toCell] = tempArr;

    return (arrangement: newArr);
  }

  /// Calculates minimal swaps needed using cycle decomposition.
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

  // ─── Group Movement (Hard/Expert/Master) ──────────────────────────

  /// Checks whether [group] can move by displacement ([dRow], [dCol]).
  ///
  /// A connected group is a MOVEABLE puzzle object. It can be
  /// repositioned anywhere on the board as long as:
  /// 1. Every cell of the group at the new position is within board bounds.
  /// 2. No target cell is occupied by a LOCKED individual cell
  ///    (ungrouped, correctly placed). Cells belonging to other movable
  ///    groups are fine — those groups will be displaced.
  /// 3. Any displaced group can fit in the group's vacated cells.
  ///
  /// CONNECTED ≠ LOCKED. A group is never locked. It is fully movable
  /// at all times until the puzzle is ultimately solved.
  static bool canMoveGroupByCells(
    PuzzleGroup group,
    int dRow,
    int dCol,
    PuzzleGrouping grouping,
    List<int> arrangement,
  ) {
    final cols = grouping.cols;
    final rows = grouping.rows;

    // 1. Check bounds: every cell of the group at the new position
    //    must be within the board.
    final newCells = <int>[];
    for (final cell in group.cells) {
      final row = cell ~/ cols;
      final col = cell % cols;
      final newRow = row + dRow;
      final newCol = col + dCol;
      if (newRow < 0 || newRow >= rows || newCol < 0 || newCol >= cols) {
        return false;
      }
      newCells.add(newRow * cols + newCol);
    }

    // 2. Check target cells: no LOCKED individual cell (ungrouped).
    //    Cells belonging to other movable groups are allowed — those
    //    groups will be displaced to the old position.
    final oldCellSet = group.cells.toSet();
    for (final cell in newCells) {
      if (oldCellSet.contains(cell)) continue; // Self-overlap is fine.

      if (arrangement[cell] == cell + 1) {
        // This cell is correctly placed. Check if it belongs to ANY
        // group. If yes, the group is movable and will be displaced.
        final occupant = grouping.findGroup(cell);
        if (occupant != null) continue;

        // Locked individual cell (no group) — cannot displace.
        return false;
      }
    }

    // 3. Check that displaced groups can fit in the old position.
    final displacedGroups = <PuzzleGroup>{};
    for (final cell in newCells) {
      if (oldCellSet.contains(cell)) continue;
      final occupant = grouping.findGroup(cell);
      if (occupant != null && occupant.id != group.id) {
        displacedGroups.add(occupant);
      }
    }

    for (final displaced in displacedGroups) {
      // All cells of the displaced group must land within the old cells.
      for (final cell in displaced.cells) {
        final row = cell ~/ cols;
        final col = cell % cols;
        final displacedNewRow = row + dRow;
        final displacedNewCol = col + dCol;
        final displacedNewCell = displacedNewRow * cols + displacedNewCol;
        if (!oldCellSet.contains(displacedNewCell)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Moves [group] by displacement ([dRow], [dCol]) and returns the
  /// new arrangement.
  ///
  /// The group must pass [canMoveGroupByCells] validation before calling.
  ///
  /// Movement rules:
  /// - The group's old cells are completely vacated.
  /// - The group's new cells are filled with the group's piece indices.
  /// - Displaced content (other groups) goes to the group's old position.
  /// - After the move, [grouping] is updated (cell map rebuilt).
  static BoardState moveGroupByCells(
    BoardState state,
    PuzzleGrouping grouping,
    PuzzleGroup group,
    int dRow,
    int dCol,
  ) {
    if (dRow == 0 && dCol == 0) return state;

    final cols = grouping.cols;
    final origArr = state.arrangement;
    final newArr = List<int>.of(origArr);

    // Compute old and new cells.
    final oldCells = group.cells.toList();
    final newCells = <int>[];
    for (final cell in oldCells) {
      final row = cell ~/ cols;
      final col = cell % cols;
      newCells.add((row + dRow) * cols + (col + dCol));
    }

    // 1. Record what was in the old cells (from original arrangement).
    final oldContents = <int, int>{};
    for (final cell in oldCells) {
      oldContents[cell] = origArr[cell];
    }

    // 2. Clear all old cells.
    for (final cell in oldCells) {
      newArr[cell] = 0;
    }

    // 3. Find and clear displaced groups.
    final displacedGroups = <PuzzleGroup>{};
    final oldCellSet = oldCells.toSet();
    for (final cell in newCells) {
      if (oldCellSet.contains(cell)) continue;
      final occupant = grouping.findGroup(cell);
      if (occupant != null && occupant.id != group.id) {
        displacedGroups.add(occupant);
      }
    }

    // Record displaced group contents and clear their cells.
    final displacedContents = <int, int>{};
    for (final displaced in displacedGroups) {
      for (final cell in displaced.cells) {
        displacedContents[cell] = origArr[cell];
        newArr[cell] = 0;
      }
    }

    // 4. Place the group at its new position.
    for (var i = 0; i < newCells.length; i++) {
      newArr[newCells[i]] = oldContents[oldCells[i]]!;
    }

    // 5. Place displaced groups at the old position.
    //    Each displaced cell moves by the same displacement.
    for (final displaced in displacedGroups) {
      for (final cell in displaced.cells) {
        final row = cell ~/ cols;
        final col = cell % cols;
        final displacedNewCell = (row + dRow) * cols + (col + dCol);
        newArr[displacedNewCell] = displacedContents[cell]!;
      }
    }

    // 6. Handle individual (ungrouped) cells that were displaced.
    //    These cells had content but no group. Place them at remaining
    //    empty old cells.
    for (final cell in newCells) {
      if (newArr[cell] != 0) continue; // Already handled.

      // This cell's content was cleared. Find an empty old cell.
      for (final oldCell in oldCells) {
        if (newArr[oldCell] == 0) {
          newArr[oldCell] = origArr[cell];
          break;
        }
      }
    }

    return (arrangement: newArr);
  }
}
