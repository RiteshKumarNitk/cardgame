import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  const AppSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.masterVolume = 1.0,
    this.sfxVolume = 1.0,
    this.musicVolume = 1.0,
  });

  final bool soundEnabled;
  final bool musicEnabled;

  /// Master output volume, 0.0–1.0. Multiplies both channels.
  final double masterVolume;

  /// Sound-effects channel volume, 0.0–1.0.
  final double sfxVolume;

  /// Music channel volume, 0.0–1.0.
  final double musicVolume;

  AppSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    double? masterVolume,
    double? sfxVolume,
    double? musicVolume,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      masterVolume: masterVolume ?? this.masterVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      musicVolume: musicVolume ?? this.musicVolume,
    );
  }

  @override
  List<Object?> get props =>
      [soundEnabled, musicEnabled, masterVolume, sfxVolume, musicVolume];
}
