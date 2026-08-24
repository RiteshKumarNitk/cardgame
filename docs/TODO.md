# TODO.md — Prioritized Backlog

---

## P0 — Critical

- [x] Puzzle group UI: visual group indicators, group-aware drag/drop on board
- [ ] Replace placeholder audio files with real audio assets
- [ ] Replace picsum.photos placeholder images with curated photography
- [ ] Update README.md to be project-specific (not Flutter boilerplate)

---

## P1 — Important

- [ ] Wire artwork collection progression into core game loop (complete puzzle → collect piece → update collection)
- [ ] Refine Home Screen to emphasize current collection artwork + large Play button as primary focus
- [ ] Remove/replace legacy card suit symbols from background (not part of core visual identity)
- [ ] Resolve font inconsistency: either use bundled Baloo2/Nunito or remove them from pubspec.yaml
- [ ] Add GDPR consent flow for Firebase Analytics (`setConsent()` gate)
- [ ] Integrate generated artwork from `content/artwork/` into the game (or remove if not intended)

---

## P2 — Improvements

- [ ] Add haptic feedback to puzzle interactions (swap, lock)
- [ ] Add visual feedback for locked cells (subtle lock icon or glow)
- [ ] Add "skip level" option for stuck players (with appropriate cost/gating)
- [ ] Add puzzle piece entrance animation (staggered deal-in per piece)
- [ ] Improve collections page — show individual level progress within sections
- [ ] Add analytics events for cosmetics purchases and equip actions
- [ ] Add cloud save conflict resolution (last-write-wins vs merge)
- [ ] Add offline support for daily challenge (cache today's puzzle)
- [ ] Add progress backup indicator on home screen

---

## Future

- [ ] Daily challenge themes (rotate through chapter themes)
- [ ] Achievement notification toasts (appear when unlocked)
- [ ] Puzzle difficulty selection (player chooses Easy/Medium/Hard per level)
- [ ] Custom puzzle mode (upload your own photo)
- [ ] Social features (friend leaderboard, challenge a friend)
- [ ] Accessibility improvements (Dynamic Type, VoiceOver optimization)
- [ ] Widget support (iOS/Android home screen widget showing daily puzzle)
- [ ] Localization (multi-language support)
