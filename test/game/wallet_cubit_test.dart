// Unit tests for WalletCubit: starts at the service's balance, persists
// and emits on addCoins/spendCoins, ignores non-positive addCoins
// amounts, and refuses to spend more than the balance covers.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/game/wallet_cubit.dart';

import '../helpers/fake_wallet_service.dart';

void main() {
  test('starts at the underlying service balance', () {
    final cubit = WalletCubit(FakeWalletService(100));
    expect(cubit.state, 100);
  });

  test('addCoins persists and emits the new balance', () async {
    final service = FakeWalletService(10);
    final cubit = WalletCubit(service);

    await cubit.addCoins(25);

    expect(cubit.state, 35);
    expect(service.balance, 35);
  });

  test('ignores zero/negative amounts', () async {
    final cubit = WalletCubit(FakeWalletService(50));

    await cubit.addCoins(0);
    await cubit.addCoins(-10);

    expect(cubit.state, 50);
  });

  test('spendCoins deducts and emits the new balance on success', () async {
    final service = FakeWalletService(50);
    final cubit = WalletCubit(service);

    final success = await cubit.spendCoins(20);

    expect(success, isTrue);
    expect(cubit.state, 30);
    expect(service.balance, 30);
  });

  test('spendCoins fails and leaves the balance untouched when insufficient', () async {
    final cubit = WalletCubit(FakeWalletService(10));

    final success = await cubit.spendCoins(20);

    expect(success, isFalse);
    expect(cubit.state, 10);
  });
}
