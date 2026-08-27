# CHANGELOG.md — Chronological Change Log

All notable changes to SuitClash are recorded here. Format follows [Keep a Changelog](https://keepachangelog.com/).

---

## 2026-08-27 (QA Fix: Destination Groups Were Protected as Rigid, Unsplittable Blocks)

`TileSwapEngine` only (`canMoveGroupByCells()`, `moveGroupByCells()`). No cubit, rendering, or drag-visual changes.

### Fixed
- **A group sitting at a move's destination could never actually split, even when the resulting board should no longer keep it connected.** `canMoveGroupByCells()` required the FULL component of every displaced multi-cell group to fit, as one rigid block, inside the cells the mover vacated (`_displacedShift` applied once per group) — rejecting the whole move otherwise. Since a rigid translation preserves a group's internal relative offsets, whenever a move *did* succeed the displaced group's shape (and therefore its adjacency) was mechanically guaranteed to reform — functionally indistinguishable from the group's old connection being "remembered," even though adjacency itself was always recomputed fresh. Solo displaced tiles never had this problem (they already bucket-filled into any vacated cell), but grouped destination content was treated as a protected, all-or-nothing unit.
- **`canMoveGroupByCells()` now only validates the MOVING group's own bounds** — every one of its cells, shifted by `(dRow, dCol)`, must land on the board. That's the only real constraint. **`moveGroupByCells()` now displaces destination content per CELL, not per group**: only the specific cells the mover actually lands on are cleared and relocated (preferring the `_displacedShift` cell, otherwise any remaining vacated cell); any other members of a destination group are left completely untouched. The vacated-cell count always exactly equals the displaced-piece count (same-size old/new cell sets), so a displacement can never fail to find every piece a home — this is no longer a possible rejection reason at all.

### Why
Groups must be a pure function of the current arrangement, never preserved objects (see AGENTS.md / ARCHITECTURE.md "Puzzle Group Architecture"). Requiring a destination group to move as one rigid block — or reject the whole move — was quietly re-introducing group permanence through the back door: a group could displace, but only ever as its old, intact self. Now a destination group can be displaced, split into smaller groups, or scattered into solo tiles depending purely on where the dragged group actually lands; adjacency and grouping are recomputed from scratch afterward exactly as before, and that recomputation is what decides the outcome, not the group's prior shape. The direct group⇄group same-shape swap is unaffected — that path is a deliberate exchange between two groups, not a collision.

### Corrected
- ARCHITECTURE.md "Group Movement Rules" (displacement path rewritten around per-cell relocation) and "CORRECT POSITION ≠ LOCKED" bullets.
- GAME_DESIGN.md "Connected Edges & Groups" and the invalid-move description under "Correctness Feedback".

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

## 2026-08-27 (Feature: Direct Group ⇄ Group Atomic Swap)

`TileSwapEngine` + `PuzzleCubit._swapWithGroups()` only. No engine rewrite, no rendering / drag-visual changes. No locking, no correctness checks.

### Added
- **`TileSwapEngine.groupsShareShape(a, b)`** — true when two connected groups have the same cell count and the same set of bounding-box-relative cell offsets (via each group's precomputed `relativePositions`). Pure geometry: no board dimensions, no absolute coordinates, no group-size threshold; records compare structurally so the `Set<(int,int)>` check is value-based. A 2-cell domino and a 7-cell blob run the identical comparison.
- **`TileSwapEngine.swapGroups(state, a, b)`** — atomically exchanges the board contents of two shape-compatible connected groups. Each cell of `a` trades contents with the cell of `b` at the same normalized offset, so both groups keep their exact internal arrangement (and edge connections) and simply change places; nothing else on the board moves. No displacement vector, no sign, no bounds math — a bijection between two equal-shaped, disjoint cell sets — so it is identical for left⇄right, right⇄left, top⇄bottom, bottom⇄top and on any board size. Whole candidate computed first, `_isPermutation`-gated, then committed once; returns the board unchanged on any mismatch.

### Changed
- **`PuzzleCubit._swapWithGroups()`** now resolves the full source and destination components up front and has three explicit branches: (1) **group → group of the same shape → `swapGroups`** (direct exchange); (2) group → anything else (solo, or a shape-incompatible group) → the existing generic displacement path (`canMoveGroupByCells` / `moveGroupByCells`), which displaces or rejects cleanly; (3) solo → group → displace the destination group toward the solo; (4) solo → solo → plain `TileSwapEngine.swap`. The group→group swap is decided from the two **full connected components**, not the single drop cell, so grabbing any member of one group and dropping on any member of the other performs the same clean exchange — no partial-overlap, no split, no dropped/duplicated tiles.

### Why
The generic displacement algorithm (previous entry) is correct but, for two equal-shaped groups dropped onto each other, it only succeeds when the inverse-translated destination group lands exactly in the moving group's vacated cells — which fails for many drop positions (e.g. grabbing the trailing cell of `A A` and dropping on the leading cell of `B B`). A same-shape group pair exchanging places is unambiguous and always valid, so it now has its own path. Shape-incompatible pairs still go through the geometric displacement logic and are rejected cleanly when no valid arrangement exists. Groups remain fully movable after the swap — adjacency and grouping are rebuilt from the resulting arrangement as after any move.

### Corrected
- ARCHITECTURE.md "Group Movement Rules" and GAME_DESIGN.md "Connected Edges & Groups" note the group⇄group swap branch.

---

## 2026-08-27 (QA Fix: Group→Group Displacement Rejected Valid Short Moves — Generic Translation)

`TileSwapEngine` only. No engine rewrite, no rendering / drag-visual / cubit changes. Direction- and size-agnostic; the previous no-overlap guarantee is preserved.

### Fixed
- **A connected group dragged onto another connected group was rejected whenever the move was shorter than the moving group's own extent along that axis** — regardless of board size, group size, group shape, or direction (it was just most visible with larger groups nudged a short way "up"). `canMoveGroupByCells()` / `moveGroupByCells()` displaced other groups by the *plain inverse* translation `(-dRow, -dCol)`. That inverse is only geometrically correct when source and destination footprints **don't overlap** (`|delta| ≥ moverExtent`). For a shorter move the footprints overlap, and `-delta` lands the displaced group back on cells the moving group re-occupies — which `vacatedSet` (`oldCells \ newCells`) correctly excludes — so the move was rejected even though the displaced group would sit perfectly in the vacated slab a little further along. Solo tiles never hit this because they bucket-fill *any* free vacated cell, not a fixed offset.
- **New generic displacement translation** — `_displacedShift(dRow, dCol, moverHeight, moverWidth)`: per axis, `-sign(delta) * max(|delta|, moverExtent)`. `max(...)` picks `-delta` for non-overlapping moves (unchanged behaviour) and stretches to the moving group's full bounding-box extent for overlapping ones (landing displaced content in the trailing vacated slab). `sign(...)` makes it identical for up/down, left/right, and negative/positive deltas — the direction falls out of the math, no `if (movingUp)` branch. It reads only cell coordinates via `_extentOf()` (min/max bounding box, works for rectangle / L / T / cross / any connected component), so there is no condition on group size, group shape, or board dimensions. `moveGroupByCells()` steps 5 and 6 apply the exact same shift the validator checked.
- Multiple affected groups in one move are all displaced by that single shared vector — disjoint components stay disjoint, each is verified to land entirely inside `vacatedSet`, and the leftover vacated cells exactly match the displaced-solo count. `_isPermutation()` remains the final atomic all-or-nothing gate.

### Why
The movement contract is "allow every move that yields a valid board state under the rigid-displacement rules; reject only those that genuinely can't." The old fixed `-delta` was a special case of the correct rule that silently failed on the overlap regime. Moves that still can't produce a valid rigid arrangement (displaced group larger than the freed slab, an irregular shape that only fits under rotation, a cell pushed off-board) are still rejected cleanly with the board untouched.

### Corrected
- ARCHITECTURE.md "Group Movement Rules": step 3/4 reworded around the generic stretched-inverse translation and `_displacedShift` / `_extentOf`.

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
