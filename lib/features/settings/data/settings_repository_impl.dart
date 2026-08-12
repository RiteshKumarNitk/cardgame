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
    masterVolume:
        (_box.get(AppConstants.masterVolumeKey) as num?)?.toDouble() ?? 1.0,
    sfxVolume:
        (_box.get(AppConstants.sfxVolumeKey) as num?)?.toDouble() ?? 1.0,
    musicVolume:
        (_box.get(AppConstants.musicVolumeKey) as num?)?.toDouble() ?? 1.0,
  );

  @override
  Future<void> save(AppSettings settings) async {
    await _box.put(AppConstants.soundEnabledKey, settings.soundEnabled);
    await _box.put(AppConstants.musicEnabledKey, settings.musicEnabled);
    await _box.put(AppConstants.masterVolumeKey, settings.masterVolume);
    await _box.put(AppConstants.sfxVolumeKey, settings.sfxVolume);
    await _box.put(AppConstants.musicVolumeKey, settings.musicVolume);
  }
}
