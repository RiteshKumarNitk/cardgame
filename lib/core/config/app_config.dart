/// Compile-time feature switches for the shipped build.
///
/// These are plain `const` so the tree-shaker can drop disabled code
/// paths entirely. Flip a flag and rebuild — there is no runtime toggle.
abstract final class AppConfig {
  const AppConfig._();

  /// Whether AdMob is wired up. `false` for the first Play Store release:
  /// no banner widgets render, no rewarded/interstitial units load, and
  /// `MobileAds` is never initialised. To enable ads in a later version,
  /// set this to `true` **and** provide real ad unit IDs via
  /// `--dart-define` (see `AdService`).
  static const bool adsEnabled = false;

  /// Whether the experimental "Photo Puzzles" section is reachable.
  /// `false` for v1 — the bundled manifest only had placeholder entries
  /// and the feature is a developer sandbox, not finished content.
  static const bool photoPuzzlesEnabled = false;
}
