import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// T1.3.03: the injectable clock.
void main() {
  group('FakeClock', () {
    test('holds a UTC instant until told otherwise', () {
      final clock = FakeClock(DateTime.parse('2026-09-22T09:00:00+02:00'));
      expect(clock.nowUtc(), DateTime.utc(2026, 9, 22, 7));
      expect(clock.nowUtc().isUtc, isTrue);
      expect(clock.nowUtc(), clock.nowUtc(), reason: 'does not tick by itself');
      clock.advance(const Duration(hours: 30));
      expect(clock.nowUtc(), DateTime.utc(2026, 9, 23, 13));
      clock.set(DateTime.utc(2027));
      expect(clock.nowUtc(), DateTime.utc(2027));
    });
  });

  group('SystemClock / TravelClock', () {
    test('SystemClock follows the wall clock, shifted by its offset', () {
      final before = DateTime.now().toUtc();
      final now = const SystemClock().nowUtc();
      final after = DateTime.now().toUtc();
      expect(now.isUtc, isTrue);
      expect(now.isBefore(before), isFalse);
      expect(now.isAfter(after), isFalse);
      final shifted = const SystemClock(offset: Duration(days: 2)).nowUtc();
      expect(shifted.difference(now).inHours, inInclusiveRange(47, 48));
    });

    test('TravelClock changes for every holder at once (debug time travel, T1.3.16)', () {
      final clock = TravelClock();
      final a = clock;
      final b = clock;
      final base = a.nowUtc();
      clock.offset = const Duration(days: 7, hours: 3);
      expect(b.nowUtc().difference(base).inHours, inInclusiveRange(7 * 24 + 3, 7 * 24 + 4));
      clock.offset = Duration.zero;
      expect(a.nowUtc().difference(base).inSeconds, lessThan(2));
    });
  });

  group('clockProvider', () {
    test('is overridable, so application code never needs DateTime.now()', () {
      final fake = FakeClock(DateTime.utc(2026, 9, 22, 9));
      final container = ProviderContainer(
        overrides: [
          envProvider.overrideWithValue(
            const Env(
              flavor: Flavor.dev,
              supabaseUrl: '',
              supabasePublishableKey: '',
              firebaseEnabled: false,
              featureFlags: {},
            ),
          ),
          clockProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(clockProvider).nowUtc(), DateTime.utc(2026, 9, 22, 9));
      fake.advance(const Duration(minutes: 1));
      expect(container.read(clockProvider).nowUtc(), DateTime.utc(2026, 9, 22, 9, 1));
    });
  });
}
