# Section 3.3 — Time-Grid Engine

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.3, 2.3, 3.1, 3.2
> Architecture: §6.9 (incl. *Grid rules (from research)*), §8.3 (view config), §9.1 (time), §9.6 (budgets)

## Goal

Build one reusable engine behind every time-based Planner view: week table, day list, N-day, work week and
ribbon. It provides:
- a time scale with slots from **1 minute to 24 hours**;
- pure layout algorithms and cheap painters;
- two renderers: proportional *timeline* and bucketed *table*, which becomes the *week list* at 24-hour slots;
- infinite paging, gestures, zoom, the all-day lane, overlays and accessibility.

It must stay smooth with 1-minute slots and thousands of tiles.

## Scope

**In:**
- Model: view-config model and persistence; local view state.
- Pure layout: slot math; DST-aware day model; overlap layout (lane cap, "+N"); bucketing.
- Rendering: grid painter, ruler, day header, tile widget and status styling, timeline and table renderers.
- Navigation and data: horizontal paging; visible-range data provider.
- Interaction: create / move / resize gestures; snapping, time bubble and haptics; all-day lane and drags
  between it and the grid; auto-scroll and auto-page; zoom.
- Display options, overlays framework, accessibility, performance harness, cascade style, secondary zones.

**Out:** screens composing the engine ([3.4], [3.5], [3.6], [3.7]); occurrence logic ([3.2]);
backlog drawer UI and drags to/from it ([3.7]).

## Progress

- [x] T3.3.01 — View config model & saved-view persistence
- [x] T3.3.02 — Local view state (anchor date, scroll, zoom)
- [x] T3.3.03 — Time scale & slot math
- [x] T3.3.04 — DST-aware day timeline model
- [x] T3.3.05 — Overlap layout algorithm (lanes, cap, "+N")
- [x] T3.3.06 — Bucketing algorithm (table mode)
- [x] T3.3.07 — Grid painter
- [x] T3.3.08 — Time ruler
- [x] T3.3.09 — Day header row
- [x] T3.3.10 — Task tile widget & status styling
- [x] T3.3.11 — Timeline renderer (proportional, culled)
- [x] T3.3.12 — Table renderer (bucketed) & week-list mode
- [x] T3.3.13 — Horizontal paging infrastructure
- [x] T3.3.14 — Visible-range occurrence provider
- [x] T3.3.15 — Create gestures
- [x] T3.3.16 — Move & resize gestures
- [x] T3.3.17 — Snapping, time bubble & haptics
- [x] T3.3.18 — All-day & multi-day lane
- [x] T3.3.19 — Drag between grid and all-day lane
- [x] T3.3.20 — Auto-scroll & auto-page while dragging
- [x] T3.3.21 — Zoom: vertical pinch, semantic zoom, horizontal pinch
- [x] T3.3.22 — Display options (color-by, density, dim past, completed/cancelled, filters)
- [x] T3.3.23 — Overlays framework
- [x] T3.3.24 — Accessibility: semantics, list fallback, keyboard
- [x] T3.3.25 — Performance harness & optimization
- [ ] T3.3.26 — Cascade overlap style & secondary time-zone rulers

## Tasks

### T3.3.01 — View config model & saved-view persistence
**Priority:** P0 · **Size:** M · **Depends on:** [2.3] (saved views, filter model)
**Description:** freezed `PlannerViewConfig` implementing arch §8.3 v1 for all view types.
- Per-type defaults, validation and a JSON upgrade path.
- Persisted in `saved_views` (section `planner`).
- First run creates one default saved view per MVP type. The Planner default is the Week table: 7 days,
  30-minute slots.
**Implementation notes:**
- Validation ranges:
  - `slotMinutes` integer 1–1440; `slotExtentPx` 8–400; `snapMinutes` 1–60 (default `min(slotMinutes, 15)`);
  - `daysVisible` 1–14; `dayWindow.start < end` (minute precision).
- Unknown keys are preserved. Invalid values clamp and log a warning.
- Type-specific settings live in an `options` map (see data dependency).
**Data model:** arch §8.3 keys:
- `options` (type-specific map: month mode, heat metric, groupBy, scale, lanes, matrix thresholds, min gap…);
- `daysVisibleLandscape`, `laneCap`, `overlapStyle` (`columns` | `cascade`);
- `dimPast`, `showWeekNumbers`, `extraTimeZones` (≤ 3), `autoScrollToNow`, `maxChipsPerCell`.
**Acceptance criteria:** configs round-trip losslessly; an older-version fixture upgrades; out-of-range
values clamp.
**Tests:** unit tests (defaults per type, validation, upgrade, unknown-key preservation).
**Notes:** Hand-written immutable `PlannerViewConfig` (ADR-016, no freezed) with defaults for every view type of arch §8.3; built-in views are stored as deterministic `saved_views` rows (`entryViewId`).

### T3.3.02 — Local view state (anchor date, scroll, zoom)
**Priority:** P0 · **Size:** S · **Depends on:** T3.3.01
**Description:** Per-view transient state kept only on the device:
- anchor date;
- vertical position stored as *minute-of-day* (not pixels, so it survives zoom changes);
- current px/min;
- days visible per orientation.
**Data model:** local-only Drift table `ui_view_state (view_id, json, updated_at)`, not synced — add it
to arch §6.5 local tables.
**Acceptance criteria:** after an app restart the view reopens on the same week and time; a zoom change
keeps the time at the viewport centre.
**Tests:** unit tests for offset ↔ minute conversion and persistence.

### T3.3.03 — Time scale & slot math
**Priority:** P0 · **Size:** S · **Depends on:** T3.3.01
**Description:** Pure `TimeScale` utilities:
- slots/day = `ceil(1440 / slot)`. Slots start at midnight; when the size doesn't divide 24 h, the last
  slot is cut short.
- slot index ↔ minute; minute ↔ px; px/min clamps.
- Label cadence: label every *k* slots so labels are ≥ 24 px apart, aligned to hours when slot < 60.
- Line hierarchy: hour lines strong; quarter-hour lines faint; slot lines only when ≥ 6 px apart; minute
  lines only when ≥ 4 px apart.
**Acceptance criteria:**
- 7 min → 206 slots, the last one 5 min; 45 min → 32 slots.
- 1 min → 1 440 slots; 1 440 min → 1 slot.
**Tests:** table-driven tests for all presets plus custom sizes 7, 13, 25, 50, 70, 100, 250, 500, 700, 1000.

### T3.3.04 — DST-aware day timeline model
**Priority:** P0 · **Size:** M · **Depends on:** T3.3.03, [2.3] (time utilities)
**Description:** `DayTimeline.build(date, zone)` returns ordered wall-clock segments with their UTC offsets,
so rows follow wall-clock time:
- A 25-hour day shows the repeated hour twice; the second copy is labelled with its offset, e.g.
  "02:00 (+01:00)".
- A 23-hour day omits the missing hour and shows a thin "clocks forward" marker.

It maps instant ↔ y and wall-clock minute ↔ y, and generates slot grids per segment.
**Acceptance criteria:**
- Correct rows for Europe/Paris 2026-03-29 (23 h) and 2026-10-25 (25 h), America/New_York, and
  Australia/Lord_Howe (30-min shift).
- A floating task at 02:30 on a gap day follows the engine's shift rule.
**Tests:** multi-zone unit tests; goldens of both Paris DST days.
**Notes:** The Paris DST goldens are the week-table and day-list DST goldens (`week_table_goldens_test.dart`, `day_list_goldens_test.dart`).

### T3.3.05 — Overlap layout algorithm (lanes, cap, "+N")
**Priority:** P0 · **Size:** M · **Depends on:** T3.3.03
**Description:** Pure `layoutDay(items, laneCap) → (List<TileRect>, List<OverflowGroup>)`:
1. Sort by start ascending; for equal starts, longer items first.
2. Build clusters of transitively overlapping items.
3. Assign columns greedily; a column is free again once its item ends.
4. Width = 1 / column count of the cluster; each tile expands right into free adjacent columns.
5. When a cluster needs more than `laneCap` columns (phone week default 2; day view and tablets 4+),
   the extra items collapse into a "+N" group anchored to the time range they cover.
6. Minimum rendered height is 18 px (compact label).
**Acceptance criteria:** property tests over 10 000 random days hold:
- placed tiles never overlap;
- widths are ≤ 1;
- output is deterministic;
- every item is either placed or in exactly one overflow group.
**Tests:** fixture and property tests.

### T3.3.06 — Bucketing algorithm (table mode)
**Priority:** P0 · **Size:** M · **Depends on:** T3.3.03
**Description:** Pure `bucketDay(items, slotMinutes)`:
- Each item is listed in every slot it overlaps. The first slot gets a full chip ("09:15 Gym"); later
  slots get a continuation marker.
- Chips are ordered by start, then priority.
- Row heights are either fixed (with "+N" when chips exceed capacity) or auto-fit: the maximum chip count
  across visible days for that row, capped at `maxChipsPerCell` before switching to "+N".
**Acceptance criteria:** with 120-min slots, a 09:15–11:30 task is a chip in 08:00–10:00 and a
continuation in 10:00–12:00; items crossing midnight continue on the next day's first row.
**Tests:** unit tests incl. midnight-crossing items and the all-day exclusion.

### T3.3.07 — Grid painter
**Priority:** P0 · **Size:** M · **Depends on:** T3.3.03, T3.3.04, [1.3] (tokens)
**Description:** One `CustomPainter` per page draws:
- slot lines following the hierarchy;
- weekend shading, off-hours shading (settings work hours) and today's column tint;
- hidden-hours bands (with badge counts supplied by the view) and DST markers.

A separate lightweight layer draws the **now line**: a red line with a dot on today, faint across other
days. A per-minute ticker updates it and pauses while the page is off-screen.
**Acceptance criteria:** repaints happen only on scale or date change; the now layer repaints once a
minute; RTL mirrors column order.
**Tests:** goldens (slots 1, 5, 30, 120 min × light/dark × LTR/RTL).
**Notes:** Painter goldens come from the week-table suite (1, 5, 30, 120, 1 440 min × light LTR / dark RTL, plus dark LTR and light RTL at 30 min).

### T3.3.08 — Time ruler
**Priority:** P0 · **Size:** S · **Depends on:** T3.3.03
**Description:** Pinned ruler column:
- labels per cadence, locale-aware 12/24 h, digit shaping per locale;
- current time highlighted;
- double-tap opens the slot-size sheet ([3.4]);
- placed on the right in RTL.
**Acceptance criteria:** labels never overlap at any zoom; 1-min slots show hour and quarter labels only.
**Tests:** unit tests for cadence; goldens.

### T3.3.09 — Day header row
**Priority:** P0 · **Size:** S · **Depends on:** T3.3.07
**Description:** Pinned header cells showing:
- weekday and localized date; today highlight; month-change marker; optional ISO week number;
- a slot for per-day stats / load tint supplied by the host view ([3.4]).

Tap → Day list for that date. Long-press → day menu (add task, skip remaining, move unfinished to tomorrow).
**Tests:** widget tests; golden.
**Notes:** Long-press opens the day menu with planner-core's one-operation day actions (`runDayAction`, T3.2.23); golden via the week-table suite.

### T3.3.10 — Task tile widget & status styling
**Priority:** P0 · **Size:** M · **Depends on:** T3.3.05, [3.2]
**Description:** Tile variants picked by available size:
- **full:** title, time range, and icons for recurrence, fixed zone, linked-checklist progress, attachments;
- **compact:** title only;
- **chip:** time + title;
- **minimal:** color bar.

Status styling:
- done: check + strikethrough + faded;
- skipped: grey hatched;
- missed: red leading edge;
- in progress: animated border (static if reduce-motion);
- cancelled: hidden unless `showCancelled`;
- past items dimmed when `dimPast`.

Color comes from category, priority, status or the task. `check` tiles have a tick-in-grid hit area
(≥ 48 dp via expanded hit testing).
**Acceptance criteria:** tile text contrast ≥ 4.5:1 on every palette color in light and dark; text never
overflows.
**Tests:** goldens for all variants × statuses; semantics-label tests.

### T3.3.11 — Timeline renderer (proportional, culled)
**Priority:** P0 · **Size:** L · **Depends on:** T3.3.05, T3.3.07, T3.3.10
**Description:** Renders one page (N day columns) as a vertically scrollable surface: painter layers plus
positioned tiles for the visible window ± one viewport only, and "+N" overflow chips.
- Works at any px/min.
- The tile layer sits in a `RepaintBoundary`.
- Tiles rebuild only when the visible window crosses a buffer boundary or the data changes.
**Acceptance criteria:** 1-min slots with 2 000 occurrences in a week stay at 60 fps while scrolling in
profile mode on the reference device (T3.3.25).
**Tests:** widget tests for culling correctness; perf scenario.
**Notes:** Culling is checked by `planner_perf_test.dart` (built tiles stay bounded at 1-min slots with 2 000 items); the profile-mode frame budget itself is measured by the `flutter drive --profile` suite of T9.1.08.

### T3.3.12 — Table renderer (bucketed) & week-list mode
**Priority:** P0 · **Size:** L · **Depends on:** T3.3.06, T3.3.10
**Description:** `TableView` (`two_dimensional_scrollables`):
- pinned header row and ruler column; rows = slots, columns = days;
- lazily built cells with chips, continuation markers and "+N" (opens a popover list for that cell, or the
  Day list at that time);
- fixed or auto-fit row heights.

**Week-list mode** kicks in at `slotMinutes = 1440`: one tall cell per day holding an ordered list of chips
(all-day first, timed by start, untimed by manual order). Dragging a chip to another day changes the date
and keeps the time.
**Acceptance criteria:** 2-hour slots show chips with start times; 24-hour slots show the week as seven
lists; 1-min table mode (1 440 rows) scrolls at 60 fps.
**Tests:** widget tests; goldens (120 min, 1 440 min, RTL).

### T3.3.13 — Horizontal paging infrastructure
**Priority:** P0 · **Size:** M · **Depends on:** T3.3.02
**Description:** `PlannerPager` on `PageView.builder` with a virtual index (±10 000 pages around the anchor).
Paging modes:
- `week`: a page is a week starting on the configured week start (any weekday);
- `day`: an N-day window that steps one day;
- `free`: continuous horizontal scroll snapping to day boundaries.

Also:
- pure, tested date ↔ page mapping;
- one vertical scroll shared by all pages and the ruler, so the time position survives page changes;
- ±1 page preloaded;
- RTL mirroring (swipe direction follows reading direction);
- animated programmatic jumps.
**Acceptance criteria:** swiping 52 weeks forward and back returns to the exact week and time; a Saturday
week start works; the DST week and the year boundary map correctly.
**Tests:** mapping unit tests (all week starts, DST weeks, year boundaries); widget tests for the linked scroll.

### T3.3.14 — Visible-range occurrence provider
**Priority:** P0 · **Size:** S · **Depends on:** T3.3.13, [3.2] (range service)
**Description:** Riverpod provider family keyed by (view id, page range). It subscribes to
`OccurrenceRangeService` for the visible page ± 1, exposes laid-out data per day (timeline layout or
buckets), and disposes off-screen pages.
**Acceptance criteria:** paging back to a cached neighbour week doesn't re-resolve it; editing one task
re-lays out only the affected days.
**Tests:** provider tests with a fake service.

### T3.3.15 — Create gestures
**Priority:** P0 · **Size:** M · **Depends on:** T3.3.11, T3.3.12, [3.1] (quick create)
**Description:**
- **Tap an empty slot** → quick-create prefilled with the slot start and the duration rule of [3.1]
  (quick-create task). In week-list mode this creates an untimed task for that day.
- **Long-press empty space, then drag** → a placeholder block follows the finger (snapped); release opens
  quick-create with the selected range. Dragging back to the origin or pressing back cancels.
**Acceptance criteria:** creating 07:00–08:30 on a 30-min grid takes one gesture plus the title.
**Tests:** widget gesture tests (tap, long-press-drag, cancel).

### T3.3.16 — Move & resize gestures
**Priority:** P0 · **Size:** L · **Depends on:** T3.3.15, [3.2] (scopes, reschedule)
**Description:**
- **Move:** long-press a tile to lift it (elevation + `mediumImpact`), then drag vertically to change the
  time and horizontally to change the day.
- **Resize:** a selected tile shows top/bottom handles with enlarged touch areas. Resizing keeps the other
  edge fixed; minimum duration = snap size (≥ 1 min); crossing midnight is allowed.
- **Commit:** release goes through the reschedule operation, with the scope dialog for recurring tasks.
  Each commit is one undo command.
- Done items can be moved only after a confirmation, to keep history honest.
- Releasing a long-press without moving opens the tile quick menu instead ([3.4]).
**Acceptance criteria:** moving one occurrence to 10:15 the next day writes one override and one
`rescheduled` event; undo restores it.
**Tests:** widget gesture tests; command and undo tests.

### T3.3.17 — Snapping, time bubble & haptics
**Priority:** P0 · **Size:** M · **Depends on:** T3.3.16
**Description:** A snap engine combining:
- grid snapping to `snapMinutes` (1–60, default `min(slotMinutes, 15)`);
- magnetic snapping to neighbouring tile edges and to *now* (within 8 px);
- free mode (second finger held, or snapping disabled in settings).

A floating bubble above the finger shows e.g. "Tue 09:15–10:00 · 45 min" in the viewer zone.
Haptics, respecting the haptics setting: `selectionClick` per snap step, `mediumImpact` on lift,
`successNotification` when a drop completes.
**Acceptance criteria:** dragging across a 1-min grid with snap 1 fires one haptic per step, throttled to
≤ 30 per second; the bubble text follows locale and 12/24 h.
**Tests:** pure snap-engine unit tests; widget test for the bubble text.

### T3.3.18 — All-day & multi-day lane
**Priority:** P0 · **Size:** M · **Depends on:** T3.3.13
**Description:** A lane pinned under the day header containing:
- all-day tasks, and multi-day tasks as bars spanning columns (greedy row packing);
- unplaced quota slots ("Run · 1/3"), and overlays when enabled.

It collapses to 2 rows + "+N". Timed tasks shorter than 24 h that cross midnight render as split tiles in
the grid; timed tasks of 24 h or more render as lane bars (setting).
**Acceptance criteria:** a 3-day trip renders as one bar across three columns and shows a continuation
arrow across page boundaries.
**Tests:** packing unit tests; goldens.

### T3.3.19 — Drag between grid and all-day lane
**Priority:** P0 · **Size:** S · **Depends on:** T3.3.16, T3.3.18
**Description:**
- Timed tile → lane: becomes all-day (time removed, duration 1 day).
- Lane item → grid: becomes timed, starting at the drop slot, with a default duration of 30 min.

Both directions reuse the scope dialog for recurring tasks and write `rescheduled` events. (Drags to and
from the backlog drawer are in [3.7].)
**Acceptance criteria:** both directions write the correct fields, are undoable, and are mirrored in RTL.
**Tests:** widget gesture tests; repository tests.

### T3.3.20 — Auto-scroll & auto-page while dragging
**Priority:** P0 · **Size:** S · **Depends on:** T3.3.16
**Description:** While creating, moving or resizing:
- scroll vertically when the finger is within 48 px of the top/bottom edge, with speed proportional to depth;
- turn to the previous/next page after a 400 ms dwell near the left/right edge (mirrored in RTL).

The drag survives page changes.
**Tests:** widget tests with simulated edge dwell.

### T3.3.21 — Zoom: vertical pinch, semantic zoom, horizontal pinch
**Priority:** P0 · **Size:** M · **Depends on:** T3.3.11, T3.3.12, T3.3.13
**Description:**
- **Vertical pinch** changes px/min continuously around the focal time (the time under the fingers stays
  put). It is clamped between "the whole day fits the viewport" and "one slot = half the viewport".
- **Semantic mode:** crossing thresholds switches `slotMinutes` along the presets
  1·5·10·15·20·30·45·60·90·120·180·240·360·480·720·1440, with a toast such as "15 min".
- **Horizontal pinch** changes visible days 1–7 (up to 14 on tablets), snapping to whole numbers.
- **Double-tap on the ruler** opens the slot-size sheet.

Zoom and days are persisted per view.
**Acceptance criteria:** in semantic mode, pinching from 30-min to 5-min granularity keeps 09:00 under the
fingers; fixed mode never changes `slotMinutes`.
**Tests:** widget tests with simulated scale gestures; unit tests of the threshold mapping.

### T3.3.22 — Display options (color-by, density, dim past, completed/cancelled, filters)
**Priority:** P0 · **Size:** S · **Depends on:** T3.3.10, T3.3.01
**Description:** View-level options consumed by the renderers:
- `colorBy` (category / priority / status / task);
- `density` (comfortable / compact: paddings and font steps);
- `dimPast`, `showCompleted`, `showCancelled`, `showWeekends`;
- filters (shared filter model, [2.3]), applied before layout.
**Tests:** filtering unit tests; density goldens.

### T3.3.23 — Overlays framework
**Priority:** P1 · **Size:** M · **Depends on:** T3.3.11, T3.3.18
**Description:** Pluggable overlay layers, each toggled via view config `overlays`:
- habits due at specific times: small markers, tap to check in ([5.2]);
- checklist items due: chips in the lane or at their due time ([4.3]);
- free-slot shading ([3.7]);
- slot-occupancy heat tint from stats ([6.3]);
- device calendars, later ([8.2]).
**Tests:** widget tests with fake overlay providers.
**Notes:** Layers (timeline renderer): `habits` = timed habit slots from `habitDayViewsProvider`, tap toggles the check-in (`checkInServiceProvider`); `checklistDue` = open checklist items due in the range, tap opens the list; `freeSlots` = openings of the T3.7.04 finder inside work hours; `heat` = weekday × hour occupancy of the four weeks before the page, aggregated from planner items (`OccupancyGrid`) rather than a stats [6.3] provider; `deviceCalendars` stays inert until [8.2]. Table / week-list modes draw no overlays.

### T3.3.24 — Accessibility: semantics, list fallback, keyboard
**Priority:** P1 · **Size:** M · **Depends on:** T3.3.11, T3.3.12
**Description:**
- **Semantics** for every tile and cell, e.g. "Gym, Monday 22 September, 07:00 to 08:00, not done, repeats
  weekly"; day headers; empty slots ("Monday 09:00, empty, double-tap to create").
- **List mode:** a linear agenda of the same range for screen-reader users.
- **Custom semantic actions:** mark done, move 15 min earlier/later, open.
- **Tablet keyboard:** arrows move the selection, Enter opens, Shift+arrows move the selected task by one
  snap step, +/- zoom.
**Acceptance criteria:** with TalkBack or VoiceOver, a user can create, open, complete and move a task
without any gesture.
**Tests:** semantics tests; guideline checks ([9.1]).
**Notes:** Tiles expose done / 15 min earlier / later / previous / next day / select actions; with accessible navigation on, empty slots become nodes (grouped to ≥ 24 px) whose tap quick-creates; the header long-press exposes the day menu (*Add task*). Keyboard on the grid: ↑/↓ select, ←/→ nearest item of the neighbour day (then page, mirrored in RTL), Enter opens, Space ticks, Shift+↑/↓ moves by the snap step, Shift+←/→ by a day, +/- zoom, Page Up/Down, Esc; Ctrl/Cmd+C/V copy / paste at the hovered or last tapped slot (planner-core `pasteAt`, T3.1.19). Selection mode (T3.1.18): tile menu *Select*, taps toggle, the toolbar becomes a selection bar opening `showBulkActionsSheet` (week table, N-day, work week, day list). Guideline checks remain part of [9.1].

### T3.3.25 — Performance harness & optimization
**Priority:** P1 · **Size:** M · **Depends on:** T3.3.11, T3.3.12, T3.3.21
**Description:** Profile-mode scenarios, recording frame build/raster times:
- a week at 1-min slots with 2 000 occurrences;
- 14 days on a tablet;
- table mode with 1 440 rows;
- 5 s of continuous pinch;
- paging through 20 weeks.

Optimizations:
- cached `TextPainter`s for labels;
- a `RepaintBoundary` per layer; const tiles;
- `ValueListenable` scroll/zoom, so nothing rebuilds per frame;
- no layout work inside paint.
**Acceptance criteria:** arch §9.6 budgets met; results stored as CI artifacts ([9.1]).
**Tests:** the perf scenarios.
**Notes:** `planner_perf_test.dart` runs all five scenarios (1-min week with 2 000 items, 14 tablet days, 1 440-row table, 5 s of pinch, 20-week paging) plus the 1 440-row day list, asserting culling bounds and a debug-mode frame ceiling. Optimizations in place: label caches (ruler, hidden-band badges), a RepaintBoundary per layer, ValueListenable now / drag state, whole-pixel page area. Profile-mode frame timings stored as CI artifacts belong to the T9.1.08 drive suite, which can reuse `perfWeek`.

### T3.3.26 — Cascade overlap style & secondary time-zone rulers
**Priority:** P2 · **Size:** M · **Depends on:** T3.3.05, T3.3.08
**Description:** An optional cascade overlap style for dense tablets: items partly overlap, widths ×1.7.
Up to 3 extra time-zone rulers (labels only) for travellers and remote work.
**Data model:** view config `overlapStyle`, `extraTimeZones` (see T3.3.01).
**Tests:** goldens.
