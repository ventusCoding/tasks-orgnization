import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show Value, habitRecords;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

enum RecordKind { bestDay, bestWeek, longestStreak, longestAbstinence, mostCravingsResisted }

/// A personal record set right now (T5.4.10) — "New record!" moments on the Today list, the
/// habit detail and the quit dashboard. Day and week records come from `everslot_metrics`
/// `habitRecords` (a backfilled old day never counts as new).
@immutable
class RecordMoment {
  const RecordMoment(this.kind, this.value);

  final RecordKind kind;

  /// Value of the record (units, days, minutes of abstinence, cravings).
  final num value;

  @override
  bool operator ==(Object other) => other is RecordMoment && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);

  @override
  String toString() => 'RecordMoment(${kind.name}, $value)';
}

/// The records [snapshot] sets as of its today.
List<RecordMoment> recordMoments(HabitSnapshot snapshot, {Weekday weekStart = Weekday.monday}) {
  final out = <RecordMoment>[];
  final today = snapshot.today;
  final habit = snapshot.build;
  final evaluation = snapshot.evaluation;
  if (habit != null && evaluation != null) {
    if (habit.goal.isMeasurable && !habit.goal.isLimit) {
      final days = [for (final d in evaluation.days.values) if (!d.startDate.isAfter(today)) d];
      final records = habitRecords(days, from: habit.startDate, to: today, currentPeriodStart: today, weekStart: weekStart);
      if (records.day case Value(value: final r) when r.isNew && r.previousBest != null && r.value > 0) {
        out.add(RecordMoment(RecordKind.bestDay, r.value));
      }
      if (records.week case Value(value: final r) when r.isNew && r.previousBest != null && r.value > 0) {
        out.add(RecordMoment(RecordKind.bestWeek, r.value));
      }
    }
    final streaks = snapshot.summary?.streaks;
    final current = streaks?.current;
    if (streaks != null && current != null && current.length >= 3) {
      final others = [for (final s in streaks.streaks) if (s != current) s.length];
      if (others.isNotEmpty && current.length > others.reduce((a, b) => a > b ? a : b)) {
        out.add(RecordMoment(RecordKind.longestStreak, current.length));
      }
    }
  }
  final calc = snapshot.quit;
  if (calc != null) {
    final intervals = calc.abstinenceIntervals;
    if (intervals.length > 1) {
      final current = calc.currentAbstinence;
      var previousBest = Duration.zero;
      for (final i in intervals.take(intervals.length - 1)) {
        final length = i.end!.difference(i.start);
        if (length > previousBest) previousBest = length;
      }
      if (current > previousBest && previousBest > Duration.zero) {
        out.add(RecordMoment(RecordKind.longestAbstinence, current.inMinutes));
      }
    }
    final resistedByDay = <LocalDate, int>{};
    for (final l in snapshot.logs) {
      if (l.kind == HabitLogKind.craving && l.resisted == true) {
        resistedByDay[l.localDate] = (resistedByDay[l.localDate] ?? 0) + 1;
      }
    }
    final todayCount = resistedByDay[today] ?? 0;
    final before = [
      for (final e in resistedByDay.entries)
        if (e.key.isBefore(today)) e.value,
    ];
    if (todayCount >= 2 && before.isNotEmpty && todayCount > before.reduce((a, b) => a > b ? a : b)) {
      out.add(RecordMoment(RecordKind.mostCravingsResisted, todayCount));
    }
  }
  return out;
}
