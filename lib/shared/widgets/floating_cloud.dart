import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A soft, semi-transparent cloud shape that drifts slowly across the
/// screen — the premium casual-game atmosphere element seen in Royal
/// Match, Candy Crush, and similar titles. Multiple instances at
/// different sizes, speeds, and vertical positions create a layered
/// parallax-like sky effect.
///
/// Each cloud is a cluster of overlapping blurred circles painted via
/// [CustomPainter] — no image assets needed.
class FloatingCloud extends StatefulWidget {
  const FloatingCloud({
    super.key,
    this.width = 160,
    this.height = 60,
    this.color = Colors.white,
    this.opacity = 0.12,
    this.initialX = 0,
    this.initialY = 0,
    this.driftDuration = const Duration(seconds: 30),
    this.driftDistance = 60,
  });

  /// Total visual width of the cloud shape.
  final double width;

  /// Total visual height of the cloud shape.
  final double height;

  /// Base tint of the cloud (applied with [opacity]).
  final Color color;

  /// Opacity of the cloud — keep low for a subtle atmospheric effect.
  final double opacity;

  /// Initial horizontal position (0 = left edge of parent).
  final double initialX;

  /// Initial vertical position (0 = top edge of parent).
  final double initialY;

  /// How long one full drift cycle takes (longer = slower = more serene).
  final Duration driftDuration;

  /// Pixels the cloud drifts left and right from its [initialX].
  final double driftDistance;

  @override
  State<FloatingCloud> createState() => _FloatingCloudState();
}

class _FloatingCloudState extends State<FloatingCloud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _drift;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.driftDuration,
    )..repeat(reverse: true);

    // Randomize the starting position so clouds don't all move in sync
    final random = math.Random();
    _controller.value = random.nextDouble();

    _drift = Tween<double>(
      begin: -widget.driftDistance,
      end: widget.driftDistance,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        return Positioned(
          left: widget.initialX + _drift.value,
          top: widget.initialY,
          child: IgnorePointer(
            child: Opacity(
              opacity: widget.opacity,
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: CustomPaint(
                  painter: _CloudPainter(
                    color: widget.color,
                    bumpCount: 4,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paints a soft cloud shape using overlapping filled circles with blur
/// applied via [MaskFilter] for a fluffy, ethereal look.
class _CloudPainter extends CustomPainter {
  _CloudPainter({
    required this.color,
    this.bumpCount = 4,
  });

  final Color color;
  final int bumpCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Main body — an elongated ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.6),
        width: size.width * 0.8,
        height: size.height * 0.6,
      ),
      paint,
    );

    // "Bumps" — smaller circles on top to give the cloud its fluffy shape
    for (var i = 0; i < bumpCount; i++) {
      final bumpX = size.width * (0.2 + (i * 0.2));
      final bumpRadius = size.height * (0.3 + (i.isEven ? 0.15 : 0.1));
      canvas.drawCircle(
        Offset(bumpX, size.height * 0.45),
        bumpRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) => false;
}
