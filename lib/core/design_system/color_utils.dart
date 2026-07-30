import 'package:flutter/material.dart';

/// Shade a [Color] darker/lighter in HSL space — used to derive a chunky
/// "3D bevel" band color from a widget's own fill color, so the bevel
/// always matches whatever brand color is passed in rather than needing a
/// hand-picked shade per widget.
extension ColorShade on Color {
  Color darken([double amount = 0.18]) {
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Color lighten([double amount = 0.18]) {
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
