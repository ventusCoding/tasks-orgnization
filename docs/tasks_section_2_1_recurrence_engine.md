# Section 2.1 — Recurrence Engine (`everslot_recurrence`)

> Milestones: M0 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.1 (package skeleton), 1.3 (pickers, l10n)
> Architecture: arch §6.8 (engine), §8.1 (rule JSON), §9.1 (time rules), §13 ADR-004

## Goal

One pure-Dart engine that turns a **fully free recurrence configuration** into concrete occurrences —
every N minutes/hours/days/weeks/months/years, specific weekdays ("each Monday and Tuesday"), every 2
days, Nth weekday of the month, last day of the month, several times per day, windows ("every 90 min
between 08:00 and 20:00"), quotas ("3 times per week, any day"), "N days after I complete it", end by
date/count/never, exceptions and per-occurrence overrides — correctly across time zones and DST, fast
enough for 1-minute rules, and explainable in plain language (EN/FR/AR). It is used by Planner tasks,
habit schedules, resettable checklists and notification schedules.

## Scope

**In:** package types, rule model + JSON v1, validation, RFC 5545-compatible expansion for all
frequencies, windows, times-per-day, quota periods, after-completion, until/count/exdates/rdates,
occurrence keys, zone/DST resolution, override merging helper, series-split helper, localized
descriptions, RRULE import/export, fixture suite, benchmarks, the rule builder UI.
**Out:** Storage of rules/overrides (Planner [3.1]/[3.2], Habits [5.1]); notification planning ([7.2]);
torture/property test campaign ([9.1] T9.1.04); Hijri calendars ([9.3]).

**Why our own engine (ADR-004):** the Dart `rrule` package has no `WKST` support (Monday-only weeks) and
does not document minutely/hourly expansion; RRULE itself cannot express windows restarting daily,
quotas or after-completion rules. We keep RFC 5545 semantics where they exist and extend beyond.

## Progress

- [x] T2.1.01 — Package core types (local date/time, weekday, zone resolver)
- [x] T2.1.02 — Rule model, JSON v1 codec & validation
- [x] T2.1.03 — Expansion: yearly/monthly/weekly/daily with BYxxx rules (RFC 5545)
- [x] T2.1.04 — Expansion: hourly/minutely, windows & times-per-day
- [x] T2.1.05 — Bounds & sets: until, count, exdates, rdates, month-day overflow
- [x] T2.1.06 — Query API: between / nextAfter / previousBefore / occurrence keys
- [x] T2.1.07 — Time zones & DST resolution (fixed vs floating)
- [x] T2.1.08 — Quota rules (N per period) & period API
- [x] T2.1.09 — After-completion rules
- [x] T2.1.10 — Override merging helper (moved / cancelled / edited occurrences)
- [x] T2.1.11 — Series split helper ("this and following")
- [x] T2.1.12 — Human-readable descriptions (EN / FR / AR)
- [x] T2.1.13 — Fixture suite & runner
- [x] T2.1.14 — App integration: `RecurrenceService` & providers
- [x] T2.1.15 — Recurrence builder UI: presets
- [x] T2.1.16 — Recurrence builder UI: advanced editor, preview & warnings
- [x] T2.1.17 — RRULE import / export (RFC 5545 text)
- [x] T2.1.18 — Performance benchmarks & safety caps
- [x] T2.1.19 — Exceptions manager UI (skipped/moved occurrences of a series)
- [x] T2.1.20 — Non-Gregorian calendar extension point (design only)

## Tasks

### T2.1.01 — Package core types (local date/time, weekday, zone resolver)
**Priority:** P0 · **Size:** M · **Depends on:** [1.1] (package skeleton)
**Description:** Immutable value types the whole app will share for wall-clock time: `LocalDate`,
`LocalTime` (minute precision, 00:00–23:59, plus `24:00` only as a window end), `LocalDateTime`,
`Weekday` (ISO 1 = Monday … 7 = Sunday), `ZoneId`, and a `ZoneResolver` that converts wall clock ↔ UTC
instants using the IANA database from the pure-Dart `timezone` package.
**Implementation notes:**
- Arithmetic in *calendar* terms: `plusDays`, `plusMonths` (with overflow policy), `plusMinutes` on
  `LocalDateTime` (no DST involvement — DST is only applied at resolution time, T2.1.07).
- ISO strings: `YYYY-MM-DD`, `HH:mm`, `YYYY-MM-DDTHH:mm`; strict parsers with helpful errors.
- `weekOfYear(date, weekStart)`, `startOfWeek(date, weekStart)` supporting any week start (MO/SA/SU/…).
- No dependency on Flutter; `timezone` initialized by the caller (`latest_all` database).
**Acceptance criteria:** types are `==`/`hashCode`-correct, comparable and round-trip through ISO strings;
week helpers correct for every week start across year boundaries.
**Tests:** unit tests incl. leap years (2024-02-29, 2100 not leap), year-boundary ISO weeks, parse errors.

### T2.1.02 — Rule model, JSON v1 codec & validation
**Priority:** P0 · **Size:** M · **Depends on:** T2.1.01
**Description:** Implement the rule schema of arch §8.1 as immutable classes (`RecurrenceRule` with
`type: fixed | afterCompletion | quota`), a JSON codec with `"v": 1`, unknown-field preservation, and a
validator returning typed issues.
**Implementation notes:**
- Fields: `freq`, `interval ≥ 1`, `byWeekday [{day, n?}]`, `byMonthDay (±1..31)`, `byMonth`, `byYearDay
  (±1..366)`, `byWeekNo (±1..53)`, `bySetPos`, `byHour`, `byMinute`, `times [HH:mm]`, `window {start, end,
  anchor: window_start | series_start}`, `wkst`, `until` (local, inclusive), `count`, `countMode
  (occurrences | completions)`, `exdates`, `rdates`,
  `afterCompletion {amount, unit}`, `quota {times, per, minGapDays}`, plus optional
  `monthDayOverflow: skip | clamp` (default `skip`, RFC behaviour; `clamp` → shorter months use their last day).
- Validation issues (code + params, localized by UI): `intervalInvalid`, `untilBeforeStart`,
  `countAndUntil`, `emptyWeekdaySet`, `ordinalOnWeekly`, `windowEndBeforeStart`, `tooFrequent`
  (> 1 440 occurrences/day), `quotaImpossible` (e.g. 8 times per week with minGap 1), `unsupportedCombo`.
- Decoder upgrades unknown older versions (none yet) through a migration table.
**Acceptance criteria:** every example in arch §8.1 round-trips byte-identically; invalid rules yield the
exact issue codes; JSON with extra keys keeps them on re-encode.
**Tests:** codec round-trip fixtures; validator table tests.

### T2.1.03 — Expansion: yearly/monthly/weekly/daily with BYxxx rules (RFC 5545)
**Priority:** P0 · **Size:** L · **Depends on:** T2.1.02
**Description:** Core iterator for calendar frequencies implementing RFC 5545 §3.3.10 "expand vs limit"
semantics for `BYMONTH`, `BYWEEKNO`, `BYYEARDAY`, `BYMONTHDAY`, `BYDAY` (incl. ordinals like `2TU`,
`-1FR`), `BYHOUR`, `BYMINUTE`, `BYSETPOS`, with `WKST` honoured for weekly intervals and week numbers.
**Implementation notes:**
- Iterate **periods** (year/month/week/day) from the anchor stepping by `interval`; inside each period
  build the candidate set per the RFC table, then apply `BYSETPOS` on the sorted set of the period.
- Invalid dates (e.g. Feb 30) are skipped (or clamped when `monthDayOverflow = clamp`).
- The anchor is **not** force-included: occurrences are exactly the rule's matches (the builder UI keeps
  the anchor synchronized with the rule; document this difference from RFC DTSTART behaviour).
- Lazy generation (`Iterable` / sync* generators) — never materialize unbounded sets.
**Acceptance criteria:** matches the RFC 5545 examples section (all applicable examples encoded as
fixtures, e.g. "every other week on MO, WE, FR until…", "last weekday of month", "every 3rd year on the
1st, 100th, 200th day"), plus: every Monday & Tuesday; every 2 days; monthly on day 31 (skip & clamp);
yearly on Feb 29 (skip in non-leap years).
**Tests:** fixture-driven (T2.1.13) with ≥ 60 cases for this task.

### T2.1.04 — Expansion: hourly/minutely, windows & times-per-day
**Priority:** P0 · **Size:** M · **Depends on:** T2.1.03
**Description:** Sub-daily recurrences: `freq = hourly | minutely` with `interval` (e.g. every 45 min,
every 3 h), optional daily **window** (`08:00–20:00`), day filters (`byWeekday` etc.), and `times`
(several fixed times on each matching day).
**Implementation notes:**
- `window.anchor = window_start` (default): each matching day restarts at the window start
  (08:00, 09:30, … every 90 min until ≤ window end). `series_start`: continuous chain from the anchor,
  filtered by the window (RRULE-compatible behaviour).
- Window end is inclusive when it lands exactly on a step; windows may not cross midnight in v1
  (validation) — users create two windows via two rules instead.
- `times` on daily/weekly/monthly rules: cross product of matching dates × times (sorted, deduplicated).
- Generation is per visible range; minutely rules are always bounded by the caller's range.
**Acceptance criteria:** "every 90 min 08:00–20:00 weekdays" produces 9 occurrences per weekday
(08:00 … 20:00) and none on weekends; "every 70 min, window_start" restarts at 08:00 each day while
`series_start` drifts; "8:00 and 20:00 daily" yields two per day.
**Tests:** fixtures (≥ 30 cases) incl. 1-minute rules over 24 h (1 440 keys) and window edge cases.

### T2.1.05 — Bounds & sets: until, count, exdates, rdates, month-day overflow
**Priority:** P0 · **Size:** M · **Depends on:** T2.1.03, T2.1.04
**Description:** Apply `until` (inclusive, local wall time), `count` (`countMode = occurrences`: RFC
semantics — exdates do **not** extend the count; `countMode = completions`: the series ends after N
completions, evaluated by the caller with completion data), `exdates` removal and `rdates` addition
(merged in order, deduplicated), and the overflow policy.
**Acceptance criteria:** `count = 10` with 2 exdates yields 8 occurrences; an rdate before the anchor is
included; `until` exactly equal to an occurrence includes it; `count` and `until` together are rejected
by validation.
**Tests:** fixtures (≥ 20 cases).

### T2.1.06 — Query API: between / nextAfter / previousBefore / occurrence keys
**Priority:** P0 · **Size:** M · **Depends on:** T2.1.05, T2.1.07
**Description:** Public API used everywhere:
`between(rule, anchor, fromLocal, toLocal, {limit})`, `nextAfter(rule, anchor, instant)`,
`previousBefore(rule, anchor, instant)`, `occurs(rule, anchor, key)`, `countBetween(...)`.
Each `Occurrence` carries `key` (`YYYY-MM-DDTHH:mm`, all-day `YYYY-MM-DD`, quota `week:YYYY-MM-DD` /
`month:YYYY-MM`), `startLocal`, `startUtc`, `endUtc` (with the owner's duration), `isAllDay`.
**Implementation notes:** `previousBefore` without full scans (bounded backward search per period);
`between` accepts an optional `durationMinutes` so occurrences *overlapping* the range (started before
`from`) are included for grid rendering.
**Acceptance criteria:** for random rules, `nextAfter(x)` equals the first element of `between(x, ∞)`;
long-running occurrences overlapping the range start are returned.
**Tests:** unit + property tests (seeded, 1 000 iterations here; the big campaign is T9.1.04).

### T2.1.07 — Time zones & DST resolution (fixed vs floating)
**Priority:** P0 · **Size:** M · **Depends on:** T2.1.01
**Description:** Resolve wall-clock occurrences to instants: fixed-zone rules use their IANA zone;
floating rules use the zone supplied by the caller (user's current zone). DST gap → shift forward by the
gap length; DST overlap → earlier offset (arch §6.8).
**Acceptance criteria:** "daily 02:30 Europe/Paris" on the spring-forward day resolves to 03:30 local;
"daily 01:30 America/New_York" on the fall-back day resolves once (first 01:30); Lord Howe's 30-min DST
handled; a floating 08:00 rule resolves to 08:00 in whichever zone is passed.
**Tests:** fixtures for Europe/Paris, America/New_York, Australia/Lord_Howe, Asia/Tehran, Africa/Tunis,
Pacific/Chatham (+12:45) — gap, overlap and normal days.

### T2.1.08 — Quota rules (N per period) & period API
**Priority:** P0 · **Size:** M · **Depends on:** T2.1.06
**Description:** `type = quota` ("3 times per week, any days", "20 times per month", "2 times per day"):
`periods(rule, anchor, from, to, weekStart)` returns `Period {key, startDate, endDate, target, eligibleDays}`
with pro-rating for partial first/last periods and hooks for excluded (paused/excused) days.
**Implementation notes:** `minGapDays` (e.g. not two days in a row) exposed as a constraint the habit
engine checks; eligible days may be restricted with `byWeekday` (e.g. 3× per week on weekdays only).
Expected count per period follows the stats research rule `E = N · eligibleDays / periodDays` for partial
periods (rounded up for display, exact for rates).
**Acceptance criteria:** a habit starting on a Thursday with 3×/week and week start Monday gets a first
period with target 3 × 4/7 (exact) and key `week:<monday date>`; week start Saturday shifts keys accordingly.
**Tests:** fixtures (≥ 15 cases) incl. month periods of 28–31 days and week starts MO/SA/SU.

### T2.1.09 — After-completion rules
**Priority:** P0 · **Size:** S · **Depends on:** T2.1.06
**Description:** `type = after_completion` ("2 days after I finish", "every 3 hours after last dose"):
`nextDue(rule, anchor, lastCompletion?)` → the anchor if never completed, else `lastCompletion + amount unit`
(calendar arithmetic in the owner's zone; day-level units keep the anchor's time of day).
**Acceptance criteria:** completing late shifts all future due times; completing early brings them
forward; keys are the due local datetime so stats can match completions.
**Tests:** unit tests for each unit (minute … year) incl. month-end arithmetic.

### T2.1.10 — Override merging helper (moved / cancelled / edited occurrences)
**Priority:** P0 · **Size:** M · **Depends on:** T2.1.06
**Description:** Generic helper that merges engine output with stored per-occurrence records
(`OccurrenceOverride {key, cancelled, newStartLocal?, newDurationMinutes?, payload}`) → resolved
occurrences for a range, including occurrences **moved into** the range from outside and excluding ones
moved out.
**Implementation notes:** callers pass overrides whose original key OR new start falls near the range
(± max duration); result keeps the original `key` (identity) plus effective times.
**Acceptance criteria:** moving Tuesday's occurrence to next Monday shows it on Monday only; cancelling
removes it; editing duration changes only that occurrence.
**Tests:** unit tests with synthetic overrides across range boundaries.

### T2.1.11 — Series split helper ("this and following")
**Priority:** P0 · **Size:** S · **Depends on:** T2.1.06
**Description:** Given a rule, its anchor and a split occurrence key, return `(truncatedRule, newRule,
newAnchor)`: the old series ends just before the split (sets `until` to the previous occurrence start,
or reduces `count` accordingly) and the new series starts at the split occurrence with the remaining count.
**Acceptance criteria:** union of both series' occurrences equals the original set (property test) when
the new rule is unchanged; count-based series split keeps the total count.
**Tests:** property tests over random rules and split points.

### T2.1.12 — Human-readable descriptions (EN / FR / AR)
**Priority:** P0 · **Size:** M · **Depends on:** T2.1.02
**Description:** `describe(rule, anchor, locale, {use24h, weekStart})` → "Every Monday and Tuesday at 08:00",
"Every 90 minutes between 08:00 and 20:00 on weekdays", "3 times a week", "2 days after completion",
"Monthly on the last weekday, 10 times" — natural phrasing, localized with correct plurals (Arabic has
zero/one/two/few/many/other forms) and ordinals.
**Implementation notes:** message catalogs inside the package (pure Dart, `intl` plural rules), no
string concatenation that breaks word order; weekday lists collapse ("weekdays", "weekends", "every day").
**Acceptance criteria:** ≥ 60 rules described in all 3 languages match reviewed golden strings.
**Tests:** golden text fixtures per locale (native-speaker review tracked in [9.1]).

### T2.1.13 — Fixture suite & runner
**Notes:** 208 fixture cases generated independently with python-dateutil/zoneinfo (`fixtures/recurrence/tool/generate_fixtures.py`); 661 package tests, 99.5 % coverage. FR/AR description goldens await native-speaker review.
**Priority:** P0 · **Size:** M · **Depends on:** T2.1.03
**Description:** `fixtures/recurrence/*.json` — each case: `{name, rule, anchor: {start, zone|null},
evalZone, range: {from, to}, expectedKeys: [...], expectedUtc?: [...], notes}` — and a test runner that
loads every file. Target ≥ 150 cases by the end of this section (the torture campaign in [9.1] extends it).
**Acceptance criteria:** adding a JSON file adds a test without code changes; failure output shows a
readable diff of keys.
**Tests:** the runner itself (a deliberately broken fixture fails with a clear message).

### T2.1.14 — App integration: `RecurrenceService` & providers
**Notes:** `recurrenceServiceProvider` (rebuilt on zone/preferences change → cache dropped) with LRU `between`, `betweenAsync` isolate offload, `nextOccurrences`, `alignAnchor`, density/never helpers; planner and the recurrence UI use it. The notification planner's pure `domain/` adapter keeps its own engine (domain can't depend on the app facade).
**Priority:** P0 · **Size:** S · **Depends on:** T2.1.06, T2.1.07, [1.3]
**Description:** App-side facade (`core/time/recurrence_service.dart`): injects `Clock`, the user's
current zone, week start and day-start settings; exposes range expansion with caching (LRU by rule hash +
range) and isolate offloading for ranges > 1 000 expected occurrences.
**Acceptance criteria:** Planner, Habits and notification planner use only this facade; changing the
device zone invalidates floating-rule caches.
**Tests:** unit tests with fake clock/zone provider; cache invalidation test.

### T2.1.15 — Recurrence builder UI: presets
**Notes:** Public API in `features/recurrence_ui/recurrence_ui.dart`: `showRecurrencePicker(context, {initial, required anchor, mode})` returns the rule to use (null = *Does not repeat*, `initial` when dismissed); `showRecurrencePickerDetailed` also returns the aligned anchor. Preset labels are the engine's localized descriptions; anchor-derived presets use the RFC minimal form. Habits never get *Does not repeat*. Goldens wait for T9.1.05 — widget tests cover EN/AR (RTL), dark theme and text scale 2.0 without overflow.
**Priority:** P0 · **Size:** M · **Depends on:** T2.1.12, T2.1.14, [1.3] (pickers)
**Description:** Bottom-sheet picker used by task/habit/checklist/notification editors: *Does not repeat*,
*Daily*, *Weekdays*, *Weekly on <day>*, *Specific days…* (weekday chips), *Every N days*, *Monthly on day
N*, *Monthly on the Nth <weekday>*, *Last day of month*, *Yearly on <date>*, *Every N hours/minutes…*,
*Several times a day…*, *N times per week/month* (habits), *After completion…*, *Custom…* (→ T2.1.16).
Shows the live description; "Ends: never / on date / after N times".
**Acceptance criteria:** every preset produces a valid rule synchronized with the anchor date (e.g. picking
"Weekly on Tuesday" when the anchor is Monday moves the anchor to Tuesday with a visible note);
available presets depend on context (quota only for habits; after-completion for tasks & habits).
**Tests:** widget tests per preset; golden in AR/RTL.

### T2.1.16 — Recurrence builder UI: advanced editor, preview & warnings
**Notes:** `showRecurrenceEditor` / `RecurrenceEditorScreen` (pinned live summary, inline errors per field, Save disabled while invalid). Weekday ordinals are added as "Nth weekday" entries; year days / week numbers are comma lists; exdates are whole days, rdates date + time. Warnings: > 24/day, nothing within 5 years, DST gap shifts (scan of the next 366 days), all-day + sub-daily. Preview budget asserted < 50 ms in `recurrence_preview_test.dart`. The "saving a rule on a task" integration test lives with the task editor tests (T3.1.06).
**Priority:** P0 · **Size:** L · **Depends on:** T2.1.15
**Description:** Full editor exposing every field: frequency, interval, weekday chips with ordinals (1st,
2nd, 3rd, 4th, last), month-day grid (incl. negatives "2nd to last"), months, set positions, hours &
minutes, times list, window with anchor mode, week start, until/count, overflow policy, exdates/rdates
lists. A **preview** lists the next 10 occurrences (local times + zone) and a mini calendar highlights
the next 60 days. Warnings: "288 occurrences per day", "never occurs in the next 5 years", DST notes.
**Acceptance criteria:** any rule the engine supports can be built and edited without JSON; invalid
states show inline localized errors and disable Save; preview updates < 50 ms.
**Tests:** widget tests for complex combos (last weekday of month; every 45 min 09–18 weekdays);
integration test saving a rule on a task.

### T2.1.17 — RRULE import / export (RFC 5545 text)
**Priority:** P1 · **Size:** M · **Depends on:** T2.1.05
**Description:** `fromRRule(String)` parses `RRULE`, optional `DTSTART;TZID=…`, `EXDATE`, `RDATE`
lines; `toRRule(rule, anchor)` returns text or `null` when not representable (windows with
`window_start` anchoring when interval doesn't divide the day, quota, after-completion, non-cross-product
`times`). Used by ICS import/export ([8.2]).
**Acceptance criteria:** RFC example rules round-trip; exports validated by parsing them back; clear
error messages for unsupported inputs (e.g. `FREQ=SECONDLY`).
**Tests:** fixture pairs (RRULE text ↔ JSON rule).

### T2.1.18 — Performance benchmarks & safety caps
**Priority:** P1 · **Size:** S · **Depends on:** T2.1.06
**Description:** Benchmarks (`benchmark_harness`): 1 year of a daily rule < 5 ms; one day of a 1-minute
rule < 2 ms; 10 years of "last weekday of month" < 5 ms; nextAfter on a 20-year-old rule < 1 ms.
Hard caps: max occurrences per call (default 10 000) and per-day density (1 440) with explicit errors.
**Acceptance criteria:** CI job records numbers; > 20 % regression fails.
**Tests:** benchmark suite.

### T2.1.19 — Exceptions manager UI (skipped/moved occurrences of a series)
**Priority:** P1 · **Size:** S · **Depends on:** T2.1.10, [3.2]
**Description:** From a series, list cancelled and moved occurrences with *Restore* / *Open*; bulk "restore
all exceptions".
**Tests:** widget test; unit test that restoring removes the override record.
**Notes:** Reusable `RecurrenceExceptionsView` (recurrence_ui) hosted by the planner sheet `showTaskExceptionsSheet`; *Restore all* also clears the rule's excluded dates in the same operation (one undo). Tests: `test/features/planner/presentation/task_exceptions_test.dart`.

### T2.1.20 — Non-Gregorian calendar extension point (design only)
**Priority:** P2 · **Size:** S · **Depends on:** T2.1.02
**Description:** Document how a `"calendar": "gregorian" | "islamic-umalqura" | …` field (RFC 7529
`RSCALE`-like, rule schema v2) would plug into period iteration and descriptions; no implementation
(tracked in [9.3] T9.3.05).
**Acceptance criteria:** short design note in `packages/everslot_recurrence/doc/rscale.md` reviewed.
