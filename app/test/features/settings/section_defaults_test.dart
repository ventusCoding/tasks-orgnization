import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot/features/planner/presentation/grid/data/work_settings.dart';
import 'package:everslot/features/settings/application/settings_providers.dart';
import 'package:everslot/features/settings/domain/settings_models.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../auth/support/widget_helpers.dart';
import 'support/settings_app.dart';

Future<void> _choose(WidgetTester tester, String tileKey, String choiceKey) async {
  await dragUntilFound(tester, find.byKey(ValueKey(tileKey)), const Offset(0, -80));
  await tester.tap(find.byKey(ValueKey(tileKey)));
  await pumpUi(tester);
  await tester.tap(find.byKey(ValueKey(choiceKey)));
  await settle(tester);
}

Future<void> _tapIn(WidgetTester tester, String tileKey, String label) async {
  await dragUntilFound(tester, find.byKey(ValueKey(tileKey)), const Offset(0, -80));
  await tester.tap(find.descendant(of: find.byKey(ValueKey(tileKey)), matching: find.text(label)));
  await settle(tester);
}

void main() {
  testWidgets('Plan defaults are read by the planner, the grid and the stats engine', (tester) async {
    final h = TestHarness.create();
    // Keys this page doesn't know are kept.
    await tester.runAsync(() => h.read(settingsRepositoryProvider).update(SettingsNs.planner, {'overlapHint': false, 'future': 1}));
    await pumpSettingsApp(tester, h, initial: '/settings/plan');
    await settle(tester);

    await _tapIn(tester, 'plan-tracking', 'Timer');
    await _choose(tester, 'plan-grace', 'choice-30');
    await dragUntilFound(tester, find.byKey(const ValueKey('plan-day-5')), const Offset(0, -80));
    await tester.tap(find.byKey(const ValueKey('plan-day-5')));
    await settle(tester);
    await _tapIn(tester, 'plan-rollover', 'Ask me');
    await _tapIn(tester, 'plan-actual-time', 'Always');

    final planner = h.read(plannerSettingsProvider);
    expect(planner.defaultTrackingMode, TrackingMode.timer);
    expect(planner.missedGraceMinutes, 30);
    expect(planner.rollOverIncomplete, RollOverPolicy.ask);
    expect(planner.askActualTimeOnDone, AskActualTimeOnDone.always);
    expect(planner.overlapHint, isFalse, reason: 'unknown-to-settings key preserved');
    expect(h.read(plannerWorkSettingsProvider).days, {1, 2, 3, 4});
    final stats = h.read(statsSettingsProvider);
    expect(stats.missedGraceMinutes, 30);
    expect(stats.workDays, {1, 2, 3, 4});
    final raw = await tester.runAsync(() => h.read(settingsRepositoryProvider).read(SettingsNs.planner));
    expect(raw!['future'], 1);
    expect(raw['workHours'], {'start': '09:00', 'end': '17:00'});
    await finish(tester, h);
  });

  testWidgets('the Plan tab default view is one of the saved views', (tester) async {
    final h = TestHarness.create();
    await tester.runAsync(() => h.read(plannerDefaultViewsProvider.future));
    await pumpSettingsApp(tester, h, initial: '/settings/plan');
    await settle(tester);
    final views = (await tester.runAsync(() => h.read(savedViewsRepositoryProvider).all()))!;
    expect(views.length, greaterThan(1));
    final target = views.firstWhere((v) => !v.isDefault);
    await _choose(tester, 'plan-default-view', 'choice-${target.id}');
    final after = (await tester.runAsync(() => h.read(savedViewsRepositoryProvider).byId(target.id)))!;
    expect(after.isDefault, isTrue);
    expect(find.descendant(of: find.byKey(const ValueKey('plan-default-view')), matching: find.textContaining(target.name)), findsOneWidget);
    await finish(tester, h);
  });

  testWidgets('Lists defaults', (tester) async {
    final h = TestHarness.create();
    await pumpSettingsApp(tester, h, initial: '/settings/lists');
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('lists-reason-ongoing')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('lists-reason-waiting')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('lists-auto-complete')));
    await settle(tester);
    await _tapIn(tester, 'lists-progress', 'Direct sub-items');
    final s = h.read(checklistsDefaultsProvider);
    expect(s.requireReasonFor, {'ongoing', 'blocked'});
    expect(s.autoCompleteParents, isFalse);
    expect(s.progressMode, ProgressModePreference.children);
    await finish(tester, h);
  });

  testWidgets('Habits defaults', (tester) async {
    final h = TestHarness.create();
    await pumpSettingsApp(tester, h, initial: '/settings/habits');
    await settle(tester);
    await _tapIn(tester, 'habits-skip', 'Break the streak');
    await tester.tap(find.byKey(const ValueKey('habits-freezes-plus')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('habits-freezes-plus')));
    await settle(tester);
    expect(h.read(habitsDefaultsProvider).defaultSkipPolicy, SkipPolicy.breaks);
    expect(h.read(habitsDefaultsProvider).defaultFreezesPerMonth, 2);
    expect(find.text('Day starts at 00:00'), findsOneWidget);
    await finish(tester, h);
  });

  testWidgets('Insights defaults reach the stats engine; unknown period keys are kept', (tester) async {
    final h = TestHarness.create();
    await tester.runAsync(() => h.read(settingsRepositoryProvider).update(SettingsNs.stats, {'defaultPeriod': 'rolling:90'}));
    await pumpSettingsApp(tester, h, initial: '/settings/insights');
    await settle(tester);
    expect(find.text('Last 90 days'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('insights-compare')));
    await settle(tester);
    expect(h.read(statsSettingsProvider).defaultPeriod, 'rolling:90', reason: 'another key edited, period untouched');
    expect(h.read(statsSettingsProvider).compareWithPrevious, isFalse);
    await _choose(tester, 'insights-period', 'choice-thisMonth');
    await _choose(tester, 'insights-week-start', 'choice-6');
    expect(h.read(statsSettingsProvider).defaultPeriod, 'thisMonth');
    expect(h.read(statsSettingsProvider).weekStartOverride?.iso, 6);
    await finish(tester, h);
  });
}
