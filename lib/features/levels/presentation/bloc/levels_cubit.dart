import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/level_service.dart';
import 'levels_state.dart';

/// Loads and mutates level progress for the Level Selection screen, backed
/// by [LevelService] (unlock/complete/reset rules) and, beneath that, a
/// Hive-persisted [LevelsRepository].
class LevelsCubit extends Cubit<LevelsState> {
  LevelsCubit(this._service) : super(const LevelsInitial());

  final LevelService _service;

  Future<void> loadLevels() async {
    emit(const LevelsLoading());
    try {
      final levels = await _service.loadLevels();
      emit(LevelsLoaded(levels));
    } catch (e) {
      emit(LevelsError(e.toString()));
    }
  }

  Future<void> completeLevel(
    int levelId, {
    required int stars,
    int? timeSeconds,
    int? moves,
  }) async {
    final current = state;
    if (current is! LevelsLoaded) return;
    try {
      final updated = await _service.completeLevel(
        current.levels,
        levelId,
        stars: stars,
        timeSeconds: timeSeconds,
        moves: moves,
      );
      emit(LevelsLoaded(updated));
    } catch (e) {
      emit(LevelsError(e.toString()));
    }
  }

  Future<void> resetProgress() async {
    emit(const LevelsLoading());
    try {
      final levels = await _service.resetProgress();
      emit(LevelsLoaded(levels));
    } catch (e) {
      emit(LevelsError(e.toString()));
    }
  }
}
