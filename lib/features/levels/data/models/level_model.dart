import 'package:hive/hive.dart';

import '../../domain/entities/level.dart';

part 'level_model.g.dart';

/// Hive-persisted form of [Level]. Kept separate from the domain entity so
/// a storage-format change never ripples into UI or bloc code.
@HiveType(typeId: 0)
class LevelModel extends HiveObject {
  LevelModel({
    required this.id,
    required this.title,
    required this.difficultyIndex,
    required this.stars,
    required this.isCompleted,
    required this.isUnlocked,
    this.bestTimeSeconds,
    this.bestMoves,
  });

  factory LevelModel.fromEntity(Level level) => LevelModel(
    id: level.id,
    title: level.title,
    difficultyIndex: level.difficulty.index,
    stars: level.stars,
    isCompleted: level.isCompleted,
    isUnlocked: level.isUnlocked,
    bestTimeSeconds: level.bestTimeSeconds,
    bestMoves: level.bestMoves,
  );

  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final int difficultyIndex;

  @HiveField(3)
  final int stars;

  @HiveField(4)
  final bool isCompleted;

  @HiveField(5)
  final bool isUnlocked;

  @HiveField(6)
  final int? bestTimeSeconds;

  @HiveField(7)
  final int? bestMoves;

  Level toEntity() => Level(
    id: id,
    title: title,
    difficulty: LevelDifficulty.values[difficultyIndex],
    stars: stars,
    isCompleted: isCompleted,
    isUnlocked: isUnlocked,
    bestTimeSeconds: bestTimeSeconds,
    bestMoves: bestMoves,
  );
}
