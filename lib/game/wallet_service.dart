import 'package:hive/hive.dart';

import '../core/constants/app_constants.dart';

/// Persistence for the player's coin balance. An interface (rather than a
/// concrete Hive class used directly) so tests can supply an in-memory
/// fake instead of touching real storage.
abstract interface class WalletService {
  int get balance;
  Future<void> addCoins(int amount);

  /// Deducts [amount] if the balance covers it. Returns whether the
  /// spend succeeded.
  Future<bool> spendCoins(int amount);
}

class HiveWalletService implements WalletService {
  Box<int> get _box => Hive.box<int>(AppConstants.walletBoxName);

  @override
  int get balance => _box.get(AppConstants.walletCoinsKey) ?? 0;

  @override
  Future<void> addCoins(int amount) async {
    await _box.put(AppConstants.walletCoinsKey, balance + amount);
  }

  @override
  Future<bool> spendCoins(int amount) async {
    if (balance < amount) return false;
    await _box.put(AppConstants.walletCoinsKey, balance - amount);
    return true;
  }
}
