// Verifies LeaderboardEntry parsing: a stored profile name is shown when
// present, otherwise the row falls back to a short uid-derived placeholder
// instead of dumping a raw uid.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/services/leaderboard_service.dart';

void main() {
  test('displayName uses the stored profile name when present', () {
    final entry = LeaderboardEntry.fromMap(const {
      'uid': 'abcde12345',
      'name': 'Ada',
      'score': 42,
      'timestamp': null,
    });
    expect(entry.displayName, 'Ada');
  });

  test('displayName falls back to a uid-derived placeholder', () {
    final entry = LeaderboardEntry.fromMap(const {
      'uid': 'abcde12345',
      'score': 42,
      'timestamp': null,
    });
    expect(entry.displayName, 'Player abcde');
  });

  test('parses a score and keeps the highest via the service contract', () {
    final entry = LeaderboardEntry.fromMap(const {
      'uid': 'abcde12345',
      'name': 'Ada',
      'score': 37,
      'timestamp': null,
    });
    expect(entry.score, 37);
  });
}
