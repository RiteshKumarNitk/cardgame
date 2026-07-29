/// A deterministic "random" photo for a level's puzzle image, sourced
/// from picsum.photos' seeded endpoint — same level always gets the same
/// photo (so replaying isn't jarring), different levels get different
/// photos. No image assets are bundled with the app.
String puzzleImageUrlFor(int levelId) =>
    'https://picsum.photos/seed/puzzle-cards-$levelId/600/600';
