import 'package:puzzle_cards/game/wallet_service.dart';

/// In-memory [WalletService] fake shared by tests that render a top bar
/// showing the coin balance — avoids touching real Hive.
class FakeWalletService implements WalletService {
  FakeWalletService([this._balance = 0]);

  int _balance;

  @override
  int get balance => _balance;

  @override
  Future<void> addCoins(int amount) async {
    _balance += amount;
  }
}
