// OnboardingService flag behavior: shows exactly once, then stays hidden.
// Uses a temp Hive dir (the real app uses the same settings box).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:puzzle_cards/core/constants/app_constants.dart';
import 'package:puzzle_cards/game/onboarding_service.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() {
    hiveDir = Directory.systemTemp.createTempSync('hive_onboarding_');
    Hive.init(hiveDir.path);
  });

  setUp(() async {
    await Hive.openBox(AppConstants.settingsBoxName);
  });

  tearDownAll(() {
    // Best-effort cleanup — closing Hive can hang on Windows, and the
    // OS temp cleaner will eventually remove any leftover directories.
    try {
      hiveDir.deleteSync(recursive: true);
    } on FileSystemException {
      // File still locked by Hive — harmless.
    }
  });

  test('shows tutorial until marked seen, then never again', () async {
    final service = OnboardingService();
    // Fresh install: never seen → should show.
    expect(service.shouldShowTutorial(), isTrue);

    await service.markTutorialSeen();

    expect(service.shouldShowTutorial(), isFalse);
  });
}
