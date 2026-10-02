# Section 8.3 — Settings, Data Portability, Privacy & Onboarding

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.3, 1.4, 1.5, 7.1
> Architecture: §8.5 (settings JSON), §6.17 (security), §9.3 (trash & retention), §7.6 (account-delete)

## Goal

One coherent Settings area backed by synced, versioned settings; full control over the user's data
(export, import, trash, deletion); privacy & security options; and a first-run experience that sets the
app up correctly (language, time zone, week start, notifications).

## Scope

**In:** settings information architecture and screens, typed settings repository, regional settings,
section defaults, sync & devices screen, export/import, trash, app lock, notification privacy, local DB
encryption, onboarding, sample data, accessibility options, about/legal, feedback.
**Out:** Notification rule editors and quiet hours UI ([7.1], [7.5]); account deletion backend ([1.5]).

## Progress

- [x] T8.3.01 — Typed settings repository & settings screen structure
- [x] T8.3.02 — Appearance & language settings
- [x] T8.3.03 — Regional settings (time zone, week start, formats, day start)
- [x] T8.3.04 — Sync & devices screen
- [x] T8.3.05 — Section defaults pages (Plan, Lists, Habits, Insights)
- [x] T8.3.06 — Trash (restore / delete forever)
- [x] T8.3.07 — Export all data (JSON + CSV)
- [x] T8.3.08 — Import / restore from a Everslot export
- [x] T8.3.09 — App lock & app-switcher privacy
- [x] T8.3.10 — Hide notification content
- [x] T8.3.11 — Onboarding flow
- [x] T8.3.12 — Accessibility options
- [x] T8.3.13 — About, legal & health disclaimer
- [x] T8.3.14 — Import from other apps
- [x] T8.3.15 — Local database encryption
- [x] T8.3.16 — Sample data / demo mode
- [ ] T8.3.17 — In-app feedback & diagnostics

## Tasks

### T8.3.01 — Typed settings repository & settings screen structure
**Priority:** P0 · **Size:** M · **Depends on:** [1.4], [1.3]
**Description:** A typed repository over `user_settings` (one row per namespace, deterministic id) with
freezed models per namespace (arch §8.5), defaults, versioned JSON upgrades; plus the Settings root
screen: Account · Appearance · Regional · Plan · Lists · Habits · Insights · Notifications ·
Sync & data · Privacy & security · Accessibility · About.
**Implementation notes:** `SettingsRepository.watch<T>(namespace)`; writes are debounced per field edit
and go through the outbox; unknown JSON keys are preserved (forward compatibility).
**Acceptance criteria:** changing a setting on device A appears on device B after sync; corrupted/older
JSON falls back to defaults without crashing and logs a warning.
**Tests:** unit tests per namespace (defaults, round-trip, upgrade from v0 fixture); widget test of root screen.
**Notes:** Hand-written typed namespaces (ADR-016, no freezed) in `features/settings/domain/settings_models.dart` over `SettingsCodec` (defaults, `"v"` upgrades from v0, unknown keys preserved, problems logged as warnings); `SettingsWriter` writes only changed keys and debounces per-field edits into one outbox patch; typed providers (`appearanceSettingsProvider`, `regionalSettingsProvider`, `habitsDefaultsProvider`, `checklistsDefaultsProvider`, `statsDefaultsProvider`, `privacySettingsProvider`). Root screen: Account · General · Sections (+ Notifications, Categories, Tags) · Data & privacy · Help; goldens in `test/features/settings/goldens/`.

### T8.3.02 — Appearance & language settings
**Priority:** P0 · **Size:** S · **Depends on:** T8.3.01
**Description:** Theme (system/light/dark), dynamic color (Android 12+), density (comfortable/compact),
language (System, English, Français, العربية) with instant switch and RTL flip.
**Acceptance criteria:** switching language updates all visible strings, date formats and layout
direction without restart; choice persists and syncs (profile `locale`).
**Tests:** widget tests switching locale/theme; goldens in AR.
**Notes:** Theme, density, language (profile `locale`; instant switch + RTL flip verified through `EverslotApp`), Arabic-Indic digits, live preview; AR/dark/2x goldens. Dynamic color (Android 12+) is not offered: it needs the `dynamic_color` package, which is not in arch §3 — deferred.

### T8.3.03 — Regional settings (time zone, week start, formats, day start)
**Priority:** P0 · **Size:** S · **Depends on:** T8.3.01, [1.5]
**Description:** Home time zone (auto-detect with manual override), current zone display, week start
(Mon/Sat/Sun/any), 12/24-hour clock, date format preview, habit **day starts at** (e.g. 04:00), currency
for quit savings.
**Acceptance criteria:** changing week start re-lays out week table, month view and all week-based stats;
changing day start shifts habit day boundaries for *future* logs only (existing `local_date`s unchanged).
**Tests:** unit tests on week computations for each week start; widget test for pickers.
**Notes:** Home zone (searchable picker, or "follow this device" = `regional.homeZoneAuto`), current zone, week start (any weekday, profile), 12/24 h with a date/time preview, habit day start (`habits.dayStartMinutes`, applies to future logs — stored `local_date`s are never rewritten), savings currency (`regional.currency`). Consumers read `userPreferencesProvider`.

### T8.3.04 — Sync & devices screen
**Priority:** P0 · **Size:** S · **Depends on:** [1.4] (sync status + device registry)
**Description:** Sync status (state, last success, pending outbox count, last error with details),
*Sync now*, *Force full resync* (confirmation), devices list (name, platform, last seen, push on/off)
with *Revoke device* (disables push; signs out that device on next contact).
**Acceptance criteria:** pending count decreases live during a push; revoke hides the device and stops pushes.
**Tests:** widget tests with fake sync states; pgTAP for the revoke RPC policy.
**Notes:** Status card (phase, last success, live pending/failed outbox counts, retry/discard rejected changes, last error with copy), Sync now, Force full resync behind a confirmation, devices list (revoked hidden, this device first, push on/off, Remove → `app.revoke_device`; pgTAP policy test in `supabase/tests/database/080_devices.test.sql`), local-only card. The devices list does not auto-retry offline (manual Retry). Widget tests: `test/features/settings/sync_page_test.dart`.

### T8.3.05 — Section defaults pages (Plan, Lists, Habits, Insights)
**Priority:** P1 · **Size:** M · **Depends on:** T8.3.01
**Description:** Planner: default view, default duration, default tracking mode, missed-grace minutes,
work hours, roll-over behaviour. Lists: require reason for waiting/blocked, auto-complete parents,
progress mode, completed items position. Habits: default skip policy, streak freezes default.
Insights: default period, compare with previous period, week start override.
**Tests:** widget tests; unit tests verifying consumers read the new defaults.
**Notes:** Pages Plan / Lists / Habits / Insights (`presentation/pages/section_pages.dart`). Plan writes the `planner` keys the planner (`PlannerSettings`), the grid (`WorkSettings`) and stats already read (duration, tracking, missed grace, work hours/days, roll-over, actual-time prompt); the default view = the planner saved view flagged default (`setDefault`). `stats.defaultPeriod` is now a stats period key (`thisWeek`, `rolling:30`…) — the earlier enum would have overwritten keys like `rolling:90`. Consumer tests: `test/features/settings/section_defaults_test.dart`. TODO(integration): new checklists and new habits should read `checklistsDefaultsProvider` / `habitsDefaultsProvider` (checklists/habits creation flows don’t yet).

### T8.3.06 — Trash (restore / delete forever)
**Priority:** P1 · **Size:** M · **Depends on:** T8.3.01, [1.4]
**Description:** Lists tombstoned tasks, checklists, items (with path), habits and attachments deleted in
the last 30 days; *Restore* (restores the subtree/children deleted in the same operation) and
*Delete forever* (RPC `app.purge_now(entity_type, ids)` — `security definer`, only own tombstoned rows).
**Acceptance criteria:** restoring a checklist item restores its descendants that were deleted with it but
not ones deleted earlier; purge removes storage objects for attachments.
**Tests:** unit tests for "deleted together" grouping (same operation id in activity events); pgTAP for purge RPC.
**Notes:** Trash = deletions of the last 30 days whose container is live (tasks, lists, list items with their path, habits, attachments). "Deleted together" = same operation = same `deleted_at` instant (features cascade inside one `SyncWriter` transaction; stored as ISO text with microseconds) — used instead of scanning activity events, which not every feature writes. Restore = one synced operation (+ `restored` activity event). Delete forever: synced accounts call `app.purge_now` (refused while the deletion itself is unpushed, nothing removed when offline), then rows + tombstoned children + outbox entries + attachment files are removed locally (mirrors the server cascade); local-only devices purge locally. pgTAP for the RPC: `supabase/tests/database/100_purge_ops.test.sql`. Tests: `test/features/settings/trash_repository_test.dart`, `trash_screen_test.dart`.

### T8.3.07 — Export all data (JSON + CSV)
**Priority:** P1 · **Size:** M · **Depends on:** [1.4]
**Description:** Export from the local DB (works offline): full-fidelity JSON (`everslot-export-v1`, one
array per table, schema version, export time, app version) and a CSV zip (one CSV per table, human
column names); optional inclusion of attachment files; shared via system share sheet.
**Acceptance criteria:** export of 100 000 rows completes in < 20 s in a background isolate with progress;
output validates against the JSON schema in `fixtures/schemas/export-v1.json`.
**Tests:** unit test exporting a fixture DB and validating schema; CSV escaping tests (commas, newlines, RTL text).
**Notes:** `ExportService` (`features/settings/application/export_service.dart`) pages every synced table of the local DB (registry order, live rows, server JSON representation, sync internals dropped) with progress, then encodes in a background isolate: JSON (`everslot-export-v1`, validated against `fixtures/schemas/export-v1.json` by a tiny in-test schema checker), or a zip of one CSV per table (human headers, UTF-8 BOM, formula-injection prefix, RFC 4180 quoting) + `manifest.json`; optional attachment files under `attachments/<id>/`. 100 000 rows export in ~1 s in the test. Shared through `share_plus`; UI in Settings › Export & import (`DataPage`).

### T8.3.08 — Import / restore from a Everslot export
**Priority:** P1 · **Size:** L · **Depends on:** T8.3.07
**Description:** Import a Everslot JSON export as **Restore** (same account: upsert by id, LWW) or
**Copy** (another account: new ids with consistent remapping of all foreign keys, occurrence ids re-derived).
Dry-run preview (counts per type, conflicts), then apply in batches through the normal outbox.
**Acceptance criteria:** export → wipe → import yields identical data (golden comparison); copy mode
never collides with existing ids.
**Tests:** round-trip test; remapping unit tests (deterministic v5 ids re-derived).
**Notes:** `ImportService` (`features/settings/application/import_service.dart`) opens a JSON or zip export in an isolate (CSV zips are refused — they are not lossless), dry-runs, then writes batches of 400 rows through `SyncWriter` (cause `import`). Restore is offered only when the export's profile id is the signed-in user; per row the newer `updated_at` wins (conflicts are counted as "kept"), "Replace newer changes" overrides, identical rows are skipped and locally deleted rows come back when the export wins. Copy (`IdRemapper`, domain) gives v7 ids to ordinary rows, re-derives v5 ids from `standardIdRecipes` (occurrences, day states, settings, tag links, runs, revisions, inbox via the remapped `dedupe_key`, default categories / sections / vocab / rules / profiles, achievements) — converging rows merge with the target account's — and rewrites every exported id found in columns, JSON values and composite strings (`storage_path`, `dedupe_key`); the target keeps its own profile, built-in saved views whose entry key isn't stored are skipped, copied attachments upload again from the zip's files. Round-trip compares exports ignoring `updated_at` / `origin_device_id` (written by the importing device).

### T8.3.09 — App lock & app-switcher privacy
**Priority:** P1 · **Size:** M · **Depends on:** T8.3.01
**Description:** Optional lock with biometrics or device credential (`local_auth`), timeout (immediately,
1/5/15 min), lock on cold start; blur/hide content in the app switcher; widgets and notifications
unaffected unless T8.3.10 is on.
**Acceptance criteria:** lock survives app kill; failure/cancel keeps content hidden; accessibility-friendly unlock.
**Tests:** widget tests with fake authenticator; manual QA.
**Notes:** `features/privacy/`: `appLockProvider` (cold start locks once the privacy namespace has loaded; content stays covered until then) relocks on `AppLifecycleService.onReturn` when the background stay reached the timeout (0/1/5/15 min; an `inactive`-only return such as the biometric sheet never locks; the one return caused by Android's device-credential screen during a successful unlock is ignored). `AppLockGate` sits in the `MaterialApp.router` builder above every route: lock screen (auto prompt once, then an *Unlock* button; content excluded from semantics) or a plain cover while `inactive`/`paused` when app-switcher privacy or the lock is on. Android also sets `FLAG_SECURE` (channel `app.everslot/privacy`). Enabling the lock first checks a device screen lock exists and authenticates once. Settings › Privacy & security replaces the placeholder (lock, timeout, app switcher, hide notification content, crash reports). Device QA of the iOS snapshot cover still pending (Xcode 26).

### T8.3.10 — Hide notification content
**Priority:** P1 · **Size:** S · **Depends on:** [7.2]
**Description:** Privacy option: system notifications show generic text ("Reminder from Everslot");
full content visible in the inbox after unlock. Applied by the planner to local and push payloads.
**Tests:** unit test that planned payloads are redacted when enabled.
**Notes:** The planner already redacted local payloads (title/body/subtitle/images, `authenticationRequired`); push content is rendered by the device planner, so it ships redacted too. Added: the running-timer surface (Android ongoing notification and iOS Live Activity) shows only "Reminder from Everslot" + the chronometer and re-renders when the setting changes. The toggle also lives on the Privacy page (both keys written, as on the Notifications page).

### T8.3.11 — Onboarding flow
**Priority:** P1 · **Size:** M · **Depends on:** T8.3.02, T8.3.03, [1.5], [7.2]
**Description:** First run after sign-in: welcome → language → time zone & week start confirmation →
choose what to track (Plan / Lists / Habits / Quit) → notification permission **primer** (explain value,
then OS prompt; Android exact-alarm explanation when relevant) → optional starter templates (morning
routine checklist, water habit, 15 push-ups habit, quit smoking) → Today.
**Acceptance criteria:** skippable at every step; re-runnable from Settings; no OS permission prompt
without a primer; completion stored in `profiles.onboarding_completed_at`.
**Tests:** integration test (patrol) through the flow incl. permission dialog.
**Notes:** `OnboardingStep` = welcome → essentials (language, zone, week start, clock — T1.5.05) → what to track → notifications → starters; Skip on every step finishes with the detected values. The notifications step is the primer itself: the OS prompt only follows its *Allow* button, and on Android a granted permission without exact alarms shows the precise-reminders explanation + button. Track choices (Plan / Lists / Habits / Quit) only filter the starters offered — every tab stays available (no section hiding). Starters (`OnboardingStarters`): built-in *Morning routine* list, *Drink water* and *15 push-ups* habit templates, *Stop smoking* quit tracker, created with the regular services in the user's language. Re-runnable from Settings › Help › *Run the setup again*. `patrol_test/onboarding_test.dart` passed on the Android emulator (API 34) including the system dialog.

### T8.3.12 — Accessibility options
**Priority:** P1 · **Size:** S · **Depends on:** T8.3.01
**Description:** Reduce motion (overrides system), haptics on/off, high-contrast category palette, larger
week-table text, "always show text labels on status pills".
**Tests:** widget tests verifying options propagate via theme extensions.
**Notes:** Settings › Accessibility (keys already in `appearance`): reduce motion and haptics keep their channels (`ReduceMotionScope`, `Haptics`); the other three travel as the `AccessibilityPrefs` theme extension (`context.a11y`, set in `app.dart`). High contrast: `CategoryColors.background/accent(highContrast:)` everywhere categories are drawn (tiles, chips, filters, editors; charts keep their data-viz palette) — accents ≥ 4.5:1 on the surface, tile text ≥ 4.5:1 for every palette color (tested). Larger week-table text: +2 pt on planner tiles. Status labels: planner tiles add the status word (done, missed, skipped, cancelled, in progress) and completed list items get a *Completed* pill. Preview of category tiles on the page.

### T8.3.13 — About, legal & health disclaimer
**Priority:** P1 · **Size:** S · **Depends on:** T8.3.01
**Description:** Version/build, open-source licenses (`LicenseRegistry` + bundled font licenses), privacy
policy & terms links ([9.2]), health information disclaimer (quit milestones are general public-health
information, not medical advice), support contact, *Rate Everslot* (`in_app_review`, never auto-prompted
more than once per 90 days).
**Tests:** widget test; unit test of review-prompt throttling.
**Notes:** Settings › About: version (`package_info_plus`), privacy policy / terms / help pages under `SITE_URL` and `SUPPORT_EMAIL` (new optional env keys, hidden while placeholders — the site is T9.2.09), open-source licenses page (`LicenseRegistry` incl. the bundled Inter / Noto Sans Arabic OFL texts), health disclaimer, *Rate Everslot*. `ReviewService`: the user's tap shows the in-app sheet when allowed, else the store page; the only automatic prompt follows a 30+ day streak celebration and is throttled to once per 90 days per device (`local_kv`).

### T8.3.14 — Import from other apps
**Priority:** P2 · **Size:** L · **Depends on:** T8.3.08
**Description:** Importers: Loop Habit Tracker (CSV/SQLite backup) → habits + logs; Google Keep (Takeout
JSON) → checklists/items (+ images); Todoist/TickTick CSV → tasks (recurrence text best-effort); plain
indented text/Markdown → nested items ([4.5]).
**Tests:** fixture files per source; mapping unit tests.
**Notes:** Pure parsers in `features/settings/domain/external_import.dart` (RFC 4180 `CsvReader`, `LoopImport` for the CSV zip — combined or per-habit `Checkmarks.csv` — and the `.db` backup read read-only with `sqlite3`, `KeepImport`, `TodoistImport` through the quick-add parser, `TickTickImport` with RRULEs and zoned instants) → `ExternalImportPlan`; `ExternalImportService` writes through the feature services (habit history via the new `CheckInService.importHistory`, batched, source `import`; lists with labels → tags and Keep images → attachments; tasks with labels/sections → tags). Loop: only manual check-ins (value 2) and skips are taken, numerical amounts ÷ 1000, "N in D days" → daily / every N days / N× per week or month (others approximated and reported). Todoist P1…P4 → urgent…none; TickTick completed tasks are left out. Text / Markdown reuses the [4.5] outline parser. Preview lists counts and what was approximated or left out. Source names are product names (not translated). Fixtures in `test/features/settings/fixtures/external/`.

### T8.3.15 — Local database encryption
**Priority:** P2 · **Size:** L · **Depends on:** T8.3.09
**Description:** Optional SQLCipher-encrypted Drift database with key in secure storage; migration from
plain DB (export → encrypted DB → verify → delete plain file); performance check vs budgets.
**Tests:** migration integration test; perf comparison recorded.
**Notes:** SQLite3MultipleCiphers instead of SQLCipher (ADR-020): the sqlite3 build hook now builds it for everyone (`hooks.user_defines` in the workspace pubspec) — plain files open unchanged, `PRAGMA key` opens encrypted ones, no OpenSSL. `DatabaseEncryption` (`core/database`): random passphrase in the Keychain / Keystore (`first_unlock_this_device`, readable by background isolates after the first unlock); Settings › Privacy › *Encrypt data on this device* records the wish, applied at the next start before the database opens (copy → `rekey` → quick_check + per-table row counts → swap → delete the plain file; any failure leaves the original). `AppDatabase` opens with the key whenever the file header says it is encrypted. Recorded (macOS host, 20 000 rows, 20 full scans with `LIKE`): plain 32 ms, encrypted 156–207 ms (worst case: every page decrypted); conversion of the 20 000-row file ≈ 100 ms; indexed screen queries stay within budget. `patrol_test/encryption_test.dart` passed on the Android emulator (real Keystore, ARM build).

### T8.3.16 — Sample data / demo mode
**Priority:** P2 · **Size:** S · **Depends on:** [3.1], [4.1], [5.1]
**Description:** Generate realistic data (6 months of tasks, checklists, habits with plausible streaks,
quit tracker with cravings) for screenshots, demos and manual stats testing; isolated demo account or
local-only flag; one-tap removal.
**Tests:** generator determinism with seed; stats screens render with generated data.
**Notes:** `features/demo/`: pure `DemoGenerator` (seeded `Random`, 182 days: six recurring series with weekday-aware done/skip history improving over time, four one-offs around today, three lists from the localized built-in templates with spread statuses, five habits with streaky check-ins (yesterday's success raises today's odds) and amounts, a smoking quit tracker 150 days old with two slips and Poisson cravings fading over time). `DemoService` writes it through the regular services — occurrence history via the new `OccurrencesRepository.importHistory` (each at its own instant through `runAutomatic`, so completion times and activity events are in the past), habit history via `CheckInService.importHistory`, relapses / cravings via `QuitService` — and keeps the created ids in `local_kv` for one-tap removal (to the trash). Debug menu › Sample data; refused for cloud accounts (local-only mode only) so it never syncs.

### T8.3.17 — In-app feedback & diagnostics
**Priority:** P2 · **Size:** S · **Depends on:** T8.3.13
**Description:** "Send feedback" composes an email with optional diagnostics (app/OS version, device
model, sync state, last error codes — no content, no ids beyond device id) the user can review before sending.
**Tests:** unit test that diagnostics contain no user content.
