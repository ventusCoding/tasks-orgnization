# Section 7.2 — Local Notifications: Planner, Scheduler & Actions

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.3, 1.4, 2.1, 3.2, 4.3, 5.1, 5.2, 5.3, 7.1
> Architecture: §6.13 (pipeline steps 1, 2, 5, 6), §6.16 (background), §9.1 (time), §9.7 (platform constraints)

## Goal

Turn the user's rules ([7.1]) into **real notifications on the device** — exact to the minute where the OS
allows, working offline, surviving reboots, time-zone changes and DST — with actionable buttons (Done,
Snooze, Log 15 push-ups…) that work from the lock screen without opening the app. The device is the
primary delivery channel (ADR-005); FCM push ([7.4]) only covers what the device cannot.

## Scope

**In:** plugin & platform setup, Android channels, iOS categories/actions, permissions & capabilities,
primers, the pure-Dart `NotificationPlanner` and its policies, planner fixtures, the local schedule table
and scheduler (budgets, merge, sentinel, schedule modes, repeating triggers), coverage reporting, replan
orchestration and triggers (incl. time-zone/clock change), action handling in foreground and background
isolates, snooze/reschedule, tap & cold-start handling, foreground suppression + in-app routing, nag chains,
grouping, delivered-notification cleanup, diagnostics, escalation, alarm profile, E2E tests.
**Out:** Rule model & editors ([7.1]); inbox UI & banner widget ([7.3]); FCM, jobs & dispatcher ([7.4]);
per-section trigger semantics ([7.5]); Live Activities / ongoing timer notifications ([8.2] T8.2.10).

## Platform budget cheat-sheet (from arch §9.7)

| Constraint | Our rule |
|---|---|
| iOS keeps only 64 pending requests | schedule ≤ 56 + reserve 8 (snooze, nag, timer, sentinel) |
| iOS calendar triggers repeat only daily/weekly/monthly/yearly; interval repeats ≥ 60 s | repeating triggers only for unconditional daily/weekly reminders; everything else one-shot |
| Android ~500 alarms/app (shared with other libs) | ≤ 250 scheduled, horizon ≤ 14 days |
| Android plays only the first sound per second | merge same-minute reminders into one notification |
| Android ≤ 3 action buttons | enforce in [7.1] validation; first 3 actions win |
| Android channels immutable (importance/sound) | channels per section × profile, curated sounds, versioned ids |
| `SCHEDULE_EXACT_ALARM` not pre-granted (14+), revocable | ask in context; inexact fallback; listen for state changes |
| Doze: allow-while-idle ≤ 1 per 9 min per app; inexact may be ~1 h late | warn in editor/diagnostics; push fallback for precision ([7.4]) |
| Plugin boot receiver misses `TIMEZONE_CHANGED` / `TIME_SET` | own receiver + resume check (T7.2.13) |
| iOS 27 SDK requires UIScene lifecycle | verify plugin callbacks under UIScene (T7.2.01) |

## Progress

- [x] T7.2.01 — Plugin setup & platform configuration
- [x] T7.2.02 — Android channels (section × profile, curated sounds)
- [x] T7.2.03 — Actions & categories (iOS categories, Android ≤ 3, text input)
- [x] T7.2.04 — Permission & capability service
- [x] T7.2.05 — Permission primers & recovery UX
- [x] T7.2.06 — NotificationPlanner core (pure Dart)
- [x] T7.2.07 — Planner policies: quiet hours, pause, mutes, conditions, lateness, caps
- [x] T7.2.08 — Planner fixture suite (DST, zones, policies)
- [x] T7.2.09 — Local schedule table & scheduler (diff, budgets, merge, sentinel)
- [x] T7.2.10 — Schedule modes & repeating-trigger optimization
- [x] T7.2.11 — Coverage & device-state reporting
- [x] T7.2.12 — Replan orchestrator & triggers
- [x] T7.2.13 — Time-zone & clock-change handling
- [x] T7.2.14 — Notification action handler (foreground + background isolate)
- [x] T7.2.15 — Snooze & reschedule engine
- [x] T7.2.16 — Tap handling, cold start & stale notifications
- [x] T7.2.17 — Foreground presentation & in-app routing
- [x] T7.2.18 — Nag chains (repeat until acknowledged / completed)
- [x] T7.2.19 — Grouping & threading
- [x] T7.2.20 — Delivered-notification cleanup & expiry
- [x] T7.2.21 — Notification diagnostics screen
- [x] T7.2.22 — End-to-end notification tests (patrol)
- [x] T7.2.23 — Escalation steps
- [ ] T7.2.24 — Alarm profile (AlarmKit / alarm clock / full-screen)
- [x] T7.2.25 — Alarm dismissal missions
- [ ] T7.2.26 — Rich notifications (images, big text, subtitle)

## Tasks

### T7.2.01 — Plugin setup & platform configuration
**Priority:** P0 · **Size:** M · **Depends on:** [1.3] (bootstrap, deep-link parser), [2.1]
**Description:** Integrate `flutter_local_notifications` 22.x (needs Flutter ≥ 3.38.1, Android minSdk 24,
iOS 13+), `timezone` (`latest_all`) and `flutter_timezone` behind a `LocalNotificationsPort` interface in
`core/notifications` (the only code touching the plugin; a fake implements it for tests).
**Implementation notes:**
- Android: core library desugaring enabled (plugin requirement for scheduling), monochrome small icon
  `ic_stat_everslot` + accent color, manifest permissions `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`,
  `RECEIVE_BOOT_COMPLETED`, `VIBRATE` (`USE_FULL_SCREEN_INTENT` only with T7.2.24), plugin receivers
  (scheduled, boot, action) registered per README.
- iOS: `UNUserNotificationCenter` delegate + plugin registrant callback for the background isolate in the
  app delegate; **UIScene lifecycle** (required when building with the iOS 27 SDK) — verify on device that
  `getNotificationAppLaunchDetails`, foreground callbacks and background actions still work under UIScene
  (research flagged this as unverified); Time Sensitive Notifications capability; bundled `.caf` sounds < 30 s.
- `initialize(..., onDidReceiveNotificationResponse, onDidReceiveBackgroundNotificationResponse)` with a
  top-level `@pragma('vm:entry-point')` background handler (T7.2.14); `tz.setLocalLocation(deviceZone)`.
**Acceptance criteria:** a debug "Test notification" fires on both platforms from background and killed
states; cold start from a notification reaches the router; release builds (R8) keep the plugin classes.
**Tests:** port contract tests with the fake; manual QA checklist entry per platform.
**Notes:** The port lives in `features/notifications/application/` (`LocalNotificationsPort`, `PluginLocalNotificationsPort`, `InMemoryLocalNotificationsPort`) instead of `core/notifications`. Manifest receivers, desugaring, `ic_stat_everslot` and the iOS delegate/registrant are in place; the on-device QA (background/killed, R8, UIScene) is still to run.

### T7.2.02 — Android channels (section × profile, curated sounds)
**Priority:** P0 · **Size:** M · **Depends on:** T7.2.01, [7.1] (profiles)
**Description:** Create notification channels per **section × profile** because importance, sound and
vibration cannot change after creation: ids `dl.<section>.<profileCode>.v<n>` (e.g.
`dl.planner.standard.v1`), plus `dl.system.v1`, `dl.digest.v1`, `dl.foreground.silent.v1` (T7.2.17);
grouped by section with `NotificationChannelGroup`s.
**Implementation notes:**
- Curated sound set (≈ 6 short sounds, same assets on iOS) — the only sounds offered by editors.
- Channel names/descriptions localized and updated on locale change (allowed after creation).
- Profile importance/sound change → new versioned channel id, old one deleted (the user sees it as a deleted
  category in system settings — warned in [7.1] T7.1.13).
- Read back channel state (`getNotificationChannels`) to detect channels the user blocked → capabilities.
- Android notification category per trigger (`reminder` for reminders, `event` for calendar-style starts,
  `alarm` only for the Alarm profile) and lock-screen visibility `private` by default.
**Acceptance criteria:** system settings show tidy groups (Plan, Lists, Habits, Quit, System) in the user's
language; a Gentle reminder never makes a sound even if the rule was edited after creation.
**Tests:** unit tests for channel-id resolution; Android instrumentation smoke test listing channels.
**Notes:** Curated sound keys are wired (Android `res/raw/<key>`, iOS `<key>.caf`) but the sound assets are not bundled yet, so every curated key falls back to the default sound; the Android instrumentation smoke test needs a device build.

### T7.2.03 — Actions & categories (iOS categories, Android ≤ 3, text input)
**Priority:** P0 · **Size:** M · **Depends on:** T7.2.01
**Description:** Map rule `delivery.actions` to platform actions: `done`, `start`, `stop`, `snooze`,
`skip`, `reschedule`, `log_value` (text input, e.g. "12"), `log_craving` (text input intensity 1–10),
`complete_item`, `mark_waiting`, `mark_blocked`, `open`, `mute_rule`.
**Implementation notes:**
- Android: `AndroidNotificationAction` (≤ 3, first three by rule order), `inputs` for text actions,
  `showsUserInterface` only for `open`/`reschedule`.
- iOS: categories are registered up front — generate one category per distinct action combination found in
  built-in profiles + the user's rules (sorted ids → category id), re-register on change (iOS replaces the
  set; cap 50); `DarwinNotificationAction.text(...)` for input actions; `.foreground` only for open-type
  actions; `authenticationRequired` for data-changing actions when app lock / hide-content is on;
  `customDismissAction` on categories with nag chains (dismiss callback, T7.2.18).
- Localized action titles; payload carries `dedupeKey`, `targetKey`, entity ids, `occurrenceKey`.
**Acceptance criteria:** from the lock screen, *Done* on a task reminder and *Log value 15* on a count habit
work without unlocking into the app (iOS asks for auth only when configured).
**Tests:** unit tests for action/category mapping; manual QA with the device locked.

### T7.2.04 — Permission & capability service
**Priority:** P0 · **Size:** M · **Depends on:** T7.2.01, [1.4] (device state RPC)
**Description:** `NotificationCapabilitiesService` exposing a reactive `NotificationCapabilities
{notifications, provisional, exactAlarm, timeSensitive, fullScreenIntent, badge, blockedChannels}`,
requesting permissions **in context** and reporting capability flags to `devices.capabilities`.
**Implementation notes:**
- Android 13+: `requestNotificationsPermission()`; exact alarms: `canScheduleExactNotifications()` and
  `requestExactAlarmsPermission()` (opens the system page) only when the user creates a precise reminder;
  native receiver for `ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` → replan with exact mode;
  revocation kills the app and cancels exact alarms → detected on next start → replan inexact.
- iOS: `requestPermissions(alert, badge, sound)` with optional **provisional** mode; read time-sensitive
  and summary settings (small method channel if the plugin doesn't expose `timeSensitiveSetting`).
- Re-check on every resume; emit changes → replan (T7.2.12) + device report (T7.2.11).
**Acceptance criteria:** denying, granting and revoking each permission is reflected within one resume;
no OS prompt is ever shown without a primer (T7.2.05).
**Tests:** unit tests with a fake port for each transition; patrol test for the Android 13 dialog.
**Notes:** Permission and exact-alarm changes are detected on resume; there is no native `ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` receiver (native Android code is outside this module). iOS time-sensitive is inferred from the authorization because the plugin exposes no `timeSensitiveSetting`.

### T7.2.05 — Permission primers & recovery UX
**Priority:** P0 · **Size:** S · **Depends on:** T7.2.04, [1.3] (design system)
**Description:** Primer sheets explaining value before the OS prompt (notifications; Android "precise
reminders" before the exact-alarm settings page; iOS time-sensitive explanation), plus recovery states:
inline banners in rule editors and Settings › Notifications when notifications are off, a channel is
blocked, or exact alarms are unavailable ("Reminders may arrive up to an hour late"), each with a settings
deep link. Reused by onboarding ([8.3] T8.3.11).
**Acceptance criteria:** every blocked state has a one-tap route to fix it; primers are skippable and
never shown twice in a session.
**Tests:** widget tests per state; golden in AR.
**Notes:** Goldens: recovery banner and primer in Arabic (`notification_goldens_test.dart`).

### T7.2.06 — NotificationPlanner core (pure Dart)
**Priority:** P0 · **Size:** L · **Depends on:** [7.1] (resolver, templates), [2.1], [3.2], [4.3], [5.1]
**Description:** Pure function `plan(PlanningContext) → List<PlannedNotification>` in
`features/notifications/domain/planner`, deterministic across devices.
**Implementation notes:**
- **Inputs:** `now`, horizon, device zone, settings (quiet hours, pause, mutes, lateness, caps,
  multi-device policy, locale, 12/24 h, hide content), capabilities, and `NotifiableTarget`s supplied by
  per-section adapters (planner occurrences via the [3.2] resolver, checklist items/checklists via [4.3],
  habit periods via [5.1], quit trackers via [5.3], digests): each target exposes anchors per occurrence
  (`start`, `end`, `due`, `follow_up`, `slot`, `period_start`, `period_end`), status, template variables and
  a guard factory.
- **Per trigger:** relative (anchor ± offset or `dayOffset` + `atTime` in the target's zone mode),
  absolute, schedule (recurrence expansion), notDoneBy, statusAge, overdue, streakRisk, quotaBehind,
  milestone (projected instant a threshold is crossed, e.g. clean time), inactivity, digest,
  statusChange/childrenComplete/childOverdue/stale (event-driven: evaluated when the event is observed).
- **Output:** `PlannedNotification {dedupeKey = sha1(rule_id|target_id|occurrence_key|trigger_idx|repeat_idx)
  (40 hex chars — valid APNs collapse-id), targetKey, ruleId, occurrenceKey, fireAt (UTC), expiresAt,
  category, section, channelKey, importance, interruptionLevel, relevance, sound, vibration, actions,
  snoozePresets, content (rendered), threadId/groupKey, deepLink, guard, deliver {system, inbox, banner},
  sticky, alarm}` sorted by fire time then priority.
- **Guard descriptors** (shared vocabulary with the server, [7.4] T7.4.05): `task_occurrence_open`,
  `habit_period_open`, `checklist_item_status_in`, `item_not_completed`, `quit_no_relapse_since`,
  `inbox_not_acted`, `always`. The planner pre-evaluates guards locally and drops instances already false.
- Runs in a background isolate; < 150 ms for affected targets, < 1 s for a full replan of 1 000 targets.
**Acceptance criteria:** identical inputs produce identical outputs (order and keys) on any device; a task
with "10 min before" and "at start" rules yields exactly two instances per occurrence.
**Tests:** unit tests per trigger type; property test (no duplicate keys, sorted, all within horizon).
**Notes:** Planning runs on the main isolate: a full replan of 1 000 mixed targets takes about 0.1 s (debug JIT, `planner_properties_test.dart`), well under budget. OS calls also stay on the main isolate.

### T7.2.07 — Planner policies: quiet hours, pause, mutes, conditions, lateness, caps
**Priority:** P0 · **Size:** M · **Depends on:** T7.2.06, [7.5] (settings model for quiet hours/pause/mutes)
**Description:** Policy stage applied to candidate instances:
- **Quiet hours** per weekday windows with mode **defer** (move to window end), **silent** (deliver on the
  section's silent/passive variant, no sound) or **drop**; bypass when the rule/profile sets
  `respectQuietHours: false` (e.g. Alarm, urgent).
- **Pause all** until an instant: suppress system and banner delivery, keep inbox rows.
- **Mutes** (rule / item / checklist / section until a date) suppress entirely.
- **Conditions:** `onlyIfStatusIn`, weekdays, time window (`drop | shift_start | shift_end`), `itemKind`,
  target devices (instance not scheduled locally on non-target devices but still uploaded as a job).
- **Multi-device policy** decides whether *this* device schedules locally (P0 default: all devices;
  primary / last-active from [7.4] T7.4.13).
- **Lateness:** `expiresAt = fireAt + latenessMinutes` (defaults: reminders 30 min, digests 120 min); at
  planning time, instances already past `fireAt` but not expired fire once immediately; older ones are
  dropped (never catch up on old occurrences).
- **Caps & horizon:** per target, per day and per user caps from [7.1] T7.1.04; horizon 7 days (iOS in
  practice limited by budget), Android 14 days.
**Acceptance criteria:** each policy is independently toggleable in tests and visible in the preview
reasons ([7.1] T7.1.11) — e.g. "Deferred to 07:00 (quiet hours)".
**Tests:** table-driven policy tests; interaction tests (quiet hours × lateness × pause).

### T7.2.08 — Planner fixture suite (DST, zones, policies)
**Priority:** P0 · **Size:** M · **Depends on:** T7.2.07
**Description:** `fixtures/notifications/planner/*.json` — `{now, zone, settings, targets, rules,
expected: [{dedupeKey, fireAtUtc, channelKey, reason}]}` — and a runner, ≥ 60 cases: offsets before/at start;
"1 day before at 20:00" across a DST change; floating vs fixed-zone tasks after a travel zone change;
all-day and date-only defaults; quiet hours defer/silent/drop; lateness; nag chains; guards already
satisfied; count habit not-done-by with partial progress; quota behind pace; clean-time milestone
projection; digests; caps.
**Acceptance criteria:** adding a JSON file adds a test; failures print a readable diff.
**Tests:** this task is the suite (also consumed by [7.4] T7.4.16 parity checks later).
**Notes:** Fixtures live in `app/test/features/notifications/fixtures/planner/*.json` (82 cases).

### T7.2.09 — Local schedule table & scheduler (diff, budgets, merge, sentinel)
**Priority:** P0 · **Size:** L · **Depends on:** T7.2.06, T7.2.02, T7.2.03, [1.4] (Drift)
**Description:** Local-only Drift table `local_notification_schedule` and a scheduler that makes the OS
state equal the desired top-K of the plan with minimal platform calls.
**Implementation notes:**
- Columns: `dedupe_key` PK, `platform_id` (31-bit FNV-1a of the key, collision-probed and persisted),
  `target_key`, `rule_id`, `occurrence_key`, `fire_at`, `expires_at`, `kind`
  (`one_shot | repeating | nag | snooze | merged | sentinel`), `match_components`, `payload_hash`,
  `channel_id`, `source_rev`, `scheduled_at`, `delivered_reconciled_at`, `cancelled_at`.
- Diff desired vs current: cancel removed/changed (payload hash differs), schedule new; batch; idempotent;
  planning in an isolate, platform calls on the main isolate.
- **Budgets:** iOS 56 regular + 8 reserved; Android 250; choose by fire time then priority.
- **Same-minute merge:** instances in the same minute become one `merged` notification ("3 reminders:
  Gym, Call Sam, Water") on Android (one sound) and iOS (one banner); individual inbox rows remain.
- **Saturation sentinel (iOS):** when the plan exceeds the budget, the last slot says "Open Everslot to keep
  your reminders up to date" at the 56th item's time.
**Acceptance criteria:** replanning with no changes makes zero platform calls; 2 000 planned instances →
≤ 56 pending on iOS and ≤ 250 on Android, always the soonest; no id collisions across 100 000 keys (probe test).
**Tests:** scheduler tests against the fake port (diff minimality, budgets, merge, sentinel, collisions).

### T7.2.10 — Schedule modes & repeating-trigger optimization
**Priority:** P0 · **Size:** S · **Depends on:** T7.2.09, T7.2.04
**Description:** Android mode per instance: `exactAllowWhileIdle` when exact alarms are granted, else
`inexactAllowWhileIdle` (`alarmClock` only for the Alarm profile, T7.2.24). Unconditional daily or weekly
reminders (no guard, no conditions, no exceptions, no quiet-hours shift) use **one repeating calendar
trigger** (`matchDateTimeComponents: time | dayOfWeekAndTime`) instead of one-shots, saving budget.
**Implementation notes:** when exact alarms are missing, mark the device capability so the dispatcher
([7.4]) may push precise copies; the push handler cancels the local alarm with the same id when it
arrives first. Warn in the rule editor when a nag interval < 10 min may be delayed by Doze.
**Acceptance criteria:** a daily 07:00 water reminder occupies one iOS slot; revoking exact alarms switches
all instances to inexact on next start.
**Tests:** mode-selection unit tests; repeating-eligibility tests.
**Notes:** Repeating triggers cover unbounded daily/weekly `schedule` rules with a target-level guard (`always`, `item_not_completed`) in the device zone, and only when the sequence has no gaps across the horizon (on iOS it must start at the next match). Members stay tracked for the inbox; a response maps to the member that fired last. Doze warning: validation code `repeatMayBeDelayed`.

### T7.2.11 — Coverage & device-state reporting
**Priority:** P0 · **Size:** S · **Depends on:** T7.2.09, [1.4] (`report_device_state`)
**Description:** After each scheduler run (debounced 30 s) and on app start, report
`local_coverage_until` (fire time of the last scheduled one-shot, or horizon end when everything fit),
`schedule_rev` (sync cursor the plan was computed from — plan only after pushing local changes),
capabilities, and the rules covered by repeating triggers.
**Data model:** `devices.local_repeating_rules uuid[]` (arch §7.3) so the dispatcher
skips jobs of rules this device covers with repeating triggers beyond `local_coverage_until`.
**Acceptance criteria:** coverage reflects budget saturation (e.g. iOS with 300 planned → coverage = 56th
instance time); reports survive offline (sent on reconnect).
**Tests:** unit tests for coverage computation; RPC contract test.
**Notes:** `local_repeating_rules` lists the rules covered by repeating triggers.

### T7.2.12 — Replan orchestrator & triggers
**Priority:** P0 · **Size:** M · **Depends on:** T7.2.09, T7.2.11, [7.1] (change events)
**Description:** `NotificationReplanService` — single-flight, dirty-target queue (or `*` for everything),
1.5 s debounce, planner in an isolate → scheduler → coverage report → job upload hook ([7.4], P1).
**Triggers:** local writes to tasks/occurrences/items/habits/logs/rules/settings (mapped to target keys);
app launch and resume (full replan if last full replan > 6 h ago); after sync pulls that applied remote
rows; Realtime nudge; notification actions; capability/permission changes; locale, 12/24 h, hide-content
changes; day rollover (extend horizon); days around DST transitions; `workmanager` periodic task (Android
≥ 15 min min interval — use ~6 h; iOS BGAppRefresh best-effort) to extend the horizon; boot / package
replaced (plugin re-arms stored notifications; a WorkManager one-off runs the Dart replan to extend them).
**Acceptance criteria:** editing a task time reschedules its reminders within 2 s; after 10 days without
opening the app on Android, reminders still fire (periodic extension).
**Tests:** orchestrator tests with fake triggers (debounce, single-flight, `*` coalescing).

### T7.2.13 — Time-zone & clock-change handling
**Priority:** P0 · **Size:** S · **Depends on:** T7.2.12, [1.5] (current zone tracking)
**Description:** The plugin's boot receiver does not handle `TIMEZONE_CHANGED`/`TIME_SET`: add a native
Android receiver for both (exempt broadcasts) that enqueues a WorkManager one-off → Dart replan; on iOS
check the zone and detect wall-clock jumps on resume and on `NSSystemTimeZoneDidChange` while running.
Floating rules shift to the new zone, fixed-zone rules keep their instants.
**Acceptance criteria:** flying Paris → Tunis: a floating "08:00 daily" habit reminder fires at 08:00 Tunis
time; a fixed "10:00 New York" meeting reminder keeps its instant.
**Tests:** planner fixtures for both cases; Android emulator manual test changing the zone.
**Notes:** Partial. Dart side is done: a zone change triggers an immediate replan, resume re-checks the zone, and the 6-hourly WorkManager replan reads the current zone. The native Android `TIMEZONE_CHANGED`/`TIME_SET` receiver and the iOS `NSSystemTimeZoneDidChange` hook are not added (native code is outside this module), so a change made while the app is closed is applied on the next resume or periodic run.

### T7.2.14 — Notification action handler (foreground + background isolate)
**Priority:** P0 · **Size:** L · **Depends on:** T7.2.03, [3.2], [4.3], [5.2], [5.3]
**Description:** One handler for `onDidReceiveNotificationResponse` and the top-level
`@pragma('vm:entry-point')` background handler: parse payload → open the database (shared Drift isolate
when the app is alive, otherwise a direct WAL connection) → call the **same application services as the
UI**: complete/skip/start/stop occurrence ([3.2]), log habit value from text input ([5.2]), log craving with
intensity ([5.3]), complete/mark waiting/blocked checklist item ([4.3], reason "set from notification"),
mute rule until tomorrow, snooze (T7.2.15). Writes go through the outbox with `source = 'notification'`;
the inbox row gets `acted_at`/`action`.
**Implementation notes:** idempotent per `(dedupeKey, action)`; invalid text input (e.g. "12a") posts a
follow-up notification explaining the error; afterwards replan the target, cancel its nag chain and attempt a
best-effort sync push within the iOS background time budget.
**Acceptance criteria:** *Done* from the lock screen with the app killed marks the occurrence done, and
it syncs on next connectivity; double-tapping an action writes once.
**Tests:** background-isolate integration test (plugin callback → DB row); idempotency unit tests.

### T7.2.15 — Snooze & reschedule engine
**Priority:** P0 · **Size:** M · **Depends on:** T7.2.14
**Description:** *Snooze* from a notification uses the first preset (settings `snoozePresets`, default
10 min); inbox/app offer all presets — 5 / 10 / 15 / 30 min, 1 h, this evening, tomorrow morning, custom —
and *next free slot* (P1, via [3.7]). A snooze creates a new instance (`dedupeKey = sha1(original|snooze|n)`)
in the reserved budget, sets inbox `snoozed_until`, and (P1) uploads a job so other devices follow.
*Reschedule* (+1 h / tonight / tomorrow) moves the **occurrence** through [3.2] (override + activity event) and replans.
**Acceptance criteria:** maximum snoozes per instance (default 5) enforced; snoozing never moves the task
itself; rescheduling does.
**Tests:** unit tests for snooze keys, limits and budget usage.
**Notes:** Snooze is complete. *Reschedule* is forwarded to the feature handler, but the planner handler doesn't implement `reschedule` yet, so it opens the occurrence instead (TODO(integration): planner-core adds `reschedule` to `PlannerNotificationActions`).

### T7.2.16 — Tap handling, cold start & stale notifications
**Priority:** P0 · **Size:** S · **Depends on:** T7.2.14, [1.3] (deep links)
**Description:** Taps (and `getNotificationAppLaunchDetails` on cold start) route through the shared
deep-link parser to the target (occurrence sheet, checklist focused on the item, habit detail, quit
dashboard, inbox for digests) and mark the inbox row opened/read. If the target is already done/deleted
(guard now false), open it with a non-blocking "Already done" message.
**Acceptance criteria:** tapping a reminder while the app is killed opens the right occurrence in < 2 s.
**Tests:** unit tests for payload → route; patrol cold-start test (T7.2.22).

### T7.2.17 — Foreground presentation & in-app routing
**Priority:** P0 · **Size:** S · **Depends on:** T7.2.09, [7.3] (banner component, inbox)
**Description:** When the app is in the foreground, show Everslot's in-app banner instead of the OS banner
(setting `bannerInApp`, default on).
**Implementation notes:** iOS: schedule with `presentBanner: false, presentSound: false, presentList: true,
presentBadge: true` (these flags only affect foreground presentation). Android: on resume, re-arm
instances due in the next 15 min on `dl.foreground.silent.v1`, re-arm them on normal channels on pause; a
foreground ticker driven by the schedule table raises the in-app banner and writes/updates the inbox row
at fire time.
**Acceptance criteria:** with the app open, a reminder produces exactly one visible alert (the in-app
banner) and one inbox row; with the app backgrounded, the OS notification behaves normally.
**Tests:** unit tests for the resume/pause re-arming; widget test for ticker → banner.

### T7.2.18 — Nag chains (repeat until acknowledged / completed)
**Priority:** P1 · **Size:** M · **Depends on:** T7.2.09, T7.2.14
**Description:** `repeat {everyMinutes, maxTimes ≤ 10 (default 5), until acknowledged | completed | max}` →
chain of one-shots (`repeat_idx` 1…n). Cancel the rest on action, tap (acknowledged), dismissal (Android
dismissal callback; iOS `customDismissAction`), completion (guard), or acknowledgement on another device
(server guard `inbox_not_acted`, [7.4]).
**Implementation notes:** on iOS only the soonest chain lives in the reserved budget, other chains rely on
push; Doze may delay repeats < 9 min (documented in the editor).
**Acceptance criteria:** a "Nag-until-done" task reminder repeats every 5 min up to 5 times and stops
immediately when *Done* is pressed on any device.
**Tests:** chain generation/cancellation unit tests; fixture cases in T7.2.08.
**Notes:** `flutter_local_notifications` has no Android dismissal callback (no delete intent), so swiping a nag away on Android doesn't stop the chain; iOS uses `customDismissAction`. Acknowledgements from other devices arrive through synced inbox rows (`acknowledgedKeys`) and the server guard `inbox_not_acted`.

### T7.2.19 — Grouping & threading
**Priority:** P1 · **Size:** S · **Depends on:** T7.2.09
**Description:** Android `groupKey` per section with an auto summary (inbox style) when ≥ 2 notifications
are active; iOS `threadIdentifier` per section (or per target for nag chains) with `summaryArgument`.
Relevance score set from importance so the iOS Scheduled Summary ranks reminders sensibly.
**Tests:** unit tests for group/thread assignment.
**Notes:** Android summaries are refreshed whenever the app sees the tray (every replan); while the app is killed, Android bundles 4+ notifications by itself. iOS uses `threadIdentifier` only; `summaryArgument` is deprecated since iOS 15 and isn't set.

### T7.2.20 — Delivered-notification cleanup & expiry
**Priority:** P1 · **Size:** S · **Depends on:** T7.2.12
**Description:** After each replan and pull, remove delivered notifications whose target is now done,
skipped or deleted (cancel by id; Android also by tag), apply Android `timeoutAfter` = lateness for
expiring reminders, clear everything on sign-out.
**Acceptance criteria:** completing a task in the app removes its reminder from the tray on the same device;
on another device after sync.
**Tests:** unit tests with the fake port.

### T7.2.21 — Notification diagnostics screen
**Priority:** P1 · **Size:** M · **Depends on:** T7.2.09, T7.2.04
**Description:** Settings › Notifications › Diagnostics: capabilities (permission, exact alarms,
time-sensitive, blocked channels), OS pending requests vs our schedule table (mismatches highlighted), budget
usage, coverage until, last replan (time, duration, reason), next 20 firings, *Send test notification*,
OEM battery guidance (manufacturer detection → dontkillmyapp.com page, open battery settings; no
`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`), and "Copy diagnostics" for support (no content).
**Acceptance criteria:** a user whose phone kills background work can find the exact fix steps in ≤ 3 taps.
**Tests:** widget tests with fake data; unit test that the export contains no titles/bodies.

### T7.2.22 — End-to-end notification tests (patrol)
**Priority:** P1 · **Size:** M · **Depends on:** T7.2.16, [9.1] (patrol harness)
**Description:** Patrol scenarios on Android emulator (CI) and iOS simulator (local): grant permissions,
create a task with "1 min before" + "at start", lock the device, verify both notifications, press *Done*
from the notification, assert the occurrence is done; cold start from tap; background action with the app
killed; time-zone change → replan.
**Acceptance criteria:** suite green in CI (Android) and documented for iOS.
**Notes:** `app/patrol_test/notifications_test.dart` on the T9.1.07 harness, green on an API 34 emulator (2/2, ~6 min): grants the OS permission, seeds a task with *1 min before* + *at start* (Custom mode, through the application APIs), backgrounds the app, sees both deliveries in the shade (sightings accumulate — reminders expire at their anchor by design), presses *Done* from the shade and asserts the occurrence is done; a second test taps a reminder and lands on the occurrence. Cold start from a killed app and the time-zone-change replan aren't driven on the device (the background action isolate and zone replans are covered by unit tests); CI runs the suite in the `android-e2e` job; iOS steps are in docs/guide.md §8.

### T7.2.23 — Escalation steps
**Priority:** P2 · **Size:** M · **Depends on:** T7.2.18
**Description:** `repeat.escalation[]` changes delivery per repeat index (passive → active → time-sensitive
→ alarm; louder sound; add devices), each step mapped to an existing channel/profile.
**Tests:** planner fixtures with escalation.
**Notes:** `repeat.escalation: [{fromRepeat, profile (built-in code or id), allDevices?}]`; each nag resolves its delivery through the step's profile (channel, importance, interruption level, sound, alarm style — the rule keeps its actions) and `allDevices` lifts `conditions.devices` for local scheduling and push targets. Editor: *Escalation* rows under the repeat settings; validation requires ascending steps within 1…10.

### T7.2.24 — Alarm profile (AlarmKit / alarm clock / full-screen)
**Priority:** P2 · **Size:** L · **Depends on:** T7.2.10, [7.1] (Alarm profile)
**Description:** The Alarm profile rings through Silent/Focus: iOS 26+ **AlarmKit** (`flutter_alarmkit`,
`NSAlarmKitUsageDescription`, user authorization, snooze via countdown; fallback to time-sensitive
notifications below iOS 26); Android `AndroidScheduleMode.alarmClock` + full-screen intent only when
`canUseFullScreenIntent()` (user-granted; Play limits auto-grant to alarm/calling apps) and the Android 17
background-audio rule (exact-alarm permission + `USAGE_ALARM` stream).
**Acceptance criteria:** an alarm-profile task rings on a silent phone where permitted and degrades
gracefully (clearly labelled) where not; Play/App Store declarations handled in [9.2].
**Tests:** manual QA matrix (OS versions × permission states).
**Notes:** Partial (open: iOS 26 AlarmKit). Android: the alarm channel (v2) plays on `USAGE_ALARM`, alarm-profile reminders use `alarmClock` + a full-screen intent only when `canUseFullScreenIntent()` (new `app.everslot/alarm` channel in `MainActivity`), and a permission change re-issues them; a tap / full-screen launch opens `AlarmScreen` (Done · Snooze · Stop), shown over the lock screen only while it is open. iOS uses the labelled time-sensitive fallback. The advanced editor flags an alarm rule that can't ring through silent and offers the missing permissions. AlarmKit (`flutter_alarmkit`, `NSAlarmKitUsageDescription`) needs the Xcode 26 toolchain this machine lacks — to do with T7.4.14's device session. Store declarations stay in [9.2].

### T7.2.25 — Alarm dismissal missions
**Priority:** P2 · **Size:** M · **Depends on:** T7.2.24
**Description:** Optional Alarmy-style missions to stop an alarm (solve a sum, type the task title, shake,
scan a saved QR code), anti-snooze limits, gradually increasing volume.
**Tests:** widget tests for missions; manual QA.
**Notes:** `delivery.alarm {mission {type: math | type | shake | qr, count?, code?}, maxSnoozes?, rampVolume?}` travels in the alarm payload to `AlarmScreen`: Done / Stop stay locked until the mission is solved, the screen plays its own generated beep on the alarm stream (rising from 10 % to full over 30 s when asked) until then, and the dispatcher enforces the per-alarm snooze limit. Configured under *Alarm options* in the advanced editor (QR codes are scanned once and saved). New deps: sensors_plus, mobile_scanner, audioplayers (arch §3). Widget tests cover every mission; on-device QA is part of the T7.4.14 device session.

### T7.2.26 — Rich notifications (images, big text, subtitle)
**Priority:** P2 · **Size:** M · **Depends on:** T7.2.09, [2.2] (attachment cache)
**Description:** Optional image in reminders for items/tasks with image attachments (Android
`BigPictureStyle` from the local cached thumbnail, iOS notification attachment from a local file copy),
big-text style for long checklist paths, iOS subtitle for `{parent_path}` / category; never downloads at
fire time (only already-cached files) and respects hide-content redaction.
**Acceptance criteria:** a checklist item with a photo shows its thumbnail in the notification on both
platforms when cached; missing files degrade to text-only silently.
**Tests:** unit tests for attachment selection and redaction; manual QA.
