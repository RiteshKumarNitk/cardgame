# GAME_PROGRESS.md — Current Project State

Core feature implementation is advanced, but visual polish and core gameplay refinement are ongoing.

---

## Implemented

- [x] Flutter project created (package: `puzzle_cards`, product: SuitClash)
- [x] Flame integrated (background floating pieces only)
- [x] GoRouter routing (19 routes with consistent transitions)
- [x] Design system (colors, typography, spacing, shadows, gradients, animations)
- [x] Single light theme (bright, colorful casual game aesthetic)
- [x] Hive local storage (10 boxes, LevelModel adapter)
- [x] Splash screen (animated logo, bootstrap progress, puzzle piece loader)
- [x] Home screen (collection artwork display, progress, Play button)
- [x] Puzzle screen (top bar + drag-and-drop board)
- [x] Puzzle board (GridView, drag-to-swap, connected-edge adjacency, dynamic groups)
- [x] Puzzle image system (board-level cover-scale-then-crop rendering)
- [x] Connected puzzle group architecture (dynamic adjacency-based formation, edge-level connections, displacement-based movement)
- [x] Connected puzzle group UI (per-edge border rendering, group-shaped drag feedback, adjacency-aware visual indicators)
- [x] Visual interaction overhaul (removed green correctness feedback, enhanced card-lift feel, seamless group rendering)
- [x] Image coverage fix (`ImageLayout.sourceRectFor()` derives every tile's crop from the board's own cell geometry, not the image's independently-scaled size — eliminates gaps/misalignment on non-matching aspect ratios)
- [x] Neutral drag-drop feedback (removed red hover tint on drop targets; invalid group moves reject with a colorless shake + haptic/SFX instead of a colored target)
- [x] Gameplay rule audit — removed a residual position-lock: a solo correctly-placed (but unconnected) tile is now always displaceable by an incoming group, matching "correct position ≠ locked" everywhere (`canMoveGroupByCells()` no longer special-cases correctness)
- [x] Fixed a group-vs-group displacement direction bug (`canMoveGroupByCells`/`moveGroupByCells` used `cell + displacement` instead of `cell - displacement` when relocating a displaced group to the vacated cells) — dragging one connected group onto another matching-shaped group was previously rejected essentially always; now succeeds when shapes fit, per design
- [x] Group drag feedback fix — every group member now fades together while dragging (not just the cell that started the drag, which previously looked like a duplicate/leftover tile), the grabbed cell stays under the pointer via a custom `dragAnchorStrategy`, and drag feedback (both individual tile and group) is rendered at exact board size with no scale-up and no drop shadow
- [x] Edge connections switched from absolute-position to relative-adjacency (`computeAdjacency()` now connects two board-adjacent pieces whenever they're each other's solved-image neighbors, regardless of whether either is at its own correct board cell) — the player can now build a partial chain anywhere on the board instead of only at each piece's exact final coordinate; the snap-pop animation now fires on first edge connection rather than on reaching absolute correctness
- [x] Star rating system (3 tiers based on minimal swaps)
- [x] Combo system (rapid correct moves)
- [x] Pity shuffle (after 6 stalled moves)
- [x] Hint system (auto-places piece, coin-gated)
- [x] Preview system (coin-gated reference image)
- [x] Pause menu (resume, restart, give up)
- [x] Tutorial overlay (first-time how-to-play)
- [x] Victory screen (image reveal, confetti, fireworks, stars, stats, share)
- [x] Levels/Journey Map (chapter banners, winding path, level nodes)
- [x] Chapter complete celebration screen
- [x] Section complete celebration screen
- [x] Chapter catalog (data-driven, 20-level sections, unlimited expansion)
- [x] Collections showcase (chapter hero cards with progress)
- [x] Gallery (all levels grid, completed vs locked)
- [x] Daily challenge (daily puzzle, streak tracking, leaderboard)
- [x] Daily reward (7-day streak system, 20-300 coins)
- [x] Achievements (9 achievements with counter-based progress)
- [x] Cosmetics (6 frames, 5 piece styles, 11 avatars)
- [x] Shop (3 coin packs, watch-ad-for-coins, remove ads)
- [x] Settings (audio toggles, volume sliders, reset progress, restore purchases)
- [x] Profile (display name editing, avatar display)
- [x] Photo puzzles (manifest-driven photo puzzle mode)
- [x] Wallet system (earn/spend coins)
- [x] Ad integration (AdMob: rewarded, interstitial, banner)
- [x] IAP integration (RevenueCat: coin packs, remove ads)
- [x] Firebase integration (anonymous auth, Firestore cloud save, analytics, crashlytics)
- [x] Audio system (manifest-driven, scene-based BGM, SFX pool, ducking)
- [x] Connected puzzle group architecture (dynamic adjacency-based formation, edge-level connections, displacement-based movement)
- [x] Connected puzzle group UI (per-edge border rendering, group-shaped drag feedback, adjacency-aware visual indicators)
- [x] Visual interaction overhaul (removed green correctness feedback, enhanced card-lift feel, seamless group rendering)
- [x] LevelConfig-driven puzzle engine (LevelConfig carries all puzzle parameters; engine never touches Chapter/Section)
- [x] Data-driven content architecture (chapters/sections/levels added by appending blueprints; no engine changes)
- [x] Section progression roles (20-level arc: introduce, practice, variation, miniChallenge, combine, advanced, challenge, preFinale, finale)
- [x] 26 shared widgets (buttons, cards, animations, effects)
- [x] Onboarding service (tutorial flag)
- [x] Game background (gradient + glow circles + floating pieces)
- [x] Artwork generation tool (16 themed PNG paintings)
- [x] Audio placeholder generation tool

---

## In Progress

- [ ] Artwork collection progression (core gameplay loop: complete puzzle → collect artwork piece → update collection)
- [ ] Home Screen refinement (focus on current collection artwork + large Play button)
- [ ] Visual polish and refinement (removing legacy casino/card-game visual elements)

---

## Known Issues

### Core Gameplay
- Artwork collection progression is not fully wired into the game loop
- Home Screen may not yet emphasize collection artwork and Play button as primary focus
- Legacy card suit symbols (♠♥♦♣) appear in background — these are not part of the core visual identity

### Font Inconsistency
- `Baloo2.ttf` and `Nunito.ttf` are declared in `pubspec.yaml` and bundled in `assets/fonts/`
- The design system (`app_typography.dart`) uses `GoogleFonts.quicksand()` and `GoogleFonts.roboto()` instead
- The bundled fonts are currently unused

### Placeholder Assets
- All audio files are procedurally-generated sine waves (tools/generate_audio.dart)
- Level photos are from picsum.photos (random) — developer's curated photography intended as replacement
- The `bevel()` method in AppShadows returns an empty list (kept for backward compatibility)

### Documentation
- `README.md` is default Flutter boilerplate, not project-specific

### content/artwork/ Not Consumed
- 16 themed PNG paintings exist in `content/artwork/` (generated by tools/generate_artwork.dart)
- The game uses real photos from `assets/images/collections/` instead
- The generated artwork is not consumed by the app

---

## Next Recommended Task

**Wire artwork collection progression** into the core game loop (complete puzzle → collect artwork piece → update collection). This is the primary remaining feature to make the game feel complete.
