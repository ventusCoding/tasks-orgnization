# Section 6.7 — Overview Dashboard, Reviews & Insights

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 5.4, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 7.5, 8.3
> Architecture: §6.12 (stats engine), §6.13 (notifications for insight delivery), §8.5 (`stats` settings)

## Goal

Pull the Planner, Lists, Habits and Quit statistics into one picture: an Overview dashboard, a weekly
review (MVP), monthly and yearly reviews, personal records, a day score, statistically careful insights
(day-of-week effects, correlations), goals with projections, data quality, gamification metrics, custom
dashboards, and export/share. Everything is computed on the device from the section catalogs
([6.3]–[6.6]). Nothing leaves the device unless the user shares it.

## Scope

**In:** Overview screen, weekly/monthly/yearly reviews, records engine, day score, day-of-week effects,
insights feed (trigger catalog), goals dashboard, data-quality overview, cross-section heatmap, export
and share cards, correlations explorer, gamification metrics, custom dashboards, cross-section time
budget, Monte Carlo goal forecasts, fixtures.
**Out:** Section metrics themselves ([6.3]–[6.6]); goal and achievement models ([5.4]); notification
delivery of insights and digests ([7.5]); the operational Today screen ([8.1]).

## Progress

- [x] T6.7.01 — Overview screen: Today board & week at a glance
- [x] T6.7.02 — Weekly review report
- [x] T6.7.03 — Guided weekly review & review streak
- [x] T6.7.04 — Monthly review
- [x] T6.7.05 — Personal records engine
- [x] T6.7.06 — Day score
- [x] T6.7.07 — Day-of-week effects
- [x] T6.7.08 — Insights feed (natural-language insights)
- [x] T6.7.09 — Goals dashboard & projections
- [x] T6.7.10 — Data-quality overview
- [x] T6.7.11 — Cross-section year activity heatmap
- [x] T6.7.12 — Export metric series & share cards
- [x] T6.7.13 — Correlations explorer
- [x] T6.7.14 — Year in review ("Wrapped")
- [x] T6.7.15 — Gamification metrics
- [x] T6.7.16 — Custom dashboards
- [x] T6.7.17 — Cross-section time budget
- [x] T6.7.18 — Monte Carlo goal forecasts
- [x] T6.7.19 — Overview fixtures & report snapshot tests

## Tasks

### T6.7.01 — Overview screen: Today board & week at a glance
**Priority:** P0 · **Size:** M · **Depends on:** [6.1] (T6.1.16, T6.1.17), [6.3] (T6.3.07, T6.3.08), [6.4] (T6.4.12), [6.5] (T6.5.13), [6.6] (T6.6.02, T6.6.03)
**Description:** The "Overview" segment of the Insights tab.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-01 | Today board | agenda progress (done ÷ planned, PL-X-01 for today); habits done ÷ due (HB-X-01) and perfect-day status; cravings today (QT-13); checklist items completed today; WIP and blocked counts (CL-X-03); overdue count (PL-X-06); next up | all sections | tiles + rings | P0 |
| GL-02 | Week at a glance | this week (to date) vs the same days last week: completion vs plan, planned vs actual hours, habit success rate, items completed, money saved | all sections | KPI tiles with Δ | P0 |

**Implementation notes:** the Overview also links to each section's Insights screen and to the latest
weekly review. Its numbers match the Today screen header ([8.1]) exactly, because both use the same
metric IDs.
**Acceptance criteria:** the Overview renders in < 300 ms with the `overview_week` fixture; it adapts
when sections are empty (e.g. no quit trackers means no quit tile).
**Tests:** widget tests with fixture results; goldens.
**Notes:** Overview segment of `InsightsScreen`: GL-01 (today board tiles only for sections with data, next up, overdue/WIP drills) and GL-02 (this week to date vs the same days last week), plus the weekly review entry; the section links are the Insights segments. The habit tile of GL-02/GL-03 uses HB-X-04's exact definition (closed scheduled units incl. quota periods, archive rule), so it equals the Habits screen; before any unit closes it shows "—". Tests: `presentation/overview_screens_test.dart` (all sections, empty sections), goldens; numbers pinned by `overview/weekly_review_snapshot.json`.

### T6.7.02 — Weekly review report
**Priority:** P0 · **Size:** L · **Depends on:** T6.7.01, [6.3] (T6.3.07–T6.3.09), [6.4] (T6.4.04, T6.4.12), [6.5] (T6.5.04, T6.5.13), [6.6] (T6.6.03, T6.6.05)
**Description:** A weekly report, by default for the last completed week (user's week start), with a
toggle for "this week so far".

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-03 | Weekly review | per-section KPIs with Δ vs the previous week; wins; attention items; time allocation; next week's load vs capacity | section metrics | report layout | P0 |

**Implementation notes:**
- **Headline KPIs** (each with Δ):
  - PL-X-01 completion vs plan
  - PL-X-12 planned vs actual hours
  - HB-X-04 habit adherence
  - CL-X-04 items completed
  - QT-07 money saved this week (all trackers)
- **Wins:**
  - streak milestones (7/14/21/30/50/66/100… days)
  - perfect days (HB-X-02)
  - health milestones reached (QT-11)
  - new records (GL-06, once T6.7.05 exists)
- **Attention:**
  - overdue tasks (PL-X-06)
  - blocked and waiting items (CL-X-03)
  - stale lists (CL-X-01)
  - overdue follow-ups (CL-L-15) and habits at risk (HB-X-07), when their P1 metrics exist
- **Time:** time by category (PL-X-13), top 3 categories with Δ.
- **Next week:** planned load vs capacity per day (PL-X-08 and PL-X-10 over next week); overbooked days
  are flagged.
- **Builder:** `WeeklyReviewBuilder` composes cached metric results. Items whose metrics aren't
  implemented yet are hidden by feature flag, never shown as errors.
- **Delivery:** a "Weekly review ready" digest (in-app or push) is configured in [7.5].
**Acceptance criteria:** the `overview_week` fixture produces the expected report values; tapping any
attention item opens the relevant entity; the report is available offline.
**Tests:** fixture test of the builder output; golden of the report.
**Notes:** GL-03 on `/insights/review` (`?week=current` opens this week so far; the in-report toggle switches): headline KPIs with Δ, wins (streak milestones, perfect days, health milestones), attention items (overdue tasks, blocked/waiting items, stale lists) each opening its entity, top categories with Δ, next week's load vs capacity. Records, overdue follow-ups and habits-at-risk join when their P1 metrics exist. Offline by construction (local DB). TODO(integration): the "weekly review ready" digest is configured by [7.5].

### T6.7.03 — Guided weekly review & review streak
**Priority:** P1 · **Size:** M · **Depends on:** T6.7.02
**Description:** A GTD-style guided flow built on the weekly report. Its steps:
1. Celebrate the wins.
2. Handle overdue tasks (reschedule, skip or drop).
3. Process waiting items (follow up, update or unblock).
4. Handle stale lists (archive or plan).
5. Handle habits at risk (adjust the schedule or pause).
6. Rebalance next week's overbooked days.
**Data model:** record review completion as an `activity_events` row (`entity_type = 'review'`,
`entity_id = uuidv5(user_id|weekKey)`, `event_type = 'completed'`).

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-04 | Weekly review streak | consecutive weeks with a completed guided review | review events | chip | P1 |

**Acceptance criteria:** each step writes normal entity changes (with undo); the flow can be resumed after
the app is killed.
**Tests:** widget/flow tests; fixture test for the streak.
**Notes:** `/insights/review-flow` (`GuidedReviewScreen` + `application/guided_review.dart`): six steps; actions go through the planner/checklist/habit services (tomorrow, skip, drop · follow up tomorrow, unblock · archive · pause a week · open day) with an Undo snackbar each; the step is kept in `local_kv` (`stats.ui.review.*`) so the flow resumes after a kill; Finish writes `activity_events` (`review`, `uuidv5(user|week)`, `completed`, `payload.week`, deterministic id). GL-04 counts reviewed weeks with the due week (last completed) open until reviewed; shown on the review screen. "Adjust schedule" opens the habit editor rather than editing inline. Tests: `overview/overview_reports_test.dart` (resume + event), `overview/global_insights_test.dart` (streak).

### T6.7.04 — Monthly review
**Priority:** P1 · **Size:** M · **Depends on:** T6.7.02

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-05 | Monthly review | the weekly-review structure over a month; month-over-month Δ (rates and per-day averages, never raw sums of unequal months); year-over-year when a year of data exists; month calendar heatmap across sections | section metrics | report layout | P1 |

**Acceptance criteria:** comparisons between February and March use per-day normalization and say so.
**Tests:** fixture tests; golden.
**Notes:** GL-05 on `/insights/month` (`?month=current` / toggle): `ReviewData(perDay: true)` with rate KPIs compared directly and sums as per-day averages (the report says so), YoY deltas in args when a year of data exists, wins (streak milestones, perfect days, records), top categories with per-day-normalized Δ and a month heatmap with a per-section breakdown (`CalendarCell.breakdown`). Day facts beyond the 5-week window come from the new `GlobalContext.history` (first data date, ≤ 5 years; planner facts bucketed per planned date so each day's snapshot is linear).

### T6.7.05 — Personal records engine
**Priority:** P1 · **Size:** M · **Depends on:** T6.7.01, [6.5] (T6.5.06)
**Description:** Detect and list personal records across sections, and announce new ones.
**Implementation notes:**
- **Record types:**
  - longest habit streak, overall and per habit
  - most tasks completed in a day
  - most actual hours in a week
  - most deep-work hours in a week
  - max value of a habit in a day, and best volume week of a habit
  - longest abstinence, per quit tracker
  - most checklist items completed in a week
  - longest perfect-day streak
  - best weekly completion vs plan (with ≥ 10 planned tasks)
  - biggest money-saved month
- **Detection:** a record is "new" when the value exceeds the maximum over all history before the
  current period. Announced record keys are stored in `user_settings.stats.announcedRecords` so a record
  is never announced twice.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-06 | Personal records | per record type: value, date, previous record; "new" badge within 7 days | all sections | trophy list | P1 |

**Acceptance criteria:** backfilling data that creates an old record doesn't trigger a "new record"
announcement dated today.
**Tests:** fixture tests.
**Notes:** GL-06 on `/insights/records`: 11 record types (`RecordType`), overall and per habit / tracker, via `personalRecord` with "new" = set in the last 7 days and above everything before (backfill never announces); `args.toAnnounce` excludes `stats.announcedRecords`, which the feed fills when it fires a record. Weekly reviews and Wrapped list records broken in their period.

### T6.7.06 — Day score
**Priority:** P1 · **Size:** M · **Depends on:** T6.7.01

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-07 | Day score | DS_d = Σ_k w_k·s_k,d ÷ Σ_k w_k over sections with data that day. s_planner = done ÷ planned (plan snapshot at day start); s_habits = done ÷ due build units; s_lists = min(1, completions_d ÷ median completions over the prior 28 active days); s_quit = 1 if abstinent (reduce: within limit) else 0. Weights default 1 (`user_settings.stats.dayScoreWeights`). Shown as 0–100 with Δ vs the 28-day median DS | section facts | gauge + sparkline with median band | P1 |

**Acceptance criteria:** with planner 4/5, habits 3/4, lists 2 completions vs a median of 4, abstinent,
and equal weights: DS = (0.8 + 0.75 + 0.5 + 1) ÷ 4 = 76.
**Tests:** fixture tests; a test that a section without data is excluded, not counted as 0.
**Notes:** GL-07 on the Overview: `dayScoreSeries` over 120 days with `stats.dayScoreWeights`; value = today 0–1 (`StatUnit.score`), 28-day sparkline with the prior-28 P25–P75 band and the Δ vs median as a card note; sections without data are excluded (test).

### T6.7.07 — Day-of-week effects
**Priority:** P1 · **Size:** S · **Depends on:** T6.7.01, [6.1] (T6.1.19 Kruskal–Wallis)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-08 | Day-of-week effects | for planner completion rate, habit success rate, checklist completions, cravings/day and deep-work hours: the mean by weekday over ≥ 4 weeks; Kruskal–Wallis across weekdays (p < 0.05 → "significant"); best/worst weekday; effect size ε² | section facts | bars + significance marks | P1 |

**Acceptance criteria:** with fewer than 4 weeks the card is insufficient; non-significant differences are
labeled "no clear weekday pattern".
**Tests:** fixture tests.
**Notes:** GL-08 on `/insights/correlations`: planner completion, habit success, items, cravings and deep-work hours over the last 26 weeks (today excluded); bars per weekday with the mean line, one note per metric (best/worst weekday or "no clear weekday pattern"); < 4 weeks → insufficient.

### T6.7.08 — Insights feed (natural-language insights)
**Priority:** P1 · **Size:** L · **Depends on:** T6.7.05, T6.7.07, [6.3], [6.4], [6.5], [6.6], [7.5] (optional notification delivery)
**Description:** A feed of short, data-backed sentences with "Why am I seeing this?" details (rule,
numbers, sample size). The rules are:
- Insights are generated locally after syncs and data changes (debounced), and daily in the background.
- Each insight is de-duplicated by (trigger, entity, value) and has per-trigger cooldowns.
- The user can dismiss an insight or mute a trigger type.
- Delivery to the inbox or as notifications is opt-in per trigger type ([7.5]); milestones are on by
  default.
- Wording is non-causal and never judgmental.
**Data model:** a local-only table `insight_state` (key, firedAt, dismissedAt) and
`user_settings.stats.mutedInsightTypes`.

| # | Trigger | Rule | Example text | Cooldown |
|---|---|---|---|---|
| 1 | New personal record | GL-06 detects a new record | "New record: 42 push-ups in a day (previous 35)." | once per value |
| 2 | Streak milestone | streak reaches 7, 14, 21, 30, 50, 66, 100, 150, 200, 365, then every 100 | "Reading: 30-day streak!" | once per milestone |
| 3 | Significant trend | adherence slope over 8 weeks with p < 0.05 and \|slope\| ≥ 2 pp/week | "Gym adherence is rising: +3 pp per week." | 14 days per entity |
| 4 | Estimation bias | PL-X-21 > +20 % with n ≥ 10 in the last 30 days | "Tasks take ~27 % longer than planned — try adding a buffer." | 30 days |
| 5 | Rising overdue | overdue count up ≥ 30 % vs 4 weeks ago and ≥ 5 | "Overdue tasks are piling up (12, up from 7)." | 7 days |
| 6 | Overbooked next week | ≥ 2 days next week with load > capacity | "Next Tuesday and Thursday are overbooked." | weekly |
| 7 | Blocker cluster | ≥ 3 blocked episodes with the same normalized reason in 14 days | "3 items blocked on 'supplier' in two weeks." | 14 days per cluster |
| 8 | Follow-ups due | ≥ 3 waiting items past their follow-up | "3 waiting items need a follow-up." | 3 days |
| 9 | Stale list | open items and no activity ≥ N days | "'Move apartment' has had no activity for 21 days." | 14 days per list |
| 10 | Falling cravings | 7-day mean cravings/day down ≥ 25 % vs previous 7 days (n ≥ 5) | "Cravings are down 40 % this week." | 7 days |
| 11 | Health milestone | QT-11 milestone reached (smoking) | "72 hours smoke-free: breathing gets easier." | once per milestone per attempt |
| 12 | Money milestone | saved crosses 10, 50, 100, 250, 500, 1 000… (currency units) | "€500 saved since you quit." | once per threshold |
| 13 | Perfect week | every due build habit done on every scheduled day of the week | "Perfect habit week!" | weekly |
| 14 | Best weekday | a weekday ≥ 15 pp above the mean over ≥ 4 weeks (and GL-08 significant) | "You're most consistent on Tuesdays (92 %)." | 30 days |
| 15 | Habit at risk | quota behind pace or score drop > 10 points in 7 days | "1 of 3 runs this week, 2 days left." | daily |
| 16 | Strength threshold | habit score crosses 50 % or 80 % upwards (re-arms after dropping below 70 %) | "Meditation strength passed 80 %." | per crossing |
| 17 | Comeback | a success after ≥ 3 consecutive misses | "Welcome back to journaling!" | per comeback |
| 18 | Correlation (P2) | GL-13 pair significant after FDR | "On days you run, your mood tends to be higher." | 30 days per pair |

**Acceptance criteria:** each trigger has a fixture proving it fires exactly once within its cooldown;
every insight opens the metric or entity that supports it; the texts are localized in EN, FR and AR.
**Tests:** rule unit tests per trigger; feed widget tests.
**Notes:** GL-19 (hidden metric) evaluates the 18 triggers in the stats isolate; `InsightsFeedService` filters with `insight_state` + `mutedInsightTypes` (`filterInsights`), stores the fired payload (new `insight_state.payload`, schema v4 + migration test) and adds fired records to `announcedRecords`. Feed on `/insights/feed` and the top 3 on the Overview: sentence, Why sheet (rule, numbers, supporting metric), dismiss, mute/unmute, tap opens the entity or metric. Generation runs while a feed is visible and data changes. TODO(integration): daily background generation and opt-in inbox/push delivery per trigger are [7.5]. Per-trigger fire-once rules are pinned in `everslot_metrics`; app tests cover dedupe, announcement, dismiss, mute and the feed widget.

### T6.7.09 — Goals dashboard & projections
**Priority:** P1 · **Size:** M · **Depends on:** T6.7.01, [5.4] (goals)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-09 | Goals & projections | for each goal (scope habit / series / category / checklist / global): progress = actual ÷ target; pace = target × elapsed fraction; status achieved / on track / behind / at risk (behind and needed rate > 1.5 × recent rate); projected end = actual + rate₂₈ × remaining days; ETA | goals + section facts | cards + line with pace line | P1 |

**Acceptance criteria:** the numbers equal HB-H-26 for habit goals; achieved goals move to an "Achieved"
list with `achieved_at`.
**Tests:** fixture tests.
**Notes:** GL-09 on the Overview and `/insights/goals`: every goal (habit goals exactly as HB-H-26 — day results, `volume`/`total_value`; quit goals from tracker days; series/category/global from planner facts; checklist/global items from completions) through `goalProgress`, active list with status, the first goal's actual vs pace line, and an Achieved list (`achieved_at` or reached). Test: numbers equal HB-H-26.

### T6.7.10 — Data-quality overview
**Priority:** P1 · **Size:** S · **Depends on:** [6.1] (T6.1.20), [6.3] (PL-X-41), [6.5] (T6.5.11)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-10 | Data quality | habit logged ratio and unknown units; backfill share (> 24 h late); planner actual-time coverage; pending sync changes; each with guidance ("Log from notifications to improve accuracy") | section facts | tiles | P1 |

**Tests:** fixture tests.
**Notes:** GL-10 on the Overview (last 30 days): habit logged ratio, unlogged units (drill), late logging, planner tracked-time coverage and pending sync changes, with guidance tips rendered in the card footer.

### T6.7.11 — Cross-section year activity heatmap
**Priority:** P1 · **Size:** S · **Depends on:** T6.7.01, [6.2] (calendar heatmap T6.2.06)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-11 | Year activity heatmap | per day: done task occurrences + done habit units + completed checklist items (abstinent days marked separately); tooltip breakdown by section | all sections | year grid | P1 |

**Tests:** fixture test; golden.
**Notes:** GL-11 on `/insights/year` (`?year=YYYY`, else the last 365 days): intensity year grid from `yearActivityHeatmap`, cells carry the per-section breakdown (semantics label + tap snackbar as the tooltip), abstinent days counted in args.

### T6.7.12 — Export metric series & share cards
**Priority:** P1 · **Size:** M · **Depends on:** [6.2] (T6.2.23 share image)
**Description:** Two export and share features.
- **Series export:** export any chart's series, or all metrics of a scope for a period, as CSV
  (a zip of files) or JSON. The export uses machine-friendly formats (ISO dates, dot decimals); a
  locale-formatted option is available. A header lists the metric definitions and the period.
- **Share cards:** a weekly summary card and single-metric cards, exported as images.
- Files are generated locally and shared via the share sheet.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-12 | Export & share | CSV/JSON per chart or scope; share cards | metric results | file / image | P1 |

**Acceptance criteria:** exported CSV values equal the on-screen values; files open correctly in common
spreadsheet apps (UTF-8 BOM option for Excel, RTL text preserved).
**Tests:** unit tests of the CSV writer; golden of a share card.
**Notes:** `presentation/export/stats_export.dart`: chart share sheet gains CSV/JSON export (local-format and Excel BOM switches) and every scope screen an "Export data" menu (summary CSV + one CSV per chart, or one JSON). Machine values equal the screen (percent ×100, ISO dates, dot decimals), `#` header with metric definitions and period; files go to the share sheet (`StatsFileSharer`). CSV is several files rather than a zip (no archive dependency). Weekly/monthly reports share a summary card (golden `overview/goldens/week_summary_card.png`).

### T6.7.13 — Correlations explorer
**Priority:** P2 · **Size:** L · **Depends on:** [6.1] (T6.1.24), [6.2] (scatter T6.2.15, matrix T6.2.21)
**Implementation notes:**
- **Candidate daily series:**
  - habit done flags (binary)
  - habit values
  - mood (habit logs)
  - planner completion rate
  - planned and actual hours
  - deep-work hours
  - checklist completions
  - cravings/day
  - quit use/day
- **Statistical tests:**
  - phi for binary × binary
  - point-biserial plus Mann–Whitney for binary × numeric
  - Spearman for numeric × numeric
- **Guards:**
  - lags 0–3 by default
  - at least 21 paired days and ≥ 7 days per group
  - BH-FDR q = 0.10 across all tested pairs
  - minimum effect |phi| ≥ 0.2 or |ρ| ≥ 0.3
  - exclude trivially related pairs (same habit, or derived metrics)
- **Output:** 1–5 stars from effect-size and significance bins.
- **Execution:** runs weekly in a background isolate or on demand, and results are cached.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-13 | Correlations | ranked list of significant pairs with effect size, lag, n, stars; scatter / bar detail; explicit "correlation is not causation" note | daily series | ranked list + scatter | P2 |

**Acceptance criteria:** a synthetic dataset with one planted relationship surfaces exactly that pair;
50 random independent series produce no discoveries in ≥ 95 % of seeds.
**Tests:** seeded fixture tests.
**Notes:** GL-13 on `/insights/correlations`: candidate series (habit done flags / values per habit, mood, planner rate, planned/actual/deep-work hours, items, cravings, quit use) over 180 days; same-habit and same-group pairs skipped; ranked significant pairs + scatter of the top pair with the "not causation" note. Runs in the stats isolate and is cached by data version (no separate weekly job). Planted-pair test in the app; the 95 % null-seed property is pinned in `everslot_metrics`.

### T6.7.14 — Year in review ("Wrapped")
**Priority:** P2 · **Size:** L · **Depends on:** T6.7.05, T6.7.11, [6.2] (share image T6.2.23)
**Description:** Story cards for a year:
1. Year in numbers (tasks done, hours planned and actual, habit check-ins, items completed, money saved).
2. Busiest month and weekday.
3. Top categories.
4. Longest streaks.
5. Deep-work hours.
6. Quit journey (days abstinent, money saved, milestones).
7. Records broken.
8. Year-over-year (when there are 2+ years of data).
9. An archetype label. It is rule-based, for example:
   - Early Bird: median first task start < 08:00
   - Night Owl: median last check-in ≥ 22:00
   - Marathoner: ≥ 200 deep-work hours
   - Consistent: habit success ≥ 85 %
   - Finisher: most items completed
10. A shareable summary card.

The review is offered from December 15 to January 31 for the closing year, and any time for past years.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-14 | Year in review | yearly aggregates, records, YoY comparisons, archetype | all sections | story cards | P2 |

**Acceptance criteria:** computed fully offline in < 2 s for 5 years of data; sharing hides names on request.
**Tests:** fixture tests; golden per card.
**Notes:** GL-14 + `/insights/wrapped` (`WrappedView`): story cards (numbers, busiest month/weekday, top categories, longest streaks, deep work, quit journey, records broken, YoY, archetypes) as pages with reduce-motion paging and a share summary card ("Hide names" in the share sheet). `args.offered` is true Dec 15–Jan 31; the year screen links it any time. Perf scenario `yearInReview` added to the stats perf suite (budget 2 s): the desktop JIT full-scale run measures 3.3–4.1 s (≈ 1.3 s loading, the rest mostly resolving 3 years of planner occurrences), so the < 2 s device criterion is not verified yet — budgets stay report-only until the device profile run (T6.1.27).

### T6.7.15 — Gamification metrics
**Priority:** P2 · **Size:** M · **Depends on:** [5.4] (achievements), [9.3] (advanced gamification spike)
**Implementation notes:** gamification is opt-in and hidden by default. The numbers below are
illustrative and must be tuned during design.
- **XP per completion:** base 10 × priority multiplier (none/low 1.0, medium 1.2, high 1.5, urgent 2.0),
  with an on-time bonus of × 1.1.
- **Habit check-in:** 10 × (1 + min(streak, 100)/100). This is inspired by Habitica's streak gold bonus.
- **Other sources:** a checklist leaf completion earns 5; an abstinent day earns 20.
- **Anti-grinding rules:** daily cap of 500; no XP for creating items; undo removes XP.
- **Levels:** cumulative threshold 100·n^1.5.
- **Inspiration only:** Todoist Karma (8 levels, "Enlightened" at ≥ 50 000) and TickTick's 12 tiers.
  Habitica's task delta (0.9747^value, clamped to [−47.27, 21.27]) is a reference, not to be copied.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-15 | XP, level & badges | XP earned per day/week, level progress, badges unlocked | all sections, achievements | level bar + badges | P2 |

**Tests:** unit tests for XP rules (caps, undo).
**Notes:** GL-15 (opt-in `stats.gamification`, Settings › Insights): XP from completed tasks (priority, on time), habit check-ins (streak bonus), list leaves and clean days — derived from current state, so undo removes XP and creating earns nothing; 500/day cap; level bar + 14-day XP bars. Hidden while off. Badges stay in the existing badge gallery ([5.4]).

### T6.7.16 — Custom dashboards
**Priority:** P2 · **Size:** M · **Depends on:** [6.1] (T6.1.16)
**Description:** Users compose dashboards from any metric card in any scope, for example "My morning
view": habit rings, today's load and quit counter. Cards can be added, reordered and resized, each with
its own period, and dashboards sync across devices.
**Data model:** the table `app.dashboards` is defined in
§7.3. Proposed columns (plus the common columns): `{name text, layout jsonb, sort_key text}`, where
layout = `[{metricId, scopeType, scopeId, period, chartVariant, span}]`.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-16 | Custom dashboards | user-defined card layouts | dashboards | any | P2 |

**Tests:** widget tests; sync round-trip test.
**Notes:** `dashboards` table via `DashboardsRepository` (SyncWriter: name, sort_key, layout JSON) + `/insights/dashboards` and `/insights/dashboard/<id>`: add cards from global/planner/lists/habits/quit (tracker picker), per-card period, half/full width, reorder, remove, rename, delete with Undo. Other entity scopes (one habit/list/series) are not offered in the picker yet. Tests: outbox round trip, widget edit.

### T6.7.17 — Cross-section time budget
**Priority:** P2 · **Size:** S · **Depends on:** [6.3] (T6.3.08), [6.5] (T6.5.05)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-17 | Time budget | per day/week: planned task minutes + duration-habit minutes (from logs) + tracked focus + remaining free time vs waking hours (configurable); overlap between habit logs and task sessions de-duplicated | planner + habits | stacked bars | P2 |

**Tests:** fixture tests.
**Notes:** GL-17 on `/insights/budget` (period selectable, default rolling 30): per day max(planned, tracked) task minutes, duration-habit minutes (log duration or minutes value) minus overlap with sessions, free time vs `stats.wakingHours` (Settings › Insights, default 16 h); weekly buckets past 31 days.

### T6.7.18 — Monte Carlo goal forecasts
**Priority:** P2 · **Size:** S · **Depends on:** T6.7.09, [6.1] (T6.1.26), [6.2] (T6.2.26)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| GL-18 | Goal forecast | resample daily progress over the last 6 weeks (10 000 trials) → completion date P50/P85/P95; cone overlay on the goal chart | goals, section facts | cone + histogram | P2 |

**Acceptance criteria:** requires ≥ 30 days of history; the wording is probabilistic.
**Tests:** seeded fixture tests.
**Notes:** GL-18 on `/insights/goals`: `goalForecast` per open goal with ≥ 30 days of history, 10 000 trials seeded by a stable hash of the goal id (reproducible), forecast histogram per goal and a probabilistic note (P50/P85/P95 dates).

### T6.7.19 — Overview fixtures & report snapshot tests
**Priority:** P0 · **Size:** S · **Depends on:** [6.1] (T6.1.15)
**Description:** An `overview_week` fixture combining the planner, checklist, habit and quit canonical
datasets across two consecutive weeks, with expected GL-01 to GL-03 values. It also includes snapshot
tests of the weekly review builder output (JSON) and of the rendered report (golden).
**Acceptance criteria:** the fixture runner passes; snapshots are stable in CI.
**Tests:** provides fixtures for the tasks above.
**Notes:** `overview_week` table fixture = the canonical planner, habits (−7 d), lists (+6 d) and quit (+52 d) datasets on one timeline, seen Mon 21 Sep 08:00 Paris; GL-01…03 expectations in the fixture runner, report numbers checked against the section metrics, JSON snapshot of the builder output (`UPDATE_STATS_SNAPSHOTS=1` regenerates) and report goldens.
