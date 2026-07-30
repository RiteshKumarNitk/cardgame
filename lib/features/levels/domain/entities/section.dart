import 'package:equatable/equatable.dart';

/// A contiguous run of levels within a [Chapter] — e.g. "Section 2,
/// Levels 21-40".
class Section extends Equatable {
  const Section({
    required this.id,
    required this.chapterId,
    required this.index,
    required this.startLevelId,
    required this.endLevelId,
  });

  final int id;
  final int chapterId;

  /// 1-based position within the chapter ("Section 1", "Section 2", ...).
  final int index;
  final int startLevelId;
  final int endLevelId;

  int get levelCount => endLevelId - startLevelId + 1;

  bool containsLevel(int levelId) =>
      levelId >= startLevelId && levelId <= endLevelId;

  @override
  List<Object?> get props => [id, chapterId, index, startLevelId, endLevelId];
}
