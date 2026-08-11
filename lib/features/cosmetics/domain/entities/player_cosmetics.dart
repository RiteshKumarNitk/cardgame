import 'package:equatable/equatable.dart';

import 'cosmetic_items.dart';

/// The player's cosmetic loadout: which items of each category they own
/// and which single item per category is currently equipped.
///
/// Owned sets only store item *ids*; the catalogs resolve ids to visuals.
/// Defaults are always implicitly owned, so a fresh install (or a
/// corrupted save) can never leave the player with nothing equipped.
class PlayerCosmetics extends Equatable {
  const PlayerCosmetics({
    required this.ownedFrames,
    required this.ownedPieceStyles,
    required this.ownedAvatars,
    required this.equippedFrame,
    required this.equippedPieceStyle,
    required this.equippedAvatar,
  });

  factory PlayerCosmetics.defaults() => PlayerCosmetics(
    ownedFrames: {defaultFrameId},
    ownedPieceStyles: {defaultPieceStyleId},
    ownedAvatars: {defaultAvatarId},
    equippedFrame: defaultFrameId,
    equippedPieceStyle: defaultPieceStyleId,
    equippedAvatar: defaultAvatarId,
  );

  /// The free starting item ids — kept here (not in the catalog) so the
  /// catalog can reference them as its defaults without a circular
  /// import.
  static const String defaultFrameId = 'classic';
  static const String defaultPieceStyleId = 'classic';
  static const String defaultAvatarId = 'default';

  final Set<String> ownedFrames;
  final Set<String> ownedPieceStyles;
  final Set<String> ownedAvatars;

  final String equippedFrame;
  final String equippedPieceStyle;
  final String equippedAvatar;

  bool ownsFrame(String id) => ownedFrames.contains(id);
  bool ownsPieceStyle(String id) => ownedPieceStyles.contains(id);
  bool ownsAvatar(String id) => ownedAvatars.contains(id);

  /// True if [item] is owned. Safe to call for any item in the catalogs.
  bool owns(CosmeticItem item) => switch (item) {
    BoardFrame f => ownsFrame(f.id),
    PieceStyle p => ownsPieceStyle(p.id),
    Avatar a => ownsAvatar(a.id),
  };

  bool isEquipped(CosmeticItem item) => switch (item) {
    BoardFrame f => equippedFrame == f.id,
    PieceStyle p => equippedPieceStyle == p.id,
    Avatar a => equippedAvatar == a.id,
  };

  PlayerCosmetics copyWith({
    Set<String>? ownedFrames,
    Set<String>? ownedPieceStyles,
    Set<String>? ownedAvatars,
    String? equippedFrame,
    String? equippedPieceStyle,
    String? equippedAvatar,
  }) {
    return PlayerCosmetics(
      ownedFrames: ownedFrames ?? this.ownedFrames,
      ownedPieceStyles: ownedPieceStyles ?? this.ownedPieceStyles,
      ownedAvatars: ownedAvatars ?? this.ownedAvatars,
      equippedFrame: equippedFrame ?? this.equippedFrame,
      equippedPieceStyle: equippedPieceStyle ?? this.equippedPieceStyle,
      equippedAvatar: equippedAvatar ?? this.equippedAvatar,
    );
  }

  /// Guards against stale/corrupt storage: guarantees the defaults are
  /// owned and every equipped slot points at an owned, valid item —
  /// falling back to the default when it doesn't.
  PlayerCosmetics normalized({
    required Set<String> validFrameIds,
    required Set<String> validPieceStyleIds,
    required Set<String> validAvatarIds,
  }) {
    final ownedF = {...ownedFrames, defaultFrameId}
        .intersection(validFrameIds);
    final ownedP = {...ownedPieceStyles, defaultPieceStyleId}
        .intersection(validPieceStyleIds);
    final ownedA = {...ownedAvatars, defaultAvatarId}
        .intersection(validAvatarIds);

    return PlayerCosmetics(
      ownedFrames: ownedF,
      ownedPieceStyles: ownedP,
      ownedAvatars: ownedA,
      equippedFrame: ownedF.contains(equippedFrame)
          ? equippedFrame
          : defaultFrameId,
      equippedPieceStyle: ownedP.contains(equippedPieceStyle)
          ? equippedPieceStyle
          : defaultPieceStyleId,
      equippedAvatar: ownedA.contains(equippedAvatar)
          ? equippedAvatar
          : defaultAvatarId,
    );
  }

  @override
  List<Object?> get props => [
    ownedFrames,
    ownedPieceStyles,
    ownedAvatars,
    equippedFrame,
    equippedPieceStyle,
    equippedAvatar,
  ];
}
