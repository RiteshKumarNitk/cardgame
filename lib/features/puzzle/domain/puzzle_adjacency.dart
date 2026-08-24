/// Edge-level adjacency state for the puzzle board.
///
/// For every atomic cell, determines whether each of its four edges is
/// connected to its correct neighboring piece. Two adjacent cells are
/// connected when:
///
/// 1. Both cells contain correctly placed pieces (`arrangement[cell] == cell + 1`).
/// 2. The two pieces are correctly adjacent in the solved puzzle.
///
/// Connected edges have their shared border removed, visually joining
/// the cells. The connected cells remain fully movable — they form a
/// connected group, not a locked region.
class PuzzleAdjacency {
  const PuzzleAdjacency({
    required this.edges,
    required this.cols,
    required this.rows,
  });

  /// Per-cell edge connectivity bitmask.
  ///
  /// [edges][cell] is a bitmask of [Edge] flags indicating which edges
  /// of that cell are connected to correctly adjacent neighbors.
  final List<int> edges;

  /// Board column count.
  final int cols;

  /// Board row count.
  final int rows;

  /// Total number of cells.
  int get cellCount => cols * rows;

  /// Whether [cell] has a connected edge in direction [edge].
  bool isConnected(int cell, Edge edge) => (edges[cell] & edge.mask) != 0;

  /// Whether [cell] has any connected edge.
  bool hasAnyConnection(int cell) => edges[cell] != 0;

  /// The number of connected edges for [cell].
  int connectionCount(int cell) {
    var count = 0;
    var v = edges[cell];
    while (v != 0) {
      count += v & 1;
      v >>= 1;
    }
    return count;
  }

  /// Total number of connected edges across the entire board.
  ///
  /// Each shared edge is counted once (from the lower-indexed cell).
  int get totalConnections {
    var total = 0;
    for (var cell = 0; cell < cellCount; cell++) {
      final row = cell ~/ cols;
      final col = cell % cols;
      // Only count right and bottom to avoid double-counting.
      if (col < cols - 1 && isConnected(cell, Edge.right)) total++;
      if (row < rows - 1 && isConnected(cell, Edge.bottom)) total++;
    }
    return total;
  }

  /// Maximum possible connections for this board size.
  int get maxConnections => cols * (rows - 1) + rows * (cols - 1);
}

/// The four edges of a cell, used as a bitmask.
enum Edge {
  top(1),
  right(2),
  bottom(4),
  left(8);

  const Edge(this.mask);

  /// Bitmask value for this edge.
  final int mask;

  /// The opposite edge (top↔bottom, left↔right).
  Edge get opposite => switch (this) {
        Edge.top => Edge.bottom,
        Edge.right => Edge.left,
        Edge.bottom => Edge.top,
        Edge.left => Edge.right,
      };
}

/// Computes edge-level adjacency for the current arrangement.
///
/// Two adjacent cells are connected when both contain correctly placed
/// pieces that are correctly adjacent in the solved puzzle.
///
/// For Easy/Medium (no groups), adjacency is still computed for visual
/// border removal between correctly adjacent individual tiles.
PuzzleAdjacency computeAdjacency({
  required List<int> arrangement,
  required int cols,
  required int rows,
}) {
  final cellCount = cols * rows;
  final edges = List.filled(cellCount, 0);

  for (var cell = 0; cell < cellCount; cell++) {
    final row = cell ~/ cols;
    final col = cell % cols;
    final piece = arrangement[cell];

    // A cell is correctly placed when arrangement[cell] == cell + 1.
    final isCorrect = piece == cell + 1;

    if (!isCorrect) continue;

    // Check right neighbor.
    if (col < cols - 1) {
      final rightCell = cell + 1;
      final rightPiece = arrangement[rightCell];
      // Right neighbor is correct when arrangement[rightCell] == rightCell + 1.
      if (rightPiece == rightCell + 1) {
        edges[cell] |= Edge.right.mask;
        edges[rightCell] |= Edge.left.mask;
      }
    }

    // Check bottom neighbor.
    if (row < rows - 1) {
      final bottomCell = cell + cols;
      final bottomPiece = arrangement[bottomCell];
      // Bottom neighbor is correct when arrangement[bottomCell] == bottomCell + 1.
      if (bottomPiece == bottomCell + 1) {
        edges[cell] |= Edge.bottom.mask;
        edges[bottomCell] |= Edge.top.mask;
      }
    }
  }

  return PuzzleAdjacency(edges: edges, cols: cols, rows: rows);
}
