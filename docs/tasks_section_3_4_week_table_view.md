# Section 3.4 — Week Table View (default Planner view)

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 3.1, 3.2, 3.3
> Architecture: §6.9, §8.3, §9.1, §9.6

## Goal

Deliver the default Planner view exactly as the user described it. It is a table where each of the 7
weekdays is a column and all 24 hours run down the rows. Rows are **30 minutes** by default, and the slot
size can be changed to 5 min, 1 h, 2 h or any custom value from **1 minute to 24 hours**. Scrolling
sideways changes the week. On top of that, the view needs everything that makes planning in it comfortable.

## Scope

**In:**
- Screen and defaults: screen composition; 7-day × 30-min defaults; week paging with any week start;
  jump-to-date and Today.
- Slot size and layout: slot-size control; render mode per slot size; 24-h week-list mode; days visible
  and orientation; visible hours.
- Toolbar and headers: filter / color-by toolbar; day header stats and load tint.
- Interaction: tick-in-grid and tile menu; create / move / resize integration; "+N" overflow.
- Correctness and polish: DST and time-zone correctness; landscape and tablet layouts; week summary;
  first-use hints; week numbers and secondary zones; test suite.

**Out:** engine internals ([3.3]); other views ([3.5]–[3.7]); stats screens ([6.3]).

## Progress

- [x] T3.4.01 — Week table screen composition
- [x] T3.4.02 — Default configuration (7 days × 30-minute rows × 24 hours)
- [x] T3.4.03 — Week paging & configurable week start
- [x] T3.4.04 — Jump to date, mini-month & Today
- [x] T3.4.05 — Slot-size control (presets + custom 1–1440 min)
- [x] T3.4.06 — Render modes by slot size
- [x] T3.4.07 — 24-hour slots: week-list mode
- [x] T3.4.08 — Days visible, weekends & orientation
- [x] T3.4.09 — Visible hours & hidden-range badges
- [x] T3.4.10 — Filter, color-by & density toolbar
- [x] T3.4.11 — Day header stats & load tint
- [x] T3.4.12 — Tick-in-grid & tile quick menu
- [x] T3.4.13 — Create / move / resize integration
- [x] T3.4.14 — Crowded slots: "+N" overflow handling
- [x] T3.4.15 — DST & time-zone correctness
- [x] T3.4.16 — Landscape & tablet layout
- [x] T3.4.17 — Week summary footer
- [x] T3.4.18 — First-use hints & empty week
- [x] T3.4.19 — Week numbers & secondary time zones
- [x] T3.4.20 — Week table test suite

## Tasks

### T3.4.01 — Week table screen composition
**Priority:** P0 · **Size:** M · **Depends on:** [3.3]
**Description:** `WeekTableScreen`, the Plan tab's default view.
- **Top bar:**
  - month/year title (tap → mini-month), Today, previous/next week buttons (accessibility, keyboards);
  - view switcher ([3.6]);
  - slot-size button showing the current size (e.g. "30 min");
  - filter button; overflow menu (view settings, save view…).
- **Body:** pinned day header row, all-day lane, then the grid (ruler + day columns).
- A contextual **+** FAB.
**Acceptance criteria:** with cached data the view appears within 100 ms of switching tabs; scroll
position and week survive tab switches (StatefulShellRoute).
**Tests:** widget tests; golden.

### T3.4.02 — Default configuration (7 days × 30-minute rows × 24 hours)
**Priority:** P0 · **Size:** S · **Depends on:** T3.4.01
**Description:** The default saved view created on first run:
- 7 days, week start from the profile;
- `slotMinutes` 30, row height 48 px, zoom mode *fixed*;
- render mode *auto* (table from 120 min), snap 15 min;
- day window 00:00–24:00, paging *week*.

On open, the grid scrolls so the current time (or 1 h before the day's first task) sits in the upper third.
**Acceptance criteria:** a fresh install shows the whole current week, 48 half-hour rows per day, scrolled
to now.
**Tests:** unit test of the defaults; widget test of the initial scroll.

### T3.4.03 — Week paging & configurable week start
**Priority:** P0 · **Size:** S · **Depends on:** T3.4.01
**Description:** Swiping horizontally goes to the previous/next week at the same time of day. A setting
chooses the paging mode: *week* (default), *step one day*, or *free scroll*. The week starts on the
profile's day (Mon, Sat, Sun or any weekday), and the header shows the range, e.g. "22–28 Sep 2026".
**Acceptance criteria:** with a Saturday week start, the grid, header, jump-to-date and stats links all
use Sat–Fri weeks.
**Tests:** widget tests for all paging modes; unit tests for week ranges.

### T3.4.04 — Jump to date, mini-month & Today
**Priority:** P0 · **Size:** S · **Depends on:** T3.4.03
**Description:**
- Tapping the title opens a mini-month: swipeable months, load dots per day, tap a week row to jump there.
- *Today* animates to the current week and time.
- Long-pressing *Today* opens a year/month/day picker for far jumps.
**Tests:** widget tests.

### T3.4.05 — Slot-size control (presets + custom 1–1440 min)
**Priority:** P0 · **Size:** M · **Depends on:** T3.4.01, [3.3] (view config, zoom)
**Description:** A slot-size sheet, also opened by double-tapping the ruler, with:
- **Preset chips:** 1, 5, 10, 15, 20, 30, 45 min; 1, 1.5, 2, 3, 4, 6, 8, 12, 24 h.
- **Custom:** any integer 1–1440 minutes, typed as minutes or h + min, validated, with a live preview of
  rows per day.
- **Row height** slider.
- **Zoom mode** (fixed / semantic), **render mode** (auto / timeline / table) and table threshold,
  **snap minutes**.
- *Apply to this view*. *Save as new view* appears once saved-views management ships ([3.6]).
**Acceptance criteria:**
- Custom 7 min → 206 rows per day, the last one 5 min.
- 24 h switches to week-list mode.
- 0, 1 441 and non-numbers are rejected with a message.
- The choice persists and syncs to other devices through the saved view.
**Tests:** widget tests for presets and custom validation; persistence test.

### T3.4.06 — Render modes by slot size
**Priority:** P0 · **Size:** S · **Depends on:** T3.4.05, [3.3] (timeline & table renderers)
**Description:** In *auto*, slots below the threshold (default 120 min) use the proportional timeline and
slots at or above it use the bucketed table. The user can force either mode. Switching keeps the time position.
**Acceptance criteria:** 30 min shows proportional tiles; 2 h shows per-cell chips with start times; a
forced timeline at 2 h still renders scaled tiles.
**Tests:** widget tests at 30/60/120/240 min.

### T3.4.07 — 24-hour slots: week-list mode
**Priority:** P0 · **Size:** S · **Depends on:** T3.4.06, [3.3] (table renderer)
**Description:** With 1 440-minute slots the week becomes seven day lists: all-day items first, then timed
items by start, then untimed items by manual order. Each chip shows time, title and status. There is no
time axis.
- Drag between days changes the date and keeps the time.
- Untimed items can be reordered within a day.
- Tapping a day header opens the Day list.
**Acceptance criteria:** behaves like a paper week planner; reordering persists via the manual order key.
**Tests:** widget tests; golden.

### T3.4.08 — Days visible, weekends & orientation
**Priority:** P0 · **Size:** S · **Depends on:** T3.4.03, [3.3] (zoom)
**Description:**
- Horizontal pinch or a setting shows 1–7 days (up to 14 on tablets).
- *Hide weekends* gives a 5-day week; custom work days are also supported.
- An optional mode "3 days in portrait, 7 in landscape". The default stays **7 in both orientations**, per
  the user's preference.
**Data model:** view config `daysVisibleLandscape` ([3.3], view config model).
**Tests:** widget tests; unit tests for day ranges with hidden weekends.

### T3.4.09 — Visible hours & hidden-range badges
**Priority:** P1 · **Size:** S · **Depends on:** T3.4.01
**Description:** A day-window setting (e.g. 06:00–24:00, 5-minute precision). Hidden ranges shrink to a thin
band; if items fall inside, the band shows a badge like "2". Tapping the band expands it temporarily.
The default is all 24 hours.
**Tests:** widget tests; unit test for badge counts.
**Notes:** Items entirely inside hidden hours are no longer laid out as tiles; they only count in the band badge, and tapping the band expands it (widget test in `time_grid_test.dart`, badge counts from `PageGeometry.hiddenCounts`).

### T3.4.10 — Filter, color-by & density toolbar
**Priority:** P1 · **Size:** M · **Depends on:** T3.4.01, [2.3] (filter model)
**Description:**
- Filter sheet: categories, tags, priorities, statuses, tracking modes, text.
- An active-filter chip row with *Clear*.
- Color-by menu: category / priority / status / task.
- Density toggle; *show completed*, *show cancelled* and *dim past* switches.

All of this is persisted in the view config.
**Tests:** widget tests.
**Notes:** Filter sheet (categories, tags, priorities, statuses, tracking modes, text), active-filter chips with *Clear*, color-by / density / completed / cancelled / dim-past in view settings; all persisted in the view config.

### T3.4.11 — Day header stats & load tint
**Priority:** P1 · **Size:** S · **Depends on:** T3.4.01, [3.3] (day header)
**Description:** Each day header shows done/total for `check` items and planned hours. The header is tinted
by load = planned minutes ÷ work-hours minutes, with configurable thresholds at 80 % and 100 % (similar
to Sunsama's workload counter).
**Tests:** unit tests for load computation; goldens.
**Notes:** Thresholds are view config options `loadWarn` / `loadOver` (default 0.8 / 1.0), set with a range slider in view settings; unit tests in `day_header_stats_test.dart`, tinted headers in the week-table goldens.

### T3.4.12 — Tick-in-grid & tile quick menu
**Priority:** P0 · **Size:** S · **Depends on:** T3.4.01, [3.2] (actions)
**Description:**
- Tapping the checkbox area of a `check` tile marks it done, with a success haptic, a check animation and an
  undo snackbar.
- Tapping elsewhere on the tile opens the occurrence sheet.
- Long-pressing and releasing without moving opens a quick menu: Done, Skip, Start, Postpone ▸, Edit,
  Duplicate, Delete.
**Tests:** widget tests.

### T3.4.13 — Create / move / resize integration
**Priority:** P0 · **Size:** M · **Depends on:** T3.4.01, [3.3] (gestures), [3.2] (scopes)
**Description:** Wire the engine gestures to quick-create, reschedule operations and scope dialogs inside
the week table: drags across days and weeks, drags between the lane and the grid, one undo per commit.
**Acceptance criteria:** this integration scenario passes:
1. Long-press-drag Monday 07:00–08:30 and create "Gym", repeating weekly on Mon & Tue.
2. Drag Tuesday's occurrence to Wednesday 10:00 (*this occurrence*).
3. Resize it to 90 minutes.
4. Undo twice → the original Tuesday occurrence is restored.
**Tests:** integration test (widget-level or patrol).

### T3.4.14 — Crowded slots: "+N" overflow handling
**Priority:** P0 · **Size:** S · **Depends on:** T3.4.01, [3.3] (overlap layout)
**Description:** Phones cap overlaps at 2 lanes. A "+N" chip opens a popover listing the hidden items in
that time range, with quick actions and *Open day* (Day list scrolled to that time).
**Tests:** widget test with 5 overlapping items.

### T3.4.15 — DST & time-zone correctness
**Priority:** P0 · **Size:** S · **Depends on:** T3.4.01, [3.3] (DST day model), [3.2] (display rules)
**Description:**
- A week containing a DST change renders its 23- or 25-hour day correctly.
- Fixed-zone tasks appear at converted times with a zone badge; floating tasks keep their wall-clock time.
- Changing the device zone while the view is open re-lays it out.
**Tests:** goldens for Paris DST weeks (March and October); widget test for a zone change.

### T3.4.16 — Landscape & tablet layout
**Priority:** P1 · **Size:** S · **Depends on:** T3.4.08
**Description:** Landscape phones show 7 wider columns with a lane cap of 3. Tablets use a lane cap of 4
and up to 14 days. A side-panel slot is reserved for task details; full multi-pane comes later ([9.3]).
**Tests:** goldens at phone-landscape and tablet sizes.
**Notes:** Lane cap follows the column width (`laneCapFor`: 2 on phone columns, 3 from 90 px — landscape phones —, 4 from 150 px — tablets); up to 14 days on tablets. `PlannerViewScaffold.sidePanel` reserves the task-details panel on wide screens (empty until [9.3]). Goldens at phone-landscape and tablet sizes in `week_table_goldens_test.dart`.

### T3.4.17 — Week summary footer
**Priority:** P1 · **Size:** S · **Depends on:** T3.4.11, [6.3]
**Description:** A collapsible footer for the visible week: planned hours, tracked hours, completion % and
top categories. Tap → Planner insights for that week.
**Acceptance criteria:** the numbers equal the metric registry values for the same range.
**Tests:** unit test comparing with the metric registry.
**Notes:** `PlanSummaryFooter` (collapsible, remembered locally; tap → Planner insights for the range). `PlanSummary` is computed from the view items; `plan_summary_test.dart` checks it against the metric registry (`capacityReport` planned minutes, `planSnapshot` completion rate) for the same range.

### T3.4.18 — First-use hints & empty week
**Priority:** P1 · **Size:** S · **Depends on:** T3.4.01
**Description:** Dismissible coach marks: "Long-press to create", "Pinch to zoom", "Tap 30 min to change
the row size". An empty week shows an illustration with *Plan your first task*.
**Tests:** widget test (each hint shown once, persisted).
**Notes:** Coach cards (long-press, pinch, slot size) above the grid, one at a time, remembered in the local view state (`hintsSeen`); an empty visible range shows *Nothing planned this week* with *Plan your first task* (opens the editor like the FAB).

### T3.4.19 — Week numbers & secondary time zones
**Priority:** P2 · **Size:** S · **Depends on:** T3.4.01, [3.3] (secondary rulers)
**Description:** Optional ISO week number in the title and header; up to 3 secondary time-zone rulers.
**Tests:** goldens.
**Notes:** `showWeekNumbers` now also appends "W39" to the toolbar title (`weekOfYear` with the view's week start — ISO with Monday); the header / corner numbers and the zone rulers come from T3.3.26. Goldens with the T3.3.26 ones.

### T3.4.20 — Week table test suite
**Priority:** P0 · **Size:** M · **Depends on:** T3.4.13
**Description:**
- Goldens at 1, 5, 30, 120 and 1 440-minute slots × light/dark × LTR/RTL × text scale 1.0/2.0.
- The T3.4.13 integration scenario.
- A performance scenario (1-min slots, 2 000 occurrences) wired into the [9.1] performance suite.
**Tests:** as described.
**Notes:** `week_table_goldens_test.dart`: 1, 5, 30, 120, 1 440 min × light LTR / dark RTL, plus dark LTR, light RTL and text scale 2.0 at 30 min, compact density and both Paris DST weeks (text scale 2.0 is covered at 30 min only). The integration scenario is `week_table_integration_test.dart` (real data layer). `planner_perf_test.dart` runs the 1-min/2 000-item, 1 440-row table and 20-week paging scenarios as structural checks; profile-mode timings belong to the T9.1.08 drive suite. The grid now keeps its page area whole-pixel (fractional widths tripped PageView's precision assertion at the ±10 000 page index).
