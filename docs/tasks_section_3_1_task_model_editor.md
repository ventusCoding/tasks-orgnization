# Section 3.1 — Task Model & Editor

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.2, 1.3, 1.4, 2.1, 2.2, 2.3
> Architecture: §6.1–§6.6, §6.8, §7.2–§7.3 (`tasks`, `task_occurrences`, `time_entries`), §8.1, §9.1–§9.3

## Goal

Define the Planner's core entity — the **task** — end to end: server tables, the local Drift mirror, a
validated domain model, a repository that writes transactionally through the outbox, and editors that
let the user create a task with any time, duration, time-zone mode and a fully free recurrence rule
("each Monday", "each Monday and Tuesday", "every 2 days", "every hour", "every 45 minutes between 09:00
and 18:00"…) in a few taps.

## Scope

**In:** migrations + pgTAP for `tasks`, `task_occurrences`, `time_entries`; Drift tables/DAOs; domain
entities and value objects; `TasksRepository` (CRUD, soft delete with cascade, restore, duplicate,
activity events); full task editor; quick-create sheet; task details view with history; delete/undo UX;
unscheduled (backlog) task model; icon; deadline; overlap warning; markdown-lite notes; linked checklist;
tags; bulk edit; copy to other days; templates; scheduling a checklist item as a task.
**Out:** occurrence resolution, actions and edit scopes ([3.2]); grid rendering and gestures ([3.3]);
recurrence engine and rule builder UI ([2.1]); notification rule editor ([7.1]); backlog drawer/list UI ([3.7]).

## Progress

- [x] T3.1.01 — Server migration: `tasks`
- [x] T3.1.02 — Server migration: `task_occurrences` & `time_entries`
- [x] T3.1.03 — Drift tables, DAOs & sync registration
- [x] T3.1.04 — Domain entities & value objects
- [x] T3.1.05 — TasksRepository (CRUD, cascade, restore, duplicate, history)
- [x] T3.1.06 — Task editor: scheduling fields
- [x] T3.1.07 — Task editor: detail fields (notes, location, URL, checklist, attachments)
- [x] T3.1.08 — Quick-create sheet
- [x] T3.1.09 — Task details view with history
- [x] T3.1.10 — Delete, restore & undo UX
- [x] T3.1.11 — Unscheduled (backlog) task model
- [x] T3.1.12 — Task icon
- [x] T3.1.13 — Deadline (due date separate from planned time)
- [x] T3.1.14 — Overlap / conflict warning
- [x] T3.1.15 — Markdown-lite notes
- [x] T3.1.16 — Linked checklist integration
- [x] T3.1.17 — Tags on tasks
- [x] T3.1.18 — Multi-select & bulk edit
- [x] T3.1.19 — Copy & duplicate to other days
- [x] T3.1.20 — Task templates
- [x] T3.1.21 — Schedule a checklist item as a task

## Tasks

### T3.1.01 — Server migration: `tasks`
**Priority:** P0 · **Size:** M · **Depends on:** [1.2] (`app.enable_sync`), [2.3] (categories)
**Description:** Create `app.tasks` exactly as in arch §7.3, wired with `app.enable_sync` (sync triggers,
`(user_id, rev)` index, RLS).
**Implementation notes:**
- CHECKs: title length 1–300; `priority` 0–4; `tracking_mode`, `status` and `notify_mode` enums;
  `duration_minutes` 0–525 600; all-day rows need a `start_local` time of 00:00 and a duration that is a
  multiple of 1 440; unscheduled rows (`start_local is null`) must have `recurrence is null`.
- `time_zone` validated by `app.is_valid_time_zone(text)` (lookup in `pg_timezone_names`), NULL = floating.
- `recurrence` must be a JSON object with a `"v"` key; `series_id` defaults to `id` (BEFORE INSERT trigger).
- `linked_checklist_id uuid` is created **without** a foreign key; [4.1] adds the FK once `checklists` exists.
- Indexes: `(user_id, start_local) where deleted_at is null`, `(user_id, series_id)`,
  `(user_id, recurrence_until_local)`.
**Acceptance criteria:**
- pgTAP proves: RLS isolation between two users; constraint violations rejected; the sync trigger sets
  `rev`; a stale `updated_at` update is ignored (LWW); `series_id` defaults to `id`.
**Tests:** `supabase/tests/planner_tasks.test.sql` (pgTAP).
**Notes:** Delivered by the foundation migration `supabase/migrations/20260922000060_create_planner.sql`; pgTAP coverage lives in the shared suites (`030_isolation`, `040_sync_triggers`, `070_domain_constraints`) instead of a separate `planner_tasks.test.sql`.

### T3.1.02 — Server migration: `task_occurrences` & `time_entries`
**Priority:** P0 · **Size:** M · **Depends on:** T3.1.01
**Description:** Create `app.task_occurrences` and `app.time_entries` (arch §7.3) with `app.enable_sync`.
**Implementation notes:**
- `task_occurrences`: `unique (task_id, occurrence_key)`; key format CHECK
  (`^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2})?$` or the quota format `^(day|week|month|year):[0-9-]+#\d+$`, see [3.2]);
  enums for `status`; `completion_percent` 0–100; `rating` 1–5; `skip_reason` free text ≤ 200 chars.
- A BEFORE INSERT trigger verifies the deterministic id `id = app.uuid_v5(task_id || '|' || occurrence_key)`
  (arch §9.2) and rejects mismatches, so buggy clients can never create duplicates.
- `time_entries`: CHECK `ended_at is null or ended_at >= started_at`; index `(user_id, task_id, started_at)`.
**Acceptance criteria:**
- Two upserts of the same occurrence id from different "devices" converge to one row (LWW).
- An insert with a mismatched id is rejected with a clear error.
**Tests:** pgTAP (isolation, id verification, convergence, CHECKs).
**Notes:** Delivered by the same foundation migration (deterministic-id trigger, CHECKs, indexes; pgTAP in `070_domain_constraints`). Client-side two-device convergence: `app/test/features/planner/data/planner_convergence_test.dart`.

### T3.1.03 — Drift tables, DAOs & sync registration
**Priority:** P0 · **Size:** M · **Depends on:** T3.1.02, [1.4]
**Description:** Local mirror of the three tables plus DAOs used by the resolver, the views and the editors.
**Implementation notes:**
- Tables in `features/planner/data/tables/` use the `SyncedTable` mixin ([1.4]); indexes mirrored.
- DAOs:
  - `watchTasksForRange(fromLocal, toLocal)` — uses the pre-filter from [3.2] (T3.2.02).
  - `watchTask(id)` and `watchUnscheduled()`.
  - `watchOccurrenceRecords(taskIds, keyFrom, keyTo)` and `watchRecordsMovedInto(rangeFrom, rangeTo)`.
  - `watchTimeEntries(taskId, occurrenceKey)` and `watchRunningEntries()`.
- Register the three tables in the sync table registry with snake_case JSON mappers.
- Bump `schemaVersion`; commit the schema dump and a migration test.
**Acceptance criteria:**
- A Drift row, its JSON and the server row round-trip identically (all columns, nulls and time types).
- The DAO range queries return exactly the expected rows on fixture data (incl. soft-deleted exclusion).
**Tests:** in-memory Drift DAO tests; mapper tests; `SchemaVerifier` migration test.
**Notes:** Tables, registry entries and the v1 schema baseline live centrally in `core/database` (no bump needed). Planner DAOs are `PlannerQueries` (`watchTask`, `watchUnscheduled`, `tasksForRange` pre-filter, `recordsForRange`, `watchRecords`, `watchTimeEntries`, `watchRunningEntries`), tested through the repository/range tests.

### T3.1.04 — Domain entities & value objects
**Priority:** P0 · **Size:** M · **Depends on:** T3.1.03, [2.1]
**Description:** Pure-Dart domain model in `features/planner/domain/` (no Flutter/Drift imports).
**Implementation notes:**
- freezed entities: `Task`, `TaskOccurrenceRecord`, `TimeEntry`.
- Value objects:
  - `TaskTitle` (trimmed, 1–300 chars) and `DurationMinutes` (0–525 600).
  - `Priority` (none, low, medium, high, urgent) and `TrackingMode` (check, event, timer).
  - `TimeZoneMode` (sealed: `Floating` | `Fixed(zoneId)`).
- `TaskSchedule {startLocal?, durationMinutes, isAllDay, zoneMode, recurrence?}` enforces the invariants of
  T3.1.01 and computes the derived `recurrenceUntilLocal` via the engine: null when open-ended; the last
  occurrence start for `count` rules.
- Convenience getters: `isRecurring`, `isUnscheduled`, `endLocal`.
- Validation errors are typed; the presentation layer localizes them.
**Acceptance criteria:**
- Invalid combinations (all-day at 09:00, recurrence on an unscheduled task, 0-length all-day) are rejected.
- `recurrenceUntilLocal` is correct for until-based, count-based and open-ended fixtures.
**Tests:** unit tests + property tests of schedule invariants.
**Notes:** Hand-written immutable entities and value objects (ADR-016) instead of freezed; `TaskForm` is the editor form state.

### T3.1.05 — TasksRepository (CRUD, cascade, restore, duplicate, history)
**Priority:** P0 · **Size:** M · **Depends on:** T3.1.04, [2.3] (activity log, undo)
**Description:** Application-facing repository; every method is one Drift transaction writing rows,
outbox entries and activity events, and returning an undo command.
**Implementation notes:**
- `create`, `update` (diff-aware: start/duration changes emit `rescheduled {fromStart, toStart, fromDuration,
  toDuration, source}`; other changes emit `updated {fields:[…]}`).
- `softDelete(taskId, operationId)` cascades to the task's `task_occurrences`, `time_entries`,
  attachments (owner `task` / `task_occurrence`) and — once [7.1] exists — its notification rules.
- `restore(operationId)` restores exactly the rows tombstoned by that operation.
- `duplicate(taskId, {asOneOff, targetStartLocal})` creates new ids and a fresh `series_id`, and copies
  attachment rows that point at the same storage objects (arch §6.7).
**Acceptance criteria:**
- Each write produces one coalesced outbox entry per touched row.
- Restoring after a cascade delete brings back occurrences and time entries but not rows deleted earlier.
- A duplicate never shares an id with its source.
**Tests:** repository tests on an in-memory DB with a fake clock, asserting rows, outbox and events.

### T3.1.06 — Task editor: scheduling fields
**Priority:** P0 · **Size:** L · **Depends on:** T3.1.05, [1.3] (pickers), [2.1] (rule builder), [2.3] (categories)
**Description:** Full-screen sheet (phones) / dialog (tablets) to create and edit a task's core fields.
Fields:
- Title.
- Date, and start time with 1-minute precision (12/24 h per profile).
- Duration **or** end time (toggle). Quick chips: 5, 15, 30, 45 min, 1, 1.5, 2, 3 h, or any custom value
  up to 365 days.
- All-day toggle, with a multi-day date range.
- Time-zone mode: Floating (default) or Fixed, with a searchable IANA zone picker showing the current offset.
- Repeat: rule builder with a live human-readable description and a preview of the next occurrences.
- Category, color override, priority.
- Tracking mode (Check / Event / Timer, each with a one-line explanation).

**Implementation notes:**
- A form-state notifier validates through the domain value objects.
- Editing the end keeps the start; crossing midnight is allowed and labelled "+1 day".
- Repeat quick presets:
  - none, daily, every weekday, weekly on this weekday;
  - several weekdays (Mon + Tue…), every N days;
  - every N hours / every N minutes, with a daily window;
  - monthly on day X, monthly on the Nth weekday, yearly;
  - custom (full builder).
- *N times per period* and *after completion* options stay behind a feature flag until [3.2] P1 tasks ship.
- Saving an edit of a recurring task routes through the edit-scope dialog of [3.2].
- Unsaved-changes guard. Prefill from the slot/day context passed by the caller.
**Acceptance criteria:**
- After typing the title, each of these takes ≤ 6 taps and is persisted exactly:
  - "Gym every Monday and Tuesday 07:00–08:00"
  - "Drink water every 90 min 08:00–20:00"
  - "Review every 2 days at 21:00"
  - "Standup every weekday 09:30 for 15 min, fixed Europe/Paris"
- No overflow in RTL and at text scale 2.0.
**Tests:** widget tests per preset; form-notifier unit tests; goldens (light/dark, LTR/RTL).
**Notes:** Tablets get the full-screen route with a centered 720-dp form rather than a dialog route (router unchanged). Goldens: `test/features/planner/presentation/goldens/task_editor_*.png`.

### T3.1.07 — Task editor: detail fields (notes, location, URL, checklist, attachments)
**Priority:** P0 · **Size:** M · **Depends on:** T3.1.06, [2.2]
**Description:** Secondary editor sections:
- notes (plain multi-line text for now; markdown-lite in T3.1.15);
- location (text) and URL (validated; opens externally after confirmation);
- linked checklist (pick an existing one or create new);
- attachments strip ([2.2] component, owner `task`);
- a "Reminders: default" row that becomes the notification editor in [7.1].
**Implementation notes:** the linked-checklist picker stays hidden behind a flag until [4.1] exists.
**Acceptance criteria:** attachments added offline show immediately and upload later; an invalid URL shows
an inline error; the reminders row is present but inert before [7.1].
**Tests:** widget tests.
**Notes:** Linked-checklist picker queries `checklists` directly (no flag: [4.1] exists). Reminders use `NotificationSettingsSection` with a draft saved in the create transaction.

### T3.1.08 — Quick-create sheet
**Priority:** P0 · **Size:** S · **Depends on:** T3.1.06
**Description:** Minimal sheet with a title field and chips for date/time/duration, repeat and category.
*More options* opens the full editor. *Add & new* keeps the sheet open with the next slot prefilled.
Used by grid gestures ([3.3]), the day list ([3.5]), the FAB and the universal quick-add ([8.1]).
**Implementation notes — default duration rule:**
1. If the caller passes a range (drag-to-create), use it.
2. Else, if 15 ≤ slot ≤ 60 min, use the slot length.
3. Else use `planner.defaultTaskDurationMinutes` (default 30). This covers 1–10-min slots and table mode ≥ 120 min.
4. In week-list mode (1 440-min slot), create an untimed (all-day) task for that day.
**Acceptance criteria:**
- Tapping 09:00 on a 30-min grid gives 09:00–09:30; on a 5-min grid, 09:00–09:30; on a 2-h grid, 08:00–08:30.
- Tapping a day in week-list mode gives an all-day task.
**Tests:** table-driven unit tests for the duration rule; widget test for *Add & new*.

### T3.1.09 — Task details view with history
**Priority:** P0 · **Size:** M · **Depends on:** T3.1.05, [2.3] (activity events)
**Description:** Series-level read view, containing:
- title and schedule summary: recurrence description, zone mode, next occurrence;
- category, priority and tracking badges; notes; attachments; linked checklist progress;
- the next 5 occurrences with their status;
- a history timeline from activity events: created, fields edited, rescheduled from→to, completed,
  skipped with reason, deleted/restored;
- actions: Edit, Duplicate, Delete, Share as text.
Occurrence-specific actions live in the occurrence sheet ([3.2]).
**Acceptance criteria:** history pages lazily, 50 events at a time; reschedule entries show both times in
the viewer's zone.
**Tests:** widget tests with fixture events; golden.

### T3.1.10 — Delete, restore & undo UX
**Priority:** P0 · **Size:** S · **Depends on:** T3.1.05, [2.3] (undo)
**Description:** Delete from the editor, the details view or a grid menu:
- One-off task: soft delete with a 5 s undo snackbar.
- Recurring task: scope dialog (this / this & following / all), logic in [3.2].
Restored tasks reappear where they were. Deleted tasks are listed in Trash ([8.3]).
**Tests:** widget test (snackbar undo); repository restore test.

### T3.1.11 — Unscheduled (backlog) task model
**Priority:** P1 · **Size:** M · **Depends on:** T3.1.05
**Description:** Tasks with `start_local = null` ("to schedule"):
- estimate, priority, category, optional deadline (T3.1.13);
- manual order via the fractional `manual_sort_key`;
- created in the same editor via a *No date* option.
Scheduling sets `start_local` and a duration equal to the estimate or the default. The drawer and list UI
live in [3.7].
**Implementation notes:**
- The resolver ignores unscheduled tasks, and recurrence is disabled while unscheduled.
- `manual_sort_key` is also the manual order of untimed tasks within a day in week-list mode (arch §7.3).
**Acceptance criteria:** switching between scheduled and unscheduled keeps all other fields and writes a
`scheduled` or `unscheduled` activity event.
**Tests:** repository and validation tests.

### T3.1.12 — Task icon
**Priority:** P1 · **Size:** S · **Depends on:** T3.1.06, [1.3] (icon picker)
**Description:** Optional icon (Material Symbols key), shown on tiles, the ribbon style ([3.5]), the agenda
and widgets. Defaults to the category icon.
**Data model:** `tasks.icon text` (nullable) (arch §7.3).
**Tests:** widget test; mapper round-trip.
**Notes:** `PlannerItem.icon` is the effective icon: the task icon, else its category icon (range items, occurrence sheet, backlog items).

### T3.1.13 — Deadline (due date separate from planned time)
**Priority:** P1 · **Size:** M · **Depends on:** T3.1.06
**Description:** Optional deadline (date or date-time, same zone mode as the task), separate from the planned
slot: "I plan it Tuesday 10:00; it's due Friday".
- Shown as a flag on tiles.
- Drives overdue/at-risk indicators, backlog sorting and Eisenhower urgency ([3.7]).
- Is the `due` anchor for reminders ([7.5]).
**Data model:** `tasks.deadline_local timestamp` (nullable) (arch §7.3).
**Acceptance criteria:** planning a task after its deadline shows a warning; stats can compare completion
time with the deadline ([6.3]).
**Tests:** validation and widget tests.
**Notes:** Tile flag, at-risk indicators and backlog sorting are rendered by the views ([3.3]–[3.7]) from `PlannerItem.deadlineLocal`; the one-off deadline is the `due` anchor of planner notification targets.

### T3.1.14 — Overlap / conflict warning
**Priority:** P1 · **Size:** S · **Depends on:** T3.1.06, [3.2]
**Description:** While editing the time, a non-blocking hint lists overlapping `check`/`timer` occurrences,
e.g. "Overlaps with Team sync 09:30–10:00". Showing `event` overlaps is optional; the hint can be disabled
in settings.
**Implementation notes:** resolve only the affected day(s); ignore done/cancelled occurrences.
**Tests:** unit test for the overlap query; widget test.

### T3.1.15 — Markdown-lite notes
**Priority:** P1 · **Size:** M · **Depends on:** T3.1.07
**Description:** Notes support bold, italic, one heading level, bullet and numbered lists, display-only
checkboxes, auto-detected links and code spans. A compact toolbar handles editing. Notes render in the
details view, the occurrence sheet and search snippets, and are stored as Markdown text.
**Implementation notes:** no raw HTML; confirm before opening external links; paragraph direction follows
the first strong character (mixed Arabic/Latin).
**Tests:** parser/renderer unit tests; goldens (LTR/RTL).
**Notes:** Search snippets belong to the search feature ([8.1]); `markdownLiteToPlain` is available for them.

### T3.1.16 — Linked checklist integration
**Priority:** P1 · **Size:** S · **Depends on:** T3.1.07, [4.1], [4.3]
**Description:** A task can link one checklist:
- open it from the task;
- show its progress (x/y and a status bar) on tiles and in details;
- create a new checklist from the task ("Add checklist"), or unlink.
The routine player ([3.7]) uses the link.
**Tests:** widget tests; progress-provider unit test.
**Notes:** Progress on grid tiles is drawn by the views ([3.3]) from `linkedChecklistProvider`; the routine player ([3.7]) uses the link.

### T3.1.17 — Tags on tasks
**Priority:** P1 · **Size:** S · **Depends on:** T3.1.06, [2.3] (tags)
**Description:** Tag picker in the editor (inline create), tag chips in details, and tag filtering in every
Planner view.
**Tests:** widget test; deterministic `entity_tags` id test.
**Notes:** Tag filtering in the Planner views belongs to the views ([3.3]–[3.7]); saved tasks edit their tags live through `EntityTagChips`.

### T3.1.18 — Multi-select & bulk edit
**Priority:** P1 · **Size:** M · **Depends on:** T3.1.05, [3.3]
**Description:** Selection mode in the week table, day list, agenda and table views (long-press → *Select*,
or the toolbar). Bulk actions:
- move by ±N days or ±time;
- set category, priority, tracking mode or tags;
- duplicate;
- delete. For recurring items the user picks per selection whether to act on the occurrence or the series.
**Acceptance criteria:** one bulk operation runs in one transaction and is undone as one command.
**Tests:** repository bulk tests; widget test.
**Notes:** Planner-core ships `showBulkActionsSheet(context, items)` (move, category, priority, tracking, add tags, duplicate, delete; occurrence vs series toggle; one op / one undo). The selection mode (long-press → Select, toolbar) in the week table, day list, agenda and table views is wired by the views agent ([3.3]–[3.7]). Bulk value types moved to `domain/bulk_change.dart` (re-exported by the repository).

### T3.1.19 — Copy & duplicate to other days
**Priority:** P1 · **Size:** S · **Depends on:** T3.1.05
**Description:**
- *Duplicate to…* opens a multi-date calendar and copies a task or occurrence as one-off tasks on the chosen
  dates, at the same time.
- *Duplicate as new series* copies the whole series.
- On tablets, Ctrl/Cmd + C / V copies and pastes at the selected slot.
**Tests:** repository tests (ids, dates and zone mode preserved).
**Notes:** The Ctrl/Cmd + C / V shortcut belongs to the grid ([3.3]); it pastes through `PlannerService.pasteAt(item, start)` (one-off copy at the slot, zone mode kept).

### T3.1.20 — Task templates
**Priority:** P2 · **Size:** S · **Depends on:** T3.1.05
**Description:** Save a task (without dates) as a template, create new tasks from templates ("From
template…") and manage the template list.
**Data model:** `tasks.is_template boolean not null default false`. The resolver, stats and default
search results exclude templates.
**Tests:** repository and resolver-exclusion tests.

### T3.1.21 — Schedule a checklist item as a task
**Priority:** P2 · **Size:** M · **Depends on:** T3.1.05, [4.2]
**Description:** Create a task linked to a checklist item, from the item's menu or by dragging it from the
backlog drawer ([3.7]). Completing the task offers to complete the item. The item shows a "scheduled"
badge linking back to the task.
**Data model:** `tasks.linked_item_id uuid` (nullable, FK to `checklist_items`).
**Tests:** repository test of the bidirectional completion prompt logic.
**Notes:** Schema v2 adds `tasks.linked_item_id` (server FK + same-owner trigger, Drift column, step migration). *Schedule as task* lives in the item details sheet (`ChecklistTaskLinks.scheduleItem`: unscheduled task titled with the item's first line, then the task editor); scheduled items show an `event_available` badge in their row and a "Scheduled: …" link in the sheet (`itemTasksProvider`). Prompts: marking an occurrence done (`PlannerCommands.setStatus`) offers to complete the open linked item; completing an item (checklist toggle) offers to mark the open occurrence of a linked one-off task done (recurring / unscheduled tasks are not offered). Logic tested on the real data layer (`item_scheduling_test.dart`). The backlog-drawer drag is part of T3.7.02.
