import 'dart:ui';

import 'package:flame/components.dart';

import '../floating_pieces_game.dart';

/// A single decorative jigsaw-piece silhouette that drifts slowly across
/// the splash background and wraps around the screen edges.
class FloatingPuzzlePiece extends PositionComponent
    with HasGameReference<FloatingPiecesGame> {
  FloatingPuzzlePiece({
    required super.position,
    required super.size,
    required Color color,
    required this.velocity,
    required this.rotationSpeed,
  }) : _paint = Paint()..color = color,
       super(anchor: Anchor.center);

  final Paint _paint;
  final Vector2 velocity;
  final double rotationSpeed;

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    angle += rotationSpeed * dt;

    final bounds = game.size;
    final margin = size.x;
    if (position.x < -margin) position.x = bounds.x + margin;
    if (position.x > bounds.x + margin) position.x = -margin;
    if (position.y < -margin) position.y = bounds.y + margin;
    if (position.y > bounds.y + margin) position.y = -margin;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawPath(_jigsawPath(size.x, size.y), _paint);
  }

  /// Rounded square with a single circular knob — a lightweight silhouette
  /// that reads as "puzzle piece" without needing an image asset.
  Path _jigsawPath(double w, double h) {
    final knobRadius = w * 0.22;
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h),
          Radius.circular(w * 0.2),
        ),
      )
      ..addOval(Rect.fromCircle(center: Offset(w / 2, 0), radius: knobRadius));
  }
}
