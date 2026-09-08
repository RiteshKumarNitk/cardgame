/// Compile-time feature switches for the shipped build.
///
/// These are plain `const` so the tree-shaker can drop disabled code
/// paths entirely. Flip a flag and rebuild — there is no runtime toggle.
abstract final class AppConfig {
  const AppConfig._();

  /// Whether AdMob is wired up. When `true`: `MobileAds` is initialised at
  /// startup, banner widgets render, and rewarded/interstitial units load.
  ///
  /// Debug/profile builds always use Google's official **test** ad unit
  /// IDs (safe, no account needed). Release builds use real ad unit IDs
  /// only when they are injected via `--dart-define`, otherwise they fall
  /// back to test IDs — see [AdConfig]. Before shipping *real* ads you
  /// must also replace the sample AdMob **App ID** in
  /// `AndroidManifest.xml` / iOS `Info.plist` and add a UMP consent form.
  static const bool adsEnabled = true;

  /// Whether the experimental "Photo Puzzles" section is reachable.
  /// `false` for v1 — the bundled manifest only had placeholder entries
  /// and the feature is a developer sandbox, not finished content.
  static const bool photoPuzzlesEnabled = false;
}
