import 'package:collection/collection.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// The part of a timed item that falls on one day, in that day's elapsed minutes.
@immutable
class DaySegment {
  const DaySegment({
    required this.item,
    required this.tStart,
    required this.tEnd,
    required this.wallStart,
    required this.repeatStart,
    required this.wallEnd,
    required this.repeatEnd,
    this.continuesBefore = false,
    this.continuesAfter = false,
  });

  final PlannerItem item;
  final int tStart;
  final int tEnd;
  final int wallStart;
  final int repeatStart;
  final int wallEnd;
  final int repeatEnd;

  /// Started on an earlier day (split at midnight).
  final bool continuesBefore;

  /// Continues on the next day.
  final bool continuesAfter;

  int get minutes => tEnd - tStart;

  @override
  bool operator ==(Object other) =>
      other is DaySegment &&
      other.item == item &&
      other.tStart == tStart &&
      other.tEnd == tEnd &&
      other.wallStart == wallStart &&
      other.repeatStart == repeatStart &&
      other.wallEnd == wallEnd &&
      other.repeatEnd == repeatEnd &&
      other.continuesBefore == continuesBefore &&
      other.continuesAfter == continuesAfter;

  @override
  int get hashCode => Object.hash(item, tStart, tEnd, wallStart, repeatStart, wallEnd, repeatEnd, continuesBefore, continuesAfter);
}

/// Everything one day column shows: timed segments and lane (all-day / multi-day) items.
@immutable
class DaySlice {
  const DaySlice({required this.date, required this.timeline, required this.timed, required this.lane});

  final LocalDate date;
  final DayTimeline timeline;

  /// Sorted by start, longer first.
  final List<DaySegment> timed;

  /// All-day items and timed items ≥ 24 h touching this day.
  final List<PlannerItem> lane;

  bool get isEmpty => timed.isEmpty && lane.isEmpty;

  /// Planned minutes (timed segments only).
  int get plannedMinutes => timed.fold(0, (a, s) => a + s.minutes);
}

/// True when [item] belongs in the all-day lane.
bool isLaneItem(PlannerItem item, {bool longTimedAsLane = true}) =>
    item.allDay || (longTimedAsLane && item.durationMinutes >= 1440);

/// Inclusive last date covered by a lane item.
LocalDate laneEndDate(PlannerItem item) {
  if (item.allDay) {
    final days = item.durationMinutes <= 0 ? 1 : (item.durationMinutes + 1439) ~/ 1440;
    return item.startLocal.date.plusDays(days - 1);
  }
  final end = item.endLocal;
  return end.time.minuteOfDay == 0 && end.date.isAfter(item.startLocal.date) ? end.date.minusDays(1) : end.date;
}

/// Splits [items] into per-day slices for [days] (T3.3.14): timed items crossing midnight are split,
/// DST days follow elapsed minutes (a repeated-hour start picks its pass from `startUtc`), lane items
/// go to every day they cover. [previous] slices whose content is unchanged are reused (identity), so
/// downstream layout caches only recompute affected days.
List<DaySlice> sliceItems({
  required List<PlannerItem> items,
  required List<LocalDate> days,
  required DayTimeline Function(LocalDate) timelineOf,
  bool longTimedAsLane = true,
  Map<LocalDate, DaySlice>? previous,
}) {
  if (days.isEmpty) return const [];
  final timed = {for (final d in days) d: <DaySegment>[]};
  final lane = {for (final d in days) d: <PlannerItem>[]};
  final first = days.first;
  final last = days.last;
  for (final item in items) {
    if (isLaneItem(item, longTimedAsLane: longTimedAsLane)) {
      final end = laneEndDate(item);
      if (end.isBefore(first) || item.startLocal.date.isAfter(last)) continue;
      for (final d in days) {
        if (!d.isBefore(item.startLocal.date) && !d.isAfter(end)) lane[d]!.add(item);
      }
      continue;
    }
    var d = item.startLocal.date;
    if (d.isAfter(last)) continue;
    var tl = timelineOf(d);
    final wall = item.startLocal.time.minuteOfDay;
    var t0 = tl.tOfWall(wall, repeat: _repeatOf(item, tl, wall));
    var remaining = item.durationMinutes < 0 ? 0 : item.durationMinutes;
    var isFirst = true;
    for (var guard = 0; guard < 400; guard++) {
      final len = tl.lengthMinutes;
      final segEnd = t0 + remaining > len ? len : t0 + remaining;
      final list = timed[d];
      if (list != null) {
        final (ws, rs) = tl.wallAt(t0);
        final (we, re) = remaining == 0 ? (ws, rs) : tl.wallAtEnd(segEnd);
        list.add(DaySegment(
          item: item,
          tStart: t0,
          tEnd: segEnd,
          wallStart: ws,
          repeatStart: rs,
          wallEnd: we,
          repeatEnd: re,
          continuesBefore: !isFirst,
          continuesAfter: t0 + remaining > len,
        ));
      }
      remaining -= segEnd - t0;
      if (remaining <= 0) break;
      d = d.plusDays(1);
      if (d.isAfter(last)) break;
      tl = timelineOf(d);
      t0 = 0;
      isFirst = false;
    }
  }
  return [
    for (final d in days)
      _reuse(
        DaySlice(
          date: d,
          timeline: timelineOf(d),
          timed: List.unmodifiable(timed[d]!..sort(_bySegment)),
          lane: List.unmodifiable(lane[d]!..sort(_byLane)),
        ),
        previous?[d],
      ),
  ];
}

DaySlice _reuse(DaySlice fresh, DaySlice? old) {
  if (old == null) return fresh;
  if (old.date != fresh.date || old.timeline != fresh.timeline) return fresh;
  if (!const ListEquality<DaySegment>().equals(old.timed, fresh.timed)) return fresh;
  if (!const ListEquality<PlannerItem>().equals(old.lane, fresh.lane)) return fresh;
  return old;
}

int _bySegment(DaySegment a, DaySegment b) {
  final c = a.tStart.compareTo(b.tStart);
  if (c != 0) return c;
  final d = b.tEnd.compareTo(a.tEnd);
  return d != 0 ? d : a.item.key.compareTo(b.item.key);
}

int _byLane(PlannerItem a, PlannerItem b) {
  final c = a.startLocal.compareTo(b.startLocal);
  if (c != 0) return c;
  final d = b.durationMinutes.compareTo(a.durationMinutes);
  return d != 0 ? d : a.key.compareTo(b.key);
}

int _repeatOf(PlannerItem item, DayTimeline tl, int wall) {
  if (tl.isRegular || !tl.hasWall(wall, repeat: 1)) return 0;
  final second = tl.instantAt(tl.tOfWall(wall, repeat: 1));
  return second.isAtSameMomentAs(item.startUtc) ? 1 : 0;
}
