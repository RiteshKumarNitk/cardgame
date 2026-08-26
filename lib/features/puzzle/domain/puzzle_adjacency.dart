/// Edge-level adjacency state for the puzzle board.
///
/// For every atomic cell, determines whether each of its four edges is
/// connected to its currently neighboring piece. Two board-adjacent cells
/// are connected when the PIECES currently sitting in them are neighbors
/// in the solved image — i.e. a purely RELATIVE relationship:
///
///     current[right] is the piece immediately right of current[left]
///     in the solved image
///
/// This is deliberately independent of whether either piece is at its
/// own correct absolute board position. Two pieces that belong next to
/// each other connect the moment they're placed next to each other on
/// the board, wherever that happens to be — exactly like discovering two
/// jigsaw pieces fit together. Connected edges have their shared border
/// removed, visually joining the cells. The connected cells remain fully
/// movable — they form a connected group, never a locked region.
class PuzzleAdjacency {
  const PuzzleAdjacency({
    required this.edges,
    required this.cols,
    required this.rows,
  });

  /// Per-cell edge connectivity bitmask.
  ///
  /// [edges][cell] is a bitmask of [Edge] flags indicating which edges
  /// of that cell are connected to a currently-adjacent piece that is
  /// also its solved-image neighbor — see [computeAdjacency].
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
/// Two board-adjacent cells are connected when the pieces CURRENTLY
/// sitting in them are neighbors in the solved image — a relative
/// relationship, evaluated purely from each piece's own solved row/col,
/// never from whether either piece is at its own correct absolute board
/// position. `arrangement[cell] == cell + 1` (absolute correctness) is
/// NOT a prerequisite anywhere in this function — a piece two rows away
/// from home can still connect to its solved neighbor the moment the
/// player places them next to each other.
///
/// For Easy/Medium (no groups), adjacency is still computed for visual
/// border removal between currently-adjacent solved-neighbor tiles.
PuzzleAdjacency computeAdjacency({
  required List<int> arrangement,
  required int cols,
  required int rows,
}) {
  final cellCount = cols * rows;
  final edges = List.filled(cellCount, 0);

  // A piece's row/col in the SOLVED image (piece indices are 1-based;
  // solved cell index is piece - 1).
  int solvedRowOf(int piece) => (piece - 1) ~/ cols;
  int solvedColOf(int piece) => (piece - 1) % cols;

  for (var cell = 0; cell < cellCount; cell++) {
    final row = cell ~/ cols;
    final col = cell % cols;
    final piece = arrangement[cell];

    // Check right neighbor: connect when the piece currently to the
    // right is this piece's solved right-neighbor — same solved row,
    // one solved column over. The same-row check guards against a
    // false match at a solved row boundary (e.g. the last piece of one
    // row and the first piece of the next differ by exactly 1 in index
    // but are not actually horizontally adjacent in the solved image).
    if (col < cols - 1) {
      final rightCell = cell + 1;
      final rightPiece = arrangement[rightCell];
      if (solvedRowOf(rightPiece) == solvedRowOf(piece) &&
          solvedColOf(rightPiece) == solvedColOf(piece) + 1) {
        edges[cell] |= Edge.right.mask;
        edges[rightCell] |= Edge.left.mask;
      }
    }

    // Check bottom neighbor: connect when the piece currently below is
    // this piece's solved bottom-neighbor — same solved column, one
    // solved row down.
    if (row < rows - 1) {
      final bottomCell = cell + cols;
      final bottomPiece = arrangement[bottomCell];
      if (solvedColOf(bottomPiece) == solvedColOf(piece) &&
          solvedRowOf(bottomPiece) == solvedRowOf(piece) + 1) {
        edges[cell] |= Edge.bottom.mask;
        edges[bottomCell] |= Edge.top.mask;
      }
    }
  }

  return PuzzleAdjacency(edges: edges, cols: cols, rows: rows);
}
