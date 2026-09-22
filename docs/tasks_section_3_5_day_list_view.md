# Section 3.5 — Day List View

> Milestones: M1 (P0) · M2 (P1) · Depends on: 3.1, 3.2, 3.3
> Architecture: §6.9, §8.3, §9.1, §9.6

## Goal

The user's second view: **select a day, then see its 24 hours as a list of time slots with all tasks**.
Granularity runs from **1 minute to 24 hours**. It is built for fast one-handed daily use and also offers a
visual *ribbon* style.

## Scope

**In:** screen and date strip; pure slot-row model (DST-aware, spanning items shown once); lazy rendering;
slot-size control; "now" handling; row actions; creating from rows; collapsing empty runs; day navigation;
all-day section; 24-hour mode; day summary; drag to reschedule; ribbon style; tests.
**Out:** engine internals ([3.3]); backlog drawer ([3.7]); Today screen ([8.1]).

## Progress

- [ ] T3.5.01 — Day list screen & date strip
- [ ] T3.5.02 — Slot-row model (pure)
- [ ] T3.5.03 — Lazy slot list rendering
- [ ] T3.5.04 — Slot-size control & per-view persistence
- [ ] T3.5.05 — Now: current-slot highlight, divider & auto-scroll
- [ ] T3.5.06 — Row content & inline actions
- [ ] T3.5.07 — Create from rows (tap & range)
- [ ] T3.5.08 — Empty-run collapsing ("Free 1 h 20")
- [ ] T3.5.09 — Day navigation (swipe, picker, Today)
- [ ] T3.5.10 — All-day & untimed section
- [ ] T3.5.11 — 24-hour slot mode (day agenda)
- [ ] T3.5.12 — Day summary header
- [ ] T3.5.13 — Drag to reschedule within the list
- [ ] T3.5.14 — Visual ribbon style
- [ ] T3.5.15 — Day list test suite

## Tasks

### T3.5.01 — Day list screen & date strip
**Priority:** P0 · **Size:** M · **Depends on:** [3.3] (view config, range provider)
**Description:** `DayListScreen` has:
- a horizontal **date strip**: 7 chips for the current week (weekday, date, load dot); swipe the strip to
  change week; the selected day is highlighted;
- a title (tap → calendar picker), *Today*, the slot-size button and the view switcher;
- the slot list as the body.
**Acceptance criteria:** selecting a chip updates the list immediately; the strip follows the configured
week start.
**Tests:** widget tests; golden.

### T3.5.02 — Slot-row model (pure)
**Priority:** P0 · **Size:** M · **Depends on:** [3.3] (slot math, DST day model, bucketing)
**Description:** `buildDayRows(day, zone, slotMinutes, dayWindow, occurrences) → List<SlotRow>`, where each
row is `{slotStart, slotEnd, items}`.
- Built on the DST-aware day model (23/25-h days) and supports an uneven last slot.
- An item spanning several slots appears **once**, in its starting slot, with a duration bar extending
  visually over the following rows.
- Items that started the previous day appear in the first row marked "continues".
**Acceptance criteria:** fixture tests pass for 1, 15, 30, 60, 120 and 1 440-minute slots, for DST days,
and for a custom 7-minute slot.
**Tests:** unit tests.

### T3.5.03 — Lazy slot list rendering
**Priority:** P0 · **Size:** M · **Depends on:** T3.5.02
**Description:** A `CustomScrollView` with a lazily built `SliverList`:
- a fixed row extent where possible, so jumping to any time is O(1);
- sticky hour headers when slots are shorter than 60 min;
- each row shows its time label (locale 12/24 h) and item chips;
- duration bars are drawn by a background painter that spans rows.
**Acceptance criteria:** 1 440 one-minute rows fling at 60 fps; jumping to 18:00 needs no layout of the
rows before it.
**Tests:** widget tests; performance scenario.

### T3.5.04 — Slot-size control & per-view persistence
**Priority:** P0 · **Size:** S · **Depends on:** T3.5.03, [3.4] (slot-size sheet)
**Description:** Reuses the week table's slot-size sheet (presets + custom 1–1440). The size is stored in
the day-list saved view, independently of the week table's size.
**Tests:** widget test; persistence test.

### T3.5.05 — Now: current-slot highlight, divider & auto-scroll
**Priority:** P0 · **Size:** S · **Depends on:** T3.5.03
**Description:** When viewing today:
- the current slot is highlighted;
- a "now" divider with a time label sits at the exact minute inside that slot;
- the list scrolls to now on open (view config `autoScrollToNow`);
- a floating *Now* button appears when scrolled away.
**Tests:** widget tests with a fake clock (crossing a slot boundary moves the highlight).

### T3.5.06 — Row content & inline actions
**Priority:** P0 · **Size:** S · **Depends on:** T3.5.03, [3.2] (actions)
**Description:** Each item chip shows its time range, title, category color, icons (recurrence, fixed
zone, checklist progress) and status styling (as in the [3.3] tile widget).
- Checkbox → done.
- Swipe right = done, swipe left = skip (configurable, with undo).
- Tap → occurrence sheet; long-press → quick menu.
**Tests:** widget tests.

### T3.5.07 — Create from rows (tap & range)
**Priority:** P0 · **Size:** S · **Depends on:** T3.5.03, [3.1] (quick create)
**Description:**
- Tap an empty row (or the empty part of a row) → quick-create at the slot start, using the default
  duration rule from [3.1].
- Long-press and drag across rows → the range is highlighted → quick-create with that range.
**Tests:** widget tests.

### T3.5.08 — Empty-run collapsing ("Free 1 h 20")
**Priority:** P0 · **Size:** S · **Depends on:** T3.5.02
**Description:** With `hideEmptySlots`, consecutive empty slots collapse into one row such as
"Free 10:00–11:20 · 1 h 20".
- Tapping it offers *Create here*.
- *Fill from backlog* is added once the backlog drawer ships ([3.7]). It shows items whose estimate fits.
- The row can be expanded back into individual slots.
**Acceptance criteria:** at 1-min slots, a day with 5 tasks collapses to about 11 rows.
**Tests:** unit tests for run compression; widget test.

### T3.5.09 — Day navigation (swipe, picker, Today)
**Priority:** P0 · **Size:** S · **Depends on:** T3.5.01
**Description:** Swipe left/right on the list to change day. This is a `PageView` of days that keeps the
time position and is mirrored in RTL. Also available: calendar picker, *Today*, and arrow keys on tablets.
**Tests:** widget tests.

### T3.5.10 — All-day & untimed section
**Priority:** P0 · **Size:** S · **Depends on:** T3.5.03
**Description:** A collapsible section at the top listing the day's all-day and multi-day items and its
unplaced quota slots, each with a checkbox. Dragging from this section into a row arrives with T3.5.13.
**Tests:** widget test.

### T3.5.11 — 24-hour slot mode (day agenda)
**Priority:** P0 · **Size:** S · **Depends on:** T3.5.02
**Description:** With 1 440-minute slots the whole day is one row: an ordered agenda (all-day first, then by
time) where each item shows its time and actions. It is the simplest daily checklist of the plan.
**Tests:** widget test; golden.

### T3.5.12 — Day summary header
**Priority:** P1 · **Size:** S · **Depends on:** T3.5.01, [6.3]
**Description:** A header card with planned time, free time within work hours, done/total and tracked
time. Tap → Insights for that day.
**Acceptance criteria:** the values equal the metric registry values for the same day.
**Tests:** consistency unit test.

### T3.5.13 — Drag to reschedule within the list
**Priority:** P1 · **Size:** M · **Depends on:** T3.5.06, [3.2] (reschedule)
**Description:** Long-press an item and drag it to another row; the list auto-scrolls at the edges.
Dropping sets the new start and keeps the duration, with the scope dialog for recurring tasks. Items can
also be dragged between the all-day section and the rows.
**Tests:** widget gesture tests.

### T3.5.14 — Visual ribbon style
**Priority:** P1 · **Size:** M · **Depends on:** T3.5.02, [3.1] (task icon)
**Description:** An alternative day-list style inspired by Structured and Tiimo:
- a vertical ribbon of rounded, colored blocks with icons, sized by duration;
- gaps shown as dotted connectors labelled "free 45 m";
- all-day items on top and a *now* marker.

Actions are the same as the slot style. Toggle *Slots / Ribbon* from the view menu.
**Data model:** `tasks.icon` ([3.1] task icon task).
**Tests:** goldens (light/dark, RTL); widget tests.

### T3.5.15 — Day list test suite
**Priority:** P0 · **Size:** S · **Depends on:** T3.5.11
**Description:** Goldens for 1, 30, 120 and 1 440-minute slots, DST days, RTL, dark mode and text scale
2.0, plus a fling-performance scenario over 1 440 rows ([9.1]).
**Tests:** as described.
