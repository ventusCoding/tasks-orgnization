import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot/features/planner/presentation/grid/engine/page_axis.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  late ZoneResolver resolver;
  setUpAll(() {
    tzdata.initializeTimeZones();
    resolver = TzZoneResolver();
  });

  List<DayTimeline> week(String firstIso, String zone) {
    final first = LocalDate.parse(firstIso);
    return [for (var i = 0; i < 7; i++) DayTimeline.build(first.plusDays(i), zone, resolver)];
  }

  test('regular axis is one proportional band', () {
    final axis = PageAxis.regular();
    expect(axis.isSimple, isTrue);
    expect(axis.height(2), 2880);
    expect(axis.yOf(540, ppm: 2), 1080);
    expect(axis.locate(1080, 2).wall, 540);
    expect(axis.slotRows(30), hasLength(48));
    expect(axis.slotRows(7), hasLength(206));
    expect(axis.slotRows(7).last.minutes, 5);
  });

  test('hidden hours collapse to thin bands', () {
    final axis = PageAxis.regular(window: const DayWindow(360, 1320));
    expect(axis.bands.map((b) => b.kind), [AxisBandKind.hidden, AxisBandKind.normal, AxisBandKind.hidden]);
    expect(axis.height(1), 960 + 40);
    expect(axis.yOf(360, ppm: 1), 20);
    expect(axis.yOf(180, ppm: 1), 10);
    final rows = axis.slotRows(60);
    expect(rows.first.kind, AxisBandKind.hidden);
    expect(rows, hasLength(16 + 2));
    final expanded = PageAxis.regular(window: const DayWindow(360, 1320), expandedHidden: {0});
    expect(expanded.bands.first.kind, AxisBandKind.normal);
  });

  test('Paris October week repeats 02:00–03:00 once, after its first pass', () {
    final axis = PageAxis.build(week('2026-10-19', 'Europe/Paris'));
    expect(axis.normalMinutes, 1500);
    final pieces = [for (final b in axis.bands) ...b.pieces];
    expect(pieces, const [AxisPiece(0, 180), AxisPiece(120, 180, 1), AxisPiece(180, 1440)]);
    // 03:00 of a normal day sits after the repeated band.
    expect(axis.yOf(180, ppm: 1), 240);
    expect(axis.yOf(120, repeat: 1, ppm: 1), 180);
    // End-exclusive mapping at the end of the first pass stays before the repeated band.
    expect(axis.yOf(180, ppm: 1, end: true), 180);
    expect(axis.yOf(180, repeat: 1, ppm: 1, end: true), 240);
    // Normal days paint the repeated band as unavailable.
    final monday = DayTimeline.build(LocalDate(2026, 10, 19), 'Europe/Paris', resolver);
    expect(axis.unavailableRanges(monday, 1), [(180.0, 240.0)]);
    final sunday = DayTimeline.build(LocalDate(2026, 10, 25), 'Europe/Paris', resolver);
    expect(axis.unavailableRanges(sunday, 1), isEmpty);
  });

  test('Paris March week keeps the missing hour but shades it on the DST day', () {
    final days = week('2026-03-23', 'Europe/Paris');
    final axis = PageAxis.build(days);
    expect(axis.normalMinutes, 1440);
    expect(axis.unavailableRanges(days.last, 1), [(120.0, 180.0)]);
    expect(axis.unavailableRanges(days.first, 1), isEmpty);
  });

  test('a single 23-h day removes the missing hour with a gap marker', () {
    final day = DayTimeline.build(LocalDate(2026, 3, 29), 'Europe/Paris', resolver);
    final axis = PageAxis.build([day]);
    expect(axis.bands.map((b) => b.kind), [AxisBandKind.normal, AxisBandKind.gap, AxisBandKind.normal]);
    expect(axis.normalMinutes, 1380);
    final rows = axis.slotRows(30);
    expect(rows.where((r) => r.kind == AxisBandKind.normal), hasLength(46));
  });

  test('25-h day rows at 30 min = 50 rows', () {
    final day = DayTimeline.build(LocalDate(2026, 10, 25), 'Europe/Paris', resolver);
    final rows = PageAxis.build([day]).slotRows(30);
    expect(rows, hasLength(50));
    expect(rows[6], const AxisRow(120, 150, 1, AxisBandKind.normal, 1));
  });

  test('locate is the inverse of yOf across bands', () {
    final axis = PageAxis.build(week('2026-10-19', 'Europe/Paris'), window: const DayWindow(60, 1380));
    for (final (wall, repeat) in [(60, 0), (125, 0), (130, 1), (179, 1), (600, 0), (1379, 0)]) {
      final y = axis.yOf(wall, repeat: repeat, ppm: 1.5);
      final loc = axis.locate(y, 1.5);
      expect(loc.wall.round(), wall, reason: 'wall $wall r$repeat');
      expect(loc.repeat, repeat, reason: 'wall $wall r$repeat');
    }
  });
}
