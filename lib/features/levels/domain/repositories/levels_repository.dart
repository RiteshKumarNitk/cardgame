import '../entities/level.dart';

/// Persistence boundary for level progress. Pure data access only — no
/// unlock/completion rules live here, see [LevelService] for those.
///
/// `loadLevels`/`saveLevels` double as "load progress"/"save progress":
/// a [Level]'s stars, completion, and unlock state *is* the player's
/// progress, there's no separate progress record to track yet.
abstract interface class LevelsRepository {
  Future<List<Level>> loadLevels();
  Future<void> saveLevels(List<Level> levels);
}
