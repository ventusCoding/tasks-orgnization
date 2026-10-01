import 'dart:math';

import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/occurrence_resolver.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Seeded property tests (T3.2.01): sorted output, no duplicate `(taskId, key)`, every
/// occurrence overlaps the range; plus the performance budget smoke test.
void main() {
  tzdata.initializeTimeZones();
  final zones = TzZoneResolver();
  final resolver = OccurrenceResolver(RecurrenceEngine(zones));
  const zoneIds = ['UTC', 'Europe/Paris', 'America/New_York', 'Asia/Tokyo', 'Australia/Lord_Howe', 'Asia/Tehran'];

  RecurrenceRule? randomRule(Random r) {
    switch (r.nextInt(8)) {
      case 0:
        return null;
      case 1:
        return RecurrenceRule(interval: 1 + r.nextInt(3));
      case 2:
        return RecurrenceRule(
          freq: Frequency.weekly,
          byWeekday: [
            for (final d in Weekday.values)
              if (r.nextBool()) WeekdayRule(d),
          ].ifEmpty(const [WeekdayRule(Weekday.monday)]),
        );
      case 3:
        return RecurrenceRule(freq: Frequency.hourly, interval: 1 + r.nextInt(4));
      case 4:
        return RecurrenceRule(
          freq: Frequency.minutely,
          interval: 30 + r.nextInt(60),
          window: DailyWindow(LocalTime(8, 0), LocalTime(18, 0)),
        );
      case 5:
        return RecurrenceRule(freq: Frequency.monthly, byMonthDay: [1 + r.nextInt(28)]);
      case 6:
        return RecurrenceRule(count: 1 + r.nextInt(10));
      default:
        return RecurrenceRule(times: [LocalTime(8, 0), LocalTime(12 + r.nextInt(8), 30)]);
    }
  }

  test('random tasks and records keep the resolver invariants', () {
    final random = Random(7);
    for (var iteration = 0; iteration < 120; iteration++) {
      final tasks = <Task>[];
      final records = <TaskOccurrenceRecord>[];
      for (var i = 0; i < 6; i++) {
        final allDay = random.nextInt(5) == 0;
        final start = allDay
            ? LocalDate(2026, 9, 1 + random.nextInt(28)).atStartOfDay
            : LocalDateTime.of(2026, 9, 1 + random.nextInt(28), random.nextInt(24), random.nextInt(4) * 15);
        final task = Task(
          id: 't$i',
          seriesId: 't$i',
          title: 'Task $i',
          startLocal: start,
          durationMinutes: allDay ? 1440 * (1 + random.nextInt(2)) : random.nextInt(180),
          isAllDay: allDay,
          timeZone: random.nextBool() ? null : zoneIds[random.nextInt(zoneIds.length)],
          recurrence: randomRule(random),
          priority: random.nextInt(5),
          trackingMode: TrackingMode.values[random.nextInt(3)],
        );
        tasks.add(task);
        if (!allDay && random.nextBool()) {
          final key = start.plusDays(random.nextInt(3)).toIso();
          records.add(
            TaskOccurrenceRecord(
              id: '${task.id}|$key',
              taskId: task.id,
              occurrenceKey: key,
              overrideStartLocal: random.nextBool() ? start.plusMinutes(random.nextInt(2000) - 1000) : null,
              isCancelled: random.nextInt(4) == 0,
              status: OccurrenceStatus.values[random.nextInt(4)],
            ),
          );
        }
      }
      final zone = zoneIds[random.nextInt(zoneIds.length)];
      final from = LocalDate(2026, 9, 1 + random.nextInt(25)).atStartOfDay;
      final to = from.plusDays(1 + random.nextInt(7));
      final result = resolver.resolve(
        tasks: tasks,
        records: records,
        from: from,
        to: to,
        viewerZone: zone,
        now: DateTime.utc(2026, 9, 15, 12),
      );
      final fromUtc = zones.resolve(from, zone).utc;
      final toUtc = zones.resolve(to, zone).utc;
      final seen = <String>{};
      final out = result.occurrences;
      for (var i = 0; i < out.length; i++) {
        final o = out[i];
        expect(seen.add(o.identity), isTrue, reason: 'duplicate ${o.identity}');
        if (i > 0) expect(compareResolved(out[i - 1], o) <= 0, isTrue);
        if (o.isAllDay) {
          expect(o.startLocalViewer.isBefore(to) && o.endLocalViewer.isAfter(from), isTrue, reason: '$o');
        } else {
          expect(o.startInstant.isBefore(toUtc), isTrue, reason: '$o');
          expect(
            o.durationMinutes == 0 ? !o.startInstant.isBefore(fromUtc) : o.endInstant.isAfter(fromUtc),
            isTrue,
            reason: '$o',
          );
        }
      }
    }
  });

  test('cap truncates dense ranges and flags them', () {
    final task = Task(
      id: 'm',
      seriesId: 'm',
      title: 'Minutely',
      startLocal: LocalDateTime.of(2026, 9, 1),
      durationMinutes: 1,
      recurrence: RecurrenceRule(freq: Frequency.minutely),
    );
    final result = resolver.resolve(
      tasks: [task],
      records: const [],
      from: LocalDateTime.of(2026, 9, 1),
      to: LocalDateTime.of(2026, 9, 3),
      viewerZone: 'UTC',
      now: DateTime.utc(2026, 9, 1),
      settings: const ResolverSettings(maxOccurrences: 500),
    );
    expect(result.truncated, isTrue);
    expect(result.occurrences.length, 500);
    expect(result.occurrences.first.occurrenceKey, '2026-09-01T00:00');
  });

  test('performance: one week for 200 tasks (10 minutely) resolves quickly', () {
    final tasks = [
      for (var i = 0; i < 200; i++)
        Task(
          id: 'p$i',
          seriesId: 'p$i',
          title: 'Task $i',
          startLocal: LocalDateTime.of(2026, 9, 1, 6 + i % 12, (i * 7) % 60),
          durationMinutes: 30,
          timeZone: i.isEven ? null : 'Europe/Paris',
          recurrence: i < 10
              ? RecurrenceRule(
                  freq: Frequency.minutely,
                  interval: 5,
                  window: DailyWindow(LocalTime(9, 0), LocalTime(17, 0)),
                )
              : (i.isEven
                    ? RecurrenceRule()
                    : RecurrenceRule(
                        freq: Frequency.weekly,
                        byWeekday: const [WeekdayRule(Weekday.monday), WeekdayRule(Weekday.thursday)],
                      )),
        ),
    ];
    final watch = Stopwatch()..start();
    late ResolveResult result;
    for (var run = 0; run < 5; run++) {
      watch.reset();
      result = resolver.resolve(
        tasks: tasks,
        records: const [],
        from: LocalDateTime.of(2026, 9, 21),
        to: LocalDateTime.of(2026, 9, 28),
        viewerZone: 'Europe/Paris',
        now: DateTime.utc(2026, 9, 22),
      );
    }
    watch.stop();
    expect(result.occurrences, isNotEmpty);
    // Budget is 30 ms on a mid-range device; allow slack for CI/JIT.
    expect(watch.elapsedMilliseconds, lessThan(400), reason: '${watch.elapsedMilliseconds} ms');
    expect(
      estimateOccurrenceCount(tasks, LocalDateTime.of(2026, 9, 21), LocalDateTime.of(2026, 9, 28)),
      greaterThan(4000),
    );
  });
}

extension<T> on List<T> {
  List<T> ifEmpty(List<T> fallback) => this.isEmpty ? fallback : this;
}
