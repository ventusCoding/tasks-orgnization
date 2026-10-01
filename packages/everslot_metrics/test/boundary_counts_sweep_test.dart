// `boundaryCounts` samples many entities at many instants. For ascending samples it evaluates an
// entity only while it is still changing and adds the constant tail through difference arrays
// (T6.1.23); the numbers must equal the direct per-sample evaluation.
import 'dart:math' as math;

import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:test/test.dart';

/// The original per-sample definition (every entity at every instant).
List<BoundaryCounts> reference(List<EntityTimeline> list, List<DateTime> sampleAt, {String? containerId}) => [
  for (final t in sampleAt)
    () {
      var arrived = 0;
      var started = 0;
      var finished = 0;
      var cancelled = 0;
      var removed = 0;
      final byStatus = <String, int>{};
      final probe = t.subtract(const Duration(microseconds: 1));
      for (final e in list) {
        if (!e.createdAt.isBefore(t)) continue;
        if (!e.isAliveAt(probe)) {
          final deleted = e.deletedBefore(probe);
          if (deleted != null) {
            final before = deleted.subtract(const Duration(microseconds: 1));
            if (containerId == null || e.containerAt(before) == containerId) removed++;
          }
          continue;
        }
        if (containerId != null && e.containerAt(probe) != containerId) continue;
        arrived++;
        final state = e.stateAt(probe) ?? e.initialStatus;
        byStatus[state] = (byStatus[state] ?? 0) + 1;
        final left = e.firstExit('todo');
        if (e.initialStatus != 'todo' || (left != null && left.isBefore(t))) started++;
        if (state == 'completed') finished++;
        if (state == 'cancelled') cancelled++;
      }
      return BoundaryCounts(
        t,
        arrived: arrived,
        started: started,
        finished: finished,
        cancelled: cancelled,
        removed: removed,
        byStatus: byStatus,
      );
    }(),
];

void main() {
  final origin = DateTime.utc(2026, 1, 1);
  DateTime day(int d, [int hour = 9]) => origin.add(Duration(days: d, hours: hour));

  /// Random histories: creation, status changes, container moves, deletions and restores.
  List<StatusEvent> events(int seed, {int entities = 60, int days = 120}) {
    final random = math.Random(seed);
    const statuses = ['todo', 'ongoing', 'waiting', 'blocked', 'completed', 'cancelled'];
    final all = <StatusEvent>[];
    for (var n = 0; n < entities; n++) {
      final id = 'e$n';
      var at = random.nextInt(days - 20);
      var status = 'todo';
      all.add(StatusEvent(id, StatusEventType.created, occurredAt: day(at, random.nextInt(20)), to: status));
      var container = random.nextBool() ? 'A' : 'B';
      var deleted = false;
      final steps = random.nextInt(7);
      for (var s = 0; s < steps; s++) {
        at += random.nextInt(15);
        final when = day(at, random.nextInt(24)).add(Duration(minutes: random.nextInt(60)));
        switch (random.nextInt(10)) {
          case 0 || 1:
            if (!deleted) {
              all.add(StatusEvent(id, StatusEventType.deleted, occurredAt: when));
              deleted = true;
            }
          case 2:
            if (deleted) {
              all.add(StatusEvent(id, StatusEventType.restored, occurredAt: when));
              deleted = false;
            }
          case 3:
            final next = container == 'A' ? 'B' : 'A';
            all.add(
              StatusEvent(id, StatusEventType.moved, occurredAt: when, fromContainerId: container, toContainerId: next),
            );
            container = next;
          default:
            final to = statuses[random.nextInt(statuses.length)];
            if (to != status) {
              all.add(StatusEvent(id, StatusEventType.statusChanged, occurredAt: when, from: status, to: to));
              status = to;
            }
        }
      }
    }
    return all;
  }

  for (final seed in [1, 2, 3, 4]) {
    test('sweep = per-sample evaluation, whole set and per container (seed $seed)', () {
      final timelines = buildTimelines(events(seed)).values.toList();
      // Day-end instants, plus samples before the first event and far after the last one.
      final samples = [for (var d = -3; d < 150; d++) day(d, 23).add(const Duration(minutes: 59, seconds: 59))];
      for (final container in [null, 'A', 'B']) {
        final actual = boundaryCounts(timelines, samples, containerId: container);
        final expected = reference(timelines, samples, containerId: container);
        expect(actual, hasLength(samples.length));
        for (var i = 0; i < samples.length; i++) {
          final reason = 'seed $seed, container $container, sample $i';
          expect(actual[i].at, expected[i].at, reason: reason);
          expect(actual[i].arrived, expected[i].arrived, reason: reason);
          expect(actual[i].started, expected[i].started, reason: reason);
          expect(actual[i].finished, expected[i].finished, reason: reason);
          expect(actual[i].cancelled, expected[i].cancelled, reason: reason);
          expect(actual[i].removed, expected[i].removed, reason: reason);
          expect(actual[i].byStatus, expected[i].byStatus, reason: reason);
        }
      }
    });
  }

  test('samples exactly on an event instant exclude that event (next day)', () {
    final timelines = buildTimelines([
      for (var n = 0; n < 12; n++) ...[
        StatusEvent('e$n', StatusEventType.created, occurredAt: day(n), to: 'todo'),
        StatusEvent('e$n', StatusEventType.statusChanged, occurredAt: day(n + 2), from: 'todo', to: 'completed'),
      ],
    ]).values.toList();
    // Sample instants equal to the completion instants of e0…e5.
    final samples = [for (var n = 0; n < 8; n++) day(n + 2)];
    final actual = boundaryCounts(timelines, samples);
    final expected = reference(timelines, samples);
    for (var i = 0; i < samples.length; i++) {
      expect(actual[i].finished, expected[i].finished, reason: 'sample $i');
      expect(actual[i].arrived, expected[i].arrived, reason: 'sample $i');
    }
  });

  test('unordered samples fall back to the direct evaluation', () {
    final timelines = buildTimelines(events(7)).values.toList();
    final samples = [day(50), day(10), day(90), day(30), day(70), day(20)];
    final actual = boundaryCounts(timelines, samples);
    final expected = reference(timelines, samples);
    for (var i = 0; i < samples.length; i++) {
      expect(actual[i].arrived, expected[i].arrived);
      expect(actual[i].byStatus, expected[i].byStatus);
    }
  });
}
