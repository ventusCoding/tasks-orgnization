import 'package:decimal/decimal.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/presentation/quit/milestone_timeline.dart';
import 'package:everslot/features/habits/presentation/quit_dashboard_screen.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show QuitMilestone;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../support/habit_fixtures.dart';

void main() {
  late TestHarness h;
  final en = lookupAppLocalizations(const Locale('en'));
  setUp(
    () => h = TestHarness.create(
      now: DateTime.utc(2026, 9, 22, 10),
      overrides: [inboxUnreadCountProvider.overrideWith((ref) => Stream.value(0))],
    ),
  );
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester, {int rounds = 8}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  /// Quit exactly 3 days (72 h) before now.
  Future<QuitHabit> createTracker(WidgetTester tester, {QuitSubstance substance = QuitSubstance.cigarettes}) async {
    final tracker = QuitHabit(
      id: Ids.v7(),
      name: 'Stop',
      startDate: d(2026, 9, 19),
      sortKey: '',
      mode: QuitMode.abstain,
      quitStartedAt: DateTime.utc(2026, 9, 19, 10),
      substance: substance,
      baselinePerDay: 10,
      unitCost: Decimal.parse('0.5'),
      currency: 'EUR',
      unit: HabitUnits.cigarettes,
    );
    await tester.runAsync(() => h.read(habitsRepositoryProvider).create(tracker));
    return tracker;
  }

  Finder scrollable() => find.byType(Scrollable).first;

  testWidgets('smoking: reached milestones with dates, the next one, sourced health rows, disclaimer', (tester) async {
    final tracker = await createTracker(tester);
    await pumpInApp(tester, h, QuitMilestonesScreen(habitId: tracker.id));
    await settle(tester);
    // Clock-restart note (from the content) and clean-time milestones.
    expect(find.textContaining('restarts after a lapse'), findsOneWidget);
    expect(find.textContaining(en.quitMilestoneDays(3)), findsOneWidget, reason: '3 days reached (chip)');
    expect(find.text(en.quitMilestoneDays(7)), findsOneWidget, reason: 'next milestone');
    expect(find.text(en.quitNextMilestone), findsOneWidget);

    final disclaimer = find.textContaining('Not medical advice');
    await tester.scrollUntilVisible(disclaimer, 300, scrollable: scrollable());
    expect(disclaimer, findsOneWidget);
    expect(find.text('Heart rate and blood pressure drop'), findsOneWidget);
    expect(find.textContaining('Reached'), findsWidgets);

    final circulation = find.text('Circulation and lung function improve');
    await tester.scrollUntilVisible(circulation, 300, scrollable: scrollable());
    expect(find.text('2–12 weeks (WHO, NHS)'), findsOneWidget, reason: 'range note');
    expect(find.widgetWithText(TextButton, 'WHO'), findsWidgets, reason: 'sources');
    await disposeTree(tester);
  });

  testWidgets('other substances show clean-time milestones only', (tester) async {
    final tracker = await createTracker(tester, substance: QuitSubstance.alcohol);
    await pumpInApp(tester, h, QuitMilestonesScreen(habitId: tracker.id));
    await settle(tester);
    expect(find.text(en.quitMilestonesClockNote), findsOneWidget);
    expect(find.text(en.quitHealthTitle), findsNothing);
    expect(find.textContaining('Not medical advice'), findsNothing);
    await disposeTree(tester);
  });

  testWidgets('a lapse restarts the milestone clock', (tester) async {
    final tracker = await createTracker(tester);
    await tester.runAsync(() => h.read(quitServiceProvider).logRelapse(tracker));
    await pumpInApp(tester, h, QuitMilestonesScreen(habitId: tracker.id));
    await settle(tester);
    expect(find.text(en.quitMilestonesReached), findsNothing);
    expect(find.text(en.quitMilestoneDays(1)), findsOneWidget, reason: 'the next milestone is 1 day again');
    await disposeTree(tester);
  });

  testWidgets('Arabic timeline renders right-to-left', (tester) async {
    final tracker = await createTracker(tester);
    await pumpInApp(tester, h, QuitMilestonesScreen(habitId: tracker.id), locale: const Locale('ar'));
    await settle(tester);
    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(find.text(ar.quitMilestonesTitle), findsOneWidget);
    expect(find.text('انخفاض معدل ضربات القلب وضغط الدم'), findsNothing, reason: 'below the fold until scrolled');
    expect(tester.takeException(), isNull);
    await disposeTree(tester);
  });

  testWidgets('the dashboard next-milestone card opens the timeline', (tester) async {
    final tracker = await createTracker(tester);
    await pumpInApp(tester, h, QuitDashboardScreen(habitId: tracker.id));
    await settle(tester);
    final card = find.text(en.quitNextMilestone);
    await tester.scrollUntilVisible(card, 200, scrollable: scrollable());
    await tester.tap(card);
    await settle(tester);
    expect(find.byType(QuitMilestonesScreen), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('offsets read naturally: days, weeks, months, years and ranges', (tester) async {
    late BuildContext ctx;
    await pumpInApp(
      tester,
      h,
      Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox();
        },
      ),
    );
    expect(milestoneOffset(ctx, const Duration(days: 3)), en.habitsDays(3));
    expect(milestoneOffset(ctx, const Duration(days: 14)), en.quitOffsetWeeks(2));
    expect(milestoneOffset(ctx, const Duration(days: 30)), en.quitOffsetMonths(1));
    expect(milestoneOffset(ctx, const Duration(days: 3650)), en.quitOffsetYears(10));
    expect(
      milestoneWhen(ctx, const QuitMilestone('c', tMin: Duration(days: 14), tMax: Duration(days: 84))),
      en.quitOffsetRange(en.quitOffsetWeeks(2), en.quitOffsetWeeks(12)),
    );
  });
}
