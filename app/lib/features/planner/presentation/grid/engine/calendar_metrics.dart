import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

// Per-day metrics of the calendar heat views (T3.6.10 year heatmap, T3.6.12 quarter): pure,
// computed from planner items by planned start date.

/// What a heat cell measures (view config `options.heatMetric`).
enum HeatMetric {
  planned,
  completion,
  count;

  static HeatMetric parse(String? s) => switch (s) {
    'completion' => completion,
    'count' => count,
    _ => planned,
  };
}

/// Value of [metric] per day for [items]: planned minutes (timed, not cancelled / skipped),
/// completion rate done ÷ countable (check / timer, not cancelled; absent when none) or the
/// number of non-cancelled items. Days without a value are absent.
Map<LocalDate, double> dayMetric(Iterable<PlannerItem> items, HeatMetric metric) {
  final planned = <LocalDate, double>{};
  final done = <LocalDate, int>{};
  final countable = <LocalDate, int>{};
  final count = <LocalDate, double>{};
  for (final i in items) {
    if (i.isBacklog || i.status == OccurrenceStatus.cancelled) continue;
    final d = i.startLocal.date;
    count[d] = (count[d] ?? 0) + 1;
    if (!i.allDay && i.status != OccurrenceStatus.skipped) planned[d] = (planned[d] ?? 0) + i.durationMinutes;
    if (i.trackingMode != TrackingMode.event) {
      countable[d] = (countable[d] ?? 0) + 1;
      if (i.isDone) done[d] = (done[d] ?? 0) + 1;
    }
  }
  return switch (metric) {
    HeatMetric.planned => planned,
    HeatMetric.count => count,
    HeatMetric.completion => {for (final e in countable.entries) e.key: (done[e.key] ?? 0) / e.value},
  };
}

/// Heat level 0–4 of a day value (0 = nothing): planned by hours (≤ 2, ≤ 4, ≤ 6, more), count by
/// items (1–2, 3–4, 5–7, 8+), completion by quartiles (a day with countable items but none done
/// is level 1).
int heatLevel(HeatMetric metric, double? value) {
  if (value == null) return 0;
  switch (metric) {
    case HeatMetric.planned:
      if (value <= 0) return 0;
      if (value <= 120) return 1;
      if (value <= 240) return 2;
      if (value <= 360) return 3;
      return 4;
    case HeatMetric.count:
      if (value <= 0) return 0;
      if (value <= 2) return 1;
      if (value <= 4) return 2;
      if (value <= 7) return 3;
      return 4;
    case HeatMetric.completion:
      if (value < 0.25) return 1;
      if (value < 0.5) return 2;
      if (value < 0.75) return 3;
      return 4;
  }
}
