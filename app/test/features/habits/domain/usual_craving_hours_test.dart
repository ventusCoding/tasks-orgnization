import 'package:everslot/features/habits/domain/quit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('usualCravingHours (T7.5.14)', () {
    test('needs at least 10 cravings', () {
      expect(usualCravingHours(List.filled(9, 18)), isEmpty);
      expect(usualCravingHours(List.filled(10, 18)), [18]);
      expect(usualCravingHours(const []), isEmpty);
    });

    test('keeps hours with ≥ 15 % of the cravings, busiest three, in clock order', () {
      final hours = [
        ...List.filled(6, 18),
        ...List.filled(4, 8),
        ...List.filled(3, 13),
        ...List.filled(3, 22),
        7, 9, 11, 15, 16, 20, // scattered: one each
      ];
      // 22 cravings → floor = ceil(3.3) = 4: 18 (6) and 8 (4) qualify; 13 and 22 (3) don't.
      expect(usualCravingHours(hours), [8, 18]);
      expect(usualCravingHours([...hours, 13, 22, 22]), [
        8,
        18,
        22,
      ], reason: '25 → floor 4: 18, 22, then 8 beats 13 (both 4) as the earlier hour');
    });

    test('ignores out-of-range hours and honours maxHours / minCravings', () {
      final hours = [...List.filled(5, 7), ...List.filled(5, 19), -1, 24, 99];
      expect(usualCravingHours(hours), [7, 19], reason: 'invalid hours are dropped before counting');
      expect(usualCravingHours(hours, maxHours: 1), [7], reason: 'equal counts: the earlier hour first');
      expect(usualCravingHours([...List.filled(4, 7)], minCravings: 4), [7]);
    });
  });
}
