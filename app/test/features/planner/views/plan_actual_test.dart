import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/item_copy.dart';
import 'package:everslot/features/planner/presentation/grid/engine/plan_actual.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

// Plan vs actual (T3.7.06). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);

  final now = at(2026, 9, 23, 18);
  ActualBlock block(String task, int h1, int m1, int h2, int m2, {String? key}) => ActualBlock(
    entryId: '$task-$h1$m1',
    taskId: task,
    occurrenceKey: key,
    start: at(2026, 9, 23, h1, m1),
    end: at(2026, 9, 23, h2, m2),
  );

  group('variance', () {
    final deep = item('Deep work', at(2026, 9, 23, 9), 60, id: 'dw');

    test('on plan within the tolerance', () {
      expect(classifyVariance(deep, [block('dw', 9, 3, 10, 2)], now), {Variance.onPlan});
    });

    test('started late and overran can both apply', () {
      expect(classifyVariance(deep, [block('dw', 9, 20, 10, 30)], now), {Variance.startedLate, Variance.overran});
      expect(classifyVariance(deep, [block('dw', 9, 0, 9, 40), block('dw', 9, 45, 10, 20)], now), {
        Variance.overran,
      }, reason: 'the last block ends 20 min after the planned end');
    });

    test('not done: the planned end passed with nothing tracked and the item still open', () {
      expect(classifyVariance(deep, const [], now), {Variance.notDone});
      expect(classifyVariance(deep, const [], at(2026, 9, 23, 9, 30)), {Variance.onPlan}, reason: 'still running');
      expect(classifyVariance(copyItem(deep, status: OccurrenceStatus.done), const [], now), {Variance.onPlan});
      expect(classifyVariance(copyItem(deep, status: OccurrenceStatus.skipped), const [], now), {Variance.onPlan});
    });

    test('blocks of an occurrence and unplanned work', () {
      final standup = item('Standup', at(2026, 9, 23, 8), 15, id: 'su', recurring: true);
      final blocks = [
        block('dw', 9, 0, 10, 0),
        block('su', 8, 0, 8, 15, key: '2026-09-23T08:00'),
        block('su', 16, 0, 16, 15, key: '2026-09-22T08:00'),
        block('other', 13, 0, 14, 0),
      ];
      expect(blocksOf(standup, blocks).single.start, at(2026, 9, 23, 8));
      expect(blocksOf(deep, blocks).single.taskId, 'dw');
      expect(unplannedBlocks(blocks, [deep, standup]).map((b) => b.entryId), ['su-160', 'other-130']);
    });
  });

  testWidgets('day columns show plan and tracked blocks with variance; tapping a block opens it', (tester) async {
    final items = [
      item('Deep work', at(2026, 9, 23, 7), 60, id: 'dw'),
      item('Email', at(2026, 9, 23, 8, 15), 30, id: 'email'),
    ];
    final h = PlannerHarness.create(
      items: items,
      overrides: [
        rangeTimeEntriesProvider.overrideWith(
          (ref, r) => Stream.value([
            TimeEntry(
              id: 'e1',
              taskId: 'dw',
              startedAt: DateTime.utc(2026, 9, 23, 7, 20),
              endedAt: DateTime.utc(2026, 9, 23, 8, 30),
            ),
            TimeEntry(
              id: 'e2',
              taskId: 'gym',
              startedAt: DateTime.utc(2026, 9, 23, 10),
              endedAt: DateTime.utc(2026, 9, 23, 10, 45),
            ),
          ]),
        ),
      ],
    );
    addTearDown(h.dispose);
    await pumpPlanner(tester, h, const PlannerScreen(view: 'plan_vs_actual', date: '2026-09-23'));
    await tester.pumpAndSettle();
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Actual'), findsOneWidget);
    expect(find.byKey(const ValueKey('pva-actual-e1')), findsOneWidget);
    expect(find.text('Deep work\nStarted late · Overran'), findsOneWidget);
    expect(find.text('Email · Not done'), findsOneWidget, reason: 'Email ended at 08:45 with nothing tracked');
    expect(find.bySemanticsLabel(RegExp(r', Unplanned$')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pva-actual-e2')));
    await tester.pumpAndSettle();
    expect(h.nav.log.last, 'task gym');
  });
}
