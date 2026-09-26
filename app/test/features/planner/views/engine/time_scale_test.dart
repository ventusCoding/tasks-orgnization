import 'package:everslot/features/planner/presentation/grid/engine/time_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('slots per day', () {
    const cases = <int, (int, int)>{
      // slot: (slots, last slot length)
      1: (1440, 1),
      5: (288, 5),
      7: (206, 5),
      10: (144, 10),
      13: (111, 10),
      15: (96, 15),
      20: (72, 20),
      25: (58, 15),
      30: (48, 30),
      45: (32, 45),
      50: (29, 40),
      60: (24, 60),
      70: (21, 40),
      90: (16, 90),
      100: (15, 40),
      120: (12, 120),
      180: (8, 180),
      240: (6, 240),
      250: (6, 190),
      360: (4, 360),
      480: (3, 480),
      500: (3, 440),
      700: (3, 40),
      720: (2, 720),
      1000: (2, 440),
      1440: (1, 1440),
    };
    for (final e in cases.entries) {
      test('${e.key} min → ${e.value.$1} slots, last ${e.value.$2}', () {
        final s = TimeScale(slotMinutes: e.key, slotExtentPx: 48);
        expect(s.slotsPerDay, e.value.$1);
        expect(s.slotLength(s.slotsPerDay - 1), e.value.$2);
        expect(s.slotStart(0), 0);
        expect(s.slotEnd(s.slotsPerDay - 1), 1440);
      });
    }

    test('every preset covers the day exactly', () {
      for (final p in SlotPresets.minutes) {
        final s = TimeScale(slotMinutes: p, slotExtentPx: 40);
        var total = 0;
        for (var i = 0; i < s.slotsPerDay; i++) {
          total += s.slotLength(i);
        }
        expect(total, 1440, reason: 'preset $p');
      }
    });
  });

  group('index / px conversions', () {
    const s = TimeScale(slotMinutes: 30, slotExtentPx: 48);
    test('px per minute', () => expect(s.pxPerMinute, 1.6));
    test('slot index', () {
      expect(s.slotIndexOf(0), 0);
      expect(s.slotIndexOf(29), 0);
      expect(s.slotIndexOf(30), 1);
      expect(s.slotIndexOf(1439), 47);
      expect(s.slotIndexOf(5000), 47);
    });
    test('minute ↔ px', () {
      expect(s.minuteToPx(60), 96);
      expect(s.pxToMinute(96), 60);
    });
    test('floor/ceil to slot', () {
      expect(s.floorToSlot(47), 30);
      expect(s.ceilToSlot(47), 60);
      expect(s.ceilToSlot(60), 60);
    });
    test('clamp px/min', () {
      // whole day fits a 720 px viewport → 0.5; one 30-min slot = 360 px → 12.
      expect(TimeScale.clampPxPerMinute(0.1, slotMinutes: 30, viewportExtent: 720), 0.5);
      expect(TimeScale.clampPxPerMinute(100, slotMinutes: 30, viewportExtent: 720), 12);
      expect(TimeScale.clampPxPerMinute(2, slotMinutes: 30, viewportExtent: 720), 2);
    });
  });

  group('label cadence', () {
    test('labels are ≥ 24 px apart at any zoom', () {
      for (final slot in [...SlotPresets.minutes, 7, 13, 25, 50, 70, 100, 250, 500, 700, 1000]) {
        for (final extent in [8.0, 12.0, 20.0, 48.0, 96.0, 200.0, 400.0]) {
          final s = TimeScale(slotMinutes: slot, slotExtentPx: extent);
          final every = s.labelEveryMinutes();
          expect(every * s.pxPerMinute >= 24 || every == 1440, isTrue, reason: 'slot $slot extent $extent');
          expect(every % slot == 0 || every % 60 == 0, isTrue, reason: 'slot $slot extent $extent');
        }
      }
    });

    test('1-min slots only show hour and quarter labels', () {
      for (final extent in [2.0, 8.0, 48.0, 400.0]) {
        final s = TimeScale(slotMinutes: 1, slotExtentPx: extent);
        final every = s.labelEveryMinutes();
        expect(every % 15 == 0, isTrue, reason: 'extent $extent → $every');
      }
    });

    test('aligned to hours when slot divides an hour', () {
      const s = TimeScale(slotMinutes: 30, slotExtentPx: 48);
      expect(s.labelEveryMinutes(), 30);
      expect(s.labelMinutes().take(3), [0, 30, 60]);
      const dense = TimeScale(slotMinutes: 30, slotExtentPx: 10);
      expect(dense.labelEveryMinutes(), 120);
    });

    test('uneven slots label every k slots', () {
      const s = TimeScale(slotMinutes: 7, slotExtentPx: 10);
      expect(s.labelEveryMinutes(), 21);
    });
  });

  group('line hierarchy', () {
    test('hour lines always, minute lines only when ≥ 4 px apart', () {
      const coarse = TimeScale(slotMinutes: 30, slotExtentPx: 48);
      expect(coarse.lineLevelAt(60), GridLineLevel.hour);
      expect(coarse.lineLevelAt(30), GridLineLevel.slot);
      expect(coarse.lineLevelAt(15), GridLineLevel.quarter);
      expect(coarse.lineLevelAt(7), isNull);
      const fine = TimeScale(slotMinutes: 1, slotExtentPx: 4);
      expect(fine.lineLevelAt(7), GridLineLevel.minute);
      const fineSlots = TimeScale(slotMinutes: 1, slotExtentPx: 6);
      expect(fineSlots.lineLevelAt(7), GridLineLevel.slot);
      const tiny = TimeScale(slotMinutes: 1, slotExtentPx: 2);
      expect(tiny.lineLevelAt(7), isNull);
      expect(tiny.lineLevelAt(15), GridLineLevel.quarter);
    });

    test('lines() enumerates in order', () {
      const s = TimeScale(slotMinutes: 20, slotExtentPx: 40);
      final lines = s.lines(0, 121).map((e) => e.$1).toList();
      expect(lines, [0, 15, 20, 30, 40, 45, 60, 75, 80, 90, 100, 105, 120]);
    });
  });

  group('slot input parsing', () {
    test('accepts minutes and h+min forms', () {
      expect(parseSlotMinutes('7'), 7);
      expect(parseSlotMinutes('1440'), 1440);
      expect(parseSlotMinutes('90m'), 90);
      expect(parseSlotMinutes('1h'), 60);
      expect(parseSlotMinutes('1h 30'), 90);
      expect(parseSlotMinutes('2 h 5 min'), 125);
      expect(parseSlotMinutes('1:30'), 90);
      expect(parseSlotMinutes('24h'), 1440);
    });
    test('rejects 0, 1441 and non-numbers', () {
      expect(parseSlotMinutes('0'), isNull);
      expect(parseSlotMinutes('1441'), isNull);
      expect(parseSlotMinutes('25h'), isNull);
      expect(parseSlotMinutes('abc'), isNull);
      expect(parseSlotMinutes(''), isNull);
      expect(parseSlotMinutes('-5'), isNull);
    });
  });

  test('presets navigation', () {
    expect(SlotPresets.finer(30), 20);
    expect(SlotPresets.coarser(30), 45);
    expect(SlotPresets.finer(1), 1);
    expect(SlotPresets.coarser(1440), 1440);
    expect(SlotPresets.finer(7), 5);
  });
}
