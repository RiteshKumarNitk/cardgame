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
- [x] Refine Home Screen to emphasize current collection artwork + large Play button as primary focus
- [x] Remove/replace legacy card suit symbols from background (not part of core visual identity)
- [x] "Warm Tactile Serenity" visual retheme — Stitch design as source of truth (tokens + shared widgets + Home / Journey / Puzzle-board visual layer). Visual only; grid logic untouched.
- [x] Bug fixes (2026-09-09): Home level-completion sync (stale Hive keys → reseed loop), Victory/last-piece drag freeze, cosmetics trimmed to Classics + flat avatars + raised coin prices, golden glow removed, moving-piece feedback cleaned, Daily Challenge Home lock indicator.
- [ ] Retheme follow-ups: on-device visual QA of every screen; consider bundling Plus Jakarta Sans instead of `google_fonts` runtime fetch. The 16 pre-existing test failures (chapter-catalog WIP, "SuitClash" rename in splash/widget tests, `PuzzleImageTile` headless, stale "locked cell" tests) still stand.
- [ ] Resolve font inconsistency: Baloo2/Nunito are declared in pubspec.yaml but unused (typography now uses Plus Jakarta Sans via GoogleFonts) — remove them or bundle Jakarta
- [ ] Add GDPR consent flow for Firebase Analytics (`setConsent()` gate)
- [ ] Integrate generated artwork from `content/artwork/` into the game (or remove if not intended)
- [x] AdMob: re-enable ads (`AppConfig.adsEnabled = true`), centralize IDs in `AdConfig`, make `BannerAdWidget` the one real banner + respect Remove Ads, add `AdLogger`, fix missing iOS `GADApplicationIdentifier`
- [ ] AdMob: add UMP (User Messaging Platform) consent form before `MobileAds.initialize()` for EEA/UK
- [ ] AdMob: create real ad units + wire real unit IDs via release `--dart-define`; replace sample App ID in `AndroidManifest.xml` / iOS `Info.plist`
- [ ] AdMob: real-device verification of the runtime chain (SDK init → test banner → `onAdLoaded` → visible `AdWidget` → navigation → dispose) — debug build + `adb logcat | grep '[AdMob]'`
- [x] Fix `victory_page.dart` build break (stray `}` after `initState`, missing `flutter/services.dart` import, non-existent `BounceIn.slideUp`) — was failing every `flutter build`

---

## P2 — Improvements

- [x] Add haptic feedback to puzzle interactions (piece snap already had it; invalid group-move rejection now plays a haptic + soft error SFX via `AudioService().playError()`)
- [ ] Add "skip level" option for stuck players (with appropriate cost/gating)
- [x] Audit and fix level progression: reduce excessive board sizes (chapters 5+ were 11×12 to 22×23), introduce board size variety within sections
- [x] Reduce Chapter 1 from 60 to 20 levels, Chapter 2 from 40 to 20 levels
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
