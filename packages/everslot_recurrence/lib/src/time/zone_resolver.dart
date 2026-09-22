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
  const ResolvedInstant(this.utc, this.kind, this.offsetMinutes);

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
class TzZoneResolver implements ZoneResolver {
  TzZoneResolver();

  final Map<String, tz.Location> _cache = {};

  tz.Location _location(String zoneId) =>
      _cache.putIfAbsent(zoneId, () => zoneId == 'UTC' ? tz.UTC : tz.getLocation(zoneId));

  int _offsetMs(tz.Location location, int utcMs) =>
      location.timeZone(utcMs).offset;

  @override
  ResolvedInstant resolve(LocalDateTime local, String zoneId) {
    final location = _location(zoneId);
    final wallMs = local.epochMinute * 60000;
    const day = 86400000;
    final offsetBefore = _offsetMs(location, wallMs - day);
    final offsetAfter = _offsetMs(location, wallMs + day);

    final candidates = <int>{wallMs - offsetBefore, wallMs - offsetAfter}
        .where((utc) => _offsetMs(location, utc) == wallMs - utc)
        .toList()
      ..sort();

    if (candidates.isEmpty) {
      // Gap: interpret with the offset in force before the gap → lands after the gap.
      final utc = wallMs - offsetBefore;
      return ResolvedInstant(
        DateTime.fromMillisecondsSinceEpoch(utc, isUtc: true),
        ResolutionKind.shiftedForward,
        _offsetMs(location, utc) ~/ 60000,
      );
    }
    final utc = candidates.first;
    return ResolvedInstant(
      DateTime.fromMillisecondsSinceEpoch(utc, isUtc: true),
      candidates.length > 1 ? ResolutionKind.ambiguousEarlier : ResolutionKind.exact,
      _offsetMs(location, utc) ~/ 60000,
    );
  }

  @override
  LocalDateTime toLocal(DateTime instant, String zoneId) {
    final utcMs = instant.toUtc().millisecondsSinceEpoch;
    final wallMs = utcMs + _offsetMs(_location(zoneId), utcMs);
    final minutes = wallMs >= 0 ? wallMs ~/ 60000 : -((-wallMs + 59999) ~/ 60000);
    return LocalDateTime.fromEpochMinute(minutes);
  }

  @override
  int offsetMinutesAt(DateTime instant, String zoneId) =>
      _offsetMs(_location(zoneId), instant.toUtc().millisecondsSinceEpoch) ~/ 60000;
}

/// A resolver for tests: every zone has the same fixed offset.
class FixedOffsetZoneResolver implements ZoneResolver {
  const FixedOffsetZoneResolver([this.offsetMinutes = 0]);

  final int offsetMinutes;

  @override
  ResolvedInstant resolve(LocalDateTime local, String zoneId) => ResolvedInstant(
    DateTime.fromMillisecondsSinceEpoch((local.epochMinute - offsetMinutes) * 60000, isUtc: true),
    ResolutionKind.exact,
    offsetMinutes,
  );

  @override
  LocalDateTime toLocal(DateTime instant, String zoneId) {
    final ms = instant.toUtc().millisecondsSinceEpoch + offsetMinutes * 60000;
    return LocalDateTime.fromEpochMinute(ms >= 0 ? ms ~/ 60000 : -((-ms + 59999) ~/ 60000));
  }

  @override
  int offsetMinutesAt(DateTime instant, String zoneId) => offsetMinutes;
}
