/// Checklist Insights catalog, P1/P2 part ([6.4]): blocked/waiting/churn per item (T6.4.03), CFD
/// (T6.4.05), cycle-time distribution, SLE and aging WIP (T6.4.06), burn charts and scope creep
/// (T6.4.07), blocker and waiting-for analytics (T6.4.08), tree shape and integrity (T6.4.09),
/// due-date performance (T6.4.10), recurring runs (T6.4.11), section benchmarks and calendars
/// (T6.4.13) and advanced flow analytics (T6.4.14). The math lives in `everslot_metrics`.
library;

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:everslot/features/stats/application/catalog/catalog_support.dart';
import 'package:everslot/features/stats/application/catalog/checklist_catalog.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;

const _items = {StatsTable.checklistItems, StatsTable.activityEvents};
const _runs = {StatsTable.checklistRuns};
const _attachments = {StatsTable.attachments, StatsTable.checklistItems};

MetricResult _noItem(String id) => MetricResult.notApplicable(id, 'noItem');

double _hours(Duration d) => d.inSeconds / 3600;

/// Item label of a fact (the item text).
ChartLabel _itemLabel(ChecklistItemFact f) => TextLabel(f.row.text);

ChartTone _toneOf(ItemStatus s) => statusTone(s);

/// Every CL-* metric of milestones M2/M3.
final List<MetricDefinition> checklistInsightMetrics = [
  // ---------------------------------------------------------------------------------------------
  // Per item: blocked, waiting & churn (T6.4.03), attachments & edits (T6.4.14)
  // ---------------------------------------------------------------------------------------------
  metric<ChecklistContext>(
    id: 'CL-I-08',
    scope: MetricScope.checklistItem,
    unit: StatUnit.hours,
    chart: ChartKind.list,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) {
      final f = c.item;
      if (f == null) return _noItem('CL-I-08');
      final b = blockedEpisodes(f, now: c.now);
      return result(
        'CL-I-08',
        Value<double>(_hours(b.episodes.total)),
        unit: StatUnit.hours,
        chart: b.episodes.count == 0
            ? null
            : ListData([
                for (final r in b.episodes.reasons) ListRow(TextLabel(r), tone: ChartTone.blocked),
                if (b.episodes.reasons.isEmpty)
                  const ListRow(TokenLabel(LabelToken.unspecified), tone: ChartTone.blocked),
              ]),
        args: {
          'episodes': b.episodes.count,
          if (b.shareOfCycleTime.valueOrNull case final s?) 'shareOfCycleTime': s,
          if (b.episodes.currentAge case final a?) 'currentHours': _hours(a),
        },
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-I-09',
    scope: MetricScope.checklistItem,
    unit: StatUnit.hours,
    chart: ChartKind.list,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) {
      final f = c.item;
      if (f == null) return _noItem('CL-I-09');
      final w = waitingEpisodes(f, now: c.now);
      return result(
        'CL-I-09',
        Value<double>(_hours(w.episodes.total)),
        unit: StatUnit.hours,
        chart: w.episodes.count == 0
            ? null
            : ListData([
                for (final r in w.episodes.reasons) ListRow(TextLabel(r), tone: ChartTone.waiting),
                if (w.followUpOverdue) const ListRow(TokenLabel(LabelToken.followUpOverdue), tone: ChartTone.warning),
              ]),
        args: {
          'episodes': w.episodes.count,
          'followUpOverdue': w.followUpOverdue,
          if (w.episodes.currentAge case final a?) 'currentHours': _hours(a),
        },
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-I-10',
    scope: MetricScope.checklistItem,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _items,
    compute: (c) {
      final f = c.item;
      if (f == null) return _noItem('CL-I-10');
      return result('CL-I-10', flowEfficiency(f), unit: StatUnit.percent, isRate: true);
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-I-11',
    scope: MetricScope.checklistItem,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) {
      final f = c.item;
      if (f == null) return _noItem('CL-I-11');
      final ch = churn(f);
      return result(
        'CL-I-11',
        countOf(ch.statusChanges),
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.statusChanges), ch.statusChanges.toDouble(), StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.reopened), ch.reopens.toDouble(), StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.loops), ch.ongoingWaitingLoops.toDouble(), StatUnit.count),
        ]),
        args: {'reopens': ch.reopens, 'loops': ch.ongoingWaitingLoops},
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-I-12',
    scope: MetricScope.checklistItem,
    unit: StatUnit.hours,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) {
      final f = c.item;
      if (f == null) return _noItem('CL-I-12');
      return result('CL-I-12', hoursOf(timeToFirstAction(f)), unit: StatUnit.hours);
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-I-13',
    scope: MetricScope.checklistItem,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    requires: _attachments,
    compute: (c) {
      final f = c.item;
      if (f == null) return _noItem('CL-I-13');
      final a = attachmentSummary(c.data.attachments.where((x) => x.ownerId == f.id));
      return _attachmentResult('CL-I-13', a);
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-I-14',
    scope: MetricScope.checklistItem,
    unit: StatUnit.count,
    chart: ChartKind.kpi,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    requires: _items,
    compute: (c) {
      final f = c.item;
      if (f == null) return _noItem('CL-I-14');
      final e = editActivity(c.data.textEdits[f.id] ?? const []);
      return result(
        'CL-I-14',
        countOf(e.edits),
        args: {if (e.lastEdited case final t?) 'lastEdited': t.toIso8601String()},
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Cumulative flow (T6.4.05)
  // ---------------------------------------------------------------------------------------------
  metric<ChecklistContext>(
    id: 'CL-L-07',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.cfd,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) {
      final cfd = cumulativeFlow(c.listFacts, range: c.elapsed, bounds: c.bounds, checklistId: c.checklistId);
      if (cfd.days.isEmpty) return const MetricResult.notApplicable('CL-L-07', Reasons.noData);
      return chartResult(
        'CL-L-07',
        cfdChart(cfd),
        value: countOf(cfd.wipAt(cfd.days.length - 1)),
        args: {
          'reopens': cfd.reopens,
          if (cfd.throughputSlope().valueOrNull case final t?) 'throughputPerDay': t,
          if (cfd.approxCycleTimeDays(cfd.days.length - 1) case final ct?) 'approxCycleTimeDays': ct,
        },
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Cycle-time distribution, SLE & aging WIP (T6.4.06)
  // ---------------------------------------------------------------------------------------------
  metric<ChecklistContext>(
    id: 'CL-L-08',
    scope: MetricScope.checklist,
    unit: StatUnit.hours,
    chart: ChartKind.histogram,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _items,
    compute: (c) {
      final period = c.instantsToNow(c.range);
      final d = cycleTimeDistribution(c.listFacts, completedFrom: period.start, completedTo: period.end);
      if (d.hours.isEmpty) {
        return result(
          'CL-L-08',
          const NotApplicable<double>(Reasons.noData),
          unit: StatUnit.hours,
          args: {'completedWithoutStart': d.completedWithoutStart},
        );
      }
      final lines = [
        for (final (stat, token) in [
          (d.p50, LabelToken.p50),
          (d.p70, LabelToken.p70),
          (d.p85, LabelToken.p85),
          (d.p95, LabelToken.p95),
        ])
          if (stat.valueOrNull case final v?) (v, TokenLabel(token) as ChartLabel),
      ];
      return result(
        'CL-L-08',
        d.p50,
        unit: StatUnit.hours,
        chart: ChartGroup([
          (
            const TokenLabel(LabelToken.count),
            histogramOf(
              d.histogram,
              unit: StatUnit.hours,
              markers: [
                for (final l in lines)
                  if (l.$2 == const TokenLabel(LabelToken.p50) || l.$2 == const TokenLabel(LabelToken.p85)) l,
              ],
            ),
          ),
          (
            const TokenLabel(LabelToken.cycleTime),
            ScatterData(
              [for (final (t, h) in d.scatter) ScatterPoint(c.bounds.dateOf(t).epochDay.toDouble(), h)],
              variant: ScatterVariant.byDate,
              xUnit: StatUnit.date,
              yUnit: StatUnit.hours,
              lines: lines,
            ),
          ),
        ]),
        args: {'completedWithoutStart': d.completedWithoutStart, if (d.p85.valueOrNull case final v?) 'p85': v},
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-09',
    scope: MetricScope.checklist,
    unit: StatUnit.hours,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _items,
    compute: (c) => result('CL-L-09', serviceLevelExpectation(c.listFacts, now: c.now), unit: StatUnit.hours),
  ),
  metric<ChecklistContext>(
    id: 'CL-L-10',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.scatter,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) {
      final d = cycleTimeDistribution(c.listFacts);
      final p85 = d.p85.valueOrNull;
      final points = agingWip(c.listFacts.where((f) => f.checklistId == c.checklistId), now: c.now, p85Hours: p85);
      if (points.isEmpty) return const MetricResult.notApplicable('CL-L-10', Reasons.noData);
      const columns = [ItemStatus.ongoing, ItemStatus.waiting, ItemStatus.blocked];
      return chartResult(
        'CL-L-10',
        ScatterData(
          [
            for (final p in points)
              ScatterPoint(
                0,
                _hours(p.age),
                column: columns.indexOf(p.status),
                highlight: p.atRisk,
                color: ToneColor(_toneOf(p.status)),
                ref: c.itemRef(p.item),
              ),
          ],
          variant: ScatterVariant.agingWip,
          xUnit: StatUnit.count,
          yUnit: StatUnit.hours,
          columns: [for (final s in columns) TokenLabel(statusToken(s))],
          lines: [
            if (d.p50.valueOrNull case final v?) (v, const TokenLabel(LabelToken.p50)),
            if (p85 != null) (p85, const TokenLabel(LabelToken.p85)),
          ],
        ),
        value: countOf(points.where((p) => p.atRisk).length),
        args: {'wip': points.length},
        drill: {'atRisk': c.refs(points.where((p) => p.atRisk).map((p) => p.item))},
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Burn charts & scope creep (T6.4.07)
  // ---------------------------------------------------------------------------------------------
  metric<ChecklistContext>(
    id: 'CL-L-11',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.burn,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) {
      final due = c.list?.dueLocal?.date;
      final b = burnChart(c.listFacts, range: c.elapsed, bounds: c.bounds, checklistId: c.checklistId, due: due);
      if (b.dates.isEmpty) return const MetricResult.notApplicable('CL-L-11', Reasons.noData);
      final cone = _forecastCone(c);
      return result(
        'CL-L-11',
        countOf(b.remaining.last),
        chart: TimeSeriesData(
          b.dates,
          [
            ChartSeries(const TokenLabel(LabelToken.remaining), [for (final v in b.remaining) v.toDouble()]),
            if (b.ideal case final ideal?)
              ChartSeries(
                const TokenLabel(LabelToken.ideal),
                ideal,
                color: const SeriesColor(1),
                role: SeriesRole.pace,
              ),
          ],
          step: true,
          cone: cone,
        ),
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-12',
    scope: MetricScope.checklist,
    unit: StatUnit.percent,
    chart: ChartKind.burn,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _items,
    compute: (c) {
      final b = burnChart(c.listFacts, range: c.elapsed, bounds: c.bounds, checklistId: c.checklistId);
      final creep = scopeCreep(c.listFacts, checklistId: c.checklistId);
      // Scope-increase markers list the items that arrived that day.
      final arrivedOn = <LocalDate, List<ChartLabel>>{};
      for (final f in c.listFacts) {
        for (final m in f.timeline.memberships) {
          if (m.containerId != c.checklistId) continue;
          arrivedOn.putIfAbsent(c.bounds.dateOf(m.start), () => []).add(_itemLabel(f));
        }
      }
      final annotations = <ChartAnnotation>[
        for (var i = 1; i < b.dates.length; i++)
          if (b.scope[i] > b.scope[i - 1])
            ChartAnnotation(
              i,
              const TokenLabel(LabelToken.scope),
              kind: AnnotationKind.scopeChange,
              details: arrivedOn[b.dates[i]] ?? const [],
            ),
      ];
      return result(
        'CL-L-12',
        creep,
        unit: StatUnit.percent,
        isRate: true,
        chart: b.dates.isEmpty
            ? null
            : TimeSeriesData(
                b.dates,
                [
                  ChartSeries(const TokenLabel(LabelToken.scope), [
                    for (final v in b.scope) v.toDouble(),
                  ], color: const ToneColor(ChartTone.warning)),
                  ChartSeries(const TokenLabel(LabelToken.done), [
                    for (final v in b.done) v.toDouble(),
                  ], color: const ToneColor(ChartTone.done)),
                ],
                step: true,
                annotations: annotations,
              ),
        args: {'removed': b.removed.isEmpty ? 0 : b.removed.last},
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-13',
    scope: MetricScope.checklist,
    unit: StatUnit.percent,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _items,
    compute: (c) {
      final s = cancelledAndShortcut(c.listFacts.where((f) => f.checklistId == c.checklistId));
      return result(
        'CL-L-13',
        s.cancelledShare,
        unit: StatUnit.percent,
        isRate: true,
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.cancelled), s.cancelledShare.valueOrNull, StatUnit.percent),
          ValueTile(const TokenLabel(LabelToken.shortcut), s.shortcutShare.valueOrNull, StatUnit.percent),
        ]),
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Blocked & waiting analytics (T6.4.08)
  // ---------------------------------------------------------------------------------------------
  metric<ChecklistContext>(
    id: 'CL-L-14',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) {
      final window = c.instantsToNow(c.range);
      final n = blockedAndWaitingNow(
        c.listFacts.where((f) => f.checklistId == c.checklistId),
        now: c.now,
        from: window.start,
        to: window.end,
      );
      return result(
        'CL-L-14',
        countOf(n.blocked + n.waiting),
        chart: n.ages.isEmpty
            ? null
            : ListData([
                for (final (f, age) in n.ages.sortedBy((a) => -a.$2.inSeconds).take(10))
                  ListRow(
                    _itemLabel(f),
                    value: _hours(age),
                    unit: StatUnit.hours,
                    tone: _toneOf(f.status),
                    secondary: TokenLabel(statusToken(f.status)),
                    ref: c.itemRef(f),
                  ),
              ]),
        args: {
          'blocked': n.blocked,
          'waiting': n.waiting,
          'blockedHoursInPeriod': _hours(n.blockedTimeInPeriod),
          'topReasons': [for (final r in n.topReasons.take(3)) r.label],
        },
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-15',
    scope: MetricScope.checklist,
    unit: StatUnit.percent,
    chart: ChartKind.list,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _items,
    compute: (c) {
      final d = followUpDiscipline(c.listFacts.where((f) => f.checklistId == c.checklistId), now: c.now);
      return result(
        'CL-L-15',
        d.onTimeRate,
        unit: StatUnit.percent,
        isRate: true,
        chart: d.overdue.isEmpty
            ? null
            : ListData([
                for (final f in d.overdue.take(10))
                  ListRow(
                    _itemLabel(f),
                    tone: ChartTone.warning,
                    ref: c.itemRef(f),
                    secondary: TokenLabel(statusToken(f.status)),
                  ),
              ]),
        args: {'overdue': d.overdue.length},
        drill: {'overdue': c.refs(d.overdue)},
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-X-06',
    scope: MetricScope.checklists,
    unit: StatUnit.count,
    chart: ChartKind.pareto,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) {
      final groups = reasonsPareto(c.sectionFacts, now: c.now, merges: c.settings.blockerClusters);
      if (groups.isEmpty) return const MetricResult.notApplicable('CL-X-06', Reasons.noData);
      return chartResult(
        'CL-X-06',
        ParetoData([
          for (final g in groups)
            (
              g.label == 'Unspecified' ? const TokenLabel(LabelToken.unspecified) : TextLabel(g.label),
              g.episodes.toDouble(),
            ),
        ]),
        value: countOf(groups.fold<int>(0, (a, g) => a + g.episodes)),
        args: {
          'hours': {for (final g in groups) g.label: _hours(g.total)},
        },
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-X-07',
    scope: MetricScope.checklists,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) {
      final reg = waitingForRegister(c.sectionFacts, now: c.now);
      if (reg.isEmpty) return const MetricResult.notApplicable('CL-X-07', Reasons.noData);
      return chartResult(
        'CL-X-07',
        ListData([
          for (final e in reg)
            ListRow(
              e.entity == 'Unspecified' ? const TokenLabel(LabelToken.unspecified) : TextLabel(e.entity),
              value: e.openCount.toDouble(),
              secondary: e.longestCurrentWait == null
                  ? null
                  : NumberLabel(_hours(e.longestCurrentWait!), StatUnit.hours),
              tone: e.overdueFollowUps > 0 ? ChartTone.warning : ChartTone.waiting,
            ),
        ], valueLabel: const TokenLabel(LabelToken.waiting)),
        value: countOf(reg.fold<int>(0, (a, e) => a + e.openCount)),
        args: {
          'entities': [
            for (final e in reg)
              {
                'entity': e.entity,
                'open': e.openCount,
                'meanWaitHours': _hours(e.meanWait),
                'overdueFollowUps': e.overdueFollowUps,
              },
          ],
        },
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-X-08',
    scope: MetricScope.checklists,
    unit: StatUnit.hours,
    chart: ChartKind.horizontalBars,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) {
      final window = c.instantsToNow(c.range);
      final ranked = mostBlockedLists(c.sectionFacts, now: c.now, from: window.start, to: window.end);
      if (ranked.isEmpty) return const MetricResult.notApplicable('CL-X-08', Reasons.noData);
      return chartResult(
        'CL-X-08',
        barsOf(
          [
            for (final e in ranked.take(10))
              (TextLabel(c.data.listById(e.checklistId)?.title ?? '') as ChartLabel, _hours(e.blocked)),
          ],
          seriesLabel: const TokenLabel(LabelToken.blocked),
          unit: StatUnit.hours,
          layout: BarLayout.horizontal,
          color: const ToneColor(ChartTone.blocked),
          drillKeys: [for (final e in ranked.take(10)) e.checklistId],
        ),
        unit: StatUnit.hours,
        value: Value<double>(_hours(ranked.fold(Duration.zero, (a, e) => a + e.blocked))),
        drill: {
          for (final e in ranked.take(10))
            e.checklistId: [DrillRef(DrillKind.checklist, e.checklistId, title: c.data.listById(e.checklistId)?.title)],
        },
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Tree shape, integrity, branches (T6.4.09)
  // ---------------------------------------------------------------------------------------------
  metric<ChecklistContext>(
    id: 'CL-L-16',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) {
      final rows = c.listRows.where((r) => r.deletedAt == null).toList();
      if (rows.isEmpty) return const MetricResult.notApplicable('CL-L-16', Reasons.noData);
      final t = treeShape(rows);
      return result(
        'CL-L-16',
        countOf(t.maxDepth),
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.maxDepth), t.maxDepth.toDouble(), StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.leafDepth), t.meanLeafDepth, StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.branching), t.meanBranchingFactor, StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.leaves), t.leaves.toDouble(), StatUnit.count),
          ValueTile(
            const TokenLabel(LabelToken.widestLevel),
            t.widestLevelSize.toDouble(),
            StatUnit.count,
            secondary: OrdinalLabel(OrdinalKind.depth, t.widestLevel),
          ),
          ValueTile(const TokenLabel(LabelToken.largestBranch), t.largestSubtree.toDouble(), StatUnit.count),
        ]),
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-17',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) {
      final rows = c.listRows.where((r) => r.deletedAt == null).toList();
      final require = {
        for (final s in c.list?.requireReasonFor ?? const <String>{})
          if (ItemStatus.values.firstWhereOrNull((x) => x.name == s) case final st?) st,
      };
      final flags = integrityFlags(rows, requireReasonFor: require);
      final byId = {for (final f in c.listFacts) f.id: f};
      return chartResult(
        'CL-L-17',
        ListData([
          for (final (id, flag) in flags.take(20))
            if (byId[id] case final f?)
              ListRow(
                _itemLabel(f),
                secondary: TokenLabel(switch (flag) {
                  IntegrityFlag.completedParentWithOpenDescendants => LabelToken.integrityOpenChildren,
                  IntegrityFlag.allChildrenDoneParentOpen => LabelToken.integrityParentOpen,
                  IntegrityFlag.missingReason => LabelToken.integrityMissingReason,
                }),
                tone: ChartTone.warning,
                ref: c.itemRef(f),
              ),
        ]),
        value: countOf(flags.length),
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-18',
    scope: MetricScope.checklist,
    unit: StatUnit.percent,
    chart: ChartKind.horizontalBars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _items,
    compute: (c) {
      final window = c.instantsToNow(c.range);
      final rows = c.listRows.where((r) => r.deletedAt == null).toList();
      final branches = branchContribution(rows, c.listFacts, now: c.now, from: window.start, to: window.end);
      if (branches.isEmpty) return const MetricResult.notApplicable('CL-L-18', Reasons.noData);
      final byId = {for (final r in rows) r.id: r};
      final ids = branches.keys.toList();
      return chartResult(
        'CL-L-18',
        BarData(
          [for (final id in ids) TextLabel(byId[id]?.text ?? '')],
          [
            BarSeries(const TokenLabel(LabelToken.done), [
              for (final id in ids) branches[id]!.progress.valueOrNull ?? 0,
            ]),
          ],
          layout: BarLayout.horizontal,
          unit: StatUnit.percent,
          drillKeys: ids,
        ),
        unit: StatUnit.percent,
        args: {
          'branches': {
            for (final id in ids)
              id: {'throughput': branches[id]!.throughput, 'blockedHours': _hours(branches[id]!.blocked)},
          },
        },
        drill: {
          for (final id in ids)
            if (c.listFacts.firstWhereOrNull((f) => f.id == id) case final f?) id: [c.itemRef(f)],
        },
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Due dates (T6.4.10)
  // ---------------------------------------------------------------------------------------------
  metric<ChecklistContext>(
    id: 'CL-L-19',
    scope: MetricScope.checklist,
    unit: StatUnit.percent,
    chart: ChartKind.bars,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _items,
    compute: (c) {
      final d = dueDatePerformance(c.listFacts.where((f) => f.checklistId == c.checklistId), now: c.now);
      return result(
        'CL-L-19',
        d.onTimeRate,
        unit: StatUnit.percent,
        isRate: true,
        chart: d.openOverdue.isEmpty
            ? null
            : BarData(
                [for (final (f, _) in d.openOverdue.take(10)) _itemLabel(f)],
                [
                  BarSeries(const TokenLabel(LabelToken.overdue), [
                    for (final (_, age) in d.openOverdue.take(10)) age.inSeconds / 86400,
                  ], color: const ToneColor(ChartTone.missed)),
                ],
                layout: BarLayout.horizontal,
                unit: StatUnit.days,
              ),
        args: {'openOverdue': d.openOverdue.length, if (d.meanDaysLate.valueOrNull case final v?) 'meanDaysLate': v},
        drill: {'overdue': c.refs(d.openOverdue.map((e) => e.$1))},
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Recurring checklist runs (T6.4.11)
  // ---------------------------------------------------------------------------------------------
  metric<ChecklistContext>(
    id: 'CL-L-20',
    scope: MetricScope.checklist,
    unit: StatUnit.percent,
    chart: ChartKind.line,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _runs,
    compute: (c) {
      final runs = _runsIn(c);
      if (runs.isEmpty) return const MetricResult.notApplicable('CL-L-20', 'noRuns');
      final r = runCompletion(runs);
      return result(
        'CL-L-20',
        r.mean,
        unit: StatUnit.percent,
        isRate: true,
        chart: TimeSeriesData(
          [for (final p in r.perRun) p.$1],
          [
            ChartSeries(const TokenLabel(LabelToken.done), [for (final p in r.perRun) p.$2]),
          ],
          unit: StatUnit.percent,
          trend: trendOf([for (final p in r.perRun) p.$2], granularity: Granularity.day, isRate: true),
        ),
        spark: sparkOf([for (final p in r.perRun) p.$2]),
        args: {'runs': runs.length},
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-21',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.streakBars,
    priority: MetricPriority.p1,
    requires: _runs,
    compute: (c) {
      final runs = c.data.runs[c.checklistId] ?? const <ChecklistRunFact>[];
      if (runs.isEmpty) return const MetricResult.notApplicable('CL-L-21', 'noRuns');
      final s = fullyCompletedRunStreak(runs);
      return result(
        'CL-L-21',
        Value<double>(s.currentLength.toDouble()),
        chart: streaksOf(s, unit: StatUnit.count),
        args: {'best': s.bestLength},
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-22',
    scope: MetricScope.checklist,
    unit: StatUnit.minutes,
    chart: ChartKind.boxPlot,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _runs,
    compute: (c) {
      final t = timeToFinishRun(_runsIn(c));
      final box = boxPlot(t.minutes).valueOrNull;
      return result(
        'CL-L-22',
        t.median,
        unit: StatUnit.minutes,
        chart: box == null
            ? null
            : BoxPlotData([(const TokenLabel(LabelToken.total), boxOf(box))], unit: StatUnit.minutes),
        args: {if (t.p85.valueOrNull case final v?) 'p85': v},
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-23',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.horizontalBars,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _runs,
    compute: (c) {
      final skipped = mostSkippedItems(_runsIn(c));
      if (skipped.isEmpty) return const MetricResult.notApplicable('CL-L-23', 'noRuns');
      final byId = {for (final f in c.listFacts) f.id: f};
      return chartResult(
        'CL-L-23',
        barsOf(
          [
            for (final s in skipped.take(10))
              (TextLabel(byId[s.itemId]?.row.text ?? '') as ChartLabel, s.missed.toDouble()),
          ],
          seriesLabel: const TokenLabel(LabelToken.missed),
          layout: BarLayout.horizontal,
          color: const ToneColor(ChartTone.missed),
        ),
        value: countOf(skipped.first.missed),
        args: {
          'shares': {for (final s in skipped.take(10)) s.itemId: s.share},
        },
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-24',
    scope: MetricScope.checklist,
    unit: StatUnit.percent,
    chart: ChartKind.bars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _runs,
    compute: (c) {
      final by = runCompletionByWeekday(_runsIn(c));
      if (by.isEmpty) return const MetricResult.notApplicable('CL-L-24', 'noRuns');
      return chartResult(
        'CL-L-24',
        weekdayBars(
          {for (final e in by.entries) e.key: e.value.valueOrNull},
          weekStart: c.weekStart,
          seriesLabel: const TokenLabel(LabelToken.done),
        ),
        unit: StatUnit.percent,
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Benchmarks & calendars (T6.4.13)
  // ---------------------------------------------------------------------------------------------
  metric<ChecklistContext>(
    id: 'CL-X-09',
    scope: MetricScope.checklists,
    unit: StatUnit.hours,
    chart: ChartKind.tiles,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _items,
    compute: (c) {
      final b = flowBenchmarks(
        c.sectionFacts,
        range: c.range,
        bounds: c.bounds,
        random: math.Random(42),
        weekStart: c.weekStart,
      );
      final slope = b.throughputTrend.valueOrNull?.slopePerWeek;
      return result(
        'CL-X-09',
        b.p50,
        unit: StatUnit.hours,
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.p50), b.p50.valueOrNull, StatUnit.hours),
          ValueTile(const TokenLabel(LabelToken.p85), b.p85.valueOrNull, StatUnit.hours),
          ValueTile(const TokenLabel(LabelToken.trend), slope, StatUnit.perWeek),
        ]),
        args: {if (slope != null) 'throughputSlopePerWeek': slope},
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-X-10',
    scope: MetricScope.checklists,
    unit: StatUnit.days,
    chart: ChartKind.calendar,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) => _completionCalendar(c, 'CL-X-10', checklistId: null),
  ),
  metric<ChecklistContext>(
    id: 'CL-L-25',
    scope: MetricScope.checklist,
    unit: StatUnit.days,
    chart: ChartKind.calendar,
    priority: MetricPriority.p1,
    requires: _items,
    compute: (c) => _completionCalendar(c, 'CL-L-25', checklistId: c.checklistId),
  ),

  // ---------------------------------------------------------------------------------------------
  // Advanced flow analytics (T6.4.14)
  // ---------------------------------------------------------------------------------------------
  metric<ChecklistContext>(
    id: 'CL-L-26',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.pareto,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p2,
    requires: {..._items, StatsTable.userSettings},
    compute: (c) {
      final clusters = blockerClusters(
        c.listFacts.where((f) => f.checklistId == c.checklistId),
        now: c.now,
        merges: c.settings.blockerClusters,
      );
      if (clusters.isEmpty) return const MetricResult.notApplicable('CL-L-26', Reasons.noData);
      // Raw normalized reasons for the merge sheet (key → first wording, episodes, cluster).
      final raw = <String, ({String label, int episodes})>{};
      for (final f in c.listFacts.where((f) => f.checklistId == c.checklistId)) {
        for (final e in f.blockedEpisodes) {
          final note = e.note?.trim();
          if (note == null || note.isEmpty) continue;
          final key = normalizeReason(note);
          if (key.isEmpty) continue;
          final cur = raw[key];
          raw[key] = (label: cur?.label ?? note, episodes: (cur?.episodes ?? 0) + 1);
        }
      }
      return chartResult(
        'CL-L-26',
        ParetoData([
          for (final g in clusters)
            (
              g.label == 'Unspecified' ? const TokenLabel(LabelToken.unspecified) : TextLabel(g.label),
              g.episodes * _hours(g.total),
            ),
        ], unit: StatUnit.hours),
        value: countOf(clusters.length),
        args: {
          'reasons': [
            for (final e in raw.entries)
              {
                'key': e.key,
                'label': e.value.label,
                'episodes': e.value.episodes,
                'cluster': ?c.settings.blockerClusters[e.key],
              },
          ],
        },
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-27',
    scope: MetricScope.checklist,
    unit: StatUnit.ratio,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    guard: MinDataGuard.calculator,
    requires: _items,
    compute: (c) {
      final window = c.instantsToNow(c.elapsed);
      final facts = c.listFacts;
      final cts = [
        for (final f in facts)
          if (f.done != null && f.start != null && window.contains(f.done!))
            f.done!.difference(f.start!).inSeconds / 86400,
      ];
      final wip = wipPerDay(facts, range: c.elapsed, bounds: c.bounds, checklistId: c.checklistId);
      final tp = c.completionsIn(c.elapsed, checklistId: c.checklistId);
      final arrivals = arrivalInstants(facts, checklistId: c.checklistId).where(window.contains).length;
      final departures = completionInstants(facts, checklistId: c.checklistId).where(window.contains).length;
      final d = littlesLawDiagnostic(
        cycleTimesDays: cts,
        dailyWip: [for (final p in wip) p.value.toDouble()],
        dailyThroughput: [for (final p in tp) p.value],
        arrivals: arrivals,
        departures: departures,
      );
      return result(
        'CL-L-27',
        d.ratio,
        unit: StatUnit.ratio,
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.littleRatio), d.ratio.valueOrNull, StatUnit.ratio),
          ValueTile(
            const TokenLabel(LabelToken.arrivalsPerDeparture),
            d.arrivalDepartureRatio.valueOrNull,
            StatUnit.ratio,
          ),
        ]),
        note: d.flags.isEmpty ? null : 'unstableFlow',
        args: {
          'flags': [for (final f in d.flags) f.name],
        },
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-28',
    scope: MetricScope.checklist,
    unit: StatUnit.days,
    chart: ChartKind.forecast,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p2,
    guard: MinDataGuard.calculator,
    estimate: true,
    requires: _items,
    compute: (c) {
      final f = _forecast(c);
      final v = f.valueOrNull;
      if (v == null) {
        return result('CL-L-28', f.map((x) => x.p85Days.toDouble()), unit: StatUnit.days, estimate: true);
      }
      return result(
        'CL-L-28',
        Value<double>(v.p85Days.toDouble()),
        unit: StatUnit.days,
        estimate: true,
        chart: ForecastData(c.today, v.histogram, p50: v.p50Days, p85: v.p85Days, p95: v.p95Days, trials: v.trials),
        args: {
          'p50Date': c.today.plusDays(v.p50Days).toIso(),
          'p85Date': c.today.plusDays(v.p85Days).toIso(),
          'p95Date': c.today.plusDays(v.p95Days).toIso(),
          'remaining': v.remaining,
        },
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-29',
    scope: MetricScope.checklist,
    unit: StatUnit.percent,
    chart: ChartKind.bars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _items,
    compute: (c) {
      final by = depthLevelProgress(c.listFacts.where((f) => f.checklistId == c.checklistId).toList());
      if (by.isEmpty) return const MetricResult.notApplicable('CL-L-29', Reasons.noData);
      final levels = by.keys.toList()..sort();
      return chartResult(
        'CL-L-29',
        BarData(
          [for (final l in levels) OrdinalLabel(OrdinalKind.depth, l)],
          [
            BarSeries(const TokenLabel(LabelToken.done), [for (final l in levels) by[l]!.valueOrNull ?? 0]),
          ],
          unit: StatUnit.percent,
        ),
        unit: StatUnit.percent,
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-L-30',
    scope: MetricScope.checklist,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    requires: _attachments,
    compute: (c) => _attachmentResult(
      'CL-L-30',
      attachmentSummary(c.data.attachments.where((a) => a.checklistId == c.checklistId)),
    ),
  ),
  metric<ChecklistContext>(
    id: 'CL-X-11',
    scope: MetricScope.checklists,
    unit: StatUnit.bytes,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    requires: _attachments,
    compute: (c) {
      final a = attachmentSummary(c.data.attachments);
      return result(
        'CL-X-11',
        Value<double>(a.totalBytes.toDouble()),
        unit: StatUnit.bytes,
        chart: _attachmentTiles(a),
        args: {'count': a.count},
      );
    },
  ),
  metric<ChecklistContext>(
    id: 'CL-X-12',
    scope: MetricScope.checklists,
    unit: StatUnit.count,
    chart: ChartKind.groupedBars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    requires: {StatsTable.checklists},
    compute: (c) {
      final from = LocalDate.min(c.range.start, c.today.minusDays(364)).startOfMonth;
      final t = listCreationTrend(c.data.lists, range: DateRange(from, c.today), bounds: c.bounds);
      return chartResult(
        'CL-X-12',
        BarData(
          [for (final p in t.created) DateLabel(p.bucket, Granularity.month)],
          [
            BarSeries(const TokenLabel(LabelToken.created), [for (final p in t.created) p.value]),
            BarSeries(const TokenLabel(LabelToken.archived), [
              for (final p in t.archived) p.value,
            ], color: const ToneColor(ChartTone.muted)),
          ],
          isTimeAxis: true,
        ),
        value: countOf(t.created.fold<double>(0, (a, p) => a + p.value)),
      );
    },
  ),
];

/// The CFD chart of a [CumulativeFlow] (bands bottom → top, reopen markers).
StackedAreaData cfdChart(CumulativeFlow cfd) {
  const order = [ItemStatus.completed, ItemStatus.blocked, ItemStatus.waiting, ItemStatus.ongoing, ItemStatus.todo];
  final dates = [for (final d in cfd.days) d.date];
  return StackedAreaData(
    dates,
    [
      for (final s in order)
        ChartSeries(TokenLabel(statusToken(s)), [
          for (final d in cfd.days) (d.bands[s] ?? 0).toDouble(),
        ], color: ToneColor(statusTone(s))),
    ],
    markers: [
      for (var i = 1; i < cfd.days.length; i++)
        if ((cfd.days[i].bands[ItemStatus.completed] ?? 0) < (cfd.days[i - 1].bands[ItemStatus.completed] ?? 0))
          ChartAnnotation(i, const TokenLabel(LabelToken.reopened)),
    ],
  );
}

/// Runs of the checklist started in the selected period.
List<ChecklistRunFact> _runsIn(ChecklistContext c) => [
  for (final r in c.data.runs[c.checklistId] ?? const <ChecklistRunFact>[])
    if (c.range.contains(r.date)) r,
];

Stat<ForecastWhen> _forecast(ChecklistContext c) {
  final facts = c.listFacts;
  final first = facts.map((f) => f.created).fold<DateTime?>(null, (a, t) => a == null || t.isBefore(a) ? t : a);
  final completions = completionInstants(facts, checklistId: c.checklistId).length;
  if (first == null || c.now.difference(first).inDays < 30) {
    return Insufficient<ForecastWhen>(30, first == null ? 0 : c.now.difference(first).inDays, 'forecastHistoryDays');
  }
  if (completions < 10) return Insufficient<ForecastWhen>(10, completions, 'forecastCompletions');
  return checklistForecast(facts, now: c.now, bounds: c.bounds, random: math.Random(7), checklistId: c.checklistId);
}

/// Burn-down cone from the forecast (remaining items per future day at P50/P85/P95).
ForecastCone? _forecastCone(ChecklistContext c) {
  final f = _forecast(c).valueOrNull;
  if (f == null || f.remaining <= 0) return null;
  final horizon = math.min(f.p95Days, 120);
  if (horizon <= 0) return null;
  List<double> line(int days) => [
    for (var d = 1; d <= horizon; d++) math.max(0, f.remaining * (1 - d / math.max(1, days))).toDouble(),
  ];
  return ForecastCone(
    [for (var d = 1; d <= horizon; d++) c.today.plusDays(d)],
    line(f.p50Days),
    line(f.p85Days),
    line(f.p95Days),
  );
}

MetricResult _completionCalendar(ChecklistContext c, String id, {required String? checklistId}) {
  final from = LocalDate.max(c.range.start, c.today.minusDays(364));
  final to = LocalDate.min(c.range.end, c.today);
  if (to.isBefore(from)) return MetricResult.notApplicable(id, Reasons.noData);
  final days = c.completionsIn(DateRange(from, to), checklistId: checklistId);
  final streak = completionDayStreak(days, today: c.today);
  return result(
    id,
    Value<double>(streak.currentLength.toDouble()),
    unit: StatUnit.days,
    chart: CalendarData(
      {
        for (final p in days)
          if (p.value > 0) p.bucket: CalendarCell(value: p.value),
      },
      from: from,
      to: to,
      today: c.today,
      mode: CalendarMode.intensity,
    ),
    args: {'best': streak.bestLength, 'completions': days.fold<double>(0, (a, p) => a + p.value)},
  );
}

TilesData _attachmentTiles(({int count, int totalBytes, Map<AttachmentKind, int> byKind}) a) => TilesData([
  ValueTile(const TokenLabel(LabelToken.files), a.count.toDouble(), StatUnit.count),
  ValueTile(const TokenLabel(LabelToken.total), a.totalBytes.toDouble(), StatUnit.bytes),
  ValueTile(const TokenLabel(LabelToken.images), (a.byKind[AttachmentKind.image] ?? 0).toDouble(), StatUnit.count),
  ValueTile(const TokenLabel(LabelToken.pdfs), (a.byKind[AttachmentKind.pdf] ?? 0).toDouble(), StatUnit.count),
]);

MetricResult _attachmentResult(String id, ({int count, int totalBytes, Map<AttachmentKind, int> byKind}) a) =>
    a.count == 0
    ? MetricResult.notApplicable(id, Reasons.noData)
    : result(id, countOf(a.count), chart: _attachmentTiles(a), args: {'bytes': a.totalBytes});

extension on LocalDate {
  LocalDate get startOfMonth => LocalDate(year, month, 1);
}
