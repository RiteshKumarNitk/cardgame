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
    required this.arrangement,
    required this.timeRemainingSeconds,
    this.isFailed = false,
    this.moves = 0,
    this.justSolved = false,
    this.coinsEarned = 0,
  });

  final DailyChallenge challenge;
  final String imageUrl;

  /// `arrangement[cell]` is the 1-based piece index currently sitting in
  /// that (0-based) cell — see `TileSwapEngine`.
  final List<int> arrangement;

  final int timeRemainingSeconds;
  final bool isFailed;

  final int moves;

  /// True only once solved *this* session — distinguishes "just finished,
  /// show the celebration" from "opened after already finishing earlier
  /// today".
  final bool justSolved;
  final int coinsEarned;

  bool get isComplete => challenge.alreadyCompletedToday || justSolved;

  DailyChallengeReady copyWith({
    List<int>? arrangement,
    int? timeRemainingSeconds,
    bool? isFailed,
    int? moves,
    bool? justSolved,
    int? coinsEarned,
    DailyChallenge? challenge,
  }) {
    return DailyChallengeReady(
      challenge: challenge ?? this.challenge,
      imageUrl: imageUrl,
      arrangement: arrangement ?? this.arrangement,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      isFailed: isFailed ?? this.isFailed,
      moves: moves ?? this.moves,
      justSolved: justSolved ?? this.justSolved,
      coinsEarned: coinsEarned ?? this.coinsEarned,
    );
  }

  @override
  List<Object?> get props => [
    challenge,
    imageUrl,
    arrangement,
    timeRemainingSeconds,
    isFailed,
    moves,
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
