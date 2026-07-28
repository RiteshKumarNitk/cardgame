import '../../domain/entities/level.dart';
import '../../domain/repositories/levels_repository.dart';
import '../datasources/levels_local_datasource.dart';
import '../models/level_model.dart';

class LevelsRepositoryImpl implements LevelsRepository {
  LevelsRepositoryImpl(this._dataSource);

  final LevelsLocalDataSource _dataSource;

  @override
  Future<List<Level>> loadLevels() async {
    final models = await _dataSource.loadLevels();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> saveLevels(List<Level> levels) async {
    await _dataSource.saveLevels(levels.map(LevelModel.fromEntity).toList());
  }
}
