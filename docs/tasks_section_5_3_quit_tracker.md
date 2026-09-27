# Section 5.3 — Quit Trackers

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 5.1, 5.2, 5.4, 1.3, 2.2, 6.6
> Architecture: §6.11 (quit trackers), §7.3 (habits quit columns, habit_logs, habit_revisions), §9.1 (instants
> vs local dates), §9.2 (UUIDv5)

## Goal

Let the user stop something — smoking, vaping, alcohol, sugar, social media… — and see, live, **how long
they have been clean** since the last relapse and since they first quit, **how many clean days** they have,
and what they have gained (money, units avoided, time). Relapses and cravings are logged with rich context
so [6.6] can deliver detailed quit analytics. Milestones, pledges and coping tools support the user, always
in a kind, non-judgmental tone.

## Scope

**In:** quit presets, tracker editor, quit calculator (`everslot_metrics`), live counter, dashboard, relapse
logging (slip vs new attempt), reduce-mode consumption logging, craving logging, daily-status rules
(auto-success), multiple trackers & quit strip, health-milestone content asset, milestone timeline, daily
pledge & evening review, trigger/place/coping libraries, savings rewards, coping toolbox.
**Out:** quit analytics and charts ([6.6]); quit notifications ([7.5]); widgets ([8.2]); the goals engine
([5.4]); build habits ([5.1], [5.2]).

## Progress

- [x] T5.3.01 — Quit presets
- [x] T5.3.02 — Quit tracker editor
- [x] T5.3.03 — Quit calculator (`everslot_metrics`)
- [x] T5.3.04 — Live counter & shared ticker
- [x] T5.3.05 — Quit dashboard
- [x] T5.3.06 — Relapse logging: slip vs new attempt
- [x] T5.3.07 — Reduce-mode consumption logging
- [x] T5.3.08 — Craving logging
- [x] T5.3.09 — Daily status rules (auto-success vs explicit)
- [x] T5.3.10 — Multiple trackers & quit strip
- [x] T5.3.11 — Health-milestone content asset (smoking)
- [x] T5.3.12 — Milestone timeline
- [x] T5.3.13 — Daily pledge & evening review
- [x] T5.3.14 — Trigger, place & coping libraries
- [x] T5.3.15 — Savings rewards
- [ ] T5.3.16 — Coping toolbox

## Tasks

### T5.3.01 — Quit presets
**Priority:** P0 · **Size:** S · **Depends on:** [5.1] (domain model)
**Description:** Preset catalog with sensible defaults: smoking (unit "cigarettes", baseline 10/day, time
per unit 5 min, health milestones and life-regained estimate available), vaping (puffs/sessions), alcohol
(drinks), caffeine (cups), sugar (servings), social media (minutes), gaming (hours), custom.
**Implementation notes:** bundled JSON with l10n keys; all defaults are editable and labelled as estimates;
health content and life-regained estimates exist **only** for smoking (research §E display rules); the preset
is stored per tracker; switching preset later changes labels/defaults only, never logged data.
**Data model:** the preset key is stored in `habits.quit_substance` (arch §7.3); it gates health content.
**Acceptance criteria:** presets prefill the editor in EN/FR/AR.
**Tests:** unit test validating the presets asset.
**Notes:** The preset catalog is Dart (`QuitPreset.all` in `domain/catalogs.dart`, labels via l10n keys) rather than a JSON asset; unit-tested, and the editor prefill is widget-tested in FR.

### T5.3.02 — Quit tracker editor
**Priority:** P0 · **Size:** M · **Depends on:** T5.3.01, [5.1] (repository), [2.2] (motivation photo)
**Description:** Create/edit a quit tracker: name, icon, color, preset, mode (*Quit completely* = abstain /
*Cut down* = reduce with a daily limit), quit start date **and time** (can be in the past: "I quit 3 days
ago"), baseline usage per day before quitting, cost (unit cost directly or pack price ÷ units per pack) and
currency, time spent per unit, motivation ("why I'm quitting", optional photo), auto-success toggle, section.
**Implementation notes:** changing baseline, unit cost or daily limit appends a `habit_revisions` row
(effective from today by default) so money saved is computed piecewise; `quit_started_at` is the **first**
quit date and is never overwritten by relapses (see T5.3.06); currency defaults from Settings › Regional ([8.3]).
**Acceptance criteria:** "Stop smoking, quit yesterday 21:00, 15/day, 10 € per 20-pack" shows correct live
values immediately; a price change next month doesn't alter money saved before the change.
**Tests:** widget tests; repository tests for revision creation.
**Notes:** Economics changes append revisions (effective today) through `HabitsRepository.update`; the motivation photo uses the attachments strip once the tracker exists.

### T5.3.03 — Quit calculator (`everslot_metrics`)
**Priority:** P0 · **Size:** L · **Depends on:** T5.3.02, [5.1] (period service)
**Description:** The single, pure implementation of quit arithmetic used by the dashboard, Today ([8.1]),
widgets ([8.2]), notifications ([7.5]) and the analytics in [6.6] (which must call these functions, not
re-implement them).
**Implementation notes:**
- **Attempts & abstinence intervals:** first quit = `quit_started_at`; a `restart` log starts a new attempt;
  each `relapse` ends the current abstinence interval (abstain mode). Outputs: attempts, abstinent intervals
  (start, end | open), lapses.
- **Current streak** = now − max(`quit_started_at`, last `restart`, last `relapse`) — live;
  **time since first quit** = now − `quit_started_at`; **longest streak** = longest interval;
  **total clean days** = local dates since first quit with no relapse (auto-success) or with an explicit
  `clean` log (explicit mode; other days are *unknown*).
- **Reduce mode:** day consumption = Σ `use` values per local date; a day succeeds if ≤ the daily limit in
  force (revision); streak = consecutive successful days.
- **Units avoided** = Σ per day (baseline in force − consumed, floored at 0), pro-rated by time for the partial
  first day; **money saved** = Σ units avoided × unit cost in force (piecewise over revisions);
  **money spent on lapses** = Σ relapse/use amounts × cost; **time won back** = units avoided ×
  `time_per_unit_minutes`; **life regained** (smoking only) = units avoided × `life_minutes_per_unit`
  (defaulted from the content asset: ~20 min per cigarette, Jackson et al. 2025; optional 11 min, BMJ 2000),
  always labelled as a population estimate.
- Durations use instants (DST-safe); day buckets use `local_date`.
**Data model:** `habit_logs.kind` values `restart` and `use` (arch §7.3).
**Acceptance criteria:** fixture suite (abstain & reduce, relapses, restarts, revisions, DST days, past quit
dates) matches expected values exactly; [6.6] tiles show identical numbers.
**Tests:** ≥ 60 fixture cases in `fixtures/quit/*.json`.
**Notes:** The arithmetic is `everslot_metrics` `QuitCalculator` (fixtures live with the package); `quitCalculatorOf` adapts habits/revisions/logs. App tests cover the live values, slips, restarts and both daily-status modes.

### T5.3.04 — Live counter & shared ticker
**Priority:** P0 · **Size:** S · **Depends on:** T5.3.03
**Description:** Reusable counter (d · h · m · s) driven by one 1 Hz ticker that runs only while a counter is
visible and the app is in the foreground; used on the dashboard, the quit strip and Today ([8.1]).
**Implementation notes:** localized formatting (FR/AR variants, Arabic-Indic digits where the locale uses
them); screen readers get minute-level updates via a polite live region; large text wraps units onto lines;
values are derived from instants on each tick (no DB writes).
**Acceptance criteria:** no drift after one hour in the background; no ticks while nothing is visible.
**Tests:** widget tests with a fake ticker; formatting unit tests.

### T5.3.05 — Quit dashboard
**Priority:** P0 · **Size:** M · **Depends on:** T5.3.03, T5.3.04
**Description:** Per-tracker screen: big live counter since the last relapse, smaller "since you first quit"
counter, tiles (money saved, units avoided, time won back, life regained for smoking), longest streak,
total clean days, next-milestone ring with ETA (P0: day milestones 1/3/7/14/30/60/90/180/365; health
timeline in T5.3.12), recent events (relapses, cravings, pledges), motivation card, and the primary buttons
**Log craving** and **Log relapse**.
**Implementation notes:** reduce mode shows today's consumption vs limit ("3 of 5"), a + button to log use and
the streak of days within the limit; *All stats* opens [6.6].
**Acceptance criteria:** every value equals the T5.3.03 output; layout works at text scale 2.0, RTL and dark mode.
**Tests:** widget tests; goldens.
**Notes:** Widget-tested (counter, money, population-estimate label, reduce mode); goldens not added.

### T5.3.06 — Relapse logging: slip vs new attempt
**Priority:** P0 · **Size:** M · **Depends on:** T5.3.03
**Description:** Record a relapse — amount, time (default now, can be set in the past), trigger, place, mood,
note — then ask kindly: *"Count it as a slip (keep my quit date; the streak restarts now)"* or *"Start a new
quit attempt from <time>"* (writes a `restart` log).
**Implementation notes:** supportive copy that highlights what was achieved ("You stayed smoke-free for
12 days — that still counts"); reset animation respects reduce motion; overflow action *Reset counter* =
relapse without amount + note "manual reset"; editing or deleting a relapse recomputes everything; the same
service is used by notification actions and widgets.
**Data model:** `habit_logs.kind = 'restart'`.
**Acceptance criteria:** a relapse logged 2 h in the past moves the streak start accordingly; deleting it
restores the previous streak.
**Tests:** service tests; widget tests for both choices.

### T5.3.07 — Reduce-mode consumption logging
**Priority:** P0 · **Size:** S · **Depends on:** T5.3.03
**Description:** For *Cut down* trackers: one-tap "+1" (and custom amount) consumption logs with time and
optional trigger/place/mood; the day total vs limit updates live; going over the limit marks the day as
"over limit" (wording is not "relapse").
**Data model:** `habit_logs.kind = 'use'`.
**Acceptance criteria:** day evaluation at day close follows T5.3.03; undo available.
**Tests:** service tests; widget tests.

### T5.3.08 — Craving logging
**Priority:** P0 · **Size:** M · **Depends on:** T5.3.02
**Description:** Quick *Log craving* (one tap = craving now at default intensity 5, editable afterwards) and a
detail sheet: intensity 1–10 slider, trigger, place, mood (1–5), coping strategy used, resisted (yes / no /
not sure), duration (from the craving timer T5.3.16 or manual), note.
**Implementation notes:** stored as `habit_logs` kind `craving` with `intensity`, `trigger`, `place`, `coping`,
`resisted`, `duration_seconds`, `mood`, `note`; reachable from the dashboard, Today ([8.1]), notification
actions ([7.2]) and widgets ([8.2]); until T5.3.14 lands, trigger/place/coping offer recent values as suggestions.
**Acceptance criteria:** a craving can be logged in ≤ 2 taps; the data covers every [6.6] craving metric
(load, context, resist rate, duration, coping effectiveness).
**Tests:** service and widget tests.

### T5.3.09 — Daily status rules (auto-success vs explicit)
**Priority:** P0 · **Size:** S · **Depends on:** T5.3.03
**Description:** How quit days count: with `auto_success = true`, a closed day without a relapse is clean
automatically; with `false`, a closed day needs an explicit "I stayed clean" (`clean` state log with id
`v5(habit|day|state)`), otherwise it stays **unknown** (hatched in calendars, counted by [6.6] data-quality
metrics, never treated as a relapse).
**Acceptance criteria:** switching the setting re-evaluates history without changing stored logs.
**Tests:** calculator fixtures for both modes.

### T5.3.10 — Multiple trackers & quit strip
**Priority:** P0 · **Size:** S · **Depends on:** T5.3.04
**Description:** A horizontal strip of live mini-counters at the top of the Habits tab ([5.2]) and an
"All clocks" screen (Nomo-style) with drag reorder; each tracker keeps its own currency.
**Acceptance criteria:** five trackers tick smoothly on one ticker; tapping a counter opens its dashboard.
**Tests:** widget tests.
**Notes:** The strip grows with text scale and counters scale down to one line (fixed an overflow at 1.0).

### T5.3.11 — Health-milestone content asset (smoking)
**Priority:** P1 · **Size:** M · **Depends on:** T5.3.01
**Description:** Localized, sourced content for smoking-cessation milestones (research §E), used by the
timeline (T5.3.12) and by the milestone metrics in [6.6].
**Implementation notes:**
- `assets/content/quit_milestones_smoking.json` with a JSON schema: rows for 20 min, 8 h, 12 h, 24 h, 48 h,
  72 h, 1 week, 2–12 weeks, 4–6 weeks, 1–9 months, 1 year, 1–2 years, 3–6 years, 5–10 years, 10 years,
  15 years, 20 years, plus life-expectancy notes; each row: offset, title and description in EN/FR/AR, a
  *range* text where sources differ, and source links (WHO, NHS, CDC, ACS, NCI, HSE).
- Withdrawal phase info (days 1–3 peak, week 1, weeks 2–4) and the life-regained constants with citations.
- Mandatory disclaimer (localized): *"Educational estimates based on population averages from
  WHO/NHS/CDC/ACS; individual results vary. Not medical advice. Consult a healthcare professional."*
- No health content for other presets (money and time only). Content reviewed by the owner before release.
**Acceptance criteria:** every row has ≥ 1 source URL and text in 3 languages; asset validation runs in CI.
**Tests:** schema validation test; l10n completeness test.
**Notes:** Asset `app/assets/content/quit_milestones_smoking.json` (path reconciled with the assignment; T6.6.05 still names `quit_milestones_cigarettes.json`) with the T6.6.05 rows — ids match the stats fallback table — plus withdrawal phases, life-regained constants and the localized disclaimer/clock note; loaded by `smokingMilestoneContentProvider`; `reviewedByOwner: false` until the owner reviews the texts.

### T5.3.12 — Milestone timeline
**Priority:** P1 · **Size:** M · **Depends on:** T5.3.11, T5.3.05, [5.4] (custom milestones via goals), [6.6] (milestone progress functions)
**Description:** Timeline of milestones: achieved ones as chips with the date reached, the next one as a
progress ring with ETA, and the upcoming list. Health rows show their source and range; the disclaimer is
always visible on this screen; custom milestones ("30 days → concert ticket") come from goals ([5.4]).
**Implementation notes:** follow the research §E display rules — the milestone clock restarts after a lapse
(say so), percentages show elapsed time only (not physiological measurement); progress/ETA computed by
[6.6] functions; reaching a milestone triggers a celebration ([5.2]) and a notification hook ([7.5]).
**Acceptance criteria:** display rules verified in review; RTL and text scale 2.0 layouts pass.
**Tests:** widget tests with fixture timelines; golden.
**Notes:** `QuitMilestonesScreen` (from the dashboard card and menu): clean-time milestones for every tracker, sourced health rows for smoking with range notes, the disclaimer at the top of the section, the clock-restart note and the current withdrawal phase; progress/ETA from `everslot_metrics` `milestoneProgress`. Custom milestones from goals come with [5.4]; reaching a milestone notifies through `QuitNotificationSource` (no in-app celebration card yet). Golden not added.

### T5.3.13 — Daily pledge & evening review
**Priority:** P1 · **Size:** M · **Depends on:** T5.3.09
**Description:** Optional ritual per tracker (I Am Sober style): a morning pledge ("Today I stay smoke-free")
and an evening review ("Did you stay clean today?" → *Yes* writes the `clean` state; *No* opens the relapse
flow). The pledge streak is shown on the dashboard; reminder times are set here and delivered by [7.5].
**Implementation notes:** one pledge log per day with deterministic id `v5(habit|day|pledge)`; per-tracker
settings (enabled, morning time, evening time).
**Data model:** `habit_logs.kind = 'pledge'`; pledge settings in `habits.settings`.
**Acceptance criteria:** pledging on two devices on the same day converges to one row.
**Tests:** service tests; widget tests.
**Notes:** Ritual card on the dashboard (pledge + streak, evening review from the evening time; explicit-mode trackers are asked at any time and about an unconfirmed yesterday) and per-tracker settings in the quit editor. Reminder delivery at the ritual times is not auto-created: the editor points to the tracker Reminders section ([7.5] rules).

### T5.3.14 — Trigger, place & coping libraries
**Priority:** P1 · **Size:** M · **Depends on:** T5.3.08
**Description:** Reusable vocabularies for craving and relapse logs — triggers (stress, coffee, alcohol, after
meals, social situations, boredom, driving, work break, phone, waking up…), places (home, work, car, bar…),
coping strategies (breathing, walk, water, gum, call a friend, delay 10 min…), distractions — each with icon
and color; users can add, rename, archive and reorder entries.
**Implementation notes:** defaults seeded with deterministic ids and localized names; logs store the entry
id (free text still allowed for ad-hoc values); renaming an entry updates every historical display.
**Data model:** new synced table `app.habit_vocab (kind trigger | place | coping | distraction, name,
icon, color, sort_key, archived_at)`.
**Acceptance criteria:** libraries sync across devices; pickers show most-used entries first.
**Tests:** repository tests; widget tests for picker and manage screen.
**Notes:** Manage screen (dashboard menu) per kind with usage counts, add, rename, icon, color, archive/restore and drag-to-reorder through `HabitVocabService`; defaults are seeded at startup (see T5.1.11). The picker already sorted most-used first.

### T5.3.15 — Savings rewards
**Priority:** P1 · **Size:** S · **Depends on:** T5.3.03, [5.4] (goals)
**Description:** "What my savings buy": a list of rewards per tracker (title, price, optional image)
implemented as goals with metric `money_saved`; progress rings and ETA at the current saving rate;
*Reward claimed* marks the goal achieved (the money stays counted as saved).
**Data model:** `attachments.owner_type` should allow `goal` (reward image); optional reward text on
`goals` (or reuse `title`).
**Acceptance criteria:** ETA updates live as savings grow; claimed rewards appear in the events timeline.
**Tests:** ETA unit tests; widget tests.
**Notes:** Rewards are money-saved goals with `reward` set (`QuitRewardsSection` on the dashboard, editor in reward mode); ETA from the goal engine refreshes each minute; claimed rewards appear in the dashboard events. The reward image (attachments with owner `goal`) is not wired yet.

### T5.3.16 — Coping toolbox
**Priority:** P2 · **Size:** M · **Depends on:** T5.3.08
**Description:** Tools to ride out a craving: a 3-minute craving timer (cravings typically pass within
3–5 minutes — HSE) that fills `duration_seconds` and asks "Did you resist?"; breathing exercises (box 4-4-4-4,
4-7-8) with a reduce-motion alternative (text + haptic pacing); a personal distraction list; a motivation card
(reasons + photo). Reachable from the dashboard and from craving notifications.
**Acceptance criteria:** finishing the timer logs a craving with duration and resisted flag in one confirmation.
**Tests:** widget tests; timer state unit tests.
