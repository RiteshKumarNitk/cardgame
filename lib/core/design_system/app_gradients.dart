import 'package:flutter/material.dart';

/// Named gradients — kept in one place so "what does a primary button look
/// like" only has one answer anywhere in the app.
///
/// The SuitClash "Warm Tactile Serenity" system is near-flat: buttons are
/// solid fills with a tactile bottom cushion ([AppShadows.tactile]), not
/// vivid gradients. These presets are therefore two very close stops (a
/// whisper of dimensional shading), kept as `Gradient`s so the
/// [AppThemeExtension] wiring and existing call sites don't change.
abstract final class AppGradients {
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4A7C59), Color(0xFF3F6E4D)],
  );

  static const LinearGradient secondaryButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF3EFE6)],
  );

  static const LinearGradient premiumButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDBA45), Color(0xFFEBA62E)],
  );

  /// The soft, warm backdrop behind every top-level screen — near-flat
  /// warm ivory so artwork and puzzle photos remain the visual focus.
  static const LinearGradient screenBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFCF9F2),
      Color(0xFFF8F5EC),
      Color(0xFFF3EFE6),
    ],
  );
}
