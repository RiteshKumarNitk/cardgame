// Unit tests for CosmeticsCubit: defaults, load normalization, buying
// (spends coins, owns, equips, persists), buy failure on insufficient
// coins, equipping owned items, and ignoring unowned ones.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/cosmetics/domain/entities/player_cosmetics.dart';
import 'package:puzzle_cards/features/cosmetics/domain/services/cosmetics_catalog.dart';
import 'package:puzzle_cards/features/cosmetics/presentation/bloc/cosmetics_cubit.dart';

import '../../helpers/fake_cosmetics_repository.dart';

void main() {
  Future<bool> spendOk(int _) async => true;
  Future<bool> spendFail(int _) async => false;

  test('starts owning and equipping the defaults', () {
    final cubit = CosmeticsCubit(FakeCosmeticsRepository());

    final state = cubit.state;
    expect(state.ownedFrames, {PlayerCosmetics.defaultFrameId});
    expect(state.equippedFrame, PlayerCosmetics.defaultFrameId);
    expect(state.equippedPieceStyle, PlayerCosmetics.defaultPieceStyleId);
    expect(state.equippedAvatar, PlayerCosmetics.defaultAvatarId);
  });

  test('load() normalizes stale equipped ids back to defaults', () async {
    final repository = FakeCosmeticsRepository(
      PlayerCosmetics(
        ownedFrames: {'classic'},
        ownedPieceStyles: {'classic'},
        ownedAvatars: {'default'},
        equippedFrame: 'stale_frame',
        equippedPieceStyle: 'classic',
        equippedAvatar: 'default',
      ),
    );
    final cubit = CosmeticsCubit(repository);
    await cubit.load();

    expect(cubit.state.equippedFrame, 'classic');
    expect(cubit.state.equippedAvatar, 'default');
  });

  test('buy() spends coins, owns, equips, and persists the item', () async {
    final repository = FakeCosmeticsRepository();
    final cubit = CosmeticsCubit(repository);
    final golden = CosmeticsCatalog.frames.firstWhere((f) => f.id == 'golden');
    var spent = 0;

    final success = await cubit.buy(golden, (amount) async {
      spent = amount;
      return true;
    });

    expect(success, isTrue);
    expect(spent, golden.price);
    expect(cubit.state.ownsFrame('golden'), isTrue);
    expect(cubit.state.equippedFrame, 'golden');
    expect(repository.saved.ownsFrame('golden'), isTrue);
    expect(repository.saved.equippedFrame, 'golden');
  });

  test('buy() fails without spending or owning when coins are short', () async {
    final cubit = CosmeticsCubit(FakeCosmeticsRepository());
    final golden = CosmeticsCatalog.frames.firstWhere((f) => f.id == 'golden');

    final success = await cubit.buy(golden, spendFail);

    expect(success, isFalse);
    expect(cubit.state.ownsFrame('golden'), isFalse);
    expect(cubit.state.equippedFrame, 'classic');
  });

  test('buy() an already-owned item is a no-op that returns true', () async {
    final cubit = CosmeticsCubit(FakeCosmeticsRepository());
    final classic = CosmeticsCatalog.frames.first;

    final success = await cubit.buy(classic, spendOk);

    expect(success, isTrue);
    expect(cubit.state.equippedFrame, 'classic');
  });

  test('equip() switches an owned item and persists it', () async {
    final repository = FakeCosmeticsRepository();
    final cubit = CosmeticsCubit(repository);
    final paw = CosmeticsCatalog.avatars.firstWhere((a) => a.id == 'paw');
    await cubit.buy(paw, spendOk);

    // Buy auto-equips; switch back to default then re-equip the paw.
    await cubit.equip(CosmeticsCatalog.avatars.first);
    expect(cubit.state.equippedAvatar, 'default');

    await cubit.equip(paw);
    expect(cubit.state.equippedAvatar, 'paw');
    expect(repository.saved.equippedAvatar, 'paw');
  });

  test('equip() ignores unowned items', () async {
    final cubit = CosmeticsCubit(FakeCosmeticsRepository());
    final gem = CosmeticsCatalog.avatars.firstWhere((a) => a.id == 'gem');

    await cubit.equip(gem);

    expect(cubit.state.equippedAvatar, 'default');
  });

  test('purchases in different categories are independent', () async {
    final cubit = CosmeticsCubit(FakeCosmeticsRepository());
    final neon = CosmeticsCatalog.pieceStyles.firstWhere((p) => p.id == 'neon');

    await cubit.buy(neon, spendOk);

    expect(cubit.state.ownsPieceStyle('neon'), isTrue);
    expect(cubit.state.equippedPieceStyle, 'neon');
    // Frame loadout untouched by a piece-style purchase.
    expect(cubit.state.equippedFrame, 'classic');
  });
}
