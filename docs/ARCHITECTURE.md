# ARCHITECTURE.md — SuitClash Technical Architecture

## Overview

SuitClash is built with **Flutter + Flame** using a **feature-first Clean Architecture** pattern with **BLoC (Cubit)** state management.

**Product name:** SuitClash
**Flutter package name:** `puzzle_cards`
**Version:** 1.0.0+1
**Dart SDK:** >=3.9.0 <4.0.0

Note: The Flutter package identifier is `puzzle_cards` (historical). The product/game name is SuitClash. Do not rename the package or application code.

---

## Folder Structure

```
lib/
  main.dart                         ← Entry point
  core/
    app/
      puzzle_cards_app.dart         ← Root widget, global providers
    constants/
      app_constants.dart            ← Hive box names, storage keys
    design_system/                  ← Visual tokens (colors, type, spacing, etc.)
      app_colors.dart
      app_typography.dart
      app_gradients.dart
      app_spacing.dart
      app_shadows.dart
      app_radius.dart
      app_theme_extension.dart
      app_animations.dart
      color_utils.dart
    router/
      app_router.dart               ← GoRouter configuration
      route_paths.dart              ← Route path constants
    theme/
      app_theme.dart                ← Material 3 theme
  features/                         ← Feature modules (15 total)
    achievements/
    collections/
    cosmetics/
    daily_puzzle/
    daily_reward/
    gallery/
    home/
    levels/
    photos/
    profile/
    puzzle/
    settings/
    shop/
    splash/
    victory/
  game/
    ads_cubit.dart
    ads_service.dart
    components/
      floating_puzzle_piece.dart
    floating_pieces_game.dart
    game_progress_manager.dart
    onboarding_service.dart
    wallet_cubit.dart
    wallet_service.dart
  services/
    ad_service.dart
    analytics_service.dart
    app_bootstrap.dart
    audio_manifest.dart
    audio_scene_mapper.dart
    audio_service.dart
    cloud_save_service.dart
    hive_service.dart
    leaderboard_service.dart
    purchase_service.dart
  shared/
    utils/
      context_read_or_null.dart
      duration_format.dart
      number_format.dart
    widgets/                        ← 26 reusable widgets
      ...
```

---

## Feature Module Structure

Each feature follows a consistent internal structure:

```
feature/
  domain/
    entities/                       ← Data classes (Level, Chapter, etc.)
    services/                       ← Business logic (LevelService, ChapterCatalog)
  data/
    datasources/                    ← Local/remote data sources (Hive)
    repositories/                   ← Repository implementations
  presentation/
    bloc/                           ← Cubits and states
    pages/                          ← Screen widgets
    widgets/                        ← Feature-specific widgets
```

---

## State Management

### Cubits (flutter_bloc)

All state management uses **Cubits** (not full Blocs). Cubits expose methods directly rather than processing events.

**Global Cubits** (provided at app root in `puzzle_cards_app.dart`):

| Cubit | Purpose | Data |
|-------|---------|------|
| `WalletCubit` | Coin balance | `int` (coins) |
| `AdsCubit` | Remove-ads entitlement | `bool` |
| `SettingsCubit` | Sound/music toggles + volumes | `AppSettings` |
| `AchievementsCubit` | Milestone tracking | `AchievementsState` |
| `CosmeticsCubit` | Owned/equipped cosmetics | `CosmeticsState` |

**Feature Cubits:**

| Cubit | Feature | Purpose |
|-------|---------|---------|
| `PuzzleCubit` | puzzle | Game state (arrangement, rotations, moves, timer, combo) |
| `LevelsCubit` | levels | Level loading and completion |
| `DailyChallengeCubit` | daily_puzzle | Daily challenge state |
| `PhotoPuzzleCubit` | photos | Photo puzzle state |
| `ProfileCubit` | profile | Player name/avatar |

---

## Routing

### GoRouter

Declarative routing via `go_router` (v17.2.3).

**Configuration:** `lib/core/router/app_router.dart`

**Route paths:** `lib/core/router/route_paths.dart` (single source of truth)

**19 named routes:**
- `/` (Splash), `/home`, `/levels`, `/puzzle/:levelId`, `/victory`
- `/chapter-complete`, `/section-complete`
- `/settings`, `/privacy-policy`
- `/daily-puzzle`, `/leaderboard`
- `/achievements`, `/gallery`, `/shop`
- `/cosmetics`, `/cosmetics/:category`
- `/collections`, `/photo-puzzles`, `/photo-puzzle`, `/profile`

**Transitions:** All routes use a consistent **fade + slight scale** custom transition (320ms, easeOut curve) via `_fadePage()` helper.

---

## Dependency Injection

**Manual DI** — no service locator or GetIt. Dependencies are:

1. **Global providers** — Cubits provided at app root via `MultiBlocProvider`
2. **Feature-scoped providers** — Cubits created in page widgets via `BlocProvider`
3. **Constructor injection** — Services accept repository interfaces; defaults to real implementations
4. **Singletons** — AudioService, AdService, AnalyticsService use singleton pattern

---

## Storage

### Hive

Local persistent storage via Hive (v2.2.3).

**10 Hive boxes:**

| Box Name | Purpose |
|----------|---------|
| `levels_box` | Level progress (completion, stars, best time) |
| `wallet_box` | Coin balance |
| `daily_challenge_box` | Daily challenge streak and history |
| `daily_reward_box` | Daily reward streak |
| `monetization_box` | Remove-ads entitlement |
| `settings_box` | Sound/music settings, tutorial flags |
| `achievements_box` | Achievement progress and unlocks |
| `cosmetics_box` | Owned and equipped cosmetics |
| `photos_box` | Photo puzzle progress |
| `profile_box` | Player display name |

**TypeAdapters:** One generated adapter (`LevelModelAdapter`) via `hive_generator`.

---

## Flame Integration

### Purpose

Flame is used **only for decorative background elements** — NOT for the puzzle board itself.

### FloatingPiecesGame

A `FlameGame` that spawns N decorative puzzle piece silhouettes that drift slowly across the splash/home background. Transparent background, no user interaction.

**Location:** `lib/game/floating_pieces_game.dart`

### FloatingPuzzlePiece

A `PositionComponent` — rounded-square jigsaw silhouette with a single knob. Drifts with velocity, wraps around screen edges, rotates slowly.

**Location:** `lib/game/components/floating_puzzle_piece.dart`

### Integration

The Flame game is embedded in `GameBackground` widget via `GameWidget`, which is used on every screen.

---

## Services Layer

All services are in `lib/services/`.

| Service | Pattern | Purpose |
|---------|---------|---------|
| `HiveService` | Static init | Bootstraps Hive, opens boxes |
| `AudioService` | Singleton | Manifest-driven audio with SFX pool + scene BGM |
| `AudioManifest` | Static | Parses manifest.json for audio paths |
| `AudioSceneMapper` | Static | Maps routes to audio scenes |
| `AdService` | Interface + impl | AdMob rewarded/interstitial/banner |
| `AnalyticsService` | Singleton | Firebase Analytics + Crashlytics facade |
| `PurchaseService` | Interface + impl | RevenueCat IAP facade |
| `CloudSaveService` | Interface + impl | Firestore cloud save |
| `LeaderboardService` | Interface + impl | Firestore leaderboard |
| `AppBootstrap` | Deferred startup | Firebase + RevenueCat + Ads initialization |

### Interface + Implementation Pattern

All data-touching services have an interface and a concrete implementation:

```dart
abstract class WalletService {
  Future<int> getCoins();
  Future<void> setCoins(int amount);
}

class HiveWalletService implements WalletService { ... }
```

This enables testability by allowing fake implementations in tests.

---

## Models & Data Structures

### Level System

| Entity | Location | Fields |
|--------|----------|--------|
| `Level` | `features/levels/domain/entities/level.dart` | id, title, difficulty, stars, isCompleted, isUnlocked, bestTimeSeconds, bestMoves |
| `LevelConfig` | `features/levels/domain/entities/level_config.dart` | levelId, chapterId, sectionId, sectionIndex, levelInSection, difficulty, cols, rows, seed, progressRole |
| `Chapter` | `features/levels/domain/entities/chapter.dart` | id, name, difficulty, boardCols, startLevelId, endLevelId, sections |
| `Section` | `features/levels/domain/entities/section.dart` | id, chapterId, index, startLevelId, endLevelId, progressRole |
| `LevelModel` | `features/levels/data/models/level_model.dart` | Hive-persisted model with generated adapter |

**Data flow:** `ChapterCatalog.levelConfigFor(levelId)` → `LevelConfig` → Puzzle Engine → Puzzle State → UI

The puzzle engine consumes `LevelConfig` exclusively. It never touches `Chapter` or `Section` directly.

### Puzzle System

| Entity | Location | Fields |
|--------|----------|--------|
| `BoardDimensions` | `features/puzzle/domain/puzzle_board_size.dart` | cols, rows |
| `BoardState` | `features/puzzle/domain/tile_swap_engine.dart` | arrangement (List&lt;int&gt;) |
| `PuzzleAdjacency` | `features/puzzle/domain/puzzle_adjacency.dart` | edges, cols, rows |
| `Edge` | `features/puzzle/domain/puzzle_adjacency.dart` | top, right, bottom, left (bitmask enum) |
| `PuzzleGroup` | `features/puzzle/domain/puzzle_group.dart` | id, cells, relativePositions, cols |
| `PuzzleGrouping` | `features/puzzle/domain/puzzle_group.dart` | groups, cols, rows, cellToGroup |
| `ImageLayout` | `features/puzzle/presentation/widgets/puzzle_image_tile.dart` | imgW, imgH, boardW, boardH, cols, rows, gap, scale, scaledW, scaledH, offsetX, offsetY, cellW, cellH, `sourceRectFor(row, col)` |
| `VictoryResult` | `features/victory/domain/entities/victory_result.dart` | level, stars, moves, timeSeconds, coinsEarned, nextLevelId |

**Puzzle Image Pipeline (HIGH PRIORITY):** The puzzle image must completely cover the puzzle grid with no gaps. The correct approach is: load the full image → scale it using cover behavior to fill the board → crop puzzle pieces from that same scaled image. Never independently scale each tile. Changing difficulty changes the grid size only. See `docs/GAME_DESIGN.md` for full details.

`ImageLayout` (built once per board layout pass in `PuzzleBoard`) is the single authority for this: it computes the cover-scale from `boardW/boardH/imgW/imgH`, and `sourceRectFor(row, col)` derives each cell's source crop rectangle from the SAME `boardW/boardH/cols/rows/gap` the GridView delegate uses to size its tiles. `PuzzleImageTile` never computes its own cell size — it fills whatever box the GridView gives it and paints `sourceRectFor(row, col)` stretched to that exact size. This is what guarantees a tile's source rect always matches its actual on-screen size: the board's own per-cell geometry, not the image's independently-scaled dimensions, is the source of truth for where a cell sits.

**Connected Groups (Hard+):** See "Puzzle Group Architecture" section below.

### Cosmetics

| Entity | Location | Fields |
|--------|----------|--------|
| `BoardFrame` | `features/cosmetics/domain/entities/cosmetic_items.dart` | borderColor, borderWidth, glowColor, backgroundColor |
| `PieceStyle` | `features/cosmetics/domain/entities/cosmetic_items.dart` | gap, cornerRadius, tileBackground, borderColors |
| `Avatar` | `features/cosmetics/domain/entities/cosmetic_items.dart` | icon, color |

### Other

| Entity | Location | Purpose |
|--------|----------|---------|
| `AppSettings` | `features/settings/domain/entities/app_settings.dart` | Sound/music toggles + volumes |
| `Achievement` | `features/achievements/domain/entities/achievement.dart` | id, title, description, iconKey, rewardCoins, counterKey, goal |
| `DailyChallenge` | `features/daily_puzzle/domain/entities/daily_challenge.dart` | dateKey, difficulty, streak, alreadyCompletedToday |
| `CoinPack` | `features/shop/domain/entities/coin_pack.dart` | name, coins, price |
| `LeaderboardEntry` | `services/leaderboard_service.dart` | uid, name, score, timestamp |

---

## Firebase Integration

**Anonymous auth** for cloud saves (no user sign-in required).

**Firestore collections:**
- Wallet backup (coin balance)
- Progress backup (star/completion data)
- Leaderboard (time attack scores)

**Firebase Analytics** — 20+ named event constants for tracking.

**Firebase Crashlytics** — Error reporting with safe no-op fallback.

**Configuration:** `docs/firebase_setup.md`

---

## Ad Integration

### Google Mobile Ads (v5.1.0)

| Ad Type | Purpose | Cap |
|---------|---------|-----|
| Rewarded | Watch for 100 coins | Unlimited |
| Interstitial | Between levels | 4/day |
| Banner | Home screen bottom | Always visible |

**Test IDs in dev; real IDs via `--dart-define`:**
- `REWARDED_AD_UNIT_ID_ANDROID`
- `REWARDED_AD_UNIT_ID_IOS`
- `REVENUECAT_ANDROID_KEY`
- `REVENUECAT_IOS_KEY`

**No-op on web** — AdService gracefully degrades.

---

## Audio System

### Manifest-Driven

Audio configuration lives in `assets/audio/manifest.json` — no code changes needed to add/swap sounds.

### Scene-Based BGM

8 audio scenes mapped to routes:
- default, home, levels, puzzle, photo_puzzle, shop, gallery, victory

BGM auto-switches when navigating between screens via `SceneAudioRouter` (watches `GoRouter`).

### SFX Pool

5-player SFX pool for concurrent non-interrupting sounds.

### Volume Mixing

Master × Sfx/Music channel mixing with music ducking for impactful sounds.

---

## Design System

All visual tokens live in `lib/core/design_system/`:

| File | Purpose |
|------|---------|
| `app_colors.dart` | 60+ color constants |
| `app_typography.dart` | Text styles via GoogleFonts |
| `app_gradients.dart` | Gradient presets |
| `app_spacing.dart` | 8px spacing scale |
| `app_shadows.dart` | Shadow presets |
| `app_radius.dart` | Border radius tokens |
| `app_theme_extension.dart` | ThemeExtension for custom tokens |
| `app_animations.dart` | Duration and curve constants |
| `color_utils.dart` | HSL darken/lighten extensions |

---

## Puzzle Group Architecture

### Overview

SuitClash uses **connected-edge adjacency** for Hard/Expert/Master difficulties. When the pieces currently sitting in two board-adjacent cells are each other's neighbors in the solved image, the shared border between them disappears, and the cells form a **connected group** that moves as one unit. This is a RELATIVE relationship (edge match) — it never requires either piece to be at its own correct absolute board position. Groups form dynamically from these edge matches — they are NOT pre-defined.

### Key Concepts

**Atomic Grid**: The image is always divided into atomic grid cells (e.g., 8×10 = 80 cells). Each cell is a crop from the same shared scaled image. The atomic grid is the source of truth for image rendering.

**PuzzleAdjacency**: Edge-level connection state. For every cell, determines which of its four edges (top, right, bottom, left) are connected to a currently-adjacent solved-image neighbor. Two board-adjacent cells are connected when the PIECES currently sitting in them are each other's solved-image neighbors — a relative relationship evaluated from each piece's own solved row/column, independent of whether either piece is at its own correct absolute board position.

**PuzzleGroup**: A connected group of cells that move together as one unit. Groups form dynamically from adjacency connections using union-find. **CONNECTED ≠ LOCKED** — a group is fully movable at all times until the puzzle is ultimately solved.

**PuzzleGrouping**: Contains all groups and provides cell-to-group lookup. Rebuilt from scratch after every move using `PuzzleGrouping.fromAdjacency()`.

### Files

| File | Purpose |
|------|---------|
| `lib/features/puzzle/domain/puzzle_adjacency.dart` | `PuzzleAdjacency` (edge-level connections), `Edge` enum, `computeAdjacency()` |
| `lib/features/puzzle/domain/puzzle_group.dart` | `PuzzleGroup` (dynamic cell set), `PuzzleGrouping` (fromAdjacency, cell map) |
| `lib/features/puzzle/domain/tile_swap_engine.dart` | `moveGroupByCells()`, `canMoveGroupByCells()`, `swap()`, `isSolved()` |

### How Connections Form

**Edge match ≠ correct absolute position.** These are two separate concepts and the code never conflates them:

1. After every move, `computeAdjacency()` checks all board-adjacent cell pairs.
2. Two cells are connected when the pieces currently in them are solved-image neighbors — for a horizontal pair, `solvedRow(rightPiece) == solvedRow(leftPiece) && solvedCol(rightPiece) == solvedCol(leftPiece) + 1` (mirrored for vertical pairs), where `solvedRow`/`solvedCol` are derived purely from each piece's own index (`piece - 1`). This is **NOT** `arrangement[cell] == cell + 1` — a piece does not need to be at its own correct absolute board position to connect to its solved neighbor.
3. Connected edges have their shared border removed visually.
4. `PuzzleGrouping.fromAdjacency()` uses union-find to compute connected components — unchanged by the above; it only consumes whatever `computeAdjacency()` produces.
5. Multi-cell components become groups. Single cells remain ungrouped.
6. Because this is recomputed from scratch after every move, a connection is never "remembered" — if a move separates two previously-adjacent solved-neighbor pieces, the connection simply doesn't exist in the next recomputation.

### Group Movement Rules

1. Find which group the source cell belongs to.
2. Compute displacement: the row/col difference from source cell to target cell.
3. Validate with `canMoveGroupByCells()`:
   - Bounds check: all cells must be within the board.
   - Target cells belonging to a multi-cell group: that group must fit entirely within the vacated old cells once shifted by the same displacement — those groups will be displaced there.
   - A solo (ungrouped) target cell — correct or not — is never an obstacle. It is not fit-checked; it is simply displaced into a vacated cell by `moveGroupByCells()`'s solo-cell relocation (step 6), exactly like an incorrectly-placed solo cell always was.
4. Execute with `moveGroupByCells()`: clear old cells, place group at new position, displace other multi-cell groups to the old position, then relocate every displaced solo piece into a vacated old cell — preferring the cell reached by the opposite displacement (so `[A A]` dragged onto solo `[B C]` gives `[B C A A]`), otherwise any still-empty vacated cell. The number of displaced solo pieces always equals the number of empty vacated cells, so the arrangement stays a valid permutation of `1..N` — no piece is ever lost or overwritten.
5. After the move, adjacency and groups are recomputed.

**Solo tile dropped onto a connected group:** a connected group is one physical object. `PuzzleCubit._swapWithGroups()` never swaps a solo tile with a single group member — when the source cell is solo and the destination cell belongs to a multi-cell group, the entire destination group is displaced toward the solo tile's cell (validated by `canMoveGroupByCells()`), or the move is rejected and the board is left exactly unchanged. The group is never split or partially replaced.

**CORRECT POSITION ≠ LOCKED. CONNECTED ≠ LOCKED:**
- All cells are always draggable — no cell is ever locked until the puzzle is solved.
- A single tile sitting in its correct position but with no matched edge is exactly as movable as any other tile — being correctly placed does not lock it, whether the player drags it directly or a group is dragged onto it.
- A connected group is fully movable at all times.
- Groups can be repositioned anywhere on the board.
- The only thing that can block a move is the board's bounds, or a multi-cell group whose shifted shape doesn't fit the vacated cells — never a cell's own correctness.
- Groups never split, never rotate, never independently scale.

### Group Shuffle

All levels use the same shuffling: pieces start in random positions (Fisher-Yates). Groups form dynamically from solved-neighbor edge matches that happen to exist in the shuffled arrangement — since this no longer requires either piece to be at its correct absolute position, it's common (and expected) for a shuffle to start with a few small connections already present purely by chance, especially on larger boards. There is no pre-generation of groups.

### Image Rendering

Groups do NOT affect image rendering. The image pipeline remains:
1. Cover-scale the image to the board.
2. Each atomic cell crops from the shared scaled image.
3. `PuzzleImageTile` renders each cell using `CustomPaint`.

### PuzzleBoard Group UI

`PuzzleBoard` accepts `PuzzleAdjacency?` and `PuzzleGrouping?` parameters.

**Visual Indicators:**
- Per-edge border rendering: connected edges have no border, unconnected edges show the normal (idle-colored, never green/red) border.
- The `correct` flag (pieceIndex == cellIndex + 1) drives the pop-scale snap animation only — never a color.

**Drag Behavior:**
- All cells are always draggable — no cell is ever locked.
- When dragging a group cell, the feedback shows the entire group's real shape (`_buildGroupFeedback()`, built from `group.cells`/`group.relativePositions`) with all cells and their image content — never a single-tile screenshot.
- Group feedback is rendered at the exact same size as the group's on-board footprint — no scale, no shadow. Every cell belonging to the dragged group fades on the board (via a `draggingGroupId` value lifted to `_PuzzleBoardState`), not just the cell whose own `Draggable` is active, so the group never appears to leave a "duplicate" tile behind.
- A custom `dragAnchorStrategy` keeps the actually-grabbed cell under the pointer (Flutter's default anchor strategy would otherwise anchor near the group's top-left corner, since the feedback widget is larger than the single cell that started the drag).

### Backward Compatibility

- `BoardState` remains `({List<int> arrangement})` — unchanged.
- Easy/Medium levels: no adjacency connections, all existing behavior is preserved.
- `PuzzleCubit.swapPieces()` delegates to `TileSwapEngine.swap()` when no groups are present.
- `PuzzleCubit.swapPieces()` uses displacement-based group movement when groups are present.

| Decision | Rationale |
|---|---|
| Cubits over full Bloc | Simpler for game state; direct method calls preferred |
| GoRouter | Declarative routing with consistent transitions |
| Hive | Lightweight local storage; no native dependencies |
| Flame (background only) | Decorative pieces only; puzzle board is pure Flutter |
| GridView puzzle board | Standard Flutter widgets for accessibility |
| GoogleFonts over bundled fonts | Dynamic loading; Baloo2/Nunito declared but unused |
| Single light theme | Bright, colorful casual game aesthetic; intentional |
| Interface + Implementation | All services/repositories testable via fakes |
| Feature-first structure | Clear boundaries; each feature self-contained |
| Manifest-driven audio | No code changes needed for audio swaps |
| LevelConfig-driven puzzle engine | Engine receives pure data class; never touches Chapter/Section |
| Data-driven content architecture | Chapters/sections/levels added by appending blueprints; no engine changes needed |
