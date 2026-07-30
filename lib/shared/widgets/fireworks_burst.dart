import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';

/// A heavier, multi-burst celebration effect for major milestones (Chapter
/// Complete) — several fireworks-style radial explosions from different
/// points across the top of the screen, fired in a staggered sequence.
/// Plays once on mount. Same particle-painter technique as ConfettiBurst,
/// scaled up for a bigger moment.
class FireworksBurst extends StatefulWidget {
  const FireworksBurst({
    super.key,
    this.burstCount = 4,
    this.particlesPerBurst = 26,
  });

  final int burstCount;
  final int particlesPerBurst;

  @override
  State<FireworksBurst> createState() => _FireworksBurstState();
}

class _FireworksBurstState extends State<FireworksBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Burst> _bursts;

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.success,
    AppColors.danger,
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2400),
        )..forward();

    final random = Random();
    _bursts = List.generate(widget.burstCount, (i) {
      final start = i / widget.burstCount * 0.6;
      final originX = 0.2 + random.nextDouble() * 0.6;
      final originY = 0.2 + random.nextDouble() * 0.25;
      final particles = List.generate(widget.particlesPerBurst, (_) {
        return _Particle(
          angle: random.nextDouble() * 2 * pi,
          speed: 60 + random.nextDouble() * 90,
          color: _colors[random.nextInt(_colors.length)],
          size: 4 + random.nextDouble() * 5,
        );
      });
      return _Burst(
        start: start,
        duration: 0.45,
        originX: originX,
        originY: originY,
        particles: particles,
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
          painter: _FireworksPainter(bursts: _bursts, progress: _controller.value),
        ),
      ),
    );
  }
}

class _Burst {
  _Burst({
    required this.start,
    required this.duration,
    required this.originX,
    required this.originY,
    required this.particles,
  });

  /// Fraction of the overall animation (0-1) at which this burst ignites.
  final double start;

  /// How long (as a fraction of the overall animation) this burst takes
  /// to fully expand and fade.
  final double duration;

  /// Origin position as a fraction of the canvas size.
  final double originX;
  final double originY;
  final List<_Particle> particles;
}

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
  });

  final double angle;
  final double speed;
  final Color color;
  final double size;
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter({required this.bursts, required this.progress});

  final List<_Burst> bursts;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final burst in bursts) {
      if (progress < burst.start) continue;
      final local = ((progress - burst.start) / burst.duration).clamp(0.0, 1.0);
      final eased = Curves.easeOut.transform(local);
      final fade = (1 - local).clamp(0.0, 1.0);
      final center = Offset(size.width * burst.originX, size.height * burst.originY);

      for (final particle in burst.particles) {
        final distance = particle.speed * eased;
        final gravity = 40 * local * local;
        final dx = cos(particle.angle) * distance;
        final dy = sin(particle.angle) * distance + gravity;
        final position = center + Offset(dx, dy);

        canvas.drawCircle(
          position,
          particle.size * (1 - local * 0.3),
          Paint()..color = particle.color.withValues(alpha: fade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
