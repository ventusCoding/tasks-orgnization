# Section 6.6 — Quit Tracker Insights

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 5.3, 5.4, 6.1, 6.2
> Architecture: §6.11 (habit & quit engine), §6.12 (stats engine), §7.3 (`habits` quit fields, `habit_revisions`, `habit_logs`)

## Goal

Motivating, honest and deeply detailed statistics for every quit tracker, for example "stop smoking".
They cover:

- live abstinence time and abstinent days
- units avoided, money saved and money spent, and "life regained" (clearly labelled as a population
  estimate)
- health-recovery milestones (smoking only, with sources and a mandatory disclaimer)
- lapse vs relapse classification, use patterns
- craving load, context, resistance and coping
- pledges, withdrawal phase information, and survival across quit attempts

Relapse screens use supportive wording: a lapse resets the clock but never erases the progress made.

## Scope

**In:** quit stats adapter, metrics QT-01…QT-28, health-milestone content and display rules, Quit
Insights screen, fixtures.
**Out:** Quit data capture (relapse/craving/pledge logging, live counter widget) ([5.3]); goals model
([5.4]); survival and correlation math ([6.1]); charts ([6.2]); quit notifications ([7.5]).

## Notation (used in all formulas below)

- **Attempt:** the first attempt starts at `quit_started_at` (qd); every `habit_logs.kind = 'restart'` row
  starts a new attempt at its `logged_at` (arch §7.3; written by [5.3] T5.3.06). **Current abstinence
  start** = max(qd, last `restart`, time of the last use).
- **Use events U:** amount a_j (null → 1) at time t_j.
  - Abstain mode: `habit_logs.kind = 'relapse'` — a use is a lapse.
  - Reduce mode: `habit_logs.kind = 'use'` — ordinary consumption, logged via "Log use".
  - A local day is **abstinent** if it has no use.
- **Per revision** ([5.1] `habit_revisions`, piecewise by `effective_from`):
  - **base** = `baseline_per_day`
  - **cpu** = `unit_cost` (currency = `habits.currency`)
  - **limit** = `daily_limit` (reduce mode)
- **LMU** = life-expectancy minutes per unit avoided. The default is 20 for cigarettes (Jackson et al.
  2025); presets are 17 (men), 22 (women) and 11 (BMJ 2000).
- **TPU** = minutes spent consuming one unit (e.g. 6 for a cigarette).
- **Cravings C:** `kind = 'craving'`, with `intensity` 1–10, `trigger`, `place`, `mood`, `resisted`,
  `coping` and `duration_seconds`. **Pledges:** `kind = 'clean'`.
- Durations use instants. Day counts use local dates with `dayStartsAt`.

## Progress

- [x] T6.6.01 — Quit stats adapter
- [x] T6.6.02 — Abstinence time metrics
- [x] T6.6.03 — Units & money metrics
- [x] T6.6.04 — Life regained (population estimate)
- [x] T6.6.05 — Health milestones: content, progress & disclaimer
- [x] T6.6.06 — Reduce-mode metrics
- [x] T6.6.07 — Craving load & context
- [ ] T6.6.08 — Craving resistance & decline
- [ ] T6.6.09 — Lapse/relapse classification, use analytics & attempts
- [ ] T6.6.10 — Savings goal, time not spent & money by period
- [ ] T6.6.11 — Pledge streak & withdrawal phase
- [ ] T6.6.12 — Advanced quit analytics
- [x] T6.6.13 — Quit Insights screen
- [x] T6.6.14 — Quit stats fixtures

## Tasks

### T6.6.01 — Quit stats adapter
**Priority:** P0 · **Size:** M · **Depends on:** [5.3] (quit logic), [6.1] (T6.1.12 loaders, T6.1.13 isolate)
**Description:** Build quit facts: attempts, use events, a per-day consumption series (with the
revision in force each day), cravings and pledges.
**Implementation notes:**
- `QuitDayFact`: `{localDate, used, base, cpu, limit, abstinent}`.
- `AttemptFact`: `{start, end?, endedBy: reset | ongoing, uses}`.
- Live metrics are computed from instants on each tick, without reloading data. The ticker lives in the UI.
**Data model (resolved in arch §7.3):** `habits.quit_substance` gates health content (milestones only for
`cigarettes`); `habits.life_minutes_per_unit` (LMU) and `habits.time_per_unit_minutes` (TPU) replace the
former single constant; attempt history comes from `habit_logs.kind = 'restart'` rows. All arithmetic lives
in the [5.3] T5.3.03 quit calculator — this task adapts its outputs into facts, it never re-implements them.
**Acceptance criteria:** the `quit_smoking_90_days` fixture produces the expected attempt and day facts,
including the price change.
**Tests:** fixture tests covering a revision change, two attempts and reduce mode.
**Notes:** `domain/habit_resolution.dart` builds the [5.3] `QuitCalculator` of a tracker (revisions in force per day, `restart` logs as attempts); the catalog only adapts its outputs. Table fixtures: `quit_smoking_90_days` (price revision), `quit_attempts` (three attempts across the March DST change), `quit_reduce_week`.

### T6.6.02 — Abstinence time metrics
**Priority:** P0 · **Size:** M · **Depends on:** T6.6.01, [6.2] (live counter T6.2.07, KPI T6.2.02)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| QT-01 | Time since quit | now − qd, live (d h m s) | habits | live counter | P0 |
| QT-02 | Current abstinence | now − max(qd, last use), live | logs | live counter | P0 |
| QT-03 | Longest abstinence | max gap among [qd → first use], [use_j → use_{j+1}], [last use → now] | logs | tile | P0 |
| QT-04 | Abstinent days | number of local days since qd without use | day facts | tile | P0 |
| QT-05 | % abstinent days | QT-04 ÷ local days since qd | day facts | ring | P0 |

**Acceptance criteria:** use `quit_smoking_90_days` as seen on 2026-07-31 00:00 (Europe/Paris): qd is
2026-06-01 00:00, with one lapse of 3 cigarettes on 2026-06-20 at 18:00. Expected:
- QT-01 = 60 d 0 h; QT-02 = 40 d 6 h; QT-03 = 40 d 6 h.
- QT-04 = 59; QT-05 = 98.3 %.
**Tests:** fixture tests; DST-crossing test (a counter across the October change stays exact).
**Notes:** QT-01…05 from instants (live counters) and local days; the attempts fixture checks an exact 1 799 h across the DST change.

### T6.6.03 — Units & money metrics
**Priority:** P0 · **Size:** M · **Depends on:** T6.6.01

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| QT-06 | Units avoided | abstain: Σ over days (base_d) − Σ a_j, floored at 0 (fractional current day allowed); reduce: Σ_d max(0, base_d − used_d) | day facts | counter + line | P0 |
| QT-07 | Money saved | Σ_d avoided_d × cpu_d (piecewise over revisions) | day facts | area line | P0 |
| QT-08 | Money spent on lapses | Σ a_j × cpu at t_j | logs, revisions | tile | P0 |
| QT-09 | Savings projections | at the current base × cpu: +1 month, +1 year, +5 years if abstinence continues | revisions | tiles | P0 |

**Acceptance criteria:** base is 20/day; cpu is €0.60 until 2026-06-30 and €0.65 from 2026-07-01.
Using the T6.6.02 fixture:
- Units avoided = 20 × 60 − 3 = 1 197.
- Money saved = (600 − 3) × 0.60 + 600 × 0.65 = €748.20.
- Money spent on lapses = €1.80.
- Projections use €0.65: 1 year ≈ €4 745.
**Tests:** fixture tests; currency formatting per locale.
**Notes:** QT-06…09 (`quit_smoking_90_days`: 1 197 units, €748.20, €1.80, €4 745/year).

### T6.6.04 — Life regained (population estimate)
**Priority:** P0 · **Size:** S · **Depends on:** T6.6.03

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| QT-10 | Life regained | units avoided × LMU, shown as d h; label "population estimate"; the explain sheet cites Jackson et al. 2025 (≈ 20 min per cigarette; men 17, women 22) and BMJ 2000 (≈ 11 min). It also notes that harm is non-linear and varies between individuals | QT-06, settings | counter | P0 |

**Implementation notes:** shown only for `quit_substance = cigarettes` unless the user explicitly sets an
LMU. Changing the preset recomputes all history.
**Acceptance criteria:** 1 197 avoided × 20 min = 23 940 min = 16 d 15 h; the label is always visible
next to the number.
**Tests:** fixture test; a widget test that the label is present.
**Notes:** QT-10 with the "population estimate" note always shown next to the number (KPI caption); hidden for other substances without an LMU (`noLifeEstimate`).

### T6.6.05 — Health milestones: content, progress & disclaimer
**Priority:** P0 · **Size:** M · **Depends on:** T6.6.02, [6.2] (milestone bars T6.2.07)
**Description:** A timeline of health-recovery milestones for smoking, with progress bars driven by the
**current abstinence** (the clock restarts after a lapse).
**Implementation notes:**
- **Content file:** `assets/content/quit_milestones_cigarettes.json` holds milestone objects
  `{id, tMin, tMax, textKey, sources[]}`, localized in EN, FR and AR and reviewed before release.
- **Progress:**
  - Single-point milestones: progress_k = min(1, current abstinence ÷ t_k).
  - Range milestones: the bar runs to tMax, with a marker at tMin, and a state of "in window" between
    the two.
  - ETA for the next milestone = current abstinence start + t_k.
- **Scope:** shipped only for `quit_substance = cigarettes`. Other substances show money and time only.
- **Display rules:**
  - every row shows its source and range;
  - a note says the milestone clock restarts after a lapse;
  - percentages show elapsed time only and are not physiological measurements;
  - the section header always shows this disclaimer: *"Educational estimates based on population
    averages from WHO, NHS, CDC and the American Cancer Society; individual results vary. Not
    medical advice. Consult a healthcare professional."*

| Time since last cigarette | Milestone | Sources |
|---|---|---|
| 20 min | Heart rate and blood pressure drop; pulse returning to normal | [WHO][who], [NHS][nhs] |
| 8 h | Carbon monoxide in the blood halved; oxygen levels recovering | [NHS][nhs] |
| 12 h | Blood carbon monoxide back to normal | [WHO][who] |
| 24 h – a few days | Nicotine in the blood falls to zero; CO normalises | [CDC][cdc], [ACS][acs] |
| 48 h | CO at non-smoker level; lungs clearing mucus; taste and smell improving | [NHS][nhs] |
| 72 h | Breathing easier as bronchial tubes relax; energy rising | [NHS][nhs] |
| 2 – 12 weeks | Circulation and lung function improve | [WHO][who], [NHS][nhs] |
| 4 – 6 weeks | Cravings usually ease (a single craving lasts about 3–5 min) | [HSE][hse] |
| 1 – 12 months (WHO 1–9, NHS 3–9, CDC/ACS 1–12) | Coughing and shortness of breath decrease; lung function up to ~10 % better | [WHO][who], [NHS][nhs], [CDC][cdc], [ACS][acs] |
| 1 year | Coronary heart disease risk about half that of a smoker | [WHO][who], [NHS][nhs] |
| 1 – 2 years | Heart-attack risk drops sharply | [CDC][cdc], [ACS][acs] |
| 3 – 6 years | Added coronary heart disease risk halves | [CDC][cdc] |
| 5 – 10 years | Added risk of mouth, throat and larynx cancer halves; stroke risk falls (WHO: non-smoker level after 5–15 years) | [CDC][cdc], [ACS][acs], [WHO][who] |
| 10 years (CDC: 10–15) | Lung-cancer risk about half that of a smoker; risks of bladder, oesophagus and other cancers fall | [WHO][who], [ACS][acs], [NHS][nhs], [CDC][cdc] |
| 15 years | Coronary heart disease risk that of (or close to) a non-smoker | [WHO][who], [CDC][cdc], [ACS][acs] |
| 20 years | Mouth, throat, larynx and pancreas cancer risk near a never-smoker's; cervical-cancer risk halves | [CDC][cdc], [ACS][acs] |
| Info row (no bar) | Quitting at 30 / 40 / 50 / 60 gains about 10 / 9 / 6 / 3 years of life expectancy ("up to 10 years", CDC/ACS) | [WHO][who], [CDC][cdc], [ACS][acs] |

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| QT-11 | Health milestones | per milestone: progress, state (done / in window / upcoming), ETA; next milestone highlighted | QT-02, content | milestone bars | P0 |

**Acceptance criteria:**
- After a lapse, every milestone restarts from the lapse time and the explanation says so.
- The disclaimer and sources are visible without scrolling inside the section.
- Non-smoking trackers never show this section.
**Tests:** widget tests (smoking vs other); golden in EN/FR/AR; content JSON schema test (every row has
at least one source).
**Notes:** QT-11 from the stats table in `domain/quit_health_content.dart`, checked row by row (ids, times, sources) against the habits feature's `assets/content/quit_milestones_smoking.json`; the disclaimer heads the card, the clock note follows; non-smoking trackers never show the card (`notSmoking` hides it). Tests: `quit/quit_health_content_test.dart`, `presentation/quit_screens_test.dart`, goldens.

### T6.6.06 — Reduce-mode metrics
**Priority:** P0 · **Size:** S · **Depends on:** T6.6.01, [6.2] (bars with limit line T6.2.04)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| QT-12 | Reduction progress | days within limit (used_d ≤ limit_d) ÷ days; mean daily use vs base and limit; % reduction = 1 − mean use ÷ base; 7-day rolling trend | day facts | bars + limit line + trend | P0 |

**Acceptance criteria:** base 20, limit 10, 7 days of use {12, 9, 10, 8, 11, 7, 6}. Expected:
- within-limit days = 5/7
- mean use = 9.0
- reduction = 55 %
- units avoided = 77
**Tests:** fixture tests.
**Notes:** QT-12 (`quit_reduce_week`: 5/7, mean 9.0, 55 %, 77 avoided); hidden on abstain trackers.

### T6.6.07 — Craving load & context
**Priority:** P0 · **Size:** M · **Depends on:** T6.6.01, [6.2] (Pareto T6.2.05, punch card T6.2.09, line T6.2.03)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| QT-13 | Craving load | cravings per day (mean over P); mean and max intensity; 7-day rolling trend | cravings | line + bars | P0 |
| QT-14 | Craving context | Pareto by trigger, place and mood; weekday × hour matrix | cravings | Pareto + punch card | P0 |

**Acceptance criteria:** triggers are grouped case-insensitively; "Unspecified" is shown last; the punch
card follows the user's week start.
**Tests:** fixture tests.
**Notes:** QT-13/14; craving load averages closed days (today excluded unless the period is only today): 40/60 per day, mean intensity 5.9, trigger Pareto 13/8/7/6 with Unspecified last.

### T6.6.08 — Craving resistance & decline
**Priority:** P1 · **Size:** M · **Depends on:** T6.6.07

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| QT-15 | Resist rate | cravings not followed by a use within 2 h ÷ cravings; an explicit `resisted` value overrides the inference | cravings, uses | KPI + trend | P1 |
| QT-16 | Craving duration | median and P85 of `duration_seconds`; context note: a craving typically lasts 3–5 min (HSE) | cravings | histogram | P1 |
| QT-17 | Cravings decline since quit | cravings/day per week since qd; % change vs week 1 | cravings | line | P1 |

**Acceptance criteria:** 10 cravings, 2 of them followed by a use within 2 h, give a resist rate of 80 %.
**Tests:** fixture tests.

### T6.6.09 — Lapse/relapse classification, use analytics & attempts
**Priority:** P1 · **Size:** M · **Depends on:** T6.6.02

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| QT-18 | Lapse vs relapse | lapse = any use. Relapse (SRNT) = use on 7 consecutive days, or use on ≥ 1 day in each of 2 consecutive 7-day blocks counted from qd. Russell Standard sustained abstinence = ≤ 5 units in total after a 2-week grace period | uses | timeline with labels | P1 |
| QT-19 | Use analytics | episodes; amount per episode; days between lapses; weekday × hour; % reduction vs base; triggers logged ≤ 2 h before a use | uses, cravings | punch card + tiles | P1 |
| QT-20 | Quit attempts | number of attempts; mean and longest attempt duration; current attempt rank | attempts | bars | P1 |

**Implementation notes:** wording stays supportive: "A slip is part of many quit journeys — you've still
been smoke-free 58 of 60 days." Never shame.
**Acceptance criteria:** uses on days 10–16 of an attempt count as a relapse; a single use on day 10
counts as a lapse; uses on days 10 and 18 (blocks 2 and 3) count as a relapse.
**Tests:** fixture tests for the classification rules.

### T6.6.10 — Savings goal, time not spent & money by period
**Priority:** P1 · **Size:** S · **Depends on:** T6.6.03, [5.4] (goals)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| QT-21 | Savings goal | saved ÷ goal price (`goals`, metric `money_saved`); ETA = remaining ÷ current daily saving | goals, QT-07 | progress ring | P1 |
| QT-22 | Time not spent consuming | units avoided × TPU | QT-06 | counter | P1 |
| QT-23 | Money saved per period | bars by week / month; mean saved per day | day facts | bars | P1 |

**Acceptance criteria:** with €748.20 saved against a €1 200 goal at €13/day, the ETA is in 35 days.
**Tests:** fixture tests.

### T6.6.11 — Pledge streak & withdrawal phase
**Priority:** P1 · **Size:** S · **Depends on:** T6.6.01, [6.1] (streaks T6.1.09)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| QT-24 | Pledge streak | consecutive local days with a pledge/review (`clean` log) | pledges | chip | P1 |
| QT-25 | Withdrawal phase | informational phase bar for the current abstinence: days 1–3 (peak), week 1 (worst), weeks 2–4 (easing) — per the NCI withdrawal fact sheet; smoking only | QT-02 | phase bar | P1 |

**Acceptance criteria:** the phase bar is labelled "typical, individual experience varies" and links to
the source.
**Tests:** widget tests.

### T6.6.12 — Advanced quit analytics
**Priority:** P2 · **Size:** M · **Depends on:** T6.6.09, [6.1] (T6.1.25 Kaplan–Meier), [6.2] (KM curve T6.2.25)

| Metric ID | Name | Definition / formula | Data | Chart | Pri |
|---|---|---|---|---|---|
| QT-26 | Time-to-lapse survival | Kaplan–Meier across attempts (event = first lapse in an attempt; current attempt censored); median abstinence ("not reached" allowed) | attempts | KM curve | P2 |
| QT-27 | Coping effectiveness | resist rate by `coping` tool (n ≥ 5 per tool) | cravings, uses | bars | P2 |
| QT-28 | Craving-free time | time since last craving; longest craving-free stretch | cravings | tiles | P2 |

**Acceptance criteria:** KM hidden with fewer than 2 attempts; coping tools with n < 5 greyed out.
**Tests:** fixture tests.

### T6.6.13 — Quit Insights screen
**Priority:** P0 · **Size:** M · **Depends on:** T6.6.02, T6.6.03, T6.6.04, T6.6.05, T6.6.06, T6.6.07, [6.1] (T6.1.16)
**Description:** Scope screen `/insights/quit/:id`, which is also embedded in the [5.3] quit dashboard.
- **P0 layout:**
  - Header: live current abstinence, money saved, units avoided, life regained (with label).
  - Sections: Milestones (smoking), Money & units, Abstinence (QT-03 to QT-05), Reduction (reduce mode
    only), Cravings (QT-13, QT-14).
- **P1 adds:**
  - Craving resistance and decline.
  - Lapse/relapse timeline and use analytics.
  - Attempts.
  - Savings goal.
  - Time not spent.
  - Pledges.
  - Withdrawal phase.
- **P2 adds:** Survival, Coping effectiveness, Craving-free time.
**Acceptance criteria:**
- The counters tick every second only while visible.
- The screen never shows health content for non-smoking trackers.
- Relapse sections use supportive copy, which is reviewed in the three languages.
**Tests:** widget tests (abstain vs reduce, smoking vs other); goldens.
**Notes:** `quitLayout` (header: live current abstinence, money saved, units avoided, life regained with its label; Milestones, Money & units, Abstinence, Reduction, Cravings); live counters tick only while visible (`LiveCounter` + `CounterTicker`). The Insights Quit segment picks a tracker. Widget tests (abstain vs reduce, smoking vs other) and goldens. TODO(integration): the [5.3] quit dashboard embeds the screen through `/insights/quit/:id` (already linked).

### T6.6.14 — Quit stats fixtures
**Priority:** P0 · **Size:** S · **Depends on:** [6.1] (T6.1.15)
**Description:** Fixtures:
- `quit_smoking_90_days`: the T6.6.02/03 numbers plus 40 cravings with triggers and places.
- `quit_reduce_week`: the T6.6.06 numbers.
- `quit_attempts`: 3 attempts, one relapse and one lapse.
**Acceptance criteria:** the fixture runner passes for all P0 metrics.
**Tests:** provides fixtures for the tasks above.
**Notes:** Table fixtures `quit_smoking_90_days`, `quit_reduce_week`, `quit_attempts` cover every P0 quit metric.

## Sources

- WHO — health benefits of smoking cessation: <https://www.who.int/news-room/questions-and-answers/item/tobacco-health-benefits-of-smoking-cessation>
- NHS — Better Health, quit smoking: <https://www.nhs.uk/better-health/quit-smoking/>
- CDC — benefits of quitting: <https://www.cdc.gov/tobacco/about/benefits-of-quitting.html>
- American Cancer Society — benefits of quitting over time: <https://www.cancer.org/cancer/risk-prevention/tobacco/guide-quitting-smoking/benefits-of-quitting-smoking-over-time.html>
- NCI — tobacco withdrawal fact sheet: <https://www.cancer.gov/about-cancer/causes-prevention/risk/tobacco/withdrawal-fact-sheet>
- HSE — cravings and withdrawal: <https://www2.hse.ie/living-well/quit-smoking/get-help-to-quit/cravings-withdrawal/>
- Shaw, Mitchell & Dorling, BMJ 2000 (≈ 11 min per cigarette): <https://pubmed.ncbi.nlm.nih.gov/10617536/>
- Jackson et al., Addiction 2025 (≈ 20 min per cigarette): <https://doi.org/10.1111/add.16757>
- SRNT measures of abstinence (Hughes et al. 2003): <https://pubmed.ncbi.nlm.nih.gov/12745503/>
- Russell Standard (West et al. 2005): <https://pubmed.ncbi.nlm.nih.gov/15733243/>

[who]: https://www.who.int/news-room/questions-and-answers/item/tobacco-health-benefits-of-smoking-cessation
[nhs]: https://www.nhs.uk/better-health/quit-smoking/
[cdc]: https://www.cdc.gov/tobacco/about/benefits-of-quitting.html
[acs]: https://www.cancer.org/cancer/risk-prevention/tobacco/guide-quitting-smoking/benefits-of-quitting-smoking-over-time.html
[nci]: https://www.cancer.gov/about-cancer/causes-prevention/risk/tobacco/withdrawal-fact-sheet
[hse]: https://www2.hse.ie/living-well/quit-smoking/get-help-to-quit/cravings-withdrawal/
