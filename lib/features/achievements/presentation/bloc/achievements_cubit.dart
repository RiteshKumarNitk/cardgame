import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/achievements_repository.dart';
import '../../domain/services/achievement_catalog.dart';
import '../../domain/services/achievement_events.dart';
import 'achievements_state.dart';
/// Owns the achievements feature end to end: applies gameplay events to
/// the persisted counters, unlocks every achievement that crossed its
/// goal, and emits the live list. Implements [AchievementEvents] so
/// gameplay cubits only ever depend on the domain-neutral interface.
class AchievementsCubit extends Cubit<AchievementsState>
    implements AchievementEvents {
  AchievementsCubit(this._repository) : super(const AchievementsLoading());

  final AchievementsRepository _repository;

  /// Loads persisted state and emits the first real snapshot.
  Future<void> load() => _refresh();

  @override
  Future<void> onPuzzleCompleted({
    required int stars,
    required int timeSeconds,
  }) async {
    final counters = await _repository.loadCounters();
    counters[AchievementCatalog.counterPuzzles] =
        (counters[AchievementCatalog.counterPuzzles] ?? 0) + 1;
    counters[AchievementCatalog.counterStars] =
        (counters[AchievementCatalog.counterStars] ?? 0) + stars;
    if (stars >= 3) counters[AchievementCatalog.flagPerfect] = 1;
    if (timeSeconds < 60) counters[AchievementCatalog.flagSpeedDemon] = 1;
    await _applyAndEmit(counters);
  }

  @override
  Future<void> onDailyChallengeCompleted(int streak) async {
    final counters = await _repository.loadCounters();
    counters[AchievementCatalog.counterBestStreak] = math.max(
      counters[AchievementCatalog.counterBestStreak] ?? 0,
      streak,
    );
    await _applyAndEmit(counters);
  }

  /// Persists counters, unlocks anything newly met, and broadcasts the
  /// updated list (with the newly-unlocked set so the app can pay out the
  /// coin rewards exactly once).
  Future<void> _applyAndEmit(Map<String, int> counters) async {
    await _repository.saveCounters(counters);

    final unlocked = await _repository.loadUnlockedIds();
    final progress = AchievementCatalog.progressFor(counters);
    final justUnlocked = [
      for (final p in progress)
        if (p.isUnlocked && !unlocked.contains(p.achievement.id))
          p.achievement,
    ];
    if (justUnlocked.isNotEmpty) {
      await _repository.saveUnlockedIds({
        ...unlocked,
        for (final a in justUnlocked) a.id,
      });
    }

    if (isClosed) return;
    emit(AchievementsLoaded(items: progress, justUnlocked: justUnlocked));
  }

  Future<void> _refresh() async {
    final counters = await _repository.loadCounters();
    if (isClosed) return;
    emit(AchievementsLoaded(items: AchievementCatalog.progressFor(counters)));
  }
}