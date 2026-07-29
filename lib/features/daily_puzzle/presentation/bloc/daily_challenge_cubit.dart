import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../puzzle/domain/puzzle_board_size.dart';
import '../../../puzzle/domain/puzzle_image.dart';
import '../../../puzzle/domain/tile_matching.dart';
import '../../domain/services/daily_challenge_service.dart';
import 'daily_challenge_state.dart';

/// Drives the Daily Challenge: loads today's status, runs the same
/// piece-matching mechanic as a regular puzzle (fixed at
/// [DailyChallengeService.difficulty]), and on solving awards a
/// streak-scaled coin bonus through [DailyChallengeService.completeToday].
class DailyChallengeCubit extends Cubit<DailyChallengeState> {
  DailyChallengeCubit(this._service) : super(const DailyChallengeLoading());

  final DailyChallengeService _service;

  Future<void> load() async {
    emit(const DailyChallengeLoading());
    try {
      final now = DateTime.now();
      final challenge = await _service.loadToday(now);
      emit(
        DailyChallengeReady(
          challenge: challenge,
          imageUrl: puzzleImageUrlForDaily(challenge.dateKey),
        ),
      );
    } catch (e) {
      emit(DailyChallengeError(e.toString()));
    }
  }

  Future<bool> attemptPlacePiece(int pieceIndex, int slotIndex) async {
    final current = state;
    if (current is! DailyChallengeReady || current.isComplete) return false;

    if (!isCorrectPlacement(pieceIndex, slotIndex)) {
      emit(
        current.copyWith(
          moves: current.moves + 1,
          wrongAttempts: current.wrongAttempts + 1,
        ),
      );
      return false;
    }

    final placed = {...current.placedPieceIds, pieceIndex};
    final size = boardSizeFor(current.challenge.difficulty);
    final solved = placed.length == size * size;

    if (!solved) {
      emit(current.copyWith(placedPieceIds: placed, moves: current.moves + 1));
      return true;
    }

    final completed = await _service.completeToday(DateTime.now());
    emit(
      current.copyWith(
        placedPieceIds: placed,
        moves: current.moves + 1,
        justSolved: true,
        coinsEarned: coinsFor(completed.streak),
        challenge: completed,
      ),
    );
    return true;
  }

  /// Base reward plus a streak bonus, capped at a 10-day streak.
  static int coinsFor(int streak) => 100 + (streak.clamp(0, 10) * 10);
}
