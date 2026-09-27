import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/today_view.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show PeriodStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../support/habit_fixtures.dart';

void main() {
  final service = periodService();
  // "Water the plants 3 days after the last time", since Sept 1; today = Sept 12, 10:00 UTC.
  final habit = buildHabit(start: d(2026, 9, 1), schedule: RecurrenceRule.forAfterCompletion(3, RecurrenceUnit.day));
  final now = DateTime.utc(2026, 9, 12, 10);

  HabitLogEntry done(int day) => HabitLogEntry(
    id: 'd$day',
    habitId: 'h1',
    kind: HabitLogKind.done,
    loggedAt: DateTime.utc(2026, 9, day, 9),
    localDate: d(2026, 9, day),
    occurrenceKey: d(2026, 9, day).toIso(),
  );

  HabitSnapshot snapshot(List<HabitLogEntry> logs) => computeSnapshot(service, habit, const [], logs, const [], now);

  group('after-completion habits (T5.1.17)', () {
    test('windows: on time, on time, late; a late completion moves the next due date', () {
      final s = snapshot([done(1), done(4), done(9)]);
      final e = s.evaluation!;
      expect(e.units.map((u) => (u.key, u.status)), [
        ('2026-09-01', PeriodStatus.done),
        ('2026-09-04', PeriodStatus.done),
        ('2026-09-07', PeriodStatus.missed), // done on the 9th: late
        ('2026-09-12', PeriodStatus.pending), // 9th + 3 days: due today
      ]);
      expect(e.dayOn(d(2026, 9, 2))!.status, PeriodStatus.notDue);
      expect(e.dayOn(d(2026, 9, 7))!.status, PeriodStatus.missed);
      expect(e.dayOn(d(2026, 9, 8))!.status, PeriodStatus.notDue, reason: 'overdue days are one period');
      expect(e.dayOn(d(2026, 9, 9))!.status, PeriodStatus.done);
      expect(e.dayOn(d(2026, 9, 12))!.status, PeriodStatus.pending);
      expect(s.summary!.currentStreak, 0, reason: 'the late window broke the streak');
      expect(s.summary!.bestStreak, 2);
    });

    test('an early completion counts for the coming window', () {
      final e = snapshot([done(1), done(3)]).evaluation!;
      expect(e.units.take(2).map((u) => (u.key, u.status)), [
        ('2026-09-01', PeriodStatus.done),
        ('2026-09-03', PeriodStatus.done),
      ]);
      // Next due: Sept 6 — the 6th to 11th are overdue, today still open and at risk.
      final today = e.dayOn(d(2026, 9, 12))!;
      expect((today.status, today.flags.atRisk), (PeriodStatus.pending, true));
      expect(e.dayOn(d(2026, 9, 6))!.status, PeriodStatus.missed);
    });

    testWidgets('the Today list flags an overdue window', (tester) async {
      final h = TestHarness.create(
        now: DateTime.utc(2026, 9, 22, 10),
        overrides: [inboxUnreadCountProvider.overrideWith((ref) => Stream.value(0))],
      );
      addTearDown(h.dispose);
      final plants = BuildHabit(
        id: Ids.v7(),
        name: 'Water the plants',
        startDate: d(2026, 9, 1),
        sortKey: '',
        goal: const HabitTarget.check(),
        schedule: RecurrenceRule.forAfterCompletion(3, RecurrenceUnit.day),
      );
      await tester.runAsync(() async {
        await h.read(habitsRepositoryProvider).create(plants);
        await h.read(checkInServiceProvider).markDone(plants, '2026-09-10');
      });
      await pumpInApp(tester, h, Scaffold(body: TodayList(date: d(2026, 9, 22))));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text(lookupAppLocalizations(const Locale('en')).habitsOverdue), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
    });

    test('not yet due today', () {
      final e = snapshot([done(11)]).evaluation!;
      expect(e.dayOn(d(2026, 9, 12))!.status, PeriodStatus.notDue, reason: 'next due Sept 14');
    });
  });
}
