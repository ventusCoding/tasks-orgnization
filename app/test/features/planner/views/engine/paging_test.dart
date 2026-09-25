import 'package:everslot/features/planner/presentation/grid/engine/paging.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final anchor = LocalDate(2026, 9, 23); // Wednesday
  const base = PagingModel.baseIndex;

  group('week paging', () {
    for (final ws in Weekday.values) {
      test('week start ${ws.code}: pages start on ${ws.code} and round-trip', () {
        final m = PagingModel(mode: PagingMode.week, anchor: anchor, weekStart: ws, daysVisible: 7);
        final days = m.daysOfPage(base);
        expect(days, hasLength(7));
        expect(days.first.weekday, ws);
        expect(days.contains(anchor), isTrue);
        for (var p = base - 60; p <= base + 60; p += 7) {
          for (final d in m.daysOfPage(p)) {
            expect(m.pageOf(d), p);
          }
        }
      });
    }

    test('Saturday week start gives Sat–Fri weeks', () {
      final m = PagingModel(mode: PagingMode.week, anchor: anchor, weekStart: Weekday.saturday, daysVisible: 7);
      expect(m.daysOfPage(base).first, LocalDate(2026, 9, 19));
      expect(m.daysOfPage(base).last, LocalDate(2026, 9, 25));
    });

    test('52 weeks forward and back return to the same week', () {
      final m = PagingModel(mode: PagingMode.week, anchor: anchor, weekStart: Weekday.monday, daysVisible: 7);
      final forward = m.daysOfPage(base + 52);
      expect(forward.first, LocalDate(2027, 9, 20));
      expect(m.daysOfPage(m.pageOf(forward.first) - 52).first, LocalDate(2026, 9, 21));
    });

    test('year boundary and DST weeks map correctly', () {
      final m = PagingModel(mode: PagingMode.week, anchor: LocalDate(2026, 12, 30), weekStart: Weekday.monday, daysVisible: 7);
      expect(m.daysOfPage(base).map((d) => d.toIso()), [
        '2026-12-28', '2026-12-29', '2026-12-30', '2026-12-31', '2027-01-01', '2027-01-02', '2027-01-03',
      ]);
      expect(m.pageOf(LocalDate(2027, 1, 3)), base);
      expect(m.pageOf(LocalDate(2027, 1, 4)), base + 1);
      final dst = PagingModel(mode: PagingMode.week, anchor: LocalDate(2026, 10, 25), weekStart: Weekday.monday, daysVisible: 7);
      expect(dst.daysOfPage(base).last, LocalDate(2026, 10, 25));
    });

    test('hidden weekends give 5-day pages', () {
      final m = PagingModel(
        mode: PagingMode.week,
        anchor: anchor,
        weekStart: Weekday.monday,
        daysVisible: 5,
        visibleWeekdays: {Weekday.monday, Weekday.tuesday, Weekday.wednesday, Weekday.thursday, Weekday.friday},
      );
      expect(m.isWeekPaging, isTrue);
      expect(m.daysOfPage(base).map((d) => d.day), [21, 22, 23, 24, 25]);
      expect(m.pageOf(LocalDate(2026, 9, 27)), base);
    });

    test('14 days on tablets = two-week pages', () {
      final m = PagingModel(mode: PagingMode.week, anchor: anchor, weekStart: Weekday.monday, daysVisible: 14);
      expect(m.daysOfPage(base), hasLength(14));
      expect(m.pageOf(LocalDate(2026, 10, 4)), base);
      expect(m.pageOf(LocalDate(2026, 10, 5)), base + 1);
    });
  });

  group('day paging', () {
    test('pages are single days; viewport shows N', () {
      final m = PagingModel(mode: PagingMode.day, anchor: anchor, weekStart: Weekday.monday, daysVisible: 3);
      expect(m.isWeekPaging, isFalse);
      expect(m.viewportFraction, closeTo(1 / 3, 1e-9));
      expect(m.daysOfPage(base), [anchor]);
      expect(m.daysOnScreen(base), [anchor, anchor.plusDays(1), anchor.plusDays(2)]);
      expect(m.pageOf(anchor.plusDays(40)), base + 40);
      expect(m.daysOfPage(base - 400).single, anchor.minusDays(400));
    });

    test('week mode with fewer days than a week falls back to day steps', () {
      final m = PagingModel(mode: PagingMode.week, anchor: anchor, weekStart: Weekday.monday, daysVisible: 3);
      expect(m.isWeekPaging, isFalse);
      expect(m.columnsOnScreen, 3);
    });

    test('hidden weekends are skipped', () {
      final m = PagingModel(
        mode: PagingMode.free,
        anchor: LocalDate(2026, 9, 25), // Friday
        weekStart: Weekday.monday,
        daysVisible: 3,
        visibleWeekdays: {Weekday.monday, Weekday.tuesday, Weekday.wednesday, Weekday.thursday, Weekday.friday},
      );
      expect(m.daysOnScreen(base).map((d) => d.day), [25, 28, 29]);
      expect(m.pageOf(LocalDate(2026, 9, 26)), base + 1); // Saturday → next visible (Monday)
      expect(m.daysOfPage(base - 1).single, LocalDate(2026, 9, 24));
      for (var p = base - 30; p < base + 30; p++) {
        expect(m.pageOf(m.daysOfPage(p).single), p);
      }
    });
  });
}
