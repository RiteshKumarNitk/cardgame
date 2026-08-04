import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';
import '../features/levels/data/models/level_model.dart';

/// Bootstraps local storage: brings Hive up, registers feature adapters,
/// and opens the boxes the app depends on at startup.
abstract final class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(LevelModelAdapter());
    await Hive.openBox<LevelModel>(AppConstants.levelsBoxName);
    await Hive.openBox<int>(AppConstants.walletBoxName);
    await Hive.openBox(AppConstants.dailyChallengeBoxName);
    await Hive.openBox(AppConstants.monetizationBoxName);
    await Hive.openBox(AppConstants.settingsBoxName);
    await Hive.openBox(AppConstants.achievementsBoxName);
  }
}
