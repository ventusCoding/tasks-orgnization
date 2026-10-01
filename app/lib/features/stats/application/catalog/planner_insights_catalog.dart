/// Planner Insights catalog, P1/P2 part ([6.3]): per-occurrence planning & focus (T6.3.03), series
/// quality, patterns and time of day (T6.3.05, T6.3.06), and the section metrics for allocation,
/// estimation, punctuality, patterns, focus, goal streak and advanced analytics (T6.3.10–T6.3.16).
/// The math lives in `everslot_metrics`; these definitions only shape results and charts.
library;

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:everslot/features/stats/application/catalog/catalog_support.dart';
import 'package:everslot/features/stats/application/catalog/planner_catalog.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/habit_resolution.dart' show ruleFrequency;
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, RecurrenceRule, Weekday;

const _tables = {StatsTable.tasks, StatsTable.taskOccurrences, StatsTable.timeEntries};
const _events = {..._tables, StatsTable.activityEvents};
const _settings = {..._tables, StatsTable.userSettings};

T _occ<T>(PlannerContext c, T Function(PlannerOccurrenceFact f) f, String id) {
  final o = c.occurrence;
  return o == null ? MetricResult.notApplicable(id, 'noOccurrence') as T : f(o);
}

/// A one-row Gantt of an occurrence: its planned slot and sessions.
GanttData _occurrenceGantt(PlannerOccurrenceFact f) {
  final sessions = f.effectiveSessions;
  final starts = [?f.plannedStart, for (final s in sessions) s.start];
  final ends = [?f.plannedEnd, for (final s in sessions) s.end];
  final from = starts.reduce((a, b) => a.isBefore(b) ? a : b).subtract(const Duration(minutes: 15));
  final to = ends.reduce((a, b) => a.isAfter(b) ? a : b).add(const Duration(minutes: 15));
  return GanttData(
    [
      GanttRow(
        TextLabel(f.title ?? ''),
        planned: f.plannedStart == null || f.plannedEnd == null ? null : TimeSpan(f.plannedStart!, f.plannedEnd!),
        actual: [for (final s in sessions) TimeSpan(s.start, s.end)],
      ),
    ],
    from: from,
    to: to,
  );
}

/// Weekly adherence chart of a series with rule-change annotations.
TimeSeriesData _adherenceWithChanges(PlannerContext c, List<RuleChangeMarker> markers) {
  final t = seriesAdherenceTrend(
    c.seriesToDate,
    now: c.now,
    from: c.seriesStart,
    to: c.today,
    random: math.Random(7),
    weekStart: c.weekStart,
    settings: c.ps,
  );
  final buckets = [for (final p in t.weekly) p.bucket];
  return TimeSeriesData(
    buckets,
    [
      ChartSeries(const TokenLabel(LabelToken.rate), [for (final p in t.weekly) p.value]),
    ],
    granularity: Granularity.week,
    unit: StatUnit.percent,
    annotations: [
      for (final m in markers)
        if (buckets.lastIndexWhere((b) => !b.isAfter(m.date)) case final i when i >= 0)
          ChartAnnotation(i, const TokenLabel(LabelToken.ruleChanged), kind: AnnotationKind.ruleChange),
    ],
  );
}

/// Every PL-* metric of milestones M2/M3.
final List<MetricDefinition> plannerInsightMetrics = [
  // ---------------------------------------------------------------------------------------------
  // Per occurrence: planning & focus (T6.3.03)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-T-08',
    scope: MetricScope.task,
    unit: StatUnit.count,
    chart: ChartKind.moveTimeline,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _events,
    compute: (c) => _occ(c, (f) {
      final moves = f.sortedMoves;
      return result(
        'PL-T-08',
        countOf(rescheduleCount(f)),
        chart: moves.isEmpty
            ? null
            : MoveTimelineData([
                for (final m in moves)
                  MoveEvent(
                    m.occurredAt,
                    fromEpochMinute: m.fromStart.epochMinute,
                    toEpochMinute: m.toStart.epochMinute,
                  ),
              ]),
        args: {'snowballing': isSnowballing(f), 'seriesMoves': moves.where((m) => m.seriesScope).length},
      );
    }, 'PL-T-08'),
  ),
  metric<PlannerContext>(
    id: 'PL-T-09',
    scope: MetricScope.task,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _events,
    compute: (c) => _occ(
      c,
      (f) => result('PL-T-09', Value<double>(rescheduleDistance(f).inMinutes.toDouble()), unit: StatUnit.minutes),
      'PL-T-09',
    ),
  ),
  metric<PlannerContext>(
    id: 'PL-T-10',
    scope: MetricScope.task,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _events,
    compute: (c) => _occ(
      c,
      (f) => result('PL-T-10', Value<double>(netDrift(f).inMinutes.toDouble()), unit: StatUnit.minutes),
      'PL-T-10',
    ),
  ),
  metric<PlannerContext>(
    id: 'PL-T-11',
    scope: MetricScope.task,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _events,
    compute: (c) => _occ(c, (f) {
      if (!isSnowballing(f)) return const MetricResult.notApplicable('PL-T-11', 'notSnowballing');
      return chartResult(
        'PL-T-11',
        ListData([
          ListRow(
            const TokenLabel(LabelToken.snowballing),
            tone: ChartTone.warning,
            value: rescheduleCount(f).toDouble(),
            unit: StatUnit.count,
          ),
        ]),
        value: countOf(rescheduleCount(f)),
      );
    }, 'PL-T-11'),
  ),
  metric<PlannerContext>(
    id: 'PL-T-12',
    scope: MetricScope.task,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) => _occ(c, (f) => result('PL-T-12', minutesOf(leadTime(f)), unit: StatUnit.minutes), 'PL-T-12'),
  ),
  metric<PlannerContext>(
    id: 'PL-T-13',
    scope: MetricScope.task,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) => _occ(c, (f) => result('PL-T-13', minutesOf(startLatency(f)), unit: StatUnit.minutes), 'PL-T-13'),
  ),
  metric<PlannerContext>(
    id: 'PL-T-14',
    scope: MetricScope.task,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: _events,
    compute: (c) => _occ(
      c,
      (f) => result('PL-T-14', minutesOf(planningHorizon(f, clock: c.clock)), unit: StatUnit.minutes),
      'PL-T-14',
    ),
  ),
  metric<PlannerContext>(
    id: 'PL-T-15',
    scope: MetricScope.task,
    unit: StatUnit.percent,
    chart: ChartKind.gantt,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _tables,
    compute: (c) => _occ(c, (f) {
      final fit = slotFit(f);
      final v = fit.valueOrNull;
      return result(
        'PL-T-15',
        fit.map((x) => x.fitShare),
        unit: StatUnit.percent,
        isRate: true,
        chart: v == null ? null : _occurrenceGantt(f),
        args: {
          if (v != null) 'spilledBeforeMinutes': v.spilledBefore.inMinutes,
          if (v != null) 'spilledAfterMinutes': v.spilledAfter.inMinutes,
        },
        note: v == null ? (fit as NotApplicable<SlotFit>).reasonKey : null,
      );
    }, 'PL-T-15'),
  ),
  metric<PlannerContext>(
    id: 'PL-T-16',
    scope: MetricScope.task,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) => _occ(c, (f) {
      final s = focusSessions(f).valueOrNull;
      if (s == null) return const MetricResult.notApplicable('PL-T-16', Reasons.notTracked);
      double m(Duration d) => d.inSeconds / 60;
      return result(
        'PL-T-16',
        countOf(s.count),
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.sessions), s.count.toDouble(), StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.total), m(s.total), StatUnit.minutes),
          ValueTile(const TokenLabel(LabelToken.mean), m(s.mean), StatUnit.minutes),
          ValueTile(const TokenLabel(LabelToken.pauses), s.pauses.toDouble(), StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.longestBlock), m(s.longestBlock), StatUnit.minutes),
        ]),
        args: {'pauses': s.pauses, 'longestMinutes': m(s.longestBlock)},
      );
    }, 'PL-T-16'),
  ),
  metric<PlannerContext>(
    id: 'PL-T-17',
    scope: MetricScope.task,
    unit: StatUnit.percent,
    chart: ChartKind.ring,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _tables,
    compute: (c) => _occ(c, (f) {
      final p = partialCompletion(f);
      return result(
        'PL-T-17',
        p,
        unit: StatUnit.percent,
        isRate: true,
        chart: p.valueOrNull == null
            ? null
            : RingData([(const TokenLabel(LabelToken.done), p.valueOrNull!, const ToneColor(ChartTone.done))]),
      );
    }, 'PL-T-17'),
  ),
  metric<PlannerContext>(
    id: 'PL-T-18',
    scope: MetricScope.task,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.higherIsBetter,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) => _occ(c, (f) {
      if (f.rating == null && (f.outcomeNote ?? '').isEmpty) {
        return const MetricResult.notApplicable('PL-T-18', 'noRating');
      }
      return result(
        'PL-T-18',
        f.rating == null ? const NotApplicable<double>('noRating') : Value<double>(f.rating!.toDouble()),
        chart: ListData([
          ListRow(
            const TokenLabel(LabelToken.rating),
            value: f.rating?.toDouble(),
            unit: StatUnit.count,
            secondary: (f.outcomeNote ?? '').isEmpty ? null : TextLabel(f.outcomeNote!),
          ),
        ]),
        args: {'rating': ?f.rating, 'note': ?f.outcomeNote},
      );
    }, 'PL-T-18'),
  ),

  // ---------------------------------------------------------------------------------------------
  // Series quality & patterns (T6.3.05) and time of day (T6.3.06)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-S-10',
    scope: MetricScope.series,
    unit: StatUnit.percent,
    chart: ChartKind.pareto,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _tables,
    compute: (c) {
      final s = skipRateAndReasons(c.seriesIn(c.range), now: c.now, settings: c.ps);
      return result(
        'PL-S-10',
        s.rate,
        unit: StatUnit.percent,
        isRate: true,
        previous: c.compare ? skipRateAndReasons(c.seriesIn(c.previous), now: c.now, settings: c.ps).rate : null,
        chart: s.reasons.isEmpty ? null : paretoOf(s.reasons),
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-11',
    scope: MetricScope.series,
    unit: StatUnit.percent,
    chart: ChartKind.boxPlot,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _tables,
    compute: (c) {
      final t = startTimeliness(c.seriesIn(c.range), grace: c.ps.grace);
      final boxes = startDelayBoxPlotsByMonth(c.seriesToDate, grace: c.ps.grace);
      final months = boxes.keys.toList()..sort();
      return result(
        'PL-S-11',
        t.onTimeRate,
        unit: StatUnit.percent,
        isRate: true,
        previous: c.compare ? startTimeliness(c.seriesIn(c.previous), grace: c.ps.grace).onTimeRate : null,
        chart: BoxPlotData([
          for (final m in months)
            if (boxes[m]!.valueOrNull case final b?) (DateLabel(m, Granularity.month), boxOf(b)),
        ], unit: StatUnit.minutes),
        args: {
          'started': t.started,
          if (t.medianDelayMinutes.valueOrNull case final v?) 'medianDelay': v,
          if (t.p85DelayMinutes.valueOrNull case final v?) 'p85Delay': v,
        },
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-12',
    scope: MetricScope.series,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _tables,
    compute: (c) => result(
      'PL-S-12',
      onTimeCompletionRate(c.seriesIn(c.range), now: c.now, settings: c.ps),
      unit: StatUnit.percent,
      isRate: true,
      previous: c.compare ? onTimeCompletionRate(c.seriesIn(c.previous), now: c.now, settings: c.ps) : null,
    ),
  ),
  metric<PlannerContext>(
    id: 'PL-S-13',
    scope: MetricScope.series,
    unit: StatUnit.count,
    chart: ChartKind.streakBars,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) {
      final s = c.seriesStreakSummary;
      return chartResult('PL-S-13', streaksOf(s, unit: StatUnit.count), value: Value<double>(s.bestLength.toDouble()));
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-14',
    scope: MetricScope.series,
    unit: StatUnit.score,
    chart: ChartKind.line,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) {
      final task = c.seriesTasks.lastWhereOrNull((t) => t.recurrence != null);
      RecurrenceRule? rule;
      try {
        rule = task?.recurrence == null ? null : RecurrenceRule.decode(task!.recurrence!);
      } on Object {
        rule = null;
      }
      final s = seriesStrength(
        c.seriesToDate,
        frequency: ruleFrequency(rule),
        today: c.today,
        now: c.now,
        settings: c.ps,
      );
      if (s.series.isEmpty) return const MetricResult.notApplicable('PL-S-14', Reasons.noData);
      final points = s.series.length > 365 ? s.series.sublist(s.series.length - 365) : s.series;
      return result(
        'PL-S-14',
        Value<double>(s.current),
        unit: StatUnit.score,
        previous: c.compare ? Value<double>(s.scoreAt(c.today.minusDays(30))) : null,
        chart: TimeSeriesData(
          [for (final p in points) p.date],
          [
            ChartSeries(const TokenLabel(LabelToken.score), [for (final p in points) p.score]),
          ],
          unit: StatUnit.score,
          area: true,
        ),
        spark: sparkOf([for (final p in points.where((p) => p.date.weekday == c.weekStart)) p.score]),
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-15',
    scope: MetricScope.series,
    unit: StatUnit.minutes,
    chart: ChartKind.boxPlot,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) {
      final s = durationStability(c.seriesToDate);
      final box = s.boxPlot.valueOrNull;
      return result(
        'PL-S-15',
        s.medianMinutes,
        unit: StatUnit.minutes,
        chart: box == null
            ? null
            : BoxPlotData([(const TokenLabel(LabelToken.actual), boxOf(box))], unit: StatUnit.minutes),
        args: {
          if (s.meanMinutes.valueOrNull case final v?) 'mean': v,
          if (s.sdMinutes.valueOrNull case final v?) 'sd': v,
          if (s.cv.valueOrNull case final v?) 'cv': v,
          if (s.medianRatio.valueOrNull case final v?) 'medianRatio': v,
        },
        note: s.medianMinutes.hasValue ? null : Reasons.notTracked,
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-16',
    scope: MetricScope.series,
    unit: StatUnit.percent,
    chart: ChartKind.bars,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _tables,
    compute: (c) {
      final w = weekdayAdherence(c.seriesToDate, now: c.now, settings: c.ps);
      if (w.isEmpty) return const MetricResult.notApplicable('PL-S-16', Reasons.noData);
      final order = [
        for (final d in Weekday.ordered(c.weekStart))
          if (w.containsKey(d)) d,
      ];
      return chartResult(
        'PL-S-16',
        BarData(
          [for (final d in order) WeekdayLabel(d)],
          [
            BarSeries(const TokenLabel(LabelToken.rate), [for (final d in order) w[d]!.valueOrNull ?? 0]),
          ],
          unit: StatUnit.percent,
          drillKeys: [for (final d in order) 'weekday:${d.iso}'],
        ),
        unit: StatUnit.percent,
        args: {'weekdays': order.length},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-17',
    scope: MetricScope.series,
    unit: StatUnit.count,
    chart: ChartKind.bars,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) {
      final hours = completionHourProfile(c.seriesToDate, clock: c.clock);
      final total = hours.fold<int>(0, (a, b) => a + b);
      if (total == 0) return const MetricResult.notApplicable('PL-S-17', Reasons.noData);
      final peak = hours.indexOf(hours.reduce(math.max));
      return chartResult(
        'PL-S-17',
        BarData(
          [for (var h = 0; h < 24; h++) HourLabel(h)],
          [
            BarSeries(const TokenLabel(LabelToken.done), [for (final v in hours) v.toDouble()]),
          ],
        ),
        value: countOf(total),
        args: {'peakHour': peak},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-18',
    scope: MetricScope.series,
    unit: StatUnit.percent,
    chart: ChartKind.tiles,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _events,
    compute: (c) {
      final r = rescheduleBehaviour(c.seriesIn(c.range));
      return result(
        'PL-S-18',
        r.movedShare,
        unit: StatUnit.percent,
        isRate: true,
        previous: c.compare ? rescheduleBehaviour(c.seriesIn(c.previous)).movedShare : null,
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.movedShare), r.movedShare.valueOrNull, StatUnit.percent),
          ValueTile(const TokenLabel(LabelToken.moved), r.meanMovesPerOccurrence.valueOrNull, StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.postponed), r.meanPostponeMinutes.valueOrNull, StatUnit.minutes),
        ]),
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-19',
    scope: MetricScope.series,
    unit: StatUnit.count,
    chart: ChartKind.line,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) {
      final starts = [
        for (final t in c.seriesTasks)
          if (t.startLocal != null) t.startLocal!.date,
      ]..sort();
      final changes = starts.length < 2 ? <LocalDate>[] : starts.sublist(1);
      final markers = ruleChangeMarkers(c.seriesToDate, changeDates: changes, now: c.now, settings: c.ps);
      return chartResult(
        'PL-S-19',
        _adherenceWithChanges(c, markers),
        value: countOf(markers.length),
        args: {
          'changes': [
            for (final m in markers)
              {'date': m.date.toIso(), 'before': m.adherenceBefore.valueOrNull, 'after': m.adherenceAfter.valueOrNull},
          ],
        },
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-20',
    scope: MetricScope.series,
    unit: StatUnit.clock,
    chart: ChartKind.rose,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) {
      final s = seriesTimeOfDay(c.seriesToDate, clock: c.clock);
      final v = s.valueOrNull;
      if (v == null) return result('PL-S-20', s.map((x) => x.meanMinuteOfDay), unit: StatUnit.clock);
      final sectors = List<double>.filled(24, 0);
      for (final f in c.seriesToDate) {
        final sessions = f.effectiveSessions;
        final t = sessions.isNotEmpty ? sessions.first.start : f.doneAt;
        if (t != null) sectors[c.clock.toLocal(t).time.hour] += 1;
      }
      return result(
        'PL-S-20',
        v.consistent ? Value<double>(v.meanMinuteRounded.toDouble()) : const NotApplicable<double>('noConsistentTime'),
        unit: StatUnit.clock,
        chart: RoseData(sectors, meanMinute: v.meanMinuteOfDay, sdMinutes: v.sdMinutes, consistent: v.consistent),
        args: {'sd': ?v.sdMinutes, 'n': v.n},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-21',
    scope: MetricScope.series,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) => result('PL-S-21', seriesStartDrift(c.seriesToDate), unit: StatUnit.minutes),
  ),

  // ---------------------------------------------------------------------------------------------
  // Allocation by priority & tag (T6.3.10)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-X-16',
    scope: MetricScope.planner,
    unit: StatUnit.minutes,
    chart: ChartKind.percentBars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) {
      final t = timeByPriority(c.periodFacts);
      final total = t.values.fold<double>(0, (a, b) => a + b);
      return result(
        'PL-X-16',
        total == 0 ? const NotApplicable<double>(Reasons.noData) : Value<double>(total),
        unit: StatUnit.minutes,
        chart: BarData(
          const [TokenLabel(LabelToken.current)],
          [
            for (var p = 4; p >= 0; p--)
              BarSeries(OrdinalLabel(OrdinalKind.priority, p), [t[p] ?? 0], color: SeriesColor(4 - p)),
          ],
          layout: BarLayout.percent,
          unit: StatUnit.minutes,
        ),
        args: {
          'minutes': {for (final e in t.entries) '${e.key}': e.value},
        },
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-17',
    scope: MetricScope.planner,
    unit: StatUnit.minutes,
    chart: ChartKind.horizontalBars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: {..._tables, StatsTable.entityTags},
    compute: (c) {
      final t = timeByTag(c.periodFacts);
      final names = {for (final tag in c.input.tags) tag.id: tag.name};
      final entries = [
        for (final e in t.minutes.entries)
          if (names[e.key] case final name?) (TextLabel(name) as ChartLabel, e.value),
      ];
      if (entries.isEmpty) return const MetricResult.notApplicable('PL-X-17', Reasons.noData);
      return chartResult(
        'PL-X-17',
        barsOf(
          entries,
          seriesLabel: const TokenLabel(LabelToken.total),
          unit: StatUnit.minutes,
          layout: BarLayout.horizontal,
          sort: true,
        ),
        unit: StatUnit.minutes,
        note: t.overlapping ? 'tagsOverlap' : null,
        args: {'overlapping': t.overlapping},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-18',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.percentBars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _tables,
    compute: (c) {
      final a = priorityAlignment(c.periodFacts, now: c.now, settings: c.ps);
      final share = a.highTimeShare.valueOrNull;
      return result(
        'PL-X-18',
        a.highTimeShare,
        unit: StatUnit.percent,
        isRate: true,
        chart: share == null
            ? null
            : BarData(
                const [TokenLabel(LabelToken.total)],
                [
                  BarSeries(const TokenLabel(LabelToken.highPriority), [share], color: const SeriesColor(0)),
                  BarSeries(const TokenLabel(LabelToken.lowPriority), [1 - share], color: const SeriesColor(1)),
                ],
                layout: BarLayout.percent,
                unit: StatUnit.percent,
              ),
        args: {
          if (a.highCompletionRate.valueOrNull case final v?) 'highCompletion': v,
          if (a.lowCompletionRate.valueOrNull case final v?) 'lowCompletion': v,
        },
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-19',
    scope: MetricScope.planner,
    unit: StatUnit.minutes,
    chart: ChartKind.treemap,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: {..._tables, StatsTable.categories},
    compute: (c) {
      final tree = allocationTreemap(c.periodFacts);
      final nodes = [
        for (final e in tree.entries)
          TreemapNode(
            c.categoryLabel(e.key),
            e.value.values.fold<double>(0, (a, b) => a + b),
            color: c.categoryColor(e.key),
            drillKey: e.key ?? '',
            children: [
              for (final t in e.value.entries.sorted((a, b) => b.value.compareTo(a.value)).take(8))
                TreemapNode(
                  TextLabel(c.tasks[t.key]?.title ?? ''),
                  t.value,
                  color: c.categoryColor(e.key),
                  drillKey: 'task:${t.key}',
                ),
            ],
          ),
      ]..sort((a, b) => b.value.compareTo(a.value));
      final byCategory = groupBy(c.periodFacts, (f) => f.categoryId ?? '');
      return chartResult(
        'PL-X-19',
        TreemapData(nodes),
        unit: StatUnit.minutes,
        value: nodes.isEmpty
            ? const NotApplicable<double>(Reasons.noData)
            : Value<double>(nodes.fold<double>(0, (a, n) => a + n.value)),
        drill: {
          for (final e in byCategory.entries) e.key: c.refs(e.value),
          for (final e in groupBy(c.periodFacts, (f) => f.taskId).entries) 'task:${e.key}': c.refs(e.value),
        },
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-20',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.donut,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _tables,
    compute: (c) {
      final r = recurringVsOneOff(c.periodFacts);
      final total = r.recurringMinutes + r.oneOffMinutes;
      return result(
        'PL-X-20',
        safeDivide(r.recurringMinutes, total),
        unit: StatUnit.percent,
        isRate: true,
        chart: total == 0
            ? null
            : DonutData([
                DonutSlice(const TokenLabel(LabelToken.recurring), r.recurringMinutes, color: const SeriesColor(0)),
                DonutSlice(const TokenLabel(LabelToken.oneOff), r.oneOffMinutes, color: const SeriesColor(1)),
              ], unit: StatUnit.minutes),
        args: {'recurringDone': r.recurringDone, 'oneOffDone': r.oneOffDone},
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Estimation accuracy (T6.3.11)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-X-21',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) {
      final e = estimationAccuracy(c.periodFacts);
      return result(
        'PL-X-21',
        e.bias,
        unit: StatUnit.percent,
        previous: c.compare ? estimationAccuracy(c.previousFacts).bias : null,
        args: {'n': e.n, if (e.bias.valueOrNull case final b?) 'tendency': estimationTendency(b).name},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-22',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) => result(
      'PL-X-22',
      estimationAccuracy(c.periodFacts).mape,
      unit: StatUnit.percent,
      previous: c.compare ? estimationAccuracy(c.previousFacts).mape : null,
    ),
  ),
  metric<PlannerContext>(
    id: 'PL-X-23',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) => result('PL-X-23', estimationAccuracy(c.periodFacts).suggestedBuffer, unit: StatUnit.percent),
  ),
  metric<PlannerContext>(
    id: 'PL-X-24',
    scope: MetricScope.planner,
    unit: StatUnit.count,
    chart: ChartKind.scatter,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) {
      final facts = [
        for (final f in c.periodFacts)
          if ((f.plannedMinutes ?? 0) > 0 && f.actualMinutes != null) f,
      ];
      if (facts.isEmpty) return const MetricResult.notApplicable('PL-X-24', Reasons.notTracked);
      final within = facts.where((f) => (f.actualMinutes! - f.plannedMinutes!).abs() <= 0.2 * f.plannedMinutes!);
      return chartResult(
        'PL-X-24',
        ScatterData(
          [
            for (final f in facts)
              ScatterPoint(
                f.plannedMinutes!,
                f.actualMinutes!,
                color: c.categoryColor(f.categoryId),
                ref: c.refs([f]).first,
              ),
          ],
          variant: ScatterVariant.planVsActual,
          xUnit: StatUnit.minutes,
          yUnit: StatUnit.minutes,
        ),
        args: {'withinBand': within.length},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-25',
    scope: MetricScope.planner,
    unit: StatUnit.minutes,
    chart: ChartKind.histogram,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) {
      final d = plannedDurationDistribution(c.periodFacts);
      final m = d.median.valueOrNull;
      return result(
        'PL-X-25',
        d.median,
        unit: StatUnit.minutes,
        chart: d.histogram.bins.isEmpty
            ? null
            : histogramOf(
                d.histogram,
                unit: StatUnit.minutes,
                markers: [if (m != null) (m, const TokenLabel(LabelToken.median))],
              ),
        args: {if (d.mean.valueOrNull case final v?) 'mean': v},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-26',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.groupedBars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: {..._tables, StatsTable.categories},
    compute: (c) {
      final by = estimationByCategory(c.periodFacts);
      final keys = [
        for (final e in by.entries)
          if (e.value.bias.hasValue) e.key,
      ];
      if (keys.isEmpty) return const MetricResult.notApplicable('PL-X-26', Reasons.needsMoreData);
      return chartResult(
        'PL-X-26',
        BarData(
          [for (final k in keys) c.categoryLabel(k)],
          [
            BarSeries(const TokenLabel(LabelToken.bias), [for (final k in keys) by[k]!.bias.valueOrNull ?? 0]),
            BarSeries(const TokenLabel(LabelToken.mape), [
              for (final k in keys) by[k]!.mape.valueOrNull ?? 0,
            ], color: const SeriesColor(1)),
          ],
          unit: StatUnit.percent,
          drillKeys: [for (final k in keys) k ?? ''],
        ),
        unit: StatUnit.percent,
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Punctuality & reschedules (T6.3.12)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-X-27',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _tables,
    compute: (c) {
      final t = startTimeliness(c.periodFacts, grace: c.ps.grace);
      return result(
        'PL-X-27',
        t.onTimeRate,
        unit: StatUnit.percent,
        isRate: true,
        previous: c.compare ? startTimeliness(c.previousFacts, grace: c.ps.grace).onTimeRate : null,
        args: {'started': t.started},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-28',
    scope: MetricScope.planner,
    unit: StatUnit.minutes,
    chart: ChartKind.punchCard,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    guard: MinDataGuard.calculator,
    requires: _tables,
    compute: (c) {
      final t = startTimeliness(c.periodFacts, grace: c.ps.grace);
      final card = startDelayPunchCard(c.periodFacts, grace: c.ps.grace);
      final byWeekday = <Weekday, List<double>>{};
      for (final e in card.entries) {
        byWeekday.putIfAbsent(e.key.$1, () => List<double>.filled(24, 0))[e.key.$2] = math.max(0, e.value);
      }
      return result(
        'PL-X-28',
        t.medianDelayMinutes,
        unit: StatUnit.minutes,
        chart: card.isEmpty ? null : punchCardOf(byWeekday, unit: StatUnit.minutes),
        args: {
          if (t.meanDelayMinutes.valueOrNull case final v?) 'mean': v,
          if (t.p85DelayMinutes.valueOrNull case final v?) 'p85': v,
        },
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-29',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _events,
    compute: (c) {
      final r = rescheduleBehaviour(c.periodFacts);
      return result(
        'PL-X-29',
        r.movedShare,
        unit: StatUnit.percent,
        isRate: true,
        previous: c.compare ? rescheduleBehaviour(c.previousFacts).movedShare : null,
        drill: {'moved': c.refs(c.periodFacts.where((f) => f.moves.isNotEmpty))},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-30',
    scope: MetricScope.planner,
    unit: StatUnit.hours,
    chart: ChartKind.tiles,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _events,
    compute: (c) {
      final r = rescheduleBehaviour(c.periodFacts);
      return result(
        'PL-X-30',
        Value<double>(r.hoursPostponed),
        unit: StatUnit.hours,
        previous: c.compare ? Value<double>(rescheduleBehaviour(c.previousFacts).hoursPostponed) : null,
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.moved), r.meanMovesPerMovedOccurrence.valueOrNull, StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.postponed), r.hoursPostponed, StatUnit.hours),
        ]),
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-31',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _events,
    compute: (c) => result(
      'PL-X-31',
      rescheduleBehaviour(c.periodFacts).procrastinationIndex,
      unit: StatUnit.percent,
      isRate: true,
      previous: c.compare ? rescheduleBehaviour(c.previousFacts).procrastinationIndex : null,
    ),
  ),
  metric<PlannerContext>(
    id: 'PL-X-32',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.pareto,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _tables,
    compute: (c) {
      final s = skipRateAndReasons(c.periodFacts, now: c.now, settings: c.ps);
      return result(
        'PL-X-32',
        s.rate,
        unit: StatUnit.percent,
        isRate: true,
        previous: c.compare ? skipRateAndReasons(c.previousFacts, now: c.now, settings: c.ps).rate : null,
        chart: s.reasons.isEmpty ? null : paretoOf(s.reasons),
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Patterns (T6.3.13)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-X-33',
    scope: MetricScope.planner,
    unit: StatUnit.minutes,
    chart: ChartKind.punchCard,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) {
      ChartData card(BusyMeasure m) => punchCardOf(
        busiestHours(c.periodFacts, measure: m, clock: c.clock),
        unit: m == BusyMeasure.completions ? StatUnit.count : StatUnit.minutes,
      );
      final planned = card(BusyMeasure.plannedMinutes);
      return chartResult(
        'PL-X-33',
        ChartGroup([
          (const TokenLabel(LabelToken.planned), planned),
          (const TokenLabel(LabelToken.actual), card(BusyMeasure.actualMinutes)),
          (const TokenLabel(LabelToken.done), card(BusyMeasure.completions)),
        ]),
        unit: StatUnit.minutes,
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-34',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.groupedBars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _tables,
    compute: (c) {
      final b = bestWorkingDays(c.periodFacts, now: c.now, settings: c.ps);
      if (b.isEmpty) return const MetricResult.notApplicable('PL-X-34', Reasons.noData);
      final order = [
        for (final w in Weekday.ordered(c.weekStart))
          if (b.containsKey(w)) w,
      ];
      final rated = order.where((w) => b[w]!.completionRate.hasValue).toList()
        ..sort((x, y) => b[y]!.completionRate.valueOrNull!.compareTo(b[x]!.completionRate.valueOrNull!));
      final best = rated.firstOrNull;
      return chartResult(
        'PL-X-34',
        ChartGroup([
          (
            const TokenLabel(LabelToken.rate),
            weekdayBars(
              {for (final w in order) w: b[w]!.completionRate.valueOrNull},
              weekStart: c.weekStart,
              seriesLabel: const TokenLabel(LabelToken.rate),
            ),
          ),
          (
            const TokenLabel(LabelToken.actual),
            weekdayBars(
              {for (final w in order) w: b[w]!.hours},
              weekStart: c.weekStart,
              seriesLabel: const TokenLabel(LabelToken.actual),
              unit: StatUnit.hours,
            ),
          ),
        ]),
        unit: StatUnit.percent,
        args: {'bestWeekday': ?best?.iso},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-35',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.matrix,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _settings,
    compute: (c) {
      final size = slotMinutesOf(c);
      final occ = slotOccupancy(
        c.periodFacts,
        range: c.range,
        slotMinutes: size,
        clock: c.clock,
        weekStart: c.weekStart,
      );
      final order = Weekday.ordered(c.weekStart);
      final slots = (1440 / size).ceil();
      final byKey = {for (final o in occ) (o.weekday, o.slotStartMinute): o};
      final any = occ.any((o) => o.plannedShare > 0 || o.usedShare > 0);
      if (!any) return const MetricResult.notApplicable('PL-X-35', Reasons.noData);
      return chartResult(
        'PL-X-35',
        MatrixData(
          [for (final w in order) WeekdayLabel(w)],
          [for (var i = 0; i < slots; i++) NumberLabel((i * size).toDouble(), StatUnit.clock)],
          [
            for (final w in order) [for (var i = 0; i < slots; i++) byKey[(w, i * size)]?.plannedShare],
          ],
        ),
        unit: StatUnit.percent,
        args: {'slotMinutes': size, 'weeks': occ.isEmpty ? 0 : occ.first.weeks},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-36',
    scope: MetricScope.planner,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _settings,
    compute: (c) {
      final size = slotMinutesOf(c);
      final occ = slotOccupancy(
        c.periodFacts,
        range: c.range,
        slotMinutes: size,
        clock: c.clock,
        weekStart: c.weekStart,
      );
      if (occ.isEmpty || occ.first.weeks < 4) return const MetricResult.notApplicable('PL-X-36', Reasons.needsMoreData);
      final dead = deadSlots(occ, slotMinutes: size, settings: c.ps);
      return chartResult(
        'PL-X-36',
        ListData([
          for (final s in dead.take(20))
            ListRow(WeekdayLabel(s.weekday), secondary: NumberLabel(s.slotStartMinute.toDouble(), StatUnit.clock)),
        ]),
        value: countOf(dead.length),
        args: {'slotMinutes': size},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-37',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.bars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _tables,
    compute: (c) {
      final r = completionRateByHour(c.periodFacts, now: c.now, settings: c.ps);
      final hours = r.keys.toList()..sort();
      if (hours.isEmpty) return const MetricResult.notApplicable('PL-X-37', Reasons.noData);
      return chartResult(
        'PL-X-37',
        BarData(
          [for (final h in hours) HourLabel(h)],
          [
            BarSeries(const TokenLabel(LabelToken.rate), [for (final h in hours) r[h]!.valueOrNull ?? 0]),
          ],
          unit: StatUnit.percent,
        ),
        unit: StatUnit.percent,
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Focus & balance (T6.3.14)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-X-38',
    scope: MetricScope.planner,
    unit: StatUnit.hours,
    chart: ChartKind.bars,
    priority: MetricPriority.p1,
    requires: _settings,
    compute: (c) {
      final blocks = deepWorkBlocks(c.periodFacts, settings: c.ps);
      double hoursOfBlocks(Iterable<SessionBlock> b) => b.fold<double>(0, (a, x) => a + x.tracked.inSeconds / 3600);
      final byDate = groupBy(blocks, (b) => c.clock.toLocal(b.start).date);
      final days = c.range.dates.toList();
      return result(
        'PL-X-38',
        Value<double>(hoursOfBlocks(blocks)),
        unit: StatUnit.hours,
        previous: c.compare ? Value<double>(hoursOfBlocks(deepWorkBlocks(c.previousFacts, settings: c.ps))) : null,
        chart: BarData(
          [for (final d in days) DateLabel(d)],
          [
            BarSeries(const TokenLabel(LabelToken.deepWork), [
              for (final d in days) hoursOfBlocks(byDate[d] ?? const []),
            ]),
          ],
          unit: StatUnit.hours,
          isTimeAxis: true,
        ),
        args: {'blocks': blocks.length, 'thresholdMinutes': c.ps.deepWorkMinutes},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-39',
    scope: MetricScope.planner,
    unit: StatUnit.minutes,
    chart: ChartKind.bars,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p1,
    requires: _settings,
    compute: (c) {
      final a = afterHours(c.periodFacts, clock: c.clock, settings: c.ps);
      return result(
        'PL-X-39',
        Value<double>(a.afterHoursMinutes),
        unit: StatUnit.minutes,
        previous: c.compare
            ? Value<double>(afterHours(c.previousFacts, clock: c.clock, settings: c.ps).afterHoursMinutes)
            : null,
        chart: BarData(
          const [TokenLabel(LabelToken.current)],
          [
            BarSeries(const TokenLabel(LabelToken.afterHours), [
              a.afterHoursMinutes,
            ], color: const ToneColor(ChartTone.warning)),
            BarSeries(const TokenLabel(LabelToken.weekend), [a.weekendMinutes], color: const SeriesColor(2)),
          ],
          unit: StatUnit.minutes,
        ),
        args: {'weekendMinutes': a.weekendMinutes},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-40',
    scope: MetricScope.planner,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: _tables,
    compute: (c) {
      final t = timerUsage(c.periodFacts);
      return result(
        'PL-X-40',
        countOf(t.sessions),
        previous: c.compare ? countOf(timerUsage(c.previousFacts).sessions) : null,
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.sessions), t.sessions.toDouble(), StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.mean), t.meanSessionMinutes.valueOrNull, StatUnit.minutes),
          ValueTile(const TokenLabel(LabelToken.trackedTime), t.doneWithSessionsShare.valueOrNull, StatUnit.percent),
        ]),
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-41',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    priority: MetricPriority.p1,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _tables,
    compute: (c) => result(
      'PL-X-41',
      actualTimeCoverage(c.periodFacts),
      unit: StatUnit.percent,
      isRate: true,
      previous: c.compare ? actualTimeCoverage(c.previousFacts) : null,
    ),
  ),

  // ---------------------------------------------------------------------------------------------
  // Completion goal streak (T6.3.15)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-X-42',
    scope: MetricScope.planner,
    unit: StatUnit.count,
    chart: ChartKind.streakBars,
    priority: MetricPriority.p1,
    requires: {..._settings, StatsTable.goals},
    compute: (c) {
      final goal = c.input.goals.firstWhereOrNull(
        (g) => g.scopeType == 'global' && g.metric == 'completions' && (g.period == 'day' || g.period == 'week'),
      );
      if (goal == null) return const MetricResult.notApplicable('PL-X-42', 'noGoal');
      final s = goalStreak(c, target: goal.target.ceil(), weekly: goal.period == 'week');
      return result(
        'PL-X-42',
        Value<double>(s.currentLength.toDouble()),
        chart: streaksOf(s, unit: goal.period == 'week' ? StatUnit.count : StatUnit.days),
        args: {'target': goal.target, 'period': goal.period, 'best': s.bestLength},
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Advanced (T6.3.16)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-X-43',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.bars,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p2,
    isRate: true,
    guard: MinDataGuard.exempt,
    requires: _settings,
    compute: (c) {
      final days = c.elapsed.dates.toList();
      final perDay = {for (final d in days) d: fragmentation(c.periodFacts, date: d, settings: c.ps).valueOrNull};
      final values = [
        for (final v in perDay.values)
          if (v != null) v.index,
      ];
      if (values.isEmpty) return const MetricResult.notApplicable('PL-X-43', 'noFreeTime');
      final gaps = perDay.values.whereType<Fragmentation>().fold<int>(0, (a, f) => a + f.gapsOver15);
      return result(
        'PL-X-43',
        mean(values),
        unit: StatUnit.percent,
        isRate: true,
        chart: BarData(
          [for (final d in days) DateLabel(d)],
          [
            BarSeries(const TokenLabel(LabelToken.fragmentation), [for (final d in days) perDay[d]?.index ?? 0]),
          ],
          unit: StatUnit.percent,
          isTimeAxis: true,
        ),
        args: {'gapsOver15': gaps},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-44',
    scope: MetricScope.planner,
    unit: StatUnit.count,
    chart: ChartKind.line,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p2,
    guard: MinDataGuard.calculator,
    requires: {..._tables, StatsTable.categories},
    compute: (c) {
      final s = contextSwitches(c.periodFacts, clock: c.clock);
      final days = c.elapsed.dates.toList();
      return result(
        'PL-X-44',
        s.perTrackedHour,
        previous: c.compare ? contextSwitches(c.previousFacts, clock: c.clock).perTrackedHour : null,
        chart: s.perDay.isEmpty
            ? null
            : TimeSeriesData(days, [
                ChartSeries(const TokenLabel(LabelToken.contextSwitches), [
                  for (final d in days) s.perDay[d]?.toDouble(),
                ]),
              ]),
        note: s.perDay.isEmpty ? Reasons.notTracked : null,
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-45',
    scope: MetricScope.planner,
    unit: StatUnit.score,
    chart: ChartKind.line,
    priority: MetricPriority.p2,
    guard: MinDataGuard.calculator,
    requires: {..._settings, StatsTable.categories},
    compute: (c) {
      final score = productivityScore(c.periodFacts, settings: c.ps);
      if (score is NotApplicable<double>) return MetricResult.notApplicable('PL-X-45', score.reasonKey);
      final days = c.elapsed.dates.toList();
      final byDay = groupBy(c.periodFacts, (f) => f.plannedDate);
      return result(
        'PL-X-45',
        score.map((v) => v / 100),
        unit: StatUnit.score,
        previous: c.compare ? productivityScore(c.previousFacts, settings: c.ps).map((v) => v / 100) : null,
        chart: TimeSeriesData(days, [
          ChartSeries(const TokenLabel(LabelToken.score), [
            for (final d in days)
              productivityScore(byDay[d] ?? const [], settings: c.ps).valueOrNull?.let((v) => v / 100),
          ]),
        ], unit: StatUnit.score),
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-46',
    scope: MetricScope.planner,
    unit: StatUnit.hours,
    chart: ChartKind.histogram,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    guard: MinDataGuard.calculator,
    requires: _events,
    compute: (c) {
      final h = planningHorizonDistribution(c.periodFacts, clock: c.clock);
      final hours = [
        for (final f in c.periodFacts)
          if (planningHorizon(f, clock: c.clock).valueOrNull case final d?) d.inSeconds / 3600,
      ];
      final med = median(hours);
      return result(
        'PL-X-46',
        MinDataRules.meanOrMedian.apply(med),
        unit: StatUnit.hours,
        chart: h.bins.isEmpty
            ? null
            : histogramOf(
                h,
                unit: StatUnit.hours,
                markers: [if (med.valueOrNull case final m?) (m, const TokenLabel(LabelToken.median))],
              ),
      );
    },
  ),
];

/// Slot size of the occupancy metrics: `slot:<minutes>` in the request extra (week-table view
/// size), else 60 min.
int slotMinutesOf(PlannerContext c) {
  final extra = c.request.extra;
  if (extra != null && extra.startsWith('slot:')) {
    final v = int.tryParse(extra.substring(5));
    if (v != null && v >= 5 && v <= 1440) return v;
  }
  return 60;
}

/// PL-X-42 over the loaded history (≥ 90 days): days (or weeks) reaching [target] completions; days
/// without capacity are neutral.
StreakSummary goalStreak(PlannerContext c, {required int target, required bool weekly}) {
  final from = c.windowStart;
  final range = DateRange(from, c.today);
  final capacity = capacityReport(
    c.facts.where((f) => f.plannedDate != null && range.contains(f.plannedDate!)),
    range: range,
    clock: c.clock,
    settings: c.ps,
  );
  final offDays = {
    for (final d in capacity.days)
      if (d.capacityMinutes <= 0) d.date,
  };
  if (!weekly) {
    return completionGoalStreak(
      c.facts,
      target: target,
      range: range,
      bounds: c.bounds,
      today: c.today,
      isDayOff: offDays.contains,
    );
  }
  final counts = <LocalDate, int>{};
  for (final f in c.facts) {
    final t = f.doneAt;
    if (f.status != PlannerOccurrenceStatus.done || t == null) continue;
    final week = c.bounds.dateOf(t).startOfWeek(c.weekStart);
    counts[week] = (counts[week] ?? 0) + 1;
  }
  final thisWeek = c.today.startOfWeek(c.weekStart);
  final weeks = <LocalDate>[];
  for (var w = from.startOfWeek(c.weekStart); !w.isAfter(thisWeek); w = w.plusDays(7)) {
    weeks.add(w);
  }
  return computeStreaks([
    for (final w in weeks)
      StreakUnit(
        w.toIso(),
        start: w,
        end: w.plusDays(6),
        kind: (counts[w] ?? 0) >= target
            ? StreakUnitKind.success
            : (w == thisWeek ? StreakUnitKind.open : StreakUnitKind.breaks),
      ),
  ]);
}

extension<T extends Object> on T {
  R let<R>(R Function(T it) f) => f(this);
}
