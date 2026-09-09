import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/level_model.dart';

/// Local (Hive) persistence for level progress.
abstract interface class LevelsLocalDataSource {
  Future<List<LevelModel>> loadLevels();
  Future<void> saveLevels(List<LevelModel> levels);
}

class HiveLevelsLocalDataSource implements LevelsLocalDataSource {
  Box<LevelModel> get _box => Hive.box<LevelModel>(AppConstants.levelsBoxName);

  @override
  Future<List<LevelModel>> loadLevels() async {
    final levels = _box.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    return levels;
  }

  @override
  Future<void> saveLevels(List<LevelModel> levels) async {
    // Authoritative write: [levels] is always the COMPLETE catalog, so
    // any key not in it is stale (e.g. left over from a previously larger
    // ChapterCatalog). Merging with putAll alone would leave those stale
    // entries in the box forever, making `_box.values.length` permanently
    // disagree with `ChapterCatalog.totalLevelCount` — which drives
    // `LevelService.loadLevels()` to reseed on every load and wipe
    // progress. Delete the stale keys, then write.
    final keep = {for (final level in levels) level.id};
    final stale = _box.keys.cast<int>().where((k) => !keep.contains(k)).toList();
    if (stale.isNotEmpty) await _box.deleteAll(stale);
    await _box.putAll({for (final level in levels) level.id: level});
  }
}
