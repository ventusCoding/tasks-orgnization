# Metrics catalog

Generated from the metric registry (`app/lib/features/stats/application/catalog/`) by
`app/test/features/stats/engine/metric_catalog_test.dart` — do not edit by hand.

177 metrics.

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
| PL-T-08 | Reschedules | Number of “rescheduled” events of this occurrence. | P1 | moveTimeline | count |
| PL-T-09 | Reschedule distance | Σ \|new start − old start\| over every move. | P1 | kpi | minutes |
| PL-T-10 | Net drift | Final planned start − first planned start. | P1 | kpi | minutes |
| PL-T-11 | Snowballing | Shown when the occurrence was moved 3 times or more. | P1 | list | count |
| PL-T-12 | Lead time | Done time − task creation time. | P1 | kpi | minutes |
| PL-T-13 | Start latency | First session start − task creation time. | P1 | kpi | minutes |
| PL-T-14 | Planning horizon | First planned start − task creation time. | P1 | kpi | minutes |
| PL-T-15 | Slot fit | Overlap(sessions, planned slot) ÷ actual minutes. | P1 | gantt | percent |
| PL-T-16 | Focus sessions | Pauses = gaps ≥ 2 min; sessions less than 2 min apart form one block. | P1 | tiles | count |
| PL-T-17 | Partial completion | Completion percent recorded with the occurrence. | P1 | ring | percent |
| PL-T-18 | Self-rating | Rating and note saved when finishing. | P1 | list | count |

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
| PL-S-10 | Skip rate & reasons | Skipped ÷ scheduled; reasons ranked by count. | P1 | pareto | percent |
| PL-S-11 | Start timeliness | On-time starts ÷ started occurrences; box plot of start delay. | P1 | boxPlot | percent |
| PL-S-12 | On-time completion | Done on time ÷ done. | P1 | kpi | percent |
| PL-S-13 | Top streaks | Streaks ordered by length, then by recency. | P1 | streakBars | count |
| PL-S-14 | Series strength | score = score·m + done·(1 − m), m = 0.5^(√f/13), f = occurrences per day. | P1 | line | score |
| PL-S-15 | Duration stability | Median, mean, SD and CV of actual minutes; median of actual ÷ planned. | P1 | boxPlot | minutes |
| PL-S-16 | Weekday profile | Done ÷ closed, non-excused occurrences per weekday. | P1 | bars | percent |
| PL-S-17 | Completion hours | Done occurrences per hour of the done time. | P1 | bars | count |
| PL-S-18 | Series reschedules | Moved ≥ 1× ÷ occurrences; mean moves; mean postponement. | P1 | tiles | percent |
| PL-S-19 | Rule changes | Adherence in the 28 days before vs after each split. | P1 | line | count |
| PL-S-20 | Time-of-day consistency | Circular mean and circular SD of start (or done) times. | P2 | rose | clock |
| PL-S-21 | Start drift | Circular mean of (actual start − planned start), within ±12 h. | P2 | kpi | minutes |

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
| PL-X-16 | Time by priority | Σ minutes per priority 0–4 (actual when tracked, else planned). | P1 | percentBars | minutes |
| PL-X-17 | Time by tag | Σ minutes per tag. | P1 | horizontalBars | minutes |
| PL-X-18 | Priority alignment | Share of time on priorities 3–4; completion rate high vs low. | P1 | percentBars | percent |
| PL-X-19 | Allocation map | Area ∝ minutes (category → task). | P1 | treemap | minutes |
| PL-X-20 | Recurring vs one-off | Recurring minutes ÷ all minutes; completions of each. | P1 | donut | percent |
| PL-X-21 | Estimation bias | exp(median ln(actual ÷ planned)) − 1; needs 10 tracked occurrences. | P1 | kpi | percent |
| PL-X-22 | Estimation error | mean(\|actual − planned\| ÷ planned) (MAPE). | P1 | kpi | percent |
| PL-X-23 | Suggested buffer | P80(actual ÷ planned) − 1. | P1 | kpi | percent |
| PL-X-24 | Planned vs actual | Points (planned, actual) with the y = x line and a ±20 % band. | P1 | scatter | count |
| PL-X-25 | Planned durations | Histogram of planned minutes; median and mean. | P1 | histogram | minutes |
| PL-X-26 | Accuracy by category | Bias and MAPE computed within each category. | P1 | groupedBars | percent |
| PL-X-27 | Punctuality | On-time starts ÷ started occurrences. | P1 | kpi | percent |
| PL-X-28 | Start delay | Median, mean and P85 of (actual start − planned start). | P1 | punchCard | minutes |
| PL-X-29 | Reschedule share | Occurrences moved ≥ 1× ÷ occurrences in the period. | P1 | kpi | percent |
| PL-X-30 | Hours postponed | Σ forward postponement (hours); mean moves per moved occurrence. | P1 | tiles | hours |
| PL-X-31 | Procrastination index | Occurrences with final start > first planned start ÷ occurrences. | P1 | kpi | percent |
| PL-X-32 | Skips & reasons | Skipped ÷ scheduled; reasons ranked by count. | P1 | pareto | percent |
| PL-X-33 | Busiest hours | Minutes (or completions) per weekday × hour. | P1 | punchCard | minutes |
| PL-X-34 | Best working days | Done ÷ closed occurrences and tracked hours per weekday. | P1 | groupedBars | percent |
| PL-X-35 | Slot occupancy | Weeks with a planned task in the slot ÷ weeks in the period. | P1 | matrix | percent |
| PL-X-36 | Unused slots | Slots inside work hours with 0 % occupancy. | P1 | list | count |
| PL-X-37 | Most productive hours | Done ÷ closed occurrences per hour of planned start. | P1 | bars | percent |
| PL-X-38 | Deep work | Blocks ≥ 60 min (setting); same-task sessions < 2 min apart are merged. | P1 | bars | hours |
| PL-X-39 | After-hours work | Σ tracked minutes outside work hours; weekend minutes. | P1 | bars | minutes |
| PL-X-40 | Timer usage | Sessions, mean session length, share of done occurrences with sessions. | P1 | tiles | count |
| PL-X-41 | Actual-time coverage | Done occurrences with sessions ÷ done occurrences. | P1 | kpi | percent |
| PL-X-42 | Goal streak | Days with ≥ N completions in a row; days without capacity are neutral. | P1 | streakBars | count |
| PL-X-43 | Fragmentation | 1 − largest free block ÷ total free time (0 = one free block). | P2 | bars | percent |
| PL-X-44 | Context switches | Category changes between consecutive sessions ÷ tracked hours. | P2 | line | count |
| PL-X-45 | Productivity score | 100 · Σ(weight × minutes) ÷ (4 · Σ minutes) over weighted categories. | P2 | line | score |
| PL-X-46 | Planning ahead | Histogram of (first planned start − creation time), in hours. | P2 | histogram | hours |

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
| CL-I-08 | Blocked episodes | Number of blocked intervals, total blocked time and its share of the cycle time. | P1 | list | hours |
| CL-I-09 | Waiting episodes | Number of waiting intervals, total wait, current wait; follow-up overdue when the date passed while waiting. | P1 | list | hours |
| CL-I-10 | Flow efficiency | Time in ongoing ÷ cycle time. | P1 | kpi | percent |
| CL-I-11 | Churn | Status changes; reopens (completed → other); ongoing ↔ waiting loops. | P1 | tiles | count |
| CL-I-12 | Time to first action | Start − created (queue time). | P1 | kpi | hours |
| CL-I-13 | Item attachments | Count, total size and type mix (images, PDFs, other). | P2 | tiles | count |
| CL-I-14 | Edit activity | Number of text edits; last edit time. | P2 | kpi | count |

## checklist

| ID | Name | Formula (EN) | Priority | Chart | Unit |
|---|---|---|---|---|---|
| CL-L-01 | Status mix | Items per status; % done over leaves and over all nodes. | P0 | donut | percent |
| CL-L-02 | Progress over time | Completed ÷ (items in scope − cancelled) at each day end. | P0 | line | percent |
| CL-L-03 | Throughput | Completions per bucket (a reopened item counts once, on its final completion). | P0 | bars | count |
| CL-L-04 | Work in progress | Count of ongoing + waiting + blocked items. | P0 | line | count |
| CL-L-05 | Arrivals vs departures | Weekly created (or moved in) vs completed; net flow = difference. | P0 | groupedBars | count |
| CL-L-06 | Stale items | Open items with staleness ≥ the stale threshold; 10 oldest by age. | P0 | list | count |
| CL-L-07 | Cumulative flow | Day-end counts per status from the event log; WIP, approximate cycle time and throughput at a date. | P1 | cfd | count |
| CL-L-08 | Cycle-time distribution | Histogram of cycle times; scatter by completion date with P50/P70/P85/P95 lines. | P1 | histogram | hours |
| CL-L-09 | Service level | P85 of the cycle time over the last 90 days. | P1 | kpi | hours |
| CL-L-10 | Aging work in progress | Age = now − start; at risk when older than P85 of the cycle time. | P1 | scatter | count |
| CL-L-11 | Burn-down | Remaining = arrived − completed − cancelled; forecast cone when enough history. | P1 | burn | count |
| CL-L-12 | Scope creep | Items added after the baseline ÷ items at the baseline (first status change). | P1 | burn | percent |
| CL-L-13 | Cancelled & shortcuts | Cancelled ÷ created; completed without start ÷ completed. | P1 | tiles | percent |
| CL-L-14 | Blocked & waiting now | Current blocked and waiting counts with ages; blocked time in the period; top reasons. | P1 | list | count |
| CL-L-15 | Follow-up discipline | Episodes acted on within 24 h of the follow-up ÷ episodes with a follow-up date; overdue follow-ups listed. | P1 | list | percent |
| CL-L-16 | Tree shape | Max depth, mean leaf depth, children per parent, leaves, widest level and largest branch. | P1 | tiles | count |
| CL-L-17 | Integrity checks | Completed parents with open children; open parents whose children are all done; missing reasons. | P1 | list | count |
| CL-L-18 | Branch contribution | Leaf-based progress per branch; completions and blocked time in the period. | P1 | horizontalBars | percent |
| CL-L-19 | Due-date performance | Done by the due time ÷ completed with a due date; open overdue items and mean days late. | P1 | bars | percent |
| CL-L-20 | Run completion | Completed ÷ total items per run; mean and trend. | P1 | line | percent |
| CL-L-21 | Perfect-run streak | Streak of fully completed runs. | P1 | streakBars | count |
| CL-L-22 | Time to finish a run | Last completion − run start for 100 % runs; median and P85. | P1 | boxPlot | minutes |
| CL-L-23 | Most-skipped items | Times not completed at reset, and share of runs. | P1 | horizontalBars | count |
| CL-L-24 | Runs by weekday | Mean completion % per weekday. | P1 | bars | percent |
| CL-L-25 | Completion calendar | Completions per day; streak of days with at least one. | P1 | calendar | days |
| CL-L-26 | Blocker clusters | Normalized reasons; rank = episodes × blocked hours; clusters can be merged in settings. | P2 | pareto | count |
| CL-L-27 | Little’s Law check | mean cycle time ÷ (mean WIP ÷ mean throughput); unstable outside 0.7–1.3 or when arrivals ÷ departures leaves 0.8–1.2. | P2 | tiles | ratio |
| CL-L-28 | Finish forecast | 10 000 simulations resampling recent daily completions; dates at 50 %, 85 % and 95 % chance. | P2 | forecast | days |
| CL-L-29 | Progress by depth | Completed ÷ countable items per depth level. | P2 | bars | percent |
| CL-L-30 | List attachments | Count, total size and type mix. | P2 | tiles | count |

## checklists

| ID | Name | Formula (EN) | Priority | Chart | Unit |
|---|---|---|---|---|---|
| CL-X-01 | Lists overview | Counts of lists; stale = no activity for N days while holding open items. | P0 | tiles | count |
| CL-X-02 | Arrivals vs departures (all lists) | Weekly created vs completed; net flow = difference. | P0 | groupedBars | count |
| CL-X-03 | Work in progress across lists | Counts across active lists (archived excluded). | P0 | tiles | count |
| CL-X-04 | Items completed | Final completions in the period, compared with the previous period. | P0 | kpi | count |
| CL-X-05 | Status distribution | Count of live items per status. | P0 | percentBars | count |
| CL-X-06 | Reasons across lists | Pareto of normalized reasons: episodes and total time. | P1 | pareto | count |
| CL-X-07 | Waiting-for register | Waiting episodes grouped by person or thing: open count, mean wait, longest wait, overdue follow-ups. | P1 | list | count |
| CL-X-08 | Most blocked lists | Lists ranked by total blocked time in the period. | P1 | horizontalBars | hours |
| CL-X-09 | Flow benchmarks | Section-wide cycle-time P50/P85; weekly throughput slope. | P1 | tiles | hours |
| CL-X-10 | Completion calendar | Completions per day; streak of days with at least one. | P1 | calendar | days |
| CL-X-11 | Attachment storage | Σ attachment sizes; count and type mix. | P2 | tiles | bytes |
| CL-X-12 | Lists created & archived | Checklists created and archived per month. | P2 | groupedBars | count |

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

