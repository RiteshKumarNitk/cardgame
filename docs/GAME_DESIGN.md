# GAME_DESIGN.md — SuitClash Game Concept & Mechanics

## Overview

SuitClash is a **casual mobile jigsaw puzzle game** where players solve photo tile puzzles by swapping shuffled pieces. Each completed puzzle contributes a piece to a larger collection artwork that gradually becomes complete.

It is **NOT** a card game, gambling game, solitaire, or casino game. Card suit symbols (♠♥♦♣) appear only as legacy/background decorative elements and are not part of the core visual identity.

---

## Core Gameplay Loop

```
Home
  ↓
Current Level
  ↓
Jigsaw Puzzle (swap pieces)
  ↓
Complete Puzzle
  ↓
Completion Animation (pieces snap, image revealed, glow/confetti)
  ↓
Collect Artwork Piece
  ↓
Update Collection Artwork
  ↓
Next Level
```

The player is **gradually completing artwork** by solving puzzles. Each completed level contributes a piece to the current collection artwork. When all pieces are collected, the full artwork is revealed. This collection/artwork progression is a core part of the game's identity.

---

## Puzzle Image Rule (HIGH PRIORITY)

**The puzzle image must completely cover the puzzle grid.** There must never be white gaps, empty areas, independently stretched tiles, incorrect cropping, or mismatched tile edges.

### Correct Pipeline

```
Original Image
  ↓
Scale the complete image to cover the board (cover behavior)
  ↓
Create the board-sized image/canvas
  ↓
Crop puzzle pieces from that same scaled image
  ↓
Render pieces
```

### Critical Constraints

- **Never independently scale each puzzle tile.** Each tile must be a crop from the same single scaled image.
- The completed puzzle must reconstruct the original image **seamlessly**.
- Changing difficulty should change the **grid size only**, not the image scaling.
- If tiles are independently scaled, the assembled image will have visible seams and misalignments.

---

## Puzzle Mechanics

### Tile Swapping

Drag one tile onto another to swap their positions. This is the core mechanic for rearranging pieces. Tiles always remain in their original orientation — no rotation is required.

### Correctness Feedback

Correctness is communicated through:
- **Image continuity**: When pieces are correctly placed, the image becomes seamless across adjacent tiles
- **Connected edges**: Shared borders disappear between correctly adjacent cells
- **Snap animation**: A subtle pop animation plays when a piece becomes correctly placed
- **Physical snapping**: Pieces feel like they snap into place

Correctness is **never** communicated through:
- Green borders or glows
- Red borders or glows
- Any color-based feedback
- Drag hover/drop-target color (the destination cell never tints red or green while a piece hovers over it — the hover affordance is a colorless lift + soft shadow, signaling "a piece can land here," not "this is correct")

An invalid move (a group displaced onto a locked cell) is rejected with a neutral physical shake plus a soft error haptic/SFX — never a colored target or border.

### Connected Edges & Groups (Hard+)

On Hard difficulty and above, the board uses **connected edges** — when two adjacent cells are both correctly placed, the shared border between them disappears, visually joining them. Connected cells form a **movable group** that can be dragged as a single unit.

**How connections form:**
- Two adjacent cells are connected when both contain correctly placed pieces
- Connections form dynamically as the player creates correct adjacencies
- Groups grow naturally: piece + piece → group, group + piece → larger group

**CONNECTED ≠ LOCKED:**
- A connected group is one movable puzzle object — it never splits
- All cells are always draggable — no cell is ever locked (until the entire puzzle is solved)
- A group can be repositioned anywhere on the board
- Groups can displace other groups (displacement-based collision)
- The image content inside a group is never independently scaled or distorted
- Groups do not rotate

**Border behavior:**
- Connected edges: shared border is removed (cells appear joined)
- Unconnected edges: normal border is visible
- Example: two correctly adjacent A pieces:
```
A ═ A C D E
A F G H I
```
The border between the two A cells disappears, visually connecting them.

**Example (4×4 grid with connections):**
```
[A] [B] [C] [D]
[E] [F] [G] [H]
[I] [J] [K] [L]
[M] [N] [O] [P]
```
If B and F are correctly adjacent, the border between them disappears:
```
[A]  B ═ F  [C] [D]
[E]  B ═ F  [G] [H]
[I] [J] [K] [L]
[M] [N] [O] [P]
```
B and F are now a connected group. Dragging either B or F moves both.

### Board Shape

The board uses a **portrait orientation** (rows > cols) to match portrait reference photos and make better use of phone screen vertical space.

---

## Difficulty System

Difficulty increases puzzle complexity through multiple dimensions, not just grid size.

**Difficulty tiers:**
- **Easy** — Small grid, individual tiles only, no groups
- **Medium** — Medium grid, individual tiles only, no groups
- **Hard** — Larger grid, introduces connected groups (1×2, 2×1)
- **Expert** — Complex grid, adds 2×2 groups, more complex grouping
- **Master** — Large grid, larger groups (up to 3×2), high visual complexity

Grid dimensions are set per chapter (via `boardCols`). Two levels with the same grid size can have different difficulty based on:

- Connected groups (Hard+): multiple cells move as one unit
- Group shapes and density
- Image complexity
- Shuffle complexity
- Move efficiency requirements
- Section progression role (introduce vs. challenge vs. finale)

---

## Level System

### Chapter Structure

The game is organized into **chapters**, each containing **sections**, each containing exactly **20 levels**.

```
Chapter (themed, e.g., "Nature", "Cities")
  └── Section (exactly 20 levels)
       └── Level (one puzzle to solve)
```

### Chapter Catalog

The game uses a **data-driven chapter catalog**. New chapters are added by appending blueprints — no engine changes needed.

| Chapter | Name | Difficulty | Board |
|---------|------|------------|-------|
| 1       | The Beginning | Easy | 3×4 |
| 2       | Nature | Medium | 5×6 |
| 3       | Cities | Hard | 7×8 |
| 4       | Animals | Expert | 9×10 |
| 5+      | Various themes | Master | 11×12+ |

The catalog has no hard upper bound on total levels. The game supports continuous content expansion by adding new chapter blueprints.

### Level Configuration

Each level is described by a `LevelConfig` — a pure data class carrying all puzzle parameters:

- Grid size (cols × rows)
- Difficulty tier
- Shuffle seed
- Section progression role (introduce, practice, variation, miniChallenge, combine, advanced, challenge, preFinale, finale)

The puzzle engine consumes `LevelConfig` exclusively. It never knows about chapters or sections.

### Level Images

Levels use photographs from `assets/images/images/`. The architecture supports adding new images without changing the puzzle engine.

---

## Artwork Collection System

### Collection Progression

Each chapter has an associated artwork. As the player completes levels within that chapter, they collect pieces of the artwork.

```
Level 1 complete → Collect piece 1 → Artwork partially revealed
Level 2 complete → Collect piece 2 → Artwork more revealed
...
Level N complete → Collect final piece → Full artwork revealed
```

### Artwork Completion

When the final piece is collected:

1. Show the completed artwork prominently in the center
2. Animate the final piece entering the artwork
3. Reveal the complete image
4. Use appropriate glow/sparkle/confetti/reward animations
5. Allow the player to continue to the next chapter

### Home Screen Integration

The Home Screen displays:
- Current collection/artwork (partially or fully revealed)
- Artwork progress (how many pieces collected)
- Current level indicator
- Large green Play/Level button at the bottom center

Secondary features (Daily Challenge, Shop, Profile, Settings, Achievements, Gallery) remain accessible but do not overpower the main Play experience.

---

## Star Rating

Stars are earned based on move efficiency compared to the **minimal swaps** needed (calculated via cycle decomposition):

| Rating | Condition |
|--------|-----------|
| ⭐⭐⭐ | moves ≤ minimalSwaps + 1 |
| ⭐⭐ | moves ≤ 2 × minimalSwaps + 2 |
| ⭐ | All others (1 star minimum) |

---

## Puzzle Mechanics Details

### Shuffle

The initial shuffle uses Fisher-Yates. The shuffle guarantees the puzzle is **never already solved** at start. All pieces remain in their original orientation.

### Combo System

Rapid correct moves within a 3-second window trigger a **combo multiplier** (displayed with a fire icon badge). Correctness is communicated through image continuity and snap animation — never through color.

### Pity Shuffle

If the player makes **6 moves without any correct placement**, a "pity shuffle" option appears, offering to re-randomize the puzzle.

### Hint System

**Cost: 10 coins** (or watch a rewarded ad when coins are insufficient)

A hint:
1. Auto-places one piece in its correct position
2. The piece becomes part of a connected group if adjacent to correctly placed pieces

### Preview

**Cost: 15 coins**

Shows the complete reference image in a bottom sheet so the player can study it.

### Pause

System back button and top-bar back arrow open a **pause menu** instead of exiting:
- Resume
- Restart (re-shuffles the puzzle)
- Give Up (returns to levels)

The timer stops while paused.

---

## Coin Economy

### Earning Coins

| Source | Amount |
|--------|--------|
| Complete level (1 star) | 20 |
| Complete level (2 stars) | 40 |
| Complete level (3 stars) | 60 |
| Combo bonus | Variable |
| Daily reward (streak) | 20-300 |
| Watch rewarded ad | 100 |

### Spending Coins

| Action | Cost |
|--------|------|
| Hint | 10 |
| Preview | 15 |

### Purchasable Coin Packs

| Pack | Coins | Price | Value |
|------|-------|-------|-------|
| Small | 100 | $0.99 | Base |
| Medium | 550 | $3.99 | Best value |
| Large | 1,200 | $7.99 | Premium |

---

## Daily Challenge

- New puzzle each day (same picture all day, different the next)
- Uses internet photos from `picsum.photos` (unbounded supply)
- Fixed Medium difficulty
- Tracks streak (consecutive days completed)
- Leaderboard for fastest completions

---

## Cosmetics

### Board Frames

6 frame styles affecting the puzzle board border and glow:
- Classic, Golden, Royal, Emerald, Midnight, Ruby

### Piece Styles

5 tile styles affecting gaps, corners, and colors:
- Classic, Chips, Golden Glow, Neon, Pastel

### Avatars

11 profile avatars:
- Player, Paw, Heart, Rocket, Music, Star, Smiley, Bolt, Sparkle, Gamer, Gem

Cosmetics are purchased with coins in the Shop.

---

## Monetization

### Ads (AdMob)

- **Rewarded ads** — Watch for 100 coins, or when hint/preview coins insufficient
- **Interstitial ads** — Shown between levels (max 4/day cap)
- **Banner ads** — Displayed on Home screen bottom

### In-App Purchases (RevenueCat)

- Coin packs (3 tiers)
- Remove Ads (one-time purchase, non-consumable)

### Remove Ads

- Purchasable in Shop
- Disables interstitial and banner ads
- Rewarded ads remain available (player's choice)

---

## Completion Flow

When the final piece is placed:

1. Piece snaps into position
2. Puzzle pieces settle
3. Borders fade away
4. Complete image is revealed with glow
5. Camera flash overlay
6. Confetti, fireworks, sparkles
7. Stars animate in (1-3 based on performance)
8. Stats display (time, moves)
9. Coin reward chips fly in
10. Artwork piece collected → Collection artwork updated
11. Chapter/section complete banners (if applicable)
12. Share result as image
13. Interstitial ad (unless ads removed)
14. Navigate to next level, replay, or home
