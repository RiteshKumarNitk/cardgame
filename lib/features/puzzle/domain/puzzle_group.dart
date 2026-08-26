import 'puzzle_adjacency.dart';

/// A connected group of cells that move together as one unit.
///
/// Groups form dynamically from relative-neighbor adjacencies: when the
/// pieces currently in two adjacent cells are each other's solved-image
/// neighbors, they connect into a group — regardless of whether either
/// piece is at its own correct absolute board position. Groups grow as
/// more such connections are created.
///
/// **CONNECTED ≠ LOCKED.** A group is fully movable at all times.
/// It can be repositioned anywhere on the board. The group is never
/// locked, never split, never rotated. The puzzle is solved only when
/// the entire arrangement is correct.
///
/// A group stores:
/// - [id]: unique identifier
/// - [cells]: list of cell indices currently in the group
/// - [relativePositions]: (rowOffset, colOffset) of each cell relative
///   to the group's top-left corner
class PuzzleGroup {
  PuzzleGroup({
    required this.id,
    required this.cells,
    required this.relativePositions,
    required this.cols,
  });

  /// Unique group identifier (0-based).
  final int id;

  /// The cell indices currently occupied by this group, in order.
  final List<int> cells;

  /// Relative position (rowOffset, colOffset) of each cell within the
  /// group's bounding box. The top-left corner of the bounding box is
  /// the minimum row and column across all cells.
  final List<(int, int)> relativePositions;

  /// Board column count (needed for cell index computation).
  final int cols;

  /// The number of cells in this group.
  int get size => cells.length;

  /// Whether this is a single tile (ungrouped).
  bool get isSingle => size == 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PuzzleGroup &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PuzzleGroup(id: $id, cells: $cells)';
}

/// Result of grouping cells into movable units based on adjacency.
///
/// Contains all groups and provides lookup methods. Rebuilt from
/// scratch after every move using [PuzzleGrouping.fromAdjacency].
class PuzzleGrouping {
  PuzzleGrouping({
    required this.groups,
    required this.cols,
    required this.rows,
  }) : cellToGroup = List.filled(cols * rows, -1) {
    _rebuildCellMap();
  }

  /// All groups in this level. Individual (ungrouped) cells are NOT
  /// in this list — they have no entry in cellToGroup (-1).
  final List<PuzzleGroup> groups;

  /// Board column count.
  final int cols;

  /// Board row count.
  final int rows;

  /// Maps each cell index to its group ID, or -1 if ungrouped.
  final List<int> cellToGroup;

  /// Whether this level has any multi-cell groups.
  bool get hasGroups => groups.isNotEmpty;

  /// Rebuilds the cell-to-group lookup from current group membership.
  void _rebuildCellMap() {
    for (var i = 0; i < cellToGroup.length; i++) {
      cellToGroup[i] = -1;
    }
    for (final group in groups) {
      for (final cell in group.cells) {
        cellToGroup[cell] = group.id;
      }
    }
  }

  /// Finds the group containing [cell], or null if the cell is ungrouped.
  PuzzleGroup? findGroup(int cell) {
    final groupId = cellToGroup[cell];
    if (groupId < 0) return null;
    return groups[groupId];
  }

  /// Returns the group ID at [cell], or -1 if ungrouped.
  int groupIdAt(int cell) => cellToGroup[cell];

  /// Builds groups dynamically from adjacency connections using
  /// union-find (disjoint set) on the adjacency graph.
  ///
  /// Each connected component of correctly-adjacent cells becomes
  /// a group. Single cells remain ungrouped.
  static PuzzleGrouping fromAdjacency({
    required PuzzleAdjacency adjacency,
    required int cols,
    required int rows,
  }) {
    final cellCount = cols * rows;

    // Union-Find data structure.
    final parent = List<int>.generate(cellCount, (i) => i);
    final rank = List<int>.filled(cellCount, 0);

    int find(int x) {
      while (parent[x] != x) {
        parent[x] = parent[parent[x]]; // path compression
        x = parent[x];
      }
      return x;
    }

    void union(int x, int y) {
      final rx = find(x);
      final ry = find(y);
      if (rx == ry) return;
      if (rank[rx] < rank[ry]) {
        parent[rx] = ry;
      } else if (rank[rx] > rank[ry]) {
        parent[ry] = rx;
      } else {
        parent[ry] = rx;
        rank[rx]++;
      }
    }

    // Connect adjacent cells that share a connected edge.
    for (var cell = 0; cell < cellCount; cell++) {
      final row = cell ~/ cols;
      final col = cell % cols;

      if (adjacency.isConnected(cell, Edge.right) && col < cols - 1) {
        union(cell, cell + 1);
      }
      if (adjacency.isConnected(cell, Edge.bottom) && row < rows - 1) {
        union(cell, cell + cols);
      }
    }

    // Group cells by their root parent.
    final componentMap = <int, List<int>>{};
    for (var cell = 0; cell < cellCount; cell++) {
      final root = find(cell);
      componentMap.putIfAbsent(root, () => []).add(cell);
    }

    // Build PuzzleGroup for each multi-cell component.
    final groups = <PuzzleGroup>[];
    var nextId = 0;

    for (final component in componentMap.values) {
      if (component.length < 2) continue; // Skip singletons.

      // Compute the bounding box of the component.
      var minRow = rows;
      var maxRow = 0;
      var minCol = cols;
      var maxCol = 0;
      for (final cell in component) {
        final r = cell ~/ cols;
        final c = cell % cols;
        if (r < minRow) minRow = r;
        if (r > maxRow) maxRow = r;
        if (c < minCol) minCol = c;
        if (c > maxCol) maxCol = c;
      }

      // Compute relative positions within the bounding box.
      final relativePositions = <(int, int)>[];
      for (final cell in component) {
        final r = cell ~/ cols;
        final c = cell % cols;
        relativePositions.add((r - minRow, c - minCol));
      }

      groups.add(PuzzleGroup(
        id: nextId,
        cells: component,
        relativePositions: relativePositions,
        cols: cols,
      ));
      nextId++;
    }

    return PuzzleGrouping(groups: groups, cols: cols, rows: rows);
  }
}
