import 'package:flutter/material.dart';

/// Corner radii, aligned to the SuitClash Stitch design system.
///
/// | token | value | usage |
/// |-------|-------|-------|
/// | xs    | 4     | tiny chips |
/// | sm    | 8     | puzzle tiles, badges, small chips, inventory slots |
/// | md    | 12    | non-pill buttons, input fields, compact cards |
/// | lg    | 16    | standard cards, dialogs, the puzzle board tray |
/// | xl    | 24    | feature / hero cards, chapter cards |
/// | pill  | 999   | buttons, currency meters, journey nodes |
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  static BorderRadius get xsRadius => BorderRadius.circular(xs);
  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);
}
