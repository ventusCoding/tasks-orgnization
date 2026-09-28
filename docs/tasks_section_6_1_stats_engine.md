# Section 6.1 — Stats Engine & Metric Foundations

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.3, 1.4, 2.1, 2.3, 3.2, 4.3, 5.1, 5.3
> Architecture: §6.12 (stats engine), §6.11 (habit period model), §6.8 (recurrence), §9.1 (time), §9.6 (budgets), §10

## Goal

Build the shared machinery behind every Insights screen: the pure-Dart math in `packages/everslot_metrics`,
a precise period and comparison model, the metric registry, the expected-occurrence and streak algorithms,
the habit-strength score, event-log primitives, data loaders over the local DB, isolate execution with
caching, and the stats screen framework. With this in place, sections 6.3–6.7 only *declare* metrics
(ID, formula, chart, priority) and layouts. Everything runs offline from the local Drift database.

> **Just-in-time note:** several P0 tasks here — period model (T6.1.05), expected occurrences (T6.1.08),
> streak engine (T6.1.09) and strength score (T6.1.10) — are also consumed by the habit/planner UIs in
> [3.2], [5.2], [5.3] and [8.1]. Implement each one when its first consumer needs it, even if that
> happens before the rest of Section 6.

## Scope

**In:** `everslot_metrics` modules (descriptive, rates & intervals, time series & trends, circular
statistics, group tests, correlation & multiple testing, survival, forecasting, streaks, strength,
occurrence ledger, status intervals), period model, metric registry & formatting, data loaders,
isolate/caching, minimum-data rules, stats fixtures, stats screen framework, Insights tab shell,
data-quality plumbing, catalog generation, performance tests, optional rollups.
**Out:** Chart widgets ([6.2]); per-section metric catalogs ([6.3]–[6.7]); habit period evaluation
(`PeriodResult`, built in [5.1] and reused here); occurrence resolution (built in [3.2]); settings UI
for stats defaults ([8.3]).

## Progress

- [x] T6.1.01 — `everslot_metrics` package structure & result types
- [x] T6.1.02 — Descriptive statistics & distributions
- [x] T6.1.03 — Rates, proportions & Wilson intervals
- [x] T6.1.04 — Time-series utilities: bucketing, rolling windows, EWMA, OLS & Theil–Sen trends
- [x] T6.1.05 — Period model & comparisons
- [x] T6.1.06 — Metric registry & definition format
- [x] T6.1.07 — Units, formatting & delta presentation
- [x] T6.1.08 — Expected-occurrences ledger (adherence denominators)
- [x] T6.1.09 — Streak engine
- [x] T6.1.10 — Habit-strength score (Loop-compatible EWMA)
- [x] T6.1.11 — Status-interval & event-log primitives
- [x] T6.1.12 — Stats data loaders over Drift
- [ ] T6.1.13 — Isolate execution, caching & invalidation
- [x] T6.1.14 — Minimum-data, confidence & honesty rules
- [ ] T6.1.15 — Stats fixture framework & canonical datasets
- [ ] T6.1.16 — Stats screen framework & "explain this metric" sheet
- [ ] T6.1.17 — Insights tab shell & navigation
- [x] T6.1.18 — Circular statistics for clock times
- [x] T6.1.19 — Group-comparison tests (Mann–Whitney, Kruskal–Wallis)
- [ ] T6.1.20 — Data-quality metrics plumbing
- [ ] T6.1.21 — Metric glossary, catalog generation & registry lint
- [ ] T6.1.22 — Per-scope card layout customization
- [ ] T6.1.23 — Stats performance suite
- [x] T6.1.24 — Correlation toolkit & false-discovery control
- [x] T6.1.25 — Kaplan–Meier survival
- [x] T6.1.26 — Monte Carlo forecasting
- [ ] T6.1.27 — Local rollups (`stats_cache`)

## Tasks

### T6.1.01 — `everslot_metrics` package structure & result types
**Priority:** P0 · **Size:** S · **Depends on:** [1.1] (package skeleton), [2.1] (LocalDate/LocalDateTime types)
**Description:** Set up the module layout and the result types that every metric returns. This keeps
NaN, divide-by-zero and "not enough data" from leaking into the UI.
**Implementation notes:**
- Modules under `packages/everslot_metrics/lib/src/`: `descriptive.dart`, `rates.dart`, `time_series.dart`,
  `trend.dart`, `circular.dart`, `group_tests.dart`, `correlation.dart`, `survival.dart`, `forecast.dart`,
  `streaks.dart`, `strength.dart`, `occurrence_ledger.dart`, `status_intervals.dart`, plus the barrel
  `everslot_metrics.dart`. Dependencies: `everslot_recurrence` (local date/time types) and `collection` only.
  No Flutter.
- `sealed class Stat<T>` with three cases: `Value<T>(value, {sampleSize, interval})`,
  `Insufficient(requiredN, haveN, reasonKey)` and `NotApplicable(reasonKey)`. Never return `NaN` or `Infinity`.
- Units: durations as `Duration` or whole minutes (`int`), rates as `double` in [0, 1], money as `Decimal`
  (from `package:decimal`) or as integer minor units. Percentages are formatted only in the UI.
- Randomness (Monte Carlo, Theil–Sen subsampling) always comes from an injected seeded `Random`.
- Every public function documents its formula in dartdoc using the notation of the Section 6 files.
**Acceptance criteria:** `dart test` passes; no public API returns `double.nan`; the coverage gate
(≥ 95 %) is active for the package.
**Tests:** unit tests for the `Stat` helpers (map, fold, combine) and for safe division.
**Notes:** Pure math lives in `packages/everslot_metrics` (`src/stat.dart`, barrel `everslot_metrics.dart`); verified 2026-09-26 — package suite green (157 tests). The app consumes it from `features/stats`.

### T6.1.02 — Descriptive statistics & distributions
**Priority:** P0 · **Size:** M · **Depends on:** T6.1.01
**Description:** Core descriptive statistics used by almost every metric.
**Implementation notes:**
- Covers count, sum, mean, median, mode, min, max and range. Variance and SD come in both sample and
  population forms, computed with Welford's online algorithm. Also: coefficient of variation (CV = SD/mean,
  `NotApplicable` when the mean is 0), IQR, MAD, 10 % trimmed mean, and the geometric mean of ratios.
- Percentiles use linear interpolation between closest ranks (Hyndman–Fan type 7, the same as NumPy's
  default and Excel `PERCENTILE.INC`). Named helpers: P50, P70, P80, P85, P90, P95.
- Histogram binning has three modes: fixed width (e.g. 5-minute bins), Freedman–Diaconis (width =
  2·IQR·n^(−1/3), clamped to 5–40 bins) and explicit edges. Values on a boundary go into the upper bin,
  except the last edge.
- Box-plot summary: five numbers plus outliers beyond 1.5·IQR, with the whisker at the most extreme
  non-outlier value.
- Log-ratio helpers `medianLogRatio` and `exp(median(ln R)) − 1`, used for estimation bias ([6.3]).
**Acceptance criteria:** results match reference values stored in `fixtures/stats/descriptive.json`
(computed once with NumPy/R) within 1e-9.
**Tests:** reference-dataset tests, including empty input, n = 1, ties and a single repeated value.
**Notes:** Implemented in `packages/everslot_metrics/lib/src/descriptive.dart` (reference values in `fixtures/stats/descriptive.json`); verified 2026-09-26 with the package suite.

### T6.1.03 — Rates, proportions & Wilson intervals
**Priority:** P0 · **Size:** S · **Depends on:** T6.1.01
**Description:** Safe ratios, confidence intervals for small samples, and period-over-period deltas.
**Implementation notes:**
- `rate(successes, trials)`: 0/0 gives `NotApplicable`. Weighted rates are supported.
- **Wilson score interval** at 95 % (z = 1.96):
  - center = (p̂ + z²/2n) / (1 + z²/n)
  - half-width = z/(1 + z²/n) · √(p̂(1 − p̂)/n + z²/4n²)
- Deltas:
  - absolute Δ = cur − prev
  - relative %Δ = (cur − prev)/|prev|; when prev = 0, the result is `NotApplicable("new")` and the UI shows "new"
  - rates are compared in **percentage points** (pp)
- Pro-rated expectations (e.g. a quota over a partial period) return fractional denominators; rounding
  happens only in the UI.
**Acceptance criteria:** Wilson(0 of 10) is [0, 0.278]; Wilson(10 of 10) is [0.722, 1]; Wilson(5 of 10) is
[0.237, 0.763] (±0.001).
**Tests:** table-driven unit tests, including n = 0 and fractional denominators.
**Notes:** Implemented in `packages/everslot_metrics/lib/src/rates.dart`; verified 2026-09-26 with the package suite (Wilson acceptance vectors included).

### T6.1.04 — Time-series utilities: bucketing, rolling windows, EWMA, OLS & Theil–Sen trends
**Priority:** P0 · **Size:** M · **Depends on:** T6.1.02, T6.1.05
**Description:** Turn event data into regular series and measure their trend.
**Implementation notes:**
- **Bucketing** by day, week, month, quarter or year. It uses the user's week start and zone, and the
  day-start hour where one applies (T6.1.05). Gap filling: count series fill with 0; rate series fill
  with `null` (no denominator, so there is no point).
- **Rolling windows** (7/28/30/90/180/365): a trailing window ending at each bucket. Emit `null` when less
  than 50 % of the window has a denominator.
- **EWMA:** s_t = α·x_t + (1 − α)·s_{t−1}, with α taken either directly or from a half-life h as
  α = 1 − 0.5^(1/h). The same helper serves the cumulative series.
- **OLS slope:**
  - b = Σ(x−x̄)(y−ȳ)/Σ(x−x̄)²
  - SE = √(Σres²/(n−2)) / √Σ(x−x̄)²
  - t = b/SE, with a two-sided p-value from a Student-t CDF with n−2 degrees of freedom (regularized
    incomplete beta, implemented in the package)
- **Theil–Sen slope:** the median of the pairwise slopes (y_j − y_i)/(x_j − x_i) for i < j. Above 1 000
  points, use a seeded subsample of 200 000 pairs. Theil–Sen is the default when the series has outliers
  (more than 5 % beyond 1.5·IQR).
- **Trend flag:** "rising" or "falling" requires n ≥ 8 buckets and p < 0.05 for OLS; with Theil–Sen, the
  bootstrap CI must exclude 0. Slopes are reported per week, e.g. "+2.1 pp/week".
**Acceptance criteria:** exact fixture values for a daily series with DST days; `y = 3x + noise` yields
b ≈ 3 with p < 0.001; Theil–Sen ignores 10 % injected outliers (|b − 3| < 0.1).
**Tests:** unit tests with fixed seeds; week-start variants (MO/SA/SU).
**Notes:** Implemented in `packages/everslot_metrics/lib/src/time_series.dart` and `trend.dart`; verified 2026-09-26 with the package suite.

### T6.1.05 — Period model & comparisons
**Priority:** P0 · **Size:** M · **Depends on:** T6.1.01, [2.3] (time utilities), [1.5] (profile: zone, week start)
**Description:** One period model shared by every metric, so that "this week", "last 30 days" and
"vs previous period" mean exactly the same thing on every screen.
**Implementation notes:**
- `StatsPeriod` (sealed) has these cases:
  - `today`, `yesterday`
  - `thisWeek`, `lastWeek`, `thisMonth`, `lastMonth`, `thisQuarter`, `thisYear`, `lastYear`
  - `rolling(days: 7 | 28 | 30 | 90 | 365)`
  - `allTime` (from the first data point of the scope)
  - `custom(from, to)`
- Each resolves to `[startLocalDate, endLocalDate]` plus instants in the user's zone.
- **Day boundaries:**
  - planner stats use civil midnight;
  - habit stats use `habits.dayStartsAt` (arch §8.5);
  - quit stats use exact instants for durations and local dates for day counts.
- **Comparisons:**
  - the previous equivalent period is the previous calendar week/month/quarter/year, or the N days
    immediately before a rolling or custom period;
  - **to-date mode** is the default while the current period is in progress (Mon–Wed vs Mon–Wed), so a
    partial period is never compared with a full one;
  - year-over-year (same period last year) is P1 and uses the same API;
  - months of different lengths are compared on **rates or per-day averages**, never on raw sums (the UI
    labels which one).
- **Auto granularity:** ≤ 14 days gives daily buckets, ≤ 120 days weekly, ≤ 2 years monthly, otherwise
  quarterly. The user can override it.
- Reads the `stats` settings namespace (default period, compare mode, week-start override) via [8.3].
**Acceptance criteria:**
- `thisWeek` is correct for week start MO, SA and SU.
- `lastMonth` on 2026-03-31 is February 2026.
- Rolling 7 days across a DST change contains exactly 7 local dates.
- With a day start of 04:00, an event at 01:30 belongs to the previous local date.
**Tests:** unit tests across zones (Europe/Paris, America/New_York, Africa/Tunis), leap years and DST
transitions.
**Notes:** Period model, day boundaries and comparisons live in `packages/everslot_metrics/lib/src/period.dart` (acceptance vectors in the package suite); the app reads `stats.defaultPeriod`, `compareWithPrevious` and `weekStartOverride` through `StatsSettings` (`statsSettingsProvider`) and applies them in every scope context (`test/features/stats/engine/period_settings_test.dart`: MO/SA/SU, DST rolling window, 04:00 day start).

### T6.1.06 — Metric registry & definition format
**Priority:** P0 · **Size:** M · **Depends on:** T6.1.01, T6.1.05
**Description:** A single registry in which every metric is declared once, with enough metadata to
compute, format, chart, explain and test it.
**Implementation notes:**
- `MetricDefinition<T>` fields:
  - identity and scope: `id` (e.g. `PL-S-03`, `HB-H-01`) and `scope`. Scopes: `task`, `series`,
    `planner`, `checklistItem`, `checklist`, `checklists`, `habit`, `habits`, `quit`, `global`.
  - text keys: `titleKey`, `shortTitleKey`, `descriptionKey`, `formulaKey` (plain-language formula)
  - presentation: `unit` (count, duration, percent, pp, ratio, currency, days, score), `direction`
    (higherIsBetter / lowerIsBetter / neutral, which drives delta colors), `defaultChart` (a [6.2] chart
    type) and `formatter`
  - behavior: `minSample` (T6.1.14), `priority` (P0/P1/P2), `requires` (the tables and settings it reads)
    and `compute(MetricInput) → MetricResult`
- `MetricResult` fields: `stat`, `previous`, `delta`, `deltaPct`, `interval`, `sampleSize`, `series?`,
  `breakdown?` (e.g. by category or weekday), `exclusions` (e.g. `{skipped: 3, paused: 2}`) and
  `explanationArgs`.
- `MetricRegistry.byScope(scope)` and `byId(id)`. Section catalogs register themselves in
  `features/stats/application/catalog/*.dart`.
**Acceptance criteria:** duplicate IDs fail at startup in debug; each metric can be computed from its
declared inputs alone (verified by the fixture framework, T6.1.15).
**Tests:** registry unit tests; a lint test (see T6.1.21) iterates over all definitions.
**Notes:** `MetricDefinition` (domain) + `MetricRegistry` (application, catalogs in `application/catalog/*_catalog.dart`); l10n keys derive from the id (`statsMetric<Stem>Title|Desc|Formula`); `formatter` is `StatFormat` keyed by `unit`; results carry `value/previous/comparison/chart/spark/exclusions/args/drill` (`breakdown` = the chart model). Tests: `test/features/stats/engine/metric_registry_test.dart` (duplicates, lookups, ARB keys, layouts, every scope computes on an empty DB).

### T6.1.07 — Units, formatting & delta presentation
**Priority:** P0 · **Size:** S · **Depends on:** T6.1.06, [1.3] (l10n, design tokens)
**Description:** Consistent, locale-aware display of every metric value and delta.
**Implementation notes:**
- Durations use `intl` in two forms: long ("1 h 25 min") and compact ("1:25"). Days are shown as
  "3 d 4 h" for live counters.
- Other formats:
  - percent, and pp for rate deltas
  - compact large numbers (12.3 k)
  - currency from the tracker's currency code (quit)
  - the "≈" prefix for estimates
  - ICU plurals ("1 day", "5 days")
- Delta chips show an arrow, a value and a color taken from the metric's `direction`. The color is never
  the only signal: the arrow and sign are always present.
- Western vs Arabic-Indic digits follow the locale setting, and number formatting is RTL-safe.
**Acceptance criteria:** golden snapshots of the formatter output for EN/FR/AR, and a lowerIsBetter
metric shows a green down-arrow.
**Tests:** unit tests per unit type and locale.
**Notes:** `StatFormat` (`presentation/format/stat_format.dart`): long/compact durations, days, %, pp, compact numbers, currency, score, clock, bytes, "≈" estimates, digits per `appearance.arabicDigits`; deltas carry arrow + sign + good/bad from `direction` and speak "percentage points". Snapshot tests per locale in `test/features/stats/format/`.

### T6.1.08 — Expected-occurrences ledger (adherence denominators)
**Priority:** P0 · **Size:** L · **Depends on:** T6.1.03, T6.1.05, [2.1], [3.2] (occurrence resolver), [5.1] (period evaluation)
**Description:** Compute how many times something *should* have happened in a window, which of those
units actually happened, and how each one is classified. This gives every adherence, miss and on-time
metric the same denominators.
**Implementation notes:**
1. **Window:** W = [max(series start, period start), min(now, series end, period end)].
   - Planner series are grouped by `series_id` across "this & following" splits.
   - Habits use `habit_revisions`, so each unit is evaluated with the rule version that was in force.
2. **Candidates by rule type:**
   - *Fixed calendar rules* come from the recurrence engine anchored at the series start, so "every 3 days"
     never shifts with the period.
   - *Interval rules* (minutely/hourly with a daily window) produce distinct intraday units.
   - *Count goals* ("8 glasses per day") are **one** unit per day with a target of 8, not 8 time points.
   - *Quota rules* ("N per week/month") produce one period unit with E = N · eligibleDays/periodDays,
     pro-rated when the stats window or excused days clip the period.
3. **Excused units (X):**
   - pauses and vacation (`habit_pauses`), `excuse` logs, and skips when the skip policy is `neutral`
   - cancelled occurrences (EXDATE) and paused series
   - these are counted separately and removed from denominators
4. **Matching:** match by `occurrence_key` first.
   - *Fallback for logs without a key* (imports, legacy data): assign each completion to the nearest
     unmatched unit whose tolerance window contains it. Windows: the same local day for day-level
     rules, and [unit − earlyTolerance (default 30 min), next unit start) for intraday rules.
   - *Extra completions* become `bonus`: they are shown, but adherence is capped at 100 %.
5. **Classification of each unit:**
   - `onTime`, `late`, `partial`
   - `excused`, `missed` (window closed with no match), `failed` (explicit "not done")
   - `pending` (window still open), `future`
6. **Ledger outputs:**
   - counts: E, D (done), X, M, F, P, bonus
   - adherence = D/(E − X)
   - miss rate = (M + F)/(E − X)
   - on-time rate = onTime/D
7. **Reuse, not re-implementation:**
   - for habits, the ledger is assembled from [5.1] `PeriodResult`s;
   - for planner series, it comes from [3.2] resolved occurrences;
   - this task owns the shared aggregation, tolerance matching, pro-rating and classification.
**Acceptance criteria:**
- **Weekly-rule case.** Setup: rule weekly MO,TU starting Tue 2026-09-01, period = September 2026, and
  "now" = 2026-09-30 23:00. A pause on Sep 14–15 excuses both of those units, and 6 completions exist.
  Expected: E = 9, X = 2, D = 6, M = 1, adherence = 6/7.
- **Quota case.** A 3×/week quota over a window of Wed–Sun with 1 excused day gives E = 3·4/7 ≈ 1.714.
- **Rule change.** A rule change mid-month evaluates each unit with the right version.
**Tests:** fixture-driven tests for every rule type, DST days, late/bonus completions, and quota pro-rating.
**Notes:** Implemented in `packages/everslot_metrics/lib/src/occurrence_ledger.dart` (habits: `ledgerUnitsFromPeriods`; planner series: `plannerLedgerUnits`); verified 2026-09-26 with the package suite. The app assembles the units in `features/stats/domain/*_resolution.dart`.

### T6.1.09 — Streak engine
**Priority:** P0 · **Size:** M · **Depends on:** T6.1.08
**Description:** One implementation of streaks for habits and planner series, following consistent rules
for skips, vacations, flexible schedules and freezes.
**Implementation notes:**
- **Unit:** an occurrence for fixed rules; a period (week/month) for quota rules. For example, "3×/week"
  streaks count successful weeks, even when individual days failed.
- **Success rules:**
  - boolean: `done`
  - multi-times per day: count ≥ daily target
  - numeric `gte`: value ≥ target
  - numeric `lte` (limit): value ≤ limit. A closed day with nothing logged counts as success (value 0)
    only when `habits.auto_success = true`; otherwise it is `missed`.
- **Neutral units** (neither extend nor break the streak):
  - non-scheduled days
  - skips (when the skip policy is `neutral`)
  - excused, paused and vacation units
  - the *current open unit* (today, or the current period until it closes)
- **Break:** a scheduled unit that closed as `failed`, `missed` or `partial`. A partial unit earns partial
  credit in the score but breaks the streak.
- **Two length policies:** (1) `successfulUnits` (the default in the UI) and (2) `calendarSpan`, which
  includes bridged neutral units (the Loop style). Both are stored, and the explain sheet shows both.
- **Outputs:** the current streak, the best streak, a list of all streaks (start, end, length) and the
  top-10 streaks.
- **At-risk flag:**
  - fixed rules: the current unit is due, not yet done, and closes within the "at-risk" horizon (default:
    today);
  - quota rules: the completions still needed exceed the eligible days left in the period.
- **Freezes:** each calendar month grants `habits.freezes_per_month` freezes, which do not carry over.
  A miss consumes one automatically (oldest first), and a protected unit is labeled `frozen` (neutral).
  An optional rule "1 miss allowed per 7 units" is P2 and behind a flag.
- **Backfills:** a pure recomputation over the ledger. Caching (T6.1.13) handles invalidation from the
  edited date onwards.
**Acceptance criteria:**
- The pattern D D S D X D M D (S = skip, X = excused, M = missed) gives a current streak of 1 and a best
  streak of 4 successful units; the calendar span of that best streak is 6.
- A weekly quota with 2 of 3 done and 1 day left is at-risk = false; with 0 days left it is true.
**Tests:** fixture tests covering every rule and policy combination; property test: the current streak is
never greater than the best streak.
**Notes:** Implemented in `packages/everslot_metrics/lib/src/streaks.dart`; verified 2026-09-26 with the package suite.

### T6.1.10 — Habit-strength score (Loop-compatible EWMA)
**Priority:** P0 · **Size:** M · **Depends on:** T6.1.08
**Description:** A clean-room implementation of the Loop Habit Tracker score formula. Loop is GPL, so
implement from the documented formula and do not copy its code. [6.5] uses it for habits and [6.3] for
planner series (P1).
**Implementation notes:**
- **Update rule:** m = 0.5^(√f/13) and score_t = score_{t−1}·m + c_t·(1 − m).
  - f = repetitions ÷ interval length: daily = 1; 3 per 8 days = 0.375; weekly MO,TU = 2/7;
    3×/week quota = 3/7.
  - The half-life is 13/√f days. Iterate day by day from the first scheduled day to today.
- **c_t variants:**
  - *boolean:* c_t = min(1, YES entries in the last `den` days ÷ `num`), where num/den is the rule's
    frequency. For non-daily boolean habits, double both num and den to smooth irregular schedules
    (Loop behaviour).
  - *numeric at least:* c_t = min(1, rolling sum over the frequency window ÷ target).
  - *numeric at most:* c_t = clamp(1 − (sum − target)/target, 0, 1), with the initial score set to 1.0.
  - *skipped, excused or paused days:* not scored, so score_t = score_{t−1}.
- For f > 1 (several units per day), aggregate by day: c_t = done_in_day ÷ expected_in_day.
- **Outputs:** the full daily series, the current score, and deltas vs 30 and 365 days ago.
- **Optional projection** of 30 days of maintenance at the current completion rate.
**Acceptance criteria:**
- A daily habit completed every day from a score of 0 reaches 0.798 after 30 updates, 0.959 after 60
  and 0.992 after 90 (±0.001). After 13 updates it is 0.500.
- For f = 0.375, m = 0.967876 (±1e-6).
- Skipped days leave the score unchanged.
**Tests:** parity vectors in `fixtures/stats/strength_loop.json`; property test: the score always stays
in [0, 1].
**Notes:** Implemented in `packages/everslot_metrics/lib/src/strength.dart` (parity vectors `fixtures/stats/strength_loop.json`); verified 2026-09-26 with the package suite.

### T6.1.11 — Status-interval & event-log primitives
**Priority:** P0 · **Size:** M · **Depends on:** T6.1.01, [2.3] (activity events), [4.3] (status events)
**Description:** Generic functions that turn an ordered status-event log into intervals, time-in-status
totals, snapshots and boundary counts. Checklist flow metrics ([6.4]) and planner reschedule/plan-snapshot
metrics ([6.3]) are built on these.
**Implementation notes:**
- Input: `(entityId, occurredAt, from, to, payload)`. Events are sorted by `occurredAt`, with `rev` as the
  tie-breaker. If an entity has no `created` event, its row `created_at` is used as an implicit first event.
- Outputs:
  - per-entity status intervals, and Σ time per status within any clip window
  - first entry and last exit for each status
  - reopen count (completed → other)
  - `stateAt(instant)`
  - boundary counts for day ends: A(d) = created by d, S(d) = first left `todo` by d, F(d) = in
    `completed` at d
- Deleted entities stop counting at `deleted_at`, and "removed from scope" is exposed for burn-up.
  Entities moved between containers are split by container using `moved` payloads.
- Durations are measured in instants; day-end sampling uses the user's zone.
**Acceptance criteria:** for a 5-item fixture log with a reopen, a deletion and a move, the time-in-status
totals and the A/S/F counts on 7 consecutive days match the hand-computed expectations.
**Tests:** unit tests with out-of-order events, identical timestamps and missing `created` events.
**Notes:** Implemented in `packages/everslot_metrics/lib/src/status_intervals.dart`; verified 2026-09-26 with the package suite.

### T6.1.12 — Stats data loaders over Drift
**Priority:** P0 · **Size:** L · **Depends on:** [1.4], [3.1], [4.1], [5.1]
**Description:** Typed, range-bounded queries that load the minimum data each scope needs into compact
DTOs that can be sent to an isolate (records and lists of primitives, never Drift row classes).
**Implementation notes:**
- `features/stats/data/stats_data_source.dart` with one loader per domain:
  - **PlannerFacts:** tasks (id, series_id, recurrence, start_local, duration, zone, category, priority,
    tracking_mode, status, created_at); occurrence records (overrides, status, completed_at, actual
    times, completion_percent, skip_reason, rating); time_entries; task activity events (`created`,
    `updated`, `rescheduled`, `completed`, `reopened`, `deleted`).
  - **ChecklistFacts:** items (id, checklist_id, parent_id, status, created_at, completed_at, deleted_at,
    due_local, follow_up_at); `checklist_item` activity events; attachment aggregates; `checklist_runs`.
  - **HabitFacts:** habits, `habit_revisions`, `habit_pauses`, and `habit_logs` (kind, value, logged_at,
    local_date, occurrence_key, mood, intensity, resisted, trigger, place, coping, duration_seconds,
    created_at).
  - **NotificationFacts** (P2 consumers): notifications (source, fire_at, acted_at, action).
- Queries exclude tombstones, except where deletion events are needed. Record the
  `EXPLAIN QUERY PLAN` output for each query in the file's doc comment; required indexes:
  `(user_id, habit_id, local_date)`, `(user_id, entity_type, entity_id, occurred_at)`, and task
  `(user_id, start_local)`.
**Acceptance criteria:** loading a year of data for 30 habits takes < 80 ms on the reference device; no
full table scans appear in the query plans.
**Tests:** DAO tests on an in-memory database with seeded fixtures; a query-plan assertion test.
**Notes:** `data/stats_data_source.dart` maps rows into the isolate records of `domain/stats_inputs.dart` (never row classes); deleted checklist items stay for history. The local DB is single-user, so the per-feature indexes omit `user_id` (residual filter). `stats_data_source_test.dart` seeds every table, checks the mapping and asserts through a query interceptor + `EXPLAIN QUERY PLAN` that the large tables are never scanned (notifications compare the ISO text so `idx_notifications_fire` applies). The 80 ms device budget is measured by the performance suite (T6.1.23).

### T6.1.13 — Isolate execution, caching & invalidation
**Priority:** P0 · **Size:** M · **Depends on:** T6.1.06, T6.1.12
**Description:** Compute metrics off the UI isolate, share the loaded data within a screen, and
invalidate precisely when the underlying data changes.
**Implementation notes:**
- `StatsComputeService.computeBatch(scope, period, metricIds)` loads the facts once, then runs all the
  requested computations in one `Isolate.run`. Loading happens through Drift, which is already off the
  UI isolate.
- Results go into an LRU cache (default 200 entries) keyed by
  `(metricId, scopeId, periodKey, compareMode, dataVersion)`.
- `dataVersion` is a per-domain counter (planner, checklists, habits, notifications), bumped by Drift
  `tableUpdates` for the relevant tables and debounced by 300 ms.
- Riverpod: an auto-dispose family provider `metricsBatchProvider(request)` with a keep-alive of 60 s after
  the last listener. Results that arrive after the screen is disposed are dropped.
**Acceptance criteria:** reopening a screen within 60 s hits the cache (< 50 ms); adding a habit log
invalidates only habit metrics; the UI thread never blocks for more than 8 ms during computation.
**Tests:** unit tests with a fake clock and fake table-update stream; a widget test proving stale results
are discarded.

### T6.1.14 — Minimum-data, confidence & honesty rules
**Priority:** P0 · **Size:** S · **Depends on:** T6.1.03, T6.1.06
**Description:** Global rules that stop the app from showing misleading numbers.
**Implementation notes:**
- **Defaults** (a metric may override them):

  | Metric kind | Hidden below | Shown with a Wilson "±" below |
  |---|---|---|
  | Rates | 3 closed units | 20 units |
  | Means and medians | n = 3 | — |
  | P85 | n = 10 | — |
  | P95 | n = 20 | — |

  | Metric kind | Needs at least |
  |---|---|
  | Trend | 6 buckets (a significance label needs 8) |
  | Day-of-week effects | 4 weeks |
  | Correlations | 21 paired days and 7 days per group |
  | Monte Carlo | 30 days of history and 10 completions |
  | Kaplan–Meier | 2 attempts |
- **Display rules:**
  - An insufficient metric renders as a greyed card, e.g. "Needs 4 more check-ins".
  - A zero denominator shows "—", never 0 %.
  - Estimates carry "≈", and population-based numbers carry a "population estimate" label.
  - Exclusions are always explained ("3 skipped days excluded").
- The rules live in `MetricDefinition.minSample` and are enforced by the framework (T6.1.16). Metric
  code never handles them ad hoc.
**Acceptance criteria:** every metric in the registry declares or inherits a rule; fixtures with n below
the threshold produce `Insufficient` with the correct counts.
**Tests:** unit tests per rule; registry lint (T6.1.21) checks that a rule is present.
**Notes:** Rules live in `MinDataRules` (package) and `MetricDefinition.minSample`, applied by the engine (`applyMinimumData`); each definition also exposes `minDataGuard` (`rule` / `calculator` / `exempt`) — rates must declare a rule or opt out explicitly, enforced by the registry test. Cards: greyed "Needs N more", "—" for zero denominators, "≈" for estimates, exclusions listed (`MetricCard`, `ExplainSheet`).

### T6.1.15 — Stats fixture framework & canonical datasets
**Priority:** P0 · **Size:** M · **Depends on:** T6.1.06, T6.1.12
**Description:** A data-driven test harness that makes "super detailed stats" verifiable. Each fixture
declares its data, a clock, a zone and expected metric values.
**Implementation notes:**
- Format: `fixtures/stats/<name>.json` with the fields `now`, `zone`, `weekStart`, `settings`, `tables`
  (rows per table), and `expect` (a list of `{metricId, scopeId, period, value | interval | series,
  tolerance}`).
- A runner seeds an in-memory Drift database, runs the registry and compares the results. Failures print
  a readable diff.
- Canonical datasets, each with hand-computed expectations:
  - `planner_two_weeks` (used by [6.3])
  - `checklist_flow_small` (used by [6.4])
  - `habits_loop_parity` (used by [6.5])
  - `quit_smoking_90_days` (used by [6.6])
  - `overview_week` (used by [6.7])
**Acceptance criteria:** each section catalog has at least one fixture per P0 metric; CI runs all fixtures
in < 20 s.
**Tests:** this task *is* the harness; include self-tests for its tolerance handling.

### T6.1.16 — Stats screen framework & "explain this metric" sheet
**Priority:** P0 · **Size:** L · **Depends on:** T6.1.07, T6.1.13, T6.1.14, [6.2] (chart foundations T6.2.01, KPI tile T6.2.02)
**Description:** The reusable screen scaffold that every Insights scope uses.
**Implementation notes:**
- **Scope header:** entity name, color and icon, plus a KPI row of 3–4 headline metrics with deltas.
- **Period selector:** chips for Today, Week, Month, Quarter, Year and All, a "Rolling" menu
  (7/28/30/90/365) and a Custom date-range picker. There is also a compare toggle for the previous period.
- **Filters:** category and tag filters reuse the [2.3] filter model.
- **Layout:** declared with `StatsLayout`, made of sections, which hold items
  (`metricId, chartVariant, span: full | half`). The grid is responsive: 1 column on phones, 2 on
  tablets. Sections are collapsible, with skeleton loading and error and insufficient states.
- **Drill-down:** tapping a chart element opens a filtered list of the occurrences, items or logs behind
  it, via typed payloads from [6.2].
- **"ⓘ Explain" sheet:** what the metric measures, its formula in plain words and symbols, the inputs and
  exclusions for the current view, the sample size and interval, and sources (for health content).
**Acceptance criteria:** a new scope screen needs only a `StatsLayout` declaration; changing the period
updates every card within one frame after the batch completes; the explain sheet shows the actual
exclusion counts.
**Tests:** widget tests with fake metric results (value, insufficient, error); goldens for the scaffold.

### T6.1.17 — Insights tab shell & navigation
**Priority:** P0 · **Size:** S · **Depends on:** T6.1.16, [1.3] (router)
**Description:** The Insights tab root, with segments Overview · Plan · Lists · Habits · Quit, and deep
links `/insights/:scope/:id` (arch §6.4).
**Implementation notes:** the last selected segment and period are remembered locally. Entry points from
the entity screens (task, series, checklist, item, habit and quit tracker) push the scoped screen. The
Overview content is built in [6.7].
**Acceptance criteria:** every canonical insights deep link opens the right scope and period; the back
navigation stack is sane.
**Tests:** router unit tests; a widget test for segment switching.

### T6.1.18 — Circular statistics for clock times
**Priority:** P1 · **Size:** S · **Depends on:** T6.1.02
**Description:** Correct averaging of times of day (the mean of 23:00 and 01:00 is 00:00, not 12:00).
**Implementation notes:**
- Convert each time to an angle: θ = 2π·minuteOfDay/1440, counting minutes from the configured day start.
- Circular mean = atan2(Σ sin θ, Σ cos θ).
- Resultant length R̄ = √((Σcos)² + (Σsin)²)/n.
- Circular SD = √(−2 ln R̄), converted back to minutes with ×1440/2π.
- Drift = the circular mean of the signed differences (actual − planned), wrapped to (−720, 720] minutes.
**Acceptance criteria:** mean(23:00, 01:00) = 00:00; identical times give an SD of 0; uniform times give
R̄ ≈ 0 and are reported as "no consistent time".
**Tests:** unit tests, including wrap-around at the day start.
**Notes:** Implemented in `packages/everslot_metrics/lib/src/circular.dart`; verified 2026-09-26 with the package suite.

### T6.1.19 — Group-comparison tests (Mann–Whitney, Kruskal–Wallis)
**Priority:** P1 · **Size:** S · **Depends on:** T6.1.02
**Description:** Non-parametric tests for "is Monday really different?" style insights.
**Implementation notes:**
- Mann–Whitney U, with average ranks for ties, a tie-corrected normal approximation for p, and
  rank-biserial correlation as the effect size.
- Kruskal–Wallis H, with the tie correction and p from χ² with k − 1 degrees of freedom, and ε² as the
  effect size.
- Both require the minimum-data rules (T6.1.14).
**Acceptance criteria:** results match reference values from R (`wilcox.test`, `kruskal.test`) stored in
the fixtures (±1e-4).
**Tests:** reference-dataset unit tests.
**Notes:** Implemented in `packages/everslot_metrics/lib/src/group_tests.dart` (R reference values in `fixtures/stats/reference_tests.json`); verified 2026-09-26.

### T6.1.20 — Data-quality metrics plumbing
**Priority:** P1 · **Size:** S · **Depends on:** T6.1.08, T6.1.12
**Description:** Shared computations that report how complete and trustworthy the user's data is.
[6.5] and [6.7] display them.
**Implementation notes:**
- **Logged ratio:** units that have any log ÷ expected closed units.
- **Unknown units:** units classified `missed` with no log of any kind.
- **Backfill share:** logs whose `created_at` is more than 24 h after the end of their unit.
- **Actual-time coverage** (planner): done occurrences that have tracked sessions ÷ done occurrences.
- **Sync caveat:** a pending outbox count > 0 adds the note "some changes from other devices may be
  missing".
**Acceptance criteria:** fixture values match; the card links to the affected units.
**Tests:** unit tests on fixtures.

### T6.1.21 — Metric glossary, catalog generation & registry lint
**Priority:** P1 · **Size:** S · **Depends on:** T6.1.06, T6.1.15
**Description:** A searchable in-app glossary of every metric. A dev command generates
`docs/generated/metrics_catalog.md` from the registry (ID, name, EN formula text, priority, chart).
**Implementation notes:** a CI lint test asserts that each metric has:
- a unique ID
- ARB keys in EN, FR and AR
- an explain text
- a chart mapping
- a minimum-data rule
- at least one fixture (P0 metrics)
**Acceptance criteria:** CI fails when any of these is missing; the glossary opens from every explain sheet.
**Tests:** the lint test itself; a widget test for glossary search.

### T6.1.22 — Per-scope card layout customization
**Priority:** P1 · **Size:** S · **Depends on:** T6.1.16, [8.3] (settings repository)
**Description:** Users can reorder, hide and pin cards per scope. The layout is stored in
`user_settings.stats` and synced across devices, with "Reset to default".
**Acceptance criteria:** the customized layout survives restarts and appears on a second device after sync.
**Tests:** a widget test for edit mode; a settings round-trip unit test.

### T6.1.23 — Stats performance suite
**Priority:** P1 · **Size:** M · **Depends on:** T6.1.13, [9.1] (performance harness)
**Description:** Synthetic large datasets and timing assertions against arch §9.6.
**Implementation notes:**
- Datasets: 30 habits × 5 years (~55 k logs); 2 000 tasks with 3 years of occurrences; 50 checklists
  × 5 000 items with 100 k status events.
- Budgets:
  - habit stats: first paint < 300 ms, cached < 50 ms
  - Planner Insights for one year: < 400 ms
  - a one-year checklist CFD: < 250 ms
  - transient isolate memory: < 50 MB
**Acceptance criteria:** results are recorded in CI artifacts; a regression of more than 10 % fails.
**Tests:** this task is the suite.

### T6.1.24 — Correlation toolkit & false-discovery control
**Priority:** P2 · **Size:** M · **Depends on:** T6.1.19
**Description:** Statistics behind the correlations explorer ([6.7]).
**Implementation notes:**
- **phi** for two binary daily series (from the 2×2 table).
- **Point-biserial** (Pearson between binary and numeric), with Mann–Whitney as the robust alternative.
- **Spearman ρ**, with average ranks and a t-approximation for p.
- **Lag alignment** for lags 0–7 days (the default tests 0–3).
- **Benjamini–Hochberg FDR** across all pairs tested in a run (q = 0.10).
- **Effect thresholds** for reporting: |phi| ≥ 0.2 or |ρ| ≥ 0.3.
**Acceptance criteria:** reference values match R (`cor.test`, `p.adjust(method = "BH")`); with 50 random
pairs of independent series, BH reports 0 discoveries in ≥ 95 % of seeds.
**Tests:** reference tests; a seeded false-positive simulation.
**Notes:** Implemented in `packages/everslot_metrics/lib/src/correlation.dart` (+ `correlationExplorer` in `global_metrics.dart`); verified 2026-09-26 with the package suite (seeded false-positive simulation included).

### T6.1.25 — Kaplan–Meier survival
**Priority:** P2 · **Size:** S · **Depends on:** T6.1.02
**Description:** Survival curves of time-to-lapse across quit attempts ([6.6]).
**Implementation notes:**
- KM estimator: S(t) = Π over event times t_i ≤ t of (1 − d_i/n_i).
- The current attempt is right-censored.
- Median survival is the first t where S(t) ≤ 0.5 ("not reached" otherwise).
- Greenwood's variance gives an optional 95 % band.
- The output is a step function for the KM curve in [6.2] (T6.2.25).
**Acceptance criteria:** matches R `survival::survfit` on a reference dataset.
**Tests:** reference tests, including all-censored and single-event cases.
**Notes:** Implemented in `packages/everslot_metrics/lib/src/survival.dart` (R `survfit` reference); verified 2026-09-26.

### T6.1.26 — Monte Carlo forecasting
**Priority:** P2 · **Size:** S · **Depends on:** T6.1.02
**Description:** Probabilistic "when will it be done" and "how many by date X" forecasts.
**Implementation notes:**
- Resample daily throughput from the last k weeks (default 6, active days only), 10 000 trials, with a
  seeded RNG.
- "When": for R remaining items, give the finish-date distribution with P50/P85/P95.
- "How many": the count completed by date X at the same percentiles.
- Minimum data follows T6.1.14. Output feeds the forecast visuals in [6.2] (T6.2.26).
**Acceptance criteria:** with constant throughput of 2/day and R = 10, all percentiles equal day 5; the
runtime for 10 000 trials is < 50 ms.
**Tests:** deterministic seeded tests; edge cases (R = 0, zero-throughput history → `Insufficient`).
**Notes:** Implemented in `packages/everslot_metrics/lib/src/forecast.dart`; verified 2026-09-26 (seeded tests, R = 0 and zero-throughput edge cases).

### T6.1.27 — Local rollups (`stats_cache`)
**Priority:** P2 · **Size:** M · **Depends on:** T6.1.23
**Description:** Build this only if T6.1.23 shows budgets failing. It keeps incremental daily rollups
per (domain, entity, metric family, local_date) in the local-only `stats_cache` table (arch §6.5).
**Implementation notes:**
- Rollups update lazily on first read after a `dataVersion` bump, from the earliest affected date forward.
- A rebuild command is available in the debug menu.
- The results must equal direct computation.
**Acceptance criteria:** metric outputs are identical with and without rollups on every fixture, and the
failing budgets are met.
**Tests:** an equivalence test that runs all fixtures in both modes.
