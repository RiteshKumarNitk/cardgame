import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../achievements/domain/services/achievement_events.dart';
import '../../../puzzle/domain/puzzle_board_size.dart';
import '../../../puzzle/domain/puzzle_image.dart';
import '../../../puzzle/domain/tile_swap_engine.dart';
import '../../domain/entities/daily_challenge.dart';
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
      _initBoard(challenge);
    } catch (e) {
      emit(DailyChallengeError(e.toString()));
    }
  }

  void _initBoard(DailyChallenge challenge) {
      final pieceCount = boardDimensionsFor(challenge.difficulty).pieceCount;
      final seed = challenge.dateKey.hashCode + DateTime.now().millisecondsSinceEpoch;
      
      final arrangement = TileSwapEngine.shuffledArrangement(
        pieceCount: pieceCount,
        seed: seed,
      );
      
      final random = math.Random(seed);
      final rotations = List.generate(pieceCount, (_) => random.nextInt(4));
      
      emit(
        DailyChallengeReady(
          challenge: challenge,
          imageUrl: puzzleImageUrlForDaily(challenge.dateKey),
          arrangement: arrangement,
          rotations: rotations,
          timeRemainingSeconds: 60, // 60 seconds Time Attack!
          isFailed: false,
        ),
      );
      
      if (!challenge.alreadyCompletedToday) {
        _startTimer();
      }
  }

  void retry() {
    final current = state;
    if (current is! DailyChallengeReady) return;
    _initBoard(current.challenge);
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
        emit(current.copyWith(timeRemainingSeconds: current.timeRemainingSeconds - 1));
      } else {
        _timer?.cancel();
        emit(current.copyWith(isFailed: true));
      }
    });
  }

  Future<void> swapPieces(int fromCell, int toCell) async {
    final current = state;
    if (current is! DailyChallengeReady || current.isComplete || current.isFailed) return;

    final arrangement = TileSwapEngine.swap(
      current.arrangement,
      fromCell,
      toCell,
    );
    
    // Swap rotations to match the pieces
    final rotations = List<int>.from(current.rotations);
    final tempRot = rotations[fromCell];
    rotations[fromCell] = rotations[toCell];
    rotations[toCell] = tempRot;

    if (identical(arrangement, current.arrangement)) return;

    final solved = TileSwapEngine.isSolved(arrangement) && rotations.every((r) => r == 0);
    if (!solved) {
      emit(current.copyWith(arrangement: arrangement, rotations: rotations, moves: current.moves + 1));
      return;
    }

    _onSolved(current, arrangement, rotations);
  }
  
  Future<void> rotatePiece(int cell) async {
    final current = state;
    if (current is! DailyChallengeReady || current.isComplete || current.isFailed) return;

    final rotations = List<int>.from(current.rotations);
    rotations[cell] = (rotations[cell] + 1) % 4;

    final solved = TileSwapEngine.isSolved(current.arrangement) && rotations.every((r) => r == 0);
    if (!solved) {
      emit(current.copyWith(rotations: rotations, moves: current.moves + 1));
      return;
    }

    _onSolved(current, current.arrangement, rotations);
  }

  Future<void> _onSolved(DailyChallengeReady current, List<int> arrangement, List<int> rotations) async {
    _timer?.cancel();
    final completed = await _service.completeToday(DateTime.now());
    await _achievementEvents?.onDailyChallengeCompleted(completed.streak);
    
    // Base 100 + Streak Bonus + Speed Bonus (2 coins per remaining second)
    final speedBonus = current.timeRemainingSeconds * 2;
    final coins = coinsFor(completed.streak) + speedBonus;
    
    emit(
      current.copyWith(
        arrangement: arrangement,
        rotations: rotations,
        moves: current.moves + 1,
        justSolved: true,
        coinsEarned: coins,
        challenge: completed,
      ),
    );
  }

  /// Base reward plus a streak bonus, capped at a 10-day streak.
  static int coinsFor(int streak) => 100 + (streak.clamp(0, 10) * 10);
}
