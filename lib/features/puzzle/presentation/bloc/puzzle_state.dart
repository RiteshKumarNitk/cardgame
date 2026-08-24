import 'package:equatable/equatable.dart';

import '../../../levels/domain/entities/level.dart';
import '../../../levels/domain/entities/level_config.dart';
import '../../domain/puzzle_adjacency.dart';
import '../../domain/puzzle_group.dart';

sealed class PuzzleState extends Equatable {
  const PuzzleState();

  @override
  List<Object?> get props => [];
}

final class PuzzleInitial extends PuzzleState {
  const PuzzleInitial();
}

final class PuzzleLoading extends PuzzleState {
  const PuzzleLoading();
}

final class PuzzleLoaded extends PuzzleState {
  const PuzzleLoaded({
    required this.level,
    required this.config,
    required this.arrangement,
    required this.minimalSwaps,
    required this.adjacency,
    this.grouping,
    this.shuffleGeneration = 0,
    this.moves = 0,
    this.elapsedSeconds = 0,
    this.isSolved = false,
    this.isPaused = false,
    this.currentCombo = 0,
    this.stuckShuffleReady = false,
  });

  final Level level;

  /// The complete puzzle configuration — grid size, difficulty, seed,
  /// progression role, and all other parameters the engine needs.
  /// The puzzle engine consumes this exclusively; it never touches
  /// Chapter or Section directly.
  final LevelConfig config;

  /// `arrangement[cell]` is the 1-based piece index currently sitting in
  /// that (0-based) cell — see [TileSwapEngine].
  final List<int> arrangement;

  /// The fewest swaps this shuffle could be solved in — the baseline for
  /// [stars].
  final int minimalSwaps;

  /// Edge-level adjacency state. For every cell, determines which of
  /// its four edges are connected to correctly adjacent neighbors.
  /// Computed after every move from the current arrangement.
  final PuzzleAdjacency adjacency;

  /// Dynamically-computed groups formed from adjacency connections.
  /// Multi-cell groups move as one unit. `null` or empty for
  /// Easy/Medium (individual tiles only).
  final PuzzleGrouping? grouping;

  /// Increments on every (re)shuffle of this level — used as the board
  /// key so the deal-in entrance animation replays on restart/shuffle.
  final int shuffleGeneration;
  final int moves;
  final int elapsedSeconds;
  final bool isSolved;
  final bool isPaused;

  /// True after several moves in a row made no progress (no new adjacency)
  /// — the UI offers a free pity shuffle.
  final bool stuckShuffleReady;

  /// The current combo count (adjacencies formed within a small time window).
  /// 0 means no active combo, 2 means a 2x combo, etc.
  final int currentCombo;

  /// Whether this level uses connected groups (Hard/Expert/Master).
  bool get hasGroups => grouping != null && grouping!.hasGroups;

  /// 1-3, derived from how close [moves] is to [minimalSwaps] — the
  /// single source of truth for star rating, read by both the
  /// persistence call and the UI.
  int get stars {
    if (moves <= minimalSwaps + 1) return 3;
    if (moves <= minimalSwaps * 2 + 2) return 2;
    return 1;
  }

  /// Coin reward for solving, scaled with [stars] so playing cleanly pays
  /// off more.
  int get coinsAwarded => stars * 20;

  PuzzleLoaded copyWith({
    List<int>? arrangement,
    PuzzleAdjacency? adjacency,
    PuzzleGrouping? grouping,
    int? moves,
    int? elapsedSeconds,
    bool? isSolved,
    bool? isPaused,
    int? currentCombo,
    bool? stuckShuffleReady,
  }) {
    return PuzzleLoaded(
      level: level,
      config: config,
      arrangement: arrangement ?? this.arrangement,
      minimalSwaps: minimalSwaps,
      adjacency: adjacency ?? this.adjacency,
      grouping: grouping ?? this.grouping,
      shuffleGeneration: shuffleGeneration,
      moves: moves ?? this.moves,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isSolved: isSolved ?? this.isSolved,
      isPaused: isPaused ?? this.isPaused,
      currentCombo: currentCombo ?? this.currentCombo,
      stuckShuffleReady: stuckShuffleReady ?? this.stuckShuffleReady,
    );
  }

  @override
  List<Object?> get props => [
    level,
    config,
    arrangement,
    minimalSwaps,
    adjacency,
    grouping,
    shuffleGeneration,
    moves,
    elapsedSeconds,
    isSolved,
    isPaused,
    currentCombo,
    stuckShuffleReady,
  ];
}

final class PuzzleError extends PuzzleState {
  const PuzzleError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
