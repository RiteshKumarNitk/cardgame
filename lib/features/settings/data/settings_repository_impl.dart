import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/entities/app_settings.dart';
import '../domain/repositories/settings_repository.dart';

class HiveSettingsRepository implements SettingsRepository {
  Box get _box => Hive.box(AppConstants.settingsBoxName);

  @override
  Future<AppSettings> load() async => AppSettings(
    soundEnabled:
        (_box.get(AppConstants.soundEnabledKey) as bool?) ?? true,
    musicEnabled:
        (_box.get(AppConstants.musicEnabledKey) as bool?) ?? true,
  );

  @override
  Future<void> save(AppSettings settings) async {
    await _box.put(AppConstants.soundEnabledKey, settings.soundEnabled);
    await _box.put(AppConstants.musicEnabledKey, settings.musicEnabled);
  }
}
