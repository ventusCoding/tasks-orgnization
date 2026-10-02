import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/view_config/day_window.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

// Free-slot finder (T3.7.04) — pure interval algebra over wall-clock time: busy blocks are merged,
// subtracted from the work window of each work day and filtered by a minimum gap. Durations come
// from an injected function so DST days count real elapsed minutes.

/// Elapsed minutes between two wall-clock times of the display zone (DST-aware in the app).
typedef ElapsedMinutes = int Function(LocalDateTime from, LocalDateTime to);

int wallMinutes(LocalDateTime from, LocalDateTime to) => from.minutesUntil(to);

/// Elapsed minutes between two wall-clock times of [zone]: a 02:00–04:00 opening on a spring-forward
/// day lasts 60 minutes, on a fall-back day 180.
int elapsedMinutes(ZoneResolver zones, String zone, LocalDateTime from, LocalDateTime to) =>
    zones.resolve(to, zone).utc.difference(zones.resolve(from, zone).utc).inMinutes;

/// A half-open wall-clock interval [start, end).
@immutable
class WallInterval {
  const WallInterval(this.start, this.end);

  final LocalDateTime start;
  final LocalDateTime end;

  bool get isEmpty => !end.isAfter(start);

  @override
  bool operator ==(Object other) => other is WallInterval && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '[$start, $end)';
}

/// One opening: a free interval of [day] lasting [minutes] (elapsed).
@immutable
class FreeInterval {
  const FreeInterval({required this.day, required this.start, required this.end, required this.minutes});

  final LocalDate day;
  final LocalDateTime start;
  final LocalDateTime end;
  final int minutes;

  @override
  bool operator ==(Object other) =>
      other is FreeInterval && other.day == day && other.start == start && other.end == end && other.minutes == minutes;

  @override
  int get hashCode => Object.hash(day, start, end, minutes);

  @override
  String toString() => 'FreeInterval($start → $end, $minutes min)';
}

/// Options of the finder (view config `options` of the free-slots view / overlay).
@immutable
class FreeSlotOptions {
  const FreeSlotOptions({
    required this.window,
    this.workDays = const {1, 2, 3, 4, 5},
    this.minGapMinutes = 30,
    this.ignoreBelowPriority,
  });

  /// Work hours (minutes of the day).
  final DayWindow window;

  /// ISO weekdays that count as work days.
  final Set<int> workDays;

  /// Openings shorter than this are dropped (at least 1 minute).
  final int minGapMinutes;

  /// When set, items with a lower priority don't count as busy.
  final int? ignoreBelowPriority;
}

/// Sorts and merges overlapping or touching intervals.
List<WallInterval> mergeIntervals(Iterable<WallInterval> intervals) {
  final sorted = [
    for (final i in intervals)
      if (!i.isEmpty) i,
  ]..sort((a, b) => a.start.compareTo(b.start));
  final out = <WallInterval>[];
  for (final i in sorted) {
    if (out.isNotEmpty && !i.start.isAfter(out.last.end)) {
      if (i.end.isAfter(out.last.end)) out[out.length - 1] = WallInterval(out.last.start, i.end);
    } else {
      out.add(i);
    }
  }
  return out;
}

/// [window] minus the merged [busy] intervals.
List<WallInterval> subtractIntervals(WallInterval window, List<WallInterval> busy) {
  final out = <WallInterval>[];
  var cursor = window.start;
  for (final b in mergeIntervals(busy)) {
    if (!b.end.isAfter(cursor)) continue;
    if (!b.start.isBefore(window.end)) break;
    if (b.start.isAfter(cursor)) out.add(WallInterval(cursor, b.start));
    if (b.end.isAfter(cursor)) cursor = b.end;
  }
  if (window.end.isAfter(cursor)) out.add(WallInterval(cursor, window.end));
  return out;
}

/// Whether [item] blocks time: timed, not all-day, not skipped / cancelled, priority high enough.
bool isBusy(PlannerItem item, {int? ignoreBelowPriority}) {
  if (item.allDay || item.isBacklog || item.durationMinutes <= 0) return false;
  if (item.status == OccurrenceStatus.skipped || item.status == OccurrenceStatus.cancelled) return false;
  if (ignoreBelowPriority != null && item.priority < ignoreBelowPriority) return false;
  return true;
}

/// Openings inside the work window of every work day of [days], in order.
List<FreeInterval> freeIntervals({
  required Iterable<PlannerItem> items,
  required Iterable<LocalDate> days,
  required FreeSlotOptions options,
  ElapsedMinutes elapsed = wallMinutes,
  LocalDateTime? notBefore,
  Iterable<(LocalDateTime, LocalDateTime)> extraBusy = const [],
}) {
  final busy = [
    for (final i in items)
      if (isBusy(i, ignoreBelowPriority: options.ignoreBelowPriority)) WallInterval(i.startLocal, i.endLocal),
    // Busy device-calendar events (T8.2.13).
    for (final (s, e) in extraBusy) WallInterval(s, e),
  ];
  final minGap = options.minGapMinutes < 1 ? 1 : options.minGapMinutes;
  final out = <FreeInterval>[];
  for (final day in days) {
    if (!options.workDays.contains(day.weekday.iso)) continue;
    var windowStart = day.atStartOfDay.plusMinutes(options.window.startMinute);
    // Openings never start in the past (today's window begins at [notBefore]).
    if (notBefore != null && notBefore.isAfter(windowStart)) windowStart = notBefore;
    final window = WallInterval(windowStart, day.atStartOfDay.plusMinutes(options.window.endMinute));
    if (window.isEmpty) continue;
    for (final gap in subtractIntervals(window, busy)) {
      final minutes = elapsed(gap.start, gap.end);
      if (minutes >= minGap) out.add(FreeInterval(day: day, start: gap.start, end: gap.end, minutes: minutes));
    }
  }
  return out;
}

/// Places [durations] one after another into [openings] (earliest first, each item in the first
/// opening that still fits it). Returns the start of each placed item (null = didn't fit).
List<LocalDateTime?> placeSequentially(List<FreeInterval> openings, List<int> durations) {
  final free = [for (final o in openings) WallInterval(o.start, o.end)];
  return [
    for (final d in durations)
      () {
        for (var i = 0; i < free.length; i++) {
          final slot = free[i];
          if (slot.start.minutesUntil(slot.end) >= d) {
            free[i] = WallInterval(slot.start.plusMinutes(d), slot.end);
            return slot.start;
          }
        }
        return null;
      }(),
  ];
}

/// *Schedule on…* (T3.7.03): places backlog items (their [durations], in order) one after another
/// into the free slots of [day] — work hours only, around the busy [items], never before
/// [notBefore]. Returns each item's start (null = didn't fit).
List<LocalDateTime?> scheduleOnDay({
  required LocalDate day,
  required Iterable<PlannerItem> items,
  required List<int> durations,
  required FreeSlotOptions options,
  LocalDateTime? notBefore,
}) {
  final openings = freeIntervals(
    items: items,
    days: [day],
    options: FreeSlotOptions(
      window: options.window,
      workDays: {day.weekday.iso},
      ignoreBelowPriority: options.ignoreBelowPriority,
      minGapMinutes: 1,
    ),
    notBefore: notBefore,
  );
  return placeSequentially(openings, durations);
}

/// Availability as text (T3.7.04 *Copy availability*), one line per day in order:
/// "Mon 22 Sep: 10:00–11:30, 14:00–16:00". Formatting is injected (locale, 12/24 h).
String availabilityText(
  List<FreeInterval> openings, {
  required String Function(LocalDate day) formatDay,
  required String Function(LocalDateTime time) formatTime,
}) {
  final byDay = <LocalDate, List<FreeInterval>>{};
  for (final o in openings) {
    byDay.putIfAbsent(o.day, () => []).add(o);
  }
  final days = byDay.keys.toList()..sort();
  return [
    for (final d in days)
      '${formatDay(d)}: ${[for (final o in byDay[d]!) '${formatTime(o.start)}–${formatTime(o.end)}'].join(', ')}',
  ].join('\n');
}
