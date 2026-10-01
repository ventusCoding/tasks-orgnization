import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/preferences/user_preferences.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/app_time.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// T2.3.07: the app's one source for now / today / this week — logical day start, week starts,
/// DST days and zone changes.
void main() {
  setUpAll(tzdata.initializeTimeZones);

  final resolver = TzZoneResolver();
  AppTime at(DateTime utc, {String zone = 'Europe/Paris', int dayStart = 0, Weekday weekStart = Weekday.monday}) =>
      AppTime(clock: FakeClock(utc), resolver: resolver, zone: zone, dayStartMinutes: dayStart, weekStart: weekStart);

  group('logical day', () {
    test('dayStartsAt 04:00: 03:59 is still yesterday, 04:00 is today', () {
      // Paris is UTC+2 on 2026-09-22.
      final before = at(DateTime.utc(2026, 9, 22, 1, 59), dayStart: 240);
      final after = at(DateTime.utc(2026, 9, 22, 2), dayStart: 240);
      expect(before.nowLocal(), LocalDateTime(LocalDate(2026, 9, 22), LocalTime(3, 59)));
      expect(before.today(), LocalDate(2026, 9, 21));
      expect(before.calendarToday(), LocalDate(2026, 9, 22), reason: 'the planner keeps the calendar date');
      expect(after.today(), LocalDate(2026, 9, 22));
      expect(after.isToday(LocalDate(2026, 9, 22)), isTrue);
    });

    test('midnight day start: the calendar date', () {
      final t = at(DateTime.utc(2026, 9, 21, 22));
      expect(t.today(), LocalDate(2026, 9, 22));
      expect(t.logicalDateAt(DateTime.utc(2026, 9, 21, 21, 59)), LocalDate(2026, 9, 21));
    });

    test('day bounds follow the day start and last 23 h / 25 h on DST days', () {
      final t = at(DateTime.utc(2026), dayStart: 240);
      final normal = t.dayBoundsUtc(LocalDate(2026, 9, 22));
      expect(normal.start, DateTime.utc(2026, 9, 22, 2));
      expect(normal.end.difference(normal.start), const Duration(hours: 24));

      final midnight = at(DateTime.utc(2026));
      final spring = midnight.dayBoundsUtc(LocalDate(2026, 3, 29)); // Paris springs forward
      expect(spring.end.difference(spring.start), const Duration(hours: 23));
      final autumn = midnight.dayBoundsUtc(LocalDate(2026, 10, 25)); // Paris falls back
      expect(autumn.end.difference(autumn.start), const Duration(hours: 25));
    });

    test('a 02:30 day start inside the spring gap shifts forward', () {
      final t = at(DateTime.utc(2026), dayStart: 150);
      expect(t.startOfDayUtc(LocalDate(2026, 3, 29)), DateTime.utc(2026, 3, 29, 1, 30)); // 03:30 CEST
    });
  });

  group('weeks', () {
    final tuesday = LocalDate(2026, 9, 22);

    test('Monday, Saturday and Sunday week starts', () {
      expect(at(DateTime.utc(2026)).weekOf(tuesday), LocalDateRange(LocalDate(2026, 9, 21), LocalDate(2026, 9, 27)));
      expect(
        at(DateTime.utc(2026), weekStart: Weekday.saturday).weekOf(tuesday),
        LocalDateRange(LocalDate(2026, 9, 19), LocalDate(2026, 9, 25)),
      );
      expect(
        at(DateTime.utc(2026), weekStart: Weekday.sunday).weekOf(tuesday),
        LocalDateRange(LocalDate(2026, 9, 20), LocalDate(2026, 9, 26)),
      );
    });

    test('this week uses the logical today; the week start day itself starts a new week', () {
      // Sunday 2026-09-27 03:00 Paris with a 04:00 day start is still Saturday 26 → week from Sat 26.
      final t = at(DateTime.utc(2026, 9, 27, 1), dayStart: 240, weekStart: Weekday.saturday);
      expect(t.today(), LocalDate(2026, 9, 26));
      final week = t.thisWeek();
      expect(week.start, LocalDate(2026, 9, 26));
      expect(week.days, hasLength(7));
      expect(week.contains(LocalDate(2026, 10, 2)), isTrue);
      expect(week.contains(LocalDate(2026, 10, 3)), isFalse);
    });

    test('month of a date', () {
      final m = at(DateTime.utc(2026)).monthOf(LocalDate(2028, 2, 10));
      expect(m, LocalDateRange(LocalDate(2028, 2, 1), LocalDate(2028, 2, 29)));
      expect(m.dayCount, 29);
    });
  });

  group('instant <-> local', () {
    test('fixed values use their own zone, floating values the current zone', () {
      final t = at(DateTime.utc(2026), zone: 'Asia/Tokyo');
      final nine = LocalDateTime(LocalDate(2026, 9, 22), LocalTime(9, 0));
      expect(t.toInstant(nine), DateTime.utc(2026, 9, 22));
      expect(t.toInstant(nine, 'Europe/Paris'), DateTime.utc(2026, 9, 22, 7));
      expect(t.toLocal(DateTime.utc(2026, 9, 22)), nine);
      expect(t.toLocal(DateTime.utc(2026, 9, 22, 7), 'Europe/Paris'), nine);
    });

    test('DST: a gap shifts forward, an overlap takes the earlier instant', () {
      final t = at(DateTime.utc(2026));
      expect(t.toInstant(LocalDateTime(LocalDate(2026, 3, 29), LocalTime(2, 30))), DateTime.utc(2026, 3, 29, 1, 30));
      expect(t.toInstant(LocalDateTime(LocalDate(2026, 10, 25), LocalTime(2, 30))), DateTime.utc(2026, 10, 25, 0, 30));
    });

    test('a zone change moves "today" with the user', () {
      final instant = DateTime.utc(2026, 9, 22, 23);
      expect(at(instant).today(), LocalDate(2026, 9, 23), reason: 'Paris 01:00');
      expect(at(instant).copyWith(zone: 'America/New_York').today(), LocalDate(2026, 9, 22), reason: 'NY 19:00');
    });
  });

  test('appTimeProvider: clock, current zone, day start and week start in one place', () {
    final clock = FakeClock(DateTime.utc(2026, 9, 22, 1, 30));
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
        clockProvider.overrideWithValue(clock),
        zoneResolverProvider.overrideWithValue(resolver),
        userPreferencesProvider.overrideWithValue(
          UserPreferences.defaults.copyWith(
            currentTimeZone: 'Europe/Paris',
            dayStartMinutes: 240,
            weekStart: Weekday.sunday,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final time = container.read(appTimeProvider);
    expect(time.zone, 'Europe/Paris');
    expect(time.today(), LocalDate(2026, 9, 21), reason: '03:30 is before the 04:00 day start');
    clock.advance(const Duration(hours: 1));
    expect(time.today(), LocalDate(2026, 9, 22), reason: 'the clock is read on every call');
    expect(time.thisWeek().start, LocalDate(2026, 9, 20));
  });
}
