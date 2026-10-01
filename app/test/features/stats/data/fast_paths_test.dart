// Fast paths added by the stats performance suite (T6.1.23): the loaders' ISO instant parser and the
// zone resolver's constant-offset shortcut must give exactly the results of the general code.
import 'package:everslot/features/stats/data/stats_data_source.dart';
import 'package:everslot/features/stats/domain/zone_snapshot.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDateTime, ResolutionKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('parseUtcIso', () {
    test('matches DateTime.parse on drift text instants', () {
      for (final v in [
        DateTime.utc(2026, 9, 30, 9),
        DateTime.utc(2024, 2, 29, 23, 59, 59, 999),
        DateTime.utc(1999, 12, 31, 0, 0, 1, 2, 3),
        DateTime.utc(2026, 3, 29, 1, 30, 0, 0, 500),
      ]) {
        final text = v.toIso8601String();
        expect(StatsDataSource.parseUtcIso(text), DateTime.parse(text), reason: text);
        expect(StatsDataSource.parseUtcIso(text)!.isUtc, isTrue);
      }
      expect(StatsDataSource.parseUtcIso('2026-09-30T09:00:00Z'), DateTime.utc(2026, 9, 30, 9));
      expect(StatsDataSource.parseUtcIso('2026-09-30T09:00:00.1Z'), DateTime.utc(2026, 9, 30, 9, 0, 0, 100));
    });

    test('other shapes fall back (null)', () {
      for (final text in [
        '2026-09-30T09:00:00.000+01:00',
        '2026-09-30T09:00:00.000',
        '2026-09-30',
        '2026-09-30 09:00:00.000Z',
        '2026-09-30T09:00:00.1234567Z',
        'x026-09-30T09:00:00.000Z',
      ]) {
        expect(StatsDataSource.parseUtcIso(text), isNull, reason: text);
      }
    });
  });

  test('LocationZoneResolver: the constant-offset shortcut keeps gap and overlap handling', () {
    tzdata.initializeTimeZones();
    final resolver = LocationZoneResolver({
      for (final z in ['Europe/Paris', 'America/New_York', 'Africa/Tunis']) z: tz.getLocation(z),
    });
    // Paris spring gap (02:30 does not exist) and autumn overlap (02:30 happens twice).
    final gap = resolver.resolve(LocalDateTime.of(2026, 3, 29, 2, 30), 'Europe/Paris');
    expect(gap.kind, ResolutionKind.shiftedForward);
    expect(gap.utc, DateTime.utc(2026, 3, 29, 1, 30));
    final overlap = resolver.resolve(LocalDateTime.of(2026, 10, 25, 2, 30), 'Europe/Paris');
    expect(overlap.kind, ResolutionKind.ambiguousEarlier);
    expect(overlap.utc, DateTime.utc(2026, 10, 25, 0, 30));
    // Every half hour of a year round-trips through toLocal (exact resolutions).
    for (final zone in ['Europe/Paris', 'America/New_York', 'Africa/Tunis']) {
      for (var m = 0; m < 366 * 48; m++) {
        final local = LocalDateTime.of(2026, 1, 1).plusMinutes(m * 30);
        final r = resolver.resolve(local, zone);
        if (r.kind == ResolutionKind.exact) {
          expect(resolver.toLocal(r.utc, zone), local, reason: '$zone $local');
          expect(r.offsetMinutes, resolver.offsetMinutesAt(r.utc, zone));
        }
      }
    }
  });
}
