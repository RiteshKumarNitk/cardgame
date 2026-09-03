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
///
/// Uses the same bundled photo set as regular levels (no network) so the
/// Daily Challenge works offline and ships no third-party imagery. The
/// date string is hashed to a stable photo id, so a given day always maps
/// to the same picture and consecutive days rarely repeat.
String puzzleImageUrlForDaily(String dateKey) {
  const photos = 300;
  var hash = 0;
  for (final codeUnit in dateKey.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  final assetId = (hash % photos) + 1;
  return 'assets/images/collections/level_$assetId.jpg';
}
