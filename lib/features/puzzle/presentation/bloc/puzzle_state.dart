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
    this.placedPieceIds = const {},
    this.moves = 0,
    this.wrongAttempts = 0,
    this.elapsedSeconds = 0,
    this.isSolved = false,
  });

  final Level level;

  /// 1-based piece indices that have been dropped on their correct slot.
  final Set<int> placedPieceIds;
  final int moves;
  final int wrongAttempts;
  final int elapsedSeconds;
  final bool isSolved;

  /// 1-3, derived from [wrongAttempts] — the single source of truth for
  /// star rating, read by both the persistence call and the UI.
  int get stars {
    if (wrongAttempts == 0) return 3;
    if (wrongAttempts <= 2) return 2;
    return 1;
  }

  PuzzleLoaded copyWith({
    Set<int>? placedPieceIds,
    int? moves,
    int? wrongAttempts,
    int? elapsedSeconds,
    bool? isSolved,
  }) {
    return PuzzleLoaded(
      level: level,
      placedPieceIds: placedPieceIds ?? this.placedPieceIds,
      moves: moves ?? this.moves,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isSolved: isSolved ?? this.isSolved,
    );
  }

  @override
  List<Object?> get props => [
    level,
    placedPieceIds,
    moves,
    wrongAttempts,
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
