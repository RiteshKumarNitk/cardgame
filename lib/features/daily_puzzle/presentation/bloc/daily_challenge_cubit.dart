import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../achievements/domain/services/achievement_events.dart';
import '../../../puzzle/domain/puzzle_board_size.dart';
import '../../../puzzle/domain/puzzle_image.dart';
import '../../../puzzle/domain/tile_swap_engine.dart';
import '../../domain/services/daily_challenge_service.dart';
import 'daily_challenge_state.dart';

/// Drives the Daily Challenge: loads today's status, runs the same
/// tile-swap mechanic as a regular puzzle (fixed at
/// [DailyChallengeService.difficulty]), and on solving awards a
/// streak-scaled coin bonus through [DailyChallengeService.completeToday].
class DailyChallengeCubit extends Cubit<DailyChallengeState> {
  DailyChallengeCubit(this._service, {AchievementEvents? achievementEvents})
    : _achievementEvents = achievementEvents,
      super(const DailyChallengeLoading());

  final DailyChallengeService _service;

  /// Optional sink for milestone events (achievements). Nullable so the
  /// cubit stays constructible standalone in tests.
  final AchievementEvents? _achievementEvents;

  Future<void> load() async {
    emit(const DailyChallengeLoading());
    try {
      final now = DateTime.now();
      final challenge = await _service.loadToday(now);
      final arrangement = TileSwapEngine.shuffledArrangement(
        pieceCount: boardDimensionsFor(challenge.difficulty).pieceCount,
        seed: challenge.dateKey.hashCode,
      );
      emit(
        DailyChallengeReady(
          challenge: challenge,
          imageUrl: puzzleImageUrlForDaily(challenge.dateKey),
          arrangement: arrangement,
        ),
      );
    } catch (e) {
      emit(DailyChallengeError(e.toString()));
    }
  }

  Future<void> swapPieces(int fromCell, int toCell) async {
    final current = state;
    if (current is! DailyChallengeReady || current.isComplete) return;

    final arrangement = TileSwapEngine.swap(
      current.arrangement,
      fromCell,
      toCell,
    );
    if (identical(arrangement, current.arrangement)) return;

    final solved = TileSwapEngine.isSolved(arrangement);
    if (!solved) {
      emit(current.copyWith(arrangement: arrangement, moves: current.moves + 1));
      return;
    }

    final completed = await _service.completeToday(DateTime.now());
    await _achievementEvents?.onDailyChallengeCompleted(completed.streak);
    emit(
      current.copyWith(
        arrangement: arrangement,
        moves: current.moves + 1,
        justSolved: true,
        coinsEarned: coinsFor(completed.streak),
        challenge: completed,
      ),
    );
  }

  /// Base reward plus a streak bonus, capped at a 10-day streak.
  static int coinsFor(int streak) => 100 + (streak.clamp(0, 10) * 10);
}
