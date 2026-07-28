import 'package:flutter/material.dart';

import 'app_gradients.dart';
import 'app_shadows.dart';

/// Design tokens that don't fit [ColorScheme]/[TextTheme] — gradients and
/// shadow presets — exposed via `Theme.of(context).extension<...>()` so
/// widgets pull them from the theme rather than importing the static
/// token classes directly.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.primaryButtonGradient,
    required this.secondaryButtonGradient,
    required this.premiumButtonGradient,
    required this.screenBackgroundGradient,
    required this.cardShadow,
    required this.buttonShadow,
    required this.floatingShadow,
  });

  static const AppThemeExtension standard = AppThemeExtension(
    primaryButtonGradient: AppGradients.primaryButton,
    secondaryButtonGradient: AppGradients.secondaryButton,
    premiumButtonGradient: AppGradients.premiumButton,
    screenBackgroundGradient: AppGradients.screenBackground,
    cardShadow: AppShadows.card,
    buttonShadow: AppShadows.button,
    floatingShadow: AppShadows.floating,
  );

  final Gradient primaryButtonGradient;
  final Gradient secondaryButtonGradient;
  final Gradient premiumButtonGradient;
  final Gradient screenBackgroundGradient;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> buttonShadow;
  final List<BoxShadow> floatingShadow;

  @override
  AppThemeExtension copyWith({
    Gradient? primaryButtonGradient,
    Gradient? secondaryButtonGradient,
    Gradient? premiumButtonGradient,
    Gradient? screenBackgroundGradient,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? buttonShadow,
    List<BoxShadow>? floatingShadow,
  }) {
    return AppThemeExtension(
      primaryButtonGradient: primaryButtonGradient ?? this.primaryButtonGradient,
      secondaryButtonGradient:
          secondaryButtonGradient ?? this.secondaryButtonGradient,
      premiumButtonGradient: premiumButtonGradient ?? this.premiumButtonGradient,
      screenBackgroundGradient:
          screenBackgroundGradient ?? this.screenBackgroundGradient,
      cardShadow: cardShadow ?? this.cardShadow,
      buttonShadow: buttonShadow ?? this.buttonShadow,
      floatingShadow: floatingShadow ?? this.floatingShadow,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    // These are fixed brand tokens, not animated between themes.
    return other is AppThemeExtension ? other : this;
  }
}
