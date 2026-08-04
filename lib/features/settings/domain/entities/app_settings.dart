import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  const AppSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
  });

  final bool soundEnabled;
  final bool musicEnabled;

  AppSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
    );
  }

  @override
  List<Object?> get props => [soundEnabled, musicEnabled];
}
