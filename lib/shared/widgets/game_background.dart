import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_theme_extension.dart';
import '../../game/floating_pieces_game.dart';
import 'floating_suit.dart';

/// The app's single background treatment: premium casino felt gradient,
/// a few glowing blurred circles, optionally the Flame floating-pieces layer,
/// and optionally drifting decorative card suits.
class GameBackground extends StatelessWidget {
  const GameBackground({
    super.key,
    this.child,
    this.showFloatingPieces = true,
    this.showClouds = false, // We'll map this to showing suits for now
  });

  final Widget? child;
  final bool showFloatingPieces;

  /// Renders several slowly drifting semi-transparent card suits behind the
  /// content for a premium casino atmosphere.
  final bool showClouds;

  /// Pre-defined suit configurations with varied positions, sizes,
  /// opacities, and drift speeds for a layered parallax-like effect.
  static const List<_SuitConfig> _suitConfigs = [
    _SuitConfig(key: 'suit_1', suit: '♠', size: 180, x: -40, y: 38, drift: 50, seconds: 45, opacity: 0.04),
    _SuitConfig(key: 'suit_2', suit: '♥', size: 140, x: 180, y: 95, drift: 40, seconds: 35, opacity: 0.05),
    _SuitConfig(key: 'suit_3', suit: '♦', size: 110, x: -20, y: 240, drift: 35, seconds: 25, opacity: 0.04),
    _SuitConfig(key: 'suit_4', suit: '♣', size: 170, x: 230, y: 370, drift: 45, seconds: 40, opacity: 0.03),
    _SuitConfig(key: 'suit_5', suit: '♠', size: 130, x: 95, y: 525, drift: 30, seconds: 30, opacity: 0.04),
  ];

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: ext.screenBackgroundGradient),
        ),
        const Positioned(
          top: -70,
          left: -50,
          child: _GlowCircle(size: 220, color: AppColors.success),
        ),
        const Positioned(
          bottom: -90,
          right: -70,
          child: _GlowCircle(size: 260, color: AppColors.primary),
        ),
        const Positioned(
          top: 180,
          right: -60,
          child: _GlowCircle(size: 160, color: AppColors.secondary),
        ),
        // Decorative drifting card suits.
        if (showClouds)
          for (final cfg in _suitConfigs)
            FloatingSuit(
              key: ValueKey(cfg.key),
              suit: cfg.suit,
              size: cfg.size,
              initialX: cfg.x,
              initialY: cfg.y,
              driftDistance: cfg.drift,
              driftDuration: Duration(seconds: cfg.seconds),
              opacity: cfg.opacity,
              color: (cfg.suit == '♥' || cfg.suit == '♦') ? AppColors.primary : AppColors.secondary,
            ),
        if (showFloatingPieces)
          Positioned.fill(
            child: GameWidget(
              game: FloatingPiecesGame(
                pieceColors: const [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.accent,
                ],
              ),
            ),
          ),
        if (child != null) child!,
      ],
    );
  }
}

class _SuitConfig {
  const _SuitConfig({
    required this.key,
    required this.suit,
    required this.size,
    required this.x,
    required this.y,
    required this.drift,
    required this.seconds,
    required this.opacity,
  });

  final String key;
  final String suit;
  final double size;
  final double x;
  final double y;
  final double drift;
  final int seconds;
  final double opacity;
}

/// A soft-edged glow blob built from a [RadialGradient] rather than a real
/// blur filter — visually reads as "blurred circle" decoration without the
/// per-frame cost of `ImageFilter.blur` sitting above a continuously
/// animating Flame canvas.
class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.08),
              color.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}
