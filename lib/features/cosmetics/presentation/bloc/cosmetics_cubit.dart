import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/analytics_service.dart';
import '../../domain/entities/cosmetic_items.dart';
import '../../domain/entities/player_cosmetics.dart';
import '../../domain/repositories/cosmetics_repository.dart';
import '../../domain/services/cosmetics_catalog.dart';

/// The player's cosmetic loadout, live across the app. Handles the two
/// player actions: buying an item (spends coins through a caller-supplied
/// [spend] callback — same pattern as `DailyChallengeCubit.retry`) and
/// equipping an owned item. Buying an item also equips it, so a purchase
/// is immediately visible on the next puzzle.
class CosmeticsCubit extends Cubit<PlayerCosmetics> {
  CosmeticsCubit(this._repository) : super(PlayerCosmetics.defaults());

  final CosmeticsRepository _repository;

  Future<void> load() async {
    final loaded = await _repository.load();
    emit(
      loaded.normalized(
        validFrameIds: CosmeticsCatalog.frameIds,
        validPieceStyleIds: CosmeticsCatalog.pieceStyleIds,
        validAvatarIds: CosmeticsCatalog.avatarIds,
      ),
    );
  }

  /// Owned check against the live state.
  bool owns(CosmeticItem item) => state.owns(item);

  /// Tries to buy [item] by spending [item.price] coins through [spend].
  /// Returns whether the purchase succeeded; on success the item is also
  /// equipped. No-op (returns true) if the item is already owned.
  Future<bool> buy(
    CosmeticItem item,
    Future<bool> Function(int amount) spend,
  ) async {
    if (state.owns(item)) return true;

    final success = await spend(item.price);
    if (!success) return false;

    final updated = _applyPurchase(_applyEquip(state, item), item);
    emit(updated);
    await _repository.save(updated);

    AnalyticsService().logEvent(
      AnalyticsService.cosmeticPurchased,
      parameters: {
        'category': item.category,
        'item_id': item.id,
        'price': item.price,
      },
    );
    return true;
  }

  /// Equips an owned item. Unknown or unowned ids are ignored.
  Future<void> equip(CosmeticItem item) async {
    if (!state.owns(item)) return;

    final updated = _applyEquip(state, item);
    emit(updated);
    await _repository.save(updated);

    AnalyticsService().logEvent(
      AnalyticsService.cosmeticEquipped,
      parameters: {'category': item.category, 'item_id': item.id},
    );
  }

  PlayerCosmetics _applyEquip(PlayerCosmetics current, CosmeticItem item) {
    return switch (item) {
      BoardFrame f => current.copyWith(equippedFrame: f.id),
      PieceStyle p => current.copyWith(equippedPieceStyle: p.id),
      Avatar a => current.copyWith(equippedAvatar: a.id),
    };
  }

  PlayerCosmetics _applyPurchase(PlayerCosmetics current, CosmeticItem item) {
    return switch (item) {
      BoardFrame f => current.copyWith(
        ownedFrames: {...current.ownedFrames, f.id},
      ),
      PieceStyle p => current.copyWith(
        ownedPieceStyles: {...current.ownedPieceStyles, p.id},
      ),
      Avatar a => current.copyWith(
        ownedAvatars: {...current.ownedAvatars, a.id},
      ),
    };
  }
}
