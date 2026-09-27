# Section 5.2 — Habit Check-ins & Views

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 5.1, 1.3, 2.3, 6.1, 6.2, 6.5
> Architecture: §6.11 (check-in semantics), §6.14 (design system, RTL, a11y), §9.1 (local_date, dayStartsAt),
> §9.2 (UUIDv5 day-state ids)

## Goal

Make "I did it / I didn't" effortless and trustworthy. The Habits tab — Today list, week matrix, calendars
and heatmaps — lets the user check in, log values, backfill and review in one or two taps, while recording
exactly what the stats need: the time of each check-in, values, source, mood and note, and the difference
between an explicit "not done" and a day that was simply never logged.

## Scope

**In:** check-in service, Habits tab shell & view switcher, Today list (sections, rings, gestures, steppers,
timers), measurable input, intraday slot check-ins, week matrix, habit detail, day editor & backfill, notes &
mood, year heatmap, multi-habit month overview, grouping & density, check-in feedback & celebrations, notes
journal, evaluation caching.
**Out:** quit tracker screens ([5.3]); goals, challenges, freezes ([5.4]); metric definitions and the full
stats screens ([6.5]); the Today home block ([8.1]); widgets ([8.2]); reminders ([7.x]).

## Progress

- [x] T5.2.01 — Check-in service
- [x] T5.2.02 — Habits tab shell & view switcher
- [x] T5.2.03 — Today list
- [x] T5.2.04 — Measurable input UX (steppers, values, timers, entries)
- [x] T5.2.05 — Intraday slot check-ins
- [x] T5.2.06 — Week matrix view
- [x] T5.2.07 — Habit detail screen
- [x] T5.2.08 — Day editor & backfill
- [x] T5.2.09 — Notes & mood on check-ins
- [x] T5.2.10 — Year heatmap per habit
- [x] T5.2.11 — Multi-habit month overview
- [ ] T5.2.12 — Reorder, grouping & density
- [ ] T5.2.13 — Check-in feedback & celebrations
- [ ] T5.2.14 — Evaluation caching & performance
- [ ] T5.2.15 — Notes journal

## Tasks

### T5.2.01 — Check-in service
**Priority:** P0 · **Size:** M · **Depends on:** [5.1] (repository, period service, evaluation), [2.3] (undo)
**Description:** One application service that performs every check-in action identically from any surface —
Habits tab, Today ([8.1]), notification actions ([7.2]), widgets ([8.2]).
**Implementation notes:**
- API: `markDone(habit, key)`, `markNotDone`, `skip(note?)`, `excuse(note?)`, `clear`, `addProgress(value,
  at?)`, `updateEntry`, `deleteEntry`, `setNoteAndMood`, `checkNow(habit)` (resolves the current slot).
- Yes/no and explicit states: exactly one state log per period key with deterministic id
  `v5(habit_id|key|state)` (arch §9.2); switching state updates `kind` on that row, *clear* soft-deletes it.
- Measurable: every addition is a new `progress` log (UUIDv7) so time-of-day patterns survive; "Done" on a
  measurable habit logs the remaining amount as one entry.
- Each log sets `logged_at` (event time), `local_date` (the period's local day, computed in the effective
  zone with `dayStartsAt`), `occurrence_key` (day or slot key — never a quota key), `source`
  (`manual | notification | widget | auto | import`).
- Guards: no `done`/`progress` for future periods; `skip`/`excuse` allowed for future days (planned
  absence); archived habits are read-only.
- Every action returns an undo command (snackbar *Undo*) and emits a domain event consumed by celebrations
  (T5.2.13), notification replanning ([7.2]) and widget refresh ([8.2]).
**Acceptance criteria:** the same action from the Habits tab, Today and a notification writes identical rows;
marking done offline on two devices converges to one row after sync; undo restores the exact prior state.
**Tests:** service unit tests (fake clock, two zones, `dayStartsAt` 04:00); add a "habit day toggled on two
devices" scenario to the [9.1] convergence suite.
**Notes:** `CheckInService` (application) is the single entry point; unit tests cover deterministic state ids, undo, guards, backfill `logged_at`, slots/tolerance and `dayStartsAt` 04:00 in two zones. The two-device scenario in the [9.1] convergence suite is not added (core/sync tests are outside this feature).

### T5.2.02 — Habits tab shell & view switcher
**Priority:** P0 · **Size:** S · **Depends on:** T5.2.01, [1.3] (shell, routing)
**Description:** Tab root with a view switcher (Today list · Week matrix · Month · Year), the quit-counter
strip at the top ([5.3]), a filter chip (All / Due / section), a date navigator (← day →) and the **+** menu
(New habit, New quit tracker, From template).
**Implementation notes:** last view and filter remembered locally; the date navigator lets the user view and
edit any past day in the Today list.
**Acceptance criteria:** switching views keeps the selected date; deep links `/habits` and `/habits/:id`
open the right screen.
**Tests:** widget tests; routing test.
**Notes:** Last view and filter are remembered in `local_kv` (`HabitUiStore`); the week matrix and month view follow the selected date. Deep links use the existing `/habits`, `/habits/:id` routes (no separate routing test).

### T5.2.03 — Today list
**Priority:** P0 · **Size:** L · **Depends on:** T5.2.02, [5.1] (sections)
**Description:** The main check-in surface: habits due on the selected day grouped by time-of-day section
(current section first), each row showing icon, name, target/progress text ("12 / 15 reps"), a progress
ring, a streak chip and one primary action.
**Implementation notes:**
- Inside each section: *Due* → *Done* → *Not due today* (collapsed by default). Quota habits show period
  progress ("2 of 3 this week") and an at-risk marker.
- Primary action by goal: yes/no → one-tap ring (setting: tap, or hold-to-complete with fill animation);
  count → +/− stepper; duration → start/stop timer; numeric → value sheet.
- Gestures: **swipe right** = done / log quick value; **swipe left** = reveal *Not done* and *Skip* (full
  swipe = *Not done*, configurable); **long-press** = full menu (not done, skip, excuse with reason, note &
  mood, edit entries, backfill another day, details, pause). Swipe directions mirror in RTL.
- Status always shown with icon + text + color (never color alone); section headers show "x / y done";
  "All done 🎉" state when nothing is due.
**Acceptance criteria:** a check-in updates the ring, streak chip and Today home block within one frame;
text scale 2.0 without clipping; 50 habits scroll at 60 fps.
**Tests:** widget tests per goal type and gesture (LTR and RTL); goldens (light/dark, 2.0 text).
**Notes:** Widget tests for one-tap, stepper, swipe done (LTR and RTL), full swipe not done, long-press skip with reason (cancel aborts), future days; goldens not added.

### T5.2.04 — Measurable input UX (steppers, values, timers, entries)
**Priority:** P0 · **Size:** M · **Depends on:** T5.2.01
**Description:** Fast, precise logging of counts, durations and numeric values.
**Implementation notes:**
- Stepper with the habit's increment step and press-and-hold repeat; quick-value chips (+5, +10, +15) from
  habit settings; numeric keypad sheet with unit, locale decimal separator, Arabic-Indic digit input.
- Duration: quick timer with start / pause / stop; running state persisted locally so it survives app kill;
  stop → `progress` log with `value` in minutes and `duration_seconds`.
- Entries list per period (time, value, note) with edit/delete; header shows total vs target and remaining.
**Data model:** local-only Drift table `habit_timer_state (habit_id, occurrence_key, started_at,
paused_accum_seconds)` — not synced.
**Acceptance criteria:** logging 10 then 5 push-ups keeps two entries with their own times; a timer running
when the app is killed resumes with the correct elapsed time.
**Tests:** widget tests; unit tests for timer persistence and decimal parsing (en, fr, ar).

### T5.2.05 — Intraday slot check-ins
**Priority:** P0 · **Size:** M · **Depends on:** T5.2.03, [5.1] (multiple-times-per-day semantics)
**Description:** For fixed-time or interval habits: a row of slot chips (08:00 · 14:00 · 20:00) with the
current slot highlighted; tapping a chip toggles that slot; the day roll-up shows "2/3".
**Implementation notes:** more than 8 slots → compact scrollable chips plus a *Check now* button (targets the
slot according to early tolerance); past unlogged slots show as missed; the week matrix shows mini-segments
per day.
**Acceptance criteria:** tapping the 14:00 chip at 13:40 (tolerance 30 min) records the 14:00 slot; the
roll-up matches the evaluation engine.
**Tests:** widget tests; unit tests for chip state mapping.

### T5.2.06 — Week matrix view
**Priority:** P0 · **Size:** M · **Depends on:** T5.2.01, T5.2.03
**Description:** Loop-style grid: habits as rows, the last N days as columns (7 by default; 5–14 depending
on width; today at the trailing edge). Each cell shows the period status; tap cycles the state, long-press
opens the full menu.
**Implementation notes:**
- Tap-cycle setting: `done → not done → clear` (default — matches "I did it or not"), `done → skip → clear`
  (Loop style) or `done → clear`; option "toggle with short press" vs "long-press to toggle" to prevent
  accidental edits.
- Measurable cells show value/target ("12/15") with fill intensity; slot habits show mini-segments;
  quota rows show "2/3 this week" in the row header with an at-risk marker; not-due cells are faded.
- Sticky habit column; horizontal swipe goes back in time (infinite); column headers respect week start;
  RTL mirrors column order.
**Data model:** `user_settings.habits` keys `matrixTapCycle`, `toggleWithShortPress`.
**Acceptance criteria:** toggling a past cell backfills per T5.2.08 rules; 30 habits × 60 days scroll at 60 fps.
**Tests:** widget tests for each cycle; goldens.
**Notes:** Tap cycle and short/long-press toggling come from `user_settings.habits` (`HabitViewSettings`); goldens not added.

### T5.2.07 — Habit detail screen
**Priority:** P0 · **Size:** M · **Depends on:** T5.2.01, [6.1] (streak & strength functions), [6.5]
**Description:** One screen per habit: header (icon, name, schedule sentence from `describe()`, goal),
stat chips — **current streak, best streak, strength score, 30-day completion rate** — a counts row
("Done 45 · Not done 6 · Missed 3 · Skipped 2" for the last 90 days), a month calendar with period
statuses (tap a day → day editor), recent entries with notes/mood, and actions (check in, edit, pause,
archive, goals [5.4], *All stats* → [6.5]).
**Implementation notes:** use the single implementations in `everslot_metrics` ([6.1]/[6.5]) — never
re-implement streaks or scores here; show both streak and strength (views research); honour [6.1]
minimum-data rules ("not enough data yet"); calendar respects week start and `dayStartsAt`.
**Acceptance criteria:** numbers equal the [6.5] stats screen for the same habit and period.
**Tests:** widget tests with fixture data; golden.
**Notes:** Streaks, strength and rates come from `everslot_metrics` through `summarizeHabit`; golden not added.

### T5.2.08 — Day editor & backfill
**Priority:** P0 · **Size:** S · **Depends on:** T5.2.01
**Description:** Edit any past period — and plan future skips/excuses — from the matrix, calendars, heatmap or
the Today date navigator: state (done / not done / skip / excuse / clear), value entries, note, mood.
**Implementation notes:** backfilled logs get `logged_at` = the period's local date at a user-chosen time
(default: the slot time, else 12:00) while `created_at` keeps the real write time, so [6.5] data-quality
metrics can detect backfills (logged > 24 h late) and exclude them from time-of-day patterns; recompute is
incremental from the edited period.
**Acceptance criteria:** backfilling last Tuesday updates streaks and score immediately; future days accept
only skip/excuse.
**Tests:** unit tests for `logged_at` rules; widget tests.
**Notes:** Backfills default to noon (or the slot time); a time picker for backfills is not offered in the day editor.

### T5.2.09 — Notes & mood on check-ins
**Priority:** P0 · **Size:** S · **Depends on:** T5.2.01
**Description:** Optional note and 1–5 mood (emoji scale with text labels) per check-in or per day, prompted
after check-in when enabled for the habit or globally.
**Implementation notes:** yes/no habits store them on the state log; measurable habits on the progress log
or a `note` log for the period; skip/excuse reasons use the same note field; notes are indexed by global
search ([2.3]); mood feeds correlations ([6.7]).
**Acceptance criteria:** the prompt never blocks the check-in and can be dismissed; notes appear in detail
and journal views.
**Tests:** widget tests; FTS index test for note text.
**Notes:** The FTS index of note text belongs to global search ([2.3]); notes are stored on the state/progress/`note` rows it indexes.

### T5.2.10 — Year heatmap per habit
**Priority:** P1 · **Size:** M · **Depends on:** T5.2.07, [6.2] (calendar heatmap component)
**Description:** GitHub-style year grid (columns = weeks, rows = weekdays per week start, today at the
trailing edge): status colors for yes/no, intensity = achieved / target for measurable habits; tap today to
log, tap a past day to open the day editor; scroll back through years.
**Acceptance criteria:** legend and accessible summary ("Done on 212 of 280 scheduled days in 2026").
**Tests:** golden; widget tap tests.
**Notes:** Painted grid (one `CustomPaint`) instead of the [6.2] heatmap component; tapping any day opens the day editor (today included, where logging happens). Paused days are not counted as scheduled in the summary. Golden not added.

### T5.2.11 — Multi-habit month overview
**Priority:** P1 · **Size:** M · **Depends on:** T5.2.06
**Description:** Month calendar where each day shows the share of due habits completed (ring) with perfect
days highlighted; tapping a day opens a sheet listing every habit's status that day with inline editing.
**Acceptance criteria:** the perfect-day definition equals [6.5] (all due habits done; excused, paused and
not-due habits don't count as due).
**Tests:** widget tests; unit test for the per-day ratio.
**Notes:** Per-day ratios come from `everslot_metrics` `dailyCompletionHeatmap` (the [6.5] perfect-day rule); the day sheet reuses the Today list for inline editing.

### T5.2.12 — Reorder, grouping & density
**Priority:** P1 · **Size:** S · **Depends on:** T5.2.03, [5.1] (manage habits)
**Description:** Drag to reorder directly in the Today list, group by section / category / none, hide
not-due habits, compact vs comfortable density, show/hide streak chips.
**Data model:** `user_settings.habits` keys `groupBy`, `density`, `showStreakChips`, `hideNotDue`.
**Tests:** widget tests.

### T5.2.13 — Check-in feedback & celebrations
**Priority:** P1 · **Size:** S · **Depends on:** T5.2.01
**Description:** Haptics (`selectionClick` per step, `mediumImpact` at hold start, success on completion),
optional sound, hold-to-complete fill animation, celebrations for streak milestones (7/30/100/365…), perfect
days, challenge completion ([5.4]) and quit milestones ([5.3]).
**Implementation notes:** respects reduce-motion, haptics and sound settings ([8.3]); celebrations are
non-blocking overlays.
**Acceptance criteria:** with reduce motion on, feedback is instant (text + haptic), no animation.
**Tests:** widget tests with reduce motion on/off.

### T5.2.14 — Evaluation caching & performance
**Priority:** P1 · **Size:** S · **Depends on:** T5.2.03, T5.2.06
**Description:** Cache `PeriodResult`s per habit (keyed by revision set + log version), recompute
incrementally from the earliest changed date, and run long ranges in a background isolate.
**Acceptance criteria:** Today list for 50 habits with 5 years of logs builds in < 100 ms; the week matrix
scrolls at 60 fps; a check-in is reflected in the UI within one frame (optimistic).
**Tests:** performance scenario in the [9.1] harness; cache invalidation unit tests.

### T5.2.15 — Notes journal
**Priority:** P2 · **Size:** S · **Depends on:** T5.2.09
**Description:** Timeline of all notes and moods across habits (filter by habit, mood, date) with a mood
sparkline and a jump to the day.
**Tests:** widget tests.
