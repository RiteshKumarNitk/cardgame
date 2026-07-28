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
    await _box.putAll({for (final level in levels) level.id: level});
  }
}
