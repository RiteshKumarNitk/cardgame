import 'package:equatable/equatable.dart';

import '../../../levels/domain/entities/level.dart';

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
    required this.arrangement,
    required this.rotations,
    required this.minimalSwaps,
    this.shuffleGeneration = 0,
    this.moves = 0,
    this.elapsedSeconds = 0,
    this.isSolved = false,
    this.isPaused = false,
    this.currentCombo = 0,
    this.stuckShuffleReady = false,
  });

  final Level level;

  /// `arrangement[cell]` is the 1-based piece index currently sitting in
  /// that (0-based) cell — see [TileSwapEngine].
  final List<int> arrangement;

  /// `rotations[cell]` is the 0-3 quarter-turns clockwise rotation of the piece.
  final List<int> rotations;

  /// The fewest swaps this shuffle could be solved in — the baseline for
  /// [stars].
  final int minimalSwaps;

  /// Increments on every (re)shuffle of this level — used as the board
  /// key so the deal-in entrance animation replays on restart/shuffle.
  final int shuffleGeneration;
  final int moves;
  final int elapsedSeconds;
  final bool isSolved;
  final bool isPaused;

  /// True after several moves in a row made no progress (no piece locked)
  /// — the UI offers a free pity shuffle.
  final bool stuckShuffleReady;

  /// The current combo count (pieces locked within a small time window).
  /// 0 means no active combo, 2 means a 2x combo, etc.
  final int currentCombo;

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
    List<int>? rotations,
    int? moves,
    int? elapsedSeconds,
    bool? isSolved,
    bool? isPaused,
    int? currentCombo,
    bool? stuckShuffleReady,
  }) {
    return PuzzleLoaded(
      level: level,
      arrangement: arrangement ?? this.arrangement,
      rotations: rotations ?? this.rotations,
      minimalSwaps: minimalSwaps,
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
    arrangement,
    rotations,
    minimalSwaps,
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
