# Section 3.6 — Calendar Views

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 3.2, 3.3, 3.4, 3.5, 6.2
> Architecture: §6.9, §8.3 (view types), §9.1

## Goal

The user asked for **more views**. This section adds calendar-style ways to look at the same plan, drawn
from the research on Google Calendar, Apple Calendar, Outlook, Fantastical, BusyCal, TickTick, Todoist,
Notion Calendar, Timepage, Tweek, Structured and Tiimo. Every view uses the same data, the time-grid engine
where time-based, and the saved-view model, so presets sync across devices.

## Scope

**In:** view registry and switcher; saved-views management; shared date state between views; N-day;
work week; week list (stacked); month (+ semantic zoom, list-below); agenda/schedule; year heatmap;
multi-week; quarter; ribbon (day & week); timeline/Gantt; category swimlanes; load heatmap; tests.
**Out:** week table ([3.4]) and day list ([3.5]); focus and productivity views ([3.7]).

## Progress

- [x] T3.6.01 — View registry & view switcher
- [x] T3.6.02 — Saved views management
- [x] T3.6.03 — Shared date state & view transitions
- [x] T3.6.04 — N-day view (rolling or fixed)
- [x] T3.6.05 — Work-week preset
- [x] T3.6.06 — Week list view (stacked days)
- [x] T3.6.07 — Month view
- [x] T3.6.08 — Month semantic zoom & list-below mode
- [x] T3.6.09 — Agenda / schedule view
- [x] T3.6.10 — Year heatmap view
- [x] T3.6.11 — Multi-week view
- [x] T3.6.12 — Quarter view
- [x] T3.6.13 — Ribbon view (day & week)
- [ ] T3.6.14 — Timeline / Gantt view
- [ ] T3.6.15 — Category swimlanes
- [ ] T3.6.16 — Load heatmap view
- [ ] T3.6.17 — Calendar views test suite

## Tasks

### T3.6.01 — View registry & view switcher
**Priority:** P0 · **Size:** S · **Depends on:** [3.3] (view config), [3.4], [3.5]
**Description:** `PlannerViewRegistry` maps each `type` (arch §8.3) to:
- its builder, default config, icon and localized name;
- capability flags: time-based, supports slot size, supports drag;
- availability, via feature flags that release P1/P2 views.

The switcher lives in the Plan app bar: a dropdown with icons, where long-press lists saved views.
Deep link: `/plan/<type>?date=YYYY-MM-DD`.
**Acceptance criteria:** the MVP ships Week table and Day list; enabling a view's flag makes it appear in
the switcher with no other code changes.
**Tests:** registry unit tests; widget test.
**Notes:** Entries are listed in `view_entries.dart`; P2 views are tier m3 (flag `planner_views_m3` or `view_<id>`, always on in dev builds).

### T3.6.02 — Saved views management
**Priority:** P1 · **Size:** S · **Depends on:** T3.6.01, [2.3] (saved views)
**Description:** *Save view as…*, rename, duplicate, delete, set as default, reorder. Each saved view keeps
its own config, e.g. "Work week · 15 min", "Night shift 18:00–06:00", "Deep work · 5 min". Views sync
across devices.
**Tests:** widget and repository tests.
**Notes:** Management sheet (save as, rename, duplicate, delete, set default, reorder) from the overflow menu or a long-press on the switcher; views sync through `saved_views`.

### T3.6.03 — Shared date state & view transitions
**Priority:** P1 · **Size:** S · **Depends on:** T3.6.01
**Description:** Switching views keeps the anchor date, and the time of day for time-based views.
Transitions use shared-axis animation. Back returns to the previous view type.
**Tests:** widget tests.
**Notes:** Switching views passes the shared anchor (first visible day, now also published for the first page) and the shared time of day; views cross-fade (instant under reduce-motion). Back returns to the previous view through `plannerViewHistoryProvider` (a `PopScope` in `PlannerScreen`); route-level page transitions stay the platform default.

### T3.6.04 — N-day view (rolling or fixed)
**Priority:** P1 · **Size:** S · **Depends on:** T3.6.01, [3.3]
**Description:** 1–14 day columns on the time-grid engine, either rolling (starting today/anchor) or aligned
to the week start. This view type defaults to 3 days in portrait (Todoist/Google style). Horizontal pinch
changes N.
**Tests:** widget tests; golden.
**Notes:** N-day entry on the time-grid engine: rolling from today (`options.rolling`, `firstDay: today`) or aligned to the week start; 3 days in portrait / 7 in landscape by default; horizontal pinch changes N; the toolbar arrows move by the visible range while swipes step one day. Golden: the calendar-views golden suite (T3.6.17).

### T3.6.05 — Work-week preset
**Priority:** P1 · **Size:** S · **Depends on:** T3.6.04
**Description:** An N-day preset limited to work days (Mon–Fri or custom days from settings), with visible
hours defaulting to work hours.
**Data model:** settings `planner.workDays` (arch §8.5).
**Tests:** unit test of day selection.

### T3.6.06 — Week list view (stacked days)
**Priority:** P1 · **Size:** S · **Depends on:** [3.4] (week-list mode)
**Description:** The week list as its own view type with a phone-friendly layout: days stacked vertically as
sections (Tweek / Things "Upcoming" style) instead of columns. Items can be dragged between days and untimed
items reordered within a day.
**Tests:** widget tests; golden.
**Notes:** `WeekListView`: stacked day sections (all-day / untimed first by manual order, then timed), long-press-drag to another day keeps the time, drop on an untimed item reorders (`manual_sort_key`), release on its own day opens the item menu; header tap → Day list; swipe / arrows / mini-month change week. Golden in the calendar-views suite (T3.6.17).

### T3.6.07 — Month view
**Priority:** P1 · **Size:** L · **Depends on:** T3.6.01, [3.2]
**Description:** A month grid of 4–6 weeks, honouring the week start and shading weekends, with chips per
day and load dots.
- Tapping a day opens its Day list, or (setting) expands the day inline, BusyCal-accordion style.
- Swipe vertically or horizontally (setting) between months.
- Long-press a day to create; drag a chip to another day (keeps its time).
**Acceptance criteria:** months with 6 week rows and leap years render correctly; dragging a recurring
occurrence triggers the scope dialog.
**Tests:** widget tests; goldens.
**Notes:** `MonthView` (months page vertically by default, `options.swipe` horizontal); tap → Day list, or inline expansion (`options.tapAction: expand`, BusyCal accordion) or list-below; drag between days goes through the reschedule command (scope dialog for recurring). Grid math unit-tested (6-row months, leap Februaries, week starts).

### T3.6.08 — Month semantic zoom & list-below mode
**Priority:** P1 · **Size:** M · **Depends on:** T3.6.07
**Description:**
- Pinching cycles density like iOS 18: dots → bars → titles → titles + times.
- *List below* mode puts a compact month on top and the selected day's items underneath (Google/Apple style).
**Data model:** view config `options.monthMode`, `options.listBelow`.
**Tests:** goldens for each density.
**Notes:** Pinch uses a raw two-pointer listener (paging stays free for one finger) and steps one density per 35 % span change; `monthMode` / `listBelow` persist in the view config. Density goldens in the calendar-views suite (T3.6.17).

### T3.6.09 — Agenda / schedule view
**Priority:** P1 · **Size:** M · **Depends on:** T3.6.01, [3.2]
**Description:** An infinite chronological list in both directions:
- grouped by day with sticky day headers;
- empty days collapsed unless *Show empty days* is on; optional notes preview;
- an optional DayTicker-style strip on top (days with colored pills at approximate times);
- inline actions.

Data loads in 2-week resolver ranges.
**Acceptance criteria:** scrolling from today to 6 months ahead stays smooth with 5 000 occurrences;
edits update rows in place.
**Tests:** widget tests; perf scenario.
**Notes:** `AgendaView`: the anchor day starts a forward region (sticky day headers, `PinnedHeaderSliver`) and earlier 2-week ranges grow upward from it (`CustomScrollView.center`; past headers scroll with their rows — no sticky there); both ends append ranges without moving the offset, empty stretches stop at a cap unless you scroll/overscroll into them. The title, DayTicker week and shared anchor follow the day at the top (header positions read on scroll). Options `showEmptyDays` / `showNotes` / `ticker`. Perf scenario: 5 000 occurrences over six months.

### T3.6.10 — Year heatmap view
**Priority:** P1 · **Size:** M · **Depends on:** T3.6.01, [3.2], [6.2] (calendar heatmap)
**Description:** 12 mini-months colored by a selectable metric: planned hours, completion rate or number of
items. Tap a day → Day list; long-press → create; navigate between years.
**Data model:** view config `options.heatMetric`.
**Tests:** unit tests for metric bins; goldens.
**Notes:** `YearView`: 12 mini-months (3 / 4 / 6 per row by width) of heat cells (`heat_calendar.dart`, shared with quarter and the load heatmap); metric `options.heatMetric` = planned | completion | count, binned by `heatLevel` (pure `dayMetric` / `heatLevel` in `calendar_metrics.dart`, unit-tested); items count on their start date. Tap → Day list, long-press → quick create (all-day), month name → Month view (the ≥ 48 dp path: single cells are small by nature), swipe / arrows change year. Cell numbers are fixed-size (dense grid); every cell has a semantics label with its value. Goldens: calendar-views suite (T3.6.17).

### T3.6.11 — Multi-week view
**Priority:** P2 · **Size:** M · **Depends on:** T3.6.07
**Description:** 2–6 rolling week rows starting this week, with month-style chips. Vertical pinch changes the
number of weeks (BusyCal).
**Data model:** view config `options.weeks`.
**Tests:** widget tests.
**Notes:** `MultiWeekView` reuses the month cell (`MonthDayCell`, now public; the 1st of a month and the first cell show "Oct 1"). Arrows / vertical swipes roll by one week; the week menu or a vertical two-finger pinch (one week per 30 % span change; spread = fewer) sets `options.weeks` (clamped 2–6). Density follows `options.monthMode`.

### T3.6.12 — Quarter view
**Priority:** P2 · **Size:** S · **Depends on:** T3.6.07
**Description:** Three months side by side (landscape/tablet) or stacked (phone), showing dots or bars per
day (Fantastical).
**Tests:** golden.
**Notes:** `QuarterView`: calendar quarters (Jan/Apr/Jul/Oct), months side by side from 600 dp, stacked below; `options.monthMode` dots (default) or bars from the toolbar; tap → Day list, long-press → all-day quick create, month name → Month view. Title uses the locale's `yQQQ` ("Q3 2026"). Golden in the calendar-views suite (T3.6.17).

### T3.6.13 — Ribbon view (day & week)
**Priority:** P2 · **Size:** M · **Depends on:** [3.5] (ribbon style)
**Description:** A full *ribbon* view type: the day ribbon from [3.5], plus a week ribbon that compresses each
day to its icons in order (Structured week view).
**Tests:** goldens.
**Notes:** `RibbonView` with `options.scope` = day | week (toolbar toggle). Day scope renders the day list's `DayRibbon` paged by day; week scope shows seven columns of icon bubbles (all-day as rounded squares first, then timed by start, connected by short lines; current item ringed). Tap an icon → task, long-press → tile menu, day header → that day's ribbon. Goldens in the calendar-views suite (T3.6.17).

### T3.6.14 — Timeline / Gantt view
**Priority:** P2 · **Size:** L · **Depends on:** T3.6.01, [3.2]
**Description:** A horizontal time axis whose scale (hours → days → weeks → months) changes with pinch.
- Rows grouped by task/series, category or priority.
- Bars sized by duration; drag to move or resize them.
- A today line.

Best for long multi-day tasks and series overviews (TickTick, Notion, ClickUp).
**Data model:** view config `options.groupBy`, `options.scale`.
**Tests:** widget tests; goldens.

### T3.6.15 — Category swimlanes
**Priority:** P2 · **Size:** M · **Depends on:** [3.3]
**Description:** Each day column splits into sub-columns per selected category, like Google's side-by-side
calendars in day view; in timeline mode, rows per category instead. The user picks the lanes and their order.
**Data model:** view config `options.lanes` (category ids).
**Tests:** goldens.

### T3.6.16 — Load heatmap view
**Priority:** P2 · **Size:** M · **Depends on:** T3.6.01, [6.2] (punch card)
**Description:** A 7×24 heatmap (weekday × hour) of planned or tracked minutes over the selected weeks, plus
per-day tints like Timepage. Colors show load against capacity. Tapping a cell lists the items behind it.
**Tests:** unit tests for the aggregation; goldens.

### T3.6.17 — Calendar views test suite
**Priority:** P1 · **Size:** S · **Depends on:** T3.6.09
**Description:** Goldens for each implemented view type (light/dark, RTL, text scale 2.0), plus an
integration test proving that switching views keeps the anchor date and time.
**Tests:** as described.
