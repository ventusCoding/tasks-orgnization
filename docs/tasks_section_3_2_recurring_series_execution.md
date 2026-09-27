# Section 3.2 — Recurring Series & Occurrence Execution

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 2.1, 2.3, 3.1
> Architecture: §6.8, §7.3 (`tasks`, `task_occurrences`, `time_entries`, `activity_events`), §9.1, §9.2 (UUIDv5)

## Goal

Turn task definitions into concrete **occurrences** for any date range. Occurrences must be correct for every
recurrence rule, override, cancellation, time zone and DST transition. The user can act on each occurrence
(done, skip, start, reschedule, track time) and edit or delete series with the familiar *this occurrence /
this & following / all* scopes. Every change is recorded as history so stats ([6.3]) can measure
completion, punctuality and procrastination.

## Scope

**In:**
- Occurrence resolver, range pre-filter, caching and isolate execution; display time-zone rules.
- Occurrence actions and occurrence sheet.
- Edit and delete scopes, including series split and orphaned overrides.
- Reschedule operations and history.
- Missed / overdue / roll-over; tracking-mode behaviour; actual-time capture.
- After-completion and quota tasks.
- Time tracking; series history; pause/resume; occurrence notes and attachments; bulk actions.

**Out:** rendering ([3.3]–[3.7]); recurrence expansion math ([2.1]); reminders ([7.x]); metrics ([6.3]).

## Progress

- [x] T3.2.01 — Occurrence resolver
- [x] T3.2.02 — Range pre-filter, caching & isolate execution
- [x] T3.2.03 — Display time-zone rules (fixed vs floating, all-day, DST)
- [x] T3.2.04 — Occurrence actions service
- [x] T3.2.05 — Occurrence sheet UI
- [x] T3.2.06 — Edit-scope dialog & "this occurrence" overrides
- [x] T3.2.07 — "This & following" series split
- [x] T3.2.08 — "All occurrences" edits with history preservation
- [x] T3.2.09 — Orphaned overrides handling
- [x] T3.2.10 — Reschedule operations & reschedule history
- [x] T3.2.11 — Delete scopes
- [x] T3.2.12 — Missed detection, overdue & roll-over
- [x] T3.2.13 — Tracking-mode behaviour
- [x] T3.2.14 — Actual-time capture on completion
- [x] T3.2.15 — After-completion recurrence execution
- [x] T3.2.16 — Quota tasks ("N times per period")
- [x] T3.2.17 — Time tracking: timers, pauses & sessions
- [x] T3.2.18 — Manual time entries & editing
- [x] T3.2.19 — Running-timer indicator & timer policy
- [x] T3.2.20 — Series history view
- [x] T3.2.21 — Pause / resume a series
- [x] T3.2.22 — Occurrence notes & attachments
- [x] T3.2.23 — Bulk occurrence actions

## Tasks

### T3.2.01 — Occurrence resolver
**Priority:** P0 · **Size:** L · **Depends on:** [2.1], [3.1]
**Description:** Pure domain service
`OccurrenceResolver.resolve(tasks, records, range, viewerZone, now, settings) → List<ResolvedOccurrence>`
for a half-open range `[from, to)` in the viewer's zone. It handles:
- one-off tasks and recurring tasks (via the engine's `between`);
- occurrence records: overrides of start/duration/title/notes, cancellations, and moves into or out of the range;
- multi-day overlap: occurrences that start before `from` but reach into it.

It also computes each occurrence's derived status and flags.
**Implementation notes:**
- `ResolvedOccurrence` fields:
  - identity: `taskId, seriesId, occurrenceKey, recordId?`
  - time: `startInstant, endInstant, startLocalViewer, endLocalViewer, isAllDay`
  - display: `title, categoryId, color, priority, trackingMode, recurrenceSummary?`
  - state: `status, isCurrent, isOverdue, isMoved, isOverridden`
- Each task is expanded over `[from − duration, to)` so long tasks crossing the start are included.
  Records whose `override_start_local` falls inside the range are included even if their original key is
  outside ("moved in"); originals moved elsewhere are excluded.
- Derived status precedence:
  1. The record status wins (`done`, `skipped`, `cancelled`, `in_progress`, explicit `missed`).
  2. Otherwise `scheduled`, with `isCurrent` while `now ∈ [start, end)`.
  3. It becomes `missed` for `check`/`timer` tasks once `now ≥ end + planner.missedGraceMinutes`. This is
     derived only and never written. `event` tasks never become missed.
- `isOverdue` = missed, one-off, and within the overdue look-back (default 7 days).
- Stable ordering: start ascending, all-day first, priority descending, title, id. Same inputs always
  produce the same output.
- No I/O: callers pass tasks and records in.
**Acceptance criteria:**
- The fixture suite `fixtures/planner/resolver/*.json` has ≥ 60 cases and passes. It covers:
  - weekly MO+TU, every 2 days, hourly, every 45 min inside a daily window, last weekday of the month;
  - moved occurrences (into and out of the range), cancelled occurrences, title/duration overrides;
  - a multi-day task crossing the range start;
  - a fixed-zone task viewed from another zone, and a floating task after the device zone changes;
  - DST gap and overlap days;
  - derived missed after the grace period, and `event` tasks that are never missed.
- Resolving one week for 200 tasks (10 of them minutely) takes < 30 ms on a mid-range device.
**Tests:** fixture-driven unit tests; property tests (sorted output, no duplicate `(taskId, key)`, all
occurrences overlap the range).

### T3.2.02 — Range pre-filter, caching & isolate execution
**Priority:** P0 · **Size:** M · **Depends on:** T3.2.01, [3.1] (DAOs)
**Description:** `OccurrenceRangeService.watch(range)` combines Drift streams with the resolver, SQL
pre-filtering, memoization and background execution for heavy ranges.
**Implementation notes:**
- Task pre-filter:
  - not deleted, not archived, scheduled;
  - `start_local <= to + 14 h` (margin for the maximum zone offset);
  - `recurrence_until_local is null or >= from − 14 h − max(duration)`.
- Records pre-filter: `task_id in (…)`, and either the key range or `override_start_local` inside the range.
- Results are cached per `(range, dataVersion)`; `dataVersion` changes on relevant Drift `tableUpdates`.
- Resolution runs in an isolate (`Isolate.run`) when estimated occurrences exceed 2 000 (minutely rules,
  long ranges). Results are diffed by `(taskId, key)` so renderers get minimal changes.
- Hard cap (default 20 000 occurrences per range). Hitting it sets a `truncated` flag and the UI says
  "Too many occurrences to display — zoom in".
**Acceptance criteria:**
- A one-year range for 300 tasks resolves off the UI thread with no dropped frames.
- Editing one task recomputes and re-emits only that task's occurrences (diff test).
**Tests:** service tests with fake DAOs; isolate-path test; cap test.
**Notes:** The "Too many occurrences — zoom in" message is rendered by the views ([3.3]) from `plannerRangeTruncatedProvider`; tests in `test/features/planner/application/occurrence_range_service_test.dart`.

### T3.2.03 — Display time-zone rules (fixed vs floating, all-day, DST)
**Priority:** P0 · **Size:** S · **Depends on:** T3.2.01
**Description:** Explicit, documented rules for mapping occurrences onto the viewer's clock:
- **Fixed-zone** task: start in its own zone → instant → viewer zone. A 10:00 New York standup shows at
  16:00 in Paris, with a zone badge.
- **Floating** task: shown at the same wall-clock time in whatever zone the viewer is in.
- **All-day** tasks are date-based and never shift days.
- **Multi-day timed** tasks keep their instants.
- **DST:** non-existent local times shift forward by the gap; ambiguous times take the earlier offset
  (arch §6.8).
- Occurrence keys always stay in the task's own wall clock.
**Acceptance criteria:** fixture cases for each rule, including a user travelling Paris → Tokyo with a mix
of floating and fixed tasks.
**Tests:** multi-zone unit tests.

### T3.2.04 — Occurrence actions service
**Priority:** P0 · **Size:** M · **Depends on:** T3.2.01, [2.3] (activity log, undo)
**Description:** `OccurrenceActions`:
- `markDone({actualStart?, actualEnd?})`, `undoDone`, `reopen`;
- `skip({reason})`;
- `start` (→ `in_progress`; starts a timer for `timer` tasks, T3.2.17) and `stop`;
- `setCompletionPercent`, `rate(1–5)`, `setOutcomeNote`.

Each action upserts the occurrence record with the deterministic id `uuidv5(task_id|occurrence_key)`,
sets `status_changed_at` / `completed_at`, writes an activity event (`completed`, `reopened`,
`skipped {reason}`, `started`, `stopped`) and returns an undo command.
**Implementation notes:**
- Everything happens in one transaction, and actions are idempotent (marking done twice is a no-op).
- `skip_reason` holds a reason key (`too_busy`, `sick`, `not_needed`, `forgot`, `other`) or free text.
- One-off tasks use the same path, with record key = `start_local`.
**Acceptance criteria:**
- Two devices marking the same occurrence done offline converge to one row (sync suite, [9.1]).
- Undo restores the previous record state exactly (including "no record").
**Tests:** unit tests per action; deterministic-id test; activity-event payload tests.

### T3.2.05 — Occurrence sheet UI
**Priority:** P0 · **Size:** M · **Depends on:** T3.2.04
**Description:** Bottom sheet opened by tapping an occurrence in any view. It shows:
- title; time range (viewer zone, plus the task's own zone if fixed); recurrence summary; status chip;
- primary actions by tracking mode: Done / Skip / Start or Stop;
- secondary actions: Reschedule…, Edit, Duplicate, Delete, Open series;
- editable actual times; rating and outcome note;
- linked checklist progress and the occurrence attachments strip (T3.2.22).
**Implementation notes:** Skip opens a reason picker (quick reasons + free text). Done applies T3.2.14.
Every action is reachable through semantics actions.
**Acceptance criteria:** every action shows in all open views within one frame of the DB write.
**Tests:** widget tests for each tracking mode; golden.
**Notes:** Goldens: `test/features/planner/presentation/goldens/occurrence_sheet_*.png`.

### T3.2.06 — Edit-scope dialog & "this occurrence" overrides
**Priority:** P0 · **Size:** M · **Depends on:** T3.2.04, [3.1]
**Description:** Saving an edit to a recurring task — from the editor, a drag/move/resize, or the sheet —
asks *This occurrence* / *This and following* / *All occurrences*, showing only valid options.

*This occurrence* writes override fields on `task_occurrences`: start, duration, title, notes. Other fields
(category, color, priority, tracking mode, location…) are series-level, so the option is disabled for those
edits with a one-line explanation. *Restore to series* clears the overrides.
**Data model (optional, P2):** `task_occurrences.override_fields jsonb`, if per-occurrence
category/color/priority/location overrides are wanted later.
**Acceptance criteria:** dragging one occurrence of a daily series to 10:00 moves only that day; *Restore
to series* moves it back.
**Tests:** unit tests for override merge; widget test for the option matrix.

### T3.2.07 — "This & following" series split
**Priority:** P0 · **Size:** L · **Depends on:** T3.2.06, [2.1] (split helper)
**Description:** Split a series at occurrence key `k`:
1. Truncate the old task's rule so `until` = start of the occurrence before `k`. If `k` is the first
   occurrence, fall back to *All*.
2. Create a new task with the same `series_id`, `start_local` = the new start of `k`, and the copied rule
   adjusted:
   - remaining `count` = original count − occurrences before `k`;
   - exdates/rdates ≥ `k` move to the new rule;
   - the user's edits applied.
3. Re-key `task_occurrences` with keys ≥ `k` to the new task: new deterministic ids, old rows tombstoned.
4. Copy the series' notification rules ([7.1] hook) and attachment rows to the new task.
**Implementation notes:**
- One transaction, with activity event `series_split {fromTaskId, toTaskId, atKey}`.
- If the new rule changes the time of day, records whose keys the new rule no longer generates go
  through T3.2.09.
**Acceptance criteria:**
- Series stats (grouped by `series_id`) stay continuous across the split ([6.3]).
- One undo restores both tasks and all records.
**Tests:** fixture tests (count-based, until-based, open-ended, split at first occurrence, time-of-day change); undo test.

### T3.2.08 — "All occurrences" edits with history preservation
**Priority:** P0 · **Size:** M · **Depends on:** T3.2.07
**Description:** Series-level edits.
- Non-timing fields (title, notes, category, color, priority, tracking mode, location…) update the master
  and apply to past and future occurrences.
- Timing or rule changes would re-key past occurrences and orphan their outcomes. By default they apply
  **from the first non-past occurrence** through an implicit split (T3.2.07), with the message "Past
  occurrences keep their original times".
- An explicit option *Also rewrite past occurrences* edits the master directly; affected records then go
  through T3.2.09.
**Acceptance criteria:** moving a daily 08:00 task to 09:00 keeps last month's history intact and visible at 08:00.
**Tests:** unit tests for both paths.

### T3.2.09 — Orphaned overrides handling
**Priority:** P0 · **Size:** S · **Depends on:** T3.2.07
**Description:** When a rule change leaves stored records (overrides or outcomes) matching no generated key,
a confirmation lists them, e.g. "2 moved occurrences, 5 completed occurrences", with two choices:
- *Keep as one-off tasks*: records become standalone tasks that keep their outcome.
- *Discard*.

Past records with an outcome (done/skipped/rated/tracked) are always converted, never discarded, to
protect history.
**Tests:** unit tests for detection and conversion.

### T3.2.10 — Reschedule operations & reschedule history
**Priority:** P0 · **Size:** M · **Depends on:** T3.2.06
**Description:** Operations shared by gestures and menus:
- move an occurrence (override); move a series (via scopes); change duration;
- *Postpone* quick options: +15 min, +1 h, this evening 20:00, tomorrow same time, next week same time,
  pick…;
- *Move to today* for overdue items.

Every change writes activity event `rescheduled {scope, fromStart, toStart, fromDuration, toDuration,
source: drag|menu|rollover|bulk|backlog}`.
**Acceptance criteria:** postponing one occurrence three times writes three events with correct from/to
values (input for the reschedule and procrastination stats in [6.3]).
**Tests:** unit tests; event payload schema test.

### T3.2.11 — Delete scopes
**Priority:** P0 · **Size:** S · **Depends on:** T3.2.06, T3.2.07
**Description:**
- *This occurrence*: record `is_cancelled = true`, status `cancelled`; hidden unless `showCancelled`.
- *This & following*: truncate the rule and tombstone records ≥ key.
- *All*: soft-delete the task with cascade ([3.1]).

All scopes are undoable and logged as activity events.
**Tests:** unit tests per scope, including the first-occurrence edge case.

### T3.2.12 — Missed detection, overdue & roll-over
**Priority:** P0 · **Size:** M · **Depends on:** T3.2.01
**Description:**
- Derived missed status, using `planner.missedGraceMinutes` (default 60).
- An overdue provider for one-off `check` tasks, with a look-back (default 7 days).
- A roll-over policy `planner.rollOverIncomplete`: `off` | `ask` | `auto`. With `auto`, unresolved one-off
  tasks move to today at app start / day change: same time if still ahead, otherwise all-day. Each move
  writes `rescheduled` with source `rollover`.
- Recurring occurrences never roll over; they stay missed but can be moved to today manually.
**Implementation notes:** two devices may roll over the same task. Both write the same values (LWW on
one row), and the activity event id is deterministic (`uuidv5(task_id|rollover|date)`), so the result is
the same.
**Acceptance criteria:** yesterday's unfinished 18:00 one-off appears as overdue; with `auto` it moves to
today exactly once, even with two devices.
**Tests:** unit tests with a fake clock; two-device idempotency test.

### T3.2.13 — Tracking-mode behaviour
**Priority:** P0 · **Size:** S · **Depends on:** T3.2.04
**Description:** One `TrackingPolicy` used by the resolver, the UI and stats:
- `check` needs done/skip and can be missed.
- `event` is a time block (meeting, meal): no checkbox, never missed, counted as busy time and in time
  allocation, excluded from completion rates.
- `timer` completes through the timer or explicit done, and counts as missed if never started.
**Tests:** unit tests over the full policy table.

### T3.2.14 — Actual-time capture on completion
**Priority:** P0 · **Size:** S · **Depends on:** T3.2.04
**Description:** On *Done*, capture actual start/end according to `planner.askActualTimeOnDone`:
- `never`;
- `if_off_schedule` (default): asked when done is more than 15 min from the planned end;
- `always`.

Quick options: *As planned*, *Just now*, *Custom…*. Timer tasks take their actual times from time entries.
**Data model:** settings key `planner.askActualTimeOnDone` (arch §8.5).
**Acceptance criteria:** *As planned* stores actual = planned; *Just now* stores end = now and start = now −
planned duration; *Custom* validates end ≥ start.
**Tests:** unit tests for the three options and the setting.

### T3.2.15 — After-completion recurrence execution
**Priority:** P1 · **Size:** M · **Depends on:** T3.2.04, [2.1]
**Description:** Rules with `type: after_completion` have exactly one pending occurrence.
- Next start = last completion + amount. Day-or-larger units land on the anchor's time of day; minute and
  hour units are exact.
- Completing it (or skipping, if configured) generates the next one.
- Keys come from the computed starts. Editing the rule re-bases the pending occurrence.
**Acceptance criteria:** "Water plants 3 days after done, at 09:00":
- done Monday 20:00 → next Thursday 09:00;
- that one done late on Friday → next Monday 09:00.
**Tests:** fixture tests incl. minute/hour units and skip policy.

### T3.2.16 — Quota tasks ("N times per period")
**Priority:** P1 · **Size:** M · **Depends on:** T3.2.01, [2.1]
**Description:** Rules with `type: quota` (e.g. "Run 3× per week, any days") produce N **unplaced** slots
per period, keyed `week:YYYY-MM-DD#1..N`.
- Unplaced slots appear in the all-day lane / week header as "Run · 1/3 this week" and in the backlog
  drawer ([3.7]).
- Dragging a slot into the grid sets `override_start_local` without changing its key.
- Completing any slot, placed or not, counts toward the period.
**Implementation notes:** periods follow the week start and month boundaries. `minGapDays` only affects
suggestions.
**Data model:** quota key format `<period>:<start>#<n>` (arch §6.8, occurrence identity).
**Acceptance criteria:** after 3 completions in a week the indicator shows "done for this week" and no
more slots appear until next week.
**Tests:** resolver fixture tests; widget test of the header indicator.
**Notes:** Planner-core ships `quotaSummaries(items)` and the `QuotaIndicator` pill ("Run · 1/3 this week" / "done for this week"); placing it in the all-day lane / week header and the backlog drawer is up to the views ([3.3]–[3.7]).

### T3.2.17 — Time tracking: timers, pauses & sessions
**Priority:** P1 · **Size:** M · **Depends on:** T3.2.04, T3.2.13
**Description:** Start / pause / resume / stop per occurrence.
- Each run is a `time_entries` row: pause closes the entry, resume opens a new one.
- `tracked_seconds` is denormalized on the record.
- `actual_start_at` = first entry start; `actual_end_at` = last entry end at completion.
- A running entry (`ended_at is null`) survives app kill and syncs across devices.
**Acceptance criteria:** a timer started on the phone shows as running on the tablet after sync; stopping
it on the tablet closes the same entry.
**Tests:** unit tests (sums, overlap rejection); two-device scenario in the sync suite ([9.1]).
**Notes:** Two-device scenario in `test/features/planner/data/planner_convergence_test.dart`.

### T3.2.18 — Manual time entries & editing
**Priority:** P1 · **Size:** S · **Depends on:** T3.2.17
**Description:** Add, edit or delete entries for an occurrence (e.g. forgot to start the timer).
Negative durations are rejected; overlaps with other entries trigger a warning.
**Tests:** unit and widget tests.

### T3.2.19 — Running-timer indicator & timer policy
**Priority:** P1 · **Size:** S · **Depends on:** T3.2.17
**Description:** A global running-timer chip in the app bar (title + elapsed; tap → occurrence).
`planner.timerPolicy` offers `single` (default: starting another timer pauses the current one) or
`multiple`. The ongoing notification and Live Activity are handled in [7.2] / [8.2].
**Data model:** settings key `planner.timerPolicy` (arch §8.5).
**Tests:** widget test; policy unit tests.
**Notes:** `RunningTimerChip` is shown by the shared `AppBarActions` (one additive line); the ongoing notification / Live Activity stay with [7.2] / [8.2].

### T3.2.20 — Series history view
**Priority:** P1 · **Size:** M · **Depends on:** T3.2.01
**Description:** For a whole series (`series_id`, across splits):
- a list of past and future occurrences with status, planned vs actual times and reschedules;
- filters: done, skipped, missed, moved;
- a mini month calendar;
- entry point to series stats ([6.3]).
**Tests:** widget tests with fixture data.

### T3.2.21 — Pause / resume a series
**Priority:** P1 · **Size:** S · **Depends on:** T3.2.01
**Description:** `status = paused` hides occurrences from the pause moment on, without deleting anything;
resume brings them back. Activity events `paused` / `resumed` let stats exclude paused spans from expected
occurrences ([6.1]).
**Tests:** resolver tests over paused spans.

### T3.2.22 — Occurrence notes & attachments
**Priority:** P2 · **Size:** S · **Depends on:** T3.2.05, [2.2]
**Description:** Per-occurrence outcome notes (`outcome_note`, markdown-lite) and attachments (owner
`task_occurrence`), e.g. a photo of today's finished workout.
**Tests:** widget test.

### T3.2.23 — Bulk occurrence actions
**Priority:** P2 · **Size:** S · **Depends on:** T3.2.04
**Description:** Day-menu actions: *Mark all remaining today as done*, *Skip the rest of the day*,
*Move unfinished to tomorrow*. Each is one transaction with a single undo.
**Tests:** unit tests.
**Notes:** Service `markRemainingDone` / `skipRestOfDay` / `moveUnfinishedToTomorrow` + reusable `DayActionsMenuButton(day:)`; placing it in the day headers is up to the views ([3.3]–[3.5]).
