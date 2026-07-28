import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// Root widget of the application.
///
/// Wires together theming and routing only — feature code must never be
/// referenced from here directly, it is reached through [appRouter].
class PuzzleCardsApp extends StatelessWidget {
  const PuzzleCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.game,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
