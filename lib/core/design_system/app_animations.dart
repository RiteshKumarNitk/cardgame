import 'package:flutter/animation.dart';

/// Durations and curves for every interaction animation — press feedback,
/// entrance pops, page transitions. Widgets reference these instead of
/// inlining raw millisecond values.
abstract final class AppAnimations {
  /// Tight micro-interactions: press scale, hover flash, tap SFX timing.
  static const Duration micro = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 130);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 800);

  /// Continuous idle loops (CTA glow) — slower and gentler than any
  /// interaction animation so they read as "alive", not distracting.
  static const Duration glowPulse = Duration(milliseconds: 2200);

  /// For button presses and scale-down feedback — quick and decisive.
  static const Curve pressCurve = Curves.easeOut;

  /// For entrance pops — snappy, with a tiny overshoot that settles fast.
  /// Used sparingly; avoid on dense list items.
  static const Curve popCurve = Curves.easeOutBack;

  /// For fade + gentle scale entrances that should feel smooth, not bouncy.
  static const Curve entranceCurve = Curves.easeOut;

  /// For content sliding up from below (victory stats, bottom sheets).
  static const Curve slideUpCurve = Curves.easeOutCubic;

  /// For content sliding down / dismissing.
  static const Curve slideDownCurve = Curves.easeInCubic;

  /// For pure opacity fades.
  static const Curve fadeCurve = Curves.easeInOut;

  /// For page transitions.
  static const Curve pageCurve = Curves.easeOutCubic;

  /// For continuous loops (glow, idle float).
  static const Curve idleCurve = Curves.easeInOut;

  /// How much a button/card compresses while pressed.
  static const double pressedScale = 0.95;
}
