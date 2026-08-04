import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/achievement.dart';

/// The achievements screen's state: either still loading persisted
/// counters or the full live list of achievement progress.
sealed class AchievementsState extends Equatable {
  const AchievementsState();

  @override
  List<Object?> get props => [];
}

final class AchievementsLoading extends AchievementsState {
  const AchievementsLoading();
}

final class AchievementsLoaded extends AchievementsState {
  const AchievementsLoaded({required this.items, this.justUnlocked = const []});

  /// Every catalog achievement with live progress, in catalog order.
  final List<AchievementProgress> items;

  /// Achievements that crossed their goal in the most recent event — empty
  /// on initial load. Transient: consumers credit rewards and it is not
  /// carried into later states.
  final List<Achievement> justUnlocked;

  @override
  List<Object?> get props => [items, justUnlocked];
}

/// Resolves an achievement's icon key to a Material icon — kept here (not
/// in the domain entity) because icons are a presentation concern.
IconData achievementIcon(String iconKey) => switch (iconKey) {
  'puzzle' => Icons.extension_rounded,
  'scoreboard' => Icons.scoreboard_rounded,
  'trophy' => Icons.emoji_events_rounded,
  'star' => Icons.star_rounded,
  'star_ring' => Icons.stars_rounded,
  'diamond' => Icons.diamond_rounded,
  'bolt' => Icons.bolt_rounded,
  'flame' => Icons.local_fire_department_rounded,
  'shield' => Icons.shield_rounded,
  _ => Icons.emoji_events_rounded,
};