// Unit tests for AppBootstrap's stage notifier and readiness future.
// (run() itself touches Firebase/ads/RevenueCat platform channels, so it
// is only exercised on device — the observable state machine is what's
// tested here.)

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/services/app_bootstrap.dart';

void main() {
  setUp(() {
    AppBootstrap().stage.value = BootstrapStage.preparing;
  });

  test('whenReady completes once the stage reaches ready', () async {
    final bootstrap = AppBootstrap();

    bootstrap.stage.value = BootstrapStage.loggingIn;
    final ready = bootstrap.whenReady();

    bootstrap.stage.value = BootstrapStage.syncing;
    bootstrap.stage.value = BootstrapStage.ready;

    await ready; // must complete, not hang
  });

  test('whenReady returns immediately when already ready', () async {
    final bootstrap = AppBootstrap();
    bootstrap.stage.value = BootstrapStage.ready;

    await bootstrap.whenReady();
  });

  test('starts unstarted at preparing', () {
    final bootstrap = AppBootstrap();
    expect(bootstrap.started, isFalse);
    expect(bootstrap.stage.value, BootstrapStage.preparing);
  });
}
