# Section 5.1 — Habit Model, Schedules & Period Evaluation

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.2, 1.3, 1.4, 2.1, 2.3, 8.3 (regional settings)
> Architecture: §6.8 (recurrence, occurrence keys, quota periods), §6.11 (habit & quit engine), §7.3 (habits,
> habit_logs, habit_pauses, habit_revisions), §8.1 (recurrence JSON), §8.4 (habit goal), §8.5 (settings),
> §9.1 (local_date, dayStartsAt, week start), §9.2 (UUIDv5)

## Goal

Give the Habits section a solid foundation: what a habit is (yes/no, count, duration, numeric, or an
"at most" limit), **when it is due** (any schedule the shared recurrence engine can express — daily,
specific weekdays, every N days, N times per week/month, several times a day, every N hours in a window,
fully custom), and — for every period — **whether it was done, partly done, explicitly not done, missed,
skipped, excused or paused**. The user's core flow ("15 push-ups every day, each day I mark did it or
not") must be modelled exactly, and every fact the stats in [6.5] need must be recorded here, including
history-preserving schedule changes.

## Scope

**In:** server migrations & pgTAP, Drift tables/DAOs, domain entities, habits repository with revisions,
habit period service, period evaluation engine (`everslot_metrics`), habit editor (basics, goal, schedule
presets, advanced options), multiple-times-per-day semantics, limit habits, time-of-day sections, schedule
change effective dates, pauses & vacation mode, manage/archive/reorder, templates, after-completion habits.
**Out:** check-in UI & views ([5.2]); quit-specific editor, calculator and screens ([5.3]); goals,
challenges, streak freezes ([5.4]); streak / strength-score / rate implementations and all habit metrics
([6.1], [6.5]); reminders ([7.1], [7.5]); widgets ([8.2]).

## Progress

- [x] T5.1.01 — Server migrations: habits, logs, pauses, revisions
- [x] T5.1.02 — Drift tables, DAOs & mappers
- [x] T5.1.03 — Domain model: habits, goals, logs, pauses, revisions
- [x] T5.1.04 — Habits repository (CRUD, revisions, cascade, undo)
- [x] T5.1.05 — Habit period service (schedule → periods & keys)
- [x] T5.1.06 — Period evaluation engine (`everslot_metrics`)
- [x] T5.1.07 — Habit editor: basics & goal
- [x] T5.1.08 — Habit editor: schedule presets & custom schedule
- [x] T5.1.09 — Multiple-times-per-day semantics
- [x] T5.1.10 — Limit ("at most") habits
- [x] T5.1.11 — Time-of-day sections (defaults)
- [x] T5.1.12 — Advanced options (skip policy, increments, prompts)
- [ ] T5.1.13 — Schedule/goal changes: effective date & retro edit
- [ ] T5.1.14 — Pauses & vacation mode
- [ ] T5.1.15 — Manage habits: archive, restore, reorder, custom sections
- [ ] T5.1.16 — Habit templates
- [ ] T5.1.17 — After-completion habits

## Tasks

### T5.1.01 — Server migrations: habits, logs, pauses, revisions
**Priority:** P0 · **Size:** M · **Depends on:** [1.2] (`app.enable_sync`, pgTAP harness)
**Description:** Create `app.habits`, `app.habit_logs`, `app.habit_pauses` and `app.habit_revisions` exactly
as in arch §7.3, wired with `app.enable_sync(...)`, plus the constraints that keep build and quit data valid.
**Implementation notes:**
- Kind-specific `CHECK`s: `kind = 'build'` ⇒ `goal_type` set and (`goal_type = 'check'` or `target_value > 0`);
  `target_op = 'lte'` only for measurable goal types; `kind = 'quit'` ⇒ `quit_mode` and `quit_started_at` set;
  `quit_mode = 'reduce'` ⇒ `daily_limit >= 0`; `currency ~ '^[A-Z]{3}$'`; `end_date >= start_date`;
  `freezes_per_month between 0 and 31`; `time_per_unit_minutes`, `life_minutes_per_unit`, `unit_cost`, `baseline_per_day` ≥ 0.
- `habit_logs`: `value >= 0`; `value` required for `progress`; `intensity` only for `craving`;
  `occurrence_key` either NULL or a **day** (`YYYY-MM-DD`) / **slot** (`YYYY-MM-DDTHH:mm`) key — logs never
  carry quota period keys (those are evaluation outputs, see T5.1.06).
- Trigger: logs, pauses and revisions must reference a habit owned by the same `user_id`.
- Indexes: `habit_logs (user_id, habit_id, local_date)`, `habit_logs (user_id, habit_id, occurrence_key)`,
  `habit_pauses (user_id, habit_id, start_date)`; `habit_revisions unique (habit_id, effective_from)`.
- Child rows are soft-deleted by the client repository (T5.1.04); the server purge job purges children of
  purged habits.
**Acceptance criteria:**
- Migration applies on a clean local stack and on top of all previous migrations.
- The RLS/trigger completeness check ([9.1]) passes for the four tables.
- Invalid rows (quit without `quit_started_at`, negative value, quota key in a log, cross-user child) are
  rejected with a clear error.
**Tests:** pgTAP — user isolation, every `CHECK`, revision uniqueness, cross-user child rejection, sync
triggers attached.
**Notes:** Delivered with the foundation migration `20260922000090_create_habits_goals.sql` (kind-specific CHECKs, day/slot-only `occurrence_key`, same-owner constraint triggers, indexes, revision uniqueness) and pgTAP coverage in `070_domain_constraints.test.sql` / `020_rls_completeness.test.sql`.

### T5.1.02 — Drift tables, DAOs & mappers
**Priority:** P0 · **Size:** M · **Depends on:** T5.1.01, [1.4]
**Description:** Local mirrors of the four tables (common `SyncedTable` columns) and DAOs with the reactive
queries used by the Habits tab, Today and stats.
**Implementation notes:**
- DAO queries: `watchActiveHabits(kind?)`, `watchHabit(id)`, `watchLogsInRange(habitIds, fromDate, toDate)`,
  `watchLogsForKeys(habitId, keys)`, `watchPauses(habitId?)`, `revisionsFor(habitId)`,
  `latestLogPerHabit()`, `lastEventOfKind(habitId, kinds)`.
- `schedule` column uses the recurrence-rule JSON converter from [2.1]; dates as `YYYY-MM-DD` text.
- Register the tables in the sync table registry ([1.4]).
**Acceptance criteria:** range queries hit indexes (`EXPLAIN QUERY PLAN`); streams emit on every write;
mapping round-trips losslessly.
**Tests:** in-memory Drift DAO tests; migration test for the schema-version bump.
**Notes:** Drift tables and the sync-registry entries come from the foundation schema; the reactive queries live in `HabitsRepository` / `HabitLogsRepository` / `HabitPausesRepository` (no separate DAO classes), tested on the in-memory DB.

### T5.1.03 — Domain model: habits, goals, logs, pauses, revisions
**Priority:** P0 · **Size:** M · **Depends on:** T5.1.02
**Description:** Pure-Dart (freezed) entities and value objects shared by build habits and quit trackers.
**Implementation notes:**
- `Habit` sealed into `BuildHabit` and `QuitTracker` (quit specifics in [5.3]); `HabitGoal { type: check |
  count | duration | numeric, target, op: gte | lte | eq, unit }` (arch §8.4); `HabitSchedule` wraps a
  `RecurrenceRule` + anchor (`start_date`, zone mode); `HabitLog` sealed by kind (`StateLog` done / fail /
  skip / excuse, `ProgressLog`, `NoteLog`, quit kinds in [5.3]); `HabitPause`; `HabitRevision`.
- Validation: name 1–80 chars; target > 0 for measurable goals; duration targets 1–1 440 min; `lte` only
  for measurable goals; units from a localized catalog or free text (1–20 chars).
- `HabitRevision.effectiveFor(date)`: latest revision with `effective_from ≤ date`, else the habit's current
  values.
**Acceptance criteria:** invalid construction throws typed validation errors mapped to localized messages;
`schedule` JSON round-trips losslessly.
**Tests:** unit tests for validation and revision resolution.
**Notes:** Hand-written immutable classes (ADR-016, no freezed): `Habit` sealed into `BuildHabit` / `QuitHabit`, `HabitTarget`, `HabitSettings` v1, `HabitLogEntry`, `PauseSpan`, `HabitRevision`; validation codes map to localized messages (`HabitLabels.validationMessage`).

### T5.1.04 — Habits repository (CRUD, revisions, cascade, undo)
**Priority:** P0 · **Size:** M · **Depends on:** T5.1.03, [2.3] (activity events, undo)
**Description:** Repository used by the application layer to create, edit, archive and delete habits. It
writes row + outbox (+ activity event) in one transaction and appends a revision whenever schedule, goal or
quit economics change, so past periods keep being evaluated with the rules they had.
**Implementation notes:**
- `create(habit)` also writes the initial revision (`effective_from = start_date`).
- `update(habit, {applyFrom})`: if schedule, goal type/target/op/unit, baseline, unit cost or daily limit
  changed → upsert `habit_revisions(effective_from = applyFrom ?? today's local date)`; cosmetic edits
  (name, icon, color, section) never create revisions.
- `delete(id)`: soft-delete the habit plus its logs, pauses and revisions in one transaction with one
  operation id (restorable from Trash, [8.3]).
- `reorder(id, before, after)` via fractional `sort_key`; `archive/unarchive`.
- Every mutation returns an undo command ([2.3]).
**Acceptance criteria:** changing "every day" → "weekdays" today leaves yesterday's evaluation unchanged
(verified with T5.1.06); delete + restore brings back all logs; undo restores the exact previous rows.
**Tests:** repository tests with in-memory DB and fake clock.

### T5.1.05 — Habit period service (schedule → periods & keys)
**Priority:** P0 · **Size:** M · **Depends on:** T5.1.03, [2.1] (`between` / `periods` API), [8.3] (dayStartsAt, week start)
**Description:** Turns a habit's revision-aware schedule into concrete periods for any date range: day
periods, intraday slot periods and quota periods (week/month), each with its key, local window and instant
window.
**Implementation notes:**
- Keys (arch §6.8): day `YYYY-MM-DD`; slot `YYYY-MM-DDTHH:mm`; quota `week:YYYY-MM-DD` (period start date,
  honouring the user's week start) or `month:YYYY-MM`.
- Day window = `[D @ dayStartsAt, D+1 @ dayStartsAt)` in the effective zone (floating → current zone;
  fixed → habit zone). With `dayStartsAt = 04:00`, a 01:00 check-in belongs to the previous day. Until
  [8.3] ships, defaults are 00:00 and the profile's week start.
- Slot window = `[slot start − earlyTolerance, next slot start)`; the last slot ends at the day window end.
- Quota periods group the eligible days (all days, or days allowed by `byWeekday`); partial first/last
  periods (habit starts or ends mid-week) expose `eligibleDays` for pro-rating (research §B).
- Each period carries the revision in force at its start; periods before `start_date` / after `end_date`
  are excluded; future periods are returned only when explicitly requested (for "upcoming" UI).
- API: `periods(habit, revisions, from, to)`, `periodForInstant(habit, instant)`, `dayKeyFor(instant)`,
  `currentPeriod(habit, now)`.
**Acceptance criteria:** 23/25-hour DST days give correct windows; week start MO/SA/SU shifts quota keys
correctly; `periodForInstant` agrees with `periods` for 10 000 random instants.
**Tests:** fixture tests incl. Europe/Paris DST, Africa/Tunis, `dayStartsAt` 00:00 and 04:00, quota month
boundaries, revision switch mid-range.

### T5.1.06 — Period evaluation engine (`everslot_metrics`)
**Priority:** P0 · **Size:** L · **Depends on:** T5.1.05
**Description:** The single implementation that decides each period's outcome — the base of check-in UI,
streaks, the strength score and every habit stat ([6.1], [6.5]). Pure, deterministic, Drift-independent.
**Implementation notes:**
- Output `PeriodResult { key, window, revision, status, achieved, target, ratio, entries, flags }` with
  `status ∈ done | partial | failed | missed | skipped | excused | paused | pending | not_due`
  (+ `frozen`, added by [5.4]).
- **Precedence:**
  1. An explicit state log for the period (single row, latest user statement): `excuse` → excused,
     `skip` → skipped, `fail` → failed (explicit "not done"), `done` → done.
  2. Otherwise evaluate the goal from progress logs (below). A `done` result stays done even inside a pause.
  3. Otherwise, if the period lies in a pause (habit-level or global) → paused (neutral).
  4. Otherwise the goal result (partial / missed / pending / failed-by-limit).
- **Goal rules:** *check* — no state & window closed → **missed** (unlogged ≠ explicitly failed), open →
  pending. *gte* — Σ progress ≥ target → done (early completion allowed); closed & 0 < Σ < target → partial;
  closed & Σ = 0 → missed. *lte* — Σ > target → failed immediately; closed & Σ ≤ target → done, unless
  `requireExplicitLog` and nothing logged → missed (T5.1.10). *eq* — closed & Σ = target → done; Σ > target
  → failed; 0 < Σ < target → partial.
- **Quota periods:** evaluate each day first (a day is *active* if done, or Σ ≥ `minPerDay` for measurable);
  check-type quota → done when active days ≥ `quota.times`; measurable quota → target applies to the period
  **total** and `quota.times` (optional) is the minimum number of active days. Closed & short → partial (≥ 1
  active day) or missed; open → pending with `atRisk` when completions still needed > remaining eligible
  days (research §C).
- **Slots:** each slot evaluated as above, plus a per-day **roll-up** result (T5.1.09) used by streaks and Today.
- Skip policy `breaks` sets `breaksStreak` on skipped periods; excused / paused / frozen never break.
- Days outside the schedule → `not_due` (never missed). Future periods are not evaluated.
- Performance: 5 years of a daily habit < 20 ms; 50 habits × 1 year < 150 ms (background isolate for long ranges).
**Acceptance criteria:** fixture suite covering every goal type × op × schedule kind (daily, weekdays, every
N days, quota week/month, fixed slots, interval windows) × special cases (pauses, skip policies, revision
change mid-range, backfilled entries); results independent of log insertion order.
**Tests:** ≥ 120 fixture cases in `fixtures/habits/*.json`; property tests (adding a progress log never lowers
`achieved`; removing a pause never turns a done period into another status).
**Notes:** Evaluation is `everslot_metrics` `evaluateHabitPeriod(s)` + `rollUpSlots`, wrapped by `domain/habit_evaluation.dart` (revisions, pauses, skip policy, freezes). App tests are table-driven in `habit_evaluation_test.dart`; the ≥ 120-case JSON fixture suite is not written yet (partial test coverage).

### T5.1.07 — Habit editor: basics & goal
**Priority:** P0 · **Size:** M · **Depends on:** T5.1.04, [1.3] (pickers), [2.3] (categories)
**Description:** First part of the full-screen editor: type (Build habit / Quit tracker → [5.3] editor),
name, icon, color, category, time-of-day section, description, goal type (Yes/No, Count, Duration,
Numeric), target, unit and comparison (at least / at most / exactly).
**Implementation notes:**
- Goal cards with examples: "15 push-ups" (count ≥ 15 reps), "≤ 2 coffees" (count ≤ 2), "Read 20 min"
  (duration ≥ 20), "Run 5 km" (numeric ≥ 5 km).
- Localized unit catalog (reps, times, glasses, pages, km, mi, steps, min, h, kcal, L, ml, cups…) plus custom
  text; ICU plurals; duration entered as h:mm, stored in minutes.
- Live sentence preview ("15 reps · at least · every day").
**Acceptance criteria:** creating "15 push-ups every day" needs ≤ 4 taps after typing the name (defaults:
count, at least, every day); localized validation; RTL verified.
**Tests:** widget tests per goal type; goldens (light/dark, AR).
**Notes:** Widget tests in `habit_editor_test.dart` (duration, numeric + unit, yes/no, validation FR); goldens not added.

### T5.1.08 — Habit editor: schedule presets & custom schedule
**Priority:** P0 · **Size:** L · **Depends on:** T5.1.07, T5.1.05, [2.1] (rule builder UI, `describe`)
**Description:** The "fully free" schedule UI for habits, built on the same engine and builder as Planner
tasks, with presets for the common cases.
**Implementation notes:**

| Preset | Rule (arch §8.1) |
|---|---|
| Every day | `daily` |
| Specific weekdays (e.g. Mon & Tue) | `weekly` + `byWeekday` |
| Weekdays / weekends | `weekly` MO–FR / SA, SU |
| Every N days (every other day = 2) | `daily`, `interval N`, anchored on the start date |
| N times per week / per month, any days | `quota { times N, per week | month }` |
| N times per day, any time | `daily` + count goal ≥ N (converts a yes/no goal to count "times") |
| At specific times (08:00, 14:00, 20:00) | `daily` + `times` (slot periods) |
| Every N hours / minutes between HH:mm–HH:mm | `hourly` / `minutely` + `window` (+ optional `byWeekday`) |
| Monthly on day X / Nth weekday / last day | `monthly` + `byMonthDay` / `byWeekday n` / `-1` |
| Custom | full [2.1] builder (any rule the engine supports) |

- Start date (default today); optional end date ("for 30 days" shortcut → challenge, [5.4]); zone mode
  (floating by default, or a fixed IANA zone).
- Live preview: the `describe()` sentence + next 10 periods + warnings (e.g. > 48 slots/day).
**Acceptance criteria:** every preset round-trips (reopening shows the same preset, not "Custom"); quota and
slot schedules evaluate correctly in T5.1.06 fixtures; the preview equals the evaluated periods.
**Tests:** widget tests per preset; bidirectional preset ↔ rule mapping unit tests.
**Notes:** "Custom…" opens the shared `showRecurrencePicker(mode: RecurrencePickerMode.habit)`; preset ↔ rule round-trips are unit- and widget-tested (reopening shows the preset, saving adds no revision).

### T5.1.09 — Multiple-times-per-day semantics
**Priority:** P0 · **Size:** M · **Depends on:** T5.1.05, T5.1.06
**Description:** Make "several times a day" unambiguous: (a) a count target per day at any time (8 glasses of
water), (b) fixed time slots (medication at 08:00 and 20:00), (c) interval slots (stand up every hour
09:00–18:00).
**Implementation notes:**
- (a) = one day period with a measurable goal; (b) and (c) = slot periods with keys `YYYY-MM-DDTHH:mm`, each
  slot yes/no (or measurable per slot).
- Day roll-up setting for slot habits: `all_slots` (default) or `min N` slots (e.g. 6 of 9 stand-ups).
- Early tolerance (0–120 min, default 30) decides which slot a "Check now" targets; tapping a slot chip
  always uses that slot's key.
**Data model:** `habits.settings jsonb` (HabitSettings v1: `slotRollup {mode, minSlots}`,
`earlyToleranceMinutes`, …) (arch §7.3).
**Acceptance criteria:** after two of three slot check-ins Today shows "2/3"; streaks use the day roll-up;
stats can still read slot-level results.
**Tests:** evaluation fixtures for roll-up modes; unit tests for "check now" targeting at tolerance edges.

### T5.1.10 — Limit ("at most") habits
**Priority:** P0 · **Size:** S · **Depends on:** T5.1.06, T5.1.07
**Description:** Negative habits that are limited rather than quit (≤ 2 coffees/day, ≤ 60 min social media):
logging consumption raises the day total; exceeding the limit fails the period immediately.
**Implementation notes:** UI shows the remaining allowance ("1 of 2 left"); option `requireExplicitLog` (off by
default = a closed period with nothing logged counts as within limit, like quit trackers' auto-success);
when the target is 0 the editor suggests a quit tracker ([5.3]) instead.
**Data model:** `requireExplicitLog` in `habits.settings`.
**Acceptance criteria:** exceeding the limit flips today's status to failed live; a day with nothing logged
evaluates as done at day close unless `requireExplicitLog` is on (then missed).
**Tests:** evaluation fixtures for `lte` with and without the explicit-log requirement.

### T5.1.11 — Time-of-day sections (defaults)
**Priority:** P0 · **Size:** S · **Depends on:** T5.1.04
**Description:** Group habits into sections — Morning, Afternoon, Evening, Anytime — used to order the Today
list ([5.2]) and to propose default reminder times ([7.5]).
**Implementation notes:** seed the four defaults per user with deterministic ids `v5(user_id|'habit_section'|key)`
and localized names; optional time window per section (Morning 04:00–12:00…) to expand the current section
first; editor field "Section" (default Anytime).
**Data model:** new synced table `app.habit_sections (name, icon, sort_key, start_time, end_time,
archived_at)` + column `habits.section_id uuid` (arch §7.3).
**Acceptance criteria:** seeding on two devices yields the same ids (no duplicates after sync); the current
section is shown first on the Today list.
**Tests:** repository tests (idempotent seeding); widget test for the section picker.
**Notes:** Defaults are seeded by the `startHabits` startup task and again when the Habits tab opens (cloud accounts wait for the first pull so renamed defaults are never overwritten).

### T5.1.12 — Advanced options (skip policy, increments, prompts)
**Priority:** P0 · **Size:** S · **Depends on:** T5.1.07
**Description:** "Advanced" group in the editor: skip policy (skips are neutral / skips break the streak),
monthly streak freezes (field only; behaviour in [5.4]), early tolerance for slots, increment step and quick
values for measurable habits, "ask for a note & mood after check-in".
**Implementation notes:** defaults come from Settings › Habits ([8.3]); skip policy is applied to history as
currently set (it is a display/streak rule, not a schedule change → no revision).
**Data model:** `habits.settings` keys `incrementStep`, `quickValues`, `askNoteAfterCheckIn`.
**Acceptance criteria:** changing the skip policy immediately recomputes streaks in [5.2] views.
**Tests:** widget tests; unit test for defaults resolution.

### T5.1.13 — Schedule/goal changes: effective date & retro edit
**Priority:** P1 · **Size:** S · **Depends on:** T5.1.04, T5.1.08
**Description:** When schedule, target, comparison or unit change, ask "Apply from: today (default) / a chosen
date / all history". "All history" replaces all revisions with one (with a warning that past stats will change).
**Acceptance criteria:** choosing a past date re-evaluates only periods from that date on; "all history"
leaves exactly one revision.
**Tests:** repository tests for the three modes; evaluation fixture per mode.

### T5.1.14 — Pauses & vacation mode
**Priority:** P1 · **Size:** M · **Depends on:** T5.1.06, T5.1.04
**Description:** Pause one habit or all habits (vacation) for a date range (open-ended allowed) with an
optional reason. Paused periods are neutral: not due, never missed, never break streaks, excluded from
completion-rate denominators ([6.5]); reminders are suppressed ([7.2]).
**Implementation notes:** `habit_pauses` rows (`habit_id` NULL = all habits); pause sheet presets (today,
3 days, 1 week, until date, indefinitely); banner "Paused until …" with *Resume* (ends the pause yesterday);
a `done` logged inside a pause still counts (T5.1.06 precedence).
**Acceptance criteria:** a 20-day streak survives a 5-day vacation; resuming mid-pause re-activates today.
**Tests:** evaluation fixtures (habit-level, global, open-ended pauses); widget test for the pause sheet.

### T5.1.15 — Manage habits: archive, restore, reorder, custom sections
**Priority:** P1 · **Size:** S · **Depends on:** T5.1.04, T5.1.11
**Description:** "Manage habits" screen listing all habits (active, paused, archived) with drag-to-reorder,
move between sections, archive/unarchive and delete (Trash, with undo); custom sections can be created,
renamed, reordered, given an icon/time window, or deleted (their habits move to Anytime).
**Acceptance criteria:** archived habits disappear from Today and reminders but keep their stats reachable;
order and sections sync across devices.
**Tests:** widget tests for reorder/archive; repository tests.

### T5.1.16 — Habit templates
**Priority:** P1 · **Size:** S · **Depends on:** T5.1.07, T5.1.08
**Description:** Localized templates that prefill the editor: 15 push-ups daily (count ≥ 15 reps), drink water
(count ≥ 8 glasses), read (duration ≥ 20 min), meditate (duration ≥ 10 min), walk (numeric ≥ 5 km), sleep
before 23:00 (yes/no), stretch every hour 09:00–18:00 (slots), gym 3× per week (quota), ≤ 2 coffees (limit),
journal (yes/no). Quit templates live in [5.3].
**Implementation notes:** bundled JSON asset with l10n keys; "Browse templates" in the create flow and in
onboarding ([8.3]).
**Acceptance criteria:** every template yields a habit passing T5.1.03 validation; texts exist in EN/FR/AR.
**Tests:** unit test validating all templates.

### T5.1.17 — After-completion habits
**Priority:** P2 · **Size:** M · **Depends on:** T5.1.06, [2.1] (after-completion rules)
**Description:** Habits due N units after the last completion ("water the plants 3 days after the last time").
**Implementation notes:** due date = last done + N; the habit stays due (overdue) until done; each due window
is one period (due date → completion), flagged on time or late; streak = consecutive on-time windows (metrics
in [6.5]).
**Acceptance criteria:** completing late moves the next due date relative to the actual completion.
**Tests:** evaluation fixtures.
