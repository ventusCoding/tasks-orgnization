# Metrics catalog

Generated from the metric registry (`app/lib/features/stats/application/catalog/`) by
`app/test/features/stats/engine/metric_catalog_test.dart` — do not edit by hand.

85 metrics.

## task

| ID | Name | Formula (EN) | Priority | Chart | Unit |
|---|---|---|---|---|---|
| PL-T-01 | Planned duration | Planned end − planned start. | P0 | kpi | minutes |
| PL-T-02 | Actual duration | Sum of tracked session lengths; unknown when nothing was tracked. | P0 | kpi | minutes |
| PL-T-03 | Duration variance | Actual − planned; ratio R = actual ÷ planned (only when planned ≥ 5 min). | P0 | bullet | minutes |
| PL-T-04 | Start delay | First session start − planned start; on time within the grace period. | P0 | kpi | minutes |
| PL-T-05 | Finish delay | Completion (or last session end for timers) − planned end. | P0 | kpi | minutes |
| PL-T-06 | Outcome | Done on time, done late, partial, skipped, missed, cancelled, pending or upcoming. | P0 | list | count |
| PL-T-07 | Overdue age | Now − planned end, bucketed 1 / 7 / 14 / 30+ days. | P0 | kpi | minutes |

## series

| ID | Name | Formula (EN) | Priority | Chart | Unit |
|---|---|---|---|---|---|
| PL-S-01 | Expected occurrences | Occurrences from the recurrence rule in the window; closed and open counted separately. | P0 | kpi | count |
| PL-S-02 | Done, missed, skipped | Counts of done (D), missed (M), skipped (K) and excused (X) occurrences. | P0 | stackedBars | count |
| PL-S-03 | Adherence | Done ÷ (expected − excused), with a 4-week rolling line and a weekly trend. | P0 | line | percent |
| PL-S-04 | Miss rate | (Missed + not done) ÷ (expected − excused). | P0 | kpi | percent |
| PL-S-05 | Current & best streak | Streak engine with one unit per occurrence. | P0 | streakBars | count |
| PL-S-06 | Time invested | Running totals of actual and planned minutes. | P0 | line | minutes |
| PL-S-07 | Total done | Count of done occurrences. | P0 | kpi | count |
| PL-S-08 | Last done | Today − date of the last completion. | P0 | kpi | days |
| PL-S-09 | Outcome calendar | Worst outcome of the day: missed > partial > late > skipped > done > excused. | P0 | calendar | count |

## planner

| ID | Name | Formula (EN) | Priority | Chart | Unit |
|---|---|---|---|---|---|
| PL-X-01 | Completion vs plan | Planned and done in the period ÷ planned as of the period start; tasks added later are excluded. | P0 | kpi | percent |
| PL-X-02 | Done vs planned per day | Per day: planned (plan snapshot) and done counts. | P0 | groupedBars | count |
| PL-X-03 | Unplanned & moved | Counts of unplanned additions, moved-out and moved-in occurrences. | P0 | tiles | count |
| PL-X-04 | Backlog flow | Created and completed per week; backlog = unscheduled tasks + overdue occurrences. | P0 | groupedBars | count |
| PL-X-05 | On-time completion | Done on time ÷ done (grace period included). | P0 | kpi | percent |
| PL-X-06 | Overdue now | Open overdue occurrences, bucketed 1 / 7 / 14 / 30+ days. | P0 | bars | count |
| PL-X-07 | Capacity | Work hours per day minus unavailable blocks, summed over the period. | P0 | kpi | minutes |
| PL-X-08 | Planned utilization | Planned minutes inside work hours ÷ capacity (can exceed 100 % with overlaps). | P0 | stackedBars | percent |
| PL-X-09 | Actual utilization | Tracked minutes inside work hours ÷ capacity; needs 60 % tracking coverage. | P0 | bars | percent |
| PL-X-10 | Overbooked days | Days with planned load > capacity; overbooked minutes = load − capacity. | P0 | bars | count |
| PL-X-11 | Remaining free time | Remaining capacity − remaining planned time (from now). | P0 | kpi | minutes |
| PL-X-12 | Planned vs actual hours | Sum of planned minutes vs sum of tracked minutes. | P0 | groupedBars | minutes |
| PL-X-13 | Time by category | Tracked minutes per category (planned when tracking covers < 60 %); share of total. | P0 | donut | minutes |
| PL-X-14 | Category trend | Minutes per category per week. | P0 | stackedBars | minutes |
| PL-X-15 | Events vs tasks | Event minutes ÷ (event + task minutes). | P0 | percentBars | percent |

## checklistItem

| ID | Name | Formula (EN) | Priority | Chart | Unit |
|---|---|---|---|---|---|
| CL-I-01 | Time in status | Sum of the intervals in each status until now (or deletion). | P0 | statusTimeline | minutes |
| CL-I-02 | Cycle time | Done − start (first move out of to do). | P0 | kpi | minutes |
| CL-I-03 | Lead time | Done − created. | P0 | kpi | minutes |
| CL-I-04 | Age | Started: now − start; not started: now − created. | P0 | kpi | minutes |
| CL-I-05 | Staleness | Now − last activity (status change, edit, attachment or child change). | P0 | kpi | minutes |
| CL-I-06 | Subtree progress | Completed leaves ÷ countable leaves (cancelled excluded). | P0 | ring | percent |
| CL-I-07 | Status timeline | Each status interval from creation to now. | P0 | statusTimeline | count |

## checklist

| ID | Name | Formula (EN) | Priority | Chart | Unit |
|---|---|---|---|---|---|
| CL-L-01 | Status mix | Items per status; % done over leaves and over all nodes. | P0 | donut | percent |
| CL-L-02 | Progress over time | Completed ÷ (items in scope − cancelled) at each day end. | P0 | line | percent |
| CL-L-03 | Throughput | Completions per bucket (a reopened item counts once, on its final completion). | P0 | bars | count |
| CL-L-04 | Work in progress | Count of ongoing + waiting + blocked items. | P0 | line | count |
| CL-L-05 | Arrivals vs departures | Weekly created (or moved in) vs completed; net flow = difference. | P0 | groupedBars | count |
| CL-L-06 | Stale items | Open items with staleness ≥ the stale threshold; 10 oldest by age. | P0 | list | count |

## checklists

| ID | Name | Formula (EN) | Priority | Chart | Unit |
|---|---|---|---|---|---|
| CL-X-01 | Lists overview | Counts of lists; stale = no activity for N days while holding open items. | P0 | tiles | count |
| CL-X-02 | Arrivals vs departures (all lists) | Weekly created vs completed; net flow = difference. | P0 | groupedBars | count |
| CL-X-03 | Work in progress across lists | Counts across active lists (archived excluded). | P0 | tiles | count |
| CL-X-04 | Items completed | Final completions in the period, compared with the previous period. | P0 | kpi | count |
| CL-X-05 | Status distribution | Count of live items per status. | P0 | percentBars | count |

## habit

| ID | Name | Formula (EN) | Priority | Chart | Unit |
|---|---|---|---|---|---|
| HB-H-01 | Habit strength | Loop score: score = previous × m + credit × (1 − m), m = 0.5^(√f ÷ 13). | P0 | line | score |
| HB-H-02 | Current streak | Streak engine: skips, excuses, pauses and freezes are neutral. | P0 | kpi | count |
| HB-H-03 | Best streak | Maximum streak length, with its date range. | P0 | kpi | count |
| HB-H-04 | Top streaks | Streaks ordered by length, then recency. | P0 | streakBars | count |
| HB-H-05 | Success rate | Done ÷ (closed scheduled units − excused); Wilson interval below 20 units. | P0 | kpi | percent |
| HB-H-06 | Outcome counts | Counts of success, partial, not done, missed, skipped and excused units. | P0 | stackedBars | count |
| HB-H-07 | History | Sums per bucket. | P0 | bars | count |
| HB-H-08 | Calendar | One cell per day: done, partial, not done, missed, skipped, excused, paused, frozen. | P0 | calendar | count |
| HB-H-09 | Total repetitions | All-time count of manual done and progress logs. | P0 | kpi | count |
| HB-H-10 | Target progress | Achieved ÷ (daily target × scheduled days − skipped days). | P0 | bullet | percent |
| HB-H-11 | Total volume | Sum of logged values in the period and all time. | P0 | line | count |
| HB-H-25 | Data completeness | Logged ratio = units with any log ÷ closed scheduled units · unknown units = missed units without any log · backfill share = logs created more than 24 h after their unit ended ÷ all logs. | P1 | tiles | percent |

## habits

| ID | Name | Formula (EN) | Priority | Chart | Unit |
|---|---|---|---|---|---|
| HB-X-01 | Today’s progress | Done ÷ due day units today (build habits). | P0 | ring | percent |
| HB-X-02 | Perfect days | Days with all due units done; perfect-day streak (days with nothing due are neutral). | P0 | calendar | count |
| HB-X-03 | Daily completion | Per day: done ÷ due across habits. | P0 | calendar | percent |
| HB-X-04 | Adherence trend | Weekly done ÷ due, with a 4-week rolling line; Δ vs previous week in points. | P0 | line | percent |
| HB-X-05 | Quit trackers roll-up | Sums over active quit trackers (life regained is a population estimate). | P0 | tiles | currency |
| HB-X-12 | Data completeness (all habits) | Σ units with any log ÷ Σ closed scheduled units across habits; Σ unknown units; Σ late logs ÷ Σ logs. | P1 | tiles | percent |

## quit

| ID | Name | Formula (EN) | Priority | Chart | Unit |
|---|---|---|---|---|---|
| QT-01 | Time since quitting | Now − quit date (live). | P0 | counter | minutes |
| QT-02 | Current abstinence | Now − max(quit date, last use) (live). | P0 | counter | minutes |
| QT-03 | Longest abstinence | Longest gap between quit date, uses and now. | P0 | kpi | minutes |
| QT-04 | Abstinent days | Count of closed days with no use. | P0 | kpi | days |
| QT-05 | Abstinent days share | Abstinent days ÷ closed days since the quit date. | P0 | ring | percent |
| QT-06 | Units avoided | Baseline per day × days − units used (floored at 0). | P0 | line | count |
| QT-07 | Money saved | Units avoided each day × unit cost in force that day. | P0 | area | currency |
| QT-08 | Spent on slips | Units used × unit cost at the time. | P0 | kpi | currency |
| QT-09 | Savings projection | Current baseline × unit cost over the next month, year and 5 years. | P0 | tiles | currency |
| QT-10 | Life regained | Units avoided × minutes of life per unit (≈ 20 min per cigarette, Jackson et al. 2025). | P0 | counter | minutes |
| QT-11 | Health milestones | Progress = current abstinence ÷ milestone time; the clock restarts after a slip. | P0 | milestones | count |
| QT-12 | Reduction progress | Days within limit ÷ days; reduction = 1 − average use ÷ baseline. | P0 | bars | percent |
| QT-13 | Craving load | Cravings per day over the period; mean and peak intensity; 7-day rolling mean. | P0 | line | perDay |
| QT-14 | Craving context | Pareto by trigger, place and mood; weekday × hour matrix. | P0 | pareto | count |

## global

| ID | Name | Formula (EN) | Priority | Chart | Unit |
|---|---|---|---|---|---|
| GL-01 | Today | Same numbers as each section’s metrics for today. | P0 | tiles | count |
| GL-02 | Week at a glance | Section KPIs to date with their change vs the previous week. | P0 | tiles | count |
| GL-03 | Weekly review | Section KPIs with their change vs the previous week. | P0 | list | count |
| GL-10 | Data quality | Habit logged ratio and unknown units (last 30 days); late-log share (> 24 h); planner actual-time coverage = done occurrences with tracked time ÷ done occurrences; pending sync changes. | P1 | tiles | count |

