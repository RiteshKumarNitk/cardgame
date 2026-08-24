# UI_UX_GUIDELINES.md — SuitClash Visual Language

## Design Direction

SuitClash should feel like a **polished casual mobile puzzle game** — colorful, playful, premium, and family-friendly. The UI should look like a real mobile game, not a standard Flutter application.

**Target feel:**
- Colorful
- Playful
- Premium
- Casual
- Family-friendly
- Puzzle-focused
- Attractive like modern casual mobile games
- Highly polished
- Animation-driven
- Simple to understand

**Avoid:**
- Casino or card-game aesthetics
- Dark, moody, or overly serious aesthetics
- Generic Flutter/Material-looking interfaces
- Cluttered screens
- Unnecessary complexity

---

## Permanent Design Constraint: Light Mode Only

SuitClash is **LIGHT MODE ONLY**.

- Do **NOT** implement dark mode.
- Do **NOT** add a dark mode toggle in Settings.
- Do **NOT** create dark theme colors.
- Do **NOT** automatically follow the device/system dark-mode preference.

The game must always use the SuitClash light, colorful, playful theme regardless of the user's device theme. This is a permanent design constraint — not subject to change.

**Legacy elements:** Card suit symbols (♠♥♦♣) currently appear as background decorative elements. These are legacy elements from an earlier prototype and may be replaced or removed during visual refinement. They are not part of the core visual identity.

---

## Color Palette

All colors are defined in `lib/core/design_system/app_colors.dart`.

### Primary Colors

| Name | Hex | Usage |
|------|-----|-------|
| Primary | `#D32F2F` | Primary actions, accents |
| Secondary | `#1E1E1E` | Secondary elements, text emphasis |
| Accent (Gold/Coin) | `#FFC107` | Coins, rewards, premium elements |
| Success | `#4CAF50` | Success states, positive feedback |
| Warning | `#FF9800` | Caution states |
| Danger | `#D32F2F` | Error states |

### Surface Colors

| Name | Hex | Usage |
|------|-----|-------|
| Background | `#F1F8F4` | Very light mint — main screen background |
| Card | `#FFFFFF` | Pure white for cards and elevated surfaces |

### Text Colors

| Name | Hex | Usage |
|------|-----|-------|
| Text Dark | `#263238` | Primary text, headings |
| Text Secondary | `#78909C` | Secondary labels, descriptions |
| Border | `#CFD8DC` | Dividers, borders |
| Shadow | `#1F000000` | 12% black for soft shadows |

### Gradient Stops

| Name | Hex | Usage |
|------|-----|-------|
| Primary Gradient Start | `#F44336` | Bright red |
| Primary Gradient End | `#B71C1C` | Deep red |
| Secondary Gradient Start | `#607D8B` | Blue grey |
| Secondary Gradient End | `#37474F` | Dark blue grey |
| Premium Gradient Start | `#FFE259` | Light gold |
| Premium Gradient End | `#FFA751` | Soft orange |

### Difficulty Tier Colors

| Difficulty | Hex |
|------------|-----|
| Easy | `#81C784` |
| Medium | `#4FC3F7` |
| Hard | `#FFB74D` |
| Expert | `#E57373` |
| Master | `#BA68C8` |

### Cosmetic Colors

| Name | Hex | Usage |
|------|-----|-------|
| Frame Gold | `#D4AF37` | Golden frame border |
| Frame Gold Glow | `#FFD700` | Golden frame glow |
| Frame Royal | `#7B1FA2` | Royal purple frame |
| Frame Emerald | `#2E7D32` | Emerald green frame |
| Frame Midnight | `#1A237E` | Midnight blue frame |
| Frame Ruby | `#B71C1C` | Ruby red frame |
| Piece Neon | `#00E5FF` | Neon piece accent |
| Piece Pastel Border | `#F06292` | Pastel piece border |
| Piece Pastel | `#FCE4EC` | Pastel piece fill |

---

## Typography

Defined in `lib/core/design_system/app_typography.dart` via Google Fonts.

### Font Families

- **Quicksand** (via GoogleFonts) — Headings, display text, titles
  - Weights: w700 (bold), w800 (extra bold)
- **Roboto** (via GoogleFonts) — Body text, labels, UI text
  - Weights: w500 (medium), w700 (bold)

### Type Scale

| Role | Font | Size | Weight |
|------|------|------|--------|
| displayLarge | Quicksand | 57px | w800 |
| displayMedium | Quicksand | 45px | w800 |
| displaySmall | Quicksand | 36px | w700 |
| headlineLarge | Quicksand | 32px | w700 |
| headlineMedium | Quicksand | 28px | w700 |
| headlineSmall | Quicksand | 24px | w700 |
| titleLarge | Quicksand | 22px | w700 |
| titleMedium | Roboto | 16px | w700 |
| titleSmall | Roboto | 14px | w700 |
| bodyLarge | Roboto | 16px | w500 |
| bodyMedium | Roboto | 14px | w500 |
| bodySmall | Roboto | 12px | w500 |
| labelLarge | Roboto | 14px | w700 |
| labelMedium | Roboto | 12px | w700 |
| labelSmall | Roboto | 11px | w700 |

**Note:** Baloo2.ttf and Nunito.ttf are bundled in `assets/fonts/` and declared in `pubspec.yaml`, but the design system currently uses Quicksand/Roboto via Google Fonts instead. This is an inconsistency — the bundled fonts are unused.

---

## Spacing System

Defined in `lib/core/design_system/app_spacing.dart` using an 8px grid.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Tight padding, icon gaps |
| sm | 8px | Small padding, inline spacing |
| md | 12px | Default padding |
| lg | 16px | Card padding, section spacing |
| xl | 24px | Section gaps |
| xxl | 48px | Screen-level spacing |

---

## Border Radius

Defined in `lib/core/design_system/app_radius.dart`.

| Token | Value | Usage |
|-------|-------|-------|
| sm | 12px | Small cards, buttons |
| md | 16px | Standard cards |
| lg | 20px | Large cards, dialogs |
| xl | 28px | Feature cards |
| pill | 999px | Fully rounded pills |

---

## Shadows

Defined in `lib/core/design_system/app_shadows.dart`.

| Preset | Usage |
|--------|-------|
| `card` | Elevated cards, tiles |
| `button` | Interactive buttons |
| `floating` | Floating elements, modals |
| `glow(color)` | Custom glow effects (frames, solved tiles) |

---

## Animations

Defined in `lib/core/design_system/app_animations.dart`.

| Animation | Duration | Curve |
|-----------|----------|-------|
| Page transition | 320ms | easeOut |
| Button tap | 100ms | easeOut |
| Card entrance | 400ms | elasticOut |
| Puzzle snap | 200ms | bounceOut |

---

## Background Treatment

Every screen uses `GameBackground` widget:
1. Gradient fill (screen background gradient from theme extension)
2. Glowing blurred circles at strategic positions
3. Optional Flame floating puzzle pieces (decorative, non-interactive)
4. Optional drifting decorative elements (legacy card suit symbols — may be replaced during visual refinement)

---

## Buttons

### GameButton

Primary action button: pill-shaped with gradient fill, shadow, press-scale animation.

**Variants:**
- Primary (red gradient)
- Secondary (grey gradient)
- Premium (gold/orange gradient)

### CircleIconButton

Circular icon-only button for navigation (back, settings, etc.)

---

## Cards

### GameCard

Rounded rectangle container with white background, card shadow, optional gradient border.

Used for level cards, achievement cards, collection cards.

---

## Reusable Widgets

| Widget | Location | Purpose |
|--------|----------|---------|
| `GameButton` | `shared/widgets/game_button.dart` | Primary/secondary/premium buttons |
| `GameCard` | `shared/widgets/game_card.dart` | Rounded card container |
| `GameBackground` | `shared/widgets/game_background.dart` | Gradient + glow + floating pieces |
| `AppImage` | `shared/widgets/app_image.dart` | Network-or-asset image with error handling |
| `StatChip` | `shared/widgets/stat_chip.dart` | Icon + value pill (coins, timer, moves) |
| `DifficultyBadge` | `shared/widgets/difficulty_badge.dart` | Difficulty-colored pill badge |
| `CircleIconButton` | `shared/widgets/circle_icon_button.dart` | Circular icon button |
| `PressScale` | `shared/widgets/press_scale.dart` | Tap-to-scale animation wrapper |
| `BounceIn` | `shared/widgets/bounce_in.dart` | Entrance bounce animation |
| `PulsingGlow` | `shared/widgets/pulsing_glow.dart` | Animated glow effect |
| `SparkleParticles` | `shared/widgets/sparkle_particles.dart` | Particle sparkle overlay |
| `ConfettiBurst` | `shared/widgets/confetti_burst.dart` | Confetti animation |
| `FireworksBurst` | `shared/widgets/fireworks_burst.dart` | Fireworks animation |
| `CoinRewardChip` | `shared/widgets/coin_reward_chip.dart` | Animated coin reward display |
| `CoinFlightAnimation` | `shared/widgets/coin_flight_animation.dart` | Coins flying from board to wallet |
| `OutlinedText` | `shared/widgets/outlined_text.dart` | Text with outline stroke |
| `FloatingBob` | `shared/widgets/floating_bob.dart` | Floating bob animation |
| `FloatingCloud` | `shared/widgets/floating_cloud.dart` | Drifting cloud |
| `FloatingSuit` | `shared/widgets/floating_suit.dart` | Legacy drifting card suit (may be replaced) |
| `PuzzlePieceLoader` | `shared/widgets/puzzle_piece_loader.dart` | 6-tile assembly animation (splash) |
| `ActionCard` | `shared/widgets/action_card.dart` | Action card widget |

---

## Screen Layout Patterns

### Home Screen Structure

```
Scaffold
  └── GameBackground
       └── SafeArea
            └── Column
                 ├── Top Bar (settings, coins, logo)
                 ├── Collection Artwork Display (progress + artwork)
                 ├── Current Level Indicator
                 └── Large Green Play Button (bottom center)
```

### Puzzle Screen Structure

```
Scaffold
  └── GameBackground
       └── SafeArea
            └── Column
                 ├── Top Bar (difficulty, coins, timer, moves, hint, pause)
                 └── PuzzleBoard (fills remaining space)
```

### Standard Screen Structure

```
Scaffold
  └── GameBackground
       └── SafeArea
            └── Column
                 ├── Top Bar (back button, title, actions)
                 └── Content (scrollable body)
```

### Modal/Bottom Sheet Pattern

```
DraggableScrollableSheet
  └── GameCard
       └── Content
```

---

## Iconography

- Material Icons for standard UI elements (back, settings, play, etc.)
- Emoji for achievement icons and special effects
- Legacy card suit symbols (♠♥♦♣) exist as background decoration — may be replaced during visual refinement

---

## Screen Reader / Accessibility

- All interactive elements have semantic labels
- Puzzle board has full semantics support for screen readers
- Minimum touch targets follow platform guidelines
