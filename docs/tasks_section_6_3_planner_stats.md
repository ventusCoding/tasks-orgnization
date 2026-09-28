# Section 6.3 — Planner Insights

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 2.3, 3.1, 3.2, 3.3, 6.1, 6.2
> Architecture: §6.12 (stats engine), §6.9 (time grid), §7.3 (`tasks`, `task_occurrences`, `time_entries`, `activity_events`)

## Goal

Very detailed statistics for every Planner task: a single occurrence, a one-off task and a whole
recurring series. The Planner section as a whole gets the same depth. Coverage:

- **Execution:** done, skipped and missed occurrences.
- **Timing:** planned vs actual, and punctuality.
- **Planning quality:** estimation accuracy and reschedules.
- **Where the time goes:** time allocation, capacity and utilization.
- **Focus and patterns:** deep work, busiest hours and slot occupancy.

Metrics appear in four places: the task stats sheet, the series stats screen, the Planner Insights
screen, and overlays inside the planner views themselves.

## Scope

**In:** planner stats adapter, per-occurrence, per-series and section metrics (catalog below), plan
snapshot algorithm, UI (task sheet, series screen, Planner Insights, in-view overlays), fixtures.
**Out:** Math primitives, ledger, streaks, strength ([6.1]); chart widgets ([6.2]); occurrence resolution
and execution capture ([3.2]); focus/Pomodoro stats (→ [9.3]).

## Notation (used in all formulas below)

- **o** — one resolved occurrence (after overrides). **ps / pe** — planned start/end instants; **Dp = pe − ps**.
  All-day occurrences are excluded from timing metrics but included in counts.
- **Sessions** — `time_entries` of the occurrence; fallback: one session [`actual_start_at`, `actual_end_at`].
  **as** = first session start, **ae** = last session end, **Da** = Σ session lengths (gaps between sessions
  are pauses and are excluded). Unknown actual time is *unknown*, never 0.
- **done_at** = `completed_at`. **g** = on-time grace (`stats.graceMinutes`, default 5 min).
- **R = Da / Dp**, defined only when both are known and Dp ≥ 5 min.
- **Tracking modes** (arch §7.3):
  - `check` — counts in completion metrics.
  - `event` — excluded from completion and adherence metrics, but included in planned time,
    allocation and capacity.
  - `timer` — completion plus sessions.
- **Outcome classes**:
  - `doneOnTime` — done_at ≤ pe + g; for timer tasks, ae ≤ pe + g.
  - `doneLate`.
  - `partial` — completion_percent 1–99, or linked checklist progress < 100 % at done time.
  - `skipped` (with `skip_reason`).
  - `missed` — derived: check task unresolved after pe + `planner.missedGraceMinutes`.
  - `cancelled` — excluded from everything except cancellation counts.
  - `pending` / `future`.
- **Excused (X)** — the following are removed from series denominators ([6.1] T6.1.08):
  - skipped occurrences, when `stats.skipPolicy = neutral` (the default);
  - cancelled occurrences;
  - paused-series ranges;
  - optionally, global vacation (`stats.vacationExcusesPlanner`).
- **wh** — work hours per weekday (`planner.workHours`). **Capacity basis**: `stats.capacityBasis` =
  `workHours` | `dayWindow` | `custom`.

## Progress

- [x] T6.3.01 — Planner stats adapter & canonical occurrence facts
- [x] T6.3.02 — Per-occurrence timing & outcome metrics
- [ ] T6.3.03 — Per-occurrence planning & focus metrics
- [x] T6.3.04 — Series execution metrics
- [ ] T6.3.05 — Series quality & pattern metrics
- [ ] T6.3.06 — Series time-of-day consistency
- [x] T6.3.07 — Section execution & flow metrics (plan snapshot)
- [x] T6.3.08 — Capacity & utilization metrics
- [x] T6.3.09 — Time allocation by category
- [ ] T6.3.10 — Allocation by priority & tag, priority alignment
- [ ] T6.3.11 — Estimation accuracy metrics
- [ ] T6.3.12 — Punctuality & reschedule behaviour
- [ ] T6.3.13 — Patterns: busiest hours, best weekdays, slot occupancy
- [ ] T6.3.14 — Focus & balance metrics
- [ ] T6.3.15 — Completion goal streak
- [ ] T6.3.16 — Advanced planner metrics
- [x] T6.3.17 — Task stats sheet (occurrence & one-off task)
- [x] T6.3.18 — Series stats screen
- [x] T6.3.19 — Planner Insights screen
- [ ] T6.3.20 — In-view insights overlays
- [x] T6.3.21 — Planner stats fixtures

## Tasks

### T6.3.01 — Planner stats adapter & canonical occurrence facts
**Priority:** P0 · **Size:** M · **Depends on:** [6.1] (T6.1.08 ledger, T6.1.12 loaders, T6.1.13 isolate), [3.2] (occurrence resolver)
**Description:** Turn planner rows into one canonical fact per occurrence. All planner metrics are
computed from these facts, never from raw rows.
**Implementation notes:**
- `PlannerOccurrenceFact` fields:
  - `taskId`, `seriesId`, `occurrenceKey`
  - ps, pe, Dp, sessions, as, ae, Da, done_at
  - outcome class
  - `categoryId`, `priority`, `trackingMode`
  - `moves` (reschedule events for this occurrence), `skipReason`, `rating`, `completionPercent`,
    `createdAt` (of the task)
- Resolution uses the [3.2] resolver in the stats isolate over the requested window, plus one extra
  look-back week so that "moved out of the period" can be detected.
- Settings are read once per batch: g, missed grace, work hours, deep-work threshold, skip policy,
  capacity basis, category weights.
- Actual-time coverage is computed alongside the facts (see [6.1] T6.1.20).
**Data model:** `rescheduled` activity events must carry `occurrenceKey` (or `scope: series`),
`fromStartLocal`, `toStartLocal`, `fromDurationMinutes`, `toDurationMinutes` and `timeZone`.
Task `updated` events must carry before/after values of `start_local`, `duration_minutes`,
`recurrence`, `time_zone` and `is_all_day` (needed by the plan snapshot, T6.3.07).
**Acceptance criteria:** for the `planner_two_weeks` fixture, the facts equal the hand-written
expectations, including overrides, cancelled occurrences and timer pauses.
**Tests:** unit tests covering every outcome class and all three tracking modes.
**Notes:** `domain/planner_resolution.dart` (`PlannerResolver`) expands series with the recurrence engine in the stats isolate, applies occurrence overrides/cancellations, attaches time sessions, reschedule moves and tags, and hands `PlannerOccurrenceFact`s to the package calculators; the context loads the period ± one look-back week (+4 weeks for moved-out detection). Settings come once per batch from `StatsSettings.planner`. Tests: `planner/planner_occurrence_test.dart` (facts for every outcome class and tracking mode) and the `planner_two_weeks` table fixture.

### T6.3.02 — Per-occurrence timing & outcome metrics
**Priority:** P0 · **Size:** M · **Depends on:** T6.3.01, [6.2] (bars/bullet T6.2.04, T6.2.07)
**Description:** Timing and outcome metrics for a single occurrence or one-off task. They appear on the
task stats sheet and in drill-down lists.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-T-01 | Planned duration | Dp = pe − ps | occurrence | value | P0 |
| PL-T-02 | Actual duration | Da = Σ(ae_i − as_i), pauses excluded | time_entries / actual times | value | P0 |
| PL-T-03 | Duration variance & ratio | variance = Da − Dp; R = Da/Dp; over/under label when \|variance\| > max(5 min, 10 % Dp) | Dp, Da | bullet bar | P0 |
| PL-T-04 | Start delay | Δs = as − ps; on time if \|Δs\| ≤ g, early if Δs < −g, late otherwise | ps, as | value + dot | P0 |
| PL-T-05 | Finish delay / on-time completion | Δe = ae − pe (timer) or done_at − pe (check); on time if Δe ≤ g | pe, ae, done_at | value | P0 |
| PL-T-06 | Outcome | one outcome class (see Notation); skip reason shown | occurrence record | status chip | P0 |
| PL-T-07 | Overdue age | open check occurrence: now − pe, bucketed 1 / 7 / 14 / 30+ days | pe, status | aging chip | P0 |

**Acceptance criteria:**
- An occurrence planned 09:00–10:00 with two sessions, 09:07–09:40 and 09:45–10:12, gives:
  Da = 60 min, Δs = +7 min (late when g = 5), and Δe = +12 min.
- An occurrence with no sessions shows "Actual time not tracked", not 0.
**Tests:** fixture tests for each metric; boundary cases at exactly the grace value (on time) and at
g + 1 minute (late).
**Notes:** PL-T-01…07 in `planner_catalog.dart`; the task stats sheet selects the occurrence through the request `extra` (`?occurrence=<key>`). Tests cover the acceptance case, the g / g + 1 boundaries, "not tracked" and overdue buckets (`planner/planner_occurrence_test.dart`).

### T6.3.03 — Per-occurrence planning & focus metrics
**Priority:** P1 · **Size:** M · **Depends on:** T6.3.02, [6.2] (move timeline T6.2.13)
**Description:** Metrics about how an occurrence was planned, moved and executed. They extend the task sheet.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-T-08 | Reschedules | number of `rescheduled` events of this occurrence (series moves count once for each affected occurrence) | activity_events | move timeline | P1 |
| PL-T-09 | Reschedule distance | Σ \|toStart − fromStart\| over moves | activity_events | value | P1 |
| PL-T-10 | Net drift | final ps − first planned ps | activity_events | value | P1 |
| PL-T-11 | Snowball flag | moves ≥ 3 → "snowballing" badge | PL-T-08 | badge | P1 |
| PL-T-12 | Lead time | done_at − task created_at | tasks, occurrence | value | P1 |
| PL-T-13 | Start latency | as − task created_at | tasks, sessions | value | P1 |
| PL-T-14 | Planning horizon | first planned ps − task created_at (how far ahead it was planned) | tasks, events | value | P1 |
| PL-T-15 | Slot fit | overlap([as, ae], [ps, pe]) / Da; minutes spilled before ps and after pe | sessions, ps, pe | Gantt overlay | P1 |
| PL-T-16 | Focus sessions | count, total, mean length, number of pauses (gaps ≥ 2 min), longest uninterrupted block | time_entries | Gantt | P1 |
| PL-T-17 | Partial completion | completion_percent, or linked checklist progress ([4.3] roll-up) at done time | occurrence, checklist | ring | P1 |
| PL-T-18 | Self-rating & note | rating 1–5 and outcome_note displayed with the occurrence | occurrence | stars | P1 |

**Acceptance criteria:** a fixture with 3 moves (+1 d, +2 h, −30 min) gives PL-T-08 = 3,
PL-T-09 = 26.5 h and PL-T-10 = +1 d 1.5 h, and shows the snowball badge.
**Tests:** fixture tests; move-timeline golden.

### T6.3.04 — Series execution metrics
**Priority:** P0 · **Size:** M · **Depends on:** T6.3.01, [6.1] (T6.1.08 ledger, T6.1.09 streaks), [6.2] (calendar heatmap T6.2.06, line T6.2.03, streak bars T6.2.08)
**Description:** Execution metrics for a recurring task series, grouped by `series_id` across
"this & following" splits.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-S-01 | Expected occurrences | E from the ledger over the window (closed and open units counted separately) | recurrence, overrides | value | P0 |
| PL-S-02 | Done / missed / skipped / excused | D, M, K, X counts; M counted only on closed windows | ledger | stacked bar | P0 |
| PL-S-03 | Adherence (completion rate) | D / (E − X); rolling 4-week line; OLS slope per week (T6.1.04) | ledger | line + trend | P0 |
| PL-S-04 | Miss rate | (M + F) / (E − X) | ledger | value | P0 |
| PL-S-05 | Current & best streak | streak engine, unit = occurrence, skips neutral per policy | ledger | streak bars | P0 |
| PL-S-06 | Time invested | cumulative Σ Da (actual) and Σ Dp (planned) since series start | facts | cumulative line | P0 |
| PL-S-07 | Total done | all-time count of done occurrences | facts | value | P0 |
| PL-S-08 | Last done | date of last done occurrence and days since then | facts | value | P0 |
| PL-S-09 | Outcome calendar | per-day outcome of the series (done / late / missed / skipped / excused) | facts | calendar heatmap | P0 |

**Acceptance criteria:** the `planner_two_weeks` fixture series "Gym (MO, WE, FR)" with 1 skip,
1 miss and 4 done gives E = 6, X = 1, D = 4, adherence = 4/5 = 80 %, and miss rate = 20 %.
**Tests:** fixture tests; test that the series-split continuity keeps the streak across a split.
**Notes:** PL-S-01…09 in `planner_catalog.dart` over the package ledger/streak engines; the series scope groups every task row sharing `series_id` ("this & following" splits). Tests: the Gym acceptance in the `planner_two_weeks` fixture and `planner/planner_series_test.dart` (streak across a split, time invested, outcome calendar).

### T6.3.05 — Series quality & pattern metrics
**Priority:** P1 · **Size:** M · **Depends on:** T6.3.04, [6.1] (T6.1.10 strength), [6.2] (box plot T6.2.14, punch card T6.2.09)
**Description:** Quality and pattern metrics for a series.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-S-10 | Skip rate & reasons | K / E; Pareto of `skip_reason` | facts | Pareto | P1 |
| PL-S-11 | Start timeliness | on-time starts / started; median and P85 of Δs | facts | box plot per month | P1 |
| PL-S-12 | On-time completion rate | doneOnTime / D | facts | value + trend | P1 |
| PL-S-13 | Top-10 streaks | streak list ordered by length | ledger | streak bars | P1 |
| PL-S-14 | Series strength | Loop EWMA with f = expected occurrences per day (e.g. MO/WE/FR → 3/7; every 90 min in 08–20 → 9); f > 1 aggregates per day | ledger | line | P1 |
| PL-S-15 | Duration stability | mean, median, SD, CV of Da; median R as estimation bias ("usually takes 1.3× plan") | facts | box plot | P1 |
| PL-S-16 | Weekday profile | adherence per weekday | ledger | bar / punch card | P1 |
| PL-S-17 | Completion hour profile | distribution of done_at (or as) by hour | facts | bar | P1 |
| PL-S-18 | Series reschedule behaviour | share of occurrences moved ≥ 1×, mean moves per occurrence, mean postpone distance | events | bar | P1 |
| PL-S-19 | Rule-change markers | annotations at each split / rule change, with before/after adherence | tasks (series) | line annotations | P1 |

**Acceptance criteria:** strength for a daily series matches [6.1] parity vectors; weekday adherence
excludes weekdays the rule never schedules.
**Tests:** fixture tests; goldens for the series quality section.

### T6.3.06 — Series time-of-day consistency
**Priority:** P2 · **Size:** S · **Depends on:** T6.3.05, [6.1] (circular stats T6.1.18), [6.2] (rose chart T6.2.19)
**Description:** When the series is actually done.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-S-20 | Time-of-day consistency | circular mean and circular SD of `as` (or done_at) | sessions | rose chart | P2 |
| PL-S-21 | Start drift | circular mean of signed (as − ps), wrapped to ±12 h | sessions | value | P2 |

**Acceptance criteria:** starts at 23:50 and 00:10 give a mean of 00:00 and an SD below 15 min.
**Tests:** fixture tests.

### T6.3.07 — Section execution & flow metrics (plan snapshot)
**Priority:** P0 · **Size:** M · **Depends on:** T6.3.01, [6.1] (T6.1.11 event primitives)
**Description:** Completion rate against the plan *as it stood at the start of the period* (TickTick's
definition). The plan is rebuilt by replaying activity events, so moving tasks out of the week does not
inflate the rate.
**Implementation notes:**
- **Plan snapshot at period start `P.start`:**
  1. Take the candidate occurrences: those currently in P, plus those in P as of `P.start` that later
     moved out.
  2. For each candidate, replay `rescheduled` events and task `updated` time-field changes whose
     `occurred_at ≤ P.start`. This gives its planned start as of `P.start`.
  3. `planned(P)` = the candidates whose snapshot start falls in P, excluding occurrences cancelled
     before `P.start`.
- **Unplanned additions:** occurrences of tasks created after `P.start` for dates in P, reported
  separately.
- **In-progress periods:** use "to date", i.e. planned occurrences with snapshot ps ≤ now.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-X-01 | Completion rate (vs plan) | \|planned(P) ∩ done in P\| / \|planned(P)\| (check tasks) | facts, events | KPI + bars | P0 |
| PL-X-02 | Done vs planned per day | per-day done and planned counts | facts | grouped bars | P0 |
| PL-X-03 | Unplanned & moved | unplanned additions; moved-out (planned but final ps ∉ P); moved-in | facts, events | tiles | P0 |
| PL-X-04 | Backlog flow | tasks created vs completed per week; open backlog = unscheduled tasks + open overdue occurrences | tasks, facts | paired bars | P0 |
| PL-X-05 | On-time completion rate | doneOnTime / done | facts | KPI | P0 |
| PL-X-06 | Overdue now | open overdue count; aging buckets 1 / 7 / 14 / 30+ days; newly overdue per week | facts | bars + aging | P0 |

**Acceptance criteria:** in the fixture, a task planned for Monday and moved on Tuesday to next week counts as
planned-not-done and moved-out for this week. It also counts as planned for next week, because it had
already moved when next week started. Unplanned additions do not change PL-X-01.
**Tests:** snapshot-algorithm unit tests covering: a move before the period starts, a move during the
period, a series edit, and a cancellation.
**Notes:** PL-X-01…06 over the package `planSnapshot` (replays `rescheduled` events up to the period start; series-scope moves expand per affected occurrence). The resolver reads the planner feature's payload keys (`fromStart/toStart/fromDuration/toDuration/occurrenceKey/scope`); task `updated` events are loaded but series edits are logged as series-scope `rescheduled` events, which the snapshot uses. Tests: `planner/planner_section_test.dart` (move before/during the period, series edit, cancellation, unplanned addition) + fixture.

### T6.3.08 — Capacity & utilization metrics
**Priority:** P0 · **Size:** M · **Depends on:** T6.3.01, [6.2] (bars with overlay T6.2.04)
**Description:** How full the schedule is compared with the time actually available.
**Implementation notes:**
- **Capacity per day:** cap_d = minutes of the capacity basis on that weekday, minus unavailable blocks.
  - The basis is work hours by default, or the view's day window, or custom.
  - Unavailable blocks are `event` tasks in categories marked "unavailable".
- **Planned load:** L_d = Σ Dp of the day's timed occurrences, unclipped, with overlapping tasks counted
  separately. All-day tasks don't count. Planned utilization uses the same sum clipped to the capacity
  windows, so it can exceed 100 % when tasks overlap.
- **Actual utilization:** shown only when actual-time coverage is ≥ 60 %; otherwise the card shows the
  coverage and a hint.
**Data model:** an optional category flag for "unavailable / time off" (proposal:
`categories.counts_as_unavailable boolean default false`) or a settings list of such categories.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-X-07 | Capacity | Σ cap_d over the period | settings, tasks | value | P0 |
| PL-X-08 | Planned utilization | Σ Dp (clipped) / capacity | facts | stacked bar + capacity line | P0 |
| PL-X-09 | Actual utilization | Σ Da (clipped) / capacity | facts | bar | P0 |
| PL-X-10 | Overbooked days | days where L_d > cap_d; count, list, overbooked minutes = L_d − cap_d | facts | bars + badges | P0 |
| PL-X-11 | Remaining free time | today/this week: capacity − planned remaining (from now) | facts | tile | P0 |
| PL-X-12 | Planned vs actual hours | Σ Dp vs Σ Da per day and per category | facts | grouped bars | P0 |

**Acceptance criteria:** with work hours 09–17 on Mon–Fri and 10 h planned on Wednesday, Wednesday is
flagged overbooked by 120 min and weekly planned utilization is correct to 0.1 %.
**Tests:** fixture tests covering weekend days without capacity, and tasks crossing work-hour boundaries.
**Notes:** Capacity = work hours (`planner.workHours/workDays`) minus `event` blocks in `counts_as_unavailable` categories; planned utilization clips to the capacity windows; days without capacity are never counted as overbooked (their load still shows in the chart). Tests: `planner/planner_capacity_test.dart` (acceptance 120 min, weekend, boundary-crossing tasks, free time from now).

### T6.3.09 — Time allocation by category
**Priority:** P0 · **Size:** S · **Depends on:** T6.3.01, [6.2] (donut T6.2.05, stacked bars T6.2.04)
**Description:** Where the time goes. The stacked-area trend variant ([6.2] T6.2.16) is added when that
P1 chart exists; until then the trend uses stacked bars.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-X-13 | Time by category | Σ Da by category; falls back to Σ Dp, labeled "planned", when coverage < 60 %; share of total | facts | donut | P0 |
| PL-X-14 | Category trend | weekly Σ minutes per category | facts | stacked area (P1) / stacked bars (P0) | P0 |
| PL-X-15 | Event vs task time | planned minutes of `event` vs `check`/`timer` occurrences | facts | 100 % bar | P0 |

**Acceptance criteria:** shares sum to 100 % (±0.1); uncategorized time appears as its own slice.
**Tests:** fixture tests.
**Notes:** PL-X-13 uses Σ Da when actual-time coverage ≥ 60 %, else Σ Dp with the "planned" note; uncategorized time is its own slice; PL-X-14 uses stacked bars until T6.2.16. Tests in `planner/planner_capacity_test.dart`.

### T6.3.10 — Allocation by priority & tag, priority alignment
**Priority:** P1 · **Size:** S · **Depends on:** T6.3.09, [2.3] (tags), [6.2] (treemap T6.2.20)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-X-16 | Time by priority | Σ minutes per priority 0–4 | facts | 100 % bar | P1 |
| PL-X-17 | Time by tag | Σ minutes per tag (a multi-tag task counts fully for each tag; UI labels the overlap) | facts, entity_tags | bars | P1 |
| PL-X-18 | Priority alignment | share of time and completion rate for high (3–4) vs low (0–2) priority | facts | 100 % bars | P1 |
| PL-X-19 | Allocation treemap | category → task minutes | facts | treemap | P1 |
| PL-X-20 | Recurring vs one-off share | minutes and completions from recurring series vs one-off tasks | facts | donut | P1 |

**Acceptance criteria:** tag totals show an "overlapping" note whenever any task has more than one tag.
**Tests:** fixture tests.

### T6.3.11 — Estimation accuracy metrics
**Priority:** P1 · **Size:** M · **Depends on:** T6.3.02, [6.1] (T6.1.02 log-ratio helpers), [6.2] (scatter T6.2.15, histogram T6.2.14)
**Description:** How good the user is at estimating durations. This addresses the planning fallacy:
for example, students estimated 33.9 days for a thesis that took 55.5.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-X-21 | Estimation bias | b = exp(median(ln R)) − 1 → "You underestimate by 23 %" (b > 5 %) or "overestimate" (b < −5 %) | facts (R defined) | KPI | P1 |
| PL-X-22 | MAPE | mean(\|Da − Dp\| / Dp) | facts | KPI | P1 |
| PL-X-23 | Suggested buffer | P80(R) − 1 → "Add +x % to estimates" | facts | tile | P1 |
| PL-X-24 | Planned vs actual scatter | points (Dp, Da) with y = x and a ±20 % band; by category filter | facts | scatter | P1 |
| PL-X-25 | Planned duration distribution | histogram of Dp; mean and median task length | facts | histogram | P1 |
| PL-X-26 | Accuracy by category | bias and MAPE per category | facts | bars | P1 |

**Acceptance criteria:** at least 10 occurrences with defined R are required (otherwise insufficient).
With R values {1.2, 1.5, 1.0, 1.3, 1.4, 1.1, 1.25, 1.6, 0.9, 1.35}: bias = exp(median ln R) − 1 = √(1.25·1.3)
− 1 ≈ +27.5 %, MAPE = 28 %, and suggested buffer = P80(R) − 1 = +42 %.
**Tests:** fixture tests.

### T6.3.12 — Punctuality & reschedule behaviour
**Priority:** P1 · **Size:** M · **Depends on:** T6.3.03, T6.3.07, [6.2] (punch card T6.2.09, Pareto T6.2.05)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-X-27 | Punctuality rate | on-time starts / started occurrences | facts | KPI | P1 |
| PL-X-28 | Start delay distribution | mean, median, P85 of Δs; by hour × weekday | facts | box plot + punch card | P1 |
| PL-X-29 | Reschedule share | occurrences moved ≥ 1× / occurrences in P | events | KPI | P1 |
| PL-X-30 | Moves per task & hours postponed | mean moves per moved occurrence; Σ forward postponement hours | events | bars | P1 |
| PL-X-31 | Procrastination index | share of occurrences whose final ps > first planned ps | events | KPI + trend | P1 |
| PL-X-32 | Skip rate & reasons | skipped / scheduled; Pareto of reasons | facts | Pareto | P1 |

**Acceptance criteria:** moves to an *earlier* time don't count as postponement in PL-X-30 but do count
in PL-X-29.
**Tests:** fixture tests.

### T6.3.13 — Patterns: busiest hours, best weekdays, slot occupancy
**Priority:** P1 · **Size:** M · **Depends on:** T6.3.07, [6.2] (punch card T6.2.09, matrix heatmap T6.2.21)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-X-33 | Busiest hours | 7 × 24 matrix of planned minutes, actual minutes, or completions (toggle) | facts | punch card | P1 |
| PL-X-34 | Best working days | completion rate and hours per weekday | facts | bars | P1 |
| PL-X-35 | Slot occupancy | per (weekday, slot of the current view size): planned% = weeks with a planned task overlapping the slot / weeks in P; used% likewise with sessions | facts | matrix / week-table overlay | P1 |
| PL-X-36 | Dead slots | slots inside wh with planned% = 0 over ≥ 4 weeks | PL-X-35 | overlay | P1 |
| PL-X-37 | Most productive hours | completion rate by the hour of ps | facts | bar | P1 |

**Acceptance criteria:** slot occupancy recomputes when the user changes slot size (e.g. 30 → 60 min)
without reloading data.
**Tests:** fixture tests; overlay golden (T6.3.20).

### T6.3.14 — Focus & balance metrics
**Priority:** P1 · **Size:** M · **Depends on:** T6.3.03, T6.3.08

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-X-38 | Deep-work blocks | count and hours of uninterrupted actual blocks ≥ `stats.deepWorkMinutes` (default 60); same-task sessions with gaps < 2 min are merged | sessions | bars | P1 |
| PL-X-39 | After-hours time | Σ Da outside wh; weekend work minutes | sessions, settings | bars | P1 |
| PL-X-40 | Timer usage | timed sessions count, mean session length, share of done occurrences with sessions | sessions | tiles | P1 |
| PL-X-41 | Actual-time coverage | done occurrences with sessions / done occurrences (data-quality companion) | facts | tile | P1 |

**Acceptance criteria:** a 50-minute session followed 1 minute later by a 20-minute session of the same
task counts as one 70-minute deep-work block.
**Tests:** fixture tests.

### T6.3.15 — Completion goal streak
**Priority:** P1 · **Size:** S · **Depends on:** T6.3.07, [5.4] (goals), [6.1] (streaks T6.1.09)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-X-42 | Goal streak | consecutive days (or weeks) reaching N completions, where N comes from a `goals` row (scope global, metric `completions`, period day/week); days off (no capacity) and vacation are neutral | facts, goals | chip + streak bars | P1 |

**Acceptance criteria:** a weekend without capacity does not break a daily goal streak.
**Tests:** fixture tests.

### T6.3.16 — Advanced planner metrics
**Priority:** P2 · **Size:** M · **Depends on:** T6.3.08, T6.3.14

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| PL-X-43 | Fragmentation index | within wh: free gaps = wh minus planned blocks; index = 1 − largest free block / total free time; count and mean length of gaps ≥ 15 min | facts, settings | Gantt + value | P2 |
| PL-X-44 | Context switches | category changes between consecutive sessions in a day; switches per tracked hour | sessions | line | P2 |
| PL-X-45 | Productivity score | 100 · Σ_c (w_c · minutes_c) / (4 · Σ_c minutes_c), with user weights w_c ∈ {0…4} per category (RescueTime-style); unweighted categories excluded | facts, settings | gauge + line | P2 |
| PL-X-46 | Planning horizon distribution | histogram of (first planned ps − created_at) | tasks, events | histogram | P2 |

**Data model:** category weights are stored in `user_settings.stats.categoryWeights`, so no schema
change is needed.
**Acceptance criteria:** a day with a single uninterrupted free block has fragmentation 0; the
productivity score is hidden until at least one category is weighted.
**Tests:** fixture tests.

### T6.3.17 — Task stats sheet (occurrence & one-off task)
**Priority:** P0 · **Size:** M · **Depends on:** T6.3.02, [6.1] (T6.1.16 framework), [3.2] (occurrence sheet)
**Description:** A "Stats" tab in the occurrence/task sheet.
- P0 content: PL-T-01 to PL-T-07 plus a mini planned-vs-actual bar.
- P1 additions: PL-T-08 to PL-T-18 (move timeline, focus sessions, slot fit Gantt).
- "See series stats" link for recurring tasks.
**Acceptance criteria:** opens in < 150 ms; values update live when a timer stops; every value has an
explain entry.
**Tests:** widget tests with fixture facts; goldens (light/dark, RTL).
**Notes:** `TaskStatsPanel(taskId, occurrenceKey)` (exported by `features/stats/insights.dart`) renders PL-T-01…07 with the PL-T-03 planned-vs-actual bullet, no period selector, and "See series stats" for recurring tasks; `/insights/task/:id?occurrence=<key>` shows it full screen. TODO(integration): the planner's occurrence sheet adds a "Stats" tab embedding `TaskStatsPanel` (planner-owned file). Timer stops invalidate through `time_entries` table updates. Tests: `presentation/planner_screens_test.dart`, goldens `screen_goldens_test.dart`.

### T6.3.18 — Series stats screen
**Priority:** P0 · **Size:** M · **Depends on:** T6.3.04, [6.1] (T6.1.16)
**Description:** Scope screen `/insights/series/:seriesId`.
- **P0:**
  - Header KPIs: adherence with delta, current and best streak, time invested, total done.
  - Outcome calendar.
  - Adherence trend with rolling mean and slope.
  - Done / missed / skipped bars.
- **P1:**
  - Strength line.
  - Weekday profile.
  - Duration stability box plot.
  - Timeliness.
  - Top-10 streaks.
  - Reschedule behaviour.
  - Rule-change annotations.
- **P2:** time-of-day rose.
**Acceptance criteria:** the period selector and compare toggle work; drill-down from any calendar day
opens that occurrence.
**Tests:** widget tests; goldens.
**Notes:** `seriesLayout` (KPIs PL-S-03/05/06/07; outcome calendar, adherence trend with rolling mean + slope, done/missed/skipped bars) on `/insights/series/:seriesId`; a calendar day opens the drill sheet of its occurrences, each opening the occurrence. Tests: `presentation/planner_screens_test.dart`, goldens.

### T6.3.19 — Planner Insights screen
**Priority:** P0 · **Size:** L · **Depends on:** T6.3.07, T6.3.08, T6.3.09, [6.1] (T6.1.16, T6.1.17)
**Description:** Scope screen `/insights/planner`, organized into sections.
- **KPI row:** completion rate vs plan, on-time rate, planned vs actual hours, planned utilization,
  overdue now.
- **Execution:** PL-X-01 to PL-X-06.
- **Capacity:** PL-X-07 to PL-X-12.
- **Time allocation:** PL-X-13 to PL-X-15; P1 adds PL-X-16 to PL-X-20.
- **Planning quality** (P1): PL-X-21 to PL-X-26 and PL-X-29 to PL-X-32.
- **Timing & patterns** (P1): PL-X-27, PL-X-28, PL-X-33 to PL-X-37.
- **Focus & balance** (P1): PL-X-38 to PL-X-42.
- **Advanced** (P2): PL-X-43 to PL-X-46.
- **Filters:** category, tag, priority, tracking mode.
**Acceptance criteria:** a one-year period renders within the [6.1] T6.1.23 budget; each chart drills
into the list of occurrences behind it.
**Tests:** widget tests; fixture-driven screen test; goldens.
**Notes:** `plannerLayout`: KPI row PL-X-01/05/12/08/06, Execution, Capacity and Allocation sections; filters category, tag, priority and tracking mode (the shared filter bar's status field). Fixture-driven screen test (`planner_two_weeks`) and goldens; the one-year budget is measured by T6.1.23.

### T6.3.20 — In-view insights overlays
**Priority:** P1 · **Size:** M · **Depends on:** T6.3.08, T6.3.13, [3.3] (grid painter, overlays), [3.4] (week table)
**Description:** Show insights where the user plans.
- **Week table:** an optional slot-occupancy heatmap overlay (PL-X-35/36), drawn by the time-grid
  painter as a translucent layer.
- **Day headers:** a utilization bar and an overbooked badge (PL-X-10), with a tap to explain.
- **Task tiles:** a long-press preview shows the series' mini-stats (adherence, current streak).
**Acceptance criteria:** the overlay toggle is saved in the view config; drawing it keeps the week table
within the [3.4] frame budget.
**Tests:** goldens of the week table with overlay; performance check.

### T6.3.21 — Planner stats fixtures
**Priority:** P0 · **Size:** M · **Depends on:** [6.1] (T6.1.15)
**Description:** A `planner_two_weeks` dataset (Europe/Paris zone, week start MO, work hours 09–17) with:
- 3 series (Gym MO/WE/FR, Standup weekdays 09:30, Reading daily 21:00);
- 12 one-off tasks;
- timer sessions, reschedules (one of them snowballing), skips with reasons, one DST-free week, and
  one cancelled occurrence.
Expected values are hand-computed for every P0 metric, and for P1 metrics as they are implemented.
**Acceptance criteria:** the fixture runner passes; the dataset is documented in
`fixtures/stats/README.md`.
**Tests:** this task provides the fixtures used by the tests above.
**Notes:** Table fixture `app/test/features/stats/fixtures/planner_two_weeks.json` (from `fixtures/stats/planner_two_weeks.json`) now has expectations for all 31 P0 planner metrics; scenario tests in `test/features/stats/planner/` cover grace boundaries, snapshot moves, capacity boundaries and series splits.
