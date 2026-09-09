# GAME_PROGRESS.md — Current Project State

Core feature implementation is advanced, but visual polish and core gameplay refinement are ongoing.

---

## Implemented

- [x] Flutter project created (package: `puzzle_cards`, product: SuitClash)
- [x] Flame integrated (background floating pieces only)
- [x] GoRouter routing (19 routes with consistent transitions)
- [x] Design system (colors, typography, spacing, shadows, gradients, animations) — **"Warm Tactile Serenity"** (2026-09-09): Stitch project *"SuitClash UI/UX Redesign System"* is the visual source of truth. Soft-sage + honey-gold on warm ivory, Plus Jakarta Sans, warm layered elevation, tactile solid buttons. Visual-only retheme — no logic/navigation/grid changes. See `docs/UI_UX_GUIDELINES.md`. Follow-up cleanup 2026-09-09: cosmetics trimmed to Classics, avatars flattened, golden glow removed, moving-piece feedback made clean, puzzle board back to square corners.
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
- [x] Fixed a movement overwrite bug that lost/overwrote pieces: `moveGroupByCells()` step 6 was dead code (guarded on an always-false condition), so a solo tile sitting where a group landed was overwritten and never relocated (`A A B C` + drag `[A A]` onto `[B C]` produced `_ _ A A` instead of `B C A A`); and `_swapWithGroups()` swapped a solo source tile with a single member of a destination connected group, splitting it (`A A` + drop `B` on an `A` gave `B A`). Now every displaced solo piece is relocated into a vacated cell (opposite-displacement preferred), and a solo→group drop displaces the whole group or is cleanly rejected. Every move stays a valid permutation of `1..N`
- [x] Fixed a connected-group overlap bug on self-overlapping moves: `canMoveGroupByCells()` checked displaced multi-cell groups against the moving group's whole old footprint (`oldCellSet`) instead of only the cells it actually frees (`oldCells \ newCells`). When a group was dragged a short distance across its own footprint with another connected group in the destination, a displaced group could pass validation yet be written on top of a moving-group tile in `moveGroupByCells()` step 5 — the overwritten tile vanished, leaving a `0` cell / duplicate-looking board. Now validated against the vacated set (plus per-axis bounds on the opposite-shift), and `moveGroupByCells()` verifies the candidate is a permutation of `1..N` before returning — otherwise the board is left exactly unchanged (atomic all-or-nothing). No overlap, split, or partial group movement is possible
- [x] Made displaced-group relocation fully generic (`_displacedShift` + `_extentOf`): displaced groups were relocated by the fixed inverse `(-dRow, -dCol)`, which is only correct when the moving group's old and new footprints don't overlap — so any group→group move shorter than the moving group's own extent (common with larger groups, any direction) was wrongly rejected. Now the shift is `-sign(delta) * max(|delta|, moverExtent)` per axis: reduces to `-delta` for non-overlapping moves (unchanged), stretches into the trailing vacated slab for overlapping ones, symmetric in all four directions, no condition on group size / shape / board size. Multiple affected groups share the one shift. Genuinely impossible displacements (slab too small, shape only fits rotated, off-board) still reject cleanly
- [x] Fixed a group-permanence bug: a destination group used to be treated as a rigid, unsplittable block — `canMoveGroupByCells()` required the group's FULL component to fit together inside the vacated cells or rejected the whole move, so whenever a displacement did succeed, the destination group's shape (and its adjacency) was mechanically guaranteed to survive intact, indistinguishable from its old connection being "remembered." Now only the MOVING group's own bounds are validated, and `moveGroupByCells()` relocates displaced destination content per CELL (not per group) — a destination group can end up split into smaller groups or solo tiles once adjacency/grouping is recomputed from the resulting board, exactly like a solo tile always could
- [x] Direct group ⇄ group atomic swap (`TileSwapEngine.groupsShareShape` + `swapGroups`): dragging a connected group onto another connected group **of the same normalized shape** now exchanges the two groups' positions directly (cell-for-cell at matching relative offsets) instead of routing through inverse-displacement, which failed for many drop positions. Resolved from the two full components (not the drop cell), no displacement vector so it's direction- and board-size-independent, `_isPermutation`-gated and committed atomically. Shape-incompatible pairs still use the generic displacement path (displace or clean reject). Groups stay movable after a swap — grouping is rebuilt from the resulting arrangement
- [x] Group drag feedback fix — every group member now fades together while dragging (not just the cell that started the drag, which previously looked like a duplicate/leftover tile), the grabbed cell stays under the pointer via a custom `dragAnchorStrategy`, and drag feedback (both individual tile and group) is rendered at exact board size with no scale-up and no drop shadow
- [x] Edge connections switched from absolute-position to relative-adjacency (`computeAdjacency()` now connects two board-adjacent pieces whenever they're each other's solved-image neighbors, regardless of whether either is at its own correct board cell) — the player can now build a partial chain anywhere on the board instead of only at each piece's exact final coordinate; the snap-pop animation now fires on first edge connection rather than on reaching absolute correctness
- [x] Star rating system (3 tiers based on minimal swaps)
- [x] Combo system (rapid correct moves)
- [x] Pity shuffle (after 6 stalled moves)
- [x] Hint system (coin-gated) — grouped levels send the first not-yet-home connected group toward its true home (full jump → single nudge → next group); Easy/Medium and the grouped fallback swap a misplaced ungrouped piece straight home. (Previously the grouped hint aimed at board corner `(0,0)` and silently did nothing when blocked.)
- [x] Elapsed timer starts on the player's first move, not on level load — the deal-in/study "beginning stage" is untimed; pause/resume can't start it early; Victory time measured from first move
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
- [x] Cosmetics (4 frames — Classic + Ivory/Sage/Slate, 1 piece style — Classic seamless, 11 avatars). Trimmed to a clean "Classics" range 2026-09-09; prices raised to a 0 / 1,500 / 3,000 / 5,000 / 7,500 / 10,000 progression.
- [x] Shop (3 coin packs, watch-ad-for-coins, remove ads)
- [x] Settings (audio toggles, volume sliders, reset progress, restore purchases)
- [x] Profile (display name editing, avatar display)
- [x] Photo puzzles (manifest-driven photo puzzle mode)
- [x] Wallet system (earn/spend coins)
- [x] Ad integration (AdMob: rewarded, interstitial, banner) — **enabled** (`AppConfig.adsEnabled = true`); test ad IDs in debug, real IDs via `--dart-define` in release; see "AdMob / Ads" section below
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
- [x] Home Screen refinement (focus on current collection artwork + large Play button)
- [x] Visual polish and refinement (removing legacy casino/card-game visual elements)

---

## AdMob / Ads

**Status:** enabled and wired end-to-end; verified with Google **test** ad IDs at
the unit-test level. Real-device verification is still outstanding (see Known
Issues → "Ad runtime verification blocked").

### Architecture
| Piece | File |
|---|---|
| Master on/off switch | `AppConfig.adsEnabled` (`lib/core/config/app_config.dart`) — now `true` |
| All ad unit IDs + sample App IDs | `AdConfig` (`lib/core/config/ad_config.dart`) |
| SDK init + preload | `AppBootstrap.run()` → `MobileAds.instance.initialize()` (once, on splash, `AppConfig.adsEnabled`-gated) |
| Banner placement (the one real widget) | `BannerAdWidget` (`lib/shared/widgets/banner_ad_widget.dart`) — Home, Gallery, Journey/Levels |
| Interstitial | `AdService.showInterstitial()` — Victory "continue" (daily cap 4), skipped when Remove Ads owned |
| Rewarded | `AdService.showRewardedAd()` — Puzzle out-of-time offer |
| Remove Ads entitlement | `AdsCubit` / `AdsService` (Hive `adsRemoved`), mirrored from RevenueCat `remove_ads` |
| Debug logging | `AdLogger` (`lib/services/ad_logger.dart`) — `[AdMob] …`, debug builds only |

### Test vs production IDs
- **Debug / profile:** always Google's official test unit IDs — no account needed, no invalid-traffic risk.
- **Release:** real unit IDs are used **only** when injected at build time:
  ```
  flutter build appbundle --release \
    --dart-define=BANNER_AD_UNIT_ID_ANDROID=ca-app-pub-xxx/xxx \
    --dart-define=INTERSTITIAL_AD_UNIT_ID_ANDROID=ca-app-pub-xxx/xxx \
    --dart-define=REWARDED_AD_UNIT_ID_ANDROID=ca-app-pub-xxx/xxx
  ```
  (`_IOS` variants exist too.) Without them a release build serves test ads (safe, earns nothing).

### Banner placement rules
- Shows on **Home**, **Gallery**, **Journey/Levels** (bottom of screen, inside `SafeArea`, adaptive width — never overlaps controls).
- **Not** shown on Puzzle (gameplay), Victory, Splash, Settings, Shop, or any full-screen celebration.
- Collapses to zero height when: ads compiled out, web, Remove Ads owned, or the load failed. The game is always fully playable without an ad.

### Remove Ads behaviour
- `BannerAdWidget` watches `AdsCubit`; a `true` state means no ad is even requested, and any live native ad is disposed.
- `victory_page` interstitial and the Shop already checked the entitlement; unchanged.

### Troubleshooting (real device, debug build)
Filter logs for `[AdMob]`. Expected happy path:
```
[AdMob] Initializing… (productionIds=false)
[AdMob] Adapter com.google.android.gms.ads.MobileAds: AdapterInitializationState.ready
[AdMob] Initialized — preloading rewarded + interstitial
[AdMob] Banner loading (360x50, unit=ca-app-pub-3940256099942544/6300978111)
[AdMob] Banner loaded
[AdMob] Banner impression
```
A failure prints `code` / `domain` / `message` (e.g. `code=3` = "no fill", `code=2` = network error). "No fill" on test IDs usually means no network or an emulator without Google Play services.

### Still required (external — AdMob / Play Console, not code)
1. Create the AdMob app + 3 ad units; put the real unit IDs in the release `--dart-define`s.
2. Replace the sample **App ID** in `android/app/src/main/AndroidManifest.xml` (`~3347511713`) and `ios/Runner/Info.plist` (`GADApplicationIdentifier`, `~1458002511`) with the real one.
3. Add a UMP consent form (EEA/UK) — `ConsentInformation` / `ConsentForm` flow before `MobileAds.initialize()`.
4. Confirm `minSdkVersion >= 23` (google_mobile_ads 5.x requirement — currently inherited from Flutter's default, which is ≥ 24).

---

## Known Issues

### Core Gameplay
- Artwork collection progression is not fully wired into the game loop

### Ad runtime verification still pending
- The app now compiles (`flutter analyze`: 0 errors; `flutter build appbundle --release` succeeds). A broken uncommitted WIP in `victory_page.dart` — stray `}` after `initState`, missing `flutter/services.dart` import for `HapticFeedback`, and `BounceIn.slideUp` (which does not exist) — was blocking every build; all three were fixed (`BounceIn.slideUp` reverted to the plain `BounceIn(delay:, child:)` it replaced).
- Banner widget logic is covered by unit tests. **The full runtime chain (SDK init → test banner request → `onAdLoaded` → visible `AdWidget` → navigation → dispose) has not yet been checked on a real device / emulator** — do this with a debug build and `adb logcat | grep '\[AdMob\]'`.

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

**Level progression refinement** — the current 7-chapter, 140-level structure is a solid foundation, but could benefit from:
- More mechanical variety (different puzzle shapes, special constraints)
- Better tutorialization in early levels (teach groups more gradually)
- Daily challenge difficulty tuning (currently 60s for 20 pieces may be too tight)
- Consider adding intermediate board sizes between chapters
