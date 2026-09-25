# Stats fixtures

Canonical datasets for `packages/everslot_metrics` (T6.1.15). Each file holds its data and the
expected values; the tests in `packages/everslot_metrics/test/` load them with `loadFixture(name)`
(paths are relative to the package root). Times are local wall-clock values in the fixture's `zone`
unless stated otherwise. Expected values are hand-computed from the task files' formulas, except the
reference files marked *(reference)*, which were computed once with NumPy 1.26 / SciPy 1.15.

| File | Section | Content | Test |
|---|---|---|---|
| `planner_two_weeks.json` | [6.3] T6.3.21 | Europe/Paris, week start MO, work hours 09–17 Mon–Fri, Mon 2026-09-07 … Sun 2026-09-20 (no DST). Series Gym (MO/WE/FR 18:00, 1 skip, 1 miss, 4 done), Standup (weekdays 09:30, timer sessions, one cancelled occurrence), Reading (daily 21:00, 2 skips, 1 miss); 12 one-off tasks incl. a snowballing reschedule (o4: +1 d, +2 h, −30 min), a task moved out of week 2 (o3), an unplanned addition (o5), events (o6, o7 in an unavailable category), an all-day task (o11), a skipped task (o12) and an overdue one (o9). Expectations: series ledgers and streaks (PL-S-01…05), plan snapshot (PL-X-01…03), on-time rate, overdue, capacity/utilization, time by category. | `planner_metrics_test.dart` |
| `checklist_flow_small.json` | [6.4] T6.4.18 | The T6.4.02 single-item history (LT 7 d 1 h, CT 6 d, flow efficiency 50 %), the T6.4.05 five-day CFD dataset (A–E with a reopen and a deletion) sampled on 7 days, and an item moved between lists. | `checklist_metrics_test.dart` |
| `checklist_runs_week.json` | [6.4] T6.4.18 | 7 runs of a 5-item morning routine with completion 100, 100, 80, 100, 100, 100, 60 % (mean 91.4 %, best streak 3, current 0). | `checklist_metrics_test.dart` |
| `checklist_tree_deep.json` | [6.4] T6.4.18 | A 12-level chain with siblings plus integrity violations (completed parent with open descendants, all children done but parent open, blocked without a reason). | `checklist_metrics_test.dart` |
| `strength_loop.json` | [6.1] T6.1.10, [6.5] T6.5.18 | Loop Habit Tracker score parity vectors (`habits_loop_parity`): daily, 3 per 8 days, weekly MO/TU, 3×/week, numeric at-least (daily and weekly windows), numeric at-most, skipped days, 9 units/day — from an independent reference port of Loop's documented algorithm. | `habit_metrics_test.dart` |
| `habit_pushups_month.json` | [6.5] T6.5.18 | The canonical "15 push-ups every day" September 2026: 24 done, 3 partial (10), 2 missed, 1 skip, one backfilled log. Success 24/29, volume 390, target progress 390/435, mean fulfilment 26/29. | `habit_metrics_test.dart` |
| `habits_portfolio.json` | [6.5] T6.5.18 | Six habits over two weeks: count ≥ 8, a 3×/week quota, an 8-slot habit (all-slots roll-up), a limit ≤ 2, a daily habit revised to weekdays on 2026-09-21, and one with a vacation. Section expectations (today progress, perfect days, weekly adherence and Δ, ranking). | `habit_metrics_test.dart` |
| `quit_smoking_90_days.json` | [6.6] T6.6.14 | Stop smoking from 2026-06-01 00:00 (Paris), baseline 20/day, €0.60 → €0.65 from 2026-07-01, one lapse of 3 on 2026-06-20 18:00, 40 cravings; seen on 2026-07-31 00:00 (QT-01 60 d, QT-02 40 d 6 h, QT-04 59, units 1 197, €748.20 saved, €1.80 spent, 16 d 15 h regained). | `quit_metrics_test.dart` |
| `quit_reduce_week.json` | [6.6] T6.6.14 | Reduce mode: baseline 20, limit 10, uses 12, 9, 10, 8, 11, 7, 6 (within limit 5/7, mean 9.0, reduction 55 %, 77 units avoided). | `quit_metrics_test.dart` |
| `quit_attempts.json` | [6.6] T6.6.14 | Three attempts across the 2026-03-29 DST change: a relapse (uses on days 10–16), a lapse (single use on day 10), and a clean current attempt; Kaplan–Meier time to first lapse (median 236 h). | `quit_metrics_test.dart` |
| `overview_week.json` | [6.7] T6.7.19 | Two consecutive weeks of per-day section facts (planner, habits, lists, quit) with the GL-01 today board, GL-02 week at a glance, GL-03 weekly review (headline Δs, wins, attention, top categories, next-week load) and the GL-07 day score. | `global_metrics_test.dart` |
| `descriptive.json` *(reference)* | [6.1] T6.1.02 | Type-7 percentiles, Welford variance, CV, IQR, MAD, 10 % trimmed mean, geometric mean, box plots, Freedman–Diaconis and fixed-width histograms for six datasets (incl. n = 1, ties, a repeated value, outliers). | `foundations_test.dart` |
| `reference_tests.json` *(reference)* | [6.1] T6.1.04/19/24/25 | OLS (`linregress`) and Theil–Sen on `y = 3x + noise` with 10 % outliers; Mann–Whitney = R `wilcox.test(exact = FALSE, correct = TRUE)`; Kruskal–Wallis = R `kruskal.test`; Pearson/Spearman/phi/point-biserial = R `cor.test`; BH = R `p.adjust(method = "BH")`; Kaplan–Meier = R `survfit` (Greenwood, log CI). | `foundations_test.dart` |

Regenerating a reference file: re-run the NumPy/SciPy script it was produced with (kept out of the
repo) and review the diff; hand-computed fixtures are edited by hand together with their tests.
