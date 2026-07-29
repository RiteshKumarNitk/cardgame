import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../game/wallet_cubit.dart';
import '../../game/wallet_service.dart';
import '../constants/app_constants.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// Root widget of the application.
///
/// Wires together theming, routing, and the one piece of state that's
/// truly global rather than screen-scoped — the coin wallet — which is
/// why [WalletCubit] is provided here instead of within a route. Feature
/// screens themselves are never referenced directly; they're reached
/// through [appRouter].
class PuzzleCardsApp extends StatelessWidget {
  /// [walletCubit] defaults to the real Hive-backed wallet; tests can
  /// supply one built on an in-memory fake instead.
  const PuzzleCardsApp({super.key, WalletCubit? walletCubit})
    : _walletCubit = walletCubit;

  final WalletCubit? _walletCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WalletCubit>(
      create: (_) => _walletCubit ?? WalletCubit(HiveWalletService()),
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.game,
        themeMode: ThemeMode.light,
        routerConfig: appRouter,
      ),
    );
  }
}
