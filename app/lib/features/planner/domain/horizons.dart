import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Planning horizons of unscheduled intentions (T3.7.11, `tasks.horizon_key`).
enum Horizon {
  day,
  week,
  month,
  quarter,
  year;

  /// Key of the period of this horizon containing [date]: `day:2026-09-23`, `week:2026-09-21`
  /// (first day of the week), `month:2026-09`, `quarter:2026-Q3`, `year:2026`.
  String keyFor(LocalDate date, Weekday weekStart) {
    String two(int n) => n.toString().padLeft(2, '0');
    return switch (this) {
      Horizon.day => 'day:${date.toIso()}',
      Horizon.week => 'week:${date.startOfWeek(weekStart).toIso()}',
      Horizon.month => 'month:${date.year}-${two(date.month)}',
      Horizon.quarter => 'quarter:${date.year}-Q${(date.month - 1) ~/ 3 + 1}',
      Horizon.year => 'year:${date.year}',
    };
  }

  /// Horizon of a stored key, or null when malformed.
  static Horizon? of(String? key) {
    if (key == null) return null;
    final i = key.indexOf(':');
    if (i <= 0) return null;
    return values.where((h) => h.name == key.substring(0, i)).firstOrNull;
  }
}

/// Whether [key] names a period that ended before [today] (an intention carried over).
bool horizonIsPast(String key, LocalDate today, Weekday weekStart) {
  final h = Horizon.of(key);
  if (h == null) return false;
  return key.compareTo(h.keyFor(today, weekStart)) < 0;
}
