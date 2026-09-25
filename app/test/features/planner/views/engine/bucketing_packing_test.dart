import 'package:everslot/features/planner/presentation/grid/engine/bucketing.dart';
import 'package:everslot/features/planner/presentation/grid/engine/lane_packing.dart';
import 'package:everslot/features/planner/presentation/grid/engine/page_axis.dart';
import 'package:everslot/features/planner/presentation/grid/engine/snapping.dart';
import 'package:everslot/features/planner/presentation/grid/engine/zoom.dart';
import 'package:flutter_test/flutter_test.dart';

List<(int, int)> rowsOf(int slot) => [for (final r in PageAxis.regular().slotRows(slot)) (r.wallStart, r.wallEnd)];

void main() {
  group('bucketing', () {
    test('120-min slots: 09:15–11:30 → chip in 08–10, continuation in 10–12', () {
      final b = bucketDay(const [BucketInput(0, 555, 690)], rowsOf(120));
      expect(b[4], const [BucketEntry(0, isStart: true)]);
      expect(b[5], const [BucketEntry(0, isStart: false)]);
      expect(b.where((c) => c.isNotEmpty), hasLength(2));
    });

    test('items continuing from the previous day start with a continuation', () {
      final b = bucketDay(const [BucketInput(0, 0, 60, continuesFromPreviousDay: true)], rowsOf(30));
      expect(b[0], const [BucketEntry(0, isStart: false)]);
      expect(b[1], const [BucketEntry(0, isStart: false)]);
    });

    test('midnight crossing: last row of day 1 holds the chip', () {
      final b = bucketDay(const [BucketInput(0, 1380, 1440)], rowsOf(60));
      expect(b.last, const [BucketEntry(0, isStart: true)]);
    });

    test('chips ordered by start then priority', () {
      final b = bucketDay(const [
        BucketInput(0, 540, 560, priority: 1),
        BucketInput(1, 540, 560, priority: 4),
        BucketInput(2, 530, 560),
      ], rowsOf(60));
      expect(b[8].map((e) => e.index), [2]);
      expect(b[9].map((e) => e.index), [2, 1, 0]);
      expect(b[9].first.isStart, isFalse);
    });

    test('zero-duration items land in one row', () {
      final b = bucketDay(const [BucketInput(0, 600, 600)], rowsOf(30));
      expect(b[20], const [BucketEntry(0, isStart: true)]);
      expect(b[21], isEmpty);
    });

    test('24-h slot: one row with every item', () {
      final b = bucketDay(const [BucketInput(0, 60, 120), BucketInput(1, 900, 960)], rowsOf(1440));
      expect(b.single.map((e) => e.isStart), [true, true]);
    });

    test('row sizing: fixed shows "+N", auto-fit grows up to the cap', () {
      final fixed = sizeRows(maxCountPerRow: [0, 1, 5], autoFit: false, rowExtent: 48, chipExtent: 20, maxChipsPerCell: 3);
      expect(fixed.heights, [48, 48, 48]);
      expect(fixed.visibleChips, [0, 1, 1]);
      final auto = sizeRows(maxCountPerRow: [0, 2, 5], autoFit: true, rowExtent: 30, chipExtent: 20, maxChipsPerCell: 3);
      expect(auto.heights, [30, 44, 84]);
      expect(auto.visibleChips, [0, 2, 3]);
      expect(maxCounts([
        [[], [const BucketEntry(0, isStart: true)]],
        [[const BucketEntry(1, isStart: true), const BucketEntry(2, isStart: true)], []],
      ], 2), [2, 1]);
    });
  });

  group('lane packing', () {
    test('a 3-day trip is one bar across three columns', () {
      final p = packLane(const [LaneInput(0, 2, 5)], 7);
      expect(p.bars.single.span, 3);
      expect(p.rowCount, 1);
    });

    test('greedy rows and collapse to 2 rows + "+N"', () {
      final p = packLane(const [
        LaneInput(0, 0, 7),
        LaneInput(1, 0, 2),
        LaneInput(2, 1, 3),
        LaneInput(3, 3, 4),
      ], 7, maxRows: 2);
      expect(p.bars.map((b) => (b.index, b.row)), [(0, 0), (1, 1), (3, 1)]);
      expect(p.hiddenPerColumn, [0, 1, 1, 0, 0, 0, 0]);
      expect(p.hasHidden, isTrue);
    });

    test('continuation flags survive packing', () {
      final p = packLane(const [LaneInput(0, 0, 7, continuesBefore: true, continuesAfter: true)], 7);
      expect(p.bars.single.continuesBefore && p.bars.single.continuesAfter, isTrue);
    });
  });

  group('snapping', () {
    test('grid snapping to snap minutes', () {
      const s = SnapEngine(snapMinutes: 15, pxPerMinute: 1.6);
      expect(s.snap(547), const SnapResult(540, SnapKind.grid));
      expect(s.snap(553), const SnapResult(555, SnapKind.grid));
      expect(s.snapFloor(554).minute, 540);
    });

    test('magnetic snapping within 8 px wins over the grid', () {
      const s = SnapEngine(snapMinutes: 15, pxPerMinute: 1.6, magnetTargets: [547]);
      expect(s.snap(544), const SnapResult(547, SnapKind.magnet));
      expect(s.snap(530), const SnapResult(525, SnapKind.grid));
    });

    test('free mode keeps minute precision', () {
      const s = SnapEngine(snapMinutes: 15, pxPerMinute: 1.6, free: true);
      expect(s.snap(547.4), const SnapResult(547, SnapKind.none));
    });

    test('default snap = min(slot, 15)', () {
      expect(SnapEngine.defaultSnapFor(30), 15);
      expect(SnapEngine.defaultSnapFor(5), 5);
      expect(SnapEngine.defaultSnapFor(1), 1);
    });

    test('haptics throttled to ≤ 30 per second', () {
      final t = HapticThrottle();
      var fired = 0;
      for (var ms = 0; ms < 1000; ms++) {
        if (t.tryFire(Duration(milliseconds: ms))) fired++;
      }
      expect(fired, lessThanOrEqualTo(30));
      expect(fired, greaterThanOrEqualTo(29));
    });
  });

  group('zoom', () {
    test('semantic zoom walks presets past thresholds', () {
      expect(ZoomMath.semanticSlot(30, 1.6), 30);
      expect(ZoomMath.semanticSlot(30, 11.2), 5);
      expect(ZoomMath.semanticSlot(30, 0.5), 60);
      expect(ZoomMath.semanticSlot(1440, 0.01), 1440);
      expect(ZoomMath.semanticSlot(1, 200), 1);
    });

    test('horizontal pinch snaps to whole days', () {
      expect(ZoomMath.daysForScale(7, 2.3), 3);
      expect(ZoomMath.daysForScale(3, 0.4), 7);
      expect(ZoomMath.daysForScale(7, 0.2, maxDays: 14), 14);
      expect(ZoomMath.daysForScale(1, 5), 1);
    });

    test('focal content y scales around fixed bands', () {
      expect(ZoomMath.scaleContentY(900, 1.5, 3), 1800);
      expect(ZoomMath.scaleContentY(920, 1.5, 3, fixedBefore: 20), 1820);
      expect(ZoomMath.keepFocal(focalContentY: 1800, focalViewportY: 300, maxOffset: 5000), 1500);
    });
  });
}
