import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/engine/occupancy.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/items.dart';

// Weekday × hour aggregation behind the heat overlay (T3.3.23) and the load heatmap (T3.6.16).
void main() {
  final mon = LocalDate(2026, 9, 21);

  test('minutes split across hour cells and weekdays', () {
    final grid = OccupancyGrid.build(
      [item('Gym', at(2026, 9, 21, 7, 30), 90), item('Night', at(2026, 9, 22, 23, 30), 60)],
      start: mon,
      days: 7,
    );
    expect((grid.minutes(1, 7), grid.minutes(1, 8), grid.minutes(1, 9)), (30.0, 60.0, 0.0));
    expect((grid.minutes(2, 23), grid.minutes(3, 0)), (30.0, 30.0), reason: 'midnight crossing continues on Wednesday');
    expect(grid.dayMinutes(1), 90);
    expect(grid.itemsAt(1, 8).single.title, 'Gym');
  });

  test('several weeks average per week; all-day, backlog and cancelled items are ignored', () {
    final grid = OccupancyGrid.build(
      [
        item('A', at(2026, 9, 21, 10), 60),
        item('B', at(2026, 9, 28, 10), 30),
        item('Trip', at(2026, 9, 21), 1440, allDay: true),
        item('Cancelled', at(2026, 9, 21, 11), 60, status: OccurrenceStatus.cancelled),
      ],
      start: mon,
      days: 14,
    );
    expect(grid.weeks, 2);
    expect(grid.averageMinutes(1, 10), 45);
    expect(grid.load(1, 10), 0.75);
    expect(grid.minutes(1, 11), 0);
    expect(grid.maxLoad, 0.75);
  });

  test('items outside the range are clipped', () {
    final grid = OccupancyGrid.build([item('Early', at(2026, 9, 20, 23), 120)], start: mon, days: 7);
    expect(grid.minutes(7, 23), 0, reason: 'Sunday 20th is before the range');
    expect(grid.minutes(1, 0), 60);
  });

  test('tracked metric weighs by tracked time', () {
    final tracked = PlannerItem(
      taskId: 't',
      seriesId: 't',
      occurrenceKey: 'k',
      title: 'Tracked',
      startLocal: at(2026, 9, 21, 9),
      durationMinutes: 60,
      startUtc: DateTime.utc(2026, 9, 21, 9),
      endUtc: DateTime.utc(2026, 9, 21, 10),
      status: OccurrenceStatus.done,
      trackedSeconds: 30 * 60,
    );
    final grid = OccupancyGrid.build([tracked], start: mon, days: 7, metric: OccupancyMetric.tracked);
    expect(grid.minutes(1, 9), 30);
  });

  test('heat bins', () {
    expect(
      [
        for (final l in [0.0, 0.1, 0.3, 0.7, 1.0, 2.0]) heatBin(l),
      ],
      [0, 1, 2, 3, 4, 4],
    );
  });
}
