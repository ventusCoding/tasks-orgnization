import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  final clock = FakeClock(DateTime.utc(2026, 9, 22, 6));
  RecurrenceService service({String zone = 'Europe/Paris', int threshold = 1000}) => RecurrenceService(
    clock: clock,
    resolver: TzZoneResolver(),
    currentZone: zone,
    isolateThreshold: threshold,
  );
  final daily = RecurrenceRule();
  final anchor = RecurrenceAnchor(LocalDateTime.of(2026, 9, 21, 8), null, durationMinutes: 30);

  test('between is memoized (LRU) per rule, anchor, range and zone', () {
    final s = service();
    final a = s.between(daily, anchor, LocalDateTime.of(2026, 9, 21), LocalDateTime.of(2026, 9, 28));
    final b = s.between(daily, anchor, LocalDateTime.of(2026, 9, 21), LocalDateTime.of(2026, 9, 28));
    expect(identical(a, b), isTrue);
    expect(a, hasLength(7));
    expect(s.cacheHits, 1);
    expect(s.cacheMisses, 1);
    s.between(daily, anchor, LocalDateTime.of(2026, 9, 21), LocalDateTime.of(2026, 9, 29));
    expect(s.cacheMisses, 2);
  });

  test('LRU evicts the oldest entries', () {
    final s = RecurrenceService(clock: clock, resolver: TzZoneResolver(), currentZone: 'UTC', cacheSize: 2);
    for (var d = 1; d <= 3; d++) {
      s.between(daily, anchor, LocalDateTime.of(2026, 9, d), LocalDateTime.of(2026, 9, d + 1));
    }
    expect(s.cacheLength, 2);
  });

  test('floating rules resolve in the current zone', () {
    final paris = service().between(daily, anchor, LocalDateTime.of(2026, 9, 22), LocalDateTime.of(2026, 9, 23));
    final tokyo = service(zone: 'Asia/Tokyo').between(daily, anchor, LocalDateTime.of(2026, 9, 22), LocalDateTime.of(2026, 9, 23));
    expect(paris.single.startUtc, DateTime.utc(2026, 9, 22, 6));
    expect(tokyo.single.startUtc, DateTime.utc(2026, 9, 21, 23));
  });

  test('changing the device zone rebuilds the service (cache invalidation)', () async {
    final h = TestHarness.create(zone: 'Europe/Paris');
    addTearDown(h.dispose);
    final first = h.read(recurrenceServiceProvider);
    first.between(daily, anchor, LocalDateTime.of(2026, 9, 21), LocalDateTime.of(2026, 9, 22));
    expect(first.cacheLength, 1);
    h.read(deviceZoneProvider.notifier).debugSet('Asia/Tokyo');
    final second = h.read(recurrenceServiceProvider);
    expect(identical(first, second), isFalse);
    expect(second.currentZone, 'Asia/Tokyo');
    expect(second.cacheLength, 0);
  });

  test('nextOccurrences starts now (or at the anchor) and handles sparse and dense rules', () {
    final s = service(zone: 'UTC');
    final next = s.nextOccurrences(daily, anchor, count: 3);
    expect(next.map((o) => o.key), ['2026-09-22T08:00', '2026-09-23T08:00', '2026-09-24T08:00']);
    final yearly = s.nextOccurrences(RecurrenceRule(freq: Frequency.yearly), anchor, count: 2);
    expect(yearly.map((o) => o.key), ['2027-09-21T08:00', '2028-09-21T08:00']);
    final minutely = s.nextOccurrences(RecurrenceRule(freq: Frequency.minutely, interval: 5), anchor, count: 10);
    expect(minutely, hasLength(10));
    final after = s.nextOccurrences(RecurrenceRule.forAfterCompletion(2, RecurrenceUnit.day), anchor);
    expect(after.single.key, '2026-09-21T08:00');
  });

  test('alignAnchor moves the anchor to the first occurrence', () {
    final s = service();
    final weeklyTue = RecurrenceRule(freq: Frequency.weekly, byWeekday: const [WeekdayRule(Weekday.tuesday)]);
    expect(s.alignAnchor(weeklyTue, anchor).start, LocalDateTime.of(2026, 9, 22, 8));
    expect(s.alignAnchor(daily, anchor), anchor);
  });

  test('describe uses the language part of the locale', () {
    final s = service();
    final rule = RecurrenceRule(freq: Frequency.weekly, byWeekday: const [WeekdayRule(Weekday.monday), WeekdayRule(Weekday.tuesday)]);
    expect(s.describe(rule, anchor, locale: 'en_US'), contains('Monday'));
    expect(s.describe(rule, anchor, locale: 'fr'), contains('lundi'));
  });

  test('density and never-occurs helpers', () {
    final s = service(zone: 'UTC');
    expect(s.maxPerDay(RecurrenceRule(freq: Frequency.minutely, interval: 5), anchor), 288);
    expect(s.maxPerDay(daily, anchor), 1);
    expect(
      s.neverOccursWithin(RecurrenceRule(freq: Frequency.yearly, byMonth: const [2], byMonthDay: const [30]), anchor),
      isTrue,
    );
    expect(s.neverOccursWithin(daily, anchor), isFalse);
  });

  test('estimate and isolate decision', () {
    final s = service(threshold: 1000);
    final minutely = RecurrenceRule(freq: Frequency.minutely);
    expect(s.estimateCount(minutely, LocalDateTime.of(2026, 9, 21), LocalDateTime.of(2026, 9, 22)), 1440);
    expect(s.shouldOffload(minutely, anchor, LocalDateTime.of(2026, 9, 21), LocalDateTime.of(2026, 9, 22)), isTrue);
    expect(s.shouldOffload(daily, anchor, LocalDateTime.of(2026, 9, 21), LocalDateTime.of(2027, 9, 22)), isFalse);
    final fixed = RecurrenceService(clock: clock, resolver: const FixedOffsetZoneResolver(), currentZone: 'UTC');
    expect(fixed.shouldOffload(minutely, anchor, LocalDateTime.of(2026, 9, 21), LocalDateTime.of(2026, 9, 22)), isFalse);
  });

  test('betweenAsync offloads heavy ranges to an isolate with identical results', () async {
    final s = service(threshold: 100);
    final minutely = RecurrenceRule(freq: Frequency.minutely, interval: 2);
    final from = LocalDateTime.of(2026, 9, 21);
    final to = LocalDateTime.of(2026, 9, 22);
    final viaIsolate = await s.betweenAsync(minutely, anchor, from, to);
    final inline = RecurrenceEngine(TzZoneResolver()).between(minutely, anchor, from, to, evalZone: 'Europe/Paris').toList();
    expect(viaIsolate, inline);
    expect(await s.betweenAsync(minutely, anchor, from, to), same(viaIsolate));
  });

  test('isolate entry point expands a rule', () {
    expect(expandInIsolate, isA<Function>());
  });
}
