import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._repository) : super(const AppSettings());

  final SettingsRepository _repository;

  Future<void> load() async {
    emit(await _repository.load());
  }

  Future<void> toggleSound() => _update(
    (settings) => settings.copyWith(soundEnabled: !settings.soundEnabled),
  );

  Future<void> toggleMusic() => _update(
    (settings) => settings.copyWith(musicEnabled: !settings.musicEnabled),
  );

  /// [persist] is false while a slider is being dragged and true when the
  /// drag ends, so we don't hammer Hive with every thumb movement.
  Future<void> setMasterVolume(double volume, {bool persist = true}) =>
      _update(
        (settings) => settings.copyWith(masterVolume: volume),
        persist: persist,
      );

  Future<void> setSfxVolume(double volume, {bool persist = true}) =>
      _update(
        (settings) => settings.copyWith(sfxVolume: volume),
        persist: persist,
      );

  Future<void> setMusicVolume(double volume, {bool persist = true}) =>
      _update(
        (settings) => settings.copyWith(musicVolume: volume),
        persist: persist,
      );

  Future<void> _update(
    AppSettings Function(AppSettings) transform, {
    bool persist = true,
  }) async {
    final updated = transform(state);
    emit(updated);
    if (persist) {
      await _repository.save(updated);
    }
  }
}
