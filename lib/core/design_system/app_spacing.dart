/// Spacing scale — 4/8 base unit, aligned to the SuitClash Stitch design
/// system: `xxs 4 · xs 8 · sm 12 · md 16 · lg 20 · xl 24 · xxl 32 ·
/// xxxl 40 · huge 48`. Layout gaps and padding should always come from
/// here instead of arbitrary numbers, so rhythm stays consistent.
///
/// Screen body margin is [screenMargin] (16); puzzle/grid gutters use
/// [gridGutter] (12).
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  /// Standard screen body horizontal margin (mobile).
  static const double screenMargin = 16;

  /// Gutter between puzzle tiles / grid cells where a gapped style is used.
  static const double gridGutter = 12;
}
