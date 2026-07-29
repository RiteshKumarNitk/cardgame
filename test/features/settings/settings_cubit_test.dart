// Unit tests for SettingsCubit: loads from the repository, and each
// toggle flips exactly its own field, emits, and persists.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/settings/domain/entities/app_settings.dart';
import 'package:puzzle_cards/features/settings/domain/repositories/settings_repository.dart';
import 'package:puzzle_cards/features/settings/presentation/bloc/settings_cubit.dart';

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings stored = const AppSettings();

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    stored = settings;
  }
}

void main() {
  test('defaults to sound/music/haptics all on before loading', () {
    final cubit = SettingsCubit(_FakeSettingsRepository());
    expect(cubit.state, const AppSettings());
  });

  test('load reflects the repository', () async {
    final repository = _FakeSettingsRepository()
      ..stored = const AppSettings(soundEnabled: false);
    final cubit = SettingsCubit(repository);

    await cubit.load();

    expect(cubit.state.soundEnabled, isFalse);
  });

  test('toggleSound flips only sound and persists', () async {
    final repository = _FakeSettingsRepository();
    final cubit = SettingsCubit(repository);
    await cubit.load();

    await cubit.toggleSound();

    expect(cubit.state.soundEnabled, isFalse);
    expect(cubit.state.musicEnabled, isTrue);
    expect(cubit.state.hapticsEnabled, isTrue);
    expect(repository.stored.soundEnabled, isFalse);
  });

  test('toggleMusic flips only music and persists', () async {
    final repository = _FakeSettingsRepository();
    final cubit = SettingsCubit(repository);
    await cubit.load();

    await cubit.toggleMusic();

    expect(cubit.state.musicEnabled, isFalse);
    expect(cubit.state.soundEnabled, isTrue);
    expect(repository.stored.musicEnabled, isFalse);
  });

  test('toggleHaptics flips only haptics and persists', () async {
    final repository = _FakeSettingsRepository();
    final cubit = SettingsCubit(repository);
    await cubit.load();

    await cubit.toggleHaptics();

    expect(cubit.state.hapticsEnabled, isFalse);
    expect(cubit.state.soundEnabled, isTrue);
    expect(repository.stored.hapticsEnabled, isFalse);
  });
}
