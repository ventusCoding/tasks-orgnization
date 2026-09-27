import 'package:everslot/core/providers.dart';
import 'package:everslot/features/planner/application/occurrence_range_service.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_settings.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../planner_test_support.dart';

/// Range pre-filter, caching, isolate execution, hard cap and diffs (T3.2.02).
void main() {
  late TestHarness h;
  setUp(() => h = plannerHarness(now: DateTime.utc(2026, 9, 22, 9)));
  tearDown(() => h.dispose());

  OccurrenceRangeService service({int isolateThreshold = 2000, int maxOccurrences = 20000}) {
    final s = OccurrenceRangeService(
      queries: h.read(plannerQueriesProvider),
      resolver: h.read(occurrenceResolverProvider),
      clock: h.read(clockProvider),
      viewerZone: 'UTC',
      isolateThreshold: isolateThreshold,
      settings: PlannerSettings(maxOccurrencesPerRange: maxOccurrences),
    );
    addTearDown(s.dispose);
    return s;
  }

  final from = ldt('2026-09-21T00:00');
  final to = ldt('2026-09-28T00:00');

  test('pre-filter loads only tasks that can reach the range', () async {
    final inWeek = await h.createTask(title: 'in week', start: '2026-09-23T10:00');
    final openSeries = await h.createTask(title: 'open series', start: '2025-01-06T08:00', rule: RecurrenceRule());
    final crossing = await h.createTask(title: 'long', start: '2026-09-20T20:00', duration: 8 * 60);
    await h.createTask(title: 'next year', start: '2027-09-23T10:00');
    await h.createTask(title: 'last month', start: '2026-08-10T10:00');
    await h.createTask(
      title: 'ended series',
      start: '2025-01-06T08:00',
      rule: RecurrenceRule(freq: Frequency.weekly, count: 3),
    );
    await h.createTask(title: 'backlog', duration: null);
    final data = await h.read(plannerQueriesProvider).loadRange(from, to);
    expect(data.tasks.map((t) => t.id), unorderedEquals([inWeek, openSeries, crossing]));
  });

  test('watchers share a cache keyed by the data version; writes invalidate it', () async {
    await h.createTask(title: 'Daily', start: '2026-09-01T08:00', rule: RecurrenceRule());
    final s = service();
    final emissions = <ResolvedRange>[];
    final sub = s.watchLocal(from, to).listen(emissions.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    expect(emissions, hasLength(1));
    expect(s.resolutions, 1);

    // A second resolution of the same range at the same data version is served from the cache.
    final cached = await s.resolveRange(from, to, useCache: true);
    expect(s.resolutions, 1);
    expect(cached.items, hasLength(7));

    await h.createTask(title: 'New', start: '2026-09-24T12:00');
    await pumpEventQueue();
    expect(s.resolutions, 2);
    expect(emissions.last.items, hasLength(8));
  });

  test('editing one task re-emits only that task; other items keep their instances', () async {
    final daily = await h.createTask(title: 'Daily', start: '2026-09-01T08:00', rule: RecurrenceRule());
    final other = await h.createTask(title: 'Other', start: '2026-09-24T12:00');
    final s = service();
    final emissions = <ResolvedRange>[];
    final sub = s.watchLocal(from, to).listen(emissions.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    await h.tasks.rescheduleTask(other, start: ldt('2026-09-24T15:00'), source: 'menu');
    await pumpEventQueue();
    expect(emissions, hasLength(2));
    final diff = diffItems(emissions.first.items, emissions.last.items);
    expect(diff.taskIds, {other});
    // A one-off's key is its start: the move is a remove + add.
    expect(diff.removed.single.startLocal, ldt('2026-09-24T12:00'));
    expect(diff.added.single.startLocal, ldt('2026-09-24T15:00'));
    expect(diff.changed, isEmpty);
    final before = {for (final i in emissions.first.items) i.key: i};
    for (final i in emissions.last.items.where((i) => i.taskId == daily)) {
      expect(identical(before[i.key], i), isTrue, reason: 'unchanged ${i.key} keeps its instance');
    }
  });

  test('a write that does not change the range does not re-emit', () async {
    await h.createTask(title: 'Daily', start: '2026-09-01T08:00', rule: RecurrenceRule());
    final s = service();
    final emissions = <ResolvedRange>[];
    final sub = s.watchLocal(from, to).listen(emissions.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await h.createTask(title: 'Far away', start: '2027-01-10T08:00');
    await pumpEventQueue();
    expect(emissions, hasLength(1));
  });

  test('heavy ranges resolve in an isolate with the same result', () async {
    await h.createTask(title: 'Water', start: '2026-09-01T08:00', duration: 1, rule: RecurrenceRule(freq: Frequency.minutely, interval: 5));
    final inline = await service(isolateThreshold: 1 << 30).resolveRange(from, to);
    final heavy = service(isolateThreshold: 100);
    final offloaded = await heavy.resolveRange(from, to);
    expect(heavy.isolateRuns, 1);
    expect(offloaded.items, hasLength(7 * 24 * 12));
    expect(offloaded.items.map((i) => i.key), inline.items.map((i) => i.key));
  });

  test('the hard cap truncates and flags the range', () async {
    await h.createTask(title: 'Tick', start: '2026-09-01T00:00', duration: 1, rule: RecurrenceRule(freq: Frequency.minutely));
    final range = await service(maxOccurrences: 1000).resolveRange(from, to);
    expect(range.truncated, isTrue);
    expect(range.items.length, lessThanOrEqualTo(1000));
    final small = await service(maxOccurrences: 1000).resolveRange(from, from.plusMinutes(600));
    expect(small.truncated, isFalse);
    expect(small.items, hasLength(600));
  });

  test('floating tasks follow the device zone; fixed tasks keep their instant', () async {
    await h.createTask(title: 'Floating', start: '2026-09-23T09:00');
    await h.createTask(title: 'Fixed', start: '2026-09-23T12:00', zone: 'UTC');
    final range = DayRange(ld('2026-09-23'), 1);
    PlannerItem byTitle(ResolvedRange r, String t) => r.items.firstWhere((i) => i.title == t);
    final before = await h.read(occurrenceRangeServiceProvider).watch(range).first;
    expect(byTitle(before, 'Floating').startUtc, DateTime.utc(2026, 9, 23, 9));
    h.read(deviceZoneProvider.notifier).debugSet('Asia/Tokyo');
    final after = await h.read(occurrenceRangeServiceProvider).watch(range).first;
    expect(byTitle(after, 'Floating').startLocal, ldt('2026-09-23T09:00'));
    expect(byTitle(after, 'Floating').startUtc, DateTime.utc(2026, 9, 23));
    expect(byTitle(after, 'Floating').timeZone, isNull);
    expect(byTitle(after, 'Fixed').startLocal, ldt('2026-09-23T21:00'));
    expect(byTitle(after, 'Fixed').startUtc, DateTime.utc(2026, 9, 23, 12));
  });

  test('item counts stay consistent with PlannerItem keys', () async {
    await h.createTask(title: 'A', start: '2026-09-22T08:00', rule: RecurrenceRule());
    final items = (await service().resolveRange(from, to)).items;
    expect(items.map((PlannerItem i) => i.key).toSet(), hasLength(items.length));
  });
}
