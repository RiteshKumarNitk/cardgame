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
  /// 2. Any full multi-cell group occupying a target cell can fit within
  ///    the vacated old cells once shifted by the same displacement — it
  ///    will be displaced there.
  ///
  /// A solo cell in the way of the move — correct or not — is NEVER an
  /// obstacle: [moveGroupByCells] simply displaces it into a vacated
  /// cell, exactly as it always has for incorrectly-placed solo cells.
  /// Position alone never locks a cell.
  ///
  /// CORRECT POSITION ≠ LOCKED. CONNECTED ≠ LOCKED. Nothing in this
  /// puzzle is ever locked by virtue of where it sits — the only thing
  /// that can block a move is the board's bounds, or a multi-cell group
  /// whose shifted shape doesn't fit the vacated cells. A group is fully
  /// movable at all times until the puzzle is ultimately solved.
  static bool canMoveGroupByCells(
    PuzzleGroup group,
    int dRow,
    int dCol,
    PuzzleGrouping grouping,
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

    // 2. Collect any full multi-cell groups occupying target cells — a
    //    solo cell (correct or not) is skipped entirely: it is never a
    //    locking obstacle, just displaced by moveGroupByCells.
    final oldCellSet = group.cells.toSet();
    final newCellSet = newCells.toSet();

    // The cells the moving group actually frees for displaced content:
    // its old cells MINUS the ones it re-occupies at the new position.
    // When the move distance is smaller than the group's own extent, the
    // old and new footprints overlap; those overlap cells are filled by
    // the moving group itself, so displaced content must never land on
    // them — doing so would put two pieces on one cell.
    final vacatedSet = oldCellSet.difference(newCellSet);

    final displacedGroups = <PuzzleGroup>{};
    for (final cell in newCells) {
      if (oldCellSet.contains(cell)) continue; // Self-overlap is fine.
      final occupant = grouping.findGroup(cell);
      if (occupant != null && occupant.id != group.id) {
        displacedGroups.add(occupant);
      }
    }

    // 3. Every displaced multi-cell group is pushed rigidly by ONE
    //    translation ([_displacedShift]) — the inverse of the move,
    //    stretched past the moving group's own footprint when the move is
    //    short enough that source and destination overlap. Check the FULL
    //    component of each affected group (not just the cells inside the
    //    destination): every one of its cells must land on a vacated cell
    //    and stay on the board. Otherwise the group would be split,
    //    overlapped, or pushed off the edge, and the whole move is
    //    rejected. This reads only cell coordinates — it is independent of
    //    group size, group shape, move direction, and board dimensions.
    final moverExtent = _extentOf(group.cells, cols);
    final shift = _displacedShift(dRow, dCol, moverExtent.$1, moverExtent.$2);
    final shiftRow = shift.$1;
    final shiftCol = shift.$2;
    for (final displaced in displacedGroups) {
      for (final cell in displaced.cells) {
        final newRow = cell ~/ cols + shiftRow;
        final newCol = cell % cols + shiftCol;
        if (newRow < 0 || newRow >= rows || newCol < 0 || newCol >= cols) {
          return false;
        }
        if (!vacatedSet.contains(newRow * cols + newCol)) {
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

    // 5. Place displaced groups into the vacated cells, translated
    //    rigidly by the exact shift canMoveGroupByCells validated (see
    //    [_displacedShift]). Same vector for every affected group, so
    //    disjoint groups stay disjoint. Size / shape / direction-agnostic.
    final moverExtent = _extentOf(oldCells, cols);
    final shift = _displacedShift(dRow, dCol, moverExtent.$1, moverExtent.$2);
    final shiftRow = shift.$1;
    final shiftCol = shift.$2;
    for (final displaced in displacedGroups) {
      for (final cell in displaced.cells) {
        final destRow = cell ~/ cols + shiftRow;
        final destCol = cell % cols + shiftCol;
        newArr[destRow * cols + destCol] = displacedContents[cell]!;
      }
    }

    // 6. Relocate the solo (ungrouped) pieces that were sitting in the
    //    group's destination cells. A solo piece is never an obstacle —
    //    correctly placed or not, it is simply shoved into a cell the
    //    group vacated. It must NOT be left overwritten: the number of
    //    displaced solo pieces always equals the number of still-empty
    //    vacated cells, so every piece is conserved and the arrangement
    //    stays a valid permutation.
    //
    //    Prefer the cell reached by the OPPOSITE displacement so a plain
    //    swap reads naturally (e.g. [A A] dragged onto solo [B C] gives
    //    [B C A A]); otherwise drop the piece in any still-empty vacated
    //    cell.
    final rows = grouping.rows;
    for (final cell in newCells) {
      if (oldCellSet.contains(cell)) continue; // Group re-occupied it.
      if (displacedContents.containsKey(cell)) continue; // Moved as a group.

      final piece = origArr[cell];
      final preferredRow = cell ~/ cols + shiftRow;
      final preferredCol = cell % cols + shiftCol;
      final preferredCell = preferredRow * cols + preferredCol;
      final preferredInBounds = preferredRow >= 0 &&
          preferredRow < rows &&
          preferredCol >= 0 &&
          preferredCol < cols;

      if (preferredInBounds &&
          oldCellSet.contains(preferredCell) &&
          newArr[preferredCell] == 0) {
        newArr[preferredCell] = piece;
        continue;
      }
      for (final oldCell in oldCells) {
        if (newArr[oldCell] == 0) {
          newArr[oldCell] = piece;
          break;
        }
      }
    }

    // Final safety net — atomic all-or-nothing. The candidate board MUST
    // be a permutation of the original: same length, every tile id once,
    // no cleared (0) cell left behind. canMoveGroupByCells already
    // rejects the geometry that could break this; if anything ever slips
    // through, discard the whole candidate and leave the board exactly as
    // it was rather than emit an overlapping / inconsistent arrangement.
    if (!_isPermutation(newArr)) {
      return state;
    }

    return (arrangement: newArr);
  }

  /// Whether [candidate] is a permutation of `1..candidate.length` — the
  /// board invariant: every tile id appears exactly once, with no
  /// duplicates, no missing ids, and no 0 (empty) cell.
  static bool _isPermutation(List<int> candidate) {
    final seen = List<bool>.filled(candidate.length + 1, false);
    for (final id in candidate) {
      if (id < 1 || id > candidate.length || seen[id]) return false;
      seen[id] = true;
    }
    return true;
  }

  /// Bounding-box extent `(height, width)`, in cells, of an arbitrary set
  /// of board [cells]. Works for any shape — rectangle, L, T, cross,
  /// disconnected — since it only takes the min/max row and column.
  static (int, int) _extentOf(Iterable<int> cells, int cols) {
    var minRow = 1 << 30;
    var maxRow = -1;
    var minCol = 1 << 30;
    var maxCol = -1;
    for (final cell in cells) {
      final row = cell ~/ cols;
      final col = cell % cols;
      if (row < minRow) minRow = row;
      if (row > maxRow) maxRow = row;
      if (col < minCol) minCol = col;
      if (col > maxCol) maxCol = col;
    }
    return (maxRow - minRow + 1, maxCol - minCol + 1);
  }

  /// The single rigid translation `(dRow, dCol)` applied to every piece
  /// and group the moving group displaces.
  ///
  /// Displaced content is pushed OPPOSITE to the move, into the cells the
  /// moving group frees:
  ///
  /// * When the move is at least as long as the moving group's own extent
  ///   along an axis, source and destination footprints do NOT overlap,
  ///   and the plain inverse `-delta` lands displaced content exactly on
  ///   the vacated old cells.
  /// * When the move is SHORTER than that extent the footprints overlap;
  ///   `-delta` would land displaced content on cells the moving group
  ///   re-occupies. Stretching the translation to the group's full extent
  ///   ([moverHeight] / [moverWidth]) instead lands it in the vacated slab
  ///   at the trailing edge.
  ///
  /// `max(|delta|, extent)` selects the right magnitude in both regimes;
  /// `sign` makes it direction-symmetric — up/down, left/right, and
  /// negative/positive deltas all go through the exact same expression.
  /// A zero delta on an axis yields a zero shift on that axis. This is
  /// pure board geometry: no branch on group size, group shape, drag
  /// direction, or board dimensions.
  static (int, int) _displacedShift(
    int dRow,
    int dCol,
    int moverHeight,
    int moverWidth,
  ) {
    final absRow = dRow.abs();
    final absCol = dCol.abs();
    final tRow = dRow == 0
        ? 0
        : -dRow.sign * (absRow > moverHeight ? absRow : moverHeight);
    final tCol = dCol == 0
        ? 0
        : -dCol.sign * (absCol > moverWidth ? absCol : moverWidth);
    return (tRow, tCol);
  }
}
