# Everslot — install, configure, run

This guide covers what to install, how to run the app (fully offline first), and the **manual steps
that need your own accounts**: Supabase cloud, Firebase (push + Crashlytics), Apple push (APNs) and the
iOS build with Xcode ≥ 26. Nothing secret is in the repository. Every missing piece degrades
gracefully: without Supabase the app runs **local-only** (ADR-017); without Firebase there is no push
and no Crashlytics, but local reminders work.

> Status: written for section 1 (foundation). Later sections add their own steps here.

## 1. Install

1. **Flutter through FVM** (the version is pinned in `.fvmrc`, 3.47.5):
   `brew install fvm`, then at the repository root `fvm install` and `fvm flutter --version`.
   Always run `fvm flutter …` / `fvm dart …`.
2. **Melos** (workspace scripts): `fvm dart pub global activate melos`.
3. **Android**: Android Studio with SDK 36, an emulator (API 24+), Java 17.
4. **iOS**: **Xcode 26 or newer** (Xcode 16 can't build: `workmanager_apple` uses the iOS 26 SDK;
   Xcode 27 requires the UIScene lifecycle the app already uses). Install from the App Store, then
   `sudo xcode-select -s /Applications/Xcode.app` and `xcodebuild -runFirstLaunch`.
5. **Backend tools** (only for the local stack): Docker Desktop, the Supabase CLI
   (`brew install supabase/tap/supabase`), Deno (`brew install deno`).

## 2. Run (local-only, no account needed)

```bash
fvm flutter pub get                      # repository root (pub workspace)
cp app/env/example.json app/env/dev.json # keep the placeholders: local-only mode
melos run l10n                           # merge ARB parts + gen-l10n
cd app && fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json
```

Checks before a commit: `melos run format`, `melos run analyze`, `melos run test`
(app tests: `cd app && fvm flutter test --concurrency 3`).

## 3. Local backend (optional)

```bash
supabase start          # Docker must be running
supabase db reset       # all migrations + seed
supabase test db        # pgTAP (506 tests)
supabase functions serve
deno test -A supabase/functions
supabase gen types typescript --local --schema app,private > supabase/functions/_shared/database.types.ts
```

Attachment pipeline against local Storage (T2.2.10, creates and deletes throwaway users):

```bash
eval "$(supabase status -o env | grep -E '^(API_URL|PUBLISHABLE_KEY|SECRET_KEY)=')"
export API_URL PUBLISHABLE_KEY SECRET_KEY
cd app && fvm flutter test test_storage
```

Point the app at it with `app/env/dev.json`: `SUPABASE_URL` = the API URL printed by `supabase start`
(`http://10.0.2.2:54321` from the Android emulator) and `SUPABASE_PUBLISHABLE_KEY` = its publishable key.

## 4. Supabase cloud (T1.2.02)

1. supabase.com → **New project** `everslot-prod` (EU region), optionally `everslot-dev`. Free plan for
   development; **Pro before launch** (free projects pause when idle).
2. Project → **Settings › API keys**: enable the **new API keys**; copy the publishable key
   (`sb_publishable_…`). Keep the secret key (`sb_secret_…`) for Edge Function secrets only.
   **Settings › JWT**: switch to asymmetric signing keys.
3. **Authentication › URL configuration**: site URL and redirect `everslot://auth-callback`.
   Enable Email OTP; Google / Apple when configured; **Multi-factor › TOTP** on (T1.5.17).
4. Terminal:
   ```bash
   supabase link --project-ref <YOUR_PROJECT_REF>
   supabase db push --dry-run && supabase db push
   supabase functions deploy --project-ref <YOUR_PROJECT_REF>
   supabase secrets set --project-ref <YOUR_PROJECT_REF> CRON_SECRET=<random> SUPABASE_SECRET_KEY=sb_secret_…
   ```
5. SQL editor (lets pg_cron call the functions):
   ```sql
   select vault.create_secret('https://<YOUR_PROJECT_REF>.supabase.co/functions/v1', 'functions_base_url');
   select vault.create_secret('<the same CRON_SECRET>', 'cron_secret');
   ```
6. App: put the URL and publishable key in `app/env/dev.json` (and `prod.json`) — never commit them.
7. Write the project refs (not keys) in `supabase/README.md › Placeholders & secrets`.
8. Optional — digest emails (T7.4.18, users opt in under Settings › Notifications):
   1. Create an account with a transactional email provider that speaks the Resend API (resend.com),
      verify your sending domain (SPF + DKIM records) and create an API key.
   2. Set the secrets (generate the two random values yourself, e.g. `openssl rand -hex 32`):
      ```bash
      supabase secrets set --project-ref <YOUR_PROJECT_REF> EMAIL_API_KEY=<provider key> \
        EMAIL_FROM="Everslot <digest@your-domain>" EMAIL_LINK_SECRET=<random> EMAIL_WEBHOOK_SECRET=<random>
      ```
   3. In the provider, add a webhook to `https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/email-events`
      for *bounced* and *complained* events, with the header `x-email-webhook-secret: <EMAIL_WEBHOOK_SECRET>`.
   Without these secrets nothing is emailed; push and the inbox are unaffected.

## 5. Firebase: push + Crashlytics (T1.2.13, T1.2.15)

1. console.firebase.google.com → create **everslot-dev** and **everslot-prod**; disable Google
   Analytics when asked.
2. `fvm dart pub global activate flutterfire_cli`, `firebase login`.
3. From `app/`, once per flavor (overwrites the placeholder files):
   ```bash
   flutterfire configure --project=<dev-project-id> --out=lib/firebase/firebase_options_dev.dart \
     --platforms=android,ios --android-package-name=app.everslot.dev --ios-bundle-id=app.everslot.dev \
     --android-out=android/app/src/dev/google-services.json
   flutterfire configure --project=<prod-project-id> --out=lib/firebase/firebase_options_prod.dart \
     --platforms=android,ios --android-package-name=app.everslot --ios-bundle-id=app.everslot \
     --android-out=android/app/src/prod/google-services.json
   ```
   Accept when it offers to add the Google Services and Crashlytics Gradle plugins and the iOS
   Crashlytics build phase. The app picks the file of the `FLAVOR` in `env/<flavor>.json`.
4. Set `"FIREBASE_ENABLED": true` in `app/env/dev.json` / `prod.json`.
5. In `app/ios/Runner/Info.plist` keep `FirebaseAppDelegateProxyEnabled` as generated; add
   `FIREBASE_ANALYTICS_COLLECTION_ENABLED` = `NO`. On Android add to the `<application>` of
   `AndroidManifest.xml`: `<meta-data android:name="firebase_analytics_collection_enabled" android:value="false"/>`.
6. Server push: Firebase → Project settings → **Service accounts › Generate new private key**, then
   `supabase secrets set FCM_SERVICE_ACCOUNT="$(base64 -i service-account.json)"` and delete the file.
7. Check: run the dev flavor, Settings › debug menu shows Firebase **on**. Crashlytics: build the dev
   flavor in release (`fvm flutter run --release --flavor dev …`), tap debug menu › **Send a test crash**,
   reopen the app — the issue appears in Crashlytics within minutes (opt-out: Settings › Privacy).

## 6. Apple push (APNs) (T1.2.14)

The app already has `UIBackgroundModes` (remote-notification, fetch, processing),
`Runner.entitlements` (`aps-environment`, time-sensitive notifications) and the notification delegate.

1. developer.apple.com → **Certificates, IDs & Profiles › Keys › +** → enable **Apple Push
   Notifications service (APNs)** → download the `.p8` once; note the **Key ID** and your **Team ID**.
2. **Identifiers**: for `app.everslot` and `app.everslot.dev` enable **Push Notifications** and
   **Time Sensitive Notifications** (and Associated Domains if you use app links).
3. Firebase (both projects) → Project settings → **Cloud Messaging › Apple app configuration** →
   upload the `.p8` with the Key ID and Team ID.
4. Xcode → Runner target → **Signing & Capabilities**: pick your team (automatic signing).
5. Check: run the dev flavor on a **real iPhone**, signed in to the cloud project, and allow
   notifications. Copy the device's token from Supabase → Table editor → `app.devices.push_token`, then
   Firebase → Messaging → **Send test message** to that token.

## 7. iOS build check (T1.1.05)

With Xcode ≥ 26 selected:

```bash
cd app && fvm flutter build ios --no-codesign --debug --flavor dev -t lib/main_dev.dart
```

It must build without the "fails to launch" UIScene error; then run it on a simulator and confirm the
plugins work after the scene connects (e.g. notifications permission prompt, sign-in screen).
CI runs the same build on `macos-26` (`.github/workflows/ci.yml`).

## 8. End-to-end tests (patrol) (T9.1.07, T7.2.22)

The suites in `app/patrol_test/` boot the real app in **local-only mode** (the placeholder
`env/example.json` leaves Supabase unconfigured) and drive the OS: permission dialogs, the
notification shade, notification actions. `patrol_test/support/e2e.dart` hands each test the app's
`ProviderContainer`, so data is seeded through the same application APIs as the UI.

```bash
fvm dart pub global activate patrol_cli 4.8.0     # once; puts `patrol` in ~/.pub-cache/bin
cd app
patrol test --flavor dev --dart-define-from-file=env/example.json                  # whole suite
patrol test --flavor dev -t patrol_test/notifications_test.dart --dart-define-from-file=env/example.json
```

- **Android** — any emulator / device with API ≥ 33 (`patrol` picks the first one; `--device <id>`
  otherwise). Each test runs in a fresh process with cleared data (Android Test Orchestrator). CI
  runs the suite on an API 34 emulator (`android-e2e` job in `.github/workflows/ci.yml`).
- **iOS (local only)** — needs Xcode ≥ 26 (same as the build check above) and a `RunnerUITests`
  target wired to patrol: in Xcode add a *UI Testing Bundle* named `RunnerUITests` to `Runner`,
  replace its test file with patrol's `PATROL_INTEGRATION_TEST_IOS_RUNNER(RunnerUITests)` stub, and
  run `patrol test --flavor dev --device "iPhone 16" …` against a booted simulator. Grant
  notifications when the dialog appears (the helper does it) — the simulator delivers local
  notifications normally; push needs a device.
- The notification suite waits for real deliveries (a task starting four minutes ahead): expect
  ~5 minutes per test. Exact timing needs *Alarms & reminders* allowed; without it Android may
  deliver a little late, which the helpers tolerate (they poll the shade for 7 minutes).
