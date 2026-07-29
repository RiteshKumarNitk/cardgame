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

  Future<void> toggleHaptics() => _update(
    (settings) => settings.copyWith(hapticsEnabled: !settings.hapticsEnabled),
  );

  Future<void> _update(AppSettings Function(AppSettings) transform) async {
    final updated = transform(state);
    emit(updated);
    await _repository.save(updated);
  }
}
