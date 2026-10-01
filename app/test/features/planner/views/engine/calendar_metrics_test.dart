import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/engine/calendar_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/items.dart';

// Per-day metrics of the calendar heat views (T3.6.10 year, T3.6.12 quarter): metric bins.
void main() {
  final d1 = LocalDate(2026, 9, 21);
  final d2 = LocalDate(2026, 9, 22);

  group('dayMetric', () {
    final items = [
      item('A', at(2026, 9, 21, 9), 60, status: OccurrenceStatus.done),
      item('B', at(2026, 9, 21, 11), 90),
      item('C', at(2026, 9, 21, 14), 30, status: OccurrenceStatus.cancelled),
      item('D', at(2026, 9, 21, 15), 45, status: OccurrenceStatus.skipped),
      item('E', at(2026, 9, 21), 1440, allDay: true),
      item('F', at(2026, 9, 21, 16), 30, trackingMode: TrackingMode.event),
      item('G', at(2026, 9, 22, 10), 30, trackingMode: TrackingMode.event),
    ];

    test('planned minutes: timed items only, cancelled and skipped excluded', () {
      final m = dayMetric(items, HeatMetric.planned);
      expect(m[d1], 60 + 90 + 30, reason: 'A + B + event F; not the cancelled, skipped or all-day ones');
      expect(m[d2], 30);
    });

    test('count: every item that was not cancelled', () {
      final m = dayMetric(items, HeatMetric.count);
      expect(m[d1], 5, reason: 'A, B, D, E, F');
      expect(m[d2], 1);
    });

    test('completion: done ÷ countable (events do not count), absent without countable items', () {
      final m = dayMetric(items, HeatMetric.completion);
      expect(m[d1], closeTo(0.25, 1e-9), reason: 'A done of A, B, D, E');
      expect(m.containsKey(d2), isFalse, reason: 'only an event that day');
    });

    test('backlog items and empty input yield nothing', () {
      expect(dayMetric(const [], HeatMetric.planned), isEmpty);
      final backlog = PlannerItem(
        taskId: 't',
        seriesId: 't',
        occurrenceKey: '',
        title: 'Someday',
        startLocal: at(2026, 9, 21),
        durationMinutes: 30,
        startUtc: DateTime.utc(2026, 9, 21),
        endUtc: DateTime.utc(2026, 9, 21, 0, 30),
        status: OccurrenceStatus.scheduled,
      );
      expect(dayMetric([backlog], HeatMetric.count), isEmpty);
    });
  });

  group('heatLevel', () {
    test('planned minutes bin at 2 h, 4 h and 6 h', () {
      expect(heatLevel(HeatMetric.planned, null), 0);
      expect(heatLevel(HeatMetric.planned, 0), 0);
      expect(heatLevel(HeatMetric.planned, 1), 1);
      expect(heatLevel(HeatMetric.planned, 120), 1);
      expect(heatLevel(HeatMetric.planned, 121), 2);
      expect(heatLevel(HeatMetric.planned, 240), 2);
      expect(heatLevel(HeatMetric.planned, 241), 3);
      expect(heatLevel(HeatMetric.planned, 360), 3);
      expect(heatLevel(HeatMetric.planned, 361), 4);
    });

    test('item counts bin at 2, 4 and 7', () {
      expect(
        [
          for (final n in [0, 1, 2, 3, 4, 5, 7, 8, 30]) heatLevel(HeatMetric.count, n.toDouble()),
        ],
        [0, 1, 1, 2, 2, 3, 3, 4, 4],
      );
    });

    test('completion bins by quartile; a day with items but none done is level 1', () {
      expect(heatLevel(HeatMetric.completion, 0), 1);
      expect(heatLevel(HeatMetric.completion, 0.24), 1);
      expect(heatLevel(HeatMetric.completion, 0.25), 2);
      expect(heatLevel(HeatMetric.completion, 0.5), 3);
      expect(heatLevel(HeatMetric.completion, 0.75), 4);
      expect(heatLevel(HeatMetric.completion, 1), 4);
      expect(heatLevel(HeatMetric.completion, null), 0);
    });

    test('metric ids parse with planned as the fallback', () {
      expect(HeatMetric.parse('completion'), HeatMetric.completion);
      expect(HeatMetric.parse('count'), HeatMetric.count);
      expect(HeatMetric.parse(null), HeatMetric.planned);
      expect(HeatMetric.parse('nonsense'), HeatMetric.planned);
    });
  });
}
