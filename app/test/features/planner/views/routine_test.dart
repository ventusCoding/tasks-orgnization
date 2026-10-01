import 'package:everslot/features/planner/application/view_config/checklist_steps.dart';
import 'package:everslot/features/planner/application/view_config/screen_awake.dart';
import 'package:everslot/features/planner/presentation/grid/engine/routine.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

class _FakeChecklistActions implements ChecklistStepActions {
  final calls = <String>[];

  @override
  Future<void> setDone(String checklistId, String itemId, {required bool done}) async =>
      calls.add('done $checklistId $itemId $done');

  @override
  Future<void> completeMany(String checklistId, Iterable<String> itemIds) async =>
      calls.add('many $checklistId ${itemIds.join(',')}');
}

class _NoAwake implements ScreenAwake {
  @override
  Future<void> keepOn({required bool on}) async {}
}

// Routine player (T3.7.07). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);

  group('state machine', () {
    final steps = [
      const RoutineStep(id: 'a', title: 'Stretch', minutes: 5),
      const RoutineStep(id: 'b', title: 'Shower', minutes: 10),
      const RoutineStep(id: 'c', title: 'Coffee', minutes: 5),
    ];

    test('durations: estimates kept, the rest shares the task time', () {
      expect(stepDurations([5, null, null], 25), [5, 10, 10]);
      expect(stepDurations([null, null, null], 30), [10, 10, 10]);
      expect(stepDurations([30, null], 20), [30, 1], reason: 'at least one minute');
      expect(stepDurations(const [], 30), isEmpty);
    });

    test('ticks count down only while running; auto-advance carries the leftover', () {
      var s = RoutineMachine.start(RoutineState(steps: steps));
      s = RoutineMachine.tick(s, const Duration(minutes: 3), autoAdvance: true);
      expect(s.remaining, const Duration(minutes: 2));
      s = RoutineMachine.pause(s);
      s = RoutineMachine.tick(s, const Duration(minutes: 30), autoAdvance: true);
      expect(s.index, 0, reason: 'paused');
      s = RoutineMachine.resume(s);
      s = RoutineMachine.tick(s, const Duration(minutes: 3), autoAdvance: true);
      expect(s.index, 1);
      expect(s.elapsed, const Duration(minutes: 1));
      expect(s.outcomes, [StepOutcome.done, StepOutcome.pending, StepOutcome.pending]);
    });

    test('without auto-advance a step runs over; skip and complete move on; the end finishes', () {
      var s = RoutineMachine.start(RoutineState(steps: steps));
      s = RoutineMachine.tick(s, const Duration(minutes: 8), autoAdvance: false);
      expect(s.index, 0);
      expect(s.remaining, const Duration(minutes: -3));
      s = RoutineMachine.skip(s);
      s = RoutineMachine.complete(s);
      expect(s.index, 2);
      s = RoutineMachine.tick(s, const Duration(minutes: 6), autoAdvance: true);
      expect(s.finished, isTrue);
      expect(s.running, isFalse);
      expect(s.outcomes, [StepOutcome.skipped, StepOutcome.done, StepOutcome.done]);
      expect(s.doneCount, 2);
      expect(RoutineMachine.complete(s), same(s), reason: 'no-op once finished');
    });

    test('consecutive blocks: back-to-back items within the gap, overlaps skipped', () {
      final items = [
        item('Wake up', at(2026, 9, 23, 7), 10, id: 'w'),
        item('Run', at(2026, 9, 23, 7, 12), 30, id: 'r'),
        item('Overlap', at(2026, 9, 23, 7, 20), 10, id: 'o'),
        item('Breakfast', at(2026, 9, 23, 7, 45), 20, id: 'b'),
        item('Work', at(2026, 9, 23, 9), 60, id: 'k'),
      ];
      expect(consecutiveBlock(items.first, items).map((i) => i.title), ['Wake up', 'Run', 'Breakfast']);
      expect(consecutiveBlock(items.last, items).map((i) => i.title), ['Work']);
    });
  });

  testWidgets('a checklist routine plays step by step and the summary completes items and the task', (tester) async {
    final actions = _FakeChecklistActions();
    final h = PlannerHarness.create(
      items: [item('Morning', at(2026, 9, 23, 10), 20, id: 'm', linkedChecklistId: 'cl')],
      overrides: [
        checklistStepsProvider.overrideWith(
          (ref, q) => const [
            ChecklistStep(id: 's1', text: 'Stretch', done: false, estimateMinutes: 5),
            ChecklistStep(id: 's2', text: 'Meditate', done: false),
            ChecklistStep(id: 's3', text: 'Old', done: true),
          ],
        ),
        checklistStepActionsProvider.overrideWithValue(actions),
        screenAwakeProvider.overrideWithValue(_NoAwake()),
      ],
    );
    addTearDown(h.dispose);
    await pumpPlanner(tester, h, const PlannerScreen(view: 'routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start routine'));
    await tester.pump();
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.byKey(const Key('routine-step')), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);

    h.clock.advance(const Duration(minutes: 5, seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Step 2 of 2'), findsOneWidget, reason: 'auto-advance');
    expect(tester.widget<Text>(find.byKey(const Key('routine-step'))).data, 'Meditate');

    await tester.tap(find.byKey(const Key('routine-skip')));
    await tester.pump();
    expect(find.text('1 of 2 steps done'), findsOneWidget);
    await tester.tap(find.byKey(const Key('routine-finish')));
    await tester.pumpAndSettle();
    expect(actions.calls, ['many cl s1']);
    expect(h.backend.calls, ['status Morning done']);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a block of consecutive tasks marks done and skipped steps', (tester) async {
    final h = PlannerHarness.create(
      items: [
        item('Wake', at(2026, 9, 23, 10), 10, id: 'w'),
        item('Run', at(2026, 9, 23, 10, 10), 30, id: 'r'),
      ],
      overrides: [screenAwakeProvider.overrideWithValue(_NoAwake())],
    );
    addTearDown(h.dispose);
    await pumpPlanner(tester, h, const PlannerScreen(view: 'routine'));
    await tester.pumpAndSettle();
    expect(find.text('Wake → Run'), findsOneWidget);
    await tester.tap(find.text('Start routine'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('routine-done')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('routine-skip')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('routine-finish')));
    await tester.pumpAndSettle();
    expect(h.backend.calls, ['status Wake done', 'status Run skipped']);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('no routine today: empty state', (tester) async {
    final h = PlannerHarness.create(items: [item('Lone', at(2026, 9, 23, 15), 30)]);
    addTearDown(h.dispose);
    await pumpPlanner(tester, h, const PlannerScreen(view: 'routine'));
    await tester.pumpAndSettle();
    expect(find.text('No routine block today'), findsOneWidget);
  });
}
