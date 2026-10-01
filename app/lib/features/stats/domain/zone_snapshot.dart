/// Zone resolution inside the stats isolate from a snapshot of `tz.Location`s (T6.1.13).
///
/// `tz.Location` objects are plain data, so the batch sends the few zones it needs instead of
/// initializing the whole IANA database in every isolate. Same DST rules as the recurrence engine's
/// `TzZoneResolver`: gaps shift forward (offset before the gap), ambiguous times take the earlier
/// instant. Pure Dart.
library;

import 'package:everslot_metrics/everslot_metrics.dart' show DayBoundaries, FunctionZoneClock, ZoneClock;
import 'package:everslot_recurrence/everslot_recurrence.dart'
    show LocalDateTime, LocalTime, ResolutionKind, ResolvedInstant, ZoneResolver;
import 'package:timezone/timezone.dart' as tz;

/// A [ZoneResolver] over a fixed set of locations. Unknown zones fall back to [fallbackZone]
/// (then UTC), so a missing snapshot never throws inside a batch.
final class LocationZoneResolver implements ZoneResolver {
  LocationZoneResolver(this.locations, {this.fallbackZone});

  final Map<String, tz.Location> locations;
  final String? fallbackZone;

  tz.Location _location(String zoneId) {
    if (zoneId == 'UTC') return tz.UTC;
    return locations[zoneId] ?? (fallbackZone == null ? null : locations[fallbackZone!]) ?? tz.UTC;
  }

  int _offsetMs(tz.Location location, int utcMs) => location.timeZone(utcMs).offset.inMilliseconds;

  @override
  ResolvedInstant resolve(LocalDateTime local, String zoneId) {
    final location = _location(zoneId);
    final wallMs = local.epochMinute * 60000;
    const day = 86400000;
    final offsetBefore = _offsetMs(location, wallMs - day);
    final offsetAfter = _offsetMs(location, wallMs + day);
    if (offsetBefore == offsetAfter) {
      // No transition near this wall time (the common case): one candidate, checked once.
      final utc = wallMs - offsetBefore;
      if (_offsetMs(location, utc) == offsetBefore) {
        return ResolvedInstant(
          DateTime.fromMillisecondsSinceEpoch(utc, isUtc: true),
          ResolutionKind.exact,
          offsetBefore ~/ 60000,
        );
      }
    }
    final candidates = <int>{
      wallMs - offsetBefore,
      wallMs - offsetAfter,
    }.where((utc) => _offsetMs(location, utc) == wallMs - utc).toList()..sort();
    if (candidates.isEmpty) {
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

/// A metrics [ZoneClock] for [zoneId] backed by [resolver].
ZoneClock zoneClockOf(ZoneResolver resolver, String zoneId) =>
    FunctionZoneClock((instant) => resolver.toLocal(instant, zoneId), (local) => resolver.resolve(local, zoneId).utc);

/// Day boundaries of [zoneId] with an optional day start (minutes after midnight).
DayBoundaries dayBoundariesOf(ZoneResolver resolver, String zoneId, {int dayStartMinutes = 0}) => DayBoundaries(
  zoneClockOf(resolver, zoneId),
  dayStartsAt: LocalTime.fromMinuteOfDay(dayStartMinutes.clamp(0, 1439)),
);
