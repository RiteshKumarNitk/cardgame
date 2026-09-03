# Play Store listing — SuitClash (copy/paste into Play Console)

Fill the four bracketed values before submitting: `[PUBLISHER LEGAL NAME]`,
`[CONTACT EMAIL]`, `[PRIVACY POLICY URL]`, `[EFFECTIVE DATE]`.

---

## App details

| Field | Value |
|---|---|
| App name | `SuitClash` |
| Default language | English (United States) – `en-US` |
| App or game | Game |
| Category | Puzzle |
| Tags | jigsaw, brain, relaxing, casual |
| Contact email | `[CONTACT EMAIL]` |
| Website | `[PRIVACY POLICY URL host, or a landing page]` |
| Privacy policy | `[PRIVACY POLICY URL]` |

---

## Short description (max 80 chars)

```
Rebuild hundreds of photo jigsaw puzzles. Slide, swap, relax.
```
(60 chars — safe.)

## Full description (max 4000 chars)

```
SuitClash is a calm, tactile jigsaw puzzle game. Every level is one photo cut
into a grid — slide and swap the pieces until the picture is whole again.

No timers on the puzzles. No forced moves. Just you, the image, and the quiet
satisfaction of the last piece clicking into place.

FEATURES
• Hundreds of hand-picked photo puzzles across 16 themed chapters — nature,
  cities, animals, oceans, mountains and more.
• A gentle difficulty curve: start on a small grid, work up to large,
  intricate boards.
• Connected pieces: matching neighbours join into groups you can move as one.
• Three-star scoring rewards efficient solving — beat your own best.
• A new Daily Challenge puzzle every day.
• Coins, hints and a preview to help when you're stuck.
• Cosmetics to personalise your profile.
• Cloud backup so your progress follows you to a new device.
• Plays fully offline.

SuitClash is free to play. This version contains no ads. Optional in-app
purchases are available.

Made for anyone who wants a screen break that actually feels restful.
```

---

## Graphics (in `docs/store-assets/`)

| Asset | Spec | File |
|---|---|---|
| App icon | 512 × 512 PNG, 32-bit | `icon-512.png` |
| Feature graphic | 1024 × 500 PNG/JPG | `feature-graphic-1024x500.png` |
| Phone screenshots | 2–8, PNG/JPG, 16:9 or 9:16, min 320 px | **you capture — see below** |
| 7-inch tablet | optional but recommended | you capture |
| 10-inch tablet | optional but recommended | you capture |

**Screenshots:** run the app on an emulator or device and capture 4–6 screens:
Home, Journey map, a puzzle mid-solve, a puzzle nearly done, Victory with
stars, Daily Challenge. `flutter run` then use the emulator's camera button, or
`adb exec-out screencap -p > shot1.png`. Aim for 1080 × 1920.

---

## Content rating questionnaire (IARC)

Answer all "No" except where noted — SuitClash is a non-violent puzzle game.

| Question | Answer |
|---|---|
| Violence (cartoon/fantasy/realistic) | No |
| Blood / gore | No |
| Sexual content or nudity | No |
| Nudity | No |
| Profanity or crude humour | No |
| Controlled substances (alcohol, tobacco, drugs) | No |
| Gambling — simulated | **No** (coins cannot be bought to gamble; no casino mechanics, no wagering, no chance-based paid loot) |
| Gambling — real money | No |
| User-generated content / user interaction | **Yes** — players can enter a display name shown on a global leaderboard. No chat, no messaging, no sharing of content. |
| Shares user's physical location | No |
| Digital purchases | **Yes** — in-app purchases (cosmetics / remove future ads) |
| Data collection | See Data safety section below |
| Miscellaneous (horror, fear) | No |

Expected result: **Everyone / PEGI 3 / rated for all ages.**

---

## Data safety form

### Does your app collect or share any of the required user data types?
**Yes.**

### Is all user data encrypted in transit?
**Yes** (Firebase / Google Play traffic is HTTPS/TLS).

### Do you provide a way for users to request that their data be deleted?
**Yes** — in-app: Settings → Erase my data. Also by email to `[CONTACT EMAIL]`.

### Data types

| Data type | Collected | Shared | Processed ephemerally | Optional / Required | Purposes |
|---|---|---|---|---|---|
| **App interactions** (Firebase Analytics: levels started/finished, feature taps, session length) | Yes | No | No | Required | Analytics |
| **Crash logs** (Firebase Crashlytics) | Yes | No | No | Required | App functionality (bug fixing) |
| **Diagnostics** (device model, OS version, memory at crash) | Yes | No | No | Required | App functionality |
| **Other identifiers** (Firebase anonymous auth UID, Analytics app-instance ID) | Yes | No | No | Required | App functionality, Analytics |
| **User-provided name** (optional display name for leaderboard) | Yes | No | No | Optional | App functionality (leaderboard) |
| **Purchase history** (which non-consumable IAP you own) | Yes | No | No | Required (only if you buy) | App functionality |

**Not collected:** no email/phone, no contacts, no location, no photos/media,
no messages, no browsing history, no advertising ID (this version has no ads),
no financial info (Google Play handles payment).

> If you ship the build with IAP disabled (no RevenueCat key configured), drop
> the "Purchase history" row.

---

## Ads declaration

**Does your app contain ads?** — **No** (matches `AppConfig.adsEnabled = false`).

---

## App access

If any part of the app is gated, provide test credentials. SuitClash has no
login wall (anonymous auth is automatic) — answer **"All functionality is
available without special access."**

---

## Government / news / COVID / financial features

None apply — answer No to each.
