import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/view_config/day_window.dart';
import 'package:everslot/features/planner/presentation/grid/engine/free_slots.dart';
import 'package:everslot/features/planner/presentation/grid/engine/plan_summary.dart';
import 'package:everslot_metrics/everslot_metrics.dart' as m;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/items.dart';

// Week summary footer (T3.4.17) and day summary header (T3.5.12) equal the Insights metric
// registry ([6.3]) for the same range: capacity report (planned), plan snapshot (completion) and
// free time = capacity − planned inside work hours.
void main() {
  final mon = LocalDate(2026, 9, 21);
  final week = DayRange(mon, 7);

  m.PlannerOccurrenceFact fact(PlannerItem i) => m.PlannerOccurrenceFact(
    i.taskId,
    i.occurrenceKey,
    seriesId: i.seriesId,
    taskCreatedAt: DateTime.utc(2026),
    plannedStartLocal: i.startLocal,
    plannedDurationMinutes: i.durationMinutes,
    plannedStart: i.startUtc,
    plannedEnd: i.endUtc,
    isAllDay: i.allDay,
    status: m.PlannerOccurrenceStatus.values.byName(i.status.name),
    trackingMode: m.TrackingMode.values.byName(i.trackingMode.name),
    doneAt: i.isDone ? i.endUtc : null,
    // The summary shows the current plan: a cancelled occurrence is out of it, like one cancelled
    // before the period in the registry's snapshot.
    cancelledAt: i.status == OccurrenceStatus.cancelled ? DateTime.utc(2026, 9, 1) : null,
    categoryId: i.categoryId,
  );

  final items = [
    item('Gym', at(2026, 9, 21, 7), 90, status: OccurrenceStatus.done, categoryId: 'health'),
    item('Deep work', at(2026, 9, 21, 9), 120, categoryId: 'work'),
    item('Call', at(2026, 9, 22, 10), 30, status: OccurrenceStatus.skipped, categoryId: 'work'),
    item('Standup', at(2026, 9, 23, 9), 15, trackingMode: TrackingMode.event, categoryId: 'work'),
    item('Cancelled', at(2026, 9, 24, 14), 60, status: OccurrenceStatus.cancelled, categoryId: 'work'),
    item('Review', at(2026, 9, 25, 16), 45, status: OccurrenceStatus.done),
    item('Trip', at(2026, 9, 26), 1440, allDay: true),
    item('Next week', at(2026, 9, 28, 9), 60),
  ];

  test('week summary: planned, completion and top categories match the registry', () {
    final s = PlanSummary.of(items, week);
    final facts = [for (final i in items) fact(i)];
    const clock = m.FixedOffsetClock();
    final period = m.DateRange(mon, mon.plusDays(6));
    final capacity = m.capacityReport(facts, range: period, clock: clock);
    final snapshot = m.planSnapshot(facts, period: period, bounds: const m.DayBoundaries(clock), now: DateTime.utc(2026, 10, 5));
    expect(s.plannedMinutes, capacity.plannedMinutes.round());
    expect(s.completion, closeTo(snapshot.completionRate.valueOrNull!, 1e-9));
    expect((s.done, s.total), (2, 5), reason: 'events and cancelled items are not counted; all-day checks are');
    expect(s.topCategories, [('work', 165), ('health', 90), (null, 45)]);
  });

  test('tracked minutes add up the tracked time of the range', () {
    final tracked = [
      for (final (i, secs) in [(items[0], 3600), (items[1], 1800), (items[7], 999)])
        PlannerItem(
          taskId: i.taskId,
          seriesId: i.seriesId,
          occurrenceKey: i.occurrenceKey,
          title: i.title,
          startLocal: i.startLocal,
          durationMinutes: i.durationMinutes,
          startUtc: i.startUtc,
          endUtc: i.endUtc,
          status: i.status,
          trackedSeconds: secs,
        ),
    ];
    expect(PlanSummary.of(tracked, week).trackedMinutes, 90);
  });

  test('day summary: free time inside work hours = capacity − planned (registry capacity day)', () {
    final day = DayRange(mon, 1);
    const window = DayWindow(9 * 60, 17 * 60);
    final s = PlanSummary.of(items, day, work: const FreeSlotOptions(window: window));
    final facts = [for (final i in items) fact(i)];
    final capacity = m.capacityReport(facts, range: m.DateRange(mon, mon), clock: const m.FixedOffsetClock());
    final monday = capacity.days.single;
    expect(s.freeMinutes, (monday.capacityMinutes - monday.plannedClippedMinutes).round());
    expect(s.plannedMinutes, monday.plannedMinutes.round());
    expect((s.done, s.total), (1, 2));
  });
}
