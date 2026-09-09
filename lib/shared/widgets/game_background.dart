import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_theme_extension.dart';
import '../../game/floating_pieces_game.dart';

/// The app's single background treatment — "Warm Tactile Serenity": a
/// near-flat warm ivory wash with a faint sage dot texture, and
/// (optionally) the Flame floating-pieces layer drifting gently behind the
/// content. Deliberately calm so artwork and puzzle photos stay the focus.
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
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _DotTexture())),
        ),
        if (showFloatingPieces)
          Positioned.fill(
            child: GameWidget(
              game: FloatingPiecesGame(
                pieceColors: const [
                  AppColors.primaryFixedDim,
                  AppColors.honey,
                  AppColors.primaryContainer,
                ],
              ),
            ),
          ),
        if (child != null) child!,
      ],
    );
  }
}

/// A faint sage dot grid — the calm ambient watermark from the Stitch
/// design (16px pitch, ~4% sage). Cheap: a handful of tiny circles per
/// frame, painted once (no animation).
class _DotTexture extends CustomPainter {
  const _DotTexture();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary.withValues(alpha: 0.04);
    const pitch = 16.0;
    for (var y = pitch / 2; y < size.height; y += pitch) {
      for (var x = pitch / 2; x < size.width; x += pitch) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotTexture oldDelegate) => false;
}
