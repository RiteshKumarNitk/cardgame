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
  test('defaults to sound and music on before loading', () {
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

  test('setMasterVolume updates and persists the master channel', () async {
    final repository = _FakeSettingsRepository();
    final cubit = SettingsCubit(repository);
    await cubit.load();

    await cubit.setMasterVolume(0.6);

    expect(cubit.state.masterVolume, 0.6);
    expect(repository.stored.masterVolume, 0.6);
    expect(cubit.state.sfxVolume, 1.0);
    expect(cubit.state.musicVolume, 1.0);
  });

  test('volume setters can skip persistence during slider drags', () async {
    final repository = _FakeSettingsRepository();
    final cubit = SettingsCubit(repository);
    await cubit.load();

    await cubit.setSfxVolume(0.4, persist: false);
    await cubit.setMusicVolume(0.2, persist: false);

    expect(cubit.state.sfxVolume, 0.4);
    expect(cubit.state.musicVolume, 0.2);
    expect(repository.stored.sfxVolume, 1.0);
    expect(repository.stored.musicVolume, 1.0);

    await cubit.setSfxVolume(0.5);
    expect(repository.stored.sfxVolume, 0.5);
  });

  test('loaded volume settings are reflected in state', () async {
    final repository = _FakeSettingsRepository()
      ..stored = const AppSettings(masterVolume: 0.5, sfxVolume: 0.7);
    final cubit = SettingsCubit(repository);

    await cubit.load();

    expect(cubit.state.masterVolume, 0.5);
    expect(cubit.state.sfxVolume, 0.7);
    expect(cubit.state.musicVolume, 1.0);
  });
}
