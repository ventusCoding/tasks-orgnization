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
- [x] T3.7.02 — Backlog drawer & timeboxing
- [x] T3.7.03 — Backlog list screen
- [x] T3.7.04 — Free-slot finder & openings
- [x] T3.7.05 — Table (spreadsheet) view
- [x] T3.7.06 — Plan-vs-actual view
- [x] T3.7.07 — Routine player
- [x] T3.7.08 — Kanban board
- [x] T3.7.09 — Eisenhower matrix
- [x] T3.7.10 — 24-hour radial clock
- [x] T3.7.11 — Horizons view
- [x] T3.7.12 — Countdown / count-up list
- [x] T3.7.13 — Map view
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
**Notes:** `BacklogDrawerHost` + `BacklogDrawerPanel` (`backlog_drawer.dart`), toggled by an inbox button in the week table / N-day / work week (`TimeGridView`) and day list toolbars (≥ 560 dp; the overflow menu on phones, where the toolbar is full). The drawer is a non-modal panel on the trailing edge (≤ 320 dp, 85 % on phones) so rows drag straight onto the grid. Sections: unscheduled, untimed / all-day of the visible days, overdue (last 7 days), unplaced quota slots ("Run · 1/3 this period"), checklist items with a due date that aren't scheduled yet; search and section chips filter. Drawer → grid: the host is a `DragTarget` that asks the view's `DropSlotSource` (`TimeGridState.dropSlotAt`, the day list page) for the slot — backlog tasks are scheduled (`scheduled`, source `backlog`) with estimate or 30 min, occurrences move (scope dialog for series), checklist items become a linked task. Grid → drawer: a tile released over the drawer (`TimeGrid.onDropOutside`, day list `onDropOutside`) unschedules a one-off task (`unscheduled`, source `backlog`); recurring occurrences and quota slots refuse with a toast. Every drop is one undoable command.

### T3.7.03 — Backlog list screen
**Priority:** P1 · **Size:** M · **Depends on:** [3.1] (unscheduled tasks)
**Description:** Full-screen backlog:
- create items; reorder them via the fractional `manual_sort_key`;
- edit estimate, priority, deadline and category;
- group by category, priority or deadline.

A bulk *Schedule on…* picks a day and places the selected items one after another into that day's free
slots, using the T3.7.04 algorithm.
**Tests:** widget tests; unit test for sequential placement (respects work hours, skips busy blocks).
**Notes:** `BacklogView`: quick add (`PlannerViewActions.createBacklog`), drag-handle reorder through the neighbours' `manual_sort_key`s (`reorder`), inline chips for estimate (`pickDuration`), priority, deadline (`pickDate`, 23:59) and category (`pickCategory`) via `editBacklog` (`BacklogEdit` applied to the task, source `backlog`); `options.groupBy` none / category / priority / deadline (`groupBacklog`, pure). Selecting items shows *Schedule on…*: the picked day's openings (work hours, from now when today, any picked day counts as a work day) receive the items in order (`scheduleOnDay` = `freeIntervals` + `placeSequentially`), as one undoable command; items that don't fit are reported.

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
**Notes:** Engine `engine/free_slots.dart` (merge / subtract / clip, min gap, DST via `elapsedMinutes`, `notBefore` so today's openings start at now, `availabilityText` with injected locale formats) feeds the grid shading overlay (`overlays.freeSlots`) and the new `FreeSlotsView` (Openings: next 1/3/7/14 days, minimum gap 15–90 min, *Ignore low-priority* = priority < 2 not busy). Each opening: *Fill this gap* (backlog items whose estimate fits → `scheduleBacklogItem` at the opening start) and *Create here* (quick create). *Share availability* sends "Wed 23 Sep: 09:30–11:00, 12:00–17:00" lines (locale day format, user 12/24 h) to the share sheet.

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
**Notes:** `PlannerTableView` on `two_dimensional_scrollables` `TableView` (header row and title column pinned, cells built lazily) with pure helpers in `engine/table_rows.dart` (columns, per-column comparators with ties by start, one-row-per-series mode, grouping lines). Options: `rows` occurrences | tasks, `rangeDays`, `columns` (chooser sheet; title always shown), `columnWidths` (drag the header's trailing handle; saved on release), `sortBy` / `sortAsc` (tap a header; again = reverse), `groupBy` none / day / category / status. Inline edits: date (`pickDate`), start (`pickTime`) and status go through `PlannerCommands` (reschedule with the scope dialog / setStatus); title (long-press the title cell — a tap opens the task), category and priority use `PlannerViewActions.editFields`, which updates the task with the editor's scope logic (`updateTask(scope, occurrenceKey)`, source `inline`). Recurrence column shows Recurring / One-off. Perf scenario: 2 000 rows (`perfWeek`) stay under 800 built text cells while scrolling; frame budgets are measured by the T9.1.08 drive suite.

### T3.7.06 — Plan-vs-actual view
**Priority:** P1 · **Size:** M · **Depends on:** [3.2] (time tracking), [3.3]
**Description:** A day or week grid where each day column splits into planned tiles and tracked time entries
side by side (Toggl-style). Variance is highlighted: started late, overran, not done, unplanned work.
Tapping an actual block edits its entries.
**Tests:** unit tests for variance classification; goldens.
**Notes:** `PlanVsActualView` (`options.scope` day | week): each day column splits into Plan (occurrences) and Actual (time entries of the range, `rangeTimeEntriesProvider` → `watchEntriesBetween`, running entries end at now) on a 1 px/min timeline. Pure `engine/plan_actual.dart`: `blocksOf` (entries of an occurrence; key-less entries belong to one-off tasks), `unplannedBlocks`, `classifyVariance` (started late / overran by > 5 min, not done = end passed with nothing tracked and still open). Flagged plans get a warning (danger for not done) border and the variance text; unplanned blocks are tinted. Tapping a block opens its occurrence sheet (entries are edited there) or, for unplanned work, the task. Golden in the productivity suite (T3.7.14).

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
**Notes:** `RoutineView` with the pure `engine/routine.dart` (`stepDurations`, `consecutiveBlock` — back-to-back items within 5 min, overlaps skipped — and `RoutineMachine`: start / tick / pause / resume / complete / skip, auto-advance carries leftover time, finished = summary). Sources: today's open tasks with a linked checklist (steps = open top-level items via `checklistStepsProvider`, durations from `checklist_items.estimate_minutes` — schema v2, editable as *Step duration* in the item sheet — else an equal share of the task) or blocks of ≥ 2 consecutive tasks. The clock drives a 1 s ticker (fake clock in tests); step changes play a haptic (honours the setting) and the system alert sound; the screen stays on while playing (`ScreenAwake`). *Finish*: checklist routines complete the done items in one operation and mark the occurrence done; blocks mark each step's occurrence done or skipped. Lock-screen / Live Activity stays in [8.2].

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
**Notes:** `KanbanView`: occurrences of `options.rangeDays` (default 7) in columns by `options.groupBy` — status (Planned incl. missed / In progress / Done / Skipped), category (category order, then none), priority (urgent first) or day — with counts in the headers. Long-press-drag a card onto another column: status → `setStatus`; category / priority → `PlannerViewActions.editFields` after the scope dialog; day → `reschedule` keeping the time. Unplaced quota markers are left out.

### T3.7.09 — Eisenhower matrix
**Priority:** P2 · **Size:** S · **Depends on:** [3.1] (deadline)
**Description:** Four quadrants — Do, Schedule, Delegate, Eliminate — built from:
- **importance:** priority ≥ threshold;
- **urgency:** deadline or scheduled start within N days.

The rules are editable (TickTick-style) and backlog tasks are included. Dragging between quadrants adjusts
priority and/or deadline.
**Data model:** view config `options.importanceThreshold`, `options.urgencyDays`; `tasks.deadline_local`.
**Tests:** classification unit tests.
**Notes:** `MatrixView` + pure `engine/eisenhower.dart` (`quadrantOf`: important = priority ≥ threshold; urgent = deadline within N days or overdue, or a scheduled start within N days; `matrixMove`). Items: open occurrences of the next 14 days (next one per series) plus the filtered backlog. Rules sheet (sliders) edits `importanceThreshold` / `urgencyDays`. Dragging a card into another quadrant raises / lowers the priority around the threshold and sets the deadline to the end of the urgency window (urgent) or clears it (not urgent) — `editBacklog` for backlog tasks, `editFields` with the scope dialog for scheduled ones.

### T3.7.10 — 24-hour radial clock
**Priority:** P2 · **Size:** M · **Depends on:** [3.2]
**Description:** The day as a 24-hour (or 12-hour) dial, Sectograph-style:
- arcs per occurrence, colored by category; a *now* hand; free gaps visible;
- tap an arc → occurrence sheet;
- zoom range of 1–12 h around now.

A home-screen widget comes later ([8.2]).
**Tests:** geometry unit tests (arc angles incl. DST days); goldens.
**Notes:** `RadialView` on pure `engine/radial_geometry.dart`: angles live on the day's elapsed-minute axis (`DayTimeline`, so a 23 h / 25 h DST day spans the whole dial), 12 o'clock at the top, clockwise; `dialWindow` = whole day (`options.hours` 24), the half day containing now (12) or `options.zoomHours` 1–12 centered on now; `arcOf` clips; `tAtAngle` hit-tests taps. Overlapping items move to up to two inner rings; free time is the bare track; done / skipped arcs are faded; a now hand and the current / next item in the center. Tap an arc → occurrence sheet. Golden in the productivity suite (T3.7.14).

### T3.7.11 — Horizons view
**Priority:** P2 · **Size:** M · **Depends on:** [3.1] (unscheduled tasks)
**Description:** Side-by-side columns of intention lists for Day, Week, Month, Quarter and Year
(Timestripe-style). Items are unscheduled tasks tagged with a horizon period. They can be dragged between
horizons or onto the calendar, and linked to goals ([5.4]).
**Data model:** `tasks.horizon_key text` (e.g. `week:2026-09-21`, `month:2026-09`, `year:2026`).
**Tests:** widget tests.
**Notes:** `HorizonsView` on `tasks.horizon_key` (schema v2; keys from the pure `Horizon.keyFor` in `domain/horizons.dart` — `day:`, `week:` (first day of the week), `month:`, `quarter:YYYY-Qn`, `year:`; server check constraint validates the format). Columns list unscheduled tasks with a key of that horizon (past periods flagged as carried over); each column adds an intention in its current period. Drag a card to another column → that horizon's current period; drop it on a day of this week → scheduled into the day's first free slot (work hours) and removed from the horizons, in one operation (`HorizonActions`, planner application). *Make it a goal* creates a series goal (complete once in the horizon's period, [5.4]); linked cards show a flag.

### T3.7.12 — Countdown / count-up list
**Priority:** P2 · **Size:** S · **Depends on:** [3.1], [5.3] (live counter engine)
**Description:** A pinned list of live counters in d/h/m, grouped:
- "N days until X" for an upcoming task or deadline;
- "N days since X" for a past event.

Reuses the quit tracker's counter engine (TickTick countdown style). A widget comes later ([8.2]).
**Data model:** `tasks.countdown_mode text check (countdown_mode in ('until','since'))` — the task
appears in the list when set.
**Tests:** unit tests for the counters, incl. DST transitions.
**Notes:** `CountdownView` over `countdownEntriesProvider` (`application/view_config/countdowns.dart`: `watchCountdownTasks` + `countdownTarget` — until = deadline, else the next occurrence / one-off start; since = the last occurrence before now / one-off start; unscheduled without a deadline is skipped). Rows show calendar days ("in 10 days" / "10 days ago", `LocalDate` arithmetic so DST days stay whole) and a live d · h · m counter from the quit tracker's `counterParts` on the shared one-second ticker (instant arithmetic: a DST weekend counts its real 47 h). Groups: Pinned (`options.pinned`), Upcoming, Since. *Add a countdown* picks a task (upcoming or backlog) and the mode; the row menu pins or removes it (`countdown_mode` cleared, one undoable update).

### T3.7.13 — Map view
**Priority:** P2 · **Size:** M · **Depends on:** [3.1]
**Description:** Tasks with coordinates appear as pins colored by category, filtered by date range
(e.g. `flutter_map` with OSM tiles, or platform maps). The editor gets a place picker with geocoding.
**Data model:** `tasks.location_lat double precision`, `tasks.location_lng double precision`.
The existing `location` stays as the display name.
**Tests:** widget tests with a fake map layer.
**Notes:** `tasks.location_lat` / `location_lng` (schema v2, both-or-none check). `MapView`: occurrences of `options.rangeDays` whose task has coordinates (`placeTasksProvider` → `watchPlaceTasks`), pins colored like the tiles, tap → item card, list below (long-press opens the task); without places an empty state explains the place picker. The editor's location field gets *Find a place* (`pickPlace`: geocoder search or tap the map to drop a pin named by reverse geocoding; the text stays the display name) and *Remove the map pin*; `TaskForm.coordinates` carries it (diff `place`). `flutter_map` + OSM tiles and the platform geocoder sit behind `mapLayerBuilderProvider` / `PlaceGeocoder` (fakes in tests).

### T3.7.14 — Productivity views test suite
**Priority:** P1 · **Size:** S · **Depends on:** T3.7.05
**Description:** Goldens and interaction tests for each implemented view: focus, backlog drawer drag,
openings, table, plan-vs-actual, and the P2 views as they land. Covers light/dark, RTL and text scale 2.0.
**Tests:** as described.
