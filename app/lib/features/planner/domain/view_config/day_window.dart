import 'package:meta/meta.dart';

/// Visible hours of a day (T3.4.09), minute precision, `start < end` (view config `dayWindow`).
@immutable
class DayWindow {
  const DayWindow(this.startMinute, this.endMinute);

  static const full = DayWindow(0, 1440);

  final int startMinute;
  final int endMinute;

  bool get isFull => startMinute <= 0 && endMinute >= 1440;
  int get minutes => endMinute - startMinute;

  bool contains(int minute) => minute >= startMinute && minute < endMinute;

  @override
  bool operator ==(Object other) =>
      other is DayWindow && other.startMinute == startMinute && other.endMinute == endMinute;

  @override
  int get hashCode => Object.hash(startMinute, endMinute);

  @override
  String toString() => 'DayWindow($startMinute–$endMinute)';
}
