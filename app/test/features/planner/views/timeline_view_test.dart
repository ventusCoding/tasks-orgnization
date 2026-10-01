import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/engine/gantt_layout.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

// Timeline / Gantt (T3.6.14). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);

  PlannerItem series(String title, String id, LocalDateTime start, int minutes, {String? category, int priority = 0}) {
    final i = item(title, start, minutes, categoryId: category, priority: priority);
    return PlannerItem(
      taskId: '$id-${start.toIso()}',
      seriesId: id,
      occurrenceKey: i.occurrenceKey,
      title: title,
      startLocal: start,
      durationMinutes: minutes,
      startUtc: i.startUtc,
      endUtc: i.endUtc,
      status: OccurrenceStatus.scheduled,
      categoryId: category,
      priority: priority,
    );
  }

  group('layout', () {
    final monday = LocalDate(2026, 9, 21);

    test('bars are positioned by minutes × px/min; overlapping bars stack in sub-lanes', () {
      final rows = ganttRows(
        [
          series('Run', 'run', at(2026, 9, 21, 7), 60),
          series('Run', 'run', at(2026, 9, 22, 7), 60),
          series('Build', 'build', at(2026, 9, 21), 4320),
          series('Build', 'build', at(2026, 9, 22), 1440),
        ],
        start: monday,
        scale: GanttScale.days,
        groupBy: GanttGroupBy.task,
      );
      expect(rows.map((r) => r.key), ['build', 'run'], reason: 'ordered by first start');
      final build = rows.first;
      expect(build.lanes, 2);
      expect(build.bars[0].x, 0);
      expect(build.bars[0].width, closeTo(3 * 96, 1e-9));
      expect(build.bars[1].lane, 1, reason: 'overlaps the 3-day bar');
      final run = rows.last;
      expect(run.lanes, 1);
      expect(run.bars[1].x, closeTo(96 + 7 * 60 * 96 / 1440, 1e-9));
      expect(run.bars[0].width, ganttMinBarWidth, reason: '1 h = 4 px at the day scale');
    });

    test('short bars keep a minimum width', () {
      final rows = ganttRows(
        [series('Pill', 'p', at(2026, 9, 21, 8), 5)],
        start: monday,
        scale: GanttScale.weeks,
        groupBy: GanttGroupBy.task,
      );
      expect(rows.single.bars.single.width, ganttMinBarWidth);
    });

    test('group by category (category order, none last) and priority (urgent first)', () {
      final items = [
        series('A', 'a', at(2026, 9, 21, 8), 30, category: 'work', priority: 1),
        series('B', 'b', at(2026, 9, 21, 9), 30, priority: 4),
        series('C', 'c', at(2026, 9, 21, 10), 30, category: 'home', priority: 1),
      ];
      final byCategory = ganttRows(
        items,
        start: monday,
        scale: GanttScale.days,
        groupBy: GanttGroupBy.category,
        categoryOrder: ['home', 'work'],
      );
      expect(byCategory.map((r) => r.key), ['home', 'work', '']);
      final byPriority = ganttRows(items, start: monday, scale: GanttScale.days, groupBy: GanttGroupBy.priority);
      expect(byPriority.map((r) => r.key), ['4', '1']);
      expect(byPriority.last.bars, hasLength(2));
    });

    test('drag snapping per scale; resize keeps at least one step', () {
      final i = series('Run', 'run', at(2026, 9, 21, 7), 60);
      expect(ganttMovedStart(i, 20, GanttScale.hours), at(2026, 9, 21, 7, 15), reason: '20 min → 15');
      expect(ganttMovedStart(i, 96, GanttScale.days), at(2026, 9, 22, 7));
      expect(ganttMovedStart(i, -48, GanttScale.days), at(2026, 9, 20, 19), reason: '−48 px = −12 h');
      expect(ganttResizedDuration(i, 50, GanttScale.hours), 105);
      expect(ganttResizedDuration(i, -500, GanttScale.hours), 15);
    });

    test('pages, ticks and scale steps', () {
      expect(GanttScale.days.pageStart(LocalDate(2026, 9, 23), Weekday.monday), monday);
      expect(GanttScale.months.pageStart(LocalDate(2026, 9, 23), Weekday.monday), LocalDate(2026, 9, 1));
      expect(ganttTicks(monday, GanttScale.days, Weekday.monday), hasLength(21));
      final months = ganttTicks(LocalDate(2026, 9, 1), GanttScale.months, Weekday.monday);
      expect(months, hasLength(12));
      expect(months.last.$2, at(2027, 8, 1));
      expect(GanttScale.days.step(1), GanttScale.hours);
      expect(GanttScale.hours.step(1), GanttScale.hours);
      expect(GanttScale.days.step(-1), GanttScale.weeks);
      expect(GanttScale.parse('nope'), GanttScale.days);
    });
  });

  group('view', () {
    Future<PlannerHarness> pump(WidgetTester tester, List<PlannerItem> items, {String scale = 'days'}) async {
      final h = PlannerHarness.create(items: items);
      addTearDown(h.dispose);
      h.read(plannerViewConfigProvider('timeline').notifier).change((c) => c.withOption('scale', scale));
      await pumpPlanner(tester, h, const PlannerScreen(view: 'timeline', date: '2026-09-21'));
      await tester.pumpAndSettle();
      return h;
    }

    final items = [
      series('Launch', 'launch', at(2026, 9, 22, 9), 1440),
      series('Run', 'run', at(2026, 9, 23, 7), 60),
    ];

    testWidgets('rows per series with the axis and today line; tap opens the task', (tester) async {
      final h = await pump(tester, items);
      expect(find.text('Sep 21 – Oct 11, 2026'), findsOneWidget);
      expect(find.text('Launch'), findsWidgets);
      expect(find.byKey(const Key('timeline-today')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('timeline-bar-launch-2026-09-22T09:00|2026-09-22T09:00')));
      await tester.pumpAndSettle();
      expect(h.nav.log.last, 'task launch-2026-09-22T09:00 2026-09-22T09:00');
    });

    testWidgets('dragging a bar moves it by whole hours at the day scale', (tester) async {
      final h = await pump(tester, items);
      final bar = find.byKey(const ValueKey('timeline-bar-launch-2026-09-22T09:00|2026-09-22T09:00'));
      await tester.drag(bar, const Offset(96 + 20, 0)); // one day + slop
      await tester.pumpAndSettle();
      expect(h.backend.calls.single, startsWith('reschedule Launch 2026-09-23T'));
    });

    testWidgets('dragging the end edge resizes', (tester) async {
      final h = await pump(tester, items);
      await tester.drag(
        find.byKey(const ValueKey('timeline-resize-launch-2026-09-22T09:00|2026-09-22T09:00')),
        const Offset(96 + 20, 0),
      );
      await tester.pumpAndSettle();
      expect(h.backend.calls.single, startsWith('reschedule Launch 2026-09-22T09:00 '));
      final minutes = int.parse(h.backend.calls.single.split(' ')[3]);
      expect(minutes, greaterThan(1440));
    });

    testWidgets('the scale menu changes the axis; group by priority relabels rows', (tester) async {
      final h = await pump(tester, items);
      await tester.tap(find.byKey(const Key('timeline-scale')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weeks').last);
      await tester.pumpAndSettle();
      expect(h.read(plannerViewConfigProvider('timeline')).option<String>('scale', ''), 'weeks');
      await tester.tap(find.byKey(const Key('timeline-group')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Priority').last);
      await tester.pumpAndSettle();
      expect(find.text('No priority'), findsOneWidget, reason: 'priority 0 row label');
    });
  });
}
