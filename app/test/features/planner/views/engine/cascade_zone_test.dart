import 'package:everslot/features/planner/presentation/grid/time_ruler.dart';
import 'package:everslot/features/planner/presentation/grid/timeline_page.dart';
import 'package:flutter_test/flutter_test.dart';

// Cascade overlap style and zone ruler helpers (T3.3.26).
void main() {
  test('cascade tiles are 1.7× their share and step across the column', () {
    final (l0, w0) = cascadeFractions(0, 1, 2, rtl: false);
    final (l1, w1) = cascadeFractions(1, 1, 2, rtl: false);
    expect(w0, closeTo(0.85, 1e-9));
    expect(w1, closeTo(0.85, 1e-9));
    expect(l0, 0);
    expect(l1 + w1, closeTo(1, 1e-9), reason: 'the last tile ends at the column edge');
    expect(l1, lessThan(l0 + w0), reason: 'tiles partly overlap');
    final (r0, _) = cascadeFractions(0, 1, 2, rtl: true);
    expect(r0, closeTo(0.15, 1e-9), reason: 'mirrored in RTL');
    expect(cascadeFractions(0, 2, 3, rtl: false).$2, 1, reason: 'capped at the full column');
  });

  test('zone short names', () {
    expect(zoneShortName('America/New_York'), 'New York');
    expect(zoneShortName('UTC'), 'UTC');
  });
}
