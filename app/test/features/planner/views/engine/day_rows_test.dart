import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_rows.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_slices.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot/features/planner/presentation/grid/engine/page_axis.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../support/items.dart';

final _day = LocalDate(2026, 9, 23);

DaySlice _slice(List<PlannerItem> items, {LocalDate? day, DayTimeline? timeline}) {
  final d = day ?? _day;
  final tl = timeline ?? DayTimeline.regular(d);
  return sliceItems(items: items, days: [d], timelineOf: (_) => tl).single;
}

void main() {
  group('slot counts', () {
    for (final (slot, rows, last) in [(1, 1440, 1), (15, 96, 15), (30, 48, 30), (60, 24, 60), (120, 12, 120), (1440, 1, 1440), (7, 206, 5)]) {
      test('$slot-minute slots → $rows rows, last $last min', () {
        final r = buildDayRows(slice: _slice(const []), slotMinutes: slot);
        expect(r, hasLength(rows));
        expect(r.last.minutes, last);
        expect(r.first.wallStart, 0);
        expect(r.last.wallEnd, 1440);
      });
    }
  });

  test('an item spanning several slots appears once, with bars over the following rows', () {
    final gym = item('Gym', at(2026, 9, 23, 9, 15), 135);
    final rows = buildDayRows(slice: _slice([gym]), slotMinutes: 30);
    final withItem = [for (final r in rows) if (r.entries.isNotEmpty) r];
    expect(withItem.single.wallStart, 9 * 60);
    final barRows = [for (final r in rows) if (r.bars.isNotEmpty) r.wallStart ~/ 30];
    expect(barRows, [18, 19, 20, 21, 22]); // 09:00 … 11:00 (ends 11:30)
    expect(rows[18].bars.single.starts, isTrue);
    expect(rows[22].bars.single.ends, isTrue);
    expect(rows[19].isCovered, isTrue);
  });

  test('items that started the previous day land in the first row marked "continues"', () {
    final night = item('Night shift', at(2026, 9, 22, 22), 360);
    final rows = buildDayRows(slice: _slice([night]), slotMinutes: 60);
    expect(rows.first.entries.single.continues, isTrue);
    expect(rows.first.entries.single.tEnd, 240);
    expect(rows[3].bars.single.ends, isTrue);
  });

  test('overlapping items get separate bar lanes', () {
    final a = item('A', at(2026, 9, 23, 9), 90);
    final b = item('B', at(2026, 9, 23, 10), 60);
    final rows = buildDayRows(slice: _slice([a, b]), slotMinutes: 30);
    final row = rows.firstWhere((r) => r.wallStart == 600);
    expect(row.bars.map((b) => b.lane).toSet(), {0, 1});
  });

  test('hidden hours are one row that keeps its items', () {
    final early = item('Early', at(2026, 9, 23, 5), 30);
    final rows = buildDayRows(slice: _slice([early]), slotMinutes: 30, window: const DayWindow(360, 1320));
    expect(rows.first.kind, AxisBandKind.hidden);
    expect(rows.first.entries.single.item.title, 'Early');
    expect(rows.last.kind, AxisBandKind.hidden);
    expect(rows, hasLength(2 + 32));
  });

  group('collapsing (hideEmptySlots)', () {
    test('1-minute slots with 5 tasks collapse to 11 rows', () {
      final items = [for (var i = 0; i < 5; i++) item('T$i', at(2026, 9, 23, 8 + i * 2), 45)];
      final rows = buildDayRows(slice: _slice(items), slotMinutes: 1);
      final collapsed = collapseRows(rows);
      expect(collapsed, hasLength(11));
      final free = collapsed.first as FreeListRow;
      expect((free.wallStart, free.wallEnd), (0, 480));
      final gap = collapsed[2] as FreeListRow;
      expect((gap.wallStart, gap.wallEnd, gap.minutes), (525, 600, 75));
    });

    test('an expanded run shows its slots again', () {
      final rows = buildDayRows(slice: _slice([item('T', at(2026, 9, 23, 10), 60)]), slotMinutes: 30);
      final expanded = collapseRows(rows, expanded: {0});
      expect(expanded.whereType<SlotListRow>().where((r) => r.row.entries.isEmpty).length, 20);
    });
  });

  group('DST', () {
    late ZoneResolver resolver;
    setUpAll(() {
      tzdata.initializeTimeZones();
      resolver = TzZoneResolver();
    });

    test('23-hour day omits the missing hour', () {
      final d = LocalDate(2026, 3, 29);
      final tl = DayTimeline.build(d, 'Europe/Paris', resolver);
      final rows = buildDayRows(slice: _slice(const [], day: d, timeline: tl), slotMinutes: 60);
      final normal = [for (final r in rows) if (r.kind == AxisBandKind.normal) r];
      expect(normal, hasLength(23));
      expect(normal.map((r) => r.wallStart), isNot(contains(120)));
      expect(rows.any((r) => r.kind == AxisBandKind.gap), isTrue);
    });

    test('25-hour day repeats the ambiguous hour and places both passes', () {
      final d = LocalDate(2026, 10, 25);
      final tl = DayTimeline.build(d, 'Europe/Paris', resolver);
      final firstPass = resolver.resolve(at(2026, 10, 25, 2, 30), 'Europe/Paris').utc;
      final items = [
        item('First', at(2026, 10, 25, 2, 30), 15, startUtc: firstPass),
        item('Second', at(2026, 10, 25, 2, 30), 15, startUtc: firstPass.add(const Duration(hours: 1))),
      ];
      final rows = buildDayRows(slice: _slice(items, day: d, timeline: tl), slotMinutes: 60);
      expect(rows, hasLength(25));
      final twoAm = [for (final r in rows) if (r.wallStart == 120) r];
      expect(twoAm.map((r) => r.repeat), [0, 1]);
      expect(twoAm.map((r) => r.entries.single.item.title), ['First', 'Second']);
    });

    test('custom 7-minute slots on a DST day end on a short slot', () {
      final d = LocalDate(2026, 3, 29);
      final tl = DayTimeline.build(d, 'Europe/Paris', resolver);
      final rows = buildDayRows(slice: _slice(const [], day: d, timeline: tl), slotMinutes: 7);
      expect(rows.last.wallEnd, 1440);
      expect(rows.last.minutes, 5);
    });
  });
}
