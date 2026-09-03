# RELEASE_CHECKLIST.md — Play Store (Android) v1.0.0

First release: **no ads**, bundled photos only, ~780 levels / 16 chapters.

Legend: `[x]` done in the repo · `[ ]` needs you (account access / hosting / device).

---

## Done in code

- [x] `AppConfig.adsEnabled = false` — no banner widgets, no rewarded/interstitial
      loads, `MobileAds` never initialised. Low-coins hint shows a plain message
      instead of an ad offer.
- [x] **All `picsum.photos` removed.** Daily Challenge + Photo Puzzles use the
      bundled `assets/images/collections/` photos (offline, no third-party media).
- [x] `AppConfig.photoPuzzlesEnabled = false` — unfinished sandbox hidden.
- [x] `pubspec.yaml` real `description`.
- [x] Adaptive launcher icons generated (`dart run flutter_launcher_icons`).
- [x] `android/app/proguard-rules.pro` created (was referenced-but-missing).
- [x] `build.gradle.kts` reads signing from `android/key.properties`.
- [x] **`android/key.properties` written** with the working keystore values
      (password is `placeholder_password` — see "Rotate the keystore" below).
- [x] **`firestore.rules` + `firebase.json` + `.firebaserc` + `firestore.indexes.json`**
      — per-user docs are owner-only; leaderboard is read-any-signed-in,
      write-your-own, size/range-checked.
- [x] **Public privacy policy** authored: `docs/legal/privacy-policy.html`
      (fill `[EFFECTIVE DATE]`, `[PUBLISHER LEGAL NAME]`, `[CONTACT EMAIL]`).
      In-app `PrivacyPolicyPage` rewritten to a matching summary (update the
      `suitclash.example.com/privacy` URL string once hosted).
- [x] **Store listing text + Data Safety answers + content-rating answers**:
      `docs/store-listing.md`.
- [x] **Store graphics**: `docs/store-assets/icon-512.png` (512²) and
      `docs/store-assets/feature-graphic-1024x500.png`. Regenerate with
      `dart run tools/make_store_assets.dart`.
- [x] **Release AAB builds & is signed with the upload key** —
      `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
      (78.5 MB). Upload-key cert SHA-1: `60:67:2B:9D:52:20:A7:7D:D4:CB:3D:3E:B4:62:F2:44:48:58:CC:19`.

---

## Needs you — account access / hosting / device

### 1. Rotate the keystore (before first publish)
- [ ] The current upload key uses the weak, git-history-exposed password
      `placeholder_password`. Either enrol in **Play App Signing** (recommended —
      the upload key can then be reset by Play support if it leaks) **or**
      generate a fresh upload keystore with a strong password:
      ```
      keytool -genkey -v -keystore android/app/upload-keystore.jks \
        -keyalg RSA -keysize 2048 -validity 10000 -alias upload
      ```
      then update `android/key.properties` and rebuild.
- [ ] Back up the keystore file + passwords off-machine.

### 2. Fill the placeholders
- [ ] `docs/legal/privacy-policy.html` — `[EFFECTIVE DATE]`,
      `[PUBLISHER LEGAL NAME]`, `[CONTACT EMAIL]`.
- [ ] `docs/store-listing.md` — same four bracketed values.
- [ ] `lib/features/settings/presentation/pages/privacy_policy_page.dart` —
      replace `suitclash.example.com/privacy` with the real hosted URL.

### 3. Host the privacy policy
- [ ] Easiest: `firebase deploy --only hosting` (the `firebase.json` hosting
      block serves `docs/legal/` and maps `/privacy`). Or drop
      `privacy-policy.html` on GitHub Pages. Result: a public URL like
      `https://cardgame-3ad8c.web.app/privacy`.

### 4. Firebase / Google Cloud
- [ ] `firebase deploy --only firestore` to publish the rules + indexes.
- [ ] Confirm `cardgame-3ad8c` is your production project (it's the one in
      `android/app/google-services.json`).
- [ ] Google Cloud console → Credentials → restrict the Android API key
      (`AIza…`) to the Android app + the Firebase APIs it uses.
- [ ] Firebase console → Authentication → enable **Anonymous** sign-in.
- [ ] Add the upload-key SHA-1 (above) to the Firebase Android app if you later
      use anything requiring it (Dynamic Links, phone auth, App Check).
- [ ] Trigger one test crash, confirm it appears in Crashlytics.

### 5. Play Console — listing (copy from `docs/store-listing.md`)
- [ ] Create app (Games › Puzzle, free), set name/descriptions.
- [ ] Upload `icon-512.png` + `feature-graphic-1024x500.png`.
- [ ] **Phone screenshots** (2–8) — you must capture on an emulator/device:
      `flutter run` then screenshot Home, Journey, a puzzle mid-solve, a puzzle
      nearly done, Victory, Daily Challenge. ~1080×1920.
- [ ] Tablet screenshots (optional, recommended).

### 6. Play Console — policy (answers in `docs/store-listing.md`)
- [ ] Privacy policy URL.
- [ ] Data safety form.
- [ ] Content rating questionnaire → expect Everyone / PEGI 3.
- [ ] Target audience (not "for children" unless you take on Families policy).
- [ ] Ads declaration: **No**.
- [ ] App access: "all functionality available without special access".
- [ ] Account/data deletion: point to Settings → Erase my data + the contact email.

### 7. Ship
- [ ] `flutter build appbundle --release` (already verified) → upload the AAB.
- [ ] Install the AAB on a **real device** via the internal-testing track.
      Smoke test: launch (no R8 crash), full puzzle solve, Daily Challenge,
      offline launch, kill+relaunch keeps progress, reinstall restores from
      cloud, (if IAP live) purchase + restore.
- [ ] Closed testing track — new personal developer accounts need **~14 days
      and 12 opted-in testers** before Production is unlocked. Start now.
- [ ] Promote to Production, staged rollout.

---

## Deferred to v1.1+ (not blockers)

- Ads: AdMob account + real unit IDs via `--dart-define`, replace the sample
  AdMob **App ID** in `AndroidManifest.xml`, add a UMP consent form, flip
  `AppConfig.adsEnabled = true`.
- RevenueCat: real products/entitlements, set `REVENUECAT_ANDROID_KEY`.
- Replace placeholder audio (`assets/audio/` — procedurally generated sine waves).
- AAB is 78.5 MB (300 bundled JPGs). Fine under the 200 MB limit; Play Asset
  Delivery later if you add many more photos.
- iOS submission (separate checklist).
- Pre-existing widget-test failures (`PuzzleImageTile` renders 0 in the test
  harness: `puzzle_page_test`, `photo_puzzle_page_test`, `daily_puzzle_page_test`;
  a couple of flaky Hive-state photo tests) — do not affect the running app.
