# Section 6.5 — Habit Insights

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 5.1, 5.2, 5.4, 6.1, 6.2
> Architecture: §6.11 (habit & quit engine), §6.12 (stats engine), §7.3 (`habits`, `habit_revisions`, `habit_logs`, `habit_pauses`, `goals`)

## Goal

Give every build habit (for example "15 push-ups daily") the richest stats in the app, and give the
Habits section a portfolio view. That covers:

- habit strength, streaks, success rates and outcome counts
- target progress and volume ("total push-ups"), records, and partial and limit behaviour
- weekday and time-of-day patterns, recovery after misses, data completeness
- pace against goals and habit formation

Quit trackers get their own catalog in [6.6]; the section roll-up here reuses it.

## Scope

**In:** habit stats adapter, per-habit and section metrics (catalog below), Habit Insights screen,
Habits section Insights screen, fixtures including Loop parity.
**Out:** Period evaluation and check-in capture ([5.1], [5.2]); goals model ([5.4]); math, ledger,
streaks and strength ([6.1]); charts ([6.2]); quit metrics ([6.6]).

## Notation (used in all formulas below)

- **Unit u.** One period from [5.1]: a day `YYYY-MM-DD`, an intraday slot `YYYY-MM-DDTHH:mm`, or a
  quota period `week:…` / `month:…`. Each unit is evaluated with the `habit_revisions` row in force.
  - Its `PeriodResult.status` is one of: `done`, `partial`, `failed` (explicit "no"), `missed` (closed and
    unlogged), `skipped`, `excused`, `paused`, `pending`, `not_due`.
  - `frozen` is added by the streak engine ([6.1] T6.1.09).
- **Counts over a window.**
  - **E** = closed scheduled units.
  - **X** = excused + paused units, plus skipped units when the skip policy is `neutral`.
  - **S** = done, **P** = partial, **F** = failed, **M** = missed.
- **Success rate** = S ÷ (E − X).
- **Values.** **v_u** = achieved value in the unit (Σ `progress` logs, or 1 for a yes/no habit).
  **t_u** = target of the unit's revision. **Fulfilment** = min(1, v_u / t_u); limit habits use the
  Loop credit instead (see HB-H-16).
- **f** = expected units per day under the revision (daily = 1; MO/WE/FR = 3/7; 3×/week quota = 3/7;
  8 slots per day = 8).
- **Day boundary** = `habits.dayStartsAt` in the habit's zone, or floating (arch §9.1).

## Progress

- [x] T6.5.01 — Habit stats adapter
- [x] T6.5.02 — Strength score per habit
- [x] T6.5.03 — Streak metrics
- [x] T6.5.04 — Success & outcome metrics
- [x] T6.5.05 — Target & volume metrics
- [ ] T6.5.06 — Volume analytics & personal records
- [ ] T6.5.07 — Limit-habit metrics
- [ ] T6.5.08 — Consistency index
- [ ] T6.5.09 — Timing patterns (weekday, time of day, slots, spacing)
- [ ] T6.5.10 — Recovery, freezes & momentum
- [ ] T6.5.11 — Data completeness
- [ ] T6.5.12 — Goal pace & projection
- [x] T6.5.13 — Habits section core metrics
- [ ] T6.5.14 — Habits section extended metrics
- [ ] T6.5.15 — Advanced habit analytics
- [x] T6.5.16 — Habit Insights screen
- [x] T6.5.17 — Habits section Insights screen
- [x] T6.5.18 — Habit stats fixtures & Loop parity

## Tasks

### T6.5.01 — Habit stats adapter
**Priority:** P0 · **Size:** M · **Depends on:** [5.1] (period evaluation), [6.1] (T6.1.08 ledger, T6.1.12 loaders, T6.1.13 isolate)
**Description:** Assemble each habit's unit series across revisions, together with per-day aggregates.
All habit metrics consume this.
**Implementation notes:**
- `HabitUnitFact`: `{key, start, end, status, value, target, revisionId, logs}`.
- `HabitDayFact`: `{localDate, dueUnits, doneUnits, value, firstLogAt, lastLogAt, mood?}`.
- The `f` value is computed per revision.
- Quit habits (`kind = quit`) are routed to [6.6].
- Reuse [5.1] `PeriodResult`s. Do not re-evaluate periods here.
**Acceptance criteria:** a schedule change from daily to weekdays on 2026-09-15 evaluates earlier days
as daily and later weekend days as `not_due`.
**Tests:** fixture tests covering a revision change, pauses and intraday slots.
**Notes:** `domain/habit_resolution.dart` builds each habit's versions from `habit_revisions` (history never shifts), expands day / slot / quota units, evaluates them with the package's period evaluation and routes quit trackers to [6.6]. Success and outcome metrics use day-level results (slot roll-ups), like streaks and calendars. Tests: `habits_portfolio` table fixture (revision daily → weekdays, vacation pause, 8 slots, quota, limit).

### T6.5.02 — Strength score per habit
**Priority:** P0 · **Size:** S · **Depends on:** T6.5.01, [6.1] (T6.1.10)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-H-01 | Strength score | Loop EWMA: score_t = score_{t−1}·m + c_t·(1 − m), m = 0.5^(√f/13); c_t per goal type (boolean / at-least / at-most; skips carry the score over); m switches when f changes at a revision; Δ vs 30 and 365 days ago | units | line (day/week/month) | P0 |

**Acceptance criteria:** parity with `fixtures/stats/strength_loop.json` (±0.001); an at-most habit
starts at 1.0.
**Tests:** fixture tests.
**Notes:** HB-H-01 with per-revision frequency; package parity vectors (`strength_loop.json`) plus app-level parity (0.500 after 13 days, 0.798 after 30, at-most starts at 1.0) in `habits/habit_metrics_app_test.dart`. Today's open unit is scored like Loop does.

### T6.5.03 — Streak metrics
**Priority:** P0 · **Size:** S · **Depends on:** T6.5.01, [6.1] (T6.1.09), [6.2] (streak bars T6.2.08)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-H-02 | Current streak | streak engine; the open unit is neutral until it closes; the UI shows successful units, with the calendar span in the explain sheet | units | chip | P0 |
| HB-H-03 | Best streak | max streak length (and its date range) | units | chip | P0 |
| HB-H-04 | Top-10 streaks | streak list ordered by length, then recency | units | streak bars | P0 |

**Acceptance criteria:** quota habits count streaks in periods ("5-week streak"); frozen units show a
snowflake marker.
**Tests:** fixture tests.
**Notes:** HB-H-02…04; quota habits count periods (`unitKind: period`), frozen units are marked on the streak bars. Tests: fixtures + `habits/habit_metrics_app_test.dart`.

### T6.5.04 — Success & outcome metrics
**Priority:** P0 · **Size:** M · **Depends on:** T6.5.01, [6.2] (calendar heatmap T6.2.06, bars T6.2.04, KPI T6.2.02)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-H-05 | Success rate | S ÷ (E − X) over 7 / 30 / 90 / 365 days and all time; Wilson interval when n < 20 | units | KPI + Δ | P0 |
| HB-H-06 | Outcome counts | success / partial / failed / missed / skipped / excused / total | units | stacked bar | P0 |
| HB-H-07 | History buckets | successes and volume per week / month / quarter / year (Loop buckets 7/31/92/365 days) | units | bars | P0 |
| HB-H-08 | Calendar | per-day status (month and year grids) | units | calendar heatmap | P0 |
| HB-H-09 | Total repetitions | all-time count of manual completions (`done` / `progress` logs, source ≠ auto) — "votes for your identity" | logs | tile | P0 |

**Acceptance criteria:** for the canonical "15 push-ups" month, skipped units are excluded and missed
and failed units are shown separately.
- Setup: 30 scheduled days — 24 done at value 15, 3 partial at value 10, 2 missed, 1 skip.
- Expected: success rate = 24/29 = 82.8 %.
**Tests:** fixture tests.
**Notes:** HB-H-05…09; the push-ups month (24/29 = 82.8 %) is in `habit_pushups_month`; history buckets and calendars tested on `habits_portfolio`.

### T6.5.05 — Target & volume metrics
**Priority:** P0 · **Size:** M · **Depends on:** T6.5.04, [6.2] (bullet chart T6.2.07)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-H-10 | Target progress | for day / week / month / quarter / year: Σ v ÷ T_P, with T_P = t_day × scheduled days in P − t_day × skipped days (Loop TargetCard); quota habits: completions ÷ (N × periods in P, pro-rated) | units | bullet bars | P0 |
| HB-H-11 | Total volume | Σ v all-time and in P ("2 145 push-ups this year") | logs | tile + cumulative line | P0 |

**Acceptance criteria:** for the canonical month:
- Total volume = 24·15 + 3·10 = 390.
- T_P = 15·30 − 15·1 = 435.
- Target progress = 390 ÷ 435 = 89.7 %.
**Tests:** fixture tests.
**Notes:** HB-H-10/11; 390 / 435 = 89.7 % in `habit_pushups_month`.

### T6.5.06 — Volume analytics & personal records
**Priority:** P1 · **Size:** M · **Depends on:** T6.5.05, [6.2] (histogram T6.2.14)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-H-12 | Averages | mean v per scheduled day and per active day (v > 0) | units | tiles | P1 |
| HB-H-13 | Records | best day, best week, best month (by volume or completions), with dates; "new record" flag | units | trophy list | P1 |
| HB-H-14 | Value distribution | histogram of daily values; median and P85 | units | histogram | P1 |
| HB-H-15 | Partial rate & fulfilment | partial share = P ÷ (E − X); mean fulfilment = mean(min(1, v_u / t_u)) over non-excused units | units | stacked bar + tile | P1 |

**Acceptance criteria:** for the canonical month, partial share = 3/29 = 10.3 % and mean fulfilment =
(24 + 3·10/15) / 29 = 89.7 %.
**Tests:** fixture tests.

### T6.5.07 — Limit-habit metrics
**Priority:** P1 · **Size:** S · **Depends on:** T6.5.04
**Description:** Metrics for habits with `target_op = lte`, such as "≤ 2 coffees".
**Implementation notes:** how an unlogged closed day is treated follows `habits.auto_success`: success
with value 0, or `missed` ([6.1] T6.1.09).

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-H-16 | Within-limit days & excess | days with v ≤ limit ÷ (E − X); excess = Σ max(0, v − limit); Loop credit c = clamp(1 − (v − limit)/limit, 0, 1) | units | bars | P1 |

**Acceptance criteria:** with a limit of 2 and values {1, 2, 3, 5, 0}: within-limit days = 3/5, excess =
4, credits = {1, 1, 0.5, 0, 1}.
**Tests:** fixture tests.

### T6.5.08 — Consistency index
**Priority:** P1 · **Size:** S · **Depends on:** T6.5.04, [6.1] (T6.1.04 rolling windows)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-H-17 | Consistency index | Habitify-style three layers. L1 per scheduled unit: 1 if done, 0 if failed/missed, v/t if partial; skipped units count 0 only when skip policy = `breaks` (otherwise excluded); excused, paused and non-scheduled units excluded. L2: rolling mean of L1 over 30/60/90/180 days. L3: mean of L2 over the selected period | units | line + tile | P1 |

**Acceptance criteria:** the result is independent of how many non-scheduled days fall in the window;
it matches the fixture ±0.001.
**Tests:** fixture tests.

### T6.5.09 — Timing patterns (weekday, time of day, slots, spacing)
**Priority:** P1 · **Size:** M · **Depends on:** T6.5.04, [6.1] (T6.1.18 circular stats), [6.2] (punch card T6.2.09, rose T6.2.19, radar T6.2.18)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-H-18 | Weekday profile | success rate per weekday (option: per weekday per month) | units | bars / radar | P1 |
| HB-H-19 | Check-in time | circular mean and circular SD of `logged_at` (time of day); weekday × hour matrix of check-ins | logs | rose + punch card | P1 |
| HB-H-20 | Slot punctuality | intraday habits: share of check-ins within ±`stats.slotToleranceMinutes` (default 30) of the slot time | logs, units | KPI | P1 |
| HB-H-21 | Multi-times per day | per day: count vs target ("2/3"); mean and median spacing between consecutive check-ins | logs | dot strip + tile | P1 |

**Acceptance criteria:** check-ins at 23:30 and 00:30, with a day start of 04:00, belong to the same
habit day, and their mean time is 00:00.
**Tests:** fixture tests.

### T6.5.10 — Recovery, freezes & momentum
**Priority:** P1 · **Size:** S · **Depends on:** T6.5.03, T6.5.02, [5.4] (streak freezes)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-H-22 | Recovery ("never miss twice") | recovery rate = misses whose next scheduled unit is a success ÷ misses with a closed next unit; longest and mean gap (consecutive failed/missed units); comebacks = successes after ≥ 3 consecutive misses | units | KPI + tiles | P1 |
| HB-H-23 | Streak freezes | freezes used / granted this month and all time; list of protected units | units | tile + list | P1 |
| HB-H-24 | Score momentum | OLS slope of the strength score over the last 30 days → rising / stable / falling (\|slope\| < 0.1 pt/day = stable) | score series | chip | P1 |

**Acceptance criteria:** the sequence D M D M M D M gives recovery rate 2/3 (the final miss has no
closed next unit), longest gap 2 and 0 comebacks.
**Tests:** fixture tests.

### T6.5.11 — Data completeness
**Priority:** P1 · **Size:** S · **Depends on:** T6.5.04, [6.1] (T6.1.20)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-H-25 | Data completeness | logged ratio = units with any log ÷ closed scheduled units; unknown units = `missed` without any log; backfill share = logs created > 24 h after the unit ended | units, logs | tiles | P1 |
| HB-X-12 | Section data completeness | the same measures aggregated across habits | units | tiles | P1 |

**Acceptance criteria:** the card explains the difference between "unlogged" and "failed".
**Tests:** fixture tests.

### T6.5.12 — Goal pace & projection
**Priority:** P1 · **Size:** S · **Depends on:** T6.5.05, [5.4] (goals), [6.2] (line with pace line T6.2.03)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-H-26 | Pace & projection | goal G over [start, end]: elapsed fraction e = elapsed days ÷ total days; pace = G·e; on track when actual ≥ pace; projected end = actual + rate₂₈ × remaining days (rate₂₈ = mean daily value over the last 28 days); ETA = date the projection reaches G | goals, logs | line + pace line | P1 |

**Acceptance criteria:** goal = 10 000 push-ups in 2026. As of 2026-06-30 (day 181 of 365), actual is
4 500 and rate₂₈ is 30/day. Expected:
- pace = 4 959; the habit is behind.
- projected end = 4 500 + 30 × 184 = 10 020.
- ETA = 2026-12-31 (5 500 remaining ÷ 30/day = 183.3 → day 184 after June 30).
**Tests:** fixture tests.

### T6.5.13 — Habits section core metrics
**Priority:** P0 · **Size:** M · **Depends on:** T6.5.04, [6.6] (quit totals: T6.6.02, T6.6.03, T6.6.04)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-X-01 | Today progress | done ÷ due units today (all build habits) | units | ring | P0 |
| HB-X-02 | Perfect days | days where every due build habit is done; perfect-day streak (days with no due habits are neutral) | units | chip + calendar | P0 |
| HB-X-03 | Daily completion heatmap | per day: done ÷ due across habits | units | calendar heatmap (intensity) | P0 |
| HB-X-04 | Adherence trend | overall weekly success rate, Δ vs previous week, rolling 4-week line | units | line | P0 |
| HB-X-05 | Quit roll-up | Σ money saved, Σ units avoided, Σ life regained (population estimate), Σ abstinent days across quit trackers | [6.6] | tiles | P0 |

**Acceptance criteria:** archived habits are excluded from today and from trends after their archive
date, but remain in history.
**Tests:** fixture tests.
**Notes:** HB-X-01…05; archived habits leave today and trends after their archive date but stay in history (`presentation/habit_screens_test.dart`). The adherence trend now ends with the (elapsed) period so a past week compares with the week before it.

### T6.5.14 — Habits section extended metrics
**Priority:** P1 · **Size:** M · **Depends on:** T6.5.13, T6.5.10, [6.2] (radar T6.2.18)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-X-06 | Strength distribution | mean and median score; ranked bars; rising / falling habits (Δ over 30 days) | scores | ranked bars | P1 |
| HB-X-07 | At-risk list | streak at risk (needed completions > eligible units left in the period) or score drop > 10 points in 7 days | units, scores | list | P1 |
| HB-X-08 | Areas | success rate and volume by category (life area) | units | radar | P1 |
| HB-X-09 | Best & worst habits | ranking by success rate in P (n ≥ 5 closed units) | units | ranked bars | P1 |
| HB-X-10 | Check-in volume | logs per day / week | logs | bars | P1 |
| HB-X-11 | Weekday profile (all habits) | success rate per weekday across habits | units | bars | P1 |

**Acceptance criteria:** the at-risk list updates live after a check-in.
**Tests:** fixture tests.

### T6.5.15 — Advanced habit analytics
**Priority:** P2 · **Size:** M · **Depends on:** T6.5.08, T6.5.14, [6.1] (T6.1.24 correlation toolkit), [6.2] (matrix heatmap T6.2.21), [7.3] (notification history)
**Data model:** SRBAI survey answers (4 items on a 1–7 scale, monthly). The proposal is a
`habit_logs.kind = 'survey'` row with `value` = mean score and the item answers in `note` as JSON, or a
dedicated `habit_surveys` table.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| HB-H-27 | Formation / automaticity | days until rolling-30 success first stays ≥ 80 % for 14 days; shown against the Lally et al. 2010 band (18–254 days to reach 95 % of the automaticity plateau; ~66-day median is widely reported and labelled as such); optional monthly SRBAI score line | units, surveys | line + band | P2 |
| HB-H-28 | Reminder effectiveness | share of check-ins within 60 min after a reminder for that habit; median latency reminder → check-in | notifications, logs | histogram + KPI | P2 |
| HB-H-29 | Mood by outcome | mean mood on done vs not-done days (Mann–Whitney; non-causal wording) | logs | bars | P2 |
| HB-H-30 | Skip & excuse reasons | Pareto of skip/excuse notes (normalized text) | logs | Pareto | P2 |
| HB-X-13 | Co-occurrence | phi coefficient between the daily done flags of each habit pair (≥ 21 overlapping due days); matrix with BH-FDR significance marks | units | matrix heatmap | P2 |
| HB-X-14 | Portfolio | habits created / archived per month; share still active at 30 and 90 days after creation | habits | bars + tiles | P2 |

**Acceptance criteria:** no correlation is shown without passing the minimum-data rules and FDR; the
wording says "often together", never "causes".
**Tests:** fixture tests.

### T6.5.16 — Habit Insights screen
**Priority:** P0 · **Size:** M · **Depends on:** T6.5.02, T6.5.03, T6.5.04, T6.5.05, [6.1] (T6.1.16)
**Description:** Scope screen `/insights/habit/:id`, which is also reachable from the habit detail
screen in [5.2].
- **P0 content:**
  - Header: score ring with Δ, current and best streak, success rate (30 days), total repetitions.
  - Sections: Strength; Calendar (month/year); History; Target & volume; Streaks; Outcomes.
- **P1 adds:**
  - Records & distribution.
  - Patterns (weekday, time, slots, spacing).
  - Recovery & momentum.
  - Consistency.
  - Limit metrics (limit habits only).
  - Goal pace (when a goal exists).
  - Data completeness.
- **P2 adds:** Formation, Reminder effectiveness, Mood, Reasons.
**Acceptance criteria:** a yes/no habit hides volume cards; limit habits show limit metrics instead of
target progress; drill-down from any day opens its logs.
**Tests:** widget tests per goal type; goldens.
**Notes:** `habitLayout` (KPIs HB-H-01/02/03/05/09; Strength, Calendar, History, Target & volume, Streaks, Outcomes). Cards that don't apply to the habit's kind are hidden (`yesNoHabit` volume, `limitHabit` target); calendar days drill into the day's refs. Widget tests per goal type and goldens.

### T6.5.17 — Habits section Insights screen
**Priority:** P0 · **Size:** M · **Depends on:** T6.5.13, [6.1] (T6.1.16, T6.1.17)
**Description:** Scope screen `/insights/habits`.
- **P0:** HB-X-01 to HB-X-05, plus a per-habit mini table (score, streak, 30-day success rate).
- **P1:** HB-X-06 to HB-X-12.
- **P2:** HB-X-13 and HB-X-14.
**Acceptance criteria:** 30 habits × 5 years render within the [6.1] T6.1.23 budget.
**Tests:** widget tests; goldens.
**Notes:** `habitsLayout` with HB-X-01…05 and the per-habit mini table (`HabitMiniTable`: score, streak, 30-day success, each row opening the habit's Insights). Widget test and goldens; the 30 × 5 years budget is measured by T6.1.23.

### T6.5.18 — Habit stats fixtures & Loop parity
**Priority:** P0 · **Size:** M · **Depends on:** [6.1] (T6.1.15)
**Description:** Fixture datasets with hand-computed values:
- `habits_loop_parity`: Loop score vectors for daily, 3-per-8-days, weekly MO/TU, numeric at-least,
  numeric at-most and skipped days.
- `habit_pushups_month`: the canonical 15-push-ups month used above.
- `habits_portfolio`: 6 habits including a quota habit, an intraday 8×/day habit, a limit habit, a
  revision change and a vacation.
**Acceptance criteria:** the fixture runner passes for all P0 metrics.
**Tests:** provides fixtures for the tasks above.
**Notes:** Table fixtures `habit_pushups_month` and `habits_portfolio` cover every P0 habit metric except the strength line, whose Loop parity is asserted by the package (`strength_loop.json`) and app-level parity tests.
