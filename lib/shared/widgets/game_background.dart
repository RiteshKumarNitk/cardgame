import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_theme_extension.dart';
import '../../game/floating_pieces_game.dart';

/// The app's single background treatment: soft brand gradient, a few
/// glowing blurred circles, and (optionally) the Flame floating-pieces
/// layer. Every top-level screen wraps its content in this instead of
/// rolling its own `DecoratedBox`/`GameWidget` combo.
class GameBackground extends StatelessWidget {
  const GameBackground({
    super.key,
    this.child,
    this.showFloatingPieces = true,
  });

  final Widget? child;
  final bool showFloatingPieces;

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
