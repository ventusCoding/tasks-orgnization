import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/record_moments.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/habit_fixtures.dart';

void main() {
  final service = periodService();
  final now = DateTime.utc(2026, 9, 22, 20);

  HabitLogEntry log(HabitLogKind kind, int day, {double? value, int hour = 9, bool? resisted}) => HabitLogEntry(
    id: '${kind.name}-$day-$hour',
    habitId: 'h1',
    kind: kind,
    loggedAt: DateTime.utc(2026, 9, day, hour),
    localDate: d(2026, 9, day),
    occurrenceKey: kind == HabitLogKind.craving || kind == HabitLogKind.relapse ? null : d(2026, 9, day).toIso(),
    value: value,
    resisted: resisted,
  );

  List<RecordMoment> moments(Habit habit, List<HabitLogEntry> logs) =>
      recordMoments(computeSnapshot(service, habit, const [], logs, const [], now));

  group('record moments (T5.4.10)', () {
    final pushUps = buildHabit(start: d(2026, 9, 1), goal: const HabitTarget(type: HabitGoalType.count, target: 20, unit: 'reps'));

    test('a best day today is a new record; a best day in the past is not', () {
      final history = [for (var day = 1; day <= 21; day++) log(HabitLogKind.progress, day, value: 20)];
      expect(moments(pushUps, [...history, log(HabitLogKind.progress, 22, value: 35)]), contains(const RecordMoment(RecordKind.bestDay, 35)));
      final oldBest = [...history.take(20), log(HabitLogKind.progress, 21, value: 50), log(HabitLogKind.progress, 22, value: 20)];
      expect(moments(pushUps, oldBest).where((m) => m.kind == RecordKind.bestDay), isEmpty);
    });

    test('the current streak beating every earlier one is a record', () {
      final yesNo = buildHabit(start: d(2026, 9, 1));
      final logs = [
        for (final day in [1, 2, 3]) log(HabitLogKind.done, day),
        for (var day = 10; day <= 22; day++) log(HabitLogKind.done, day),
      ];
      expect(moments(yesNo, logs), contains(const RecordMoment(RecordKind.longestStreak, 13)));
      expect(moments(yesNo, [for (var day = 1; day <= 22; day++) log(HabitLogKind.done, day)]), isEmpty, reason: 'no earlier streak to beat');
    });

    test('quit: longest abstinence and most cravings resisted in a day', () {
      final tracker = QuitHabit(
        id: 'h1',
        name: 'Stop smoking',
        startDate: d(2026, 9, 1),
        sortKey: 'a0',
        mode: QuitMode.abstain,
        quitStartedAt: DateTime.utc(2026, 9, 1),
        substance: QuitSubstance.cigarettes,
        baselinePerDay: 10,
      );
      final logs = [
        log(HabitLogKind.relapse, 5, hour: 12),
        log(HabitLogKind.craving, 10, resisted: true),
        log(HabitLogKind.craving, 22, resisted: true, hour: 8),
        log(HabitLogKind.craving, 22, resisted: true, hour: 12),
      ];
      final m = moments(tracker, logs);
      expect(m.map((e) => e.kind), containsAll([RecordKind.longestAbstinence, RecordKind.mostCravingsResisted]));
      expect(m.firstWhere((e) => e.kind == RecordKind.mostCravingsResisted).value, 2);
    });
  });
}
