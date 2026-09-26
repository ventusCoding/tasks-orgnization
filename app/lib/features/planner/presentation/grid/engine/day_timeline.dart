import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// A run of elapsed minutes of one local day with a constant UTC offset (T3.3.04).
@immutable
class TimelineSegment {
  const TimelineSegment({
    required this.tStart,
    required this.tEnd,
    required this.wallStart,
    required this.offsetMinutes,
    this.repeat = 0,
  });

  /// Elapsed minutes since the start of the day, [tStart, tEnd).
  final int tStart;
  final int tEnd;

  /// Wall-clock minute of day at [tStart].
  final int wallStart;
  final int offsetMinutes;

  /// 0 = first pass of these wall-clock minutes, 1 = repeated pass (DST fall-back).
  final int repeat;

  int get wallEnd => wallStart + (tEnd - tStart);
  int get length => tEnd - tStart;

  @override
  bool operator ==(Object other) =>
      other is TimelineSegment &&
      other.tStart == tStart &&
      other.tEnd == tEnd &&
      other.wallStart == wallStart &&
      other.offsetMinutes == offsetMinutes &&
      other.repeat == repeat;

  @override
  int get hashCode => Object.hash(tStart, tEnd, wallStart, offsetMinutes, repeat);

  @override
  String toString() => 'Seg(t $tStart–$tEnd, wall $wallStart–$wallEnd, off $offsetMinutes, r$repeat)';
}

/// Wall-clock rows of one local day in a zone: a 23-h day omits the missing hour, a 25-h day
/// repeats the ambiguous hour (second copy flagged `repeat = 1`). Maps instant ↔ elapsed minute ↔
/// wall-clock minute.
@immutable
class DayTimeline {
  const DayTimeline._(this.date, this.zone, this.startUtc, this.segments);

  /// A 24-h day without transitions (fast path, tests).
  factory DayTimeline.regular(LocalDate date, {String zone = 'UTC', int offsetMinutes = 0}) => DayTimeline._(
    date,
    zone,
    date.atStartOfDay.toDateTimeUtc().subtract(Duration(minutes: offsetMinutes)),
    [TimelineSegment(tStart: 0, tEnd: 1440, wallStart: 0, offsetMinutes: offsetMinutes)],
  );

  /// Builds the timeline of [date] in [zone] using the recurrence engine's resolver (so gap rules
  /// match the engine: a wall time inside a gap shifts forward).
  factory DayTimeline.build(LocalDate date, String zone, ZoneResolver resolver) {
    final startUtc = resolver.resolve(date.atStartOfDay, zone).utc;
    final endUtc = resolver.resolve(date.plusDays(1).atStartOfDay, zone).utc;
    final length = endUtc.difference(startUtc).inMinutes;
    int offsetAt(int t) => resolver.offsetMinutesAt(startUtc.add(Duration(minutes: t)), zone);
    final off0 = offsetAt(0);
    final firstWall = resolver.toLocal(startUtc, zone);
    final wall0 = firstWall.date == date ? firstWall.time.minuteOfDay : 0;
    if (length == 1440 && wall0 == 0 && offsetAt(length - 1) == off0) {
      return DayTimeline._(date, zone, startUtc, [
        TimelineSegment(tStart: 0, tEnd: 1440, wallStart: 0, offsetMinutes: off0),
      ]);
    }
    // Find transitions: 15-min scan + binary search to the minute.
    final transitions = <(int, int)>[]; // (t, new offset)
    var prevOff = off0;
    var prevT = 0;
    for (var t = 15; t < length + 15; t += 15) {
      final tt = t > length - 1 ? length - 1 : t;
      final off = offsetAt(tt);
      if (off != prevOff) {
        var lo = prevT;
        var hi = tt;
        while (hi - lo > 1) {
          final mid = (lo + hi) ~/ 2;
          if (offsetAt(mid) == prevOff) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        transitions.add((hi, off));
        prevOff = off;
      }
      prevT = tt;
      if (tt == length - 1) break;
    }
    final segments = <TimelineSegment>[];
    var segT = 0;
    var segWall = wall0;
    var segOff = off0;
    var segRepeat = 0;
    var repeatUntilWall = -1; // wall minute where a repeated pass ends
    void close(int tEnd) {
      if (tEnd > segT) {
        segments.add(TimelineSegment(
          tStart: segT,
          tEnd: tEnd,
          wallStart: segWall,
          offsetMinutes: segOff,
          repeat: segRepeat,
        ));
      }
    }

    final events = [...transitions];
    var i = 0;
    while (true) {
      // Next boundary: a transition, or the end of a repeated pass.
      final nextTransition = i < events.length ? events[i].$1 : length;
      final repeatEndT = segRepeat == 1 ? segT + (repeatUntilWall - segWall) : length;
      if (repeatEndT < nextTransition && repeatEndT < length) {
        close(repeatEndT);
        segWall = repeatUntilWall;
        segT = repeatEndT;
        segRepeat = 0;
        continue;
      }
      if (i >= events.length) {
        close(length);
        break;
      }
      final (tx, newOff) = events[i++];
      close(tx);
      final wallAtTx = segWall + (tx - segT);
      final newWall = wallAtTx + (newOff - segOff);
      segT = tx;
      segOff = newOff;
      if (newWall < wallAtTx) {
        segWall = newWall;
        segRepeat = 1;
        repeatUntilWall = wallAtTx;
      } else {
        segWall = newWall;
        segRepeat = 0;
      }
    }
    return DayTimeline._(date, zone, startUtc, List.unmodifiable(segments));
  }

  final LocalDate date;
  final String zone;
  final DateTime startUtc;
  final List<TimelineSegment> segments;

  int get lengthMinutes => segments.last.tEnd;

  bool get isRegular =>
      segments.length == 1 && segments.first.wallStart == 0 && segments.first.tEnd == 1440;

  /// Wall-clock ranges that don't exist on this day (clocks forward).
  List<(int, int)> get gaps {
    final result = <(int, int)>[];
    var covered = 0;
    if (segments.first.wallStart > 0) result.add((0, segments.first.wallStart));
    for (final s in segments) {
      if (s.repeat == 1) continue;
      if (s.wallStart > covered && covered > 0) result.add((covered, s.wallStart));
      if (s.wallEnd > covered) covered = s.wallEnd;
    }
    if (covered < 1440 && covered > 0) result.add((covered, 1440));
    return result;
  }

  /// Wall-clock ranges shown twice (clocks back); the second pass has `repeat = 1`.
  List<(int, int)> get repeatedRanges => [
    for (final s in segments)
      if (s.repeat == 1) (s.wallStart, s.wallEnd),
  ];

  /// Wall minute and pass at elapsed minute [t] (t = length → end of day).
  (int, int) wallAt(int t) {
    if (t <= 0) return (segments.first.wallStart, segments.first.repeat);
    for (final s in segments) {
      if (t >= s.tStart && t < s.tEnd) return (s.wallStart + (t - s.tStart), s.repeat);
    }
    final last = segments.last;
    return (last.wallEnd, last.repeat);
  }

  /// End-exclusive variant of [wallAt]: at a segment boundary, the segment that *ends* at [t] wins
  /// (so the end of a repeated pass maps to the end of the repeated band).
  (int, int) wallAtEnd(int t) {
    if (t <= 0) return wallAt(t);
    for (final s in segments) {
      if (t > s.tStart && t <= s.tEnd) return (s.wallStart + (t - s.tStart), s.repeat);
    }
    return wallAt(t);
  }

  /// Elapsed minute of a wall-clock minute. Walls inside a gap shift forward by the gap length
  /// (engine rule); a missing repeated pass falls back to the first pass.
  int tOfWall(int wall, {int repeat = 0}) {
    if (wall >= 1440) return lengthMinutes;
    for (final s in segments) {
      if (s.repeat == repeat && wall >= s.wallStart && wall < s.wallEnd) return s.tStart + (wall - s.wallStart);
    }
    if (repeat == 1) return tOfWall(wall);
    for (final (a, b) in gaps) {
      if (wall >= a && wall < b) {
        final shifted = wall + (b - a);
        return shifted >= 1440 ? lengthMinutes : tOfWall(shifted);
      }
    }
    return wall.clamp(0, lengthMinutes);
  }

  /// End-exclusive variant: a wall equal to a segment end maps to that segment's end.
  int tOfWallEnd(int wall, {int repeat = 0}) {
    if (wall >= 1440) return lengthMinutes;
    for (final s in segments) {
      if (s.repeat == repeat && wall > s.wallStart && wall <= s.wallEnd) return s.tStart + (wall - s.wallStart);
    }
    return tOfWall(wall, repeat: repeat);
  }

  bool hasWall(int wall, {int repeat = 0}) {
    for (final s in segments) {
      if (s.repeat == repeat && wall >= s.wallStart && wall < s.wallEnd) return true;
    }
    return false;
  }

  DateTime instantAt(int t) => startUtc.add(Duration(minutes: t));

  int tOfInstant(DateTime utc) => utc.toUtc().difference(startUtc).inMinutes;

  /// Offset of the segment containing wall [wall] on pass [repeat], e.g. "+01:00".
  String offsetLabelAt(int wall, {int repeat = 0}) {
    for (final s in segments) {
      if (s.repeat == repeat && wall >= s.wallStart && wall < s.wallEnd) return formatOffset(s.offsetMinutes);
    }
    return formatOffset(segments.first.offsetMinutes);
  }

  static String formatOffset(int minutes) {
    final sign = minutes < 0 ? '-' : '+';
    final abs = minutes.abs();
    return '$sign${(abs ~/ 60).toString().padLeft(2, '0')}:${(abs % 60).toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DayTimeline || other.date != date || other.zone != zone) return false;
    if (other.segments.length != segments.length) return false;
    for (var i = 0; i < segments.length; i++) {
      if (other.segments[i] != segments[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(date, zone, Object.hashAll(segments));

  @override
  String toString() => 'DayTimeline($date $zone, $segments)';
}

/// Caches timelines per (date, zone) — building a DST day is a few dozen zone lookups.
class DayTimelineCache {
  DayTimelineCache(this.resolver, {this.maxEntries = 400});

  final ZoneResolver? resolver;
  final int maxEntries;
  final Map<String, DayTimeline> _cache = {};

  DayTimeline of(LocalDate date, String zone) {
    final key = '$zone|$date';
    final hit = _cache[key];
    if (hit != null) return hit;
    if (_cache.length >= maxEntries) _cache.remove(_cache.keys.first);
    final r = resolver;
    final built = (r == null || zone == 'UTC') ? DayTimeline.regular(date, zone: zone) : DayTimeline.build(date, zone, r);
    return _cache[key] = built;
  }
}
