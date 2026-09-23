import 'dart:math' as math;

import 'package:everslot_metrics/src/checklist_metrics.dart';
import 'package:everslot_metrics/src/forecast.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/status_intervals.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:test/test.dart';

import 'support/support.dart';

final ZoneClock paris = tzClock('Europe/Paris');
final DayBoundaries bounds = DayBoundaries(paris);

StatusEvent eventFrom(Map<String, Object?> e) => StatusEvent(
  e['item']! as String,
  StatusEventType.values.byName(e['type']! as String),
  occurredAt: at(paris, e['at']! as String),
  from: e['from'] as String?,
  to: e['to'] as String?,
  note: e['note'] as String?,
  fromContainerId: e['fromContainer'] as String?,
  toContainerId: e['toContainer'] as String?,
);

List<StatusEvent> eventsOf(Object? list) =>
    [for (final e in (list! as List).cast<Map<String, Object?>>()) eventFrom(e)];

ChecklistItemRow row(
  String id, {
  String checklist = 'L',
  ItemStatus status = ItemStatus.todo,
  String? parent,
  String created = '2026-09-01T09:00',
  String? deleted,
  String? due,
  String? followUp,
  String? waitingOn,
  String? note,
}) => ChecklistItemRow(
  id,
  checklistId: checklist,
  status: status,
  createdAt: at(paris, created),
  parentId: parent,
  deletedAt: deleted == null ? null : at(paris, deleted),
  dueAt: due == null ? null : at(paris, due),
  followUpAt: followUp == null ? null : at(paris, followUp),
  waitingOn: waitingOn,
  statusNote: note,
);

double hours(Duration d) => d.inSeconds / 3600;

void main() {
  final fixture = loadFixture('checklist_flow_small');

  group('T6.4.02 item (checklist_flow_small)', () {
    final item = fixture['item']! as Map<String, Object?>;
    final e = item['expect']! as Map<String, Object?>;
    final facts = buildChecklistItemFacts(
      [row('X', checklist: 'L0', status: ItemStatus.completed)],
      eventsOf(item['events']),
    );
    final x = facts.single;
    final now = at(paris, '2026-09-10T00:00');

    test('CL-I-01…03 time in status, CT, LT', () {
      expect(hours(leadTimeOf(x).valueOrNull!), e['leadTimeHours']);
      expect(hours(cycleTime(x).valueOrNull!), e['cycleTimeHours']);
      final tis = timeInStatus(x, now: x.done!);
      final expected = e['timeInStatusHours']! as Map<String, Object?>;
      for (final entry in expected.entries) {
        expect(hours(tis[ItemStatus.parse(entry.key)]!), entry.value, reason: entry.key);
      }
      expect(statusTimeline(x).length, 7);
      expect(itemAge(x, now: now).hasValue, isFalse);
    });

    test('CL-I-08…12 blocked share, flow efficiency, churn', () {
      expect(flowEfficiency(x).valueOrNull, near(e['flowEfficiency']! as num));
      final blocked = blockedEpisodes(x, now: now);
      expect(blocked.shareOfCycleTime.valueOrNull, near(e['blockedShare']! as num));
      expect(blocked.episodes.reasons, ['supplier invoice missing']);
      final c = churn(x);
      expect(c.statusChanges, e['statusChanges']);
      expect(c.reopens, e['reopens']);
      expect(c.ongoingWaitingLoops, e['ongoingWaitingLoops']);
      expect(hours(timeToFirstAction(x).valueOrNull!), e['timeToFirstActionHours']);
      final waiting = waitingEpisodes(x, now: now);
      expect(waiting.episodes.count, 1);
      expect(waiting.episodes.total, const Duration(days: 2));
      expect(waiting.followUpOverdue, isFalse);
    });
  });

  group('T6.4.05 CFD (checklist_flow_small)', () {
    final cfd = fixture['cfd']! as Map<String, Object?>;
    final e = cfd['expect']! as Map<String, Object?>;
    final days = [for (final s in (cfd['days']! as List).cast<String>()) d(s)];
    final range = DateRange(days.first, days.last);
    final rows = [
      for (final r in (cfd['rows']! as List).cast<Map<String, Object?>>())
        row(
          r['id']! as String,
          checklist: 'L1',
          status: ItemStatus.parse(r['status']! as String),
          deleted: r['deleted'] as String?,
        ),
    ];
    final facts = buildChecklistItemFacts(rows, eventsOf(cfd['events']));
    final flow = cumulativeFlow(facts, range: range, bounds: bounds, checklistId: 'L1');
    final order = (e['bandOrder']! as List).cast<String>().map(ItemStatus.parse).toList();

    test('bands, boundary lines, reopens', () {
      expect(
        [
          for (final day in flow.days) [for (final s in order) day.bands[s]],
        ],
        e['bands'],
      );
      expect(flow.reopens, e['reopens']);
      expect(flow.days.map((x) => x.arrived), e['arrived']);
      expect(flow.days.map((x) => x.started), e['started']);
      expect(flow.days.map((x) => x.finished), e['finished']);
      expect(flow.wipAt(2), 3);
      expect(flow.approxCycleTimeDays(4), 3);
      expect(flow.approxCycleTimeDays(0), isNull);
      expect(flow.throughputSlope().valueOrNull, isNotNull);
      final burn = burnChart(facts, range: range, bounds: bounds, checklistId: 'L1', due: days[6]);
      expect(burn.removed, e['removed']);
      expect(burn.remaining, [3, 3, 4, 3, 2, 2, 2]);
      expect(burn.scope, e['arrived']);
      expect(burn.ideal!.first, 3);
      expect(burn.ideal!.last, 0);
      final withCancelled = cumulativeFlow(
        facts,
        range: range,
        bounds: bounds,
        includeCancelled: true,
      );
      expect(withCancelled.days.first.bands[ItemStatus.cancelled], 0);
    });

    test('time in status with reopen and deletion (T6.1.11)', () {
      final now = at(paris, e['now']! as String);
      Map<String, double> tis(String id) => {
        for (final x in timeInStatus(facts.firstWhere((f) => f.id == id), now: now).entries)
          x.key.name: hours(x.value),
      };
      expect(tis('A'), (e['timeInStatusHoursA']! as Map).cast<String, num>());
      expect(tis('D'), (e['timeInStatusHoursD']! as Map).cast<String, num>());
    });

    test('throughput counts the final completion only; WIP; progress', () {
      final perDay = completionsPerDay(facts, range: range, bounds: bounds, checklistId: 'L1');
      expect(perDay.map((p) => p.value), e['throughputCompletedByDay']);
      final weekly = throughput(facts, range: range, bounds: bounds);
      expect(weekly.weekly.fold<double>(0, (a, p) => a + p.value), 2);
      final wip = wipPerDay(facts, range: range, bounds: bounds, checklistId: 'L1');
      expect(wip.map((p) => p.value), [1, 1, 3, 2, 1, 1, 1]);
      final progress = progressOverTime(facts, range: range, bounds: bounds, checklistId: 'L1');
      expect(progress[4].value, near(0.5));
      final leaves = progressOverTime(facts, range: range, bounds: bounds, leavesOnly: true);
      expect(leaves.first.value, 0);
      final streak = completionDayStreak(perDay, today: days.last);
      expect(streak.bestLength, 2);
      expect(streak.currentLength, 0);
    });

    test('waiting-for register groups "waiting for Sam" and "@sam invoice"', () {
      final item = fixture['item']! as Map<String, Object?>;
      final x = buildChecklistItemFacts(
        [row('X', checklist: 'L0', status: ItemStatus.completed)],
        eventsOf(item['events']),
      );
      final register = waitingForRegister([...x, ...facts], now: at(paris, '2026-09-06T00:00'));
      final groups = (e['waitingForGroups']! as Map).cast<String, int>();
      final sam = register.firstWhere((r) => r.entity == 'Sam');
      expect(sam.openCount + 1, groups['Sam']);
      expect(sam.longestCurrentWait, const Duration(hours: 13));
      final reasons = reasonsPareto(facts, now: at(paris, '2026-09-06T00:00'));
      expect(reasons.map((r) => r.label), ['Supplier', 'Sam invoice']);
    });

    test('moves split membership (arrivals on the move day)', () {
      final move = fixture['move']! as Map<String, Object?>;
      final me = move['expect']! as Map<String, Object?>;
      final moved = buildChecklistItemFacts(
        [row('M', checklist: 'L3', created: '2026-09-02T10:00')],
        eventsOf(move['events']),
      );
      final r5 = DateRange(days.first, days[4]);
      int arrivedIn(String list, int i) =>
          dailyCounts(moved, range: r5, bounds: bounds, checklistId: list)[i].arrived;
      expect([for (var i = 0; i < 5; i++) arrivedIn('L2', i)], me['L2arrived']);
      expect([for (var i = 0; i < 5; i++) arrivedIn('L3', i)], me['L3arrived']);
      final flows = arrivalsVsDepartures(moved, range: r5, bounds: bounds, checklistId: 'L3');
      expect(flows.arrivals.single.value, 1);
      expect(flows.net.single.value, 1);
      expect(arrivalInstants(moved), [at(paris, '2026-09-02T10:00')]);
    });
  });

  test('CL-L-12 scope creep: 3 items added to a 10-item list = 30 %', () {
    final rows = [
      for (var i = 0; i < 13; i++)
        row('i$i', created: i < 10 ? '2026-09-01T09:00' : '2026-09-03T09:00'),
    ];
    final events = [
      StatusEvent(
        'i0',
        StatusEventType.statusChanged,
        occurredAt: at(paris, '2026-09-02T09:00'),
        from: 'todo',
        to: 'ongoing',
      ),
    ];
    final facts = buildChecklistItemFacts(rows, events);
    expect(scopeCreep(facts).valueOrNull, near(0.3));
    expect(scopeCreep(facts, baseline: at(paris, '2026-09-04T00:00')).valueOrNull, 0);
    expect(scopeCreep(buildChecklistItemFacts([row('z')], const [])), isA<NotApplicable<double>>());
    final burn = burnChart(
      facts,
      range: DateRange(d('2026-09-01'), d('2026-09-04')),
      bounds: bounds,
    );
    expect(burn.scope, [10, 10, 13, 13]);
  });

  group('checklist_runs_week (T6.4.11)', () {
    final runsFixture = loadFixture('checklist_runs_week');
    final e = runsFixture['expect']! as Map<String, Object?>;
    final runs = [
      for (final r in (runsFixture['runs']! as List).cast<Map<String, Object?>>())
        ChecklistRunFact(
          r['key']! as String,
          date: d(r['date']! as String),
          startedAt: at(paris, r['startedAt']! as String),
          totalItems: r['total']! as int,
          completedItems: r['completed']! as int,
          snapshot: [
            for (final s in (r['snapshot']! as List).cast<Map<String, Object?>>())
              RunItemSnapshot(
                s['item']! as String,
                status: ItemStatus.parse(s['status']! as String),
                completedAt: s['completedAt'] == null ? null : at(paris, s['completedAt']! as String),
              ),
          ],
        ),
    ];
    test('CL-L-20…24', () {
      expect(runCompletion(runs).mean.valueOrNull, near(e['meanCompletion']! as num));
      final streak = fullyCompletedRunStreak(runs);
      expect(streak.bestLength, e['bestStreak']);
      expect(streak.currentLength, e['currentStreak']);
      final finish = timeToFinishRun(runs);
      expect(finish.median.valueOrNull, e['medianFinishMinutes']);
      expect(finish.p85, isA<Insufficient<double>>());
      expect(
        [
          for (final m in mostSkippedItems(runs)) [m.itemId, m.missed],
        ],
        e['mostSkipped'],
      );
      final byWeekday = runCompletionByWeekday(runs);
      expect(byWeekday[Weekday.wednesday]!.valueOrNull, near(0.8));
      expect(byWeekday[Weekday.sunday]!.valueOrNull, near(0.6));
    });
  });

  group('checklist_tree_deep (T6.4.09)', () {
    final treeFixture = loadFixture('checklist_tree_deep');
    final e = treeFixture['expect']! as Map<String, Object?>;
    final rows = [
      for (final r in (treeFixture['rows']! as List).cast<Map<String, Object?>>())
        row(
          r['id']! as String,
          status: ItemStatus.parse(r['status']! as String),
          parent: r['parent'] as String?,
        ),
    ];
    test('shape and integrity', () {
      final shape = treeShape(rows);
      expect(shape.maxDepth, e['maxDepth']);
      expect(shape.leaves, e['leaves']);
      expect(shape.widestLevel, e['widestLevel']);
      expect(shape.widestLevelSize, e['widestLevelSize']);
      expect(shape.largestSubtree, e['largestSubtree']);
      expect(shape.meanBranchingFactor, near(2));
      final flags = integrityFlags(rows, requireReasonFor: const {ItemStatus.blocked});
      expect(
        [
          for (final (id, flag) in flags) [id, flag.name],
        ],
        e['flags'],
      );
      final facts = buildChecklistItemFacts(rows, const []);
      final levels = depthLevelProgress(facts);
      expect(levels.length, 12);
      expect(levels[1]!.valueOrNull, near(2 / 4));
      final progress = subtreeProgress(rows, rootId: 'p');
      expect(progress.leafBased.valueOrNull, 1);
      expect(progress.recursive.valueOrNull, 1);
      expect(progress.descendants, 2);
      final branches = branchContribution(
        rows,
        facts,
        now: at(paris, '2026-09-10T00:00'),
        from: at(paris, '2026-09-01T00:00'),
        to: at(paris, '2026-09-10T00:00'),
      );
      expect(branches['p']!.progress.valueOrNull, 1);
      expect(branches['b']!.progress.valueOrNull, 0);
      final mix = statusMix(rows);
      expect(mix.counts[ItemStatus.completed], 9);
      expect(mix.doneNodeBased.valueOrNull, near(9 / 28));
      expect(statusDistribution(facts)[ItemStatus.blocked], 1);
    });
  });

  group('section & item analytics', () {
    final now = at(paris, '2026-09-20T12:00');
    final rows = [
      row('a', checklist: 'L1', status: ItemStatus.ongoing, created: '2026-09-01T09:00'),
      row(
        'w',
        checklist: 'L1',
        status: ItemStatus.waiting,
        followUp: '2026-09-15T09:00',
        waitingOn: 'Alice',
        due: '2026-09-18T18:00',
      ),
      row('t', checklist: 'L2', created: '2026-09-18T09:00'),
      row(
        'c',
        checklist: 'L2',
        status: ItemStatus.completed,
        due: '2026-09-05T18:00',
      ),
      row('late', checklist: 'L2', status: ItemStatus.completed, due: '2026-09-03T18:00'),
      row('x', checklist: 'L2', status: ItemStatus.cancelled),
      row('gone', checklist: 'L2', deleted: '2026-09-02T09:00'),
    ];
    StatusEvent change(String id, String at_, String from, String to, [String? note]) => StatusEvent(
      id,
      StatusEventType.statusChanged,
      occurredAt: at(paris, at_),
      from: from,
      to: to,
      note: note,
    );
    final events = [
      change('a', '2026-09-02T09:00', 'todo', 'ongoing'),
      change('a', '2026-09-03T09:00', 'ongoing', 'blocked', 'Waiting on the supplier'),
      change('a', '2026-09-04T09:00', 'blocked', 'ongoing'),
      change('w', '2026-09-10T09:00', 'todo', 'waiting', 'waiting for alice'),
      change('c', '2026-09-04T09:00', 'todo', 'completed'),
      change('late', '2026-09-02T09:00', 'todo', 'ongoing'),
      change('late', '2026-09-04T09:00', 'ongoing', 'completed'),
      change('x', '2026-09-03T09:00', 'todo', 'cancelled'),
      StatusEvent('gone', StatusEventType.deleted, occurredAt: at(paris, '2026-09-02T09:00')),
    ];
    final facts = buildChecklistItemFacts(
      rows,
      events,
      extraActivity: {'t': at(paris, '2026-09-19T09:00')},
    );
    ChecklistItemFact f(String id) => facts.firstWhere((x) => x.id == id);

    test('ages, staleness, stale lists, WIP', () {
      expect(itemAge(f('a'), now: now).valueOrNull!.kind, ItemAgeKind.workItem);
      expect(itemAge(f('t'), now: now).valueOrNull!.kind, ItemAgeKind.queue);
      expect(staleness(f('t'), now: now), const Duration(days: 1, hours: 3));
      final stale = staleItems(facts, now: now);
      expect(stale.stale.map((x) => x.id), ['a']);
      expect(stale.oldest.first.$1.id, 'a');
      final lists = listsOverview(
        [
          ChecklistRow('L1', createdAt: at(paris, '2026-09-01T08:00')),
          ChecklistRow('L2', createdAt: at(paris, '2026-09-01T08:00')),
          ChecklistRow('L3', createdAt: at(paris, '2026-09-01T08:00'), archivedAt: now),
          ChecklistRow('T', createdAt: at(paris, '2026-09-01T08:00'), isTemplate: true),
        ],
        facts,
        now: now,
        staleDays: 7,
      );
      expect(lists.total, 4);
      expect(lists.active, 2);
      expect(lists.archived, 1);
      expect(lists.templates, 1);
      expect(lists.staleListIds, ['L1']);
      final wip = globalWip(facts, now: now, archivedListIds: const {'L2'});
      expect(wip.wip, 2);
      expect(wip.waiting, 1);
      expect(wip.blocked, 0);
      final creation = listCreationTrend(
        [ChecklistRow('L3', createdAt: at(paris, '2026-09-01T08:00'), archivedAt: now)],
        range: DateRange(d('2026-09-01'), d('2026-09-30')),
        bounds: bounds,
      );
      expect(creation.created.single.value, 1);
      expect(creation.archived.single.value, 1);
    });

    test('blocked & waiting, follow-ups, register, most blocked lists', () {
      final from = at(paris, '2026-09-01T00:00');
      final bw = blockedAndWaitingNow(facts, now: now, from: from, to: now);
      expect(bw.blocked, 0);
      expect(bw.waiting, 1);
      expect(bw.blockedTimeInPeriod, const Duration(days: 1));
      expect(bw.topReasons.map((r) => r.label), ['Alice', 'Supplier']);
      final follow = followUpDiscipline(facts, now: now);
      expect(follow.overdue.map((x) => x.id), ['w']);
      expect(follow.onTimeRate.valueOrNull, 0);
      final register = waitingForRegister(facts, now: now);
      expect(register.single.entity, 'Alice');
      expect(register.single.overdueFollowUps, 1);
      expect(waitingEpisodes(f('w'), now: now).followUpOverdue, isTrue);
      expect(mostBlockedLists(facts, now: now, from: from, to: now).single.checklistId, 'L1');
      expect(blockerClusters(facts, now: now).single.label, 'Supplier');
      expect(
        reasonsPareto(facts, now: now, merges: const {'supplier': 'Vendors'}).map((r) => r.label),
        contains('Vendors'),
      );
    });

    test('due dates, cancelled/shortcut shares, CT distribution, aging, forecast', () {
      final due = dueDatePerformance(facts, now: now);
      expect(due.onTimeRate.valueOrNull, near(0.5));
      expect(due.openOverdue.single.$1.id, 'w');
      expect(due.meanDaysLate.valueOrNull, near(15 / 24));
      final shares = cancelledAndShortcut(facts);
      expect(shares.cancelledShare.valueOrNull, near(1 / 6));
      expect(shares.shortcutShare.valueOrNull, near(0.5));
      final ct = cycleTimeDistribution(facts);
      expect(ct.hours, [48]);
      expect(ct.completedWithoutStart, 1);
      expect(ct.p85, isA<Insufficient<double>>());
      expect(serviceLevelExpectation(facts, now: now), isA<Insufficient<double>>());
      final aging = agingWip(facts, now: now, p85Hours: 24);
      expect(aging.map((p) => p.item.id), ['a', 'w']);
      expect(aging.every((p) => p.atRisk), isTrue);
      expect(cycleTimeUnitFor(const Duration(hours: 30)), CycleTimeUnit.hours);
      expect(cycleTimeUnitFor(const Duration(days: 3)), CycleTimeUnit.days);
      expect(inclusiveDays(at(paris, '2026-09-01T09:00'), at(paris, '2026-09-01T18:00'), bounds), 1);
      final forecast = checklistForecast(facts, now: now, bounds: bounds, random: math.Random(1));
      expect(forecast, isA<Insufficient<ForecastWhen>>());
      final items = itemsCompleted(
        facts,
        period: InstantRange(at(paris, '2026-09-01T00:00'), at(paris, '2026-09-08T00:00')),
        previous: InstantRange(at(paris, '2026-08-25T00:00'), at(paris, '2026-09-01T00:00')),
      );
      expect(items.current.valueOrNull, 2);
      expect(items.deltaPct, const NotApplicable<double>(Reasons.isNew));
      final bench = flowBenchmarks(
        facts,
        range: DateRange(d('2026-09-01'), d('2026-09-20')),
        bounds: bounds,
        random: math.Random(2),
      );
      expect(bench.p50, isA<Insufficient<double>>());
    });

    test('attachments, edits, Little law, waiting parser, normalization', () {
      final att = attachmentSummary(const [
        AttachmentFact('a', byteSize: 100, mimeType: 'image/png'),
        AttachmentFact('a', byteSize: 50, mimeType: 'application/pdf'),
        AttachmentFact('a', byteSize: 10, mimeType: 'text/plain'),
      ]);
      expect(att.count, 3);
      expect(att.totalBytes, 160);
      expect(att.byKind, {AttachmentKind.image: 1, AttachmentKind.pdf: 1, AttachmentKind.other: 1});
      final edits = editActivity([at(paris, '2026-09-01T09:00'), at(paris, '2026-09-03T09:00')]);
      expect(edits.edits, 2);
      expect(edits.lastEdited, at(paris, '2026-09-03T09:00'));
      final stable = littlesLawDiagnostic(
        cycleTimesDays: [2, 2, 2],
        dailyWip: [4, 4, 4],
        dailyThroughput: [2, 2, 2],
        arrivals: 10,
        departures: 10,
      );
      expect(stable.ratio.valueOrNull, near(1));
      expect(stable.flags, isEmpty);
      final unstable = littlesLawDiagnostic(
        cycleTimesDays: [6, 6],
        dailyWip: [4, 4],
        dailyThroughput: [2, 2],
        arrivals: 20,
        departures: 10,
        meanWipAgeByDay: [1, 2, 3, 4, 5, 6.1],
      );
      expect(unstable.flags, FlowInstability.values);
      expect(
        littlesLawDiagnostic(
          cycleTimesDays: const [],
          dailyWip: const [],
          dailyThroughput: const [],
          arrivals: 0,
          departures: 0,
        ).ratio,
        isA<NotApplicable<double>>(),
      );
      expect(waitingForEntity(note: 'en attente de Paul pour le devis'), 'paul');
      expect(waitingForEntity(note: 'بانتظار أحمد'), 'أحمد');
      expect(waitingForEntity(note: 'Bob: send keys'), 'bob');
      expect(waitingForEntity(note: 'no idea'), isNull);
      expect(waitingForEntity(), isNull);
      expect(normalizeReason('Waiting on the Suppliers!'), 'supplier');
      expect(normalizeReason('en attente des fournisseurs'), 'fournisseur');
      expect(normalizeReason('testing boxes started'), 'test box start');
    });
  });
}
