import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/item_copy.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart' show viewExtraActionsProvider;
import 'package:everslot/features/planner/presentation/grid/engine/eisenhower.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fake_view_actions.dart';
import 'support/items.dart';
import 'support/planner_harness.dart';

// Eisenhower matrix (T3.7.09). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);
  final today = LocalDate(2026, 9, 23);
  const rules = MatrixRules();

  PlannerItem backlogItem(String title, {int priority = 0, LocalDateTime? deadline}) => PlannerItem(
    taskId: title,
    seriesId: title,
    occurrenceKey: '',
    title: title,
    startLocal: today.atStartOfDay,
    durationMinutes: 30,
    startUtc: DateTime.utc(2026, 9, 23),
    endUtc: DateTime.utc(2026, 9, 23, 0, 30),
    status: OccurrenceStatus.scheduled,
    priority: priority,
    deadlineLocal: deadline,
  );

  group('classification', () {
    test('importance by priority threshold; urgency by deadline or start within N days', () {
      expect(quadrantOf(backlogItem('A', priority: 4, deadline: at(2026, 9, 24)), rules, today), Quadrant.doNow);
      expect(quadrantOf(backlogItem('B', priority: 3), rules, today), Quadrant.schedule);
      expect(
        quadrantOf(item('C', at(2026, 9, 25, 9), 30), rules, today),
        Quadrant.delegate,
        reason: 'starts in 2 days',
      );
      expect(quadrantOf(item('D', at(2026, 9, 26, 9), 30), rules, today), Quadrant.eliminate);
      expect(
        quadrantOf(backlogItem('E', deadline: at(2026, 9, 20)), rules, today),
        Quadrant.delegate,
        reason: 'overdue',
      );
      expect(quadrantOf(backlogItem('F'), const MatrixRules(importanceThreshold: 0 + 1), today), Quadrant.eliminate);
    });

    test('rules change the boundaries', () {
      final d = item('D', at(2026, 9, 26, 9), 30, priority: 2);
      expect(quadrantOf(d, const MatrixRules(importanceThreshold: 2, urgencyDays: 3), today), Quadrant.doNow);
    });

    test('moves adjust priority and deadline', () {
      final b = backlogItem('B', priority: 1);
      final toDo = matrixMove(b, Quadrant.doNow, rules, today);
      expect(toDo.priority, 3);
      expect(toDo.deadline, at(2026, 9, 25, 23, 59));
      final urgent = backlogItem('U', priority: 4, deadline: at(2026, 9, 24));
      final toSchedule = matrixMove(urgent, Quadrant.schedule, rules, today);
      expect(toSchedule.priority, isNull);
      expect(toSchedule.clearDeadline, isTrue);
      expect(matrixMove(urgent, Quadrant.delegate, rules, today).priority, 2);
      expect(matrixMove(urgent, Quadrant.doNow, rules, today).isEmpty, isTrue);
    });
  });

  testWidgets('quadrants with items; dragging to Schedule lowers urgency; rules are editable', (tester) async {
    final extra = FakeViewActions();
    final h = PlannerHarness.create(
      items: [
        item('Report', at(2026, 9, 23, 14), 60, id: 'r', priority: 4),
        copyItem(item('Done', at(2026, 9, 23, 8), 30), status: OccurrenceStatus.done),
      ],
      overrides: [viewExtraActionsProvider.overrideWithValue(extra)],
    );
    addTearDown(h.dispose);
    h.backend.backlog.add(backlogItem('Read book', priority: 1));
    await pumpPlanner(tester, h, const PlannerScreen(view: 'matrix'), size: const Size(800, 900));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Do, 1 item'), findsOneWidget);
    expect(find.bySemanticsLabel('Eliminate, 1 item'), findsOneWidget, reason: 'backlog, low priority');
    expect(find.text('Done'), findsNothing, reason: 'closed items are left out');

    final gesture = await tester.startGesture(tester.getCenter(find.text('Read book')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey('quadrant-schedule'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(extra.calls.single, startsWith('edit Read book est=null prio=3'));

    await tester.tap(find.byKey(const Key('matrix-rules')));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('rule-urgency')), const Offset(200, 0));
    await tester.tap(find.byKey(const Key('rules-save')));
    await tester.pumpAndSettle();
    expect(h.read(plannerViewConfigProvider('matrix')).option<int>('urgencyDays', 2), greaterThan(2));
  });
}
