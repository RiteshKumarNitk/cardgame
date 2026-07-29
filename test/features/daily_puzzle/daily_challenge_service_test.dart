// Unit tests for DailyChallengeService's streak rules: first-ever
// completion, consecutive-day extension, a gap resetting the streak, and
// same-day idempotency. Pure Dart, backed by an in-memory fake repository.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/daily_puzzle/domain/repositories/daily_challenge_repository.dart';
import 'package:puzzle_cards/features/daily_puzzle/domain/services/daily_challenge_service.dart';

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

void main() {
  test('dateKeyFor formats as zero-padded yyyy-mm-dd', () {
    expect(
      DailyChallengeService.dateKeyFor(DateTime(2026, 1, 5)),
      '2026-01-05',
    );
  });

  group('loadToday', () {
    test('not completed when never played', () async {
      final service = DailyChallengeService(_FakeDailyChallengeRepository());

      final challenge = await service.loadToday(DateTime(2026, 7, 29));

      expect(challenge.alreadyCompletedToday, isFalse);
      expect(challenge.streak, 0);
    });

    test('reflects a completion earlier today', () async {
      final repository = _FakeDailyChallengeRepository()
        ..lastCompletedDate = '2026-07-29'
        ..streak = 4;

      final challenge = await DailyChallengeService(
        repository,
      ).loadToday(DateTime(2026, 7, 29));

      expect(challenge.alreadyCompletedToday, isTrue);
      expect(challenge.streak, 4);
    });
  });

  group('completeToday', () {
    test('first ever completion starts the streak at 1', () async {
      final service = DailyChallengeService(_FakeDailyChallengeRepository());

      final challenge = await service.completeToday(DateTime(2026, 7, 29));

      expect(challenge.streak, 1);
      expect(challenge.alreadyCompletedToday, isTrue);
    });

    test('completing the day right after the last one extends the streak', () async {
      final repository = _FakeDailyChallengeRepository()
        ..lastCompletedDate = '2026-07-28'
        ..streak = 4;

      final challenge = await DailyChallengeService(
        repository,
      ).completeToday(DateTime(2026, 7, 29));

      expect(challenge.streak, 5);
    });

    test('a gap of more than a day resets the streak to 1', () async {
      final repository = _FakeDailyChallengeRepository()
        ..lastCompletedDate = '2026-07-20'
        ..streak = 9;

      final challenge = await DailyChallengeService(
        repository,
      ).completeToday(DateTime(2026, 7, 29));

      expect(challenge.streak, 1);
    });

    test('completing again the same day is a no-op', () async {
      final repository = _FakeDailyChallengeRepository()
        ..lastCompletedDate = '2026-07-29'
        ..streak = 3;

      final challenge = await DailyChallengeService(
        repository,
      ).completeToday(DateTime(2026, 7, 29));

      expect(challenge.streak, 3);
      expect(
        repository.streak,
        3,
        reason: 'nothing new should have been persisted',
      );
    });
  });
}
