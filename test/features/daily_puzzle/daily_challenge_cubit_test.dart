// Unit tests for DailyChallengeCubit: solving the (medium, 4x4 = 16
// piece) board marks it justSolved, computes the streak-scaled coin
// reward, and persists through DailyChallengeService.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/daily_puzzle/domain/repositories/daily_challenge_repository.dart';
import 'package:puzzle_cards/features/daily_puzzle/domain/services/daily_challenge_service.dart';
import 'package:puzzle_cards/features/daily_puzzle/presentation/bloc/daily_challenge_cubit.dart';
import 'package:puzzle_cards/features/daily_puzzle/presentation/bloc/daily_challenge_state.dart';

class _FakeDailyChallengeRepository implements DailyChallengeRepository {
  String? lastCompletedDate;
  int streak = 0;

  @override
  Future<String?> loadLastCompletedDate() async => lastCompletedDate;

  @override
  Future<int> loadStreak() async => streak;

  @override
  Future<void> save({
    required String lastCompletedDate,
    required int streak,
  }) async {
    this.lastCompletedDate = lastCompletedDate;
    this.streak = streak;
  }
}

Future<void> _solve(DailyChallengeCubit cubit) async {
  for (var piece = 1; piece <= 16; piece++) {
    await cubit.attemptPlacePiece(piece, piece - 1);
  }
}

void main() {
  test('coinsFor scales with streak, capped at a 10-day bonus', () {
    expect(DailyChallengeCubit.coinsFor(0), 100);
    expect(DailyChallengeCubit.coinsFor(1), 110);
    expect(DailyChallengeCubit.coinsFor(10), 200);
    expect(DailyChallengeCubit.coinsFor(50), 200, reason: 'bonus caps at 10 days');
  });

  test('solving marks justSolved, awards coins, and persists the streak', () async {
    final repository = _FakeDailyChallengeRepository();
    final cubit = DailyChallengeCubit(DailyChallengeService(repository));
    await cubit.load();

    await _solve(cubit);

    final state = cubit.state as DailyChallengeReady;
    expect(state.justSolved, isTrue);
    expect(state.isComplete, isTrue);
    expect(state.challenge.streak, 1);
    expect(state.coinsEarned, 110);
    expect(repository.streak, 1, reason: 'should be persisted, not just in memory');
  });

  test('a wrong drop does not place the piece', () async {
    final cubit = DailyChallengeCubit(
      DailyChallengeService(_FakeDailyChallengeRepository()),
    );
    await cubit.load();

    final correct = await cubit.attemptPlacePiece(1, 5);

    expect(correct, isFalse);
    final state = cubit.state as DailyChallengeReady;
    expect(state.placedPieceIds, isEmpty);
    expect(state.wrongAttempts, 1);
  });
}
