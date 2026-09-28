# Section 6.4 — Checklist Insights

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 2.2, 2.3, 4.1, 4.3, 4.5, 6.1, 6.2
> Architecture: §6.12 (stats engine), §6.10 (checklist tree), §7.3 (`checklist_items`, `checklist_runs`, `activity_events`, `attachments`)

## Goal

Treat every checklist as a small flow system and measure it the way Kanban teams do. There are three
levels of statistics:

- **Items:** time in each status, cycle and lead time, age, blocked and waiting episodes, and churn.
- **Checklists:** status mix, throughput, WIP, cumulative flow, cycle-time distributions and
  service-level expectations, burn-down/up, blockers, tree shape, due-date performance and recurring runs.
- **Lists section:** a summary across all checklists.

Everything is computed from the status-change history recorded by [4.3] (`activity_events`) and the
current tree.

## Scope

**In:** event normalization, per-item, per-checklist and section metrics (catalog below), CFD
computation, forecasts, recurring-run stats, UI (item panel, checklist screen, Lists screen), fixtures.
**Out:** Status workflow and event recording ([4.3]); tree operations ([4.2]); math primitives, event
primitives and forecasting ([6.1]); chart widgets ([6.2]).

## Notation (used in all formulas below)

- **Status events:** `activity_events` with `entity_type = 'checklist_item'` and
  `event_type ∈ {created, status_changed, moved, deleted, restored}`. The `status_changed` payload is
  `{from, to, note}`. Events are ordered by `occurred_at`, then `rev` ([6.1] T6.1.11).
- **Stage order:** created → `todo` → `ongoing` → {`waiting`, `blocked`} → `completed`.
  - **WIP / in progress** = ongoing + waiting + blocked.
  - `cancelled` is terminal. It is excluded from CT/LT, throughput and percentiles, and counted separately.
- **Key times for an item i:**
  - **start(i)** = the first transition from `todo` into ongoing, waiting or blocked. An item completed
    directly from todo has no start and therefore no CT; it is counted as "completed without start".
  - **done(i)** = the last transition into `completed` (only while the item is still completed).
  - **created(i)** = the `created` event, or the row's `created_at` as a fallback.
- **CT(i) = done − start** (cycle time); **LT(i) = done − created** (lead time).
- **Leaf** = an item without live children. A **countable** item is one that is not cancelled.
- **Day-end sampling** happens at local midnight in the user's zone.
- **Time unit:** hours when the checklist's median CT is under 2 days; otherwise days, counted
  inclusively (same day = 1).
- **Stale threshold N** = `stats.staleDays` (default 14).

## Progress

- [x] T6.4.01 — Checklist stats adapter & event normalization
- [x] T6.4.02 — Per-item flow metrics
- [ ] T6.4.03 — Per-item blocked, waiting & churn metrics
- [x] T6.4.04 — Checklist status & throughput metrics
- [ ] T6.4.05 — Cumulative flow diagram (CFD)
- [ ] T6.4.06 — Cycle-time distribution, SLE & aging WIP
- [ ] T6.4.07 — Burn-down, burn-up & scope creep
- [ ] T6.4.08 — Blocked & waiting analytics
- [ ] T6.4.09 — Tree shape, integrity & branch contribution
- [ ] T6.4.10 — Due-date performance
- [ ] T6.4.11 — Recurring checklist run stats
- [x] T6.4.12 — Lists section overview metrics
- [ ] T6.4.13 — Section benchmarks & completion calendars
- [ ] T6.4.14 — Advanced flow analytics
- [x] T6.4.15 — Item insights panel
- [x] T6.4.16 — Checklist Insights screen
- [x] T6.4.17 — Lists Insights screen
- [x] T6.4.18 — Checklist stats fixtures

## Tasks

### T6.4.01 — Checklist stats adapter & event normalization
**Priority:** P0 · **Size:** M · **Depends on:** [6.1] (T6.1.11 event primitives, T6.1.12 loaders, T6.1.13 isolate), [4.3] (status events)
**Description:** Build per-item status timelines and per-checklist snapshots that every checklist
metric uses.
**Implementation notes:**
- `ChecklistItemFact` fields: `id`, `checklistId`, `parentId`, `depth`, `isLeaf`, `created`, `start`,
  `done`, `intervals` (by status), `reopens`, `statusChanges`, `blockedEpisodes` and `waitingEpisodes`
  (each with a note), `dueAt`, `followUpAt`, `deletedAt`, `lastActivityAt`.
- `moved` events split membership when an item changes checklist. A moved item counts in the source
  list until it moves and in the target list afterwards.
- Deleted items stop counting at `deleted_at`. They appear as "removed from scope" in burn-up.
**Data model:**
- `moved` events must carry `fromChecklistId`, `toChecklistId`, `fromParentId` and `toParentId`.
- `status_changed` events must be written for every change, including bulk changes and changes
  cascaded from parents ([4.3]).
**Acceptance criteria:** for the `checklist_flow_small` fixture, the facts (intervals, start/done,
reopens) match the expectations exactly.
**Tests:** unit tests covering reopen, cancel, move, delete/restore, and events with identical timestamps.
**Notes:** `domain/checklist_resolution.dart` (`ChecklistFacts`) normalizes `created / status_changed / moved / deleted / restored` events (payload keys as written by the checklists feature) into the package's `ChecklistItemFact`s; other event types feed staleness. The single-list loader also loads items that moved out so their history stays in the source list. Tests: `checklists/checklist_adapter_test.dart` (reopen + cancel, delete/restore, identical timestamps by rev, move membership) and the `checklist_flow_small` fixture.

### T6.4.02 — Per-item flow metrics
**Priority:** P0 · **Size:** M · **Depends on:** T6.4.01, [6.2] (bars T6.2.04, progress ring T6.2.07)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| CL-I-01 | Time in status | Σ interval lengths per status (todo, ongoing, waiting, blocked, completed, cancelled) until now or deletion | events | stacked status timeline bar | P0 |
| CL-I-02 | Cycle time | CT = done − start | events | value | P0 |
| CL-I-03 | Lead time | LT = done − created | events | value | P0 |
| CL-I-04 | Age | open and started: now − start (work-item age); open and not started: now − created (queue age) | events | value + aging chip | P0 |
| CL-I-05 | Staleness | now − last activity (status change, edit, attachment, child change) | events | value | P0 |
| CL-I-06 | Subtree progress | leaf-based = completed countable leaves ÷ countable leaves; recursive = mean of children's progress; descendant count | tree | progress ring | P0 |
| CL-I-07 | Status timeline | the item's history as colored segments with notes | events | timeline bar | P0 |

**Acceptance criteria:** consider an item with this history:

| When | Transition |
|---|---|
| 09-01 09:00 | created |
| 09-02 10:00 | → ongoing |
| 09-03 10:00 | → waiting ("waiting for Sam") |
| 09-05 10:00 | → ongoing |
| 09-06 10:00 | → blocked |
| 09-07 10:00 | → ongoing |
| 09-08 10:00 | → completed |

It must give LT = 7 d 1 h and CT = 6 d. Time in status must be todo 1 d 1 h, ongoing 3 d, waiting 2 d
and blocked 1 d.
**Tests:** fixture tests; timeline golden.
**Notes:** CL-I-01…07; the acceptance item (LT 7 d 1 h, CT 6 d, 25/72/48/24 h) is in the `checklist_flow_small` fixture; the timeline is covered by the item screen goldens.

### T6.4.03 — Per-item blocked, waiting & churn metrics
**Priority:** P1 · **Size:** M · **Depends on:** T6.4.02

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| CL-I-08 | Blocked episodes | count of blocked intervals; total blocked time; % of CT blocked; reasons (notes) | events | bars + list | P1 |
| CL-I-09 | Waiting episodes | count; total wait; current wait age; follow-up overdue flag (`follow_up_at` < now while waiting) | events, item | list + age chip | P1 |
| CL-I-10 | Flow efficiency | time in ongoing ÷ CT | events | % tile | P1 |
| CL-I-11 | Churn | number of status changes; reopens (completed → other); ongoing ↔ waiting loops | events | counts | P1 |
| CL-I-12 | Time to first action | start − created (queue time) | events | value | P1 |

**Acceptance criteria:** the T6.4.02 item gives flow efficiency 50 %, blocked share 16.7 % of CT,
6 status changes, 0 reopens and 1 ongoing↔waiting loop.
**Tests:** fixture tests.

### T6.4.04 — Checklist status & throughput metrics
**Priority:** P0 · **Size:** M · **Depends on:** T6.4.01, [6.2] (donut T6.2.05, bars T6.2.04, line T6.2.03)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| CL-L-01 | Status mix | count per status; % done leaf-based and node-based | items | donut + bar | P0 |
| CL-L-02 | Progress over time | per day: F(d) ÷ (A(d) − cancelled(d)) (leaf-based toggle) | events | line | P0 |
| CL-L-03 | Throughput | items completed per day/week (exact count) + 4-week rolling mean | events | bars + line | P0 |
| CL-L-04 | WIP | count of ongoing + waiting + blocked items at each day end | events | line | P0 |
| CL-L-05 | Arrivals vs departures | items created vs completed per week; net flow | events | paired bars | P0 |
| CL-L-06 | Stale items | open items with staleness ≥ N days; the 10 oldest open items with ages | facts | list + count | P0 |

**Acceptance criteria:** a reopened then re-completed item counts once in throughput, on its final
completion day; creations in another list that were moved in count as arrivals on the move day.
**Tests:** fixture tests.
**Notes:** CL-L-01…06 (throughput bars now drill into the items completed each week). Fixture covers the reopen-counted-once and moved-in-arrival acceptance cases.

### T6.4.05 — Cumulative flow diagram (CFD)
**Priority:** P1 · **Size:** M · **Depends on:** T6.4.04, [6.2] (stacked area / CFD T6.2.16)
**Description:** Exact CFD computed from the event log.
**Implementation notes:**
- **State per item per day:** for each day end d, state(i, d) = the `to` of the last status event at or
  before d. An item whose only event is `created` is `todo`. Items created after d, or deleted by d, are
  excluded.
- **Bands** (bottom to top): completed, blocked, waiting, ongoing, todo. Cancelled items are hidden by
  default, with a toggle to show them as a separate top band.
- **Boundary lines:** A(d), S(d) and F(d) from [6.1] T6.1.11, exposed for annotations. At a selected
  date:
  - **WIP** is the count of in-progress items (the vertical distance between the lines).
  - **Approximate CT** is d − d′, where F(d) = S(d′) (the horizontal distance between the lines).
  - **Throughput** is the slope of F over the last 14 days.
- **Reopens** make the completed band drop. They are marked with a dot and counted separately.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| CL-L-07 | Cumulative flow | daily state counts per band + WIP / approx-CT / throughput annotations | events | CFD | P1 |

**Acceptance criteria:** use the 5-day fixture below.

| Day | Events that day |
|---|---|
| d1 | A, B, C created; A → ongoing |
| d2 | A → completed; B → ongoing; D created |
| d3 | B → blocked; C → ongoing; A reopened → ongoing |
| d4 | B → ongoing; A → completed; E created; D deleted |
| d5 | B → completed; C → waiting |

The CFD must produce these day-end band counts, and report 1 reopen:

| Day | todo | ongoing | waiting | blocked | completed |
|---|---|---|---|---|---|
| d1 | 2 | 1 | 0 | 0 | 0 |
| d2 | 2 | 1 | 0 | 0 | 1 |
| d3 | 1 | 2 | 0 | 1 | 0 |
| d4 | 1 | 2 | 0 | 0 | 1 |
| d5 | 1 | 0 | 1 | 0 | 2 |

**Tests:** fixture test using exactly this dataset; CFD golden.

### T6.4.06 — Cycle-time distribution, SLE & aging WIP
**Priority:** P1 · **Size:** M · **Depends on:** T6.4.04, [6.2] (scatter T6.2.15, histogram T6.2.14)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| CL-L-08 | CT distribution | histogram of CT; scatter by completion date with P50/P70/P85/P95 lines | facts | histogram + scatter | P1 |
| CL-L-09 | Service-level expectation | "85 % of items finish within X" where X = P85 CT over a rolling 90 days | facts | tile | P1 |
| CL-L-10 | Aging WIP | each open started item at (status column, age); background bands at CT P50/P85; items older than P85 highlighted as "at risk" | facts | aging scatter | P1 |

**Acceptance criteria:** items completed without a start are excluded from CT percentiles and reported
as a count; P85 is hidden when fewer than 10 items have a CT.
**Tests:** fixture tests.

### T6.4.07 — Burn-down, burn-up & scope creep
**Priority:** P1 · **Size:** S · **Depends on:** T6.4.05, [6.2] (burn charts T6.2.17)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| CL-L-11 | Burn-down | remaining(d) = A(d) − F(d) − cancelled(d); ideal line from the start to `due_local` when the checklist has a due date | events | line | P1 |
| CL-L-12 | Burn-up & scope creep | scope(d) = A(d) − cancelled(d) and done(d) = F(d); scope creep = items added after the baseline date ÷ items at baseline (baseline = first status change, or a user-set start) | events | burn-up | P1 |
| CL-L-13 | Cancelled & shortcut share | cancelled ÷ total created; "completed without start" ÷ completed | facts | tiles | P1 |

**Acceptance criteria:** adding 3 items to a 10-item list after the baseline shows 30 % scope creep
and a step in the scope line.
**Tests:** fixture tests.

### T6.4.08 — Blocked & waiting analytics
**Priority:** P1 · **Size:** M · **Depends on:** T6.4.03, [6.2] (Pareto T6.2.05)
**Description:** Blocker and waiting-for analytics, at the level of one checklist and across all lists.
**Implementation notes:** the waiting-for register uses the explicit "waiting on" field when present.
Otherwise it parses the note with heuristics: a leading `@name`, `name:`, "waiting for X",
"en attente de X" or "بانتظار X". Entities that are not recognized are grouped as "Unspecified".
**Data model:** an optional `checklist_items.waiting_on text` column (who or what the item is
waiting for). This is set in the waiting-reason sheet in [4.3].

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| CL-L-14 | Blocked & waiting now | current blocked/waiting counts with ages; total blocked time in P; top reasons | facts | tiles + list | P1 |
| CL-L-15 | Follow-up discipline | among waiting/blocked episodes with `follow_up_at`: on time = an activity on the item by `follow_up_at` + 24 h; overdue follow-ups = open items past `follow_up_at` with no activity since | facts | % tile + list | P1 |
| CL-X-06 | Reasons across lists | Pareto of blocked and waiting reasons (normalized text), count and total time | facts | Pareto | P1 |
| CL-X-07 | Waiting-for register | waiting episodes grouped by entity: open count, mean wait, longest current wait, overdue follow-ups | facts | table | P1 |
| CL-X-08 | Most blocked lists | lists ranked by total blocked time in P | facts | bars | P1 |

**Acceptance criteria:** notes "waiting for Sam" and "@sam invoice" group under "Sam" (case-insensitive).
**Tests:** parser unit tests (EN/FR/AR); fixture tests.

### T6.4.09 — Tree shape, integrity & branch contribution
**Priority:** P1 · **Size:** S · **Depends on:** T6.4.02

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| CL-L-16 | Tree shape | max depth; mean leaf depth; mean branching factor (children per non-leaf); leaves; widest level; largest subtree size | tree | bars + indented tree | P1 |
| CL-L-17 | Integrity flags | completed parent with open descendants; all children completed but parent open; waiting/blocked without a reason (when reasons are required) | tree, items | warning list | P1 |
| CL-L-18 | Branch contribution | per top-level branch: progress, throughput, blocked time | facts | bars | P1 |

**Acceptance criteria:** tapping an integrity flag opens the checklist focused on that item.
**Tests:** fixture tests with a 12-level tree.

### T6.4.10 — Due-date performance
**Priority:** P1 · **Size:** S · **Depends on:** T6.4.02

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| CL-L-19 | Due-date performance | among items with `due_local`: on-time rate = completed with done ≤ due ÷ completed with a due date; open overdue count and ages; mean days late | items, events | tiles + aging bars | P1 |

**Acceptance criteria:** due instants are resolved with the item's zone or as floating ([2.3] time utilities).
**Tests:** fixture tests across time zones.

### T6.4.11 — Recurring checklist run stats
**Priority:** P1 · **Size:** M · **Depends on:** T6.4.01, [4.5] (resettable checklists)
**Description:** Statistics across the runs of a resettable checklist, such as a daily morning routine.
**Data model:** `checklist_runs.snapshot` must store, for every item, `{itemId, status,
completedAt}` at reset time (arch §7.3).

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| CL-L-20 | Run completion | per run: completed_items ÷ total_items at reset; mean over P; trend | checklist_runs | line + bars | P1 |
| CL-L-21 | Fully-completed runs streak | consecutive runs at 100 % (streak engine, unit = run) | checklist_runs | chip + streak bars | P1 |
| CL-L-22 | Time to finish a run | last completedAt − run start for 100 % runs; median and P85 | snapshots | box plot | P1 |
| CL-L-23 | Most-skipped items | items most often not completed at reset (count and %) | snapshots | ranked bars | P1 |
| CL-L-24 | Run completion by weekday | mean completion % per weekday | checklist_runs | bars | P1 |

**Acceptance criteria:** a 7-run fixture with completion 100, 100, 80, 100, 100, 100, 60 % gives a mean
of 91.4 %, a best streak of 3 and a current streak of 0.
**Tests:** fixture tests.

### T6.4.12 — Lists section overview metrics
**Priority:** P0 · **Size:** M · **Depends on:** T6.4.04

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| CL-X-01 | Lists overview | total, active, archived and template checklists; stale lists = no activity for ≥ N days while holding open items | checklists, facts | tiles | P0 |
| CL-X-02 | Arrivals vs departures (all lists) | items created vs completed per week; net flow | events | paired bars | P0 |
| CL-X-03 | Global WIP / blocked / waiting | counts across lists; the 10 oldest open items | facts | tiles + list | P0 |
| CL-X-04 | Items completed | completed in P with Δ vs the previous period | events | KPI | P0 |
| CL-X-05 | Status distribution | status counts across all lists | items | 100 % bar | P0 |

**Acceptance criteria:** archived lists are excluded from WIP but included in historical throughput.
**Tests:** fixture tests.
**Notes:** CL-X-01…05; archived lists leave WIP but keep historical throughput (`checklists/checklist_section_test.dart`).

### T6.4.13 — Section benchmarks & completion calendars
**Priority:** P1 · **Size:** S · **Depends on:** T6.4.06, T6.4.12, [6.2] (calendar heatmap T6.2.06)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| CL-X-09 | Flow benchmarks | section-wide CT P50/P85; throughput trend slope (per week) | facts | tiles + line | P1 |
| CL-X-10 | Completion calendar (section) | completions per day; streak of days with ≥ 1 completion | events | calendar heatmap | P1 |
| CL-L-25 | Completion calendar (one list) | same as CL-X-10, for one checklist | events | calendar heatmap | P1 |

**Tests:** fixture tests.

### T6.4.14 — Advanced flow analytics
**Priority:** P2 · **Size:** M · **Depends on:** T6.4.05, T6.4.06, T6.4.08, [6.1] (T6.1.26 Monte Carlo), [6.2] (forecast visuals T6.2.26)
**Implementation notes:**
- **Blocker clustering:** normalize the reason text (lowercase, trim, strip punctuation, remove
  EN/FR/AR stopwords, light stemming). Users can merge and rename clusters; the mapping is stored in
  `user_settings.stats.blockerClusters`.
- **Little's Law check:** compute ratio = mean CT ÷ (mean WIP ÷ mean throughput) over a stable window.
  Flag the flow as "unstable" when the ratio falls outside [0.7, 1.3], when arrivals ÷ departures falls
  outside [0.8, 1.2], or when mean WIP age is rising.

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| CL-L-26 | Blocker clustering | clusters ranked by episodes × total blocked time (Pareto) | facts | Pareto | P2 |
| CL-L-27 | Little's Law diagnostic | ratio and stability flag (never used as a forecast) | facts | diagnostic tile | P2 |
| CL-L-28 | Monte Carlo forecast | finish date for the remaining items at P50/P85/P95; "how many by date X" | throughput history | probability histogram + cone | P2 |
| CL-L-29 | Depth-level progress | % done per depth level | tree | bars | P2 |
| CL-L-30 | Attachments summary | count and total size by type (image/PDF/other) for the list | attachments | tiles | P2 |
| CL-I-13 | Item attachments | count, total size, type mix | attachments | tile | P2 |
| CL-I-14 | Edit activity | number of text edits; last edited | events | value | P2 |
| CL-X-11 | Attachment storage used | Σ byte_size across lists | attachments | tile | P2 |
| CL-X-12 | List creation & archival trend | checklists created/archived per month | checklists | bars | P2 |

**Acceptance criteria:** the forecast is hidden until ≥ 30 days of history and ≥ 10 completions exist;
the forecast wording is probabilistic ("85 % chance by …").
**Tests:** seeded fixture tests.

### T6.4.15 — Item insights panel
**Priority:** P0 · **Size:** S · **Depends on:** T6.4.02, [4.2] (item details sheet)
**Description:** An "Insights" section in the item details sheet.
- P0: CL-I-01 to CL-I-07.
- P1 adds CL-I-08 to CL-I-12.
- P2 adds CL-I-13 and CL-I-14.
**Acceptance criteria:** opens in < 100 ms for items with 200 events; the reasons shown are the actual
notes.
**Tests:** widget tests; golden.
**Notes:** `ItemStatsPanel(itemId)` (exported by `features/stats/insights.dart`) with CL-I-01…07 and the actual reason notes in the status timeline; no period selector. TODO(integration): the checklists feature embeds it in the item details sheet (checklists-owned file); `/insights/item/:id` already shows it. The 200-event budget is measured by T6.1.23.

### T6.4.16 — Checklist Insights screen
**Priority:** P0 · **Size:** M · **Depends on:** T6.4.04, [6.1] (T6.1.16 framework)
**Description:** Scope screen `/insights/checklist/:id`.
- **P0 KPI row:** % done, throughput this week, WIP, blocked + waiting, stale items.
- **P0 sections:** Status, Flow, Stale.
- **P1 sections:** CFD, cycle time & SLE, aging WIP, burn charts, blockers & waiting, tree health, due
  dates, runs (recurring lists only).
- **P2 section:** Forecast & diagnostics.
**Acceptance criteria:** drill-down from any chart opens the checklist filtered to those items; a
50-item list with 6 months of history renders within budget.
**Tests:** widget tests; goldens.
**Notes:** `checklistLayout` (KPIs CL-L-01/03/04/06; Status, Flow, Stale sections); chart elements open a drill sheet of the items behind them, each opening the item in its list. "Blocked + waiting" joins the KPI row with the P1 blocked/waiting metrics (T6.4.08).

### T6.4.17 — Lists Insights screen
**Priority:** P0 · **Size:** M · **Depends on:** T6.4.12, [6.1] (T6.1.16, T6.1.17)
**Description:** Scope screen `/insights/checklists`.
- **P0:** CL-X-01 to CL-X-05, plus a list ranking (most active, most blocked, stalest).
- **P1:** CL-X-06 to CL-X-10.
- **P2:** CL-X-11 and CL-X-12.
**Tests:** widget tests; goldens.
**Notes:** `checklistsLayout` (CL-X-01…05); CL-X-01's card adds the list ranking tabs (most active, most blocked, stalest), each row opening its list.

### T6.4.18 — Checklist stats fixtures
**Priority:** P0 · **Size:** M · **Depends on:** [6.1] (T6.1.15)
**Description:** Fixture datasets with hand-computed expectations:
- `checklist_flow_small`: the T6.4.02 item plus the T6.4.05 CFD dataset.
- `checklist_tree_deep`: 12 levels, integrity violations.
- `checklist_runs_week`: 7 runs of a morning routine.
**Acceptance criteria:** the fixture runner passes for all P0 metrics (P1/P2 metrics are added as implemented).
**Tests:** provides fixtures for the tasks above.
**Notes:** `checklist_flow_small` table fixture covers all 18 P0 checklist metrics; `checklist_tree_deep` and `checklist_runs_week` stay package fixtures until their P1 metrics (T6.4.09, T6.4.11) are registered.
