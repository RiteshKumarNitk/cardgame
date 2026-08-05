import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/cloud_save_service.dart';
import 'wallet_service.dart';

/// The player's coin balance, live across the whole app. State is just
/// the current balance (an int) — there's nothing richer to model yet.
class WalletCubit extends Cubit<int> {
  WalletCubit(this._service) : super(_service.balance);

  final WalletService _service;

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    await _service.addCoins(amount);
    emit(_service.balance);
    CloudSaveService().backupWallet(_service.balance);
  }

  /// Attempts to spend [amount] coins. Returns whether it succeeded —
  /// callers use this to gate coin-locked content without needing to
  /// inspect state themselves.
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    final success = await _service.spendCoins(amount);
    if (success) {
      emit(_service.balance);
      CloudSaveService().backupWallet(_service.balance);
    }
    return success;
  }
}
