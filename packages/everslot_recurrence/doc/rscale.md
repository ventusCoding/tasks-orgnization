# Non-Gregorian calendars (RSCALE) — design note

Status: design only (T2.1.20). Implementation is tracked in T9.3.05.

## Goal

Let a rule recur in another calendar system — e.g. "every 1 Ramadan", "on the
15th of each Hijri month", "yearly on 1 Tishrei" — while occurrences keep the
same identity, zone and DST rules as today. We follow RFC 7529 (`RSCALE`,
`SKIP`) so that RRULE import/export stays possible.

## Rule schema v2

Two optional fields, added in schema order after `wkst`:

```jsonc
{
  "v": 2,
  "calendar": "islamic-umalqura", // gregorian (default) | islamic-umalqura | islamic-civil | hebrew | persian | …
  "skip": "omit"                  // omit | backward | forward (RFC 7529 SKIP)
}
```

* `calendar` uses CLDR calendar identifiers (the values RFC 7529 registers for
  `RSCALE`). Absent = `gregorian`, so every v1 rule is a valid v2 rule.
* `skip` generalizes today's `monthDayOverflow`: `omit` = `skip`, `backward` =
  `clamp`. The v1 → v2 migration (added to `RecurrenceRule.migrations[1]`)
  maps `monthDayOverflow` to `skip` and writes `"v": 2`; `forward` (use the
  first day of the next month) becomes available for all calendars.
* `byMonth` values may carry a leap marker (`"5L"` for Adar I in the Hebrew
  calendar), so the field becomes `List<String>` in v2 for non-Gregorian rules.
* Validation: unknown calendar → `unsupportedCombo`; `byWeekNo` is rejected for
  non-Gregorian calendars (RFC 7529 leaves it undefined).

## Where it plugs into the engine

The engine already separates *period iteration* from *zone resolution*:

1. `RulePlan` iterates periods (years, months, weeks, days) and builds each
   period's candidate days, applying the `BYxxx` filters and `BYSETPOS`.
2. `RecurrenceEngine` resolves the resulting wall-clock minutes through the
   `ZoneResolver`.

Only step 1 depends on the calendar. We introduce a small interface:

```dart
abstract interface class CalendarSystem {
  /// Converts an epoch day to calendar fields (year, month, day, leap month flag).
  CalendarDate fromEpochDay(int epochDay);
  int toEpochDay(int year, int month, int day);
  int monthsInYear(int year);
  int daysInMonth(int year, int month);
  int daysInYear(int year);
}
```

* `GregorianCalendar` wraps the existing `LocalDate` arithmetic (no behaviour
  change; benchmarks must not regress).
* Yearly/monthly periods, `byMonth`, `byMonthDay` (±), `byYearDay` (±) and
  month-day overflow are evaluated in calendar fields obtained from the
  `CalendarSystem`; weekly and daily periods and every sub-daily rule are
  calendar-independent (weekdays and days are shared by all calendars).
* Candidate days are still epoch days and times are still wall-clock minutes,
  so occurrence keys (`YYYY-MM-DDTHH:mm`, Gregorian), exdates, rdates, DST
  resolution, quotas and the override/split helpers are unchanged.
* `RulePlan.compile` receives the `CalendarSystem` for `rule.calendar`
  (default Gregorian); anchor-derived defaults (month, day) are read in that
  calendar.
* Islamic calendars: `islamic-umalqura` uses the Umm al-Qura table (1300–1600 AH)
  and falls back to the arithmetic `islamic-civil` outside it; sighting-based
  variants are out of scope (they need a server-side data feed).

## Descriptions

`RecurrenceDescriber` gets per-calendar month-name lists in each catalog
(`months.islamic`, `months.hebrew`, …) and a calendar suffix when it isn't the
user's default (e.g. "Yearly on 1 Ramadan (Hijri calendar)"). Dates in
`until` are shown in the rule's calendar with the Gregorian date in brackets.

## RRULE import / export

`RRuleCodec` already accepts `RSCALE=GREGORIAN` with `SKIP=OMIT|BACKWARD`
(mapped to `monthDayOverflow`). v2 accepts the other registered `RSCALE`
values, maps `SKIP=FORWARD`, and exports `RSCALE`/`SKIP` whenever the rule's
calendar is not Gregorian or `skip` is not `omit`.

## Testing

* Fixtures in `fixtures/recurrence/rscale_*.json` generated from ICU4X /
  `java.time.chrono.HijrahDate` as an independent oracle (same approach as the
  python-dateutil fixtures), including 29/30-day Hijri months with `skip`
  variants and Hebrew leap years.
* Property tests: for Gregorian, v2 rules must produce exactly the v1 output.
