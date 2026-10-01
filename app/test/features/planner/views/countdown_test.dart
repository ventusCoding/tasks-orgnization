import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/application/view_config/countdowns.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support/planner_harness.dart';

// Countdown / count-up list (T3.7.12). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initializeDateFormatting();
  });

  group('counters', () {
    test('calendar days across a DST change are whole days (Europe/Paris)', () {
      expect(calendarDaysBetween(LocalDate(2026, 3, 28), LocalDate(2026, 3, 30)), 2);
      expect(calendarDaysBetween(LocalDate(2026, 10, 26), LocalDate(2026, 10, 24)), -2);
      final zones = TzZoneResolver();
      final before = zones.resolve(LocalDateTime.of(2026, 3, 28, 12, 0), 'Europe/Paris').utc;
      final after = zones.resolve(LocalDateTime.of(2026, 3, 30, 12, 0), 'Europe/Paris').utc;
      expect(after.difference(before), const Duration(hours: 47), reason: 'the counter counts real time');
    });

    test('targets: deadline first, next / previous occurrence for series, one-off start', () {
      final h = PlannerHarness.create();
      addTearDown(h.dispose);
      final service = h.read(recurrenceServiceProvider);
      final now = DateTime.utc(2026, 9, 23, 9, 30);
      DateTime? target(Task t) => countdownTarget(t, service, nowUtc: now, zone: 'UTC');
      final trip = Task(
        id: 't',
        seriesId: 't',
        title: 'Trip',
        startLocal: LocalDateTime.of(2026, 10, 3, 8, 0),
        durationMinutes: 60,
        countdownMode: CountdownMode.until,
      );
      expect(target(trip), DateTime.utc(2026, 10, 3, 8));
      expect(target(trip.copyWith(deadlineLocal: LocalDateTime.of(2026, 9, 30, 18, 0))), DateTime.utc(2026, 9, 30, 18));
      final weekly = trip.copyWith(startLocal: LocalDateTime.of(2026, 9, 1, 7, 0), recurrence: RecurrenceRule());
      expect(target(weekly), DateTime.utc(2026, 9, 24, 7), reason: 'next daily occurrence after now');
      expect(target(weekly.copyWith(countdownMode: CountdownMode.since)), DateTime.utc(2026, 9, 23, 7));
      expect(target(trip.copyWith(startLocal: null)), isNull, reason: 'unscheduled without a deadline');
    });
  });

  testWidgets('rows show days until / since with a live counter; pin and remove', (tester) async {
    final h = PlannerHarness.create(realData: true);
    addTearDown(h.dispose);
    await tester.runAsync(() async {
      final s = h.read(plannerServiceProvider);
      await s.createTask(
        Task(
          id: '',
          seriesId: '',
          title: 'Vacation',
          startLocal: LocalDateTime.of(2026, 10, 3, 9, 30),
          durationMinutes: 60,
          countdownMode: CountdownMode.until,
        ),
        source: 'test',
      );
      await s.createTask(
        Task(
          id: '',
          seriesId: '',
          title: 'Quit sugar',
          startLocal: LocalDateTime.of(2026, 9, 13, 9, 30),
          durationMinutes: 30,
          countdownMode: CountdownMode.since,
        ),
        source: 'test',
      );
    });
    await pumpPlanner(tester, h, const PlannerScreen(view: 'countdown'));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('in 10 days'), findsOneWidget);
    expect(find.text('10 days ago'), findsOneWidget);
    expect(find.textContaining('10 d 0 h 0 min'), findsWidgets);

    h.clock.advance(const Duration(hours: 1, minutes: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('9 d 22 h 55 min'), findsOneWidget, reason: 'the countdown ticks');

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin').last);
    await tester.pumpAndSettle();
    expect(h.read(plannerViewConfigProvider('countdown')).options['pinned'], hasLength(1));
    expect(find.text('Pinned'), findsOneWidget);
    h.clock.advance(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
  });
}
