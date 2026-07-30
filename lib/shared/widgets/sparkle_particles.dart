import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/app_animations.dart';
import '../../core/design_system/app_colors.dart';

/// A gentle, continuously looping sparkle particle effect that radiates
/// tiny glowing stars from random positions across the screen. Each
/// sparkle fades in, floats upward, spins, and fades out — creating a
/// magical, premium celebration atmosphere.
///
/// Used on the Chapter Complete and Victory screens as an extra layer
/// of polish alongside confetti and fireworks.
class SparkleParticles extends StatefulWidget {
  const SparkleParticles({
    super.key,
    this.sparkleCount = 18,
    this.colors,
  });

  final int sparkleCount;
  final List<Color>? colors;

  @override
  State<SparkleParticles> createState() => _SparkleParticlesState();
}

class _SparkleParticlesState extends State<SparkleParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Sparkle> _sparkles;
  final math.Random _random = math.Random();

  static const _defaultColors = [
    Color(0xFFFFD700), // Gold
    Color(0xFFFF6B6B), // Coral
    Color(0xFF4ECDC4), // Teal
    Color(0xFFFFD93D), // Yellow
    Color(0xFF6C5CE7), // Purple
    Colors.white,
    AppColors.accent,
    AppColors.secondary,
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final colors = widget.colors ?? _defaultColors;

    _sparkles = List.generate(widget.sparkleCount, (_) {
      return _Sparkle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        startTime: _random.nextDouble(),
        duration: 2.0 + _random.nextDouble() * 3.0,
        size: 6.0 + _random.nextDouble() * 10.0,
        color: colors[_random.nextInt(colors.length)],
        driftX: (_random.nextDouble() - 0.5) * 40,
        driftY: -20 - _random.nextDouble() * 40,
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 4,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _SparklePainter(
            sparkles: _sparkles,
            time: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _Sparkle {
  _Sparkle({
    required this.x,
    required this.y,
    required this.startTime,
    required this.duration,
    required this.size,
    required this.color,
    required this.driftX,
    required this.driftY,
    required this.rotation,
    required this.rotationSpeed,
  });

  final double x;
  final double y;
  final double startTime;
  final double duration;
  final double size;
  final Color color;
  final double driftX;
  final double driftY;
  final double rotation;
  final double rotationSpeed;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({
    required this.sparkles,
    required this.time,
  });

  final List<_Sparkle> sparkles;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    for (final sparkle in sparkles) {
      // Each sparkle has its own lifecycle based on its start time and duration
      final localTime = (time - sparkle.startTime) % 1.0;
      final sparkleProgress = (localTime * (4.0 / sparkle.duration)) % 1.0;

      // Fade in, hold, fade out
      final fade = _computeFade(sparkleProgress);
      if (fade <= 0.01) continue;

      // Position with drift
      final posX = (sparkle.x * size.width) + sparkle.driftX * sparkleProgress;
      final posY = (sparkle.y * size.height) + sparkle.driftY * sparkleProgress;

      // Scale: pop in then slowly shrink
      final scale = (sparkleProgress < 0.15)
          ? sparkleProgress / 0.15 // Pop in
          : 1.0 - (sparkleProgress - 0.15) * 0.6; // Slowly shrink

      final currentSize = sparkle.size * scale;
      final rotation = sparkle.rotation + sparkle.rotationSpeed * sparkleProgress * math.pi * 2;

      canvas.save();
      canvas.translate(posX, posY);
      canvas.rotate(rotation);

      // Glow circle behind
      final glowPaint = Paint()
        ..color = sparkle.color.withValues(alpha: fade * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset.zero, currentSize * 0.8, glowPaint);

      // Star shape (4-pointed sparkle)
      final sparklePaint = Paint()
        ..color = sparkle.color.withValues(alpha: fade)
        ..style = PaintingStyle.fill;

      final path = Path();
      final points = 4;
      for (var i = 0; i < points * 2; i++) {
        final angle = (math.pi * i / points) - math.pi / 2;
        final radius = i.isEven ? currentSize : currentSize * 0.3;
        final px = math.cos(angle) * radius;
        final py = math.sin(angle) * radius;
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();
      canvas.drawPath(path, sparklePaint);

      canvas.restore();
    }
  }

  double _computeFade(double progress) {
    // Fade in from 0 to 0.2, hold until 0.7, fade out to 1.0
    if (progress < 0.2) return progress / 0.2;
    if (progress < 0.7) return 1.0;
    return (1.0 - progress) / 0.3;
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.time != time;
}
