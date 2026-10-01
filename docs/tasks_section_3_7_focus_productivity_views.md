# Section 3.7 — Focus & Productivity Views

> Milestones: M2 (P1) · M3 (P2) · Depends on: 3.1, 3.2, 3.3, 3.6, 4.3, 5.3
> Architecture: §6.9, §8.3 (view types), §8.5 (planner settings)

## Goal

Views that help the user *act* on the plan rather than just look at it:
- a focus screen for *now*, and a routine player;
- timeboxing unscheduled work into the grid, and finding free time;
- a spreadsheet of tasks, and comparing plan with reality;
- alternative lenses: Kanban, Eisenhower, radial clock, horizons, countdowns, map.

These close the "find more views" request with the productivity patterns found in research (Sunsama,
Akiflow, Structured, Todoist, TickTick, Fantastical, Toggl, Sectograph, Timestripe, Routinery, Tiimo, Notion).

## Scope

**In:** Now/Next focus view; backlog drawer and backlog list; free-slot finder and openings; table
(spreadsheet) view; plan-vs-actual; routine player; Kanban; Eisenhower matrix; 24-h radial clock; horizons;
countdown / count-up; map; tests.
**Out:** Live Activities, lock-screen timers and widgets ([8.2]); insights dashboards ([6.3]).

## Progress

- [x] T3.7.01 — Now / Next focus view
- [ ] T3.7.02 — Backlog drawer & timeboxing
- [ ] T3.7.03 — Backlog list screen
- [ ] T3.7.04 — Free-slot finder & openings
- [ ] T3.7.05 — Table (spreadsheet) view
- [ ] T3.7.06 — Plan-vs-actual view
- [ ] T3.7.07 — Routine player
- [ ] T3.7.08 — Kanban board
- [ ] T3.7.09 — Eisenhower matrix
- [ ] T3.7.10 — 24-hour radial clock
- [ ] T3.7.11 — Horizons view
- [ ] T3.7.12 — Countdown / count-up list
- [ ] T3.7.13 — Map view
- [ ] T3.7.14 — Productivity views test suite

## Tasks

### T3.7.01 — Now / Next focus view
**Priority:** P1 · **Size:** M · **Depends on:** [3.2] (actions, time tracking), [3.6] (view registry)
**Description:** A full-screen focus mode for the current occurrence, showing:
- a large countdown ring (time left until the planned end) and the elapsed tracked time;
- title and notes; the linked checklist's items, tickable inline;
- a *Next up* card with its own countdown.

Actions:
- Start / Pause / Stop, Done, Skip, *Next*;
- *Extend* (+5 / +15 / +30 min), which overrides this occurrence's end only.

Optional keep-screen-on; honours reduce-motion.
**Acceptance criteria:** reopening focus mode after an app restart shows the correct remaining and elapsed
times; *Extend* writes one override and one `rescheduled` event.
**Tests:** widget tests with a fake clock.
**Notes:** `FocusView` + pure `selectFocus` (pinned → in progress → covering now; `missed` never current) in `engine/focus_selection.dart`. Everything derives from the clock and stored data (time entries, tracked seconds), so a restart shows the right times. Ring counts down to the planned end and counts overtime up; reduced motion hides seconds and ticks every 15 s. *Extend* = `reschedule(thisOccurrence)` with the longer duration (one override + `rescheduled` event in planner-core). Linked checklist rows come from `checklistStepsProvider` (shared with the routine player). Keep-screen-on uses `wakelock_plus` behind `ScreenAwake`. Recovered from an unfinished agent branch and finished here.

### T3.7.02 — Backlog drawer & timeboxing
**Priority:** P1 · **Size:** L · **Depends on:** [3.1] (unscheduled tasks), [3.3] (gestures), [3.4]
**Description:** A drawer that slides from the trailing edge (right in LTR, left in RTL) in the week table,
day list and N-day views. It lists:
- unscheduled tasks;
- untimed/all-day tasks of the visible days;
- overdue items;
- unplaced quota slots ("Run · 1/3 this week");
- checklist items with due dates (once item scheduling exists, [3.1] P2).

It has filters and search. Drag behaviour:
- **Drawer → grid:** schedules the item at the drop slot, with duration = estimate or 30 min.
- **Grid → drawer:** unschedules a one-off timed task. Recurring occurrences refuse, with an explanatory toast.
**Acceptance criteria:** time-blocking a backlog task takes one drag; undo restores it; a `scheduled` /
`unscheduled` / `rescheduled` event is written (source `backlog`).
**Tests:** widget gesture tests; repository tests.

### T3.7.03 — Backlog list screen
**Priority:** P1 · **Size:** M · **Depends on:** [3.1] (unscheduled tasks)
**Description:** Full-screen backlog:
- create items; reorder them via the fractional `manual_sort_key`;
- edit estimate, priority, deadline and category;
- group by category, priority or deadline.

A bulk *Schedule on…* picks a day and places the selected items one after another into that day's free
slots, using the T3.7.04 algorithm.
**Tests:** widget tests; unit test for sequential placement (respects work hours, skips busy blocks).

### T3.7.04 — Free-slot finder & openings
**Priority:** P1 · **Size:** M · **Depends on:** [3.2], T3.7.02
**Description:** Computes free intervals inside work hours and work days (from settings) over the next N
days.
- `check`, `timer` and `event` items count as busy; an option ignores low-priority items.
- Results can be filtered by minimum gap.
- Shown as shading in the grids (overlay, [3.3]) and as an *Openings* list.
- Actions:
  - *Fill this gap*: choose a backlog item that fits;
  - *Create here*;
  - *Copy availability as text*, localized, e.g. "Mon 22 Sep: 10:00–11:30, 14:00–16:00", to the share sheet.
**Data model:** settings `planner.workDays` (arch §8.5).
**Acceptance criteria:** the availability text follows locale and 12/24 h; zero-length and sub-minimum
gaps are excluded; DST days produce correct intervals.
**Tests:** pure interval-algebra unit tests (merge busy blocks, subtract, clip to work hours, DST days).

### T3.7.05 — Table (spreadsheet) view
**Priority:** P1 · **Size:** M · **Depends on:** [3.2], [2.3] (filters)
**Description:** A database-style table like Notion or ClickUp.
- **Rows:** the occurrences in a date range, or tasks/series (toggle).
- **Columns:** title, date, start, end, duration, status, category, priority, tags, tracking mode,
  recurrence summary, actual duration, deadline.
- Sort by any column, filter, and group by day / category / status.
- A column chooser with resizable widths; header and first column pinned (`TableView`).
- Inline editing for title, time, status, category and priority.
**Acceptance criteria:** 2 000 rows scroll at 60 fps; inline edits go through the same repository and scope
logic as the editor.
**Tests:** widget tests; perf scenario.

### T3.7.06 — Plan-vs-actual view
**Priority:** P1 · **Size:** M · **Depends on:** [3.2] (time tracking), [3.3]
**Description:** A day or week grid where each day column splits into planned tiles and tracked time entries
side by side (Toggl-style). Variance is highlighted: started late, overran, not done, unplanned work.
Tapping an actual block edits its entries.
**Tests:** unit tests for variance classification; goldens.

### T3.7.07 — Routine player
**Priority:** P2 · **Size:** M · **Depends on:** T3.7.01, [4.3]
**Description:** Run a routine step by step, like Routinery or Tiimo.
- Steps come from the task's linked checklist, or from a sequence of consecutive tasks such as a
  "Morning block".
- Each step has its own timer, auto-advance, and a sound/haptic on step change.
- Steps can be paused or skipped.
- A summary at the end completes the items and marks the occurrence done.

Lock-screen / Live Activity support is in [8.2].
**Data model:** `checklist_items.estimate_minutes integer` for step durations. Without it, the task
duration is split equally across steps.
**Tests:** state-machine unit tests; widget tests.

### T3.7.08 — Kanban board
**Priority:** P2 · **Size:** M · **Depends on:** [3.2]
**Description:** A board for a date range, grouped by status (planned / in progress / done / skipped),
category, priority or day. Dragging a card between columns updates the matching field:
- status → occurrence action;
- category or priority → task update, following scope rules;
- day → reschedule.

Each column shows its item count.
**Data model:** view config `options.groupBy`.
**Tests:** widget tests.

### T3.7.09 — Eisenhower matrix
**Priority:** P2 · **Size:** S · **Depends on:** [3.1] (deadline)
**Description:** Four quadrants — Do, Schedule, Delegate, Eliminate — built from:
- **importance:** priority ≥ threshold;
- **urgency:** deadline or scheduled start within N days.

The rules are editable (TickTick-style) and backlog tasks are included. Dragging between quadrants adjusts
priority and/or deadline.
**Data model:** view config `options.importanceThreshold`, `options.urgencyDays`; `tasks.deadline_local`.
**Tests:** classification unit tests.

### T3.7.10 — 24-hour radial clock
**Priority:** P2 · **Size:** M · **Depends on:** [3.2]
**Description:** The day as a 24-hour (or 12-hour) dial, Sectograph-style:
- arcs per occurrence, colored by category; a *now* hand; free gaps visible;
- tap an arc → occurrence sheet;
- zoom range of 1–12 h around now.

A home-screen widget comes later ([8.2]).
**Tests:** geometry unit tests (arc angles incl. DST days); goldens.

### T3.7.11 — Horizons view
**Priority:** P2 · **Size:** M · **Depends on:** [3.1] (unscheduled tasks)
**Description:** Side-by-side columns of intention lists for Day, Week, Month, Quarter and Year
(Timestripe-style). Items are unscheduled tasks tagged with a horizon period. They can be dragged between
horizons or onto the calendar, and linked to goals ([5.4]).
**Data model:** `tasks.horizon_key text` (e.g. `week:2026-09-21`, `month:2026-09`, `year:2026`).
**Tests:** widget tests.

### T3.7.12 — Countdown / count-up list
**Priority:** P2 · **Size:** S · **Depends on:** [3.1], [5.3] (live counter engine)
**Description:** A pinned list of live counters in d/h/m, grouped:
- "N days until X" for an upcoming task or deadline;
- "N days since X" for a past event.

Reuses the quit tracker's counter engine (TickTick countdown style). A widget comes later ([8.2]).
**Data model:** `tasks.countdown_mode text check (countdown_mode in ('until','since'))` — the task
appears in the list when set.
**Tests:** unit tests for the counters, incl. DST transitions.

### T3.7.13 — Map view
**Priority:** P2 · **Size:** M · **Depends on:** [3.1]
**Description:** Tasks with coordinates appear as pins colored by category, filtered by date range
(e.g. `flutter_map` with OSM tiles, or platform maps). The editor gets a place picker with geocoding.
**Data model:** `tasks.location_lat double precision`, `tasks.location_lng double precision`.
The existing `location` stays as the display name.
**Tests:** widget tests with a fake map layer.

### T3.7.14 — Productivity views test suite
**Priority:** P1 · **Size:** S · **Depends on:** T3.7.05
**Description:** Goldens and interaction tests for each implemented view: focus, backlog drawer drag,
openings, table, plan-vs-actual, and the P2 views as they land. Covers light/dark, RTL and text scale 2.0.
**Tests:** as described.
