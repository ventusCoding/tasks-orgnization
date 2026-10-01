import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/data/habit_logs_repository.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot/features/habits/presentation/habit_detail_screen.dart';
import 'package:everslot/features/habits/presentation/habits_screen.dart';
import 'package:everslot/features/habits/presentation/today_view.dart';
import 'package:everslot/features/habits/presentation/week_matrix.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../support/habit_fixtures.dart';

void main() {
  late TestHarness h;
  final en = lookupAppLocalizations(const Locale('en'));
  setUp(
    () => h = TestHarness.create(
      // Tuesday 2026-09-22, 13:40 UTC.
      now: DateTime.utc(2026, 9, 22, 13, 40),
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

  /// Creates a habit with a fresh id (the fixture's id is replaced).
  Future<String> create(WidgetTester tester, BuildHabit habit) async {
    final id = Ids.v7();
    final base = habit;
    await tester.runAsync(
      () => h
          .read(habitsRepositoryProvider)
          .create(
            BuildHabit(
              id: id,
              name: base.name,
              startDate: base.startDate,
              sortKey: '',
              goal: base.goal,
              schedule: base.schedule,
              settings: base.settings,
            ),
          ),
    );
    return id;
  }

  Future<List<HabitLogEntry>> logsOf(WidgetTester tester, String id) async =>
      (await tester.runAsync(() => h.read(habitLogsRepositoryProvider).forHabit(id)))!;

  Future<void> pumpToday(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    await pumpInApp(
      tester,
      h,
      Scaffold(body: TodayList(date: d(2026, 9, 22))),
      locale: locale,
    );
    await settle(tester);
  }

  group('Today list gestures (T5.2.03)', () {
    testWidgets('swipe start→end marks done (LTR)', (tester) async {
      final id = await create(tester, buildHabit(name: 'Meditate'));
      await pumpToday(tester);
      await tester.drag(find.widgetWithText(HabitRow, 'Meditate'), const Offset(400, 0));
      await settle(tester);
      expect((await logsOf(tester, id)).single.kind, HabitLogKind.done);
      await disposeTree(tester);
    });

    testWidgets('swipe directions mirror in RTL: dragging left marks done', (tester) async {
      final id = await create(tester, buildHabit(name: 'Meditate'));
      await pumpToday(tester, locale: const Locale('ar'));
      await tester.drag(find.widgetWithText(HabitRow, 'Meditate'), const Offset(-400, 0));
      await settle(tester);
      expect((await logsOf(tester, id)).single.kind, HabitLogKind.done);
      await disposeTree(tester);
    });

    testWidgets('a full swipe end→start marks not done (explicit fail)', (tester) async {
      final id = await create(tester, buildHabit(name: 'Meditate'));
      await pumpToday(tester);
      await tester.drag(find.widgetWithText(HabitRow, 'Meditate'), const Offset(-700, 0));
      await settle(tester);
      expect((await logsOf(tester, id)).single.kind, HabitLogKind.fail);
      await disposeTree(tester);
    });

    testWidgets('long-press menu: skip with a reason; cancelling the reason skips nothing', (tester) async {
      final id = await create(tester, buildHabit(name: 'Meditate'));
      await pumpToday(tester);
      await tester.longPress(find.text('Meditate'));
      await settle(tester);
      await tester.tap(find.widgetWithText(ListTile, en.habitsActionSkip));
      await settle(tester);
      await tester.tap(find.widgetWithText(TextButton, en.actionCancel));
      await settle(tester);
      expect(await logsOf(tester, id), isEmpty);

      await tester.longPress(find.text('Meditate'));
      await settle(tester);
      await tester.tap(find.widgetWithText(ListTile, en.habitsActionSkip));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Sick');
      await tester.tap(find.widgetWithText(FilledButton, en.actionSave));
      await settle(tester);
      final log = (await logsOf(tester, id)).single;
      expect(log.kind, HabitLogKind.skip);
      expect(log.note, 'Sick');
      await disposeTree(tester);
    });

    testWidgets('future days offer only planned skips and excuses', (tester) async {
      await create(tester, buildHabit(name: 'Meditate'));
      await pumpInApp(tester, h, Scaffold(body: TodayList(date: d(2026, 9, 23))));
      await settle(tester);
      await tester.longPress(find.text('Meditate'));
      await settle(tester);
      expect(find.widgetWithText(ListTile, en.habitsActionDone), findsNothing);
      expect(find.widgetWithText(ListTile, en.habitsActionSkip), findsOneWidget);
      expect(find.widgetWithText(ListTile, en.habitsActionExcuse), findsOneWidget);
      await disposeTree(tester);
    });
  });

  group('measurable input (T5.2.04)', () {
    testWidgets('numeric value sheet accepts a French decimal comma', (tester) async {
      final id = await create(
        tester,
        buildHabit(
          name: 'Run',
          goal: const HabitTarget(type: HabitGoalType.numeric, target: 5, unit: HabitUnits.km),
        ),
      );
      await pumpToday(tester, locale: const Locale('fr'));
      await tester.tap(find.descendant(of: find.widgetWithText(HabitRow, 'Run'), matching: find.byIcon(Icons.add)));
      await settle(tester);
      await tester.enterText(find.byType(TextField), '2,5');
      await tester.tap(find.widgetWithText(FilledButton, lookupAppLocalizations(const Locale('fr')).actionSave));
      await settle(tester);
      final log = (await logsOf(tester, id)).single;
      expect(log.kind, HabitLogKind.progress);
      expect(log.value, 2.5);
      await disposeTree(tester);
    });

    testWidgets('duration timer: start, 10 minutes later stop → one entry with its seconds', (tester) async {
      final id = await create(
        tester,
        buildHabit(
          name: 'Read',
          goal: const HabitTarget(type: HabitGoalType.duration, target: 20, unit: HabitUnits.minutes),
        ),
      );
      await pumpToday(tester);
      await tester.tap(find.byTooltip(en.habitsActionStartTimer));
      await settle(tester);
      h.clock.advance(const Duration(minutes: 10));
      await settle(tester);
      await tester.tap(find.byTooltip(en.habitsActionStopTimer));
      await settle(tester);
      final log = (await logsOf(tester, id)).single;
      expect(log.value, 10);
      expect(log.durationSeconds, 600);
      await disposeTree(tester);
    });
  });

  testWidgets('slot chips: tapping 14:00 at 13:40 records the 14:00 slot; roll-up 1/3 (T5.2.05)', (tester) async {
    final id = await create(
      tester,
      buildHabit(
        name: 'Medication',
        schedule: SchedulePreset(
          SchedulePresetKind.specificTimes,
          times: [LocalTime(8, 0), LocalTime(14, 0), LocalTime(20, 0)],
        ).toRule(weekStart: Weekday.monday),
      ),
    );
    await pumpToday(tester);
    await tester.tap(find.widgetWithText(FilterChip, '14:00'));
    await settle(tester);
    final log = (await logsOf(tester, id)).single;
    expect(log.occurrenceKey, '2026-09-22T14:00');
    expect(log.kind, HabitLogKind.done);
    expect(find.text('1/3'), findsWidgets);
    await disposeTree(tester);
  });

  testWidgets('week matrix: tapping today cycles done → not done → clear (T5.2.06)', (tester) async {
    final id = await create(tester, buildHabit(name: 'Meditate', start: d(2026, 9, 1)));
    await pumpInApp(tester, h, Scaffold(body: WeekMatrix(endDate: d(2026, 9, 22))));
    await settle(tester);
    final cell = find.bySemanticsLabel(RegExp('^Meditate, Tuesday, September 22:'));
    expect(cell, findsOneWidget);
    await tester.tap(cell);
    await settle(tester);
    expect((await logsOf(tester, id)).single.kind, HabitLogKind.done);
    await tester.tap(cell);
    await settle(tester);
    expect((await logsOf(tester, id)).single.kind, HabitLogKind.fail);
    await tester.tap(cell);
    await settle(tester);
    expect(await logsOf(tester, id), isEmpty);
    await disposeTree(tester);
  });

  testWidgets('detail screen shows streaks, rate and counts from the metrics (T5.2.07)', (tester) async {
    final id = await create(tester, buildHabit(name: 'Meditate', start: d(2026, 9, 15)));
    await tester.runAsync(() async {
      final logs = h.read(habitLogsRepositoryProvider);
      for (final day in [19, 20, 21]) {
        await logs.write(
          (tx) => HabitLogsRepository.upsertStateInTx(
            tx,
            habitId: id,
            key: '2026-09-$day',
            kind: HabitLogKind.done,
            loggedAt: DateTime.utc(2026, 9, day, 12),
            localDate: d(2026, 9, day),
            source: 'manual',
          ),
        );
      }
    });
    await pumpInApp(tester, h, HabitDetailScreen(habitId: id));
    await settle(tester);
    expect(find.text(en.habitsCurrentStreak), findsOneWidget);
    expect(find.text(en.habitsDays(3)), findsWidgets);
    expect(find.text(en.habitsCounts(3, 0, 4, 0)), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('switching views keeps the selected date (T5.2.02)', (tester) async {
    await create(tester, buildHabit(name: 'Meditate', start: d(2026, 9, 1)));
    await pumpInApp(tester, h, const HabitsScreen());
    await settle(tester);
    await tester.tap(find.byTooltip(en.habitsPrevDay));
    await settle(tester);
    final label = find.textContaining('September 21');
    expect(label, findsOneWidget);
    await tester.tap(find.text(en.habitsViewMonth));
    await settle(tester);
    await tester.tap(find.text(en.habitsViewToday));
    await settle(tester);
    expect(find.textContaining('September 21'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('note & mood prompt after check-in is optional and dismissible (T5.2.09)', (tester) async {
    final id = await create(
      tester,
      buildHabit(name: 'Journal', settings: HabitSettings.defaults.copyWith(askNoteAfterCheckIn: true)),
    );
    await pumpToday(tester);
    await tester.tap(
      find.descendant(of: find.widgetWithText(HabitRow, 'Journal'), matching: find.byType(InkResponse)).last,
    );
    await settle(tester);
    expect(find.text(en.habitsNoteMoodTitle), findsOneWidget);
    // Dismissing the prompt keeps the check-in.
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);
    expect(find.text(en.habitsNoteMoodTitle), findsNothing);
    expect((await logsOf(tester, id)).single.kind, HabitLogKind.done);
    await disposeTree(tester);
  });
}
