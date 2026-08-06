import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/analytics_service.dart';
import '../../../achievements/domain/services/achievement_events.dart';
import 'package:flutter/services.dart';
import '../../../../services/audio_service.dart';
import '../../../puzzle/domain/puzzle_board_size.dart';
import '../../../puzzle/domain/puzzle_image.dart';
import '../../../puzzle/domain/tile_swap_engine.dart';
import '../../../../services/leaderboard_service.dart';
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
  final AchievementEvents? _achievementEvents;
  Timer? _timer;

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  Future<void> load() async {
    emit(const DailyChallengeLoading());
    try {
      final now = DateTime.now();
      final challenge = await _service.loadToday(now);
      
      final size = boardDimensionsFor(challenge.difficulty);
      final pieceCount = size.pieceCount;
      final seed = challenge.dateKey.hashCode;
      
      final board = TileSwapEngine.shuffledArrangement(
        pieceCount: pieceCount,
        seed: seed,
        withRotation: true,
      );
      
      if (!challenge.alreadyCompletedToday) {
        emit(
          DailyChallengeReady(
            challenge: challenge,
            imageUrl: puzzleImageUrlForDaily(challenge.dateKey),
            arrangement: board.arrangement,
            rotations: board.rotations,
            timeRemainingSeconds: 60, // 60 seconds Time Attack!
            isFailed: false,
          ),
        );
        AnalyticsService().logEvent(AnalyticsService.dailyChallengeStarted);
        _startTimer();
      } else {
        emit(DailyChallengeReady(
          challenge: challenge,
          imageUrl: puzzleImageUrlForDaily(challenge.dateKey),
          arrangement: List.generate(pieceCount, (i) => i + 1),
          rotations: List.filled(pieceCount, 0),
          timeRemainingSeconds: 0,
          justSolved: false, // Already completed *earlier* today, not just now.
        ));
      }
    } catch (e) {
      emit(DailyChallengeError(e.toString()));
    }
  }

  /// Retries the current failed daily challenge for a cost of 50 coins.
  Future<bool> retry(Future<bool> Function(int) spendCoins) async {
    final current = state;
    if (current is! DailyChallengeReady || !current.isFailed) return false;

    // Deduct cost
    final success = await spendCoins(50);
    if (!success) return false;

    final size = boardDimensionsFor(current.challenge.difficulty);
    final pieceCount = size.pieceCount;
    final board = TileSwapEngine.shuffledArrangement(
      pieceCount: pieceCount,
      seed: current.challenge.dateKey.hashCode + DateTime.now().millisecondsSinceEpoch,
      withRotation: true,
    );

    // Emit fresh state and restart timer
    emit(
      current.copyWith(
        isFailed: false,
        arrangement: board.arrangement,
        rotations: board.rotations,
        timeRemainingSeconds: 60,
        moves: 0,
      ),
    );
    _startTimer();
    return true;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state;
      if (current is! DailyChallengeReady || current.isComplete || current.isFailed) {
        _timer?.cancel();
        return;
      }
      
      if (current.timeRemainingSeconds > 0) {
        if (current.timeRemainingSeconds <= 10) {
          AudioService().playTick();
        }
        emit(current.copyWith(timeRemainingSeconds: current.timeRemainingSeconds - 1));
      } else {
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        emit(current.copyWith(isFailed: true));
        AnalyticsService().logEvent(AnalyticsService.dailyChallengeFailed);
      }
    });
  }

  Future<void> swapPieces(int fromCell, int toCell) async {
    final current = state;
    if (current is! DailyChallengeReady || current.isComplete || current.isFailed) return;

    final newState = TileSwapEngine.swap(
      (arrangement: current.arrangement, rotations: current.rotations),
      fromCell,
      toCell,
    );

    // No-op swaps (same cell, or a locked cell) must not count a move.
    if (identical(newState.arrangement, current.arrangement) &&
        identical(newState.rotations, current.rotations)) {
      return;
    }

    emit(current.copyWith(
      arrangement: newState.arrangement,
      rotations: newState.rotations,
      moves: current.moves + 1,
    ));

    if (TileSwapEngine.isSolved(newState)) {
      _onSolved(current, newState.arrangement, newState.rotations);
    }
  }

  Future<void> rotatePiece(int cell) async {
    final current = state;
    if (current is! DailyChallengeReady || current.isComplete || current.isFailed) return;

    // Daily challenges are time attacks; maybe rotation doesn't add a move, 
    // or maybe it does. Let's add a move for simplicity.
    final newRotations = List<int>.of(current.rotations);
    newRotations[cell] = (newRotations[cell] + 1) % 4;

    emit(current.copyWith(rotations: newRotations, moves: current.moves + 1));

    if (TileSwapEngine.isSolved((arrangement: current.arrangement, rotations: newRotations))) {
      _onSolved(current, current.arrangement, newRotations);
    }
  }

  Future<void> _onSolved(DailyChallengeReady current, List<int> arrangement, List<int> rotations) async {
    _timer?.cancel();
    final completed = await _service.completeToday(DateTime.now());
    await _achievementEvents?.onDailyChallengeCompleted(completed.streak);
    
    // Base 100 + Streak Bonus + Speed Bonus (2 coins per remaining second)
    final speedBonus = current.timeRemainingSeconds * 2;
    final coins = coinsFor(completed.streak) + speedBonus;
    
    AnalyticsService().logEvent(
      AnalyticsService.dailyChallengeComplete,
      parameters: {
        'streak': completed.streak,
        'coins': coins,
        'seconds_left': current.timeRemainingSeconds,
      },
    );
    
    // Submit to global leaderboard
    LeaderboardService().submitTimeAttackScore(current.timeRemainingSeconds);
    
    emit(
      current.copyWith(
        arrangement: arrangement,
        rotations: rotations,
        justSolved: true,
        coinsEarned: coins,
        challenge: completed,
      ),
    );
  }

  /// Base reward plus a streak bonus, capped at a 10-day streak.
  static int coinsFor(int streak) => 100 + (streak.clamp(0, 10) * 10);
}
