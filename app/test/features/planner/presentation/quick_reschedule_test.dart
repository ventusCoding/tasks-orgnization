// Quick reschedule from an overdue reminder (T7.5.03): choices by time of day.
import 'package:everslot/features/planner/presentation/quick_reschedule_sheet.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = LocalDateTime(LocalDate(2026, 9, 22), LocalTime(10, 0));

  test('afternoon: in an hour (rounded to 5 min), tonight 20:00, tomorrow at the same time', () {
    final c = quickRescheduleChoices(LocalDateTime(LocalDate(2026, 9, 22), LocalTime(14, 12)), start);
    expect(c.map((x) => x.$1), [
      QuickRescheduleKind.inAnHour,
      QuickRescheduleKind.tonight,
      QuickRescheduleKind.tomorrow,
    ]);
    expect(c[0].$2, LocalDateTime(LocalDate(2026, 9, 22), LocalTime(15, 15)));
    expect(c[1].$2, LocalDateTime(LocalDate(2026, 9, 22), LocalTime(20, 0)));
    expect(c[2].$2, LocalDateTime(LocalDate(2026, 9, 23), LocalTime(10, 0)));
  });

  test('evening: no "tonight"; late night rolls the hour into the next day', () {
    final c = quickRescheduleChoices(LocalDateTime(LocalDate(2026, 9, 22), LocalTime(23, 30)), start);
    expect(c.map((x) => x.$1), [QuickRescheduleKind.inAnHour, QuickRescheduleKind.tomorrow]);
    expect(c[0].$2, LocalDateTime(LocalDate(2026, 9, 23), LocalTime(0, 30)));
  });
}
