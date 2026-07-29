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
    required this.minimalSwaps,
    this.moves = 0,
    this.elapsedSeconds = 0,
    this.isSolved = false,
  });

  final Level level;

  /// `arrangement[cell]` is the 1-based piece index currently sitting in
  /// that (0-based) cell — see [TileSwapEngine].
  final List<int> arrangement;

  /// The fewest swaps this shuffle could be solved in — the baseline for
  /// [stars].
  final int minimalSwaps;
  final int moves;
  final int elapsedSeconds;
  final bool isSolved;

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
    int? moves,
    int? elapsedSeconds,
    bool? isSolved,
  }) {
    return PuzzleLoaded(
      level: level,
      arrangement: arrangement ?? this.arrangement,
      minimalSwaps: minimalSwaps,
      moves: moves ?? this.moves,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isSolved: isSolved ?? this.isSolved,
    );
  }

  @override
  List<Object?> get props => [
    level,
    arrangement,
    minimalSwaps,
    moves,
    elapsedSeconds,
    isSolved,
  ];
}

final class PuzzleError extends PuzzleState {
  const PuzzleError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
