# UI_UX_GUIDELINES.md — SuitClash Visual Language

## Design Direction — "Warm Tactile Serenity"

The **Stitch project "SuitClash UI/UX Redesign System"** is the visual
source of truth. SuitClash should feel like a **calm, tactile, artwork-first
casual puzzle game** — the sensory warmth of premium stationery, smooth
river stones, and museum exhibition prints. Playful through proportion and
soft corners, balanced with deliberate typography and generous negative
space.

**Target feel:** warm · reassuring · organic · tactile · artwork-first ·
premium · family-friendly · animation-driven · simple.

**Avoid:**
- Casino / gambling / betting cues — no neon flashes, skeuomorphic gold
  bevels, slot counters, spinning wheels, hyper-saturated toy outlines
- Dark, moody, or overly serious aesthetics
- Generic Flutter / Material-looking interfaces
- Cluttered screens, unnecessary complexity
- Cold blue-greys and sterile paper-whites — everything sits on **warm
  ivory cream**

> Stitch HTML/Tailwind is **reference only**. It is never copied into the
> app — every screen is native Flutter, driven by the centralized tokens
> in `lib/core/design_system/`.

---

## Permanent Design Constraint: Light Mode Only

SuitClash is **LIGHT MODE ONLY**. Do not implement dark mode, a dark-mode
toggle, dark theme colors, or system-theme following. Permanent, not
subject to change.

---

## Colors — `lib/core/design_system/app_colors.dart`

Palette: gentle natural pigmentations — botanical gardens, honey,
sun-baked clay, unbleached cotton. Every color comes from `AppColors`;
never a raw hex or `Colors.*` in a widget.

### Brand — Soft Sage
| Token | Hex | Usage |
|---|---|---|
| `primary` | `#316342` | text, icons, active states on light surfaces |
| `primaryContainer` | `#4A7C59` | **primary button fills, CTAs, active trail, completed milestones** |
| `primaryFixed` | `#B9EFC5` | icon bubbles, soft chips |
| `primaryFixedDim` | `#9DD3AA` | progress-bar fills, mint accents |

### Prestige — Warm Honey Gold
| Token | Hex | Usage |
|---|---|---|
| `honey` / `accent` | `#FDBA45` | coins, collected stars, currency badges, victory accents |
| `honeyText` | `#7F5700` | text/icon on honey surfaces |
| `honeySoft` | `#FFDEAE` | pale honey backgrounds |

### Attention — Dusty Rose (sparing)
| Token | Hex | Usage |
|---|---|---|
| `attention` | `#B85248` | streak alerts, urgent counters, "time low" — **never** primary actions |
| `attentionStrong` | `#993A32` | |

### Semantic / surfaces / text
| Token | Hex | Usage |
|---|---|---|
| `secondary` | `#1C1C18` | deep-moss dark icons & text |
| `success` | `#3F7D4E` | positive / completion (sage-family) |
| `warning` | `#D99B26` | caution — amber honey |
| `danger` | `#BA1A1A` | error states |
| `background` | `#FCF9F2` | warm ivory canvas |
| `card` | `#FFFFFF` | lifted cards & playing tiles |
| `cardWell` | `#F0EEE7` | recessed well / puzzle-board tray base |
| `cardWellHigh` | `#E5E2DB` | chips, locked journey nodes |
| `surfaceLow` | `#F6F3EC` | low container (journey strip) |
| `textDark` | `#1C1C18` | primary text, headings (Deep Moss Bark, not jet) |
| `textSecondary` | `#414942` | secondary labels |
| `textMeta` | `#717971` | muted captions / meta |
| `border` | `#C1C9BF` | hairline borders, dividers |
| `outline` | `#142D312E` (8% moss) | 1px feather outline on lifted cards |
| `shadow` | `#14413220` (8% warm brown) | soft shadow ink |

### Difficulty ramp — warm (sage → honey → terracotta → rose)
`easy #4A7C59 · medium #7FA08A · hard #D99B26 · expert #C9743F · master #993A32`

### Cosmetics
Cosmetic frame / piece / avatar colors are **unchanged** in this pass —
some are deliberately vivid for unlockable variety. Revisit when the
Cosmetics screen is restyled.

---

## Typography — `lib/core/design_system/app_typography.dart`

**Plus Jakarta Sans** throughout (via `GoogleFonts.plusJakartaSans`),
weights 500 / 600 / 700 / 800. Screens read from
`Theme.of(context).textTheme`, never `GoogleFonts.*` directly.

| Role | Size / line / weight / tracking |
|---|---|
| displayLarge / displayMedium | 40 / 48 / 800 / −0.8 · 32 / 40 / 800 / −0.6 |
| displaySmall / headlineLarge | 28 / 36 / 700 / −0.3 |
| headlineMedium | 22 / 28 / 700 / −0.2 |
| headlineSmall / titleLarge | 18 / 24 / 600–700 |
| titleMedium / titleSmall | 16 / 22 / 600 · 14 / 20 / 600 |
| bodyLarge / bodyMedium / bodySmall | 16 / 24 / 500 · 14 / 20 / 500 · 12 / 16 / 500 |
| labelLarge / labelMedium / labelSmall | 14 / 18 / 700 / 0.3 · 12 / 16 / 700 / 0.4 · 11 / 14 / 700 / 0.5 |

Use **`AppTypography.tabular(style)`** for numbers that update in place —
move counts, coin balances, timers — so digits don't jitter.

---

## Spacing — `lib/core/design_system/app_spacing.dart`

4 / 8 base unit, aligned to Stitch:

| Token | px |
|---|---|
| xxs | 4 |
| xs | 8 |
| sm | 12 |
| md | 16 |
| lg | 20 |
| xl | 24 |
| xxl | 32 |
| xxxl | 40 |
| huge | 48 |

`screenMargin = 16` (screen body horizontal margin), `gridGutter = 12`.

---

## Border Radius — `lib/core/design_system/app_radius.dart`

| Token | px | Usage |
|---|---|---|
| xs | 4 | tiny chips |
| sm | 8 | puzzle tiles, badges, small chips |
| md | 12 | non-pill buttons, inputs |
| lg | 16 | standard cards, dialogs, the puzzle-board tray |
| xl | 24 | feature / hero cards, chapter cards |
| pill | 999 | buttons, currency meters, journey nodes |

---

## Elevation & Shadows — `lib/core/design_system/app_shadows.dart`

Warm, layered — brown/moss tints, never flat grey.

| Preset | Usage |
|---|---|
| `card` | L2 resting card / tile — dual warm shadow (pair with a 1px `AppColors.outline` feather border) |
| `pill` | stat chips, currency meters, small pills |
| `button` | ambient shadow under a button |
| `lifted` | L3 — a picked-up tile or card, "rises off the tray" |
| `floating` | L4 — sheets, modals, dialogs |
| `tactile(cushion)` | primary CTA: hard `0 4px 0` resting cushion + soft ambient — the button feels physically pressable |
| `glow(color)` | soft warm halo — completed frames, solved-tile bloom, active node |

Modal scrim: translucent moss (`textDark @ ~0.38`) over a **6px backdrop
blur** — the board reads as "set aside", not hidden.

---

## Animations — `lib/core/design_system/app_animations.dart`

| Animation | Duration / curve |
|---|---|
| micro / fast / medium / slow | 90 / 130 / 280 / 520 ms |
| page transition | 300 ms · easeOutCubic (fade + 0.97→1.0 scale) |
| glow pulse (CTA, active node ring) | 2800 ms · easeInOut |
| tactile press | 120 ms |
| pressed scale | 0.97 (restrained) |

---

## Components

### GameButton — `shared/widgets/game_button.dart`
Solid pill fill with a **tactile bottom cushion** ([AppShadows.tactile]),
press-scale feedback.
- **primary** — Soft Sage `#4A7C59` fill, white label. Main CTAs.
- **secondary** — warm cream fill, 1.5px hairline stroke, dark label.
- **premium** — Honey Gold `#FDBA45` fill, dark label. Coin / boost.

### GameCard — `shared/widgets/game_card.dart`
16px radius, 1px warm feather outline, warm L2 shadow. `glass` variant =
warm paper-translucent (82% ivory + light blur) for content on the
background.

### StatChip — `shared/widgets/stat_chip.dart`
Stadium capsule, 90% ivory fill, a tinted **icon bubble** on the left,
**tabular** bold number on the right.

### CircleIconButton — `shared/widgets/circle_icon_button.dart`
White disc, 1.5px hairline, pill shadow. Utility actions (back, settings,
hint).

### GameBackground — `shared/widgets/game_background.dart`
Near-flat warm-ivory wash + a faint sage dot texture (16px pitch, ~4%) +
optional Flame floating pieces (retinted sage / honey / mint, low
presence). No saturated glow blobs.

### Journey nodes — `features/levels/presentation/journey/`
Dashed sage winding path (`primaryContainer @ 0.35`). Completed = sage
fill + white check + honey stars below. Current = larger ivory disc with a
pulsing sage ring. Locked = sand (`cardWellHigh`) + lock icon.

### Puzzle board — `features/puzzle/presentation/widgets/puzzle_board.dart`
A rounded, recessed **cream tray well** (`cardWell`, radius `lg`, clipped
corners, warm border + shadow). Pieces stay **seamless** — connected edges
still remove the shared border so a solved board reads as one photo.
Lifted / drop-target tile = 2.5px sage halo + warm `lifted` shadow.
A connected group, while dragged, gets a soft sage outline + lift — a
**"joined" cue, never a lock**: groups stay fully draggable at all times
(`CONNECTED ≠ LOCKED`, see AGENTS.md / ARCHITECTURE.md).

**The puzzle grid's logic, dimensions, drag/drop, snapping, adjacency,
grouping, displacement, hint, shuffle, solve detection, timer, scoring and
the cover-scale `ImageLayout` pipeline are unchanged by the retheme — only
decoration/color/radius/shadow.**

---

## Screen Layout Patterns

### Home ("Home & Artwork Journey")
```
Scaffold › GameBackground › SafeArea › Column
  ├ _HomeHeader        (profile group | coins pill | settings)
  ├ Expanded › scroll › Column
  │    ├ brand row     (logo · "SuitClash" · chapter/section)
  │    ├ _ArtworkHero  (framed section mosaic + progress scrim + status chip + stars)
  │    ├ Continue CTA  (solid sage, tactile, pulsing)
  │    ├ _JourneyStrip (dashed sage node preview → opens /levels)
  │    ├ _DailyDiscovery (Daily Challenge · Collections bento)
  │    └ _ShortcutRow  (Journey · Gallery · Awards · Shop)
  └ BannerAdWidget
```

### Puzzle
```
Scaffold › GameBackground(no pieces) › SafeArea › Column
  ├ _PuzzleTopBar   (back/pause · difficulty · coins/timer/moves chips · 3★ target · hint · preview · pause)
  └ PuzzleBoard     (cream tray, fills remaining space)
```

### Standard screen
```
Scaffold › GameBackground › SafeArea › Column
  ├ Top Bar (CircleIconButton back · title · actions)
  └ Content (scrollable)
```

### Modal / bottom sheet
`showModalBottomSheet` (transparent bg) › `GameCard`, over the L4 blur
scrim.

---

## Iconography
Material rounded icons for UI. Emoji for achievement icons / effects. No
card-suit symbols. Identity = puzzle + artwork + collection.

## Accessibility
Semantic labels on all interactive elements; full puzzle-board semantics;
platform-minimum touch targets; `MediaQuery.disableAnimations` respected
for celebration effects.
