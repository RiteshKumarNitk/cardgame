// AnalyticsService must be a safe no-op in any environment where Firebase
// was never bootstrapped (widget tests, web) — nothing may throw, and no
// platform channels may be hit.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/services/analytics_service.dart';

void main() {
  test('logEvent is a no-op without Firebase', () async {
    await AnalyticsService().logEvent(
      AnalyticsService.levelComplete,
      parameters: {'level_id': 1},
    );
  });

  test('recordError is a no-op without Firebase', () async {
    await AnalyticsService().recordError(
      StateError('boom'),
      StackTrace.current,
    );
  });

  test('enableCrashReporting is a no-op without Firebase', () {
    AnalyticsService().enableCrashReporting();
  });

  test('setUserId is a no-op without Firebase', () async {
    await AnalyticsService().setUserId('test-user');
  });
}
