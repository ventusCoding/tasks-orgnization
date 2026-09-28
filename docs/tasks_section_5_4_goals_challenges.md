# Section 5.4 — Goals, Challenges, Streak Freezes & Achievements

> Milestones: M2 (P1) · M3 (P2) · Depends on: 5.1, 5.2, 5.3, 1.2, 1.4, 6.1
> Architecture: §7.3 (goals, achievements, habit_logs), §6.11 (period evaluation), §9.2 (UUIDv5)

## Goal

Add longer-horizon motivation on top of daily check-ins, computed offline from the same logs:
numeric **goals** (10 000 push-ups this year, 30 clean days, 500 € saved), time-boxed **challenges**
(30-day push-up challenge), **streak freezes** that forgive an occasional miss transparently, and
**achievements** / personal records.

## Scope

**In:** goals model, editor, progress & projection engine, goal surfaces; challenges (progressive targets in
P2); streak freezes; achievements catalog & unlock engine; badge gallery & share cards; personal-record moments.
**Out:** goal and record charts in Insights ([6.5], [6.7]); notifications for goals, milestones and records
([7.5]); XP/levels gamification ([9.3]).

## Progress

- [x] T5.4.01 — Goals: migration, Drift & domain
- [x] T5.4.02 — Goal editor
- [x] T5.4.03 — Goal progress & projection engine
- [x] T5.4.04 — Goal surfaces & completion
- [x] T5.4.05 — Challenges
- [x] T5.4.06 — Streak freezes
- [x] T5.4.07 — Progressive challenge targets
- [x] T5.4.08 — Achievements: catalog & unlock engine
- [x] T5.4.09 — Badge gallery & share cards
- [x] T5.4.10 — Personal-record moments

## Tasks

### T5.4.01 — Goals: migration, Drift & domain
**Priority:** P1 · **Size:** M · **Depends on:** [1.2], [1.4]
**Description:** Create `app.goals` (arch §7.3) with `app.enable_sync` and pgTAP tests, its Drift table and
DAO, and the domain `Goal { scopeType, scopeId, metric, target, period, startDate, endDate, title, achievedAt }`.
**Implementation notes:** metric validity per scope — `total_value` (measurable habits), `completions` (any
habit or task series), `streak_days` (habits), `clean_days` / `money_saved` / `units_avoided` (quit trackers),
`tracked_minutes` (series, category), `items_completed` (checklists); periods `all_time | year | quarter |
month | week | custom` (custom requires start/end).
**Acceptance criteria:** invalid metric/scope combinations are rejected in domain and by a DB `CHECK`.
**Tests:** pgTAP isolation & checks; DAO and validation unit tests.
**Notes:** The table, sync wiring and Drift table came with the foundation; this adds migration `20260927120000_add_goals_checks.sql` (metric per scope, positive target, custom dates, scope id) with pgTAP `135_goals.test.sql` — written but not run against a local stack in this session. Domain `features/goals/domain/goal.dart` (same rules, habit-kind narrowing, period windows) and `GoalsRepository` (achieved once, habit deletion cascades).

### T5.4.02 — Goal editor
**Priority:** P1 · **Size:** M · **Depends on:** T5.4.01
**Description:** Create or edit a goal from the habit detail, quit dashboard, Insights or a global Goals
screen: scope, metric (filtered by scope), target, period, title; smart suggestions from the current pace
("At your pace you'd reach 8 400 reps this year — aim for 10 000?").
**Acceptance criteria:** impossible combinations can't be chosen; all texts localized; works offline.
**Tests:** widget tests.
**Notes:** Editor sheet for habit/quit goals (from the habit detail, quit dashboard and the Goals screen): measures filtered by habit kind, target, period (incl. custom dates), title, pace suggestion (`niceTargetAbove` of the projected end), delete. Scopes other than habits (series, categories, checklists) belong to [6.7]/other features and are not offered here.

### T5.4.03 — Goal progress & projection engine
**Priority:** P1 · **Size:** M · **Depends on:** T5.4.01, [6.1] (period model, trend functions)
**Description:** Pure functions in `everslot_metrics` computing, for any goal: current value, % complete, pace
line (target × elapsed / total), status (ahead / on track / behind), required rate per remaining day or
week, ETA from the recent rate (last 28 days) with a simple uncertainty band, and achievement detection.
This is the single implementation reused by [6.7] (goals & projections).
**Acceptance criteria:** fixture suite (steady, accelerating, stalled, already achieved, custom period, quit
money goal) matches expected values.
**Tests:** fixture tests in `fixtures/goals/*.json`.
**Notes:** The engine is `everslot_metrics` `goalProgress` (with its package tests); this adds the habit/quit adapter `evaluateHabitGoal` (per-day totals, done days, streak level, clean days, money saved, units avoided) with scenario tests (steady, stalled, achieved, custom period, streak, quit money/clean days) in `app/test/features/goals/`. The JSON fixture suite `fixtures/goals/*.json` for the package is not added (package outside this scope).

### T5.4.04 — Goal surfaces & completion
**Priority:** P1 · **Size:** S · **Depends on:** T5.4.02, T5.4.03
**Description:** Goal cards (progress bar + pace marker) on the habit detail ([5.2]), quit dashboard ([5.3])
and Today ([8.1]); a Goals screen (active, achieved, expired); on achievement set `achieved_at` once,
celebrate ([5.2]) and call the notification hook ([7.5]).
**Acceptance criteria:** achieving the same goal offline on two devices converges to one achieved state.
**Tests:** widget tests; service test for achievement detection.
**Notes:** Goal cards (progress bar + pace marker, status text + color, ETA / required rate / achieved date) on the habit detail and quit dashboard, and a Goals screen (active, achieved, ended). `achieved_at` is recorded once with the start of the day it was reached (deterministic across devices) and confirmed with a snackbar + haptic. TODO(integration): the [7.5] notification hook has no API on main yet; the Today [8.1] goal card belongs to the today feature.

### T5.4.05 — Challenges
**Priority:** P1 · **Size:** M · **Depends on:** [5.1] (schedule presets, templates)
**Description:** Time-boxed habits ("30-day challenge"): a habit with start and end dates plus challenge
presentation — "Day 12 of 30", days remaining, success rule (every day done, or ≥ X % of days), a completion
screen with a summary (days done, best streak, total volume) and *Keep going*, which turns it into an
ongoing habit (clears the end date, keeps history).
**Implementation notes:** challenge templates (30 days of push-ups, 21 days without sugar, 14 days of
meditation) added to the templates asset ([5.1]); the result screen is shown once, after the end date passes.
**Data model:** `habits.settings.challenge { successRule, minRatio }`.
**Acceptance criteria:** at the end date the challenge closes automatically and shows its result exactly once
per device.
**Tests:** success-rule unit tests; widget tests.
**Notes:** `challengeOutcome` (domain) + `ChallengeCard` on the detail screen, success-rule controls in the editor, and a result sheet shown once per device (local flag in `local_kv`) when the Habits tab opens after the end date, with Keep going. The challenge templates already exist in the templates catalog. Challenge celebrations reuse the result sheet (no overlay card).

### T5.4.06 — Streak freezes
**Priority:** P1 · **Size:** M · **Depends on:** [5.1] (period evaluation), [6.1] (streak rules)
**Description:** Optional forgiveness: each habit gets `freezes_per_month`; when a scheduled period closes as
missed or failed and a freeze is available, it is applied automatically and the period becomes **frozen** —
neutral for streaks but still a miss for completion-rate stats. Frozen periods are labelled clearly
(snowflake icon + text) and can be undone.
**Implementation notes:** freezes are materialized as the period's state log with kind `freeze` (same
deterministic id `v5(habit|key|state)`, so two devices converge), written by an idempotent "close periods" job
on app start and day rollover; the allotment resets monthly (no rollover in v1); [6.1] streak rules treat
`frozen` as neutral; add `frozen` to `PeriodResult.status` ([5.1]).
**Data model:** `habit_logs.kind = 'freeze'`.
**Acceptance criteria:** with 1 freeze per month, the first missed day keeps the streak and the second breaks it;
completion rate counts both misses.
**Tests:** fixtures for allocation across month boundaries; convergence test (two devices close the same period).
**Notes:** The streak engine (`everslot_metrics` `computeStreaks`) allots freezes per month virtually; `StreakFreezeJob` materializes them as `freeze` state rows (deterministic id, the period end as clock, source `auto`) for the last 62 days, at start-up and when the Habits tab opens or resumes. Frozen days show the snowflake + *Frozen* label. Partial: undoing a freeze is not offered — the engine would forgive the miss again from the allotment; quota periods stay virtual (logs cannot carry quota keys).

### T5.4.07 — Progressive challenge targets
**Priority:** P2 · **Size:** S · **Depends on:** T5.4.05
**Description:** Targets that grow during a challenge (start at 10 push-ups, +2 every 3 days, max 50),
implemented as generated `habit_revisions` or a progression rule evaluated per period.
**Data model:** `habits.settings.targetProgression { start, step, everyDays, max }` (if not using
generated revisions).
**Tests:** evaluation fixtures.
**Notes:** Implemented as `habits.settings.targetProgression` evaluated per period by the period service (no generated revisions); the editor sets it for measurable challenges with a today-target preview. Editing the progression re-evaluates past days too (settings are not revisioned).

### T5.4.08 — Achievements: catalog & unlock engine
**Priority:** P2 · **Size:** M · **Depends on:** T5.4.03, [5.3] (quit calculator)
**Description:** Create `app.achievements` (arch §7.3) and a badge catalog: first check-in, first perfect
day, streaks 7/30/100/365, totals (1 000 / 10 000 reps), perfect week, challenge completed, quit milestones
(1 day, 1 week, 30 days, 100 days, 1 year clean), money-saved thresholds, 50 cravings resisted,
backfill-free month.
**Implementation notes:** deterministic ids `v5(code|scope_type|scope_id)` so re-evaluation and multiple
devices never duplicate; cheap predicates evaluated after relevant writes (debounced) and in a daily job;
unlocking triggers a celebration and an optional notification ([7.5]).
**Data model:** achievements use deterministic ids (arch §9.2).
**Tests:** unit tests per predicate; idempotency test.
**Notes:** The table came with the foundation. Catalog + pure predicates (`goals/domain/achievements.dart`), `AchievementService` (facts from snapshots; skips the 400-day scans once those badges exist; concurrent calls coalesce), deterministic ids via `Ids.achievement`. Runs after done/progress check-ins (badge cards in the celebration overlay) and at start-up. TODO(integration): optional [7.5] notification on unlock (no event API on main).

### T5.4.09 — Badge gallery & share cards
**Priority:** P2 · **Size:** S · **Depends on:** T5.4.08
**Description:** Gallery of earned and locked badges with progress hints; share a badge or quit milestone as
an image card containing only what the user chooses.
**Tests:** goldens for share cards.
**Notes:** Badge gallery (Goals screen app bar): earned badges with habit and date, locked ones with progress hints from `badgeValues`; the share sheet renders `BadgeShareCard` to a PNG (habit name off by default, date optional) and shares it with share_plus. Goldens (light/EN, dark/AR) in `badge_share_card_golden_test.dart` (tag golden, Ahem font). Sharing quit milestones as cards is not added.

### T5.4.10 — Personal-record moments
**Priority:** P2 · **Size:** S · **Depends on:** T5.4.08, [6.5]
**Description:** Surface personal records computed in [6.5]/[6.7] — longest streak, max value in a day, best
week, longest abstinence, most cravings resisted in a day — as "New record!" moments in the Habits tab and
detail screens.
**Tests:** widget tests.
**Notes:** `recordMoments` (best day/week via `everslot_metrics` `habitRecords`, current streak beating all earlier ones, longest abstinence, most cravings resisted in a day) shown as a New record! banner on the habit detail and quit dashboard and a pill on the Today row. Records are not persisted as announced (the stats `announcedRecords` setting belongs to [6.7]).
