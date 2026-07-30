import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_theme_extension.dart';
import '../../game/floating_pieces_game.dart';
import 'floating_cloud.dart';

/// The app's single background treatment: soft brand gradient, a few
/// glowing blurred circles, optionally the Flame floating-pieces layer,
/// and optionally drifting decorative clouds. Every top-level screen
/// wraps its content in this instead of rolling its own
/// `DecoratedBox`/`GameWidget`/cloud layout.
class GameBackground extends StatelessWidget {
  const GameBackground({
    super.key,
    this.child,
    this.showFloatingPieces = true,
    this.showClouds = false,
  });

  final Widget? child;
  final bool showFloatingPieces;

  /// Renders several slowly drifting semi-transparent clouds behind the
  /// content for a premium casual-game atmosphere (Royal Match, Candy
  /// Crush style). Disabled by default — opt-in where appropriate.
  final bool showClouds;

  /// Pre-defined cloud configurations with varied positions, sizes,
  /// opacities, and drift speeds for a layered parallax-like sky effect.
  static const List<_CloudConfig> _cloudConfigs = [
    _CloudConfig(
      key: 'cloud_1', width: 200, height: 70,
      x: -40, y: 38, drift: 50,
      seconds: 45, opacity: 0.08,
    ),
    _CloudConfig(
      key: 'cloud_2', width: 140, height: 50,
      x: 180, y: 95, drift: 40,
      seconds: 35, opacity: 0.10,
    ),
    _CloudConfig(
      key: 'cloud_3', width: 110, height: 40,
      x: -20, y: 240, drift: 35,
      seconds: 25, opacity: 0.07,
    ),
    _CloudConfig(
      key: 'cloud_4', width: 170, height: 55,
      x: 230, y: 370, drift: 45,
      seconds: 40, opacity: 0.09,
    ),
    _CloudConfig(
      key: 'cloud_5', width: 130, height: 45,
      x: 95, y: 525, drift: 30,
      seconds: 30, opacity: 0.06,
    ),
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
          child: _GlowCircle(size: 220, color: AppColors.primary),
        ),
        const Positioned(
          bottom: -90,
          right: -70,
          child: _GlowCircle(size: 260, color: AppColors.secondary),
        ),
        const Positioned(
          top: 180,
          right: -60,
          child: _GlowCircle(size: 160, color: AppColors.accent),
        ),
        // Decorative drifting clouds (behind floating pieces, behind
        // child content — atmospheric depth layer).
        if (showClouds)
          for (final cfg in _cloudConfigs)
            FloatingCloud(
              key: ValueKey(cfg.key),
              width: cfg.width,
              height: cfg.height,
              initialX: cfg.x,
              initialY: cfg.y,
              driftDistance: cfg.drift,
              driftDuration: Duration(seconds: cfg.seconds),
              opacity: cfg.opacity,
              color: Colors.white,
            ),
        if (showFloatingPieces)
          Positioned.fill(
            child: GameWidget(
              game: FloatingPiecesGame(
                pieceColors: [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.accent,
                ],
              ),
            ),
          ),
        ?child,
      ],
    );
  }
}

/// Compile-time cloud descriptor — avoids `dart:math` in the build method
/// and makes the cloud layout stable, deterministic, and inspectable.
class _CloudConfig {
  const _CloudConfig({
    required this.key,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    required this.drift,
    required this.seconds,
    required this.opacity,
  });

  final String key;
  final double width;
  final double height;
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
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
