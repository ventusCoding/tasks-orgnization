@Tags(['benchmark'])
library;

import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// T2.1.18 budgets, asserted loosely (×10) so CI machines and JIT warm-up
/// never make the suite flaky. The measured numbers are printed.
void main() {
  tzdata.initializeTimeZones();
  final engine = RecurrenceEngine(TzZoneResolver());
  final paris = RecurrenceAnchor(LocalDateTime.of(2026, 1, 1, 8), 'Europe/Paris');

  /// Best of [runs] after one warm-up, in microseconds.
  int measure(void Function() body, {int runs = 7}) {
    body();
    var best = 1 << 62;
    for (var i = 0; i < runs; i++) {
      final watch = Stopwatch()..start();
      body();
      watch.stop();
      if (watch.elapsedMicroseconds < best) best = watch.elapsedMicroseconds;
    }
    return best;
  }

  void report(String name, int micros, int budgetMicros) {
    // ignore: avoid_print
    print('$name: ${(micros / 1000).toStringAsFixed(2)} ms (budget ${budgetMicros / 1000} ms)');
    expect(micros, lessThan(budgetMicros * 10), reason: '$name exceeded 10× its budget');
  }

  test('1 year of a daily rule < 5 ms', () {
    final micros = measure(() {
      final n = engine
          .between(RecurrenceRule(), paris, LocalDateTime.of(2026, 1, 1), LocalDateTime.of(2027, 1, 1))
          .length;
      expect(n, 365);
    });
    report('daily × 1 year', micros, 5000);
  });

  test('one day of a 1-minute rule < 2 ms', () {
    final micros = measure(() {
      final n = engine
          .between(
            RecurrenceRule(freq: Frequency.minutely),
            paris,
            LocalDateTime.of(2026, 6, 1),
            LocalDateTime.of(2026, 6, 2),
          )
          .length;
      expect(n, 1440);
    });
    report('minutely × 1 day', micros, 2000);
  });

  test('10 years of "last weekday of month" < 5 ms', () {
    final rule = RecurrenceRule(
      freq: Frequency.monthly,
      byWeekday: [for (final d in Weekday.values.take(5)) WeekdayRule(d)],
      bySetPos: const [-1],
    );
    final micros = measure(() {
      final n = engine.between(rule, paris, LocalDateTime.of(2026, 1, 1), LocalDateTime.of(2036, 1, 1)).length;
      expect(n, 120);
    });
    report('last weekday × 10 years', micros, 5000);
  });

  test('nextAfter on a 20-year-old rule < 1 ms', () {
    final old = RecurrenceAnchor(LocalDateTime.of(2006, 3, 1, 7, 30), 'America/New_York');
    final rule = RecurrenceRule(freq: Frequency.weekly, byWeekday: const [WeekdayRule(Weekday.monday)]);
    final micros = measure(() {
      expect(engine.nextAfter(rule, old, DateTime.utc(2026, 9, 23)), isNotNull);
    }, runs: 20);
    report('nextAfter after 20 years', micros, 1000);
  });

  test('hard cap: more than 10 000 occurrences per call is an explicit error', () {
    final week = engine.between(
      RecurrenceRule(freq: Frequency.minutely),
      paris,
      LocalDateTime.of(2026, 6, 1),
      LocalDateTime.of(2026, 6, 8),
    );
    expect(week.toList, throwsA(isA<RecurrenceLimitExceeded>()));
    expect(engine.maxOccurrencesPerCall, 10000);
    expect(RecurrenceRule(freq: Frequency.minutely).validate().isValid, isTrue);
  });
}
