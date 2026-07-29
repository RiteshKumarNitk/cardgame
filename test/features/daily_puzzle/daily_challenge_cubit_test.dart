// Unit tests for DailyChallengeCubit: solving the (medium, 4 cols x 5
// rows = 20 piece) board marks it justSolved, computes the streak-scaled
// coin reward, and persists through DailyChallengeService.

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

/// Solves the board by walking its permutation cycles (see the matching
/// helper in puzzle_cubit_test.dart for why this always converges).
Future<void> _solve(DailyChallengeCubit cubit) async {
  while (true) {
    final state = cubit.state as DailyChallengeReady;
    if (state.isComplete) return;

    var wrongCell = -1;
    for (var i = 0; i < state.arrangement.length; i++) {
      if (state.arrangement[i] != i + 1) {
        wrongCell = i;
        break;
      }
    }
    final targetCell = state.arrangement[wrongCell] - 1;
    await cubit.swapPieces(wrongCell, targetCell);
  }
}

void main() {
  test('coinsFor scales with streak, capped at a 10-day bonus', () {
    expect(DailyChallengeCubit.coinsFor(0), 100);
    expect(DailyChallengeCubit.coinsFor(1), 110);
    expect(DailyChallengeCubit.coinsFor(10), 200);
    expect(DailyChallengeCubit.coinsFor(50), 200, reason: 'bonus caps at 10 days');
  });

  test('load shuffles a 4x5 (20-piece) board, unsolved', () async {
    final cubit = DailyChallengeCubit(
      DailyChallengeService(_FakeDailyChallengeRepository()),
    );

    await cubit.load();

    final state = cubit.state as DailyChallengeReady;
    expect(state.arrangement.toSet(), List.generate(20, (i) => i + 1).toSet());
    expect(state.isComplete, isFalse);
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

  test('swapping a locked cell does not count a move', () async {
    final cubit = DailyChallengeCubit(
      DailyChallengeService(_FakeDailyChallengeRepository()),
    );
    await cubit.load();

    var state = cubit.state as DailyChallengeReady;
    final pieceOneCell = state.arrangement.indexOf(1);
    if (pieceOneCell != 0) {
      await cubit.swapPieces(0, pieceOneCell);
    }
    state = cubit.state as DailyChallengeReady;
    final movesSoFar = state.moves;

    await cubit.swapPieces(0, 1);

    state = cubit.state as DailyChallengeReady;
    expect(state.moves, movesSoFar);
  });
}
