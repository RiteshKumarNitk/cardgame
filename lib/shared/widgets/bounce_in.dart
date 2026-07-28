import 'package:flutter/material.dart';

import '../../core/design_system/app_animations.dart';

/// Wraps [child] with a one-time "pop in" entrance animation (fade + scale
/// with an elastic overshoot). Give each item in a list a slightly
/// increasing [delay] to stagger them.
class BounceIn extends StatefulWidget {
  const BounceIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppAnimations.slow,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<BounceIn> createState() => _BounceInState();
}

class _BounceInState extends State<BounceIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.bounceCurve),
    );
    _fade = CurvedAnimation(parent: _controller, curve: AppAnimations.fadeCurve);
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
