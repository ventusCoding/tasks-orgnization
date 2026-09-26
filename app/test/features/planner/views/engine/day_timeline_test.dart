import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  late ZoneResolver resolver;
  setUpAll(() {
    tzdata.initializeTimeZones();
    resolver = TzZoneResolver();
  });

  DayTimeline day(String iso, String zone) => DayTimeline.build(LocalDate.parse(iso), zone, resolver);

  test('regular day is a single 24-h segment', () {
    final t = day('2026-09-22', 'Europe/Paris');
    expect(t.isRegular, isTrue);
    expect(t.lengthMinutes, 1440);
    expect(t.gaps, isEmpty);
    expect(t.repeatedRanges, isEmpty);
    expect(t.tOfWall(540), 540);
    expect(t.wallAt(540), (540, 0));
  });

  group('Europe/Paris', () {
    test('2026-03-29 has 23 hours and omits 02:00–03:00', () {
      final t = day('2026-03-29', 'Europe/Paris');
      expect(t.lengthMinutes, 1380);
      expect(t.segments, hasLength(2));
      expect(t.segments[0], const TimelineSegment(tStart: 0, tEnd: 120, wallStart: 0, offsetMinutes: 60));
      expect(t.segments[1], const TimelineSegment(tStart: 120, tEnd: 1380, wallStart: 180, offsetMinutes: 120));
      expect(t.gaps, [(120, 180)]);
      expect(t.hasWall(150), isFalse);
      expect(t.wallAt(120), (180, 0));
    });

    test('a floating 02:30 on the gap day shifts forward to 03:30 (engine rule)', () {
      final t = day('2026-03-29', 'Europe/Paris');
      final shifted = t.tOfWall(150);
      expect(t.wallAt(shifted), (210, 0));
      final engine = resolver.resolve(LocalDateTime.of(2026, 3, 29, 2, 30), 'Europe/Paris');
      expect(t.instantAt(shifted), engine.utc);
    });

    test('2026-10-25 has 25 hours and shows 02:00–03:00 twice', () {
      final t = day('2026-10-25', 'Europe/Paris');
      expect(t.lengthMinutes, 1500);
      expect(t.segments, [
        const TimelineSegment(tStart: 0, tEnd: 180, wallStart: 0, offsetMinutes: 120),
        const TimelineSegment(tStart: 180, tEnd: 240, wallStart: 120, offsetMinutes: 60, repeat: 1),
        const TimelineSegment(tStart: 240, tEnd: 1500, wallStart: 180, offsetMinutes: 60),
      ]);
      expect(t.repeatedRanges, [(120, 180)]);
      expect(t.tOfWall(150), 150);
      expect(t.tOfWall(150, repeat: 1), 210);
      expect(t.offsetLabelAt(120, repeat: 1), '+01:00');
      expect(t.offsetLabelAt(120), '+02:00');
    });
  });

  group('America/New_York', () {
    test('spring forward 2026-03-08', () {
      final t = day('2026-03-08', 'America/New_York');
      expect(t.lengthMinutes, 1380);
      expect(t.gaps, [(120, 180)]);
    });
    test('fall back 2026-11-01 repeats 01:00–02:00', () {
      final t = day('2026-11-01', 'America/New_York');
      expect(t.lengthMinutes, 1500);
      expect(t.repeatedRanges, [(60, 120)]);
      expect(t.offsetLabelAt(60, repeat: 1), '-05:00');
    });
  });

  group('Australia/Lord_Howe (30-min shift)', () {
    test('2026-04-05 repeats 01:30–02:00', () {
      final t = day('2026-04-05', 'Australia/Lord_Howe');
      expect(t.lengthMinutes, 1470);
      expect(t.repeatedRanges, [(90, 120)]);
    });
    test('2026-10-04 omits 02:00–02:30', () {
      final t = day('2026-10-04', 'Australia/Lord_Howe');
      expect(t.lengthMinutes, 1410);
      expect(t.gaps, [(120, 150)]);
    });
  });

  test('instant ↔ elapsed minute', () {
    final t = day('2026-10-25', 'Europe/Paris');
    final at = t.instantAt(200);
    expect(t.tOfInstant(at), 200);
    expect(resolver.toLocal(at, 'Europe/Paris'), LocalDateTime.of(2026, 10, 25, 2, 20));
  });

  test('cache returns the same instance', () {
    final cache = DayTimelineCache(resolver);
    final a = cache.of(LocalDate(2026, 3, 29), 'Europe/Paris');
    expect(identical(a, cache.of(LocalDate(2026, 3, 29), 'Europe/Paris')), isTrue);
    expect(cache.of(LocalDate(2026, 3, 29), 'UTC').isRegular, isTrue);
  });
}
