import 'dart:math' as math;

/// Slot sizes accepted by the grid (arch §6.9): any integer minute count in [1, 1440].
const kMinSlotMinutes = 1;
const kMaxSlotMinutes = 1440;
const kMinutesPerDay = 1440;

/// Preset slot sizes (semantic zoom walks these; the slot-size sheet shows them as chips).
abstract final class SlotPresets {
  static const minutes = <int>[1, 5, 10, 15, 20, 30, 45, 60, 90, 120, 180, 240, 360, 480, 720, 1440];

  /// Largest preset strictly smaller than [slot] (or [slot] when none).
  static int finer(int slot) {
    for (var i = minutes.length - 1; i >= 0; i--) {
      if (minutes[i] < slot) return minutes[i];
    }
    return slot;
  }

  /// Smallest preset strictly larger than [slot] (or [slot] when none).
  static int coarser(int slot) {
    for (final m in minutes) {
      if (m > slot) return m;
    }
    return slot;
  }

  static bool isPreset(int slot) => minutes.contains(slot);
}

/// Validates free-form slot input: "7", "90m", "1h", "1h 30", "1:30", "2 h 5 min".
/// Returns the minutes or null when invalid / out of range.
int? parseSlotMinutes(String input) {
  final s = input.trim().toLowerCase().replaceAll(',', '.');
  if (s.isEmpty) return null;
  int? total;
  final colon = RegExp(r'^(\d{1,2}):(\d{1,2})$').firstMatch(s);
  if (colon != null) {
    total = int.parse(colon.group(1)!) * 60 + int.parse(colon.group(2)!);
  } else if (RegExp(r'^\d+$').hasMatch(s)) {
    total = int.tryParse(s);
  } else {
    final m = RegExp(r'^(?:(\d+)\s*h(?:ours?|rs?)?)?\s*(?:(\d+)\s*(?:m|min|mins|minutes?)?)?$').firstMatch(s);
    if (m == null || (m.group(1) == null && m.group(2) == null)) return null;
    total = int.parse(m.group(1) ?? '0') * 60 + int.parse(m.group(2) ?? '0');
  }
  if (total == null || total < kMinSlotMinutes || total > kMaxSlotMinutes) return null;
  return total;
}

enum GridLineLevel { hour, quarter, slot, minute }

/// Pure slot math for a grid (T3.3.03). Slots start at midnight; when [slotMinutes] doesn't divide
/// the day, the last slot is cut short.
class TimeScale {
  const TimeScale({required this.slotMinutes, required this.slotExtentPx})
    : assert(slotMinutes >= kMinSlotMinutes && slotMinutes <= kMaxSlotMinutes, 'slot out of range');

  factory TimeScale.withPpm(int slotMinutes, double pxPerMinute) =>
      TimeScale(slotMinutes: slotMinutes, slotExtentPx: slotMinutes * pxPerMinute);

  final int slotMinutes;
  final double slotExtentPx;

  double get pxPerMinute => slotExtentPx / slotMinutes;

  int get slotsPerDay => slotsIn(kMinutesPerDay);

  int slotsIn(int dayMinutes) => (dayMinutes + slotMinutes - 1) ~/ slotMinutes;

  int slotIndexOf(int minute, [int dayMinutes = kMinutesPerDay]) => minute.clamp(0, dayMinutes - 1) ~/ slotMinutes;

  int slotStart(int index) => index * slotMinutes;

  int slotEnd(int index, [int dayMinutes = kMinutesPerDay]) => math.min((index + 1) * slotMinutes, dayMinutes);

  int slotLength(int index, [int dayMinutes = kMinutesPerDay]) => slotEnd(index, dayMinutes) - slotStart(index);

  int floorToSlot(int minute) => minute - minute % slotMinutes;

  int ceilToSlot(int minute) => minute % slotMinutes == 0 ? minute : floorToSlot(minute) + slotMinutes;

  double minuteToPx(num minute) => minute * pxPerMinute;

  double pxToMinute(double px) => px / pxPerMinute;

  bool get showSlotLines => slotMinutes * pxPerMinute >= 6;
  bool get showQuarterLines => 15 * pxPerMinute >= 6;
  bool get showMinuteLines => pxPerMinute >= 4;

  /// Line level at [minute] (null = no line). Hour lines strong; quarter-hour lines faint; slot lines
  /// when ≥ 6 px apart; minute lines when ≥ 4 px apart.
  GridLineLevel? lineLevelAt(int minute) {
    if (minute % 60 == 0) return GridLineLevel.hour;
    if (minute % slotMinutes == 0 && showSlotLines) return GridLineLevel.slot;
    if (minute % 15 == 0 && showQuarterLines) return GridLineLevel.quarter;
    if (showMinuteLines) return GridLineLevel.minute;
    return null;
  }

  /// Every line in [from, to) (minutes), cheapest step first.
  Iterable<(int, GridLineLevel)> lines(int from, int to) sync* {
    final step = showMinuteLines ? 1 : _gcd(showSlotLines ? slotMinutes : 60, showQuarterLines ? 15 : 60);
    var m = from - from % step;
    if (m < from) m += step;
    for (; m < to; m += step) {
      final level = lineLevelAt(m);
      if (level != null) yield (m, level);
    }
  }

  /// Minutes between two ruler labels so labels are ≥ [minGapPx] apart; aligned to hours when the
  /// slot divides an hour (1-min slots show hour and quarter labels only).
  int labelEveryMinutes({double minGapPx = 24}) {
    final ppm = pxPerMinute;
    if (slotMinutes < 60 && 60 % slotMinutes == 0) {
      const divisors = [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30];
      final floor = slotMinutes < 15 ? 15 : slotMinutes;
      for (final d in divisors) {
        if (d % slotMinutes == 0 && d >= floor && d * ppm >= minGapPx) return d;
      }
      const hours = [60, 120, 180, 240, 360, 720, 1440];
      for (final h in hours) {
        if (h * ppm >= minGapPx) return h;
      }
      return 1440;
    }
    final k = math.max(1, (minGapPx / (slotMinutes * ppm)).ceil());
    return math.min(k * slotMinutes, 1440);
  }

  /// Label minutes in [0, dayMinutes).
  List<int> labelMinutes({double minGapPx = 24, int dayMinutes = kMinutesPerDay}) {
    final every = labelEveryMinutes(minGapPx: minGapPx);
    return [for (var m = 0; m < dayMinutes; m += every) m];
  }

  /// px/min clamps: between "the whole day fits the viewport" and "one slot = half the viewport".
  static double clampPxPerMinute(
    double ppm, {
    required int slotMinutes,
    required double viewportExtent,
    int dayMinutes = kMinutesPerDay,
  }) {
    if (viewportExtent <= 0) return ppm;
    final min = viewportExtent / dayMinutes;
    final max = math.max(min, viewportExtent / 2 / slotMinutes);
    return ppm.clamp(min, max);
  }

  TimeScale copyWith({int? slotMinutes, double? slotExtentPx}) =>
      TimeScale(slotMinutes: slotMinutes ?? this.slotMinutes, slotExtentPx: slotExtentPx ?? this.slotExtentPx);

  @override
  bool operator ==(Object other) =>
      other is TimeScale && other.slotMinutes == slotMinutes && other.slotExtentPx == slotExtentPx;

  @override
  int get hashCode => Object.hash(slotMinutes, slotExtentPx);
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
