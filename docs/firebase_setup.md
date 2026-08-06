# Firebase Analytics + Crashlytics setup

Puzzle Cards reports analytics (Firebase Analytics) and crashes
(Firebase Crashlytics) through a single facade,
[`lib/services/analytics_service.dart`](../lib/services/analytics_service.dart).
All wiring is done — this guide is the one-time account/configuration work
required before the reports actually start flowing.

## Prerequisites

- A Google account (free tier is enough; each Firebase project gives ~GCP
  quotas that cover a game's analytics + crash needs).
- Flutter CLI on PATH.
- The `firebase` CLI (installed with `dart pub global activate
  firebase_cli`) and the FlutterFire CLI (`dart pub global activate
  flutterfire_cli`).

## Steps

### 1. Create the Firebase project

1. Open <https://console.firebase.google.com> → **Add project**.
2. Enter a project name (e.g. `puzzle-cards`), keep Google Analytics
   **enabled** (required for Firebase Analytics), accept the terms.
3. Wait for provisioning, then **Continue**.

### 2. Register the app(s)

From the project overview, tap the Android/iOS icons:

- **Android:** add the application ID (exactly what's in
  `android/app/build.gradle.kts`/`build.gradle`, e.g. `com.example.puzzle_cards`).
  Download the generated `google-services.json` into `android/app/`.
- **iOS:** add the bundle ID (`ios/Runner.xcodeproj/...` under "Project
  Runner → General → Bundle Identifier"). Download `GoogleService-Info.plist`
  into `ios/Runner/`.
- Web **and** Android **require** the downloaded config files at the paths
  above before FlutterFire can detect them.

### 3. Run flutterfire configure

From the project root:

```bash
flutterfire configure
```

This detects your platform config files, writes a
`lib/firebase_options.dart`, and registers the two first-party plugins
already listed in `pubspec.yaml` (`firebase_analytics`,
`firebase_crashlytics`).

If you prefer to skip the CLI, create `lib/firebase_options.dart` by hand
and set `DefaultFirebaseOptions.currentPlatform` as the argument to
`Firebase.initializeApp(options: ...)` in `lib/main.dart`.

### 4. Enable Crashlytics (Android)

- Firebase Console → your project → **Crashlytics** → do one of:
  - **Android**: click "Get started", it installs the Crashlytics Gradle
    plugin. With the FlutterFire setup you do **not** need to modify
    `build.gradle` manually — Crashlytics is available via
    `FirebaseCrashlytics.instance` automatically.
  - **iOS/macOS**: **Start** → enable **dSYM upload** in the console (the
    download works without a build-phase change).
- Analytics is on by default once `Firebase.initializeApp()` runs.

### 4. Verify locally (Android)

Run with a real device/emulator (web tests do nothing on web — the
service no-ops):

```bash
flutter run
```

- Open a puzzle and complete it, then trigger a crash by temporarily
  adding a line in a debug build, e.g. in `main()`:
  ```dart
  throw StateError('crashlytics test');
  ```
- After ~30s open the **Firebase console → Crashlytics**; you should see
  the crash and the analytic events under **Analytics → Events**
  (`app_launch`, `level_start`, `level_complete`, `coins_earned`, …).

### 5. Publish build config

The app reads its production identifiers from
[`--dart-define`](https://dart.dev/tools/arguments) constants. For release
builds:

```bash
flutter build apk --release \
  --dart-define=REWARDED_AD_UNIT_ID_ANDROID=ca-app-pub-XXXXXXXXXXXXXXXX/YYYY \
  --dart-define=REWARDED_AD_UNIT_ID_IOS=ca-app-pub-XXXXXXXXXXXXXXXX/YYYY \
  --dart-define=REVENUECAT_ANDROID_KEY=your_play_sdk_key \
  --dart-define=REVENUECAT_IOS_KEY=your_ios_sdk_key
```

Without them the app starts safely with AdMob test IDs and RevenueCat
unconfigured (ads/​IAP are no-ops).

## References / next hardening

- The service swallows every error and no-ops on web/tests; if you later
  require GDPR consent, gate `FirebaseAnalytics.instance.setConsent()`
  (E4) from a consent flow before `logEvent`.
- When the store build ID changes, bump `version: <x>.y.z+<n>` in
  `pubspec.yaml` so Crashlytics versions show correctly.

## Common failures

- "no Firebase App '[DEFAULT]' has been created": config files are
  missing or `flutterfire configure` hasn't been run — update
  `lib/firebase_options.dart` and pass it to `Firebase.initializeApp`.
- No events in console after 24h: ensure the device isn't an emulator
  without Google Play services, and check the debug mode "tag" — events
  are real-time via the debug viewer (`Analytics ⚙ → DebugView`).
- Crashlytics "Missing dSYM"/upload warnings: you must upload
  debug-symbols for Android (run the enabled Crashlytics Gradle plugin)
  o set `firebase_crashlytics`'s `crashlytics-devtool` for iOS.