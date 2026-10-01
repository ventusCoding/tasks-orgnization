import 'dart:convert';
import 'dart:io';

import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Loads `fixtures/stats/<name>.json` (tests run from the package root).
Map<String, Object?> loadFixture(String name) {
  final file = File('../../fixtures/stats/$name.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

var _tzReady = false;

/// A [ZoneClock] backed by the IANA database (DST-aware). Gaps shift forward, ambiguous times take
/// the earlier offset (Everslot's rules).
ZoneClock tzClock(String zoneId) {
  if (!_tzReady) {
    tzdata.initializeTimeZones();
    _tzReady = true;
  }
  final location = zoneId == 'UTC' ? tz.UTC : tz.getLocation(zoneId);
  int offsetMs(int utcMs) => location.timeZone(utcMs).offset.inMilliseconds;
  return FunctionZoneClock(
    (instant) {
      final utcMs = instant.toUtc().millisecondsSinceEpoch;
      final wallMs = utcMs + offsetMs(utcMs);
      return LocalDateTime.fromEpochMinute((wallMs / 60000).floor());
    },
    (local) {
      final wallMs = local.epochMinute * 60000;
      const day = 86400000;
      final before = offsetMs(wallMs - day);
      final after = offsetMs(wallMs + day);
      final candidates = <int>{wallMs - before, wallMs - after}.where((utc) => offsetMs(utc) == wallMs - utc).toList()
        ..sort();
      final utc = candidates.isEmpty ? wallMs - before : candidates.first;
      return DateTime.fromMillisecondsSinceEpoch(utc, isUtc: true);
    },
  );
}

/// Parses `YYYY-MM-DD`.
LocalDate d(String iso) => LocalDate.parse(iso);

/// Parses `YYYY-MM-DDTHH:mm` as a wall-clock value.
LocalDateTime ldt(String iso) => LocalDateTime.parse(iso);

/// UTC instant from an ISO string (a trailing `Z` is optional).
DateTime utc(String iso) => DateTime.parse(iso.endsWith('Z') ? iso : '${iso}Z').toUtc();

/// Instant of a wall-clock time in [clock].
DateTime at(ZoneClock clock, String localIso) => clock.toInstant(ldt(localIso));

/// Matcher for doubles within [tolerance].
Matcher near(num expected, [double tolerance = 1e-9]) => closeTo(expected, tolerance);
