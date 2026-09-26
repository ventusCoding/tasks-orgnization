import 'dart:math';

import 'package:everslot/features/planner/presentation/grid/engine/overlap_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('non-overlapping items take the full width', () {
    final l = layoutDay(const [LayoutInput(0, 60, 120), LayoutInput(1, 120, 180)]);
    expect(l.tiles.map((t) => (t.column, t.span, t.columns)), [(0, 1, 1), (0, 1, 1)]);
    expect(l.overflow, isEmpty);
  });

  test('two overlapping items split the column', () {
    final l = layoutDay(const [LayoutInput(0, 60, 180), LayoutInput(1, 90, 150)]);
    expect(l.tiles.map((t) => (t.index, t.column, t.columns)), [(0, 0, 2), (1, 1, 2)]);
  });

  test('tiles expand right into free columns', () {
    // A 60–180 (col 0), B 60–90 (col 1), C 60–90 (col 2), D 100–170 (col 1 → expands into col 2).
    final l = layoutDay(const [
      LayoutInput(0, 60, 180),
      LayoutInput(1, 60, 90),
      LayoutInput(2, 60, 90),
      LayoutInput(3, 100, 170),
    ]);
    final d = l.tiles.firstWhere((t) => t.index == 3);
    expect((d.column, d.span, d.columns), (1, 2, 3));
  });

  test('longer items come first on equal starts', () {
    final l = layoutDay(const [LayoutInput(0, 60, 90), LayoutInput(1, 60, 240)]);
    expect(l.tiles.first.index, 1);
    expect(l.tiles.first.column, 0);
  });

  test('lane cap 2: five overlapping items → 2 lanes + "+3"', () {
    final l = layoutDay([for (var i = 0; i < 5; i++) LayoutInput(i, 540, 600 + i)], laneCap: 2);
    expect(l.tiles, hasLength(2));
    expect(l.overflow, hasLength(1));
    expect(l.overflow.single.count, 3);
    expect(l.overflow.single.start, 540);
  });

  test('min duration makes point items occupy their rendered height', () {
    final l = layoutDay(const [LayoutInput(0, 60, 60), LayoutInput(1, 65, 70)], minDuration: 15);
    expect(l.tiles.map((t) => t.columns), [2, 2]);
    expect(l.tiles.first.end, 75);
  });

  group('properties over 10 000 random days', () {
    final rnd = Random(42);
    final days = List.generate(10000, (_) {
      final n = rnd.nextInt(14);
      return [
        for (var i = 0; i < n; i++)
          () {
            final s = rnd.nextInt(1400);
            return LayoutInput(i, s, s + rnd.nextInt(240));
          }(),
      ];
    });

    for (final cap in [2, 4, 1 << 20]) {
      test('lane cap $cap', () {
        for (final items in days) {
          final l = layoutDay(items, laneCap: cap, minDuration: 10);
          // Deterministic.
          final again = layoutDay(items.reversed.toList(), laneCap: cap, minDuration: 10);
          expect(again.tiles.toSet(), l.tiles.toSet());
          // Every item placed or in exactly one overflow group.
          final placed = l.tiles.map((t) => t.index).toList();
          final spilled = [for (final g in l.overflow) ...g.indices];
          expect({...placed, ...spilled}.length, items.length);
          expect(placed.length + spilled.length, items.length);
          for (final t in l.tiles) {
            expect(t.width, lessThanOrEqualTo(1.0));
            expect(t.column + t.span, lessThanOrEqualTo(t.columns));
            expect(t.columns, lessThanOrEqualTo(cap));
          }
          // Placed tiles never overlap.
          for (var a = 0; a < l.tiles.length; a++) {
            for (var b = a + 1; b < l.tiles.length; b++) {
              final x = l.tiles[a];
              final y = l.tiles[b];
              final timeOverlap = x.start < y.end && y.start < x.end;
              final colOverlap = x.column < y.column + y.span && y.column < x.column + x.span;
              expect(timeOverlap && colOverlap, isFalse, reason: '$x vs $y');
            }
          }
        }
      });
    }
  });
}
