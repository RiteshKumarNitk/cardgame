# AGENTS.md — Permanent Instructions for AI Agents

## Project Identity

**SuitClash** (Flutter package name: `puzzle_cards`) is a **casual mobile jigsaw puzzle game** built with Flutter + Flame.

It is **NOT**:
- A card game
- A solitaire game
- A casino game
- A gambling game
- A card-based game

The "suit" in SuitClash refers to decorative card suit symbols (♠♥♦♣) that currently appear as **legacy/background visual elements**. These may be replaced or removed during visual refinement. They are **not** part of the core visual identity.

### Core Experience

```
Home
  ↓
Current Level
  ↓
Jigsaw Puzzle (swap pieces)
  ↓
Complete Puzzle
  ↓
Completion Animation
  ↓
Collect Artwork Piece
  ↓
Update Collection Artwork
  ↓
Next Level
```

The player is **gradually completing artwork** by solving puzzles. Each completed level contributes a piece to the current collection artwork. The collection/artwork progression is a core part of the game's identity.

---

## IMPORTANT: Current Gameplay Rule

There is **no "locked cell" mechanic** in the current puzzle system.

Historical references to locked cells in CHANGELOG.md are historical only.

Current gameplay uses:
- **Connected edges** — when two board-adjacent cells hold pieces that are each other's neighbors in the SOLVED image, the shared border is removed. This is a RELATIVE relationship (edge match), evaluated from each piece's own solved row/column — it is never conditioned on either piece being at its own correct absolute board position (`arrangement[cell] == cell + 1` is not a prerequisite for a connection to form)
- **Dynamically formed movable groups** — connected cells form groups that move as one unit
- **Edge-level border removal** — visual connection between two currently-adjacent solved-image-neighbor pieces, wherever on the board that happens

A correctly positioned tile is **NOT** locked.
A correctly connected group is **NOT** locked.
A tile or group does **NOT** need to be at its correct absolute position to become connected — two pieces that belong together connect the moment they're placed next to each other, anywhere on the board.
All pieces remain movable until the puzzle is completely solved.

Do **NOT** implement, reference, or re-introduce any form of cell locking. Do **NOT** treat `arrangement[cell] == cell + 1` as a reason to prevent movement. The only locked state is when the entire puzzle is solved.

---

## Development Philosophy

- **Build incrementally.** Do not rewrite working systems unnecessarily.
- **Do not modify unrelated features.** Stay focused on the task.
- **Keep UI and game logic separated.** Presentation in `presentation/`, domain in `domain/`, data in `data/`.
- **Prefer reusable components.** Shared widgets live in `lib/shared/widgets/`.
- **Preserve existing architecture** unless there is a strong reason to change it.
- **Make small focused changes.** One milestone at a time.
- **Do not create huge implementation queues.** Prioritize the single most important next task.
- **I will perform testing manually.** Do not run `flutter test` unless asked.
- **Document everything.** Keep documentation synchronized with code.

---

## Important Rule: Before Modifying Code

1. **Read `AGENTS.md`** (this file).
2. **Read the relevant documentation in `docs/`.**
3. **Inspect the existing implementation** using the search/read tools.
4. **Understand dependencies** — what imports what, what calls what.
5. **Make the smallest appropriate change.** Do not refactor broadly.

---

## Important Rule: After Modifying Code

1. **Update the relevant documentation** in `docs/`.
2. **Update `docs/GAME_PROGRESS.md`** if a feature was added/completed.
3. **Update `docs/CHANGELOG.md`** with a meaningful entry.
4. **Update `docs/TODO.md`** if the task status changed.

**Never leave the documentation describing an outdated implementation.**

---

## Key Technical Decisions

| Decision | Rationale |
|---|---|
| Cubits (not full Bloc) | Simpler for game state; direct method calls preferred over events |
| GoRouter | Declarative routing with consistent page transitions |
| Hive | Lightweight local storage; no native dependencies |
| Flame (background only) | Floating decorative pieces; NOT the puzzle board itself |
| GridView puzzle board | Standard Flutter widgets for accessibility and simplicity |
| Cover-scale-then-crop image pipeline | Puzzle image must cover the board with no gaps; never independently scale tiles (HIGH PRIORITY) |
| LevelConfig-driven puzzle engine | Engine receives pure data class; never touches Chapter/Section directly |
| Connected puzzle groups (Hard+) | Dynamic adjacency-based formation: RELATIVE solved-image-neighbor adjacencies create connections (never absolute position), removing shared borders; connected cells form movable groups; groups never lock, split, or rotate; rebuilt from adjacency after every move |
| Data-driven content architecture | Chapters/sections/levels added by appending blueprints; no engine changes needed |
| GoogleFonts (not bundled fonts) | Baloo2.ttf/Nunito.ttf are declared but typography uses Quicksand/Roboto via GoogleFonts |
| Single light theme | Bright, colorful casual game aesthetic; **light mode only — no dark mode, no toggle, no system-theme following** (permanent design constraint) |
| Interface + Implementation pattern | All services/repositories have interfaces for testability |

---

## File Naming Conventions

- **Files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Variables/functions:** `camelCase`
- **Constants:** `camelCase` (not SCREAMING_CAPS)
- **Private members:** `_` prefix

---

## Architecture Overview

```
lib/
  main.dart                    ← Entry point
  core/                        ← App shell, routing, theme, design system
  features/                    ← Feature modules (15 total)
    puzzle/                    ← Core gameplay (domain + presentation)
      domain/
        tile_swap_engine.dart  ← Swap logic + group-aware movement
        puzzle_board_size.dart ← Grid dimensions from LevelConfig
        puzzle_image.dart      ← Image URL resolution
        puzzle_adjacency.dart  ← Edge-level connection state (Edge enum, computeAdjacency)
        puzzle_group.dart      ← PuzzleGroup, PuzzleGrouping.fromAdjacency (dynamic groups)
      presentation/
        bloc/
          puzzle_cubit.dart    ← Game state driver (consumes LevelConfig, rebuilds adjacency)
          puzzle_state.dart    ← PuzzleLoaded with LevelConfig + adjacency + grouping
        widgets/
          puzzle_board.dart    ← GridView board (per-edge borders, group drag feedback)
          puzzle_image_tile.dart ← Renders one atomic cell from shared image
    levels/                    ← Level/chapter/section system
      domain/
        entities/
          level.dart           ← Player progress (id, stars, completion)
          level_config.dart    ← Puzzle parameters (grid, difficulty, seed, role)
          chapter.dart         ← Themed chapter (board size, level range)
          section.dart         ← 20-level section with progression role
        services/
          chapter_catalog.dart ← Source of truth: builds LevelConfig from level ID
```
    victory/                   ← Victory celebration screen
    home/                      ← Main hub screen (collection artwork + play)
    collections/               ← Chapter artwork showcase
    gallery/                   ← All levels grid
    daily_puzzle/              ← Daily challenge
    daily_reward/              ← Daily streak rewards
    achievements/              ← Milestone tracking
    cosmetics/                 ← Board frames, piece styles, avatars
    shop/                      ← Coin packs, IAP, remove ads
    settings/                  ← Audio toggles, reset, privacy
    splash/                    ← Loading screen
    photos/                    ← Photo puzzle mode
    profile/                   ← Player name/avatar
  game/                        ← Flame game, wallet, ads cubits
  services/                    ← Audio, ads, analytics, cloud save, etc.
  shared/                      ← Reusable widgets and utilities
```

---

## Game Flow

```
Splash (bootstrap: Firebase, Ads, RevenueCat)
  ↓
Home (current collection artwork, progress, large Play button)
  ↓
ChapterCatalog.levelConfigFor(levelId) → LevelConfig
  ↓
Puzzle Screen (top bar + drag-and-drop board)
  ↓ [on solve]
Completion Animation (pieces snap, image revealed, glow/confetti)
  ↓
Collect Artwork Piece (update collection artwork)
  ↓
Victory Screen (stars, coins, share)
  ↓ [if chapter/section complete]
Chapter/Section Complete (celebration)
  ↓
Back to Home → Next Level
```

---

## Testing Approach

- Manual testing by the developer.
- Do NOT run `flutter test` during analysis or code changes.
- Do NOT run the application.
- The developer will test all changes themselves.

---

## Documentation Structure

```
AGENTS.md                          ← This file (permanent instructions)
docs/
├── GAME_DESIGN.md                 ← Game concept and mechanics
├── UI_UX_GUIDELINES.md            ← Visual language, colors, typography, components
├── ARCHITECTURE.md                ← Technical architecture
├── GAME_PROGRESS.md               ← Current project state
├── CHANGELOG.md                   ← Chronological change log
├── TODO.md                        ← Prioritized backlog
└── firebase_setup.md              ← Firebase configuration guide (existing)
```
