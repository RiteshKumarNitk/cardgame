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
  /// A connected group is a MOVEABLE puzzle object. The only real
  /// constraint on a move is the MOVING group's own rigidity: every one of
  /// its cells, shifted by ([dRow], [dCol]), must land on the board.
  ///
  /// Whatever currently occupies the destination cells — a solo tile, part
  /// of a connected group, or a whole group — is NEVER an obstacle and
  /// never protected as a rigid unit. [moveGroupByCells] displaces each
  /// individual displaced cell into a vacated cell; a group sitting at the
  /// destination is not required to move as one piece and may end up
  /// split once the board is re-grouped from scratch. This is always
  /// geometrically possible: a rigid shift of an N-cell group vacates
  /// exactly as many old cells as it overwrites at the destination, so
  /// every displaced piece always has a home to go to.
  ///
  /// CORRECT POSITION ≠ LOCKED. CONNECTED ≠ LOCKED. A group is fully
  /// movable at all times until the puzzle is ultimately solved, and a
  /// group's PAST shape/connections have no bearing on future moves —
  /// grouping is always recomputed from scratch after the move.
  static bool canMoveGroupByCells(
    PuzzleGroup group,
    int dRow,
    int dCol,
    PuzzleGrouping grouping,
  ) {
    final cols = grouping.cols;
    final rows = grouping.rows;

    // The only real constraint: every cell of the MOVING group, shifted
    // to its new position, must stay on the board.
    for (final cell in group.cells) {
      final row = cell ~/ cols;
      final col = cell % cols;
      final newRow = row + dRow;
      final newCol = col + dCol;
      if (newRow < 0 || newRow >= rows || newCol < 0 || newCol >= cols) {
        return false;
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
  /// - Whatever occupies the destination cells is displaced per CELL, not
  ///   per group — a group sitting at the destination is never treated as
  ///   a protected, rigid whole. Only the cells the moving group actually
  ///   lands on are displaced; any other members of that group are left
  ///   completely untouched. A destination group can therefore end up
  ///   split across the board once grouping is recomputed from the
  ///   resulting arrangement — it is never preserved just because it used
  ///   to be connected.
  /// - After the move, [grouping] must be rebuilt from scratch by the
  ///   caller (adjacency → grouping) — this function only produces the
  ///   new arrangement.
  static BoardState moveGroupByCells(
    BoardState state,
    PuzzleGrouping grouping,
    PuzzleGroup group,
    int dRow,
    int dCol,
  ) {
    if (dRow == 0 && dCol == 0) return state;

    final cols = grouping.cols;
    final rows = grouping.rows;
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
    final oldCellSet = oldCells.toSet();

    // 1. Record what was in the old cells, then vacate them.
    final oldContents = <int, int>{};
    for (final cell in oldCells) {
      oldContents[cell] = origArr[cell];
    }
    for (final cell in oldCells) {
      newArr[cell] = 0;
    }

    // 2. Record whatever sits in the destination cells the mover doesn't
    //    already occupy, then clear those cells — per CELL, regardless of
    //    whether that cell's occupant belongs to a group. A group is
    //    never treated as an all-or-nothing block here.
    final displacedContents = <int, int>{};
    for (final cell in newCells) {
      if (oldCellSet.contains(cell)) continue; // Self-overlap: mover keeps it.
      displacedContents[cell] = origArr[cell];
      newArr[cell] = 0;
    }

    // 3. Place the group at its new position.
    for (var i = 0; i < newCells.length; i++) {
      newArr[newCells[i]] = oldContents[oldCells[i]]!;
    }

    // 4. Relocate every displaced piece into a vacated cell. The number of
    //    vacated cells (`oldCells \ newCells`) always exactly equals the
    //    number of displaced pieces (`newCells \ oldCells`), since oldCells
    //    and newCells are the same size — so every piece always finds a
    //    home; this can never be the reason a move is rejected. Prefer the
    //    cell reached by the OPPOSITE displacement so a plain push reads
    //    naturally (e.g. [A A] dragged onto [B C] gives [B C A A]);
    //    otherwise drop the piece in any still-vacant cell. Each piece is
    //    relocated independently, so a group that was sitting at the
    //    destination can scatter across separate vacated cells instead of
    //    moving as one rigid unit.
    final moverExtent = _extentOf(oldCells, cols);
    final shift = _displacedShift(dRow, dCol, moverExtent.$1, moverExtent.$2);
    final shiftRow = shift.$1;
    final shiftCol = shift.$2;
    final remainingVacated = oldCellSet.difference(newCells.toSet()).toList();

    for (final entry in displacedContents.entries) {
      final cell = entry.key;
      final piece = entry.value;

      final preferredRow = cell ~/ cols + shiftRow;
      final preferredCol = cell % cols + shiftCol;
      final preferredCell = preferredRow * cols + preferredCol;
      final preferredInBounds = preferredRow >= 0 &&
          preferredRow < rows &&
          preferredCol >= 0 &&
          preferredCol < cols;

      final target = (preferredInBounds && remainingVacated.contains(preferredCell))
          ? preferredCell
          : remainingVacated.first;
      newArr[target] = piece;
      remainingVacated.remove(target);
    }

    // Final safety net — atomic all-or-nothing. The candidate board MUST
    // be a permutation of the original: same length, every tile id once,
    // no cleared (0) cell left behind. This can never actually fail given
    // the construction above; kept as a defensive invariant check so an
    // inconsistent board is never emitted instead of a move being rejected.
    if (!_isPermutation(newArr)) {
      return state;
    }

    return (arrangement: newArr);
  }

  // ─── Group ⇄ Group Swap ───────────────────────────────────────────

  /// Whether [a] and [b] are the same rigid shape — identical cell count
  /// and identical set of cell offsets relative to each group's own
  /// bounding-box top-left. Only the shape matters; where the two groups
  /// currently sit is irrelevant. This is the eligibility test for a
  /// direct [swapGroups] exchange.
  ///
  /// Pure geometry via each group's precomputed `relativePositions`: no
  /// board dimensions, no absolute coordinates, no size threshold — a
  /// 2-cell domino, a 7-cell blob and everything between run the exact
  /// same set comparison. Records compare structurally, so the
  /// `Set<(int, int)>` membership check is value-based.
  static bool groupsShareShape(PuzzleGroup a, PuzzleGroup b) {
    if (a.cells.length != b.cells.length) return false;
    final shapeA = a.relativePositions.toSet();
    final shapeB = b.relativePositions.toSet();
    return shapeA.length == shapeB.length && shapeA.containsAll(shapeB);
  }

  /// Atomically exchanges the board contents of two connected groups [a]
  /// and [b] that pass [groupsShareShape].
  ///
  /// Each cell of [a] trades contents with the cell of [b] at the SAME
  /// normalized offset, so both groups keep their exact internal
  /// arrangement — and therefore their edge connections — and simply
  /// change places. Nothing else on the board moves.
  ///
  /// Direction-agnostic by construction: no displacement vector, no sign,
  /// no bounds arithmetic — just a bijection between two equal-shaped,
  /// disjoint cell sets, so it behaves identically for left⇄right,
  /// right⇄left, top⇄bottom, bottom⇄top and on any board size. Distinct
  /// groups from [PuzzleGrouping.fromAdjacency] are always disjoint, so
  /// no cell is written twice.
  ///
  /// Computes the whole candidate first, then commits once. Returns
  /// [state] unchanged if the shapes don't line up or the result would
  /// not be a permutation (defensive — callers gate on [groupsShareShape]
  /// first, so the board is never left half-mutated).
  static BoardState swapGroups(BoardState state, PuzzleGroup a, PuzzleGroup b) {
    final origArr = state.arrangement;
    final newArr = List<int>.of(origArr);

    final bCellByOffset = <(int, int), int>{};
    for (var i = 0; i < b.cells.length; i++) {
      bCellByOffset[b.relativePositions[i]] = b.cells[i];
    }

    for (var i = 0; i < a.cells.length; i++) {
      final aCell = a.cells[i];
      final bCell = bCellByOffset[a.relativePositions[i]];
      if (bCell == null) return state; // Shapes don't line up — no-op.
      newArr[aCell] = origArr[bCell];
      newArr[bCell] = origArr[aCell];
    }

    if (!_isPermutation(newArr)) return state;
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
