import 'package:decimal/decimal.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot/features/habits/presentation/habit_editor_screen.dart';
import 'package:everslot/features/habits/presentation/quit_dashboard_screen.dart';
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

  void harness(DateTime now) =>
      h = TestHarness.create(now: now, overrides: [inboxUnreadCountProvider.overrideWith((ref) => Stream.value(0))]);
  tearDown(() => h.dispose());

  Future<QuitHabit> createTracker(WidgetTester tester, {bool pledge = true, bool autoSuccess = true}) async {
    final tracker = QuitHabit(
      id: Ids.v7(),
      name: 'Stop smoking',
      startDate: d(2026, 9, 15),
      sortKey: '',
      mode: QuitMode.abstain,
      quitStartedAt: DateTime.utc(2026, 9, 15, 8),
      substance: QuitSubstance.cigarettes,
      baselinePerDay: 10,
      unitCost: Decimal.parse('0.5'),
      currency: 'EUR',
      unit: HabitUnits.cigarettes,
      autoSuccess: autoSuccess,
      settings: HabitSettings.defaults.copyWith(
        pledge: PledgeSettings(enabled: pledge, morning: LocalTime(8, 0), evening: LocalTime(21, 0)),
      ),
    );
    await tester.runAsync(() => h.read(habitsRepositoryProvider).create(tracker));
    return tracker;
  }

  Future<List<HabitLogEntry>> logsOf(WidgetTester tester, String id) async =>
      (await tester.runAsync(() => h.read(habitLogsRepositoryProvider).forHabit(id)))!;

  Future<void> scrollTo(WidgetTester tester, Finder f) =>
      tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);

  testWidgets('morning pledge: one row per day with its streak (T5.3.13)', (tester) async {
    harness(DateTime.utc(2026, 9, 22, 8));
    final tracker = await createTracker(tester);
    await pumpInApp(tester, h, QuitDashboardScreen(habitId: tracker.id));
    await settle(tester);
    await scrollTo(tester, find.text(en.quitPledgeAction));
    expect(find.text(en.quitReviewQuestion), findsNothing, reason: 'before the evening review time');
    await tester.tap(find.text(en.quitPledgeAction));
    await settle(tester);
    final pledge = (await logsOf(tester, tracker.id)).single;
    expect(pledge.kind, HabitLogKind.pledge);
    expect(pledge.id, Ids.habitPledge(tracker.id, '2026-09-22'));
    expect(find.text(en.quitPledged), findsOneWidget);
    expect(find.text(en.quitPledgeStreak(1)), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('evening review: yes marks the day clean, no opens the relapse flow', (tester) async {
    harness(DateTime.utc(2026, 9, 22, 21, 30));
    final tracker = await createTracker(tester);
    await pumpInApp(tester, h, QuitDashboardScreen(habitId: tracker.id));
    await settle(tester);
    await scrollTo(tester, find.text(en.quitReviewQuestion));
    await tester.tap(find.widgetWithText(TextButton, en.quitNo));
    await settle(tester);
    expect(find.text(en.quitRelapseTitle), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);

    await scrollTo(tester, find.text(en.quitReviewQuestion));
    await tester.tap(find.widgetWithText(TextButton, en.quitYes));
    await settle(tester);
    final clean = (await logsOf(tester, tracker.id)).single;
    expect((clean.kind, clean.localDate, clean.occurrenceKey), (HabitLogKind.clean, d(2026, 9, 22), '2026-09-22'));
    expect(find.text(en.quitReviewedClean), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('explicit mode asks about an unconfirmed yesterday', (tester) async {
    harness(DateTime.utc(2026, 9, 22, 8));
    final tracker = await createTracker(tester, pledge: false, autoSuccess: false);
    await pumpInApp(tester, h, QuitDashboardScreen(habitId: tracker.id));
    await settle(tester);
    await scrollTo(tester, find.text(en.quitReviewYesterdayQuestion));
    final row = find.ancestor(of: find.text(en.quitReviewYesterdayQuestion), matching: find.byType(Row));
    await tester.tap(find.descendant(of: row, matching: find.widgetWithText(TextButton, en.quitYes)));
    await settle(tester);
    final clean = (await logsOf(tester, tracker.id)).single;
    expect((clean.kind, clean.localDate), (HabitLogKind.clean, d(2026, 9, 21)));
    expect(find.text(en.quitReviewYesterdayQuestion), findsNothing);
    await disposeTree(tester);
  });

  testWidgets('the quit editor turns the ritual on with default times', (tester) async {
    harness(DateTime.utc(2026, 9, 22, 8));
    final tracker = await createTracker(tester, pledge: false);
    await pumpInApp(tester, h, HabitEditorScreen(habitId: tracker.id));
    await settle(tester);
    final toggle = find.text(en.quitRitualEnable);
    await scrollTo(tester, toggle);
    await tester.tap(toggle);
    await tester.pump();
    expect(find.text(en.quitPledgeMorning), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, en.actionSave));
    await settle(tester);
    final saved = (await tester.runAsync(() => h.read(habitsRepositoryProvider).byId(tracker.id)))! as QuitHabit;
    expect(saved.settings.pledge, PledgeSettings(enabled: true, morning: LocalTime(8, 0), evening: LocalTime(21, 0)));
    await disposeTree(tester);
  });
}
