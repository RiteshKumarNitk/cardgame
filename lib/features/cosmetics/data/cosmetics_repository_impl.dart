import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/entities/player_cosmetics.dart';
import '../domain/repositories/cosmetics_repository.dart';

/// Hive-backed [CosmeticsRepository]. Only item *ids* are stored — the
/// catalogs resolve ids to visuals, so rebalancing prices or re-skinning
/// icons never requires a migration.
class HiveCosmeticsRepository implements CosmeticsRepository {
  Box get _box => Hive.box(AppConstants.cosmeticsBoxName);

  @override
  Future<PlayerCosmetics> load() async {
    return PlayerCosmetics(
      ownedFrames: _stringSet(AppConstants.cosmeticsOwnedFramesKey),
      ownedPieceStyles: _stringSet(AppConstants.cosmeticsOwnedPieceStylesKey),
      ownedAvatars: _stringSet(AppConstants.cosmeticsOwnedAvatarsKey),
      equippedFrame:
          _box.get(AppConstants.cosmeticsEquippedFrameKey) as String? ??
          PlayerCosmetics.defaultFrameId,
      equippedPieceStyle:
          _box.get(AppConstants.cosmeticsEquippedPieceStyleKey) as String? ??
          PlayerCosmetics.defaultPieceStyleId,
      equippedAvatar:
          _box.get(AppConstants.cosmeticsEquippedAvatarKey) as String? ??
          PlayerCosmetics.defaultAvatarId,
    );
  }

  Set<String> _stringSet(String key) {
    final raw = _box.get(key);
    if (raw is List) {
      return raw.whereType<String>().toSet();
    }
    return <String>{};
  }

  @override
  Future<void> save(PlayerCosmetics cosmetics) async {
    await _box.put(AppConstants.cosmeticsOwnedFramesKey, cosmetics.ownedFrames.toList());
    await _box.put(AppConstants.cosmeticsOwnedPieceStylesKey, cosmetics.ownedPieceStyles.toList());
    await _box.put(AppConstants.cosmeticsOwnedAvatarsKey, cosmetics.ownedAvatars.toList());
    await _box.put(AppConstants.cosmeticsEquippedFrameKey, cosmetics.equippedFrame);
    await _box.put(AppConstants.cosmeticsEquippedPieceStyleKey, cosmetics.equippedPieceStyle);
    await _box.put(AppConstants.cosmeticsEquippedAvatarKey, cosmetics.equippedAvatar);
  }
}
