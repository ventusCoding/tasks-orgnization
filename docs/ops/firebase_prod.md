# Firebase production setup (T9.2.06)

**Owner:** project lead. **When:** before the first TestFlight / Play internal build that should receive
pushes. **Done when:** a push reaches a production TestFlight build, and the FCM service-account key exists
only as the Supabase Edge Function secret `FCM_SERVICE_ACCOUNT`.

Firebase is used for two things only: **Cloud Messaging** (push delivery, sent by the `push-dispatch` and
`sync-nudge` Edge Functions) and **Crashlytics**. No Analytics, no other Firebase product.

## 0. Repository state to fix first (outside this doc's scope)

- `app/lib/firebase_options.dart` is a placeholder (`isConfigured = false`): generate the real options with
  the FlutterFire CLI as described in `docs/guide.md` (Firebase section) and set `FIREBASE_ENABLED` in the
  prod env file.
- iOS has no entitlements file yet: add the *Push Notifications*, *Background Modes* (remote notifications,
  background fetch, background processing), *Time Sensitive Notifications* and *Sign in with Apple*
  capabilities ([1.2] T1.2.14, [1.5] T1.5.10).
- Symbol upload is not wired in the fastlane lanes yet (step 5).

## 1. Project

- [ ] Firebase console › Add project `everslot-prod` in the same Google account as `everslot-dev`. On the
      creation screen **turn "Enable Google Analytics for this project" off**. If a project already has it:
      Project settings › Integrations › Google Analytics › Unlink.
- [ ] Plan: Spark (free) covers FCM and Crashlytics. Move to Blaze only if another product needs it — then
      create a budget alert (`docs/ops/cost_quotas.md`).
- [ ] Project settings › General › Your apps: add the Android app `app.everslot` and the iOS app
      `app.everslot` (App Store ID and Team ID once known). Never commit `google-services.json` /
      `GoogleService-Info.plist` with anything but public identifiers (they contain no secrets).
- [ ] Project settings › Users and permissions: owner = project lead with 2-step verification; no other
      owners; remove unused members.

## 2. APNs authentication key

- [ ] Apple Developer › Certificates, Identifiers & Profiles › Keys › **+** › enable *Apple Push
      Notifications service (APNs)* → download `AuthKey_<KEY_ID>.p8` (it can be downloaded once). Keep it
      in the password manager, never in the repository.
- [ ] Firebase console › Project settings › Cloud Messaging › Apple app configuration (`app.everslot`) ›
      *APNs Authentication Key* › Upload the `.p8` with its Key ID and the Team ID. The same key serves
      sandbox and production and can also be uploaded to `everslot-dev`.
- [ ] If the key is ever revoked: create a new one, upload it to both projects, then revoke the old key.

## 3. FCM HTTP v1 API

- [ ] Project settings › Cloud Messaging shows *Firebase Cloud Messaging API (V1): Enabled*. If not:
      Google Cloud console (project `everslot-prod`) › APIs & Services › Library › *Firebase Cloud Messaging
      API* › Enable. The legacy API no longer exists; nothing else to switch on.

## 4. Least-privilege sender account

The Edge Functions only need `cloudmessaging.messages.create`. Do **not** use the auto-created
`firebase-adminsdk-…` account (it has broad admin roles).

```bash
PROJECT=everslot-prod
SA=fcm-sender@$PROJECT.iam.gserviceaccount.com
gcloud iam roles create fcmSender --project=$PROJECT --title="FCM sender" \
  --permissions=cloudmessaging.messages.create --stage=GA
gcloud iam service-accounts create fcm-sender --project=$PROJECT \
  --display-name="Everslot FCM sender (Supabase Edge Functions)"
gcloud projects add-iam-policy-binding $PROJECT \
  --member="serviceAccount:$SA" --role="projects/$PROJECT/roles/fcmSender"
# Alternative to the custom role: --role=roles/firebasecloudmessaging.admin (FCM API Admin).
gcloud iam service-accounts keys create fcm-sender.json --iam-account=$SA
supabase secrets set --project-ref <YOUR_PROJECT_REF> \
  FCM_SERVICE_ACCOUNT="$(base64 -i fcm-sender.json | tr -d '\n')"
rm -P fcm-sender.json    # macOS; use `shred -u` on Linux. Keep no other copy: rotate instead.
```

- If key creation is blocked by the organization policy `iam.disableServiceAccountKeyCreation`, grant an
  exception for this project only (Google Cloud › IAM & Admin › Organization policies).
- Check: `curl -s https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/health` → `"fcm_configured": true`.
- **Rotation** (yearly, on exposure, or when someone with access leaves): create a new key, `supabase
  secrets set` it, check `health` and send a test push (step 7), then delete the old key:
  `gcloud iam service-accounts keys list --iam-account=$SA --managed-by=user` and
  `gcloud iam service-accounts keys delete <OLD_KEY_ID> --iam-account=$SA`.
- Also list keys of the default `firebase-adminsdk-…` account and delete any user-managed key nobody uses.

## 5. Crashlytics

- [ ] Firebase console › Crashlytics › enable for both apps.
- [ ] App behaviour (already in `app/lib/bootstrap.dart`): handlers installed in release builds only.
      Still to implement in [8.3]: the *Crash reports* switch (`user_settings.privacy.crashReporting`)
      calls `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(...)`.
- [ ] No personal data: never call `setUserIdentifier` with the account id or e-mail, never log item titles.
      The privacy labels (`docs/ops/store_compliance.md`) assume crash data is *not linked* to the user.
- [ ] **iOS symbols**: add `upload_symbols_to_crashlytics(gsp_path: "Runner/GoogleService-Info.plist")`
      after `build_app` in the `beta` lane of `app/ios/fastlane/Fastfile`, or the Crashlytics run-script
      build phase. Without dSYMs, native iOS frames stay unsymbolicated.
- [ ] **Dart symbols**: only if release builds use `--obfuscate --split-debug-info=build/symbols`; then
      upload them: `firebase crashlytics:symbols:upload --app=<FIREBASE_APP_ID> build/symbols`.
- [ ] Check: force a test crash from a prod-config release build (e.g. a crash button in the debug menu)
      and see it in the dashboard within a few minutes. Alerts: `docs/ops/monitoring.md` § Crashlytics.

## 6. Analytics stays off

- [ ] `app/pubspec.yaml` has no `firebase_analytics` (true today — keep it that way; adding it changes the
      privacy policy, the App Privacy labels and the Data safety form).
- [ ] Belt and braces for transitive SDKs (owner: app platform): `FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED`
      = `YES` in `Info.plist` and
      `<meta-data android:name="firebase_analytics_collection_deactivated" android:value="true"/>` in the
      Android manifest.
- [ ] Before each release, check that the merged Android manifest has no
      `com.google.android.gms.permission.AD_ID` (`docs/ops/store_compliance.md` § Permissions).

## 7. Acceptance test (record the evidence in the release checklist)

1. Install the TestFlight build (production Supabase + `everslot-prod` Firebase), sign in, allow
   notifications, then close the app.
2. Confirm the device has a token (SQL editor):
   `select platform, app_version, push_enabled, push_token is not null as has_token, last_seen_at
    from app.devices where user_id = '<USER_ID>';`
3. On a second device with the same account, create a task starting in 3 minutes with a reminder "at start".
   The TestFlight device does not cover it locally, so the dispatcher pushes it.
4. The notification arrives on the TestFlight device; `private.push_deliveries` has a `sent` row:
   `select outcome, error_code, created_at from private.push_deliveries order by created_at desc limit 5;`
5. Tick the Progress box of T9.2.06 only after this passes.

## Sign-off

| Step | Evidence | Date | By |
|---|---|---|---|
| 1 Project, apps, members | | | |
| 2 APNs key uploaded | | | |
| 3 FCM v1 enabled | | | |
| 4 Sender account, secret set, health true | | | |
| 5 Crashlytics + symbols | | | |
| 6 Analytics off | | | |
| 7 Push reached TestFlight build | | | |
