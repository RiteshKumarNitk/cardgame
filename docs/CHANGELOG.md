# CHANGELOG.md — Chronological Change Log

All notable changes to SuitClash are recorded here. Format follows [Keep a Changelog](https://keepachangelog.com/).

---

## 2026-08-24 (Connected-Edge Adjacency Mechanic)

### Added
- `PuzzleAdjacency` domain model (`puzzle_adjacency.dart`) — edge-level connection state for every cell, determining which edges are connected to correctly adjacent neighbors
- `Edge` enum with bitmask values (top, right, bottom, left) for compact per-cell edge storage
- `computeAdjacency()` — computes which edges are connected based on current arrangement
- `PuzzleGrouping.fromAdjacency()` — dynamically forms groups from adjacency connections using union-find
- `TileSwapEngine.canMoveGroupByCells()` — displacement-based group movement validation
- `TileSwapEngine.moveGroupByCells()` — moves groups by cell displacement with displaced-group handling
- `PuzzleBoard._edgeBorder()` — per-edge border rendering that hides borders on connected edges
- `PuzzleLoaded.adjacency` — carries adjacency state in puzzle state

### Changed
- **PuzzleGroup rewritten**: No more anchor/shape. Groups are dynamic sets of cells with relative positions, formed from correct adjacencies
- **PuzzleGrouping rewritten**: `fromAdjacency()` uses union-find to compute connected components from adjacency graph
- **TileSwapEngine rewritten**: Removed `isCellLocked()`, `isGroupLocked()`, `isGroupAtHome()`. Added `canMoveGroupByCells()` and `moveGroupByCells()`
- **PuzzleCubit rewritten**: Computes adjacency and rebuilds groups after every move. Tracks "new connections" instead of "locked cells" for combo/progress. `useHint()` moves first incomplete group toward home
- **PuzzleBoard rewritten**: Renders per-edge borders based on adjacency state. Connected edges have no border, unconnected edges show normal border. All cells are always draggable
- **PuzzleState updated**: `PuzzleLoaded` carries `adjacency` field. Progress tracked by connection count, not locked cells

### Removed
- `isCellLocked()` from TileSwapEngine (no more cell locking)
- `isGroupLocked()` from TileSwapEngine (groups are never locked)
- `isGroupAtHome()` from TileSwapEngine (replaced by checking arrangement directly)
- `PuzzleGroupGenerator` (groups are now dynamic, not pre-generated)
- Lock-based error shake from `_BoardCell` (all cells are always draggable)
- `shuffledArrangementWithGroups()` (groups form dynamically, no pre-placement needed)

### Fixed
- All cells are always draggable — no cell is ever locked until the entire puzzle is solved
- Connected edges visually remove shared borders between correctly adjacent cells
- Groups form dynamically as correct adjacencies are created
- Groups remain movable at all times — dragging any cell in a group moves the entire group
- Group movement preserves internal connections and relative positions

---

## 2026-08-24 (Connected Group UI)

### Added
- `PuzzleBoard.grouping` — accepts `PuzzleGrouping?` for group-aware rendering
- `_BoardCell` group detection — cells in connected groups get visual indicators and group-shaped drag feedback
- `_BoardCell._buildGroupFeedback()` — renders entire group as drag preview with image content for each cell
- `_BoardCell._groupBorderColor` — subtle purple border distinguishes group cells from individual tiles
- Group-aware semantics — screen readers announce "connected group" for group cells

### Changed
- **PuzzleBoard**: Now passes `grouping` and `arrangement` to each `_BoardCell`
- **_BoardCell.build()**: Three-way branch — solved (locked), group cell (group drag), individual cell (standard drag)
- **puzzle_page.dart**: Passes `state.grouping` to `PuzzleBoard`

---

## 2026-08-24 (Connected Group Movement Fix)

### Fixed
- `canMoveGroup()`: Groups can now move to positions occupied by other movable groups (previously rejected as "locked")
- `canMoveGroup()`: Removed same-size-swap restriction — any group that fits in the old position can be displaced (previously required identical size and shape)
- `canMoveGroup()`: Only individual ungrouped locked cells block movement; group-occupied cells are treated as movable

### Corrected
- ARCHITECTURE.md: Added "CONNECTED ≠ LOCKED" to PuzzleGroup description; updated Group Movement Rules
- GAME_DESIGN.md: Clarified connected groups — groups are fully movable until solved, can displace any group that fits
- PuzzleGroup doc comments: Clarified that connected groups are movable puzzle objects, not locked

---

## 2026-08-24 (Level Architecture)

### Added
- `LevelConfig` domain model (`level_config.dart`) — pure data class carrying all puzzle parameters (grid, difficulty, seed, progression role)
- `SectionProgressRole` enum — 9 roles defining a section's 20-level progression arc (introduce, practice, variation, miniChallenge, combine, advanced, challenge, preFinale, finale)
- `ChapterCatalog.levelConfigFor(levelId)` — builds LevelConfig from level position in catalog
- `boardDimensionsFromConfig(LevelConfig)` — preferred way to get board dimensions for chaptered levels
- `PuzzleLoaded.config` — carries LevelConfig in puzzle state

### Changed
- **ChapterCatalog rewritten**: Every section now contains exactly 20 levels. New chapters added by appending `_ChapterBlueprint` entries. No hard upper bound on total levels.
- **Section entity updated**: Now carries `progressionRole` field
- **PuzzleCubit refactored**: `loadLevel()` builds LevelConfig from ChapterCatalog and uses it for all puzzle parameters. Engine never touches Chapter/Section directly.
- **puzzle_page.dart updated**: Uses `boardDimensionsFromConfig(state.config)` instead of `boardDimensionsForLevel(level.id)`

### Removed
- `_minimumTotalLevels = 1080` hard limit from ChapterCatalog
- `_continuationBlueprint()` procedural generation (replaced by explicit blueprints)
- `_cycleSuffix()` for continuation chapter naming
- `_sectionLevelCounts` variable-length sections (all sections now 20 levels)

### Corrected
- GAME_DESIGN.md: Removed "1,080+ levels" and "300 bundled photographs" as fixed limits
- GAME_DESIGN.md: Fixed connected groups rules (displacement-based, not same-size swap)
- GAME_DESIGN.md: Removed rotation references
- GAME_DESIGN.md: Updated difficulty to emphasize multi-dimensional complexity
- ARCHITECTURE.md: Added LevelConfig to Level System table
- ARCHITECTURE.md: Updated PuzzleGroup/PuzzleGrouping field descriptions
- ARCHITECTURE.md: Replaced "300 cycled photos" decision with LevelConfig-driven architecture
- AGENTS.md: Updated architecture overview with LevelConfig data flow

---

### Added
- AGENTS.md — permanent instructions for AI agents
- docs/GAME_DESIGN.md — game concept and mechanics documentation
- docs/UI_UX_GUIDELINES.md — visual language, colors, typography, components
- docs/ARCHITECTURE.md — technical architecture documentation
- docs/GAME_PROGRESS.md — current project state tracking
- docs/CHANGELOG.md — this file
- docs/TODO.md — prioritized backlog

### Removed
- Tile rotation mechanic from puzzle gameplay (swap-only)
- Rotation state from PuzzleLoaded, TileSwapEngine, PuzzleBoard
- "Tap to rotate" from tutorial overlay
- Rotation-based difficulty scaling

### Corrected
- Removed casino/felt/card-game identity from all documentation
- Documented artwork collection as core gameplay loop
- Added puzzle image rule as high priority constraint (cover-scale-then-crop)
- Clarified legacy status of card suit symbols (background decorative elements only)
- Corrected Home Screen documentation to focus on collection artwork + Play button
- Removed "feature-complete" claim — project is advanced but polish ongoing
- Clarified branding: package name `puzzle_cards`, product name SuitClash

### Fixed
- Puzzle image pipeline: board now resolves image intrinsic dimensions once and computes cover-scale layout centrally (was per-tile BoxFit.cover)
- Removed stale rotation references from DailyChallengeCubit, PhotoPuzzleCubit, and their tests

### Added
- Connected puzzle group architecture for Hard/Expert/Master difficulties
- `PuzzleGroup` and `PuzzleGrouping` domain models (`puzzle_group.dart`)
- `PuzzleGroupGenerator` — deterministic group generation from level seed
- `TileSwapEngine.moveGroup()` — general group movement to any valid board position
- `TileSwapEngine.canMoveGroup()` — move validation (bounds, locked cells, overlap)
- `TileSwapEngine.shuffledArrangementWithGroups()` — group-aware shuffling
- `PuzzleLoaded.grouping` field — carries group definitions in game state
- `PuzzleCubit` now generates groups for Hard+ levels on load
- `PuzzleCubit._swapWithGroups()` — displacement-based group movement in swapPieces
- `PuzzleCubit.useHint()` — group-aware hint (moves first unlocked group home)

---

## Prior Changes (before documentation setup)

The following features were implemented before this documentation session. They are listed here for completeness but the exact dates are not recorded.

### Core Systems
- Flutter project created with package name `puzzle_cards`
- Flame integrated for decorative background floating pieces
- GoRouter routing with 19 named routes and consistent fade+scale transitions
- Hive local storage with 10 boxes and generated LevelModel adapter
- Design system: colors, typography, spacing, shadows, gradients, animations, theme extension
- Single light theme with bright, colorful casual game aesthetic

### Gameplay
- Puzzle board with GridView, drag-to-swap, tap-to-rotate mechanics
- TileSwapEngine with Fisher-Yates shuffle, lock detection, cycle-based minimal swaps
- Portrait-oriented boards (rows > cols) for phone screen optimization
- Star rating system (3 tiers based on move efficiency)
- Combo system (rapid correct moves within 3s window)
- Pity shuffle (after 6 stalled moves)
- Hint system (auto-places + fixes rotation, 10 coins)
- Preview system (shows reference image, 15 coins)
- Pause menu (resume, restart, give up)
- Tutorial overlay (first-time how-to-play)

### Progression
- Chapter catalog with 1,080+ levels across 20+ themed chapters
- Journey Map with chapter banners, winding path, level nodes
- Chapter and section complete celebration screens
- Collections showcase with chapter hero cards
- Gallery grid showing all levels (completed vs locked)

### Monetization
- AdMob integration (rewarded, interstitial, banner)
- RevenueCat IAP (3 coin packs, remove ads)
- Coin economy (earn from levels, spend on hints/previews)

### Social & Cloud
- Firebase anonymous auth
- Firestore cloud save (wallet + progress backup)
- Firebase Analytics + Crashlytics
- Leaderboard (time attack scores)
- Share result as image

### Features
- Daily challenge (daily puzzle, streak, leaderboard)
- Daily reward (7-day streak, 20-300 coins)
- Achievements (9 counter-based achievements)
- Cosmetics (6 frames, 5 piece styles, 11 avatars)
- Shop (coin packs, watch-ad-for-coins, remove ads)
- Settings (audio toggles, volume sliders, reset, restore)
- Profile (display name, avatar)
- Photo puzzles (manifest-driven)
- Audio system (manifest-driven, scene-based BGM, SFX pool, ducking)
- 26 shared widgets (buttons, cards, animations, effects)
- Game background (gradient + glow + floating pieces)
- Onboarding service

### Tools
- Artwork generation tool (16 themed PNG paintings)
- Audio placeholder generation tool
- Image download tool (300 photos from picsum.photos)
