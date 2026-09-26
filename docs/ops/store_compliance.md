# Store compliance (T9.2.10, T9.2.11, T9.2.12)

Answers for the App Store and Google Play forms, the declarations they need and the listing rules.
**Owner:** project lead. **When:** before the first external TestFlight group / closed test, then at every
release that adds a permission, an SDK, a data type or a feature that sends data off the device.
Sources: `app/android/app/src/main/AndroidManifest.xml` + plugin manifests (versions in `pubspec.lock`),
`app/ios/Runner/Info.plist`, `app/pubspec.yaml`, `supabase/README.md` and the privacy policy
(`site/*/privacy.html`). When an answer changes, update the policy, this file and the store form together.

## Blocking items found while preparing (fix before submission)

1. **Sign in with Apple token revocation** (backend): `account-delete` still returns `not_configured`
   (`revokeAppleTokens`, needs `APPLE_CLIENT_SECRET`). Apple requires revoking the user's tokens
   (`https://appleid.apple.com/auth/revoke`) when the account is deleted.
2. **No privacy manifest** (app platform): `app/ios/Runner/PrivacyInfo.xcprivacy` is missing
   (§ Privacy manifest).
3. **No iOS entitlements** (app platform): push (`aps-environment`), Sign in with Apple, Associated
   Domains, time-sensitive notifications.
4. **Usage strings in English only** (app platform): add `fr.lproj` / `ar.lproj` `InfoPlist.strings`
   (§ Usage strings).
5. **Unused microphone string** (app platform): `NSMicrophoneUsageDescription` is declared but audio notes
   are P2 ([2.2] T2.2.13); remove it for v1.0.
6. **Android Auto Backup** (app platform): on by default (no `allowBackup` / `dataExtractionRules`), so the
   Drift database and the `flutter_secure_storage` preferences would be copied to the user's Google backup
   and restored on another device with a stale outbox, a duplicated device id and undecryptable keys.
   Recommended: disable it — cloud sync is the backup.
7. **Guests with files never cleaned up** (backend): `private.stale_anonymous_users` skips guests with
   uploaded attachments; route them through `account-delete`. The policy only says guests "may" be deleted.
8. **Crashlytics symbols** (release): upload not wired (`docs/ops/firebase_prod.md` § 5).

## Apple (T9.2.10)

### App Privacy answers

App Store Connect › App › App Privacy. **Tracking: no** (no data is used to track, no App Tracking
Transparency prompt). Every collected type below: not used for tracking, purpose *App Functionality* only.

| Apple data type | Linked to user | What it is |
|---|---|---|
| Contact Info › Email Address | Yes | sign-in e-mail (Apple relay addresses included) |
| Contact Info › Name | Yes | display name, or the name Apple/Google share at sign-in |
| Health & Fitness › Health | Yes | quit-tracker entries (use, relapses, cravings), mood on check-ins |
| Health & Fitness › Fitness | Yes | exercise habits (counts, durations) |
| User Content › Photos or Videos | Yes | attachments (photos, video files) |
| User Content › Audio Data | Yes | audio files a user attaches (the bucket accepts them) |
| User Content › Other User Content | Yes | tasks, lists, items, notes, habits, logs, rules, settings |
| Identifiers › User ID | Yes | account id |
| Identifiers › Device ID | Yes | app-generated device id, push token |
| Usage Data › Product Interaction | Yes | last app opening per device (push routing), change history |
| Diagnostics › Crash Data | No | Crashlytics crash reports |
| Diagnostics › Other Diagnostic Data | No | device state and breadcrumb logs attached to crash reports |

- Not collected: Location, Sensitive Info, Contacts, Financial Info, Browsing History, Search History (search
  is local), Purchases, Advertising Data, Other Usage Data, Gameplay Content, Customer Support (support is by
  e-mail outside the app; add it when in-app feedback, [8.3] T8.3.17, ships).
- Crash data stays *not linked* only while Crashlytics never receives a user identifier
  (`docs/ops/firebase_prod.md` § 5). Local-only use collects nothing but crash data.
- Data processed only on the device (statistics, search, notification planning) is not "collected".

### Privacy manifest

`app/ios/Runner/PrivacyInfo.xcprivacy` must list the required-reason APIs used by code compiled into the app
target without its own manifest (SQLite from the `sqlite3` build hook, `home_widget`, `pdfrx`/PDFium,
`flutter_image_compress`, `path_provider_foundation` over FFI, Dart and app code) and mirror the App Privacy
table in `NSPrivacyCollectedDataTypes`.

| Category (`NSPrivacyAccessedAPICategory…`) | Reason | Why |
|---|---|---|
| `UserDefaults` | `CA92.1` | app and plugin settings read/written by the app itself |
| `UserDefaults` | `1C8F.1` | only once the widget App Group `group.app.everslot.shared` ships |
| `FileTimestamp` | `C617.1` | SQLite and the attachment cache read timestamps inside the app container |
| `SystemBootTime` | `35F9.1` | elapsed time for timers and performance measurement |
| `DiskSpace` | `E174.1` | free-space checks before writing attachments, exports and the database |

Plugin manifests checked in the pub cache (2026-09-26): `firebase_messaging`, `flutter_local_notifications`
and `workmanager` declare UserDefaults `CA92.1`; `shared_preferences` declares `1C8F.1`; `app_links`,
`connectivity_plus`, `device_info_plus`, `file_picker`, `flutter_secure_storage`, `flutter_timezone`,
`google_sign_in_ios`, `image_picker_ios`, `in_app_review`, `local_auth`, `package_info_plus`,
`quick_actions`, `share_plus` and `url_launcher` ship empty manifests; the Firebase iOS SDKs ship their own;
`sign_in_with_apple`, `home_widget`, `flutter_image_compress`, `pdfrx`, `path_provider_foundation` and
`sqlite3` ship none. Re-check after every dependency bump.

Skeleton — create it in Xcode (File › New › File › App Privacy) so it joins the Runner target, then fill it:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key><false/>
  <key>NSPrivacyTrackingDomains</key><array/>
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <!-- One dict per row of the App Privacy table. Types: EmailAddress, Name, Health, Fitness,
         PhotosorVideos, AudioData, OtherUserContent, UserID, DeviceID, ProductInteraction (linked),
         CrashData, OtherDiagnosticData (not linked) — each prefixed NSPrivacyCollectedDataType. -->
    <dict>
      <key>NSPrivacyCollectedDataType</key><string>NSPrivacyCollectedDataTypeEmailAddress</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
  </array>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key><string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key><array><string>CA92.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key><string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key><array><string>C617.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key><string>NSPrivacyAccessedAPICategorySystemBootTime</string>
      <key>NSPrivacyAccessedAPITypeReasons</key><array><string>35F9.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key><string>NSPrivacyAccessedAPICategoryDiskSpace</string>
      <key>NSPrivacyAccessedAPITypeReasons</key><array><string>E174.1</string></array>
    </dict>
  </array>
</dict>
</plist>
```

Check: Xcode › Product › Archive › Organizer › right-click the archive › *Generate Privacy Report*: every
component listed, no missing reason. An upload with a missing declaration triggers an `ITMS-91053` e-mail.

### Account deletion (guideline 5.1.1(v))

- In the app: *Settings › Account › Delete account* ([1.5] T1.5.12) deletes the account, not a
  deactivation; re-authentication with a fresh code; export offered first.
- On the web: `https://YOUR_SITE_DOMAIN/<lang>/delete-account.html` (steps, what is deleted, when).
- Sign in with Apple tokens must be revoked during deletion — blocking item 1.

### Sign in with Apple (guideline 4.8)

- Offered next to Google and the e-mail code with equal prominence, Apple-provided button ([1.5] T1.5.10).
- Apple sends the name only on the first sign-in; the app stores it in the profile.
- Private relay: Apple Developer › Certificates, Identifiers & Profiles › Services › *Sign in with Apple for
  Email Communication*: register the sending domain and `no-reply@YOUR_SITE_DOMAIN` (SPF must pass),
  otherwise codes and support replies to `@privaterelay.appleid.com` addresses bounce.
- Android web flow: Services ID with return URL `https://<YOUR_PROJECT_REF>.supabase.co/auth/v1/callback`;
  its client secret expires within 6 months (runbook in `docs/ops/runbooks.md`).

### Usage strings (`Info.plist`)

- `NSCameraUsageDescription` — keep.
  - FR: Everslot utilise l’appareil photo pour joindre des photos à vos tâches, éléments de liste et notes
    d’habitudes.
  - AR: يستخدم Everslot الكاميرا لإرفاق الصور بمهامك وعناصر قوائمك وملاحظات عاداتك.
- `NSPhotoLibraryUsageDescription` — keep.
  - FR: Everslot vous permet de joindre des photos de votre photothèque à vos tâches, éléments de liste et
    notes d’habitudes.
  - AR: يتيح لك Everslot إرفاق صور من مكتبتك بمهامك وعناصر قوائمك وملاحظات عاداتك.
- `NSFaceIDUsageDescription` — keep.
  - FR: Everslot utilise Face ID pour déverrouiller l’app lorsque le verrouillage est activé.
  - AR: يستخدم Everslot بصمة الوجه (Face ID) لفتح التطبيق عند تفعيل قفل التطبيق.
- `NSMicrophoneUsageDescription` — remove for v1.0 (audio notes are P2).

Notifications need no plist string: the app explains them before the system prompt ([7.2] T7.2.05).

### Export compliance

`ITSAppUsesNonExemptEncryption = false` is in `Info.plist`, and the `release` lane answers
`export_compliance_uses_encryption: false`. Justification: only encryption provided by the operating system
or standard HTTPS/TLS (Supabase, Firebase, Google and Apple sign-in) and the Keychain; no proprietary
cryptography. Re-answer when the optional SQLCipher database encryption ([8.3] T8.3.15, P2) ships — it still
uses a standard algorithm, but App Store Connect then asks about distribution in France (ANSSI declaration).

### Other review points

- 2.1 completeness: guest mode needs no demo account; the review notes explain it
  (`app/ios/fastlane/metadata/review_information/notes.txt`).
- 1.4.1 health: quit milestones show sources and the "not medical advice" disclaimer (T5.3.11, T6.6.05).
- 2.3.10: listings never name Android or Google Play (the checker below enforces it).
- 4.5.4: no marketing pushes; 5.1.1(i): privacy policy URL in the listing and in *Settings › About*.
- 5.1.1(iv): every permission is requested in context after an explanation; the app works when refused.
- Background modes (`fetch`, `processing`, `remote-notification`) are justified in the review notes.
- The app targets iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`): iPad screenshots are mandatory.

## Google Play (T9.2.11)

### Permissions in the release bundle

From the app manifest plus plugin and library manifests (checked on the resolved versions and on the merged
manifest of a September 2026 dev build). Compare with the real release bundle before each release:

```bash
bundletool dump manifest --bundle app/build/app/outputs/bundle/prodRelease/app-prod-release.aab \
  | grep -oE 'uses-permission[^>]*name="[^"]+"' | sed -E 's/.*name="([^"]+)"/\1/' | sort -u
```

| Permission | Declared by | Why, declaration |
|---|---|---|
| `INTERNET`, `ACCESS_NETWORK_STATE` | app, connectivity_plus, FCM, WorkManager | sync; normal permissions |
| `POST_NOTIFICATIONS` | app, notifications plugins, FCM | runtime on Android 13+, asked after a primer |
| `SCHEDULE_EXACT_ALARM` | app | exact reminders; user grant; no Play form (§ Exact alarms) |
| `RECEIVE_BOOT_COMPLETED` | app, WorkManager | re-schedule reminders after a reboot |
| `VIBRATE` | app, flutter_local_notifications | notification vibration |
| `WAKE_LOCK` | app, FCM, WorkManager | background sync and message handling |
| `USE_BIOMETRIC`, `USE_FINGERPRINT` | local_auth, androidx.biometric | optional app lock |
| `FOREGROUND_SERVICE`, `…_SHORT_SERVICE` | workmanager | expedited work; `shortService`: no FGS form |
| `com.google.android.c2dm.permission.RECEIVE` | FCM | push delivery |
| `app.everslot.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | androidx.core | signature-level, internal |

Must stay absent (a release must fail if one appears): `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`,
`READ_MEDIA_AUDIO`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `CAMERA`, `ACCESS_FINE_LOCATION`,
`ACCESS_COARSE_LOCATION`, `USE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `QUERY_ALL_PACKAGES`,
`com.google.android.gms.permission.AD_ID`, Health Connect permissions. If a dependency adds one, remove it in
the app manifest with `tools:node="remove"`.

### Data safety answers

Play Console › Policy › App content › Data safety.

- Collects or shares required user data: **yes**. Encrypted in transit: **yes**.
- Users can request deletion: **yes** — in the app and at `https://YOUR_SITE_DOMAIN/en/delete-account.html`.
  Partial deletion without deleting the account: **yes** (delete items; Trash › *Delete forever*).
- Shared with third parties: **no** — Supabase and Google Firebase process data on our behalf (service
  providers do not count as sharing). Processed ephemerally: **no** for every type.
- Independent security review: no. Families policy: not applicable (not designed for children).

| Play data type | Required or optional | Purposes |
|---|---|---|
| Personal info › Email address | optional (guest mode) | App functionality, Account management |
| Personal info › Name | optional | App functionality, Account management |
| Personal info › User IDs | required | App functionality, Account management |
| Health and fitness › Health info | optional | App functionality |
| Health and fitness › Fitness info | optional | App functionality |
| Photos and videos › Photos, Videos | optional | App functionality |
| Audio › Other audio files | optional | App functionality |
| Files and docs | optional | App functionality |
| App activity › Other user-generated content | required | App functionality |
| App activity › App interactions | required | App functionality (last-opened time, change history) |
| App info and performance › Crash logs | optional (switch in settings) | App functionality, Analytics |
| App info and performance › Diagnostics | optional | App functionality, Analytics |
| Device or other IDs | required | App functionality (device id, FCM token, Firebase installation id) |

Not collected: location (the time zone is a device setting, not location data), contacts, messages,
calendar (tasks are user content, not the device calendar — revisit with the P2 calendar overlay), web
history, financial info (quit costs are user content), advertising id.

### Exact alarms

- Everslot declares `SCHEDULE_EXACT_ALARM`, asks for it in context (onboarding or the first timed
  reminder) after an explanation, reacts to the permission-change broadcast and falls back to inexact alarms
  plus server push when it is refused (arch §9.7, [7.2]). No Play Console form is needed for it.
- `USE_EXACT_ALARM` is **not** declared: Play restricts it to alarm, timer and calendar apps and reviews
  every declaration; a planner with reminders may be refused, which would block releases. Revisit only if
  Play accepts the calendar use case (App content › Exact alarm permission).
- Test: with *Alarms & reminders* denied, reminders still arrive (inexact, up to about an hour late in
  Doze) and pushes cover other devices; with it granted, they fire on time.

### Photos and files

`image_picker` opens the system picker (`ACTION_GET_CONTENT` below API 36, the Photo Picker on 36+) and
`file_picker` the Storage Access Framework, so no media permission exists and no *Photo and video
permissions* declaration is needed. Recommended (app platform): set
`ImagePickerAndroid.useAndroidPhotoPicker = true` to use the Photo Picker on every version.

### Foreground services

Only `shortService` (WorkManager expedited work), exempt from the *Foreground service permissions*
declaration. A future running-timer notification ([8.2] T8.2.10, P2) that uses another type (for example
`specialUse`) needs that declaration and a video.

### Health apps declaration

Play Console › Policy › App content › Health apps: declare the health-related features truthfully — habit
tracking including exercise (activity and fitness) and quit trackers for smoking, alcohol and other habits
(choose the closest current category for substance-use reduction). Do not select medical, clinical,
medical-device or research options. No Health Connect access in v1.0 ([8.2] T8.2.14 is P2). The listing and
the app carry the "not medical advice" disclaimer.

### Notifications permission

`POST_NOTIFICATIONS` (Android 13+) is requested after a primer that explains reminders ([7.2] T7.2.05,
[8.3] T8.3.11). Refusing keeps the app usable: the in-app inbox still lists reminders and a banner offers to
enable them. Channels are created per section × profile ([7.2] T7.2.02). No Play declaration.

### Target API level

`compileSdk = 36`, `targetSdk = 36`, `minSdk = 24` (`app/android/app/build.gradle.kts`). Since
31 August 2026 new apps and updates must target API 36 (Android 16): compliant. The next bump usually lands
on 31 August of the following year — check Play Console › Policy status each spring.

### Other App content forms

- Privacy policy: `https://YOUR_SITE_DOMAIN/en/privacy.html`.
- App access: all functionality is available without special access (*Continue without account*).
- Ads: no ads. Advertising ID: not used.
- Target audience: 13 and over (matches the terms); not designed for children.
- Government, financial features, news, health research: no.
- Content rating (IARC): category productivity/utility; no user interaction, sharing, location or
  purchases. Quit-tracker presets name tobacco and alcohol: answer the controlled-substance question
  truthfully (references, no depiction).
- Pre-launch report (Test and release › Testing › Pre-launch report › Settings): on; fix accessibility and
  security findings before promoting a build.

## Age ratings

- App Store Connect › App Information › Age Ratings: *Alcohol, Tobacco, or Drug Use or References* =
  infrequent (quit presets and smoking milestones); *Medical or treatment information* = infrequent
  (milestones with disclaimer); everything else none; no unrestricted web access, no user-to-user content,
  no messaging, no advertising. Expect 13+; that is fine for a productivity app.
- Google Play: IARC questionnaire as above.

## Store listings (T9.2.12)

Texts live in fastlane layout and are uploaded with `bundle exec fastlane metadata` (from `app/android` or
`app/ios`). Locales: Play `en-US`, `fr-FR`, `ar`; App Store `en-US`, `fr-FR`, `ar-SA`.

| Store | File | Limit | EN / FR / AR (2026-09-26) |
|---|---|---|---|
| Play | `title.txt` | 30 chars | 27 / 29 / 22 |
| Play | `short_description.txt` | 80 chars | 77 / 77 / 75 |
| Play | `full_description.txt` | 4000 chars | 3447 / 3959 / 3305 |
| Play | `changelogs/default.txt` | 500 chars | 236 / 277 / 221 |
| App Store | `name.txt`, `subtitle.txt` | 30 chars each | 27, 26 / 29, 24 / 22, 25 |
| App Store | `description.txt` | 4000 chars | 3447 / 3959 / 3305 |
| App Store | `keywords.txt` | 100 bytes | 99 / 98 / 94 |
| App Store | `promotional_text.txt` | 170 chars | 162 / 163 / 130 |
| App Store | `release_notes.txt` | 4000 chars | 236 / 277 / 221 |
| App Store | `review_information/notes.txt` | 4000 bytes | 2109 |

Rules: describe only shipped (P0/P1) features; never name the other platform, competitors or trademarks;
no "free", "best", "#1", emoji or all-caps words in titles; keywords are comma-separated without spaces and
do not repeat words of the name; no trailing newline (stores count every character).

Run the checker from the repository root after every edit:

```bash
python3 - <<'EOF'
import pathlib, re, sys
A, I = pathlib.Path("app/android/fastlane/metadata/android"), pathlib.Path("app/ios/fastlane/metadata")
LIM = {"title.txt": 30, "short_description.txt": 80, "full_description.txt": 4000,
       "changelogs/default.txt": 500, "name.txt": 30, "subtitle.txt": 30, "description.txt": 4000,
       "keywords.txt": -100, "promotional_text.txt": 170, "release_notes.txt": 4000}   # < 0: bytes
OTHER = {A: r"\b(iPhone|iPad|iOS|App Store|TestFlight)\b", I: r"\b(Android|Google Play|Play Store)\b"}
bad = []
for base, locs in ((A, ("en-US", "fr-FR", "ar")), (I, ("en-US", "fr-FR", "ar-SA"))):
    for loc in locs:
        for f in sorted((base / loc).rglob("*.txt")):
            rel, t = f.relative_to(base / loc).as_posix(), f.read_text(encoding="utf-8")
            lim = LIM.get(rel)
            if lim:
                n = len(t.encode()) if lim < 0 else len(t)
                print(f"{loc:5} {rel:24} {n:5}/{abs(lim)}")
                bad += [f"{f}: too long"] if n > abs(lim) else []
            bad += [f"{f}: whitespace at start/end"] if t != t.strip() else []
            bad += [f"{f}: names the other platform"] if re.search(OTHER[base], t) else []
notes = (I / "review_information/notes.txt").read_text(encoding="utf-8").encode()
bad += ["review notes > 4000 bytes"] if len(notes) > 4000 else []
print("\n".join(bad) or "OK")
sys.exit(1 if bad else 0)
EOF
```

Before uploading:

- Replace `YOUR_SITE_DOMAIN` in the App Store URLs (`docs/ops/app_identity.md` § Website).
- `review_information/`: fill name, phone and e-mail; **empty** `demo_user.txt` and `demo_password.txt`
  (guest mode needs no account; empty values make *Sign-in required* off).
- `copyright.txt`: replace `[DEVELOPER NAME]`. Categories: `PRODUCTIVITY` / `HEALTH_AND_FITNESS`.
- Release notes: `release.yml` regenerates only `en-US/changelogs/default.txt` (Play) from the commits;
  update the FR/AR changelogs and the three App Store `release_notes.txt` by hand at each release. The first
  App Store version cannot have "What's New": remove `release_notes.txt` from that first upload if App Store
  Connect refuses it.

### Screenshots (to produce)

Generated by an integration test with demo data ([8.3] T8.3.16) in EN, FR and AR — not written yet
(owner: release). Scenes: week table zoomed to 15-minute slots, day list, nested checklist with statuses,
habits week matrix, quit dashboard, habit insights, Today, plus one Arabic RTL shot per store.

- App Store: 6.9-inch iPhone (1320 × 2868 or 1290 × 2796) and 13-inch iPad (2064 × 2752 or 2048 × 2732).
- Google Play: at least 4 phone screenshots ≥ 1080 px on the short side (9:16), 7- and 10-inch tablet
  screenshots, the 1024 × 500 feature graphic and the 512 × 512 icon (`docs/ops/app_identity.md`).

## Questions for the lawyer

- Controller identity and address; EU representative (GDPR art. 27) if there is no EU establishment.
- Health data (GDPR art. 9): is choosing to create a quit tracker an explicit consent, or does the app need
  a separate consent step before the first quit tracker / health entry? The policy text assumes consent.
- Crash reporting is on by default with an opt-out: acceptable for EU users (ePrivacy art. 5(3)), or must it
  become opt-in?
- Governing law, consumer rights, Apple's minimum EULA terms; minimum age (13 vs national ages such as 15 in
  France); retention periods (server logs 28 days, backups 30 days, support e-mails); transfer safeguards for
  Supabase and Google.
