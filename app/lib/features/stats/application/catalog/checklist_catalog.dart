/// Checklist Insights catalog ([6.4]): per-item (CL-I-*), per-checklist (CL-L-*) and Lists section
/// (CL-X-*) metrics on top of the `everslot_metrics` flow calculators.
library;

import 'package:collection/collection.dart';
import 'package:everslot/features/stats/application/catalog/catalog_support.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/checklist_resolution.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/domain/zone_snapshot.dart';
import 'package:everslot_metrics/everslot_metrics.dart';

/// Batch context of the checklist scopes (item, checklist, checklists).
final class ChecklistContext extends StatsContext {
  ChecklistContext(super.job, super.resolver) : input = job.checklists ?? const ChecklistInput();

  final ChecklistInput input;

  @override
  late final DayBoundaries bounds = dayBoundariesOf(resolver, env.zoneId);

  late final ChecklistFacts data = ChecklistFacts(input, resolver: resolver, viewerZone: env.zoneId, now: now);

  late final Set<String> templateIds = {
    for (final c in input.checklists)
      if (c.isTemplate) c.id,
  };

  /// Section facts (template lists excluded).
  late final List<ChecklistItemFact> sectionFacts = [
    for (final f in data.facts)
      if (!templateIds.contains(f.checklistId)) f,
  ];

  // -- Checklist scope --------------------------------------------------------------------------

  String get checklistId => request.scope == MetricScope.checklistItem ? (item?.checklistId ?? '') : (scopeId ?? '');

  late final List<ChecklistItemFact> listFacts = data.factsOf(checklistId);
  late final List<ChecklistItemRow> listRows = data.rowsOf(checklistId);
  late final ChecklistRecord? list = data.listById(checklistId);

  int get staleDays => list?.staleAfterDays ?? settings.staleDays;

  // -- Item scope --------------------------------------------------------------------------------

  late final ChecklistItemFact? item = request.scope == MetricScope.checklistItem
      ? data.facts.firstWhereOrNull((f) => f.id == scopeId)
      : null;

  DrillRef itemRef(ChecklistItemFact f) =>
      DrillRef(DrillKind.item, f.checklistId, extra: f.id, title: f.row.text, subtitle: f.status.name);

  List<DrillRef> refs(Iterable<ChecklistItemFact> list, {int cap = 200}) => [
    for (final f in list.take(cap)) itemRef(f),
  ];

  /// Completion day series of a scope over the period (exact counts).
  List<SeriesPoint<double>> completionsIn(DateRange r, {String? checklistId}) => completionsPerDay(
    checklistId == null ? sectionFacts : listFacts,
    range: r,
    bounds: bounds,
    checklistId: checklistId,
  );
}

MetricResult _noItem(String id) => MetricResult.notApplicable(id, 'noItem');

T _withItem<T>(ChecklistContext c, T Function(ChecklistItemFact f) f, T Function() none) {
  final i = c.item;
  return i == null ? none() : f(i);
}

const _itemTables = {StatsTable.checklistItems, StatsTable.activityEvents};

/// List ranking (T6.4.17): most active (status events in the period), most blocked (blocked time
/// in the period) and stalest (days since the last activity of a list holding open items). Template
/// lists are left out; archived lists only count for activity.
({ListData active, ListData blocked, ListData stalest}) _listRanking(ChecklistContext c, {int top = 5}) {
  final window = c.instantsToNow(c.range);
  final listOf = {for (final f in c.sectionFacts) f.id: f.checklistId};
  DrillRef ref(String id) => DrillRef(DrillKind.checklist, id, title: c.data.listById(id)?.title);
  ChartLabel name(String id) => TextLabel(c.data.listById(id)?.title ?? '');
  final activity = <String, int>{};
  for (final e in c.data.events) {
    final list = listOf[e.entityId];
    if (list == null || !window.contains(e.occurredAt)) continue;
    activity[list] = (activity[list] ?? 0) + 1;
  }
  final active = activity.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final blocked = mostBlockedLists(c.sectionFacts, now: c.now, from: window.start, to: window.end);
  final archived = c.data.archivedListIds;
  final last = <String, DateTime>{};
  for (final f in c.sectionFacts) {
    if (f.isDeleted || archived.contains(f.checklistId)) continue;
    if (f.status == ItemStatus.completed || f.status == ItemStatus.cancelled) continue;
    final at = f.lastActivityAt;
    final cur = last[f.checklistId];
    if (cur == null || at.isAfter(cur)) last[f.checklistId] = at;
  }
  final stalest = last.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
  return (
    active: ListData([
      for (final e in active.take(top)) ListRow(name(e.key), value: e.value.toDouble(), ref: ref(e.key)),
    ], valueLabel: const TokenLabel(LabelToken.count)),
    blocked: ListData([
      for (final e in blocked.take(top))
        ListRow(name(e.checklistId), value: e.blocked.inSeconds / 60, unit: StatUnit.minutes, ref: ref(e.checklistId)),
    ], valueLabel: const TokenLabel(LabelToken.blocked)),
    stalest: ListData([
      for (final e in stalest.take(top))
        ListRow(name(e.key), value: c.now.difference(e.value).inMinutes / 1440, unit: StatUnit.days, ref: ref(e.key)),
    ], valueLabel: const TokenLabel(LabelToken.stale)),
  );
}

ChartTone statusTone(ItemStatus s) => switch (s) {
  ItemStatus.todo => ChartTone.todo,
  ItemStatus.ongoing => ChartTone.ongoing,
  ItemStatus.waiting => ChartTone.waiting,
  ItemStatus.blocked => ChartTone.blocked,
  ItemStatus.completed => ChartTone.completed,
  ItemStatus.cancelled => ChartTone.cancelled,
};

LabelToken statusToken(ItemStatus s) => switch (s) {
  ItemStatus.todo => LabelToken.todo,
  ItemStatus.ongoing => LabelToken.ongoing,
  ItemStatus.waiting => LabelToken.waiting,
  ItemStatus.blocked => LabelToken.blocked,
  ItemStatus.completed => LabelToken.completed,
  ItemStatus.cancelled => LabelToken.cancelled,
};

ItemStatus? _parseStatus(String s) => ItemStatus.values.firstWhereOrNull((x) => x.name == s);

/// Status donut of counts.
DonutData _statusDonut(Map<ItemStatus, int> counts) => DonutData([
  for (final s in ItemStatus.values)
    if ((counts[s] ?? 0) > 0)
      DonutSlice(TokenLabel(statusToken(s)), counts[s]!.toDouble(), color: ToneColor(statusTone(s)), drillKey: s.name),
]);

/// Every checklist metric.
final List<MetricDefinition> checklistMetrics = [
  // ---------------------------------------------------------------------------------------------
  // Per item (T6.4.02)
  // ---------------------------------------------------------------------------------------------
  metric<ChecklistContext>(
    id: 'CL-I-01',
    scope: MetricScope.checklistItem,
    unit: StatUnit.minutes,
    chart: ChartKind.statusTimeline,
    direction: MetricDirection.neutral,
    requires: _itemTables,
    compute: (c) => _withItem(c, (f) {
      final t = timeInStatus(f, now: c.now);
      final ordered = [
        for (final s in ItemStatus.values)
          if ((t[s] ?? Duration.zero) > Duration.zero) s,
      ];
      return result(
        'CL-I-01',
        Value<double>((t[f.status] ?? Duration.zero).inSeconds / 60),
        unit: StatUnit.minutes,
        args: {'status': f.status.name, for (final s in ordered) s.name: t[s]!.inSeconds / 60},
        chart: BarData(
          const [TokenLabel(LabelToken.current)],
          [
            for (final s in ordered)
              BarSeries(TokenLabel(statusToken(s)), [t[s]!.inSeconds / 60], color: ToneColor(statusTone(s))),
          ],
          layout: BarLayout.horizontal,
          unit: StatUnit.minutes,
        ),
      );
    }, () => _noItem('CL-I-01')),
  ),
  metric<ChecklistContext>(
    id: 'CL-I-02',
    scope: MetricScope.checklistItem,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    requires: _itemTables,
    compute: (c) => _withItem(c, (f) {
      final v = minutesOf(cycleTime(f));
      return result('CL-I-02', v, unit: StatUnit.minutes, note: v is NotApplicable<double> ? v.reasonKey : null);
    }, () => _noItem('CL-I-02')),
  ),
  metric<ChecklistContext>(
    id: 'CL-I-03',
    scope: MetricScope.checklistItem,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    requires: _itemTables,
    compute: (c) => _withItem(c, (f) {
      final v = minutesOf(leadTimeOf(f));
      return result('CL-I-03', v, unit: StatUnit.minutes, note: v is NotApplicable<double> ? v.reasonKey : null);
    }, () => _noItem('CL-I-03')),
  ),
  metric<ChecklistContext>(
    id: 'CL-I-04',
    scope: MetricScope.checklistItem,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    requires: _itemTables,
    compute: (c) => _withItem(c, (f) {
      final a = itemAge(f, now: c.now);
      return result(
        'CL-I-04',
        a.map((x) => x.age.inSeconds / 60),
        unit: StatUnit.minutes,
        args: {if (a.valueOrNull case final x?) 'kind': x.kind.name},
        note: a.hasValue ? null : 'closed',
      );
    }, () => _noItem('CL-I-04')),
  ),
  metric<ChecklistContext>(
    id: 'CL-I-05',
    scope: MetricScope.checklistItem,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    requires: {..._itemTables, StatsTable.attachments},
    compute: (c) => _withItem(
      c,
      (f) => result(
        'CL-I-05',
        Value<double>(staleness(f, now: c.now).inSeconds / 60),
        unit: StatUnit.minutes,
        args: {'lastActivity': f.lastActivityAt.toIso8601String(), 'staleDays': c.staleDays},
      ),
      () => _noItem('CL-I-05'),
    ),
  ),
  metric<ChecklistContext>(
    id: 'CL-I-06',
    scope: MetricScope.checklistItem,
    unit: StatUnit.percent,
    chart: ChartKind.ring,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: {StatsTable.checklistItems},
    compute: (c) => _withItem(c, (f) {
      final p = subtreeProgress(c.listRows, rootId: f.id);
      final value = p.descendants == 0
          ? Value<double>(f.status == ItemStatus.completed ? 1 : 0, sampleSize: 1)
          : p.leafBased;
      return result(
        'CL-I-06',
        value,
        unit: StatUnit.percent,
        chart: RingData([
          (const TokenLabel(LabelToken.completed), value.valueOr(0), const ToneColor(ChartTone.completed)),
        ], centerValue: value.valueOrNull),
        args: {'descendants': p.descendants, if (p.recursive.valueOrNull case final r?) 'recursive': r},
      );
    }, () => _noItem('CL-I-06')),
  ),
  metric<ChecklistContext>(
    id: 'CL-I-07',
    scope: MetricScope.checklistItem,
    unit: StatUnit.count,
    chart: ChartKind.statusTimeline,
    direction: MetricDirection.neutral,
    requires: _itemTables,
    compute: (c) => _withItem(c, (f) {
      final intervals = statusTimeline(f);
      final segments = [
        for (final i in intervals)
          if (_parseStatus(i.status) case final s?)
            TimeSpan(
              i.start,
              i.end ?? c.now,
              tone: statusTone(s),
              label: i.note == null || i.note!.isEmpty ? TokenLabel(statusToken(s)) : TextLabel(i.note!),
            ),
      ];
      return chartResult(
        'CL-I-07',
        StatusTimelineData(segments, now: c.now),
        value: Value<double>(f.statusChanges.toDouble()),
        args: {'reopens': f.reopens},
      );
    }, () => _noItem('CL-I-07')),
  ),

  // ---------------------------------------------------------------------------------------------
  // Checklist status & throughput (T6.4.04)
  // ---------------------------------------------------------------------------------------------
  metric<ChecklistContext>(
    id: 'CL-L-01',
    scope: MetricScope.checklist,
    unit: StatUnit.percent,
    chart: ChartKind.donut,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: {StatsTable.checklistItems},
    compute: (c) {
      final mix = statusMix(c.listRows);
      final byStatus = groupBy([
        for (final f in c.listFacts)
          if (!f.isDeleted && f.checklistId == c.checklistId) f,
      ], (f) => f.status.name);
      return result(
        'CL-L-01',
        mix.doneLeafBased,
        unit: StatUnit.percent,
        chart: _statusDonut(mix.counts),
        args: {
          if (mix.doneNodeBased.valueOrNull case final n?) 'nodeBased': n,
          for (final e in mix.counts.entries) e.key.name: e.value,
        },
        drill: {for (final e in byStatus.entries) e.key: c.refs(e.value)},
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-02',
    scope: MetricScope.checklist,
    unit: StatUnit.percent,
    chart: ChartKind.line,
    requires: _itemTables,
    compute: (c) {
      final points = progressOverTime(c.listFacts, range: c.elapsed, bounds: c.bounds, checklistId: c.checklistId);
      final leaves = progressOverTime(
        c.listFacts,
        range: c.elapsed,
        bounds: c.bounds,
        checklistId: c.checklistId,
        leavesOnly: true,
      );
      return result(
        'CL-L-02',
        maybe(points.lastOrNull?.value),
        unit: StatUnit.percent,
        chart: TimeSeriesData(
          [for (final p in points) p.bucket],
          [
            ChartSeries(const TokenLabel(LabelToken.items), [for (final p in points) p.value]),
            ChartSeries(
              const TokenLabel(LabelToken.completed),
              [for (final p in leaves) p.value],
              color: const SeriesColor(1),
              role: SeriesRole.previous,
            ),
          ],
          unit: StatUnit.percent,
        ),
        spark: sparkOf([for (final p in points) p.value]),
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-03',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.bars,
    requires: _itemTables,
    compute: (c) {
      final t = throughput(
        c.listFacts,
        range: c.range,
        bounds: c.bounds,
        checklistId: c.checklistId,
        weekStart: c.weekStart,
      );
      final cur = c.completionsIn(c.range, checklistId: c.checklistId).fold<double>(0, (a, p) => a + p.value);
      final prev = c.completionsIn(c.previous, checklistId: c.checklistId).fold<double>(0, (a, p) => a + p.value);
      // Items behind each weekly bar: their final completion falls in that week.
      final byWeek = <String, List<ChecklistItemFact>>{};
      for (final f in c.listFacts) {
        final done = f.done;
        if (done == null || f.isDeleted) continue;
        final d = c.bounds.dateOf(done);
        if (!c.range.contains(d)) continue;
        byWeek.putIfAbsent(d.startOfWeek(c.weekStart).toIso(), () => []).add(f);
      }
      return result(
        'CL-L-03',
        Value<double>(cur),
        previous: c.compare ? Value<double>(prev) : null,
        chart: BarData(
          [for (final p in t.weekly) DateLabel(p.bucket, Granularity.week)],
          [
            BarSeries(const TokenLabel(LabelToken.completed), [
              for (final p in t.weekly) p.value,
            ], color: const ToneColor(ChartTone.completed)),
          ],
          overlays: [BarOverlay(const TokenLabel(LabelToken.rollingMean), t.rolling4, color: const SeriesColor(1))],
          isTimeAxis: true,
          drillKeys: [for (final p in t.weekly) p.bucket.toIso()],
        ),
        spark: sparkOf([for (final p in t.weekly) p.value]),
        drill: {for (final e in byWeek.entries) e.key: c.refs(e.value)},
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-04',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.line,
    direction: MetricDirection.neutral,
    requires: _itemTables,
    compute: (c) {
      final w = wipPerDay(c.listFacts, range: c.elapsed, bounds: c.bounds, checklistId: c.checklistId);
      final current = c.listFacts.where((f) => !f.isDeleted && f.checklistId == c.checklistId && f.status.isWip).length;
      return result(
        'CL-L-04',
        Value<double>(current.toDouble()),
        chart: timeSeries([
          for (final p in w) SeriesPoint<double?>(p.bucket, p.value.toDouble()),
        ], label: const TokenLabel(LabelToken.wip)),
        spark: sparkOf([for (final p in w) p.value.toDouble()]),
        drill: {'wip': c.refs(c.listFacts.where((f) => !f.isDeleted && f.status.isWip))},
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-05',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.groupedBars,
    direction: MetricDirection.neutral,
    requires: _itemTables,
    compute: (c) => _arrivalsDepartures('CL-L-05', c, c.listFacts, c.checklistId),
  ),
  metric<ChecklistContext>(
    id: 'CL-L-06',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.lowerIsBetter,
    requires: _itemTables,
    compute: (c) {
      final live = [
        for (final f in c.listFacts)
          if (f.checklistId == c.checklistId) f,
      ];
      final s = staleItems(live, now: c.now, staleDays: c.staleDays);
      return result(
        'CL-L-06',
        Value<double>(s.stale.length.toDouble()),
        chart: ListData([
          for (final (f, age) in s.oldest)
            ListRow(
              TextLabel(f.row.text),
              value: age.inSeconds / 60,
              unit: StatUnit.minutes,
              ref: c.itemRef(f),
              tone: statusTone(f.status),
            ),
        ], valueLabel: const TokenLabel(LabelToken.count)),
        args: {'staleDays': c.staleDays},
        drill: {'stale': c.refs(s.stale)},
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Lists section (T6.4.12)
  // ---------------------------------------------------------------------------------------------
  metric<ChecklistContext>(
    id: 'CL-X-01',
    scope: MetricScope.checklists,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    requires: {StatsTable.checklists, StatsTable.checklistItems},
    compute: (c) {
      final o = listsOverview(c.data.lists, c.data.facts, now: c.now, staleDays: c.settings.staleDays);
      final ranking = _listRanking(c);
      return chartResult(
        'CL-X-01',
        ChartGroup([
          (
            const TokenLabel(LabelToken.summary),
            TilesData([
              ValueTile(const TokenLabel(LabelToken.lists), o.total.toDouble(), StatUnit.count),
              ValueTile(const TokenLabel(LabelToken.inProgress), o.active.toDouble(), StatUnit.count),
              ValueTile(const TokenLabel(LabelToken.archived), o.archived.toDouble(), StatUnit.count),
              ValueTile(const TokenLabel(LabelToken.templates), o.templates.toDouble(), StatUnit.count),
              ValueTile(
                const TokenLabel(LabelToken.stale),
                o.staleListIds.length.toDouble(),
                StatUnit.count,
                drillKey: 'stale',
              ),
            ]),
          ),
          // List ranking of the Lists screen (T6.4.17).
          (const TokenLabel(LabelToken.mostActive), ranking.active),
          (const TokenLabel(LabelToken.mostBlocked), ranking.blocked),
          (const TokenLabel(LabelToken.stalest), ranking.stalest),
        ]),
        value: Value<double>(o.active.toDouble()),
        args: {'staleDays': c.settings.staleDays},
        drill: {
          'stale': [
            for (final id in o.staleListIds) DrillRef(DrillKind.checklist, id, title: c.data.listById(id)?.title),
          ],
        },
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-X-02',
    scope: MetricScope.checklists,
    unit: StatUnit.count,
    chart: ChartKind.groupedBars,
    direction: MetricDirection.neutral,
    requires: _itemTables,
    compute: (c) => _arrivalsDepartures('CL-X-02', c, c.sectionFacts, null),
  ),
  metric<ChecklistContext>(
    id: 'CL-X-03',
    scope: MetricScope.checklists,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    requires: _itemTables,
    compute: (c) {
      final g = globalWip(c.sectionFacts, now: c.now, archivedListIds: c.data.archivedListIds);
      final live = [
        for (final f in c.sectionFacts)
          if (!f.isDeleted && !c.data.archivedListIds.contains(f.checklistId)) f,
      ];
      return result(
        'CL-X-03',
        Value<double>(g.wip.toDouble()),
        chart: ListData([
          for (final (f, age) in g.oldest)
            ListRow(
              TextLabel(f.row.text),
              value: age.inSeconds / 60,
              unit: StatUnit.minutes,
              ref: c.itemRef(f),
              tone: statusTone(f.status),
            ),
        ]),
        args: {'blocked': g.blocked, 'waiting': g.waiting, 'wip': g.wip},
        drill: {
          'wip': c.refs(live.where((f) => f.status.isWip)),
          'blocked': c.refs(live.where((f) => f.status == ItemStatus.blocked)),
          'waiting': c.refs(live.where((f) => f.status == ItemStatus.waiting)),
        },
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-X-04',
    scope: MetricScope.checklists,
    unit: StatUnit.count,
    chart: ChartKind.kpi,
    requires: _itemTables,
    compute: (c) {
      final cmp = itemsCompleted(c.data.facts, period: c.instantsToNow(c.elapsed), previous: c.instants(c.previous));
      final daily = c.completionsIn(c.elapsed);
      return MetricResult(
        'CL-X-04',
        value: cmp.current,
        previous: c.compare ? cmp.previous : null,
        comparison: c.compare ? cmp : null,
        spark: sparkOf([for (final p in daily) p.value]),
        chart: BarData(
          [for (final p in daily) DateLabel(p.bucket)],
          [
            BarSeries(const TokenLabel(LabelToken.completed), [
              for (final p in daily) p.value,
            ], color: const ToneColor(ChartTone.completed)),
          ],
          drillKeys: [for (final p in daily) p.bucket.toIso()],
          isTimeAxis: true,
        ),
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-X-05',
    scope: MetricScope.checklists,
    unit: StatUnit.count,
    chart: ChartKind.percentBars,
    direction: MetricDirection.neutral,
    requires: {StatsTable.checklistItems},
    compute: (c) {
      final counts = statusDistribution(c.sectionFacts);
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      return result(
        'CL-X-05',
        total == 0 ? const NotApplicable<double>(Reasons.noData) : Value<double>(total.toDouble()),
        chart: BarData(
          const [TokenLabel(LabelToken.items)],
          [
            for (final s in ItemStatus.values)
              BarSeries(TokenLabel(statusToken(s)), [(counts[s] ?? 0).toDouble()], color: ToneColor(statusTone(s))),
          ],
          layout: BarLayout.percent,
        ),
        args: {for (final e in counts.entries) e.key.name: e.value},
      );
    },
  ),
];

MetricResult _arrivalsDepartures(String id, ChecklistContext c, List<ChecklistItemFact> facts, String? checklistId) {
  final a = arrivalsVsDepartures(
    facts,
    range: c.range,
    bounds: c.bounds,
    checklistId: checklistId,
    weekStart: c.weekStart,
  );
  final net = a.net.fold<double>(0, (s, p) => s + p.value);
  return result(
    id,
    Value<double>(net),
    chart: BarData(
      [for (final p in a.arrivals) DateLabel(p.bucket, Granularity.week)],
      [
        BarSeries(const TokenLabel(LabelToken.arrivals), [
          for (final p in a.arrivals) p.value,
        ], color: const SeriesColor(1)),
        BarSeries(const TokenLabel(LabelToken.departures), [
          for (final p in a.departures) p.value,
        ], color: const ToneColor(ChartTone.completed)),
      ],
      overlays: [
        BarOverlay(const TokenLabel(LabelToken.net), [for (final p in a.net) p.value], color: const SeriesColor(2)),
      ],
      isTimeAxis: true,
    ),
    args: {
      'arrivals': a.arrivals.fold<double>(0, (s, p) => s + p.value),
      'departures': a.departures.fold<double>(0, (s, p) => s + p.value),
    },
  );
}
