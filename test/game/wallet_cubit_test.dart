// Unit tests for WalletCubit: starts at the service's balance, persists
// and emits on addCoins, and ignores non-positive amounts.

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
}
