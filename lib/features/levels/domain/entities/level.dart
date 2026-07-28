import 'package:equatable/equatable.dart';

enum LevelDifficulty { easy, medium, hard, expert }

/// A single puzzle level and the player's progress on it.
///
/// This is the domain-layer representation — plain Dart, no Hive
/// annotations — so features and UI never depend on the storage format.
class Level extends Equatable {
  const Level({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.stars,
    required this.isCompleted,
    required this.isUnlocked,
    this.bestTimeSeconds,
    this.bestMoves,
  });

  final int id;
  final String title;
  final LevelDifficulty difficulty;

  /// 0-3.
  final int stars;
  final bool isCompleted;
  final bool isUnlocked;
  final int? bestTimeSeconds;
  final int? bestMoves;

  Level copyWith({
    int? stars,
    bool? isCompleted,
    bool? isUnlocked,
    int? bestTimeSeconds,
    int? bestMoves,
  }) {
    return Level(
      id: id,
      title: title,
      difficulty: difficulty,
      stars: stars ?? this.stars,
      isCompleted: isCompleted ?? this.isCompleted,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
      bestMoves: bestMoves ?? this.bestMoves,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    difficulty,
    stars,
    isCompleted,
    isUnlocked,
    bestTimeSeconds,
    bestMoves,
  ];
}
