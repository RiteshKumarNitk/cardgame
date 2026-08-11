/// The puzzle image for a regular level.
///
/// Levels pull from the bundled real photos (`assets/images/collections/
/// level_1.jpg` .. `level_300.jpg`) — the developer's curated photography,
/// cycled for the 1,000+ levels. To swap in different artwork, replace
/// the files in that folder (or change the asset id arithmetic below).
String puzzleImageUrlFor(int levelId) {
  const photos = 300;
  final assetId = ((levelId - 1) % photos) + 1;
  return 'assets/images/collections/level_$assetId.jpg';
}

/// The puzzle image for a given day's Daily Challenge (`dateKey` is
/// `yyyy-mm-dd`) — same picture all day, a new one each day.
/// Uses internet photos so daily challenges have an unbounded supply.
String puzzleImageUrlForDaily(String dateKey) =>
    'https://picsum.photos/seed/puzzle-cards-daily-$dateKey/600/800';
