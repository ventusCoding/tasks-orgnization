/// Planner Insights catalog ([6.3]): per-occurrence (PL-T-*), per-series (PL-S-*) and section
/// (PL-X-*) metrics declared on top of the `everslot_metrics` planner calculators.
library;

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:everslot/features/stats/application/catalog/catalog_support.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/planner_resolution.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/domain/zone_snapshot.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;

/// Batch context of the planner scopes (task, series, planner).
final class PlannerContext extends StatsContext {
  PlannerContext(super.job, super.resolver) : input = job.planner ?? const PlannerInput();

  final PlannerInput input;

  @override
  late final DayBoundaries bounds = dayBoundariesOf(resolver, env.zoneId);

  ZoneClock get clock => bounds.clock;

  PlannerStatsSettings get ps => settings.planner;

  late final PlannerResolver planner = PlannerResolver(input, resolver: resolver, viewerZone: env.zoneId, now: now);

  late final Map<String, CategoryInfo> categories = {for (final c in input.categories) c.id: c};

  late final Map<String, TaskRecord> tasks = {for (final t in input.tasks) t.id: t};

  /// Label of a category (uncategorized → token).
  ChartLabel categoryLabel(String? id) {
    final c = id == null ? null : categories[id];
    return c == null ? const TokenLabel(LabelToken.uncategorized) : TextLabel(c.name);
  }

  ChartColor categoryColor(String? id) {
    final c = id == null ? null : categories[id];
    return c == null ? const ToneColor(ChartTone.muted) : ArgbColor(c.color);
  }

  bool _matches(PlannerOccurrenceFact f) {
    final filters = request.filters;
    if (filters.isEmpty) return true;
    if (filters.categoryIds.isNotEmpty && !filters.categoryIds.contains(f.categoryId ?? '')) return false;
    if (filters.priorities.isNotEmpty && !filters.priorities.contains(f.priority)) return false;
    if (filters.trackingModes.isNotEmpty && !filters.trackingModes.contains(f.trackingMode.name)) return false;
    if (filters.tagIds.isNotEmpty && !f.tagIds.any(filters.tagIds.contains)) return false;
    return true;
  }

  /// Loaded window: previous period − 1 week … end of the period + 4 weeks (moved-out detection).
  late final LocalDate windowStart = LocalDate.min(previous.start, range.start).minusDays(7);
  late final LocalDate windowEnd = range.end.plusDays(28);

  late final PlannerFacts section = planner.resolve(from: windowStart, to: windowEnd);

  /// Facts of the section window (filters applied).
  late final List<PlannerOccurrenceFact> facts = section.facts.where(_matches).toList();

  List<PlannerOccurrenceFact> plannedIn(DateRange r) => [
    for (final f in facts)
      if (f.plannedDate != null && r.contains(f.plannedDate!)) f,
  ];

  /// Facts planned in the selected period.
  late final List<PlannerOccurrenceFact> periodFacts = plannedIn(range);

  /// Facts planned in the previous equivalent period.
  late final List<PlannerOccurrenceFact> previousFacts = plannedIn(previous);

  late final PlanSnapshot snapshot = planSnapshot(facts, period: range, bounds: bounds, now: now);
  late final PlanSnapshot previousSnapshot = planSnapshot(facts, period: previous, bounds: bounds, now: now);

  late final CapacityReport capacity = capacityReport(periodFacts, range: range, clock: clock, settings: ps);
  late final CapacityReport previousCapacity = capacityReport(
    previousFacts,
    range: previous,
    clock: clock,
    settings: ps,
  );

  // -- Series scope --------------------------------------------------------------------------

  String get seriesId => scopeId ?? '';

  late final List<TaskRecord> seriesTasks = [
    for (final t in input.tasks)
      if (t.seriesId == seriesId) t,
  ];

  late final LocalDate seriesStart = seriesTasks
      .map((t) => t.startLocal?.date)
      .whereType<LocalDate>()
      .fold<LocalDate>(today, LocalDate.min);

  /// Every occurrence of the series from its start to the end of the period (or today).
  late final List<PlannerOccurrenceFact> seriesAll = planner
      .resolve(from: seriesStart, to: LocalDate.max(today, range.end), seriesIds: {seriesId})
      .facts;

  /// Series occurrences up to now (all-time metrics).
  late final List<PlannerOccurrenceFact> seriesToDate = [
    for (final f in seriesAll)
      if (f.plannedDate != null && !f.plannedDate!.isAfter(today)) f,
  ];

  List<PlannerOccurrenceFact> seriesIn(DateRange r) => [
    for (final f in seriesAll)
      if (f.plannedDate != null && r.contains(f.plannedDate!)) f,
  ];

  late final Ledger seriesLedgerNow = seriesLedger(seriesIn(range), now: now, settings: ps);
  late final Ledger seriesLedgerPrevious = seriesLedger(seriesIn(previous), now: now, settings: ps);
  late final StreakSummary seriesStreakSummary = seriesStreaks(seriesToDate, now: now, settings: ps);

  // -- Task scope ----------------------------------------------------------------------------

  late final PlannerOccurrenceFact? occurrence = planner.occurrence(scopeId ?? '', request.extra);

  List<DrillRef> refs(Iterable<PlannerOccurrenceFact> list, {int cap = 200}) => [
    for (final f in list.take(cap))
      DrillRef(
        DrillKind.occurrence,
        f.taskId,
        extra: f.occurrenceKey,
        title: f.title,
        subtitle: f.plannedStartLocal?.toIso(),
      ),
  ];

  Map<String, List<DrillRef>> refsByDate(Iterable<PlannerOccurrenceFact> list) {
    final map = <String, List<PlannerOccurrenceFact>>{};
    for (final f in list) {
      final d = f.plannedDate;
      if (d != null) map.putIfAbsent(d.toIso(), () => []).add(f);
    }
    return {for (final e in map.entries) e.key: refs(e.value)};
  }
}

T _occ<T>(PlannerContext c, T Function(PlannerOccurrenceFact f) f, T Function() none) {
  final o = c.occurrence;
  return o == null ? none() : f(o);
}

MetricResult _noOccurrence(String id) => MetricResult.notApplicable(id, 'noOccurrence');

const _plannerTables = {StatsTable.tasks, StatsTable.taskOccurrences, StatsTable.timeEntries};
const _eventTables = {..._plannerTables, StatsTable.activityEvents};

/// Every planner metric.
final List<MetricDefinition> plannerMetrics = [
  // ---------------------------------------------------------------------------------------------
  // Per occurrence (T6.3.02)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-T-01',
    scope: MetricScope.task,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.neutral,
    requires: _plannerTables,
    compute: (c) => _occ(
      c,
      (f) => result('PL-T-01', minutesOf(plannedDuration(f)), unit: StatUnit.minutes),
      () => _noOccurrence('PL-T-01'),
    ),
  ),
  metric<PlannerContext>(
    id: 'PL-T-02',
    scope: MetricScope.task,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.neutral,
    requires: _plannerTables,
    compute: (c) => _occ(c, (f) {
      final v = minutesOf(actualDuration(f));
      return result('PL-T-02', v, unit: StatUnit.minutes, note: v.hasValue ? null : Reasons.notTracked);
    }, () => _noOccurrence('PL-T-02')),
  ),
  metric<PlannerContext>(
    id: 'PL-T-03',
    scope: MetricScope.task,
    unit: StatUnit.minutes,
    chart: ChartKind.bullet,
    direction: MetricDirection.neutral,
    requires: _plannerTables,
    compute: (c) => _occ(c, (f) {
      final v = durationVariance(f);
      final dp = f.plannedMinutes;
      final da = f.actualMinutes;
      return result(
        'PL-T-03',
        v.map((x) => x.variance.inSeconds / 60),
        unit: StatUnit.minutes,
        args: {
          if (v.valueOrNull?.ratio case final r?) 'ratio': r,
          if (v.valueOrNull?.label case final l?) 'label': l.name,
        },
        chart: dp == null || da == null
            ? null
            : BulletData(actual: da, target: dp, unit: StatUnit.minutes, label: const TokenLabel(LabelToken.actual)),
        note: v.hasValue ? null : (v as NotApplicable<DurationVariance>).reasonKey,
      );
    }, () => _noOccurrence('PL-T-03')),
  ),
  metric<PlannerContext>(
    id: 'PL-T-04',
    scope: MetricScope.task,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    requires: _plannerTables,
    compute: (c) => _occ(c, (f) {
      final d = startDelay(f, grace: c.ps.grace);
      return result(
        'PL-T-04',
        d.map((x) => x.delta.inSeconds / 60),
        unit: StatUnit.minutes,
        args: {if (d.valueOrNull case final x?) 'punctuality': x.punctuality.name},
        note: d.hasValue ? null : (d as NotApplicable<TimingDelta>).reasonKey,
      );
    }, () => _noOccurrence('PL-T-04')),
  ),
  metric<PlannerContext>(
    id: 'PL-T-05',
    scope: MetricScope.task,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    requires: _plannerTables,
    compute: (c) => _occ(c, (f) {
      final d = finishDelay(f, grace: c.ps.grace);
      return result(
        'PL-T-05',
        d.map((x) => x.delta.inSeconds / 60),
        unit: StatUnit.minutes,
        args: {if (d.valueOrNull case final x?) 'punctuality': x.punctuality.name},
        note: d.hasValue ? null : (d as NotApplicable<TimingDelta>).reasonKey,
      );
    }, () => _noOccurrence('PL-T-05')),
  ),
  metric<PlannerContext>(
    id: 'PL-T-06',
    scope: MetricScope.task,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.neutral,
    requires: _plannerTables,
    compute: (c) => _occ(c, (f) {
      final o = plannerOutcome(f, now: c.now, settings: c.ps);
      return chartResult(
        'PL-T-06',
        ListData([
          ListRow(
            TokenLabel(_outcomeToken(o)),
            tone: _outcomeTone(o),
            secondary: f.skipReason == null ? null : TextLabel(f.skipReason!),
          ),
        ]),
        value: const Value<double>(1),
        args: {'outcome': o.name, if (f.skipReason != null) 'skipReason': f.skipReason},
      );
    }, () => _noOccurrence('PL-T-06')),
  ),
  metric<PlannerContext>(
    id: 'PL-T-07',
    scope: MetricScope.task,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    requires: _plannerTables,
    compute: (c) => _occ(c, (f) {
      final a = overdueAge(f, now: c.now);
      return result(
        'PL-T-07',
        a.map((x) => x.age.inSeconds / 60),
        unit: StatUnit.minutes,
        args: {if (a.valueOrNull case final x?) 'bucket': x.bucket.name},
        note: a.hasValue ? null : 'notOverdue',
      );
    }, () => _noOccurrence('PL-T-07')),
  ),

  // ---------------------------------------------------------------------------------------------
  // Series execution (T6.3.04)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-S-01',
    scope: MetricScope.series,
    unit: StatUnit.count,
    chart: ChartKind.kpi,
    direction: MetricDirection.neutral,
    requires: _plannerTables,
    compute: (c) {
      final l = c.seriesLedgerNow;
      return result(
        'PL-S-01',
        Value<double>(l.expected, sampleSize: l.expected),
        previous: c.compare ? Value<double>(c.seriesLedgerPrevious.expected) : null,
        args: {'closed': l.expectedClosed, 'open': l.pending},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-02',
    scope: MetricScope.series,
    unit: StatUnit.count,
    chart: ChartKind.stackedBars,
    requires: _plannerTables,
    compute: (c) {
      final l = c.seriesLedgerNow;
      const tokens = [LabelToken.done, LabelToken.missed, LabelToken.skipped, LabelToken.excused];
      const tones = [ChartTone.done, ChartTone.missed, ChartTone.skipped, ChartTone.excused];
      final values = [l.done, l.missed + l.failed, l.skipped, l.excused - (l.skipped > l.excused ? 0 : l.skipped)];
      return result(
        'PL-S-02',
        Value<double>(l.done, sampleSize: l.denominator),
        chart: BarData(
          const [TokenLabel(LabelToken.current)],
          [
            for (var i = 0; i < tokens.length; i++)
              BarSeries(TokenLabel(tokens[i]), [math.max(0, values[i])], color: ToneColor(tones[i])),
          ],
          layout: BarLayout.stacked,
          drillKeys: const ['all'],
        ),
        args: {'done': l.done, 'missed': l.missed, 'failed': l.failed, 'skipped': l.skipped, 'excused': l.excused},
        drill: {'all': c.refs(c.seriesIn(c.range))},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-03',
    scope: MetricScope.series,
    unit: StatUnit.percent,
    chart: ChartKind.line,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _plannerTables,
    compute: (c) {
      final l = c.seriesLedgerNow;
      final t = seriesAdherenceTrend(
        c.seriesToDate,
        now: c.now,
        from: c.seriesStart,
        to: c.today,
        random: math.Random(7),
        weekStart: c.weekStart,
        settings: c.ps,
      );
      final chart = TimeSeriesData(
        [for (final p in t.weekly) p.bucket],
        [
          ChartSeries(const TokenLabel(LabelToken.rate), [for (final p in t.weekly) p.value]),
          ChartSeries(
            const TokenLabel(LabelToken.rollingMean),
            t.rolling4Weeks,
            color: const SeriesColor(1),
            role: SeriesRole.rollingMean,
          ),
        ],
        granularity: Granularity.week,
        unit: StatUnit.percent,
        trend: trendOf([for (final p in t.weekly) p.value], granularity: Granularity.week, isRate: true),
      );
      return result(
        'PL-S-03',
        l.adherence,
        unit: StatUnit.percent,
        isRate: true,
        previous: c.compare ? c.seriesLedgerPrevious.adherence : null,
        chart: chart,
        spark: sparkOf([for (final p in t.weekly) p.value]),
        exclusions: {'skipped': l.skipped, 'excused': l.excused - l.skipped, 'cancelled': l.cancelled},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-04',
    scope: MetricScope.series,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _plannerTables,
    compute: (c) => result(
      'PL-S-04',
      c.seriesLedgerNow.missRate,
      unit: StatUnit.percent,
      isRate: true,
      previous: c.compare ? c.seriesLedgerPrevious.missRate : null,
    ),
  ),
  metric<PlannerContext>(
    id: 'PL-S-05',
    scope: MetricScope.series,
    unit: StatUnit.count,
    chart: ChartKind.streakBars,
    requires: _plannerTables,
    compute: (c) {
      final s = c.seriesStreakSummary;
      return result(
        'PL-S-05',
        Value<double>(s.currentLength.toDouble()),
        unit: StatUnit.count,
        chart: streaksOf(s, unit: StatUnit.count),
        args: {
          'best': s.bestLength,
          'currentSpan': s.currentCalendarSpan,
          'bestSpan': s.bestCalendarSpan,
          if (s.best != null) 'bestFrom': s.best!.startDate.toIso(),
          if (s.best != null) 'bestTo': s.best!.endDate.toIso(),
        },
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-06',
    scope: MetricScope.series,
    unit: StatUnit.minutes,
    chart: ChartKind.line,
    requires: _plannerTables,
    compute: (c) {
      final t = seriesTimeInvested(c.seriesToDate);
      final dates = {for (final p in t.actual) p.$1, for (final p in t.planned) p.$1}.toList()..sort();
      final actual = {for (final p in t.actual) p.$1: p.$2};
      final planned = {for (final p in t.planned) p.$1: p.$2};
      final total = t.actual.isEmpty ? 0.0 : t.actual.last.$2;
      final plannedTotal = t.planned.isEmpty ? 0.0 : t.planned.last.$2;
      return result(
        'PL-S-06',
        Value<double>(total),
        unit: StatUnit.minutes,
        args: {'planned': plannedTotal},
        chart: TimeSeriesData(
          dates,
          [
            ChartSeries(const TokenLabel(LabelToken.actual), [for (final d in dates) actual[d]]),
            ChartSeries(const TokenLabel(LabelToken.planned), [
              for (final d in dates) planned[d],
            ], color: const SeriesColor(1)),
          ],
          unit: StatUnit.minutes,
          cumulative: true,
        ),
        note: c.seriesToDate.any((f) => f.hasActualTime) ? null : Reasons.notTracked,
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-07',
    scope: MetricScope.series,
    unit: StatUnit.count,
    chart: ChartKind.kpi,
    requires: _plannerTables,
    compute: (c) => result('PL-S-07', countOf(seriesTotalDone(c.seriesToDate))),
  ),
  metric<PlannerContext>(
    id: 'PL-S-08',
    scope: MetricScope.series,
    unit: StatUnit.days,
    chart: ChartKind.kpi,
    direction: MetricDirection.lowerIsBetter,
    requires: _plannerTables,
    compute: (c) {
      final l = seriesLastDone(c.seriesToDate, clock: c.clock, today: c.today);
      return result(
        'PL-S-08',
        l.map((x) => x.daysSince.toDouble()),
        unit: StatUnit.days,
        args: {if (l.valueOrNull case final x?) 'date': x.date.toIso()},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-S-09',
    scope: MetricScope.series,
    unit: StatUnit.count,
    chart: ChartKind.calendar,
    requires: _plannerTables,
    compute: (c) {
      final cal = seriesOutcomeCalendar(c.seriesToDate, now: c.now, settings: c.ps);
      final byDate = <String, List<PlannerOccurrenceFact>>{};
      for (final f in c.seriesToDate) {
        final d = f.plannedDate;
        if (d != null) byDate.putIfAbsent(d.toIso(), () => []).add(f);
      }
      return chartResult(
        'PL-S-09',
        CalendarData(
          {
            for (final e in cal.entries)
              e.key: CalendarCell(tone: _calendarTone(e.value), label: TokenLabel(_calendarToken(e.value))),
          },
          from: LocalDate.max(c.seriesStart, c.today.minusDays(364)),
          to: c.today,
          today: c.today,
        ),
        drill: {for (final e in byDate.entries) e.key: c.refs(e.value)},
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Section execution & flow (T6.3.07)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-X-01',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _eventTables,
    compute: (c) {
      final s = c.snapshot;
      return result(
        'PL-X-01',
        s.completionRate,
        unit: StatUnit.percent,
        isRate: true,
        previous: c.compare ? c.previousSnapshot.completionRate : null,
        spark: _dailyCompletionSpark(c),
        args: {'planned': s.planned.length, 'done': s.plannedDone.length},
        exclusions: {'unplanned': s.unplanned.length},
        drill: {'planned': c.refs(s.planned), 'done': c.refs(s.plannedDone)},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-02',
    scope: MetricScope.planner,
    unit: StatUnit.count,
    chart: ChartKind.groupedBars,
    requires: _eventTables,
    compute: (c) {
      final perDay = donePlannedPerDay(c.snapshot, bounds: c.bounds);
      final days = c.range.dates.toList();
      return chartResult(
        'PL-X-02',
        BarData(
          [for (final d in days) DateLabel(d)],
          [
            BarSeries(const TokenLabel(LabelToken.planned), [
              for (final d in days) (perDay[d]?.planned ?? 0).toDouble(),
            ], color: const SeriesColor(1)),
            BarSeries(const TokenLabel(LabelToken.done), [
              for (final d in days) (perDay[d]?.done ?? 0).toDouble(),
            ], color: const ToneColor(ChartTone.done)),
          ],
          drillKeys: [for (final d in days) d.toIso()],
          isTimeAxis: true,
        ),
        value: Value<double>(c.snapshot.plannedDone.length.toDouble()),
        drill: c.refsByDate(c.snapshot.planned),
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-03',
    scope: MetricScope.planner,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    requires: _eventTables,
    compute: (c) {
      final s = c.snapshot;
      return chartResult(
        'PL-X-03',
        TilesData([
          ValueTile(
            const TokenLabel(LabelToken.unplanned),
            s.unplanned.length.toDouble(),
            StatUnit.count,
            drillKey: 'unplanned',
          ),
          ValueTile(
            const TokenLabel(LabelToken.movedOut),
            s.movedOut.length.toDouble(),
            StatUnit.count,
            drillKey: 'movedOut',
          ),
          ValueTile(
            const TokenLabel(LabelToken.movedIn),
            s.movedIn.length.toDouble(),
            StatUnit.count,
            drillKey: 'movedIn',
          ),
        ]),
        value: Value<double>((s.unplanned.length + s.movedOut.length + s.movedIn.length).toDouble()),
        drill: {'unplanned': c.refs(s.unplanned), 'movedOut': c.refs(s.movedOut), 'movedIn': c.refs(s.movedIn)},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-04',
    scope: MetricScope.planner,
    unit: StatUnit.count,
    chart: ChartKind.groupedBars,
    direction: MetricDirection.lowerIsBetter,
    requires: _plannerTables,
    compute: (c) {
      final flow = backlogFlow(
        taskCreatedAt: c.section.taskCreatedAt,
        facts: c.facts,
        unscheduledOpenTasks: c.section.unscheduledOpen,
        bounds: c.bounds,
        range: c.range,
        now: c.now,
        weekStart: c.weekStart,
      );
      return result(
        'PL-X-04',
        Value<double>(flow.openBacklog.toDouble()),
        chart: BarData(
          [for (final p in flow.created) DateLabel(p.bucket, Granularity.week)],
          [
            BarSeries(const TokenLabel(LabelToken.created), [
              for (final p in flow.created) p.value,
            ], color: const SeriesColor(1)),
            BarSeries(const TokenLabel(LabelToken.completed), [
              for (final p in flow.completed) p.value,
            ], color: const ToneColor(ChartTone.done)),
          ],
          isTimeAxis: true,
        ),
        args: {'unscheduled': c.section.unscheduledOpen},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-05',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _plannerTables,
    compute: (c) => result(
      'PL-X-05',
      onTimeCompletionRate(c.periodFacts, now: c.now, settings: c.ps),
      unit: StatUnit.percent,
      isRate: true,
      previous: c.compare ? onTimeCompletionRate(c.previousFacts, now: c.now, settings: c.ps) : null,
    ),
  ),
  metric<PlannerContext>(
    id: 'PL-X-06',
    scope: MetricScope.planner,
    unit: StatUnit.count,
    chart: ChartKind.bars,
    direction: MetricDirection.lowerIsBetter,
    requires: _plannerTables,
    compute: (c) {
      final o = overdueNow(c.facts, now: c.now, bounds: c.bounds, range: c.range, weekStart: c.weekStart);
      final overdue = [
        for (final f in c.facts)
          if (overdueAge(f, now: c.now).hasValue) f,
      ];
      return result(
        'PL-X-06',
        Value<double>(o.count.toDouble()),
        chart: BarData(
          [for (final b in OverdueBucket.values) TokenLabel(_bucketToken(b))],
          [
            BarSeries(const TokenLabel(LabelToken.count), [
              for (final b in OverdueBucket.values) (o.byBucket[b] ?? 0).toDouble(),
            ], color: const ToneColor(ChartTone.missed)),
          ],
          drillKeys: [for (final b in OverdueBucket.values) b.name],
        ),
        drill: {
          for (final b in OverdueBucket.values)
            b.name: c.refs(overdue.where((f) => overdueAge(f, now: c.now).valueOrNull?.bucket == b)),
        },
        args: {'newlyThisPeriod': o.newlyOverduePerWeek.fold<double>(0, (a, p) => a + p.value)},
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Capacity & utilization (T6.3.08)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-X-07',
    scope: MetricScope.planner,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.neutral,
    requires: {..._plannerTables, StatsTable.userSettings, StatsTable.categories},
    compute: (c) => result(
      'PL-X-07',
      Value<double>(c.capacity.capacityMinutes),
      unit: StatUnit.minutes,
      previous: c.compare ? Value<double>(c.previousCapacity.capacityMinutes) : null,
    ),
  ),
  metric<PlannerContext>(
    id: 'PL-X-08',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.stackedBars,
    direction: MetricDirection.neutral,
    isRate: true,
    requires: {..._plannerTables, StatsTable.userSettings},
    compute: (c) {
      final days = c.capacity.days;
      return result(
        'PL-X-08',
        c.capacity.plannedUtilization,
        unit: StatUnit.percent,
        isRate: true,
        previous: c.compare ? c.previousCapacity.plannedUtilization : null,
        chart: BarData(
          [for (final d in days) DateLabel(d.date)],
          [
            BarSeries(const TokenLabel(LabelToken.planned), [
              for (final d in days) d.plannedMinutes,
            ], color: const SeriesColor(0)),
          ],
          unit: StatUnit.minutes,
          overlays: [
            BarOverlay(const TokenLabel(LabelToken.capacity), [for (final d in days) d.capacityMinutes]),
          ],
          drillKeys: [for (final d in days) d.date.toIso()],
          isTimeAxis: true,
        ),
        drill: c.refsByDate(c.periodFacts),
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-09',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.bars,
    direction: MetricDirection.neutral,
    isRate: true,
    requires: {..._plannerTables, StatsTable.userSettings},
    compute: (c) {
      final days = c.capacity.days;
      return result(
        'PL-X-09',
        c.capacity.actualUtilization,
        unit: StatUnit.percent,
        isRate: true,
        previous: c.compare ? c.previousCapacity.actualUtilization : null,
        args: {'coverage': c.capacity.actualTimeCoverage},
        chart: BarData(
          [for (final d in days) DateLabel(d.date)],
          [
            BarSeries(const TokenLabel(LabelToken.actual), [
              for (final d in days) d.actualClippedMinutes,
            ], color: const SeriesColor(2)),
          ],
          unit: StatUnit.minutes,
          overlays: [
            BarOverlay(const TokenLabel(LabelToken.capacity), [for (final d in days) d.capacityMinutes]),
          ],
          isTimeAxis: true,
        ),
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-10',
    scope: MetricScope.planner,
    unit: StatUnit.count,
    chart: ChartKind.bars,
    direction: MetricDirection.lowerIsBetter,
    requires: {..._plannerTables, StatsTable.userSettings},
    compute: (c) {
      final over = c.capacity.overbookedDays;
      final days = c.capacity.days;
      return result(
        'PL-X-10',
        Value<double>(over.length.toDouble()),
        previous: c.compare ? Value<double>(c.previousCapacity.overbookedDays.length.toDouble()) : null,
        chart: BarData(
          [for (final d in days) DateLabel(d.date)],
          [
            BarSeries(const TokenLabel(LabelToken.over), [
              for (final d in days) d.overbookedMinutes,
            ], color: const ToneColor(ChartTone.warning)),
          ],
          unit: StatUnit.minutes,
          drillKeys: [for (final d in days) d.date.toIso()],
          isTimeAxis: true,
        ),
        args: {
          'overbookedMinutes': over.fold<double>(0, (a, d) => a + d.overbookedMinutes),
          'days': [for (final d in over) d.date.toIso()],
        },
        drill: c.refsByDate(c.periodFacts),
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-11',
    scope: MetricScope.planner,
    unit: StatUnit.minutes,
    chart: ChartKind.kpi,
    direction: MetricDirection.neutral,
    requires: {..._plannerTables, StatsTable.userSettings},
    compute: (c) {
      if (c.range.end.isBefore(c.today)) return MetricResult.notApplicable('PL-X-11', 'pastPeriod');
      return result(
        'PL-X-11',
        Value<double>(remainingFreeMinutes(c.periodFacts, range: c.range, now: c.now, clock: c.clock, settings: c.ps)),
        unit: StatUnit.minutes,
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-12',
    scope: MetricScope.planner,
    unit: StatUnit.minutes,
    chart: ChartKind.groupedBars,
    direction: MetricDirection.neutral,
    requires: _plannerTables,
    compute: (c) {
      final days = c.capacity.days;
      final planned = c.capacity.plannedMinutes;
      final actual = c.capacity.actualMinutes;
      final byCategory = plannedVsActualByCategory(c.periodFacts);
      return result(
        'PL-X-12',
        Value<double>(actual),
        unit: StatUnit.minutes,
        previous: c.compare ? Value<double>(c.previousCapacity.actualMinutes) : null,
        args: {
          'planned': planned,
          'byCategory': {
            for (final e in byCategory.entries) e.key ?? '': [e.value.planned, e.value.actual],
          },
        },
        chart: BarData(
          [for (final d in days) DateLabel(d.date)],
          [
            BarSeries(const TokenLabel(LabelToken.planned), [
              for (final d in days) d.plannedMinutes,
            ], color: const SeriesColor(1)),
            BarSeries(const TokenLabel(LabelToken.actual), [
              for (final d in days) d.actualMinutes,
            ], color: const SeriesColor(0)),
          ],
          unit: StatUnit.minutes,
          drillKeys: [for (final d in days) d.date.toIso()],
          isTimeAxis: true,
        ),
        drill: c.refsByDate(c.periodFacts),
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Time allocation (T6.3.09)
  // ---------------------------------------------------------------------------------------------
  metric<PlannerContext>(
    id: 'PL-X-13',
    scope: MetricScope.planner,
    unit: StatUnit.minutes,
    chart: ChartKind.donut,
    direction: MetricDirection.neutral,
    requires: {..._plannerTables, StatsTable.categories},
    compute: (c) {
      final t = timeByCategory(c.periodFacts);
      final total = t.slices.fold<double>(0, (a, s) => a + s.minutes);
      final byCategory = groupBy(c.periodFacts, (PlannerOccurrenceFact f) => f.categoryId ?? '');
      return result(
        'PL-X-13',
        total == 0 ? const NotApplicable<double>(Reasons.noData) : Value<double>(total),
        unit: StatUnit.minutes,
        chart: DonutData([
          for (final s in t.slices)
            DonutSlice(c.categoryLabel(s.key), s.minutes, color: c.categoryColor(s.key), drillKey: s.key ?? ''),
        ], unit: StatUnit.minutes),
        note: t.usedPlanned ? 'usedPlanned' : null,
        args: {
          'shares': {for (final s in t.slices) s.key ?? '': s.share},
        },
        drill: {for (final e in byCategory.entries) e.key: c.refs(e.value)},
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-14',
    scope: MetricScope.planner,
    unit: StatUnit.minutes,
    chart: ChartKind.stackedBars,
    direction: MetricDirection.neutral,
    requires: {..._plannerTables, StatsTable.categories},
    compute: (c) {
      final trend = categoryTrend(c.periodFacts, range: c.range, weekStart: c.weekStart);
      final keys = trend.keys.toList()
        ..sort(
          (a, b) => trend[b]!
              .fold<double>(0, (s, p) => s + p.value)
              .compareTo(trend[a]!.fold<double>(0, (s, p) => s + p.value)),
        );
      final buckets = trend.isEmpty ? <LocalDate>[] : [for (final p in trend[keys.first]!) p.bucket];
      return chartResult(
        'PL-X-14',
        BarData(
          [for (final b in buckets) DateLabel(b, Granularity.week)],
          [
            for (final k in keys)
              BarSeries(c.categoryLabel(k), [for (final p in trend[k]!) p.value], color: c.categoryColor(k)),
          ],
          layout: BarLayout.stacked,
          unit: StatUnit.minutes,
          isTimeAxis: true,
        ),
        unit: StatUnit.minutes,
      );
    },
  ),
  metric<PlannerContext>(
    id: 'PL-X-15',
    scope: MetricScope.planner,
    unit: StatUnit.percent,
    chart: ChartKind.percentBars,
    direction: MetricDirection.neutral,
    requires: _plannerTables,
    compute: (c) {
      final m = eventVsTaskMinutes(c.periodFacts);
      final total = m.event + m.task;
      return result(
        'PL-X-15',
        safeDivide(m.event, total),
        unit: StatUnit.percent,
        args: {'eventMinutes': m.event, 'taskMinutes': m.task},
        chart: BarData(
          const [TokenLabel(LabelToken.current)],
          [
            BarSeries(const TokenLabel(LabelToken.event), [m.event], color: const SeriesColor(3)),
            BarSeries(const TokenLabel(LabelToken.task), [m.task], color: const SeriesColor(0)),
          ],
          layout: BarLayout.percent,
          unit: StatUnit.minutes,
        ),
      );
    },
  ),
];

List<double?> _dailyCompletionSpark(PlannerContext c) {
  final perDay = donePlannedPerDay(c.snapshot, bounds: c.bounds);
  return sparkOf([
    for (final d in c.elapsed.dates)
      if (perDay[d] case final p?) p.planned == 0 ? null : p.done / p.planned else null,
  ]);
}

LabelToken _outcomeToken(PlannerOutcome o) => switch (o) {
  PlannerOutcome.doneOnTime => LabelToken.doneOnTime,
  PlannerOutcome.doneLate => LabelToken.doneLate,
  PlannerOutcome.partial => LabelToken.partial,
  PlannerOutcome.skipped => LabelToken.skipped,
  PlannerOutcome.missed => LabelToken.missed,
  PlannerOutcome.cancelled => LabelToken.cancelled,
  PlannerOutcome.pending => LabelToken.pending,
  PlannerOutcome.future => LabelToken.future,
  PlannerOutcome.notTracked => LabelToken.notTracked,
};

ChartTone _outcomeTone(PlannerOutcome o) => switch (o) {
  PlannerOutcome.doneOnTime => ChartTone.done,
  PlannerOutcome.doneLate => ChartTone.late,
  PlannerOutcome.partial => ChartTone.partial,
  PlannerOutcome.skipped => ChartTone.skipped,
  PlannerOutcome.missed => ChartTone.missed,
  PlannerOutcome.cancelled => ChartTone.cancelled,
  PlannerOutcome.pending => ChartTone.pending,
  PlannerOutcome.future => ChartTone.notDue,
  PlannerOutcome.notTracked => ChartTone.muted,
};

ChartTone _calendarTone(CalendarOutcome o) => switch (o) {
  CalendarOutcome.done => ChartTone.done,
  CalendarOutcome.late => ChartTone.late,
  CalendarOutcome.partial => ChartTone.partial,
  CalendarOutcome.missed => ChartTone.missed,
  CalendarOutcome.skipped => ChartTone.skipped,
  CalendarOutcome.excused => ChartTone.excused,
  CalendarOutcome.pending => ChartTone.pending,
};

LabelToken _calendarToken(CalendarOutcome o) => switch (o) {
  CalendarOutcome.done => LabelToken.done,
  CalendarOutcome.late => LabelToken.doneLate,
  CalendarOutcome.partial => LabelToken.partial,
  CalendarOutcome.missed => LabelToken.missed,
  CalendarOutcome.skipped => LabelToken.skipped,
  CalendarOutcome.excused => LabelToken.excused,
  CalendarOutcome.pending => LabelToken.pending,
};

LabelToken _bucketToken(OverdueBucket b) => switch (b) {
  OverdueBucket.underOneDay => LabelToken.overdueToday,
  OverdueBucket.oneDay => LabelToken.overdue1,
  OverdueBucket.sevenDays => LabelToken.overdue7,
  OverdueBucket.fourteenDays => LabelToken.overdue14,
  OverdueBucket.thirtyPlusDays => LabelToken.overdue30,
};
