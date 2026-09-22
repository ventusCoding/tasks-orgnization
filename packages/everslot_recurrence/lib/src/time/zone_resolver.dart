import 'package:everslot_recurrence/src/time/local_date_time.dart';
import 'package:timezone/timezone.dart' as tz;

/// How a wall-clock time was resolved to an instant.
enum ResolutionKind {
  /// The local time exists exactly once.
  exact,

  /// The local time falls into a DST gap; shifted forward by the gap length
  /// (interpreted with the UTC offset in force before the gap — RFC 5545 erratum 4271).
  shiftedForward,

  /// The local time occurs twice (DST fall-back); the earlier instant was chosen.
  ambiguousEarlier,
}

/// Result of resolving a wall-clock time in a zone.
class ResolvedInstant {
  const new(this.utc, this.kind, this.offsetMinutes);

  /// UTC instant.
  final DateTime utc;
  final ResolutionKind kind;

  /// UTC offset (minutes) in force at [utc].
  final int offsetMinutes;
}

/// Converts between wall-clock values and instants for IANA zones.
abstract interface class ZoneResolver {
  /// Resolves [local] in [zoneId] applying Everslot's DST rules.
  ResolvedInstant resolve(LocalDateTime local, String zoneId);

  /// Wall-clock value of [instant] in [zoneId] (seconds truncated).
  LocalDateTime toLocal(DateTime instant, String zoneId);

  /// UTC offset in minutes at [instant] in [zoneId].
  int offsetMinutesAt(DateTime instant, String zoneId);
}

/// [ZoneResolver] backed by `package:timezone`.
///
/// The caller must initialize the database first, e.g.
/// `import 'package:timezone/data/latest_all.dart'; initializeTimeZones();`.
///
/// Lookups are memoized per zone (the transition-free segment of the last
/// lookup is cached), so resolving long sequential runs of wall-clock values —
/// the typical recurrence expansion pattern — costs one comparison per value.
class TzZoneResolver implements ZoneResolver {
  new();

  final Map<String, _ZoneSegmentCache> _cache = {};

  _ZoneSegmentCache _zone(String zoneId) => _cache.putIfAbsent(
    zoneId,
    () => _ZoneSegmentCache(zoneId == 'UTC' ? tz.UTC : tz.getLocation(zoneId)),
  );

  static const int _dayMs = 86400000;

  @override
  ResolvedInstant resolve(LocalDateTime local, String zoneId) {
    final zone = _zone(zoneId);
    final wallMs = local.epochMinute * 60000;

    // Fast path: the cached segment covers ±1 day around the candidate
    // instant, so the wall time exists exactly once.
    final guess = wallMs - zone.offset;
    if (guess - _dayMs >= zone.start && guess + _dayMs < zone.end) {
      return ResolvedInstant(
        DateTime.fromMillisecondsSinceEpoch(guess, isUtc: true),
        ResolutionKind.exact,
        zone.offset ~/ 60000,
      );
    }

    final offsetBefore = zone.offsetAt(wallMs - _dayMs);
    final offsetAfter = zone.offsetAt(wallMs + _dayMs);
    final a = wallMs - offsetBefore;
    final b = wallMs - offsetAfter;
    final aValid = zone.offsetAt(a) == offsetBefore;
    final bValid = a != b && zone.offsetAt(b) == offsetAfter;

    if (!aValid && !bValid) {
      // Gap: interpret with the offset in force before the gap → lands after the gap.
      return ResolvedInstant(
        DateTime.fromMillisecondsSinceEpoch(a, isUtc: true),
        ResolutionKind.shiftedForward,
        zone.offsetAt(a) ~/ 60000,
      );
    }
    final int utc;
    final ResolutionKind kind;
    if (aValid && bValid) {
      utc = a < b ? a : b;
      kind = ResolutionKind.ambiguousEarlier;
    } else {
      utc = aValid ? a : b;
      kind = ResolutionKind.exact;
    }
    return ResolvedInstant(
      DateTime.fromMillisecondsSinceEpoch(utc, isUtc: true),
      kind,
      zone.offsetAt(utc) ~/ 60000,
    );
  }

  @override
  LocalDateTime toLocal(DateTime instant, String zoneId) {
    final utcMs = instant.toUtc().millisecondsSinceEpoch;
    final wallMs = utcMs + _zone(zoneId).offsetAt(utcMs);
    final minutes = wallMs >= 0
        ? wallMs ~/ 60000
        : -((-wallMs + 59999) ~/ 60000);
    return LocalDateTime.fromEpochMinute(minutes);
  }

  @override
  int offsetMinutesAt(DateTime instant, String zoneId) =>
      _zone(zoneId).offsetAt(instant.toUtc().millisecondsSinceEpoch) ~/ 60000;
}

/// Caches the transition-free segment of the last lookup for one zone.
final class _ZoneSegmentCache {
  new(this.location);

  final tz.Location location;

  /// Segment start (inclusive, UTC ms); empty until the first lookup.
  int start = 1;

  /// Segment end (exclusive, UTC ms).
  int end = 0;

  /// Offset (ms) in force during the segment.
  int offset = 0;

  int offsetAt(int utcMs) {
    if (utcMs >= start && utcMs < end) return offset;
    final instant = location.lookupTimeZone(utcMs);
    start = instant.start;
    end = instant.end;
    return offset = instant.timeZone.offset.inMilliseconds;
  }
}

/// A resolver for tests: every zone has the same fixed offset.
class FixedOffsetZoneResolver implements ZoneResolver {
  const new([this.offsetMinutes = 0]);

  final int offsetMinutes;

  @override
  ResolvedInstant resolve(LocalDateTime local, String zoneId) =>
      ResolvedInstant(
        DateTime.fromMillisecondsSinceEpoch(
          (local.epochMinute - offsetMinutes) * 60000,
          isUtc: true,
        ),
        ResolutionKind.exact,
        offsetMinutes,
      );

  @override
  LocalDateTime toLocal(DateTime instant, String zoneId) {
    final ms = instant.toUtc().millisecondsSinceEpoch + offsetMinutes * 60000;
    return LocalDateTime.fromEpochMinute(
      ms >= 0 ? ms ~/ 60000 : -((-ms + 59999) ~/ 60000),
    );
  }

  @override
  int offsetMinutesAt(DateTime instant, String zoneId) => offsetMinutes;
}
