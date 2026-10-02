# Section 8.2 — Home Widgets, Shortcuts & Integrations

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.3, 3.2, 4.3, 5.2, 5.3, 7.2
> Architecture: §6.4 (deep links), §6.16 (background), §6.17

## Goal

Let the user see and act on Everslot without opening it (home/lock-screen widgets, app shortcuts, share
sheet) and connect it to the rest of the phone (deep links, device calendars, health data, timers on the
lock screen).

## Scope

**In:** deep-link entry points, `home_widget` bridge, iOS WidgetKit + Android Glance widgets (agenda,
habits, quit counter, checklist), app shortcuts, share-into-app, ICS import/export, device-calendar
overlay, Health integrations, Live Activities / ongoing timer notification, Siri/App Actions.
**Out:** Wearable companion apps and two-way calendar sync (→ [9.3]).

## Progress

- [x] T8.2.01 — External deep links & app links
- [x] T8.2.02 — Widget data bridge (`home_widget`)
- [x] T8.2.03 — Widget: Today agenda
- [x] T8.2.04 — Widget: Habits check-in (interactive)
- [x] T8.2.05 — Widget: Quit counter
- [x] T8.2.06 — App shortcuts (quick actions)
- [x] T8.2.07 — Share into Everslot
- [x] T8.2.08 — Widget: Checklist (interactive)
- [x] T8.2.09 — Lock-screen / StandBy accessory widgets
- [x] T8.2.10 — Running timer on lock screen (Live Activity / ongoing notification)
- [x] T8.2.11 — ICS export (share tasks as calendar events)
- [x] T8.2.12 — ICS import
- [ ] T8.2.13 — Device-calendar overlay (read-only)
- [ ] T8.2.14 — Health data auto-logging for habits
- [ ] T8.2.15 — Siri Shortcuts / App Intents & Android App Actions

## Tasks

### T8.2.01 — External deep links & app links
**Priority:** P1 · **Size:** M · **Depends on:** [1.3] (router), [7.2]
**Description:** Handle `everslot://…` links from outside the app (widgets, notifications, shortcuts,
other apps) and, once a domain exists, verified universal links / Android App Links.
**Implementation notes:**
- `app_links` stream → single `DeepLinkParser` (pure, shared with notification payloads) → `go_router`.
- Cold start vs warm start handled; unknown/invalid links show a friendly "not found" and never crash.
- Links pointing at deleted entities open the Trash entry when possible ([8.3]).
- Universal links: `apple-app-site-association` and `assetlinks.json` hosted with the privacy site ([9.2]).
**Acceptance criteria:** every canonical path in arch §6.4 opens the right screen from cold start, warm
start and background; malicious/oversized parameters are rejected.
**Tests:** parser unit tests (valid, invalid, fuzzed); integration test opening 3 links from cold start.
**Notes:** `features/integrations`: pure `ExternalLinkPolicy` on top of the shared `DeepLinkParser` (UUID ids, ISO dates, bounded params, internal screens `/dev` `/auth` `/onboarding` refused, `everslot://do/<command>` + `everslot://share` commands) → `ExternalLinksService` (`app_links`; cold/warm/background identical, duplicate launch-link report de-duplicated) → buffered UI events → `IntegrationsOverlay` (`go` for tab roots, `push` otherwise). Flutter's built-in deep linking is disabled (Info.plist `FlutterDeepLinkingEnabled`, manifest `flutter_deeplinking_enabled`) so each link is handled once; Supabase auth callbacks are ignored. The web domain is the placeholder `YOUR_SITE_DOMAIN` in three places: `EVERSLOT_LINK_DOMAIN` (Xcode project build setting → `Runner.entitlements` `applinks:`), `appLinksHost` (`android/app/build.gradle.kts`) and the `APP_LINKS_DOMAIN` dart-define. Universal links / App Links verification is unverified on device (needs the real domain, Team ID and signing fingerprints in `site/.well-known/*`; iOS build needs Xcode 26+).

### T8.2.02 — Widget data bridge (`home_widget`)
**Priority:** P1 · **Size:** M · **Depends on:** T8.2.01
**Description:** Infrastructure shared by all widgets: a compact JSON snapshot written to the App Group
(iOS) / shared preferences (Android) and a refresh trigger after relevant DB changes.
**Implementation notes:**
- `features/widgets_home`: `WidgetSnapshotBuilder` (pure) → `{generatedAt, today: {...}, habits: [...],
  quit: [...], pinnedChecklist: {...}}`, size-bounded (< 50 KB), localized strings pre-rendered.
- Debounced writer (2 s) listening to Drift table updates; also on day rollover and time-zone change.
- iOS: App Group `group.<bundle>.shared`; Android: `HomeWidgetProvider` receivers.
- Interactive actions from widgets go through `home_widget` background callbacks into a Dart isolate that
  opens Drift and performs the same application-service calls as the UI (writes + outbox).
**Acceptance criteria:** snapshot updates within 3 s of a change while the app runs; widgets show
"Open Everslot to refresh" when the snapshot is older than 24 h.
**Tests:** unit tests for snapshot builder (size cap, localization); manual checklist per platform.
**Notes:** `features/widgets_home`: `WidgetSnapshotBuilder` (from the Today overview, strings pre-rendered, `bounded()` ≤ 50 KB), debounced `WidgetSnapshotWriter` (2 s, skips unchanged content, rewrites after 6 h), `HomeWidgetBridge` (App Group per flavor). Background actions reuse `NotificationBackground.run` (Drift + SyncWriter); date symbols are initialised by hand there. Verified on the Android emulator: changes reach widgets within ~3 s. iOS: taps are queued in the App Group and drained on start / resume with the tap time (`currentTarget(at:)`) — no Flutter engine in the extension.

### T8.2.03 — Widget: Today agenda
**Priority:** P1 · **Size:** L · **Depends on:** T8.2.02
**Description:** Small / medium / large widgets listing the next tasks today (time, title, category
color), with a "now" marker; tap on a row opens the occurrence, tap elsewhere opens Today.
**Implementation notes:** iOS SwiftUI WidgetKit timeline entries pre-computed for the day (one entry per
task boundary) so the widget advances without the app; Android Jetpack Glance with the same data.
**Acceptance criteria:** correct in light/dark, RTL and large text; updates at task boundaries without
opening the app (iOS timeline, Android periodic update ≤ 30 min).
**Tests:** snapshot fixtures rendered in Xcode/Android previews; manual QA script entry.
**Notes:** Glance `TodayWidget` (now marker, colour bar, row → occurrence link, 30-min update) and WidgetKit `TodayWidget` (timeline entries at every task boundary). Verified on Android; the iOS extension compiles (Xcode 16.4) but the full iOS app needs Xcode 26 to build, so on-device iOS QA is pending.

### T8.2.04 — Widget: Habits check-in (interactive)
**Priority:** P1 · **Size:** L · **Depends on:** T8.2.02, [5.2]
**Description:** Grid/list of today's habits with tap-to-check (iOS 17+ App Intents, Android Glance
actions); count habits increment by one; shows progress rings.
**Acceptance criteria:** tapping updates the widget immediately (optimistic) and writes a correct
`habit_logs` row (source = `widget`) that syncs; works when the app has been killed.
**Tests:** integration test of the background callback writing the log; manual QA.
**Notes:** Android: Glance `ActionCallback` patches the snapshot optimistically, then `HomeWidgetBackgroundIntent` runs `widgetInteractivityCallback` → `habit_logs` row with `source = widget`; verified with the app force-stopped. iOS 17 `HabitTapIntent` (optimistic + queue). Counters add `incrementStep`.

### T8.2.05 — Widget: Quit counter
**Priority:** P1 · **Size:** M · **Depends on:** T8.2.02, [5.3]
**Description:** Clean-time counter for a chosen quit tracker + money saved + next milestone.
**Implementation notes:** iOS `Text(date, style: .timer/.relative)` for a live count without refreshes;
Android `Chronometer` in RemoteViews / Glance equivalent.
**Acceptance criteria:** counter is live without app refreshes; relapse logged in app resets the widget
within 3 s.
**Tests:** manual QA; unit test on snapshot fields.
**Notes:** Android: whole days as text + system `Chronometer` (via `AndroidRemoteViews`) for the running part — ticks without the app, verified on the emulator. iOS: `Text(date, style: .timer)` with a timeline entry per day boundary.

### T8.2.06 — App shortcuts (quick actions)
**Priority:** P1 · **Size:** S · **Depends on:** T8.2.01
**Description:** Long-press app icon shortcuts: *New task*, *Log habit*, *Log craving*, *Today*.
**Implementation notes:** `quick_actions`; localized titles; route through deep links.
**Tests:** unit test mapping shortcut type → deep link.
**Notes:** `AppShortcut` (new_task, log_habit, log_craving, today) → external links through `ExternalLinksService.handle`, localized titles that follow the app language. `everslot://do/new-task` opens the universal quick add (`QuickAddUiEvent`, registered by the app layer); `do/craving` logs a craving when exactly one quit tracker exists, else opens Habits / the quit editor. Verified registered on the Android emulator.

### T8.2.07 — Share into Everslot
**Priority:** P1 · **Size:** M · **Depends on:** T8.2.01, [2.2], [4.1]
**Description:** Accept text, URLs, images and files from the system share sheet → choose *New task*,
*Add to checklist (pick list / parent item)* or *Attach to existing item*.
**Implementation notes:** `receive_sharing_intent` (iOS share extension + Android intent filters);
multi-line text can become multiple items (each line an item; indentation → nesting, reuse [4.5] parser).
**Acceptance criteria:** sharing 5 photos creates one item with 5 attachments queued for upload offline.
**Tests:** unit tests for text-to-items conversion; manual QA on both platforms.
**Notes:** `receive_sharing_intent` 1.9 (needs compileSdk 37: bumped, targetSdk stays 36). Android: SEND / SEND_MULTIPLE filters. iOS: own `EverslotShare` extension writing the plugin's App Group contract (no plugin linkage in the extension); builds with Xcode 16.4, device QA pending (Xcode 26 for the app). Sheet: Task (first line = title, rest = notes), List (existing list + parent item, or a *new list* from the text — default for multi-line text), Attach (search tasks/items). Text → items via the [4.5] import parser. Unreadable files are rejected, not fatal. Verified on the Android emulator (text → new list, image → task).

### T8.2.08 — Widget: Checklist (interactive)
**Priority:** P2 · **Size:** M · **Depends on:** T8.2.02, [4.3]
**Description:** Shows the open items (top level or a chosen branch) of a pinned checklist with tap-to-complete.
**Tests:** background callback integration test; manual QA.
**Notes:** First pinned checklist, open items two levels deep, tap-to-complete (Android background callback / iOS 17 intent). Settings shows how to pin it.

### T8.2.09 — Lock-screen / StandBy accessory widgets
**Priority:** P2 · **Size:** M · **Depends on:** T8.2.03, T8.2.05
**Description:** iOS accessory widgets (circular: habit ring, rectangular: next task, inline: clean time)
and StandBy layouts.
**Tests:** manual QA.
**Notes:** WidgetKit accessory families: circular habit ring (`Gauge`), rectangular next task, inline clean time; `containerBackground` makes the system widgets StandBy-ready. Compiles; on-device QA pending (Xcode 26).

### T8.2.10 — Running timer on lock screen (Live Activity / ongoing notification)
**Priority:** P2 · **Size:** L · **Depends on:** [3.2] (time tracking)
**Description:** When a task timer runs: iOS Live Activity / Dynamic Island with elapsed & planned end;
Android ongoing notification with chronometer and Stop/Done actions (foreground service only if required).
**Acceptance criteria:** stopping from the lock screen writes the time entry; survives app kill.
**Tests:** manual QA; unit tests for state mapping.
**Notes:** `TimerSurface` (pure; latest timer leads, others counted, planned end from the resolved occurrence) mirrored by `TimerSurfaceService` from `runningTimersProvider`. Android: ongoing silent notification (quiet channel) with a system chronometer (`OsNotificationRequest.chronometerFrom`) and *Stop* / *Done* handled by the existing notification action dispatcher — in the background isolate when the app was killed — so the time entry closes from the lock screen. iOS: `live_activities` Live Activity + Dynamic Island in the widget extension (`TimerActivity.swift`, timer text runs without updates); *Stop* opens Everslot via `everslot://do/timer-stop` (ending an activity from the extension is not reliable), which stops the timer and opens the occurrence. The plugin's Android FCM service is removed in the manifest (it would take FCM events). Device QA: Android build verified; iOS needs Xcode 26.

### T8.2.11 — ICS export (share tasks as calendar events)
**Priority:** P2 · **Size:** M · **Depends on:** [2.1] (RRULE export)
**Description:** Export a task, a date range or a category as `.ics` (VEVENT with RRULE/EXDATE when
representable; otherwise expanded instances) and share it.
**Tests:** golden `.ics` fixtures; round-trip with T8.2.12.
**Notes:** Pure `IcsWriter` (CRLF, 75-octet UTF-8-safe folding, escaping, `TZID` by IANA name — no VTIMEZONE blocks, which Google / Apple / Outlook accept) + `IcsMapping.eventsForTask`: one VEVENT with `RRuleCodec` DTSTART/RRULE/EXDATE (cancelled occurrences → EXDATE, moved/retitled ones → RECURRENCE-ID events) when representable, else expanded instances over the range (180 days by default). Entry points: task menu *Add to calendar (.ics)*, Settings › Widgets & integrations › Calendar files (next 7/30/90/365 days, optional category). Golden `export_golden.ics`; round trip with T8.2.12 tested.

### T8.2.12 — ICS import
**Priority:** P2 · **Size:** M · **Depends on:** [2.1] (RRULE import), [3.1]
**Description:** Import `.ics` files (VEVENT → tasks, RRULE/EXDATE/RECURRENCE-ID → rules and overrides,
VALARM → notification rules) with a preview and duplicate detection (UID stored in task metadata).
**Tests:** fixtures from Google Calendar, Apple Calendar and Outlook exports.
**Notes:** `IcsParser` reads Google / Apple / Outlook exports (fixtures): folded lines, quoted / Windows `TZID`s (mapped to IANA), `VALUE=DATE`, UTC, DURATION, EXDATE/RDATE, RECURRENCE-ID overrides (moved / cancelled), VALARM → *N min before start* reminders. New `tasks.external_uid` (server migration + pgTAP 159, Drift v6) stores the UID: duplicates start unchecked in the preview sheet; re-exports keep the original UID. Opened from Settings (file picker) or by sharing an `.ics` file into the app.

### T8.2.13 — Device-calendar overlay (read-only)
**Priority:** P2 · **Size:** L · **Depends on:** [3.3], [3.4]
**Description:** Show events from selected device calendars (Google/iCloud/Exchange via the OS) as
read-only tiles in planner views, toggled per view (`overlays.deviceCalendars`). Not stored server-side.
**Implementation notes:** `device_calendar` permission flow; cache per visible range; distinct styling;
free-slot finder ([3.7]) treats them as busy.
**Tests:** unit tests for mapping; manual QA with real calendars.

### T8.2.14 — Health data auto-logging for habits
**Priority:** P2 · **Size:** L · **Depends on:** [5.1], [5.2]
**Description:** Link a habit to Apple HealthKit / Android Health Connect metrics (steps, workouts,
mindful minutes, sleep, water) → automatic `progress` logs (source = `auto`) with de-duplication.
**Acceptance criteria:** "10 000 steps" habit completes automatically; user can override; permissions
explained with a primer screen.
**Tests:** unit tests for aggregation/dedupe; manual QA on devices.

### T8.2.15 — Siri Shortcuts / App Intents & Android App Actions
**Priority:** P2 · **Size:** M · **Depends on:** T8.2.01
**Description:** Voice/automation entry points: "Log push-ups 15", "What's next?", "Start focus task".
**Tests:** manual QA; unit tests for intent parameter mapping.
