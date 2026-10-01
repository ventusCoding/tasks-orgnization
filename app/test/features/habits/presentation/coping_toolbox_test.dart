import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/quit/coping_toolbox.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
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

  Future<QuitHabit> createTracker(WidgetTester tester) async {
    final tracker = QuitHabit(
      id: Ids.v7(),
      name: 'Stop smoking',
      startDate: d(2026, 9, 1),
      sortKey: '',
      mode: QuitMode.abstain,
      quitStartedAt: DateTime.utc(2026, 9, 1),
      substance: QuitSubstance.cigarettes,
      baselinePerDay: 10,
      unit: HabitUnits.cigarettes,
      motivation: 'For my kids',
    );
    await tester.runAsync(() => h.read(habitsRepositoryProvider).create(tracker));
    return tracker;
  }

  testWidgets('finishing the 3-minute timer logs the craving with its duration and resisted flag in one step', (
    tester,
  ) async {
    final tracker = await createTracker(tester);
    await pumpInApp(tester, h, CopingToolboxScreen(habitId: tracker.id));
    await settle(tester);
    expect(find.text('For my kids'), findsOneWidget, reason: 'motivation card');
    await tester.tap(find.text(en.quitToolboxStart));
    await settle(tester);
    expect(find.text('00:03:00'), findsOneWidget);

    h.clock.advance(const Duration(minutes: 3, seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(find.text(en.quitToolboxDone), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.quitYes));
    await settle(tester);

    final craving = (await tester.runAsync(() => h.read(habitLogsRepositoryProvider).forHabit(tracker.id)))!.single;
    expect((craving.kind, craving.durationSeconds, craving.resisted), (HabitLogKind.craving, 180, true));
    expect(craving.loggedAt, DateTime.utc(2026, 9, 22, 10), reason: 'logged at the start of the craving');
    expect(find.text(en.quitToolboxStart), findsOneWidget, reason: 'the timer resets');
    await disposeTree(tester);
  });

  testWidgets('stopping early records the elapsed time', (tester) async {
    final tracker = await createTracker(tester);
    await pumpInApp(tester, h, CopingToolboxScreen(habitId: tracker.id));
    await settle(tester);
    await tester.tap(find.text(en.quitToolboxStart));
    await settle(tester);
    h.clock.advance(const Duration(seconds: 75));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text(en.quitToolboxThrough));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, en.quitNotSure));
    await settle(tester);
    final craving = (await tester.runAsync(() => h.read(habitLogsRepositoryProvider).forHabit(tracker.id)))!.single;
    expect((craving.durationSeconds, craving.resisted), (75, null));
    await disposeTree(tester);
  });

  testWidgets('breathing paces the phases; with reduce motion only the text changes', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final tracker = await createTracker(tester);
    await pumpInApp(tester, h, CopingToolboxScreen(habitId: tracker.id));
    await settle(tester);
    final start = find.text(en.quitBreathingStart);
    await tester.scrollUntilVisible(start, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(start);
    await settle(tester);
    expect(find.text(en.quitBreathPhase(en.quitBreathIn, 4)), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNothing, reason: 'no growing circle with reduce motion');
    h.clock.advance(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(en.quitBreathPhase(en.quitBreathHold, 3)), findsOneWidget);
    await tester.tap(find.text(en.quitBreathingStop));
    await settle(tester);
    await disposeTree(tester);
  });
}
