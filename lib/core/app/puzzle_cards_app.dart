import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../game/ads_cubit.dart';
import '../../game/ads_service.dart';
import '../../game/wallet_cubit.dart';
import '../../game/wallet_service.dart';
import '../constants/app_constants.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// Root widget of the application.
///
/// Wires together theming, routing, and the two pieces of state that are
/// truly global rather than screen-scoped — the coin wallet and the
/// "ads removed" entitlement — which is why [WalletCubit]/[AdsCubit] are
/// provided here instead of within a route. Feature screens themselves
/// are never referenced directly; they're reached through [appRouter].
class PuzzleCardsApp extends StatelessWidget {
  /// [walletCubit]/[adsCubit] default to the real Hive-backed services;
  /// tests can supply ones built on in-memory fakes instead.
  const PuzzleCardsApp({super.key, WalletCubit? walletCubit, AdsCubit? adsCubit})
    : _walletCubit = walletCubit,
      _adsCubit = adsCubit;

  final WalletCubit? _walletCubit;
  final AdsCubit? _adsCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WalletCubit>(
          create: (_) => _walletCubit ?? WalletCubit(HiveWalletService()),
        ),
        BlocProvider<AdsCubit>(
          create: (_) => _adsCubit ?? AdsCubit(HiveAdsService()),
        ),
      ],
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
