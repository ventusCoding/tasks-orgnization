# Section 7.3 — In-App Inbox & Banners

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.3, 1.4, 7.1, 7.2
> Architecture: §6.13 (In-app, pipeline steps 4–5), §7.3 (`notifications` table), §9.2 (UUIDv5 ids)

## Goal

Every reminder the user configures is also visible **inside the app**: a notification center (inbox) that
lists what fired, what was snoozed and what still needs action — synced across devices — plus an in-app
banner when a reminder fires while Everslot is open. The inbox is the record of truth for "what did
Everslot tell me?", independent of whether the alert came from a local notification or an FCM push.

## Scope

**In:** inbox repository and queries, inbox row creation paths and convergence rules (device + server),
inbox screen, row actions and deep links, the in-app banner component and queue, badges, system notices,
snoozed section, per-item notification history, retention, search/bulk actions (P2).
**Out:** The `notifications` migration and Drift table ([7.1] T7.1.01–02); OS delivery and the foreground
ticker ([7.2]); server inbox writes by the dispatcher ([7.4] T7.4.07); notification statistics ([7.5] T7.5.17).

## Convergence rules (normative)

- Inbox id = `uuidv5(dedupe_key)` on every writer (device reconciliation, foreground ticker, dispatcher),
  so the same firing never appears twice.
- User state (`read_at`, `opened_at`, `acted_at`, `action`, `snoozed_until`, `dismissed_at`) is written
  only by devices. The server dispatcher inserts rows or, on conflict, patches **delivery fields only**
  (`delivered_at` = earliest, `delivered_via` = union, `late`) with server HLC stamps; with per-field
  last-writer-wins (arch §6.6) a device's "read" and the server's delivery info both survive.
- Rows created automatically (reconciliation, dispatcher) are stamped with the HLC of the **scheduled fire
  instant** (arch §6.6 *automatic writes*), so any later user edit always wins.

## Progress

- [ ] T7.3.01 — Inbox repository & queries
- [ ] T7.3.02 — Inbox row creation & device reconciliation
- [ ] T7.3.03 — Inbox screen
- [ ] T7.3.04 — Inbox row actions & deep links
- [ ] T7.3.05 — In-app banner component & queue
- [ ] T7.3.06 — Bell badge & app-icon badge policy
- [ ] T7.3.07 — System notices in the inbox
- [ ] T7.3.08 — Snoozed section & "remind me again"
- [ ] T7.3.09 — Per-item notification history
- [ ] T7.3.10 — Retention & cleanup
- [ ] T7.3.11 — Inbox search, rule filters & bulk actions

## Tasks

### T7.3.01 — Inbox repository & queries
**Priority:** P0 · **Size:** M · **Depends on:** [7.1] (inbox table & repository skeleton), [1.4]
**Description:** `InboxRepository` over the synced `notifications` table: `watchInbox({filter, limit})`,
`watchUnreadCount()`, `markRead(ids)`, `markUnread(id)`, `markAllRead({section?})`, `markOpened(id)`,
`markActed(id, action)`, `dismiss(id)` (sets `dismissed_at`, undoable), `snooze(id, until)`,
`watchForSource(sourceType, sourceId)`, `upsertDelivered(...)` implementing the convergence rules above.
**Implementation notes:** all writes through the sync writer; unread = `read_at is null and dismissed_at is
null and (snoozed_until is null or snoozed_until <= now)`; pagination by `fire_at desc`; filters: section,
category (`reminder | nag | digest | milestone | streak | system`), unread only, date range.
**Acceptance criteria:** marking read on device A clears the unread badge on device B after sync; dismiss
+ undo restores the row exactly.
**Tests:** Drift DAO tests incl. per-field merge (server delivery patch + local read patch both survive a
simulated pull).

### T7.3.02 — Inbox row creation & device reconciliation
**Priority:** P0 · **Size:** M · **Depends on:** T7.3.01, [7.2] (schedule table, foreground ticker)
**Description:** Create inbox rows for every fired instance with `deliver.inbox = true`, even when the
app never ran at fire time (iOS runs no code when a local notification fires).
**Implementation notes:**
- Foreground: the [7.2] T7.2.17 ticker inserts the row at fire time (`delivered_via = {local}` or
  `{inbox_only}` when `deliver.system = false`).
- Background/killed: on launch/resume, reconcile `local_notification_schedule` entries with
  `fire_at <= now` and `delivered_reconciled_at is null` (+ `getActiveNotifications()` to confirm what is
  still in the tray) → insert rows with `delivered_at = fire_at`, mark reconciled; expired instances
  (past `expires_at` and never shown, e.g. dropped by quiet hours) are not inserted.
- Rows rendered from the planned content (already localized/redacted) with the deep link and actions in
  `payload`; `late = true` when shown after its lateness window (push path, [7.4]).
**Acceptance criteria:** a reminder that fired while the phone was off appears once in the inbox after the
next launch; the same reminder also delivered by push on another device yields one row after sync.
**Tests:** reconciliation unit tests with the fake port; two-client convergence scenario (local + server
insert of the same dedupe key) added to [9.1] T9.1.03.

### T7.3.03 — Inbox screen
**Priority:** P0 · **Size:** M · **Depends on:** T7.3.01, [1.3] (design system, router)
**Description:** Bell icon in the app bar opens the Inbox: rows grouped by day (Today, Yesterday, dates),
nag chains collapsed into one row ("×5"), each row with section icon/color, title, body, relative time,
`late` badge, unread dot and up to two inline action chips (T7.3.04); filter chips (Unread, Plan, Lists,
Habits, Quit, System); *Mark all read*; swipe right = read/unread, swipe left = dismiss (undo snackbar);
pull-to-refresh = sync; empty and "all caught up" states.
**Acceptance criteria:** 1 000 rows scroll at 60 fps; text scale 2.0 and RTL without clipping; screen
reader reads "Unread reminder, Gym, starts in 10 minutes, 08:50".
**Tests:** widget tests (grouping, filters, swipe + undo); goldens light/dark/RTL.

### T7.3.04 — Inbox row actions & deep links
**Priority:** P0 · **Size:** S · **Depends on:** T7.3.03, [7.2] (action handler, snooze engine)
**Description:** Row actions mirror the notification's actions (Done, Start, Snooze ▸ presets, Skip, Log
value, Log craving, Complete item, Mark waiting/blocked) and call the **same** action handler as OS
notifications ([7.2] T7.2.14), so behaviour is identical everywhere. Tapping a row marks it read/opened and
navigates via the shared deep-link parser; stale targets open with "Already done".
**Acceptance criteria:** completing a task from the inbox cancels its remaining nag chain and removes the OS
notification from the tray.
**Tests:** widget tests invoking actions against fake services; deep-link unit tests.

### T7.3.05 — In-app banner component & queue
**Priority:** P0 · **Size:** M · **Depends on:** T7.3.01, [1.3]
**Description:** `InAppBannerHost` at the app root (`OverlayPortal`) showing one banner at a time with a
queue: icon, title, body, up to two actions, tap → deep link, swipe up to dismiss, auto-dismiss after 5 s
(8 s with actions or when a screen reader is active).
**Implementation notes:** de-duplicates by dedupe key and collapses bursts ("3 reminders"); when the
related screen is already visible (e.g. that task's sheet) show a subtle in-place highlight instead;
announces via `SemanticsService.announce`; reduce-motion → fade instead of slide; haptic per profile.
**Acceptance criteria:** five reminders firing within one second produce one collapsed banner and five inbox
rows; banners never cover the keyboard input field in use.
**Tests:** widget tests for queueing, collapsing, auto-dismiss timing (fake clock), a11y announcement.

### T7.3.06 — Bell badge & app-icon badge policy
**Priority:** P1 · **Size:** S · **Depends on:** T7.3.01
**Description:** Bell badge = unread count ("99+" cap). App-icon badge policy setting: *Off*, *Unread inbox*,
*Overdue + due today*; updated after DB changes, actions (also in the background isolate) and day rollover.
**Implementation notes:** iOS badge via notification `badgeNumber` and a badge plugin for direct updates
(choose at implementation, e.g. `app_badge_plus`); Android launcher badges come from active notifications
(`number` where supported) — document launcher variance.
**Acceptance criteria:** badge matches the chosen policy within 2 s of a change and after background actions.
**Tests:** unit tests for badge computation per policy.

### T7.3.07 — System notices in the inbox
**Priority:** P1 · **Size:** S · **Depends on:** T7.3.02, [7.2] (capabilities)
**Description:** Category `system` rows created by the app for conditions the user must know about:
notifications disabled, a channel blocked, exact alarms revoked ("reminders may be late"), iOS reminder
budget saturated, device revoked, sync errors persisting > 24 h, app update required ([9.2] T9.2.07).
Each has a fix action (deep link to settings/diagnostics) and auto-resolves (dismissed) when fixed.
**Acceptance criteria:** revoking exact alarms creates exactly one notice; granting again resolves it.
**Tests:** unit tests for notice lifecycle (create once, resolve, no duplicates via deterministic ids).

### T7.3.08 — Snoozed section & "remind me again"
**Priority:** P1 · **Size:** S · **Depends on:** T7.3.03, [7.2] (snooze engine)
**Description:** A "Snoozed" group at the top listing rows with `snoozed_until > now` (time remaining,
*Wake now*, *Change snooze*), and *Remind me again…* on any past row (creates a snooze instance even for
reminders that were not snoozed).
**Acceptance criteria:** snoozing on one device shows the row as snoozed on others and the snooze fires on the
device(s) chosen by the multi-device policy ([7.4]).
**Tests:** widget tests; unit tests for wake-now cancellation.

### T7.3.09 — Per-item notification history
**Priority:** P1 · **Size:** S · **Depends on:** T7.3.01, [7.1] (notification section component)
**Description:** In task/occurrence, checklist item, habit and quit details: "Reminder history" listing past
inbox rows for that source (fired, opened, acted, snoozed, dismissed) — useful to verify that reminders
work and later feeds reminder-effectiveness stats ([6.5]).
**Tests:** widget test with fixture rows.

### T7.3.10 — Retention & cleanup
**Priority:** P1 · **Size:** S · **Depends on:** T7.3.01, [1.2] (pg_cron)
**Description:** Keep 90 days of inbox history: devices hide older rows; a nightly server job soft-deletes
rows with `fire_at` older than 90 days (tombstones then removed by the standard purge, arch §7.7); local
reconciliation markers older than 14 days are cleaned from the schedule table.
**Data model:** the inbox retention job (arch §7.7 (daily: soft-delete `app.notifications`
older than 90 days).
**Acceptance criteria:** inbox size stays bounded; statistics that need longer history use aggregates
computed before deletion ([7.5] T7.5.17).
**Tests:** pgTAP for the retention function; unit test for local cleanup.

### T7.3.11 — Inbox search, rule filters & bulk actions
**Priority:** P2 · **Size:** S · **Depends on:** T7.3.03
**Description:** Search inbox text, filter by rule/profile/target, multi-select to mark read, dismiss or
*Mute this rule* in bulk; "Show only rules that fired most this week" helps tame noisy configurations.
**Tests:** widget tests for multi-select actions.
