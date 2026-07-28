import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';

/// A one-shot burst of colorful confetti particles radiating outward from
/// the top-center and falling under light gravity, then fading out.
/// Plays once on mount — used for the Victory screen's win moment.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.particleCount = 28});

  final int particleCount;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.success,
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1400),
        )..forward();

    final random = Random();
    _particles = List.generate(widget.particleCount, (_) {
      return _Particle(
        angle: random.nextDouble() * 2 * pi,
        speed: 80 + random.nextDouble() * 140,
        color: _colors[random.nextInt(_colors.length)],
        size: 6 + random.nextDouble() * 6,
        rotationSpeed: (random.nextDouble() - 0.5) * 8,
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
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.rotationSpeed,
  });

  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double rotationSpeed;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.3);
    final eased = Curves.easeOut.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0);

    for (final particle in particles) {
      final distance = particle.speed * eased;
      final gravity = 260 * progress * progress;
      final dx = cos(particle.angle) * distance;
      final dy = sin(particle.angle) * distance + gravity;
      final position = center + Offset(dx, dy);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(particle.rotationSpeed * progress * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 1.6,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = particle.color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
