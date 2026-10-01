import 'dart:math' as math;

import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot/features/planner/presentation/grid/engine/radial_geometry.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support/items.dart';
import 'support/planner_harness.dart';

// 24-hour radial clock (T3.7.10). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initializeDateFormatting();
  });

  group('geometry', () {
    const day = DialWindow(0, 1440);

    test("12 o'clock at the top, clockwise; 06:00 at 3 o'clock on a 24 h dial", () {
      expect(angleOf(0, day), closeTo(-math.pi / 2, 1e-9));
      expect(angleOf(360, day), closeTo(0, 1e-9));
      expect(angleOf(720, day), closeTo(math.pi / 2, 1e-9));
      expect(tAtAngle(0, day), 360);
      expect(tAtAngle(-math.pi / 2, day), 0);
      expect(tAtAngle(math.pi, day), 1080);
    });

    test('arcs clip to the window', () {
      final a = arcOf(60, 180, day)!;
      expect(a.sweep, closeTo(2 * math.pi / 12, 1e-9));
      expect(arcOf(1500, 1600, day), isNull);
      final half = dialWindow(dayLength: 1440, hours: 12, zoomHours: 0, nowT: 800);
      expect(half, const DialWindow(720, 720));
      expect(arcOf(600, 780, half)!.sweep, closeTo(2 * math.pi * 60 / 720, 1e-9), reason: 'clipped to 12:00');
    });

    test('zoom centers the window on now', () {
      expect(dialWindow(dayLength: 1440, hours: 24, zoomHours: 2, nowT: 600), const DialWindow(540, 120));
      expect(angleOf(600, const DialWindow(540, 120)), closeTo(math.pi / 2, 1e-9), reason: "now at 6 o'clock");
    });

    test('DST days span their real length (Europe/Paris)', () {
      final zones = TzZoneResolver();
      final spring = DayTimeline.build(LocalDate(2026, 3, 29), 'Europe/Paris', zones);
      final autumn = DayTimeline.build(LocalDate(2026, 10, 25), 'Europe/Paris', zones);
      expect(spring.lengthMinutes, 1380);
      expect(autumn.lengthMinutes, 1500);
      final w = dialWindow(dayLength: spring.lengthMinutes, hours: 24, zoomHours: 0, nowT: 0);
      // 12:00 wall on the short day is 11 h after midnight: 11/23 of the dial.
      final noon = spring.tOfWall(720);
      expect(noon, 660);
      expect(angleOf(noon, w), closeTo(-math.pi / 2 + 2 * math.pi * 660 / 1380, 1e-9));
      final w2 = dialWindow(dayLength: autumn.lengthMinutes, hours: 12, zoomHours: 0, nowT: 0);
      expect(w2, const DialWindow(0, 750), reason: 'half of a 25-hour day');
    });
  });

  testWidgets('arcs per item; tapping an arc opens the occurrence', (tester) async {
    final h = PlannerHarness.create(items: [item('Deep work', at(2026, 9, 23, 6), 180, id: 'dw', color: 0xFF6A1B9A)]);
    addTearDown(h.dispose);
    await pumpPlanner(tester, h, const PlannerScreen(view: 'radial'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Deep work, 06:00 – 09:00')), findsOneWidget);
    // 07:30 on a 24 h dial is 112.5° clockwise from the top.
    final dial = tester.getRect(find.byKey(const Key('radial-dial')));
    final r = dial.width / 2 - 26;
    const angle = -math.pi / 2 + 2 * math.pi * 450 / 1440;
    await tester.tapAt(dial.center + Offset(math.cos(angle), math.sin(angle)) * r);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });
}
