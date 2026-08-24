import 'package:equatable/equatable.dart';

import 'level_config.dart';

/// A contiguous run of exactly 20 levels within a [Chapter].
///
/// Each section has a consistent 20-level progression arc defined by
/// [SectionProgressRole]. The section's theme and mechanics determine
/// *what* the player learns, while the role determines *when* and
/// *how* it's introduced.
class Section extends Equatable {
  const Section({
    required this.id,
    required this.chapterId,
    required this.index,
    required this.startLevelId,
    required this.endLevelId,
    required this.progressRole,
  });

  final int id;
  final int chapterId;

  /// 1-based position within the chapter ("Section 1", "Section 2", ...).
  final int index;
  final int startLevelId;
  final int endLevelId;

  /// The progression role of this level within its section's 20-level arc.
  /// Determines difficulty ramp, mechanic introduction, and challenge pacing.
  final SectionProgressRole progressRole;

  int get levelCount => endLevelId - startLevelId + 1;

  bool containsLevel(int levelId) =>
      levelId >= startLevelId && levelId <= endLevelId;

  @override
  List<Object?> get props => [
    id,
    chapterId,
    index,
    startLevelId,
    endLevelId,
    progressRole,
  ];
}
