import 'package:flutter/material.dart';

/// Warm, layered elevation presets — aligned to the SuitClash Stitch
/// design system. Visual hierarchy uses warm ambient lighting (brown/moss
/// tints), never flat grey drop-shadows, evoking matte-laminated tiles
/// resting on unbleached linen.
///
/// Every elevated surface (card, button, tile, sheet) picks one of these
/// instead of hand-rolling a `BoxShadow`.
abstract final class AppShadows {
  /// L2 — resting card / tile. Dual-layer warm shadow. Pair with a 1px
  /// [AppColors.outline] feather border on the surface itself.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A41321E), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0F41321E), blurRadius: 16, offset: Offset(0, 8)),
  ];

  /// Compact stadium pills — stat chips, currency meters.
  static const List<BoxShadow> pill = [
    BoxShadow(color: Color(0x0D41321E), blurRadius: 6, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0A2D312E), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Ambient shadow beneath an interactive button (used together with
  /// [tactile] for primary CTAs, or on its own for lighter buttons).
  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x1C316342), blurRadius: 18, offset: Offset(0, 10)),
  ];

  /// L3 — a lifted / picked-up tile or card. Rises cleanly off the board.
  static const List<BoxShadow> lifted = [
    BoxShadow(color: Color(0x2441321E), blurRadius: 28, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x1441321E), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// L4 — sheets, modals, dialogs, victory toasts.
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x28281E14), blurRadius: 40, offset: Offset(0, 20)),
  ];

  /// Tactile CTA "cushion": a hard resting edge in [cushion] (no blur)
  /// plus a soft ambient shadow — approximates Stitch's `0 4px 0` bottom
  /// shadow that makes the button feel physically pressable.
  static List<BoxShadow> tactile(Color cushion) => [
    BoxShadow(color: cushion, offset: const Offset(0, 4), blurRadius: 0),
    BoxShadow(
      color: cushion.withValues(alpha: 0.28),
      offset: const Offset(0, 10),
      blurRadius: 18,
    ),
  ];

  /// Soft colored halo — completed frames, solved-tile bloom, active
  /// journey node. Warm and understated, never a hard neon ring.
  static List<BoxShadow> glow(Color color, {double opacity = 0.35}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 24,
      spreadRadius: 2,
      offset: const Offset(0, 8),
    ),
  ];

  /// Legacy no-op — the chunky "3D bevel" band is gone, but the method
  /// remains so existing call sites keep compiling.
  static List<BoxShadow> bevel(
    Color fillColor, {
    double depth = 5,
    double darkenAmount = 0.16,
  }) => const [];
}
