# CHANGELOG.md — Chronological Change Log

All notable changes to SuitClash are recorded here. Format follows [Keep a Changelog](https://keepachangelog.com/).

---

## 2026-08-27 (QA Fix: Hint Broken on Grouped Levels + Timer Runs During the Untimed Opening)

`PuzzleCubit` only. No engine, rendering, or UI-widget changes.

### Fixed
- **`useHint()` did nothing on grouped (Hard+) levels.** It computed the group's displacement as `(-avgRow, -avgCol)` — i.e. toward the board's top-left **corner**, not toward the group's actual home cells — and then, if `canMoveGroupByCells()` rejected that (which it almost always did: any group cell above/left of the group's own centroid produced a negative destination row/col → out of bounds, or the corner was occupied), it `return`ed without trying anything else. The coins were already spent by the top bar, so a hint on a grouped level typically did nothing at all. Now it derives the group's true home translation from any member (`(homeCell - cell)` in row/col — valid because a connected group's pieces are always in the correct relative layout), attempts the full jump home, then a single nudge toward home, then the next group; if no group can move it falls through to the solo path (swap a misplaced ungrouped piece straight home, never splitting a group). The Easy/Medium hint path is unchanged in behaviour.
- **The elapsed clock ran during the opening "beginning stage".** `loadLevel()` started the repeating timer immediately, so it ticked through the deal-in animation and while the player was still studying the board. The timer now starts on the **player's first move** (`_ensureTimerStarted()`, called from `_checkSolveAndEmit()` when `movesDelta > 0`), covering both drags and hints. `loadLevel()` resets `_timerStarted` and cancels any stray timer; `setPaused(false)` only resumes the clock if it was already started, so pausing/resuming during the untimed opening does not kick it off early. Victory time is now measured from the first move.

### Why
The grouped hint's "move toward (0,0)" heuristic predates the relative-adjacency model and was never a real path home. Starting the clock before the first interaction penalised players for the intro animation and for planning — a first-move start is the conventional puzzle-game behaviour.

### Corrected
- GAME_DESIGN.md: "Hint System" rewritten to describe the home-directed group hint + solo fallback; new "Elapsed Timer" subsection describing the first-move start.
- `test/features/puzzle/puzzle_cubit_test.dart`: the pause/resume clock test now makes a move first (the clock no longer runs on load); header note updated. `test/features/puzzle/puzzle_page_test.dart`: stale "loaded puzzle starts a Timer" comment corrected.

---

## 2026-08-27 (QA Fix: Connected-Group Move Could Overlap Pieces on Self-Overlapping Moves)

Movement/displacement only. No change to `computeAdjacency()`, `PuzzleGrouping.fromAdjacency()`, image rendering, drag visuals, or completion logic. No locking reintroduced.

### Fixed
- **`canMoveGroupByCells()` validated displaced multi-cell groups against the wrong target set, so a self-overlapping group move could place two pieces on one cell.** It checked that each displaced group cell, shifted by the opposite displacement, landed somewhere in `oldCellSet` (the moving group's *entire* old footprint). When the move distance is smaller than the group's own extent, the old and new footprints overlap, and those overlap cells are re-filled by the moving group itself in `moveGroupByCells()` step 4. A displaced group whose opposite-shift landed on such an overlap cell passed validation, then step 5 wrote it on top of the moving group's tile — the overwritten tile vanished (its vacated source cell stayed `0`), producing a duplicate-looking / inconsistent board. Now the displaced group is checked against `vacatedSet = oldCellSet \ newCellSet` (only the cells the moving group genuinely frees), and each shifted cell is also bounds-checked (`0 ≤ row < rows`, `0 ≤ col < cols`) so an off-board opposite-shift can't alias onto a valid linear index. If any cell of a displaced group fails, the whole move is rejected and the board is left exactly unchanged — a connected group is never split or partially displaced.
- **`moveGroupByCells()` now verifies the candidate arrangement before returning it (atomic all-or-nothing).** After constructing the new board it checks `_isPermutation()` — length unchanged, every tile id `1..N` present exactly once, no `0` cell. If the check fails for any reason, it returns the original `BoardState` unchanged (the cubit already treats an identical arrangement as a rejected move → neutral shake). This is a defensive net on top of the `canMoveGroupByCells()` fix; it guarantees the board can never be emitted in an overlapping / duplicate / missing-tile state.

### Why
Board invariant: one cell holds exactly one piece, and the arrangement is always a permutation of `1..N`. The old displaced-group check was a necessary-but-not-sufficient condition — correct for non-overlapping moves (the common case, still unaffected) but not for a group dragged a short distance across its own footprint while another connected group sat in the destination. Correct absolute position is still never consulted (`arrangement[cell] == cell + 1` appears nowhere in the movement path); the only things that block a move remain board bounds and a multi-cell group whose shifted shape doesn't fit the vacated cells.

### Corrected
- ARCHITECTURE.md "Group Movement Rules": step 3 reworded to say displaced groups must fit the *vacated* cells (`oldCells \ newCells`), not the whole old footprint; added the post-construction permutation check to step 4.

---

## 2026-08-27 (QA Fix: Movement Overwrite — Displaced Solo Tiles Vanished, Solo→Group Split the Group)

Movement/displacement only. No change to `computeAdjacency()`, `PuzzleGrouping.fromAdjacency()`, image rendering, drag visuals, or completion logic. No locking reintroduced.

### Fixed
- **`TileSwapEngine.moveGroupByCells()` step 6 was dead code — displaced solo tiles disappeared.** The loop guarded on `if (newArr[cell] != 0) continue;` for every `cell` in the group's destination cells, but step 4 had already filled *every* destination cell with the moving group's pieces, so the body never ran. Any solo (ungrouped) tile sitting where the group landed was overwritten in step 4 and never relocated — the vacated source cell stayed `0` and the piece was lost, breaking the tile-conservation invariant. Example: `A A B C` with `[A A]` a connected group, drag `[A A]` onto `[B C]` → produced `_ _ A A` (B and C gone) instead of `B C A A`. Step 6 now iterates the genuinely-displaced solo cells (destination cells not re-occupied by the group and not part of a displaced multi-cell group) and places each piece into a vacated source cell — preferring the cell reached by the opposite displacement (so `A A B C` → `B C A A`), otherwise any still-empty vacated cell. The count of displaced solo pieces always equals the count of empty vacated cells, so the arrangement stays a valid permutation.
- **`PuzzleCubit._swapWithGroups()` overwrote a single member of a connected group.** When the dragged (source) cell was a solo tile, it called `TileSwapEngine.swap(arrangement, fromCell, toCell)` unconditionally — even when the *destination* cell belonged to a multi-cell connected group. That swapped the solo tile with exactly one group member, splitting the group (`A A` + drag `B` onto the first `A` → `B A`). Now, when the source is solo and the destination is a connected group, the whole destination group is displaced toward the solo tile's cell via `canMoveGroupByCells()` / `moveGroupByCells()` (the solo tile is shoved into a vacated cell by the step-6 fix above); if the group's shifted shape doesn't fit, the move is rejected and the board is left exactly unchanged (the caller plays the neutral shake). A connected group is never partially replaced.

### Why
Physical-jigsaw invariant: after every successful move the arrangement must remain a permutation of `1..N` — no piece disappears, duplicates, or is overwritten, and a connected group is one rigid object that moves whole or not at all. Both bugs violated this. Correct absolute position is still never consulted for movement (`arrangement[cell] == cell + 1` is not used anywhere in the movement path); the only things that block a move remain board bounds and a multi-cell group whose shifted shape doesn't fit the vacated cells.

### Corrected
- ARCHITECTURE.md "Group Movement Rules": step 4 reworded to describe the working solo-cell bucket-fill; added a note that a solo→connected-group drop displaces the entire destination group (or is rejected), never a single member.

---

## 2026-08-26 (Gameplay Change: Relative Edge Connections, Not Absolute Position)

### Changed
- **`computeAdjacency()` now connects pieces by RELATIVE solved-image adjacency, not absolute board position.** Previously, two board-adjacent cells connected only when `arrangement[cell] == cell + 1` was true for BOTH cells (i.e. both pieces were at their own correct final position). Now, two board-adjacent cells connect whenever the pieces currently sitting in them are each other's solved-image neighbors — evaluated purely from each piece's own solved row/column (`solvedRow(piece) = (piece - 1) ~/ cols`, `solvedCol(piece) = (piece - 1) % cols`) — regardless of whether either piece is anywhere near its own correct cell. A piece can now connect to its solved neighbor the moment the player places them next to each other, anywhere on the board. `arrangement[cell] == cell + 1` is no longer a prerequisite anywhere in `computeAdjacency()`
- **`_BoardCellState`'s snap-pop animation now triggers on a cell's first edge connection, not on reaching its correct absolute position.** Its own doc comment already claimed to fire "when a new adjacency is formed," but the code actually gated on `widget.correct` (absolute position) — under the old absolute-position connection rule these were closely correlated, but under the new relative rule they're fully decoupled, so leaving it keyed on `correct` would have made the primary "pieces click together" feedback moment silent for most of normal play. Now compares `PuzzleAdjacency.hasAnyConnection(cellIndex)` before/after instead

### Why
This is a deliberate game-design shift from "guess the exact coordinate" to "discover which pieces belong together" — the player can now build a partial `A—B—C` chain anywhere on the board (not just at its final destination) and then move the whole chain toward its final spot, same as assembling a physical jigsaw puzzle off to the side of the box lid.

### Explicitly unchanged
Per the request, this was scoped to the connection *criterion* only: `TileSwapEngine` (movement/displacement/`isSolved`), `PuzzleGrouping.fromAdjacency()` (still a pure union-find consumer of whatever `computeAdjacency()` produces), group drag feedback/rendering/scale/shadow/pointer-anchor (from the previous fix), and completion logic are all untouched. Completion still requires the full absolute `arrangement[i] == i + 1` for every cell — connections are a mid-game aid, not a substitute for the win condition.

### Corrected
- `PuzzleAdjacency`, `computeAdjacency()`, `PuzzleGroup`, and `PuzzleLoaded.adjacency` doc comments rewritten to describe the relative rule
- GAME_DESIGN.md: "Connected Edges & Groups" section rewritten with an explicit Edge Match vs. Correct Absolute Position table; "Correctness Feedback" section updated to match
- ARCHITECTURE.md: "How Connections Form," "Group Shuffle," and the Puzzle Group Architecture overview updated; noted that a shuffle can now start with a few connections already present by chance (impossible under the old absolute-position rule)

---

## 2026-08-26 (Group Drag Feedback: Duplicate Look, Pointer Jump, Shadow/Scale)

Presentation-only fixes in `puzzle_board.dart` — no change to `TileSwapEngine`, `PuzzleAdjacency`, `PuzzleGrouping`, or any movement/displacement/completion logic.

### Fixed
- **Group drag looked duplicated.** Each cell in a connected group has its own independent `Draggable` (Flutter has no multi-cell drag primitive) — Flutter's `childWhenDragging` only fades the ONE cell whose own Draggable is active. Dragging B out of a connected `A—B` left A rendering normally at full opacity on the board while the A+B feedback (built from `_buildGroupFeedback`) followed the pointer — looking like a duplicate/leftover A tile beside the real group. Fixed by lifting a `_draggingGroupId` value to `_PuzzleBoardState` (set via each Draggable's `onDragStarted`/`onDragEnd`) and threading it down to every cell: any cell whose group id matches now fades to the same 0.35 opacity regardless of which cell actually started the drag
- **Group feedback jumped away from the grabbed cell.** Draggable's default `childDragAnchorStrategy` maps "where within the grabbed cell you touched" onto the *same fraction* of the `feedback` widget. That's correct when `feedback` and `child` are the same size (individual tile), but wrong for a group: `feedback` is the whole group's bounding box, so the default anchored the pointer near the group's top-left (roughly cell A's position) instead of under whichever cell — e.g. B — was actually grabbed, causing a visible jump the instant the drag started. Fixed with a custom `dragAnchorStrategy` that adds the grabbed cell's own pixel offset within the group's bounding box (from `group.relativePositions`, the same data the movement engine uses) to the local grab point, so the grabbed cell stays exactly under the finger
- **Drag feedback was scaled up and had a drop shadow**, for both individual tiles (`Transform.scale(1.10)` + two `BoxShadow`s) and groups (`Transform.scale(1.08)` + two `BoxShadow`s). Removed both entirely from `feedback:` in both paths — the dragged piece/group is now pixel-identical in size to its on-board appearance; only the pointer-following motion signals it's being moved. (The drop-target hover lift on the *receiving* cell — `_neutralHoverLift()`, a separate, still-neutral-colored affordance — was left untouched; it wasn't part of this bug report.)

### Corrected
- `_buildGroupFeedback()`'s doc comment updated to describe the current (unscaled, unshadowed) behavior and to note it derives directly from `group.cells`/`group.relativePositions` — the same shape data the movement engine consumes, not a re-derived interpretation

---

## 2026-08-26 (QA Audit: Group-vs-Group Displacement Direction Bug)

### Fixed
- **`TileSwapEngine`: displaced-group relocation used the wrong sign.** Both `canMoveGroupByCells()`'s fit check and `moveGroupByCells()`'s placement step computed a displaced group's new position as `cell + (dRow, dCol)` — the SAME direction as the incoming group's own displacement — when it needed to be `cell - (dRow, dCol)`, the OPPOSITE direction, to land the displaced group back in the incoming group's vacated old cells (as the code's own comment, "Place displaced groups at the old position," already said). Traced with concrete coordinates (a 3×3 board, a 1×2 domino sliding down onto a matching domino) — the old formula computed a target cell outside the vacated region in every non-trivial case, so `canMoveGroupByCells()` almost always returned `false` for a legitimate group-vs-group swap. Net effect: dragging one connected group onto another connected group was silently rejected as "invalid" essentially always, even when the shapes matched and the move should have succeeded — a real, reproducible defect, not a hypothetical one. Fixed by negating `dRow`/`dCol` in both the validation check and the execution step (kept mirrored, as they must be)
- Verified conservation (every tile ID appears exactly once, no duplicates, no loss) holds for solo-vs-group, group-vs-group, and mixed group+solo displacement in the same move, by tracing that the fallback bucket-fill for solo cells reads from the untouched `origArr` (never the partially-mutated `newArr`), and that a rigid translation applied to disjoint cell sets can never produce colliding target cells

---

## 2026-08-26 (Gameplay Rule Audit: Correct Position ≠ Locked)

### Fixed
- **`TileSwapEngine.canMoveGroupByCells()` no longer treats a solo correctly-placed cell as an obstacle.** Previously, dragging a connected group onto a target region containing a lone correctly-placed ungrouped tile was silently rejected (`return false`) — a de facto position-lock that contradicted the game's own "no locked cells" rule. Multi-cell correct groups in the way were always displaceable; only a *solo* correct tile was special-cased as immovable. Removed that special case entirely: a solo cell in the way — correct or not — is now always displaced into a vacated cell by `moveGroupByCells()`'s existing solo-cell fallback, exactly as an incorrectly-placed solo cell always was. Verified by conservation argument: the number of cells vacated by the incoming group's move always equals the number of cells needing to be filled, regardless of whether the displaced content is grouped or solo, correct or not — so no capacity/fit check was needed for solo cells (multi-cell groups still get the existing shape-fit check, since a rigid group can legitimately fail to fit)
- `canMoveGroupByCells()` no longer takes an `arrangement` parameter — it was only used by the removed correctness check. Updated both call sites in `PuzzleCubit` (`_swapWithGroups`, `useHint`)

### Corrected
- ARCHITECTURE.md: "Group Movement Rules" rewritten — target cells are no longer described as blocked by a "LOCKED individual cell"; a solo cell is never fit-checked or treated as an obstacle
- Updated stale "locked cell" doc comments in `puzzle_board.dart` and `puzzle_cubit.dart` (both already described the *new* neutral-rejection UI correctly, but referenced "a locked cell" as the example rejection cause — replaced with "a group whose shifted shape doesn't fit")

---

## 2026-08-26 (Image Coverage Fix & Neutral Drop Feedback)

### Fixed
- **Root cause of image gaps/misalignment**: `PuzzleImageTile` independently recomputed its own per-cell size from the image's cover-scaled dimensions (`layout.scaledW / gridCols`), which only coincidentally matched the GridView's actual per-cell size (`boardWidth / cols`, accounting for the piece-style gap). Since the puzzle board fills an `Expanded` area of arbitrary aspect ratio and photos have arbitrary aspect ratios, these two independently-computed cell sizes almost never matched — whichever axis wasn't the cover-limiting one drifted further out of alignment with every row/column, producing exactly the reported right-side gaps, missing image regions, and misaligned adjacent edges
- `ImageLayout` is now the single authority for both the cover-scale AND the per-cell geometry: `sourceRectFor(row, col)` derives each cell's source crop rectangle directly from the board's own `boardW/boardH/cols/rows/gap` — the same inputs the GridView delegate uses — so a tile's source rect always matches the canvas size Flutter actually gives it, regardless of image or board aspect ratio
- `PuzzleImageTile` no longer sizes itself; it fills whatever box the GridView cell gives it and draws `layout.sourceRectFor(row, col)` stretched to that exact size via `drawImageRect`, eliminating the possibility of the two sizes ever diverging again
- Added `FilterQuality.medium` to the tile paint so scaled/dragged pieces render smoothly instead of with nearest-neighbor aliasing

### Changed
- **PuzzleBoard drop-target feedback**: Removed the `AppColors.primary`-tinted border/glow/fill shown on every drag hover (`AppColors.primary` is literally the app's red — this was the "red destination background" reported as a correctness signal). Replaced with `_neutralHoverLift()`: a colorless 1.03x scale + soft black shadow that reads as "a piece can land here" without implying correct/incorrect
- **PuzzleBoard invalid-move feedback**: `PuzzleCubit.swapPieces()` (and the Daily Challenge / Photo Puzzle equivalents) now return `Future<bool>` indicating whether the move was accepted. `_BoardCell._handleDrop()` uses this to trigger the existing (previously unwired) shake animation plus `AudioService().playError()` (haptic + soft error SFX) only when a group move is actually rejected — never a color change
- **PuzzleBoard shake styling**: The shake animation's impact shadow is now a neutral black pulse instead of `AppColors.danger` (which was the same red as `AppColors.primary`)

### Corrected
- ARCHITECTURE.md: `ImageLayout` field list updated to reflect the board-geometry-driven model (`boardW`, `boardH`, `cellW`, `cellH`, `gap`, `sourceRectFor()`) in place of the old image-scale-only fields
- GAME_DESIGN.md: Clarified that correctness feedback (or its absence) extends to drag hover state, not just border/glow color

---

## 2026-08-24 (Visual & Interaction Overhaul)

### Changed
- **PuzzleBoard**: Removed all green correctness visual feedback — no green borders, no green glow, no thicker borders for correct cells. Correctness is now communicated purely through image continuity and snap animation
- **PuzzleBoard**: Border width is now uniform (0.5) for all cells regardless of correctness
- **PuzzleBoard**: Removed purple group border from individual cells in group feedback — group cells render without borders, creating a seamless physical object
- **PuzzleBoard**: Enhanced group drag feedback with layered drop shadow (24px soft + 8px hard) for more realistic physical card feel
- **PuzzleBoard**: Enhanced individual cell drag feedback with layered drop shadow and slightly larger scale (1.10) for better card-lift feel
- **PuzzleBoard**: Removed `_groupBorderColor` constant (no longer used)

### Corrected
- GAME_DESIGN.md: Removed "Locked Cells" section (cells are never locked in current system)
- GAME_DESIGN.md: Updated Hint System to not mention locking (hints place pieces, never lock)
- GAME_DESIGN.md: Updated Combo System description
- AGENTS.md: Added permanent rule that correctness is never communicated through color

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
