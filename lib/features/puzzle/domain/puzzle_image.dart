/// A deterministic "random" photo for the given [seed], sourced from
/// picsum.photos' seeded endpoint — the same seed always gets the same
/// photo (so replaying isn't jarring), different seeds get different
/// photos. No image assets are bundled with the app.
///
/// Fetched portrait (3:4) to match the board's portrait grid — see
/// [BoardDimensions].
String _puzzleImageUrlForSeed(String seed) =>
    'https://picsum.photos/seed/puzzle-cards-$seed/600/800';

/// The puzzle image for a regular level.
/// Now pulls from local assets for the first 300 levels!
String puzzleImageUrlFor(int levelId) {
  final assetId = ((levelId - 1) % 300) + 1;
  return 'assets/images/collections/level_$assetId.jpg';
}

/// The puzzle image for a given day's Daily Challenge (`dateKey` is
/// `yyyy-mm-dd`) — same picture all day, a new one each day.
/// This still uses the network so daily challenges are infinite.
String puzzleImageUrlForDaily(String dateKey) =>
    _puzzleImageUrlForSeed('daily-$dateKey');
