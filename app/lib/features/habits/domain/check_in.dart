import 'package:everslot_metrics/everslot_metrics.dart'
    show DayBoundaries, HabitLogKind, HabitPeriod, HabitPeriodKind, PeriodResult, PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Explicit statements a user can make about a period (arch §6.11 check-in semantics).
enum CheckInState {
  done(HabitLogKind.done),
  notDone(HabitLogKind.fail),
  skip(HabitLogKind.skip),
  excuse(HabitLogKind.excuse);

  const CheckInState(this.kind);

  final HabitLogKind kind;

  static CheckInState? ofKind(HabitLogKind? kind) {
    for (final s in values) {
      if (s.kind == kind) return s;
    }
    return null;
  }

  /// Planned absences are allowed for future days; done / not done are not.
  bool get allowedInFuture => this == skip || this == excuse;
}

/// Week-matrix tap cycles (T5.2.06, `user_settings.habits.matrixTapCycle`).
enum TapCycle {
  /// done → not done → clear (default — "I did it or not").
  doneNotDoneClear('done_fail_clear'),

  /// done → skip → clear (Loop style).
  doneSkipClear('done_skip_clear'),

  /// done → clear.
  doneClear('done_clear');

  const TapCycle(this.json);

  final String json;

  static TapCycle parse(Object? value) =>
      values.firstWhere((c) => c.json == value, orElse: () => TapCycle.doneNotDoneClear);

  /// Next state after a tap on a cell whose current explicit state is [current] (null = none);
  /// null means *clear*.
  CheckInState? next(HabitLogKind? current) {
    switch (this) {
      case TapCycle.doneNotDoneClear:
        return switch (current) {
          null => CheckInState.done,
          HabitLogKind.done => CheckInState.notDone,
          HabitLogKind.fail => null,
          _ => CheckInState.done,
        };
      case TapCycle.doneSkipClear:
        return switch (current) {
          null => CheckInState.done,
          HabitLogKind.done => CheckInState.skip,
          HabitLogKind.skip => null,
          _ => CheckInState.done,
        };
      case TapCycle.doneClear:
        return current == HabitLogKind.done ? null : CheckInState.done;
    }
  }
}

/// Where a check-in lands: a day key or a slot key (never a quota key) with its window.
@immutable
class CheckInTarget {
  const CheckInTarget({
    required this.key,
    required this.localDate,
    required this.windowStart,
    required this.windowEnd,
    this.slotTime,
  });

  /// Day target (`YYYY-MM-DD`) of [date] — also used for days inside quota periods.
  factory CheckInTarget.day(LocalDate date, DayBoundaries boundaries) => CheckInTarget(
    key: date.toIso(),
    localDate: date,
    windowStart: boundaries.startOf(date),
    windowEnd: boundaries.endOf(date),
  );

  /// Target of a day or slot [period]; quota periods map to the day [date] inside them.
  factory CheckInTarget.ofPeriod(HabitPeriod period, DayBoundaries boundaries, {LocalDate? date}) {
    switch (period.kind) {
      case HabitPeriodKind.day:
        return CheckInTarget(
          key: period.key,
          localDate: period.startDate,
          windowStart: period.windowStart,
          windowEnd: period.windowEnd,
        );
      case HabitPeriodKind.slot:
        return CheckInTarget(
          key: period.key,
          localDate: period.startDate,
          windowStart: period.windowStart,
          windowEnd: period.windowEnd,
          slotTime: LocalDateTime.tryParse(period.key)?.time,
        );
      case HabitPeriodKind.quota:
        return CheckInTarget.day(date ?? period.startDate, boundaries);
    }
  }

  final String key;
  final LocalDate localDate;
  final DateTime windowStart;
  final DateTime windowEnd;

  /// Wall-clock time of a slot target.
  final LocalTime? slotTime;

  bool get isSlot => slotTime != null;

  bool isFuture(DateTime now) => windowStart.isAfter(now);

  bool isOpen(DateTime now) => !windowStart.isAfter(now) && windowEnd.isAfter(now);

  bool isClosed(DateTime now) => !windowEnd.isAfter(now);

  @override
  bool operator ==(Object other) =>
      other is CheckInTarget &&
      other.key == key &&
      other.localDate == localDate &&
      other.windowStart == windowStart &&
      other.windowEnd == windowEnd &&
      other.slotTime == slotTime;

  @override
  int get hashCode => Object.hash(key, localDate, windowStart, windowEnd, slotTime);

  @override
  String toString() => 'CheckInTarget($key)';
}

/// `logged_at` of a check-in (T5.2.08): the real time while the period is open; for a closed
/// (backfilled) or future (planned) period, the period's local date at [chosenTime] — default the
/// slot time, else 12:00 — in the habit zone. `created_at` always keeps the real write time.
DateTime checkInInstant(
  CheckInTarget target, {
  required DateTime now,
  required DayBoundaries boundaries,
  LocalTime? chosenTime,
}) {
  if (chosenTime == null && target.isOpen(now)) return now;
  final wall = target.isSlot && chosenTime == null
      ? LocalDateTime.tryParse(target.key)
      : null;
  final local = wall ?? target.localDate.atTime(chosenTime ?? LocalTime.noon);
  return boundaries.clock.toInstant(local);
}

/// Why a check-in is refused.
enum CheckInRefusal {
  /// Done / progress for a period that has not started.
  future,

  /// Archived habits are read-only.
  archived,
}

/// Guard of the check-in service (T5.2.01).
CheckInRefusal? checkInRefusal({
  required CheckInTarget target,
  required DateTime now,
  required bool archived,
  CheckInState? state,
  bool progress = false,
}) {
  if (archived) return CheckInRefusal.archived;
  if (target.isFuture(now) && (progress || !(state?.allowedInFuture ?? false))) {
    return CheckInRefusal.future;
  }
  return null;
}

/// Visual state of an intraday slot chip (T5.2.05).
enum SlotChipState { done, partial, failed, skipped, excused, frozen, paused, missed, current, upcoming }

/// Maps a slot result to its chip state at [now]: pending slots are *current* while their window is
/// open and *upcoming* before it; past unlogged slots are *missed*.
SlotChipState slotChipState(PeriodResult r, DateTime now) => switch (r.status) {
  PeriodStatus.done => SlotChipState.done,
  PeriodStatus.partial => SlotChipState.partial,
  PeriodStatus.failed => SlotChipState.failed,
  PeriodStatus.skipped => SlotChipState.skipped,
  PeriodStatus.excused => SlotChipState.excused,
  PeriodStatus.frozen => SlotChipState.frozen,
  PeriodStatus.paused => SlotChipState.paused,
  PeriodStatus.missed => SlotChipState.missed,
  PeriodStatus.pending || PeriodStatus.notDue =>
    r.windowStart.isAfter(now) ? SlotChipState.upcoming : SlotChipState.current,
};

/// Remaining amount to reach the target of a measurable period ("Done" logs it as one entry).
double remainingToTarget(PeriodResult r) {
  final left = r.target - r.achieved;
  return left > 0 ? left : 0;
}

/// Parses a user-typed decimal in any locale: `,` or `.` decimal separators, Arabic-Indic and
/// Eastern Arabic digits, the Arabic decimal separator `٫` and grouping characters (T5.2.04).
double? parseLocalizedDecimal(String input) {
  const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  const easternArabic = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final rune in input.trim().runes) {
    final ch = String.fromCharCode(rune);
    final ai = arabicIndic.indexOf(ch);
    final ea = easternArabic.indexOf(ch);
    if (ai >= 0) {
      buffer.write(ai);
    } else if (ea >= 0) {
      buffer.write(ea);
    } else if (ch == '٫' || ch == ',') {
      buffer.write('.');
    } else if (ch == '٬' || ch == ' ' || ch == ' ' || ch == ' ' || ch == "'") {
      continue;
    } else {
      buffer.write(ch);
    }
  }
  var text = buffer.toString();
  // "1.234.5" style (several dots): keep the last one as the decimal separator.
  final dots = '.'.allMatches(text).length;
  if (dots > 1) {
    final last = text.lastIndexOf('.');
    text = text.substring(0, last).replaceAll('.', '') + text.substring(last);
  }
  if (text.isEmpty) return null;
  final value = double.tryParse(text);
  return value == null || value.isNaN || value.isInfinite ? null : value;
}
