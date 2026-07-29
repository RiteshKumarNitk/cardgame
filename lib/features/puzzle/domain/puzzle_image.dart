/// A deterministic "random" photo for the given [seed], sourced from
/// picsum.photos' seeded endpoint — the same seed always gets the same
/// photo (so replaying isn't jarring), different seeds get different
/// photos. No image assets are bundled with the app.
String _puzzleImageUrlForSeed(String seed) =>
    'https://picsum.photos/seed/puzzle-cards-$seed/600/600';

/// The puzzle image for a regular level.
String puzzleImageUrlFor(int levelId) => _puzzleImageUrlForSeed('$levelId');

/// The puzzle image for a given day's Daily Challenge (`dateKey` is
/// `yyyy-mm-dd`) — same picture all day, a new one each day.
String puzzleImageUrlForDaily(String dateKey) =>
    _puzzleImageUrlForSeed('daily-$dateKey');
