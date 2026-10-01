import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/presentation/calendar_views.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../support/habit_fixtures.dart';

void main() {
  late TestHarness h;
  final en = lookupAppLocalizations(const Locale('en'));
  final fmt = AppFormat('en');
  setUp(
    () => h = TestHarness.create(
      now: DateTime.utc(2026, 9, 22, 10),
      overrides: [inboxUnreadCountProvider.overrideWith((ref) => Stream.value(0))],
    ),
  );
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  Future<BuildHabit> create(WidgetTester tester, String name) async {
    final habit = BuildHabit(
      id: Ids.v7(),
      name: name,
      startDate: d(2026, 9, 1),
      sortKey: '',
      goal: const HabitTarget.check(),
      schedule: buildHabit().schedule,
    );
    await tester.runAsync(() => h.read(habitsRepositoryProvider).create(habit));
    return habit;
  }

  testWidgets('month overview: share of due habits per day, perfect days, excused not due (T5.2.11)', (tester) async {
    final a = await create(tester, 'Meditate');
    final b = await create(tester, 'Read');
    await tester.runAsync(() async {
      final checkIn = h.read(checkInServiceProvider);
      for (final day in ['2026-09-19', '2026-09-20', '2026-09-21']) {
        await checkIn.markDone(a, day);
      }
      await checkIn.markDone(b, '2026-09-21');
      await checkIn.markNotDone(b, '2026-09-20');
      await checkIn.excuse(b, '2026-09-19');
    });
    await pumpInApp(tester, h, Scaffold(body: MonthOverview(initialMonth: d(2026, 9, 22))));
    await settle(tester);
    String label(int day, double ratio) => '${fmt.dayLong(d(2026, 9, day))}, ${fmt.percent(ratio)}';
    expect(find.bySemanticsLabel(label(21, 1)), findsOneWidget);
    expect(find.bySemanticsLabel(label(20, 0.5)), findsOneWidget);
    expect(find.bySemanticsLabel(label(19, 1)), findsOneWidget, reason: 'an excused habit is not due');
    expect(find.text(en.habitsPerfectDays(2)), findsOneWidget);

    // Tapping a day lists every habit of that day with inline editing.
    await tester.tap(find.bySemanticsLabel(label(20, 0.5)));
    await settle(tester);
    expect(find.text(fmt.dayLong(d(2026, 9, 20))), findsOneWidget);
    expect(find.text('Meditate'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('year heatmap: accessible summary, legend, tap a day opens the day editor (T5.2.10)', (tester) async {
    final habit = await create(tester, 'Meditate');
    await tester.runAsync(() async {
      final checkIn = h.read(checkInServiceProvider);
      await checkIn.markDone(habit, '2026-09-20');
      await checkIn.markDone(habit, '2026-09-21');
      await h.read(habitServiceProvider).pause(habitId: habit.id, start: d(2026, 9, 10), end: d(2026, 9, 12));
    });
    await pumpInApp(
      tester,
      h,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: YearHeatmap(habitId: habit.id),
        ),
      ),
    );
    await settle(tester);
    // Sept 1–21 minus 3 paused days = 18 scheduled days, 2 done (today is still pending).
    final summary = en.habitsYearSummary(2, 18, '2026');
    expect(find.text(summary), findsOneWidget);
    expect(find.bySemanticsLabel(summary), findsOneWidget);
    expect(find.text(en.habitsStatusDone), findsOneWidget, reason: 'legend');

    final weekStart = h.read(userPreferencesProvider).weekStart;
    final start = d(2026, 9, 22).minusDays(52 * 7).startOfWeek(weekStart);
    final index = start.daysUntil(d(2026, 9, 21));
    final grid = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_HeatmapPainter',
    );
    await tester.tapAt(tester.getTopLeft(grid) + Offset((index ~/ 7) * 15 + 6, (index % 7) * 15 + 6));
    await settle(tester);
    expect(find.text(fmt.dayLong(d(2026, 9, 21))), findsOneWidget);
    await disposeTree(tester);
  });
}
