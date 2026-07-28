import 'package:equatable/equatable.dart';

import '../../../../game/game_progress_manager.dart';
import '../../domain/entities/level.dart';

sealed class LevelsState extends Equatable {
  const LevelsState();

  @override
  List<Object?> get props => [];
}

final class LevelsInitial extends LevelsState {
  const LevelsInitial();
}

final class LevelsLoading extends LevelsState {
  const LevelsLoading();
}

final class LevelsLoaded extends LevelsState {
  const LevelsLoaded(this.levels);

  final List<Level> levels;

  GameProgress get progress => GameProgressManager.computeFrom(levels);

  @override
  List<Object?> get props => [levels];
}

final class LevelsError extends LevelsState {
  const LevelsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
