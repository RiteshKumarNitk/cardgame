import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app/puzzle_cards_app.dart';
import 'services/app_bootstrap.dart';
import 'services/audio_service.dart';
import 'services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await HiveService.init();

  // Load the audio manifest + asset index before the first screen so the
  // ambient-music scenes resolve to their tracks immediately.
  await AudioService().initialize();

  // Everything network-y (Firebase login, entitlement sync, ad init) runs
  // deferred while the splash is on screen — the loader shows real stage
  // progress instead of a fake fixed delay. Never blocks first frame.
  unawaited(AppBootstrap().run());

  runApp(const PuzzleCardsApp());
}
