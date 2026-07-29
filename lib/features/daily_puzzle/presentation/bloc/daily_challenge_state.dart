import 'package:equatable/equatable.dart';

import '../../domain/entities/daily_challenge.dart';

sealed class DailyChallengeState extends Equatable {
  const DailyChallengeState();

  @override
  List<Object?> get props => [];
}

final class DailyChallengeLoading extends DailyChallengeState {
  const DailyChallengeLoading();
}

final class DailyChallengeReady extends DailyChallengeState {
  const DailyChallengeReady({
    required this.challenge,
    required this.imageUrl,
    this.placedPieceIds = const {},
    this.moves = 0,
    this.wrongAttempts = 0,
    this.justSolved = false,
    this.coinsEarned = 0,
  });

  final DailyChallenge challenge;
  final String imageUrl;
  final Set<int> placedPieceIds;
  final int moves;
  final int wrongAttempts;

  /// True only once solved *this* session — distinguishes "just finished,
  /// show the celebration" from "opened after already finishing earlier
  /// today".
  final bool justSolved;
  final int coinsEarned;

  bool get isComplete => challenge.alreadyCompletedToday || justSolved;

  DailyChallengeReady copyWith({
    Set<int>? placedPieceIds,
    int? moves,
    int? wrongAttempts,
    bool? justSolved,
    int? coinsEarned,
    DailyChallenge? challenge,
  }) {
    return DailyChallengeReady(
      challenge: challenge ?? this.challenge,
      imageUrl: imageUrl,
      placedPieceIds: placedPieceIds ?? this.placedPieceIds,
      moves: moves ?? this.moves,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
      justSolved: justSolved ?? this.justSolved,
      coinsEarned: coinsEarned ?? this.coinsEarned,
    );
  }

  @override
  List<Object?> get props => [
    challenge,
    imageUrl,
    placedPieceIds,
    moves,
    wrongAttempts,
    justSolved,
    coinsEarned,
  ];
}

final class DailyChallengeError extends DailyChallengeState {
  const DailyChallengeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
