/// Habit Insights catalog ([6.5]): per-habit (HB-H-*) and Habits section (HB-X-*) metrics on top of
/// the [5.1] period evaluation and the `everslot_metrics` habit calculators.
library;

import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:everslot/features/stats/application/catalog/catalog_support.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/habit_resolution.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/domain/zone_snapshot.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, Weekday;

/// Batch context of the habit scopes (habit, habits).
final class HabitContext extends StatsContext {
  HabitContext(super.job, super.resolver) : input = job.habits ?? const HabitInput();

  final HabitInput input;

  @override
  late final DayBoundaries bounds = dayBoundariesOf(resolver, env.zoneId, dayStartMinutes: env.dayStartMinutes);

  late final HabitResolver habits = HabitResolver(
    input,
    resolver: resolver,
    viewerZone: env.zoneId,
    now: now,
    dayStartMinutes: env.dayStartMinutes,
    weekStart: weekStart,
  );

  late final Map<String, HabitRecord> byId = {for (final h in input.habits) h.id: h};

  late final List<HabitRecord> buildHabits = [
    for (final h in input.habits)
      if (!h.isQuit && _matches(h)) h,
  ];

  bool _matches(HabitRecord h) {
    final f = request.filters;
    if (f.categoryIds.isNotEmpty && !f.categoryIds.contains(h.categoryId ?? '')) return false;
    return true;
  }

  final Map<String, HabitEvaluation> _evaluations = {};

  HabitEvaluation evaluation(HabitRecord h) => _evaluations.putIfAbsent(h.id, () => habits.evaluate(h));

  // -- Habit scope --------------------------------------------------------------------------------

  late final HabitRecord? habit = byId[scopeId];

  late final HabitEvaluation? eval = habit == null || habit!.isQuit ? null : evaluation(habit!);

  // -- Section scope ------------------------------------------------------------------------------

  late final List<HabitEvaluation> evaluations = [for (final h in buildHabits) evaluation(h)];

  late final List<HabitSeries> series = [for (final e in evaluations) e.series];

  late final List<QuitCalculator> quitCalculators = [
    for (final h in input.habits)
      if (h.isQuit && h.archivedAt == null)
        if (habits.quit(h) case final c?) c,
  ];

  DrillRef dayRef(String habitId, LocalDate d) =>
      DrillRef(DrillKind.day, habitId, extra: d.toIso(), title: byId[habitId]?.name);
}

MetricResult _noHabit(String id) => MetricResult.notApplicable(id, 'noHabit');

T _withHabit<T>(HabitContext c, T Function(HabitEvaluation e) f, T Function() none) {
  final e = c.eval;
  return e == null ? none() : f(e);
}

const _habitTables = {StatsTable.habits, StatsTable.habitLogs, StatsTable.habitPauses, StatsTable.habitRevisions};

ChartTone periodTone(PeriodStatus s) => switch (s) {
  PeriodStatus.done => ChartTone.done,
  PeriodStatus.partial => ChartTone.partial,
  PeriodStatus.failed => ChartTone.failed,
  PeriodStatus.missed => ChartTone.missed,
  PeriodStatus.skipped => ChartTone.skipped,
  PeriodStatus.excused => ChartTone.excused,
  PeriodStatus.frozen => ChartTone.frozen,
  PeriodStatus.paused => ChartTone.paused,
  PeriodStatus.pending => ChartTone.pending,
  PeriodStatus.notDue => ChartTone.notDue,
};

LabelToken periodToken(PeriodStatus s) => switch (s) {
  PeriodStatus.done => LabelToken.done,
  PeriodStatus.partial => LabelToken.partial,
  PeriodStatus.failed => LabelToken.failed,
  PeriodStatus.missed => LabelToken.missed,
  PeriodStatus.skipped => LabelToken.skipped,
  PeriodStatus.excused => LabelToken.excused,
  PeriodStatus.frozen => LabelToken.frozen,
  PeriodStatus.paused => LabelToken.paused,
  PeriodStatus.pending => LabelToken.pending,
  PeriodStatus.notDue => LabelToken.notDue,
};

/// Last value of a daily series per bucket (score lines by week/month).
List<SeriesPoint<double?>> lastPerBucket(
  List<StrengthPoint> series,
  DateRange range,
  Granularity g,
  Weekday weekStart,
) {
  final byBucket = <LocalDate, double>{};
  for (final p in series) {
    if (!range.contains(p.date)) continue;
    byBucket[bucketStart(p.date, g, weekStart: weekStart)] = p.score;
  }
  return [
    for (final b in bucketStarts(range.start, range.end, g, weekStart: weekStart)) SeriesPoint<double?>(b, byBucket[b]),
  ];
}

/// Every habit metric.
final List<MetricDefinition> habitMetrics = [
  // ---------------------------------------------------------------------------------------------
  // Strength & streaks (T6.5.02, T6.5.03)
  // ---------------------------------------------------------------------------------------------
  metric<HabitContext>(
    id: 'HB-H-01',
    scope: MetricScope.habit,
    unit: StatUnit.score,
    chart: ChartKind.line,
    requires: _habitTables,
    compute: (c) => _withHabit(c, (e) {
      final s = e.strength;
      final g = c.range.days <= 31 ? Granularity.day : c.granularity;
      final points = lastPerBucket(s.series, c.elapsed, g, c.weekStart);
      final d30 = s.deltaVsDaysAgo(30);
      return MetricResult(
        'HB-H-01',
        value: s.series.isEmpty ? const Insufficient<double>(1, 0) : Value<double>(s.current),
        unit: StatUnit.score,
        comparison: PeriodComparison(
          Value<double>(s.current),
          Value<double>(s.current - d30.valueOr(0)),
          delta: d30.map((v) => v * 100),
          deltaPct: const NotApplicable<double>('rateUsesPp'),
          isRate: true,
        ),
        chart: TimeSeriesData(
          [for (final p in points) p.bucket],
          [
            ChartSeries(const TokenLabel(LabelToken.score), [for (final p in points) p.value]),
          ],
          granularity: g,
          unit: StatUnit.score,
        ),
        spark: sparkOf([for (final p in lastPerBucket(s.series, c.elapsed, Granularity.day, c.weekStart)) p.value]),
        args: {
          if (d30.valueOrNull case final v?) 'delta30': v,
          if (s.deltaVsDaysAgo(365).valueOrNull case final v?) 'delta365': v,
          'frequency': e.versionOn(e.today).frequency.f,
        },
      );
    }, () => _noHabit('HB-H-01')),
  ),
  metric<HabitContext>(
    id: 'HB-H-02',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.kpi,
    requires: _habitTables,
    compute: (c) => _withHabit(c, (e) {
      final s = e.streaks;
      return result(
        'HB-H-02',
        Value<double>(s.currentLength.toDouble()),
        args: {
          'span': s.currentCalendarSpan,
          'unitKind': e.isQuota ? 'period' : 'day',
          'frozen': s.current?.frozenUnits ?? 0,
        },
      );
    }, () => _noHabit('HB-H-02')),
  ),
  metric<HabitContext>(
    id: 'HB-H-03',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.kpi,
    requires: _habitTables,
    compute: (c) => _withHabit(c, (e) {
      final s = e.streaks;
      return result(
        'HB-H-03',
        Value<double>(s.bestLength.toDouble()),
        args: {
          'span': s.bestCalendarSpan,
          'unitKind': e.isQuota ? 'period' : 'day',
          if (s.best != null) 'from': s.best!.startDate.toIso(),
          if (s.best != null) 'to': s.best!.endDate.toIso(),
        },
      );
    }, () => _noHabit('HB-H-03')),
  ),
  metric<HabitContext>(
    id: 'HB-H-04',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.streakBars,
    requires: _habitTables,
    compute: (c) => _withHabit(
      c,
      (e) => chartResult(
        'HB-H-04',
        streaksOf(e.streaks, unit: e.isQuota ? StatUnit.count : StatUnit.days),
        args: {'unitKind': e.isQuota ? 'period' : 'day'},
      ),
      () => _noHabit('HB-H-04'),
    ),
  ),

  // ---------------------------------------------------------------------------------------------
  // Success & outcomes (T6.5.04)
  // ---------------------------------------------------------------------------------------------
  metric<HabitContext>(
    id: 'HB-H-05',
    scope: MetricScope.habit,
    unit: StatUnit.percent,
    chart: ChartKind.kpi,
    isRate: true,
    minSample: MinDataRules.rate,
    requires: _habitTables,
    compute: (c) => _withHabit(c, (e) {
      final cur = successRate(e.units, from: c.range.start, to: c.range.end, skipPolicy: e.skipPolicy);
      final prev = successRate(e.units, from: c.previous.start, to: c.previous.end, skipPolicy: e.skipPolicy);
      final counts = outcomeCounts(e.units, from: c.range.start, to: c.range.end);
      final weekly = bucketRate(
        [
          for (final r in e.units)
            if (isClosedScheduled(r) && !isExcludedUnit(r, skipPolicy: e.skipPolicy))
              (r.endDate, r.status == PeriodStatus.done ? 1 : 0, 1),
        ],
        from: c.today.minusDays(83),
        to: c.today,
        granularity: Granularity.week,
        weekStart: c.weekStart,
      );
      return result(
        'HB-H-05',
        cur,
        unit: StatUnit.percent,
        isRate: true,
        previous: c.compare ? prev : null,
        spark: sparkOf([for (final p in weekly) p.value]),
        exclusions: {
          'skipped': e.skipPolicy == SkipPolicy.neutral ? counts.skipped : 0,
          'excused': counts.excused,
          'paused': counts.paused,
          'frozen': counts.frozen,
        },
        args: {
          for (final d in const [7, 30, 90, 365])
            'rate$d': successRate(
              e.units,
              from: c.today.minusDays(d - 1),
              to: c.today,
              skipPolicy: e.skipPolicy,
            ).valueOrNull,
          'rateAll': successRate(e.units, skipPolicy: e.skipPolicy).valueOrNull,
        },
      );
    }, () => _noHabit('HB-H-05')),
  ),
  metric<HabitContext>(
    id: 'HB-H-06',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.stackedBars,
    requires: _habitTables,
    compute: (c) => _withHabit(c, (e) {
      final o = outcomeCounts(e.units, from: c.range.start, to: c.range.end);
      final rows = <(LabelToken, ChartTone, int)>[
        (LabelToken.success, ChartTone.done, o.success),
        (LabelToken.partial, ChartTone.partial, o.partial),
        (LabelToken.failed, ChartTone.failed, o.failed),
        (LabelToken.missed, ChartTone.missed, o.missed),
        (LabelToken.skipped, ChartTone.skipped, o.skipped),
        (LabelToken.excused, ChartTone.excused, o.excused),
        (LabelToken.frozen, ChartTone.frozen, o.frozen),
        (LabelToken.paused, ChartTone.paused, o.paused),
      ];
      return result(
        'HB-H-06',
        Value<double>(o.total.toDouble()),
        chart: BarData(
          const [TokenLabel(LabelToken.total)],
          [
            for (final r in rows)
              if (r.$3 > 0) BarSeries(TokenLabel(r.$1), [r.$3.toDouble()], color: ToneColor(r.$2)),
          ],
          layout: BarLayout.stacked,
        ),
        args: {for (final r in rows) r.$1.name: r.$3},
      );
    }, () => _noHabit('HB-H-06')),
  ),
  metric<HabitContext>(
    id: 'HB-H-07',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.bars,
    requires: _habitTables,
    compute: (c) => _withHabit(c, (e) {
      final g = c.granularity == Granularity.day ? Granularity.week : c.granularity;
      final from = c.range.days < 60 ? c.today.minusDays(7 * 12 - 1) : c.range.start;
      final h = historyBuckets(e.streakUnits, from: from, to: c.today, granularity: g, weekStart: c.weekStart);
      final measurable = e.isMeasurable;
      return chartResult(
        'HB-H-07',
        BarData(
          [for (final p in h.successes) DateLabel(p.bucket, g)],
          [
            BarSeries(const TokenLabel(LabelToken.success), [
              for (final p in h.successes) p.value,
            ], color: const ToneColor(ChartTone.done)),
            if (measurable)
              BarSeries(const TokenLabel(LabelToken.volume), [
                for (final p in h.volume) p.value,
              ], color: const SeriesColor(1)),
          ],
          isTimeAxis: true,
        ),
        value: Value<double>(h.successes.fold<double>(0, (a, p) => a + p.value)),
        args: {'granularity': g.name},
      );
    }, () => _noHabit('HB-H-07')),
  ),
  metric<HabitContext>(
    id: 'HB-H-08',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.calendar,
    requires: _habitTables,
    compute: (c) => _withHabit(c, (e) {
      final cal = habitCalendar(e.dayResults);
      final from = LocalDate.max(e.habit.startDate, c.today.minusDays(364));
      return chartResult(
        'HB-H-08',
        CalendarData(
          {
            for (final entry in cal.entries)
              entry.key: CalendarCell(tone: periodTone(entry.value), label: TokenLabel(periodToken(entry.value))),
          },
          from: from,
          to: c.today,
          today: c.today,
        ),
        drill: {
          for (final d in cal.keys) d.toIso(): [c.dayRef(e.habit.id, d)],
        },
      );
    }, () => _noHabit('HB-H-08')),
  ),
  metric<HabitContext>(
    id: 'HB-H-09',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.kpi,
    requires: {StatsTable.habitLogs},
    compute: (c) =>
        _withHabit(c, (e) => result('HB-H-09', countOf(totalRepetitions(e.logs))), () => _noHabit('HB-H-09')),
  ),

  // ---------------------------------------------------------------------------------------------
  // Target & volume (T6.5.05)
  // ---------------------------------------------------------------------------------------------
  metric<HabitContext>(
    id: 'HB-H-10',
    scope: MetricScope.habit,
    unit: StatUnit.percent,
    chart: ChartKind.bullet,
    requires: _habitTables,
    compute: (c) => _withHabit(c, (e) {
      if (e.isLimit) return MetricResult.notApplicable('HB-H-10', 'limitHabit');
      final cur = targetProgress(e.units, from: c.range.start, to: c.range.end);
      final prev = targetProgress(e.units, from: c.previous.start, to: c.previous.end);
      final achieved = totalVolume(e.units, from: c.range.start, to: c.range.end);
      final target = cur.valueOrNull == null || cur.valueOrNull == 0 ? null : achieved / cur.valueOrNull!;
      return result(
        'HB-H-10',
        cur,
        unit: StatUnit.percent,
        previous: c.compare ? prev : null,
        chart: BulletData(
          actual: achieved,
          target: target,
          previous: prev.valueOrNull == null ? null : totalVolume(e.units, from: c.previous.start, to: c.previous.end),
          bands: target == null ? const [] : [target * 0.5, target * 0.8, target],
        ),
        args: {'achieved': achieved, if (target != null) 'target': target},
      );
    }, () => _noHabit('HB-H-10')),
  ),
  metric<HabitContext>(
    id: 'HB-H-11',
    scope: MetricScope.habit,
    unit: StatUnit.count,
    chart: ChartKind.line,
    requires: {StatsTable.habitLogs},
    compute: (c) => _withHabit(c, (e) {
      if (!e.isMeasurable) return MetricResult.notApplicable('HB-H-11', 'yesNoHabit');
      final inPeriod = totalVolume(e.units, from: c.range.start, to: c.range.end);
      final prev = totalVolume(e.units, from: c.previous.start, to: c.previous.end);
      final all = totalVolume(e.units);
      final days = [
        for (final d in e.dayFacts)
          if (!d.localDate.isAfter(c.today)) d,
      ];
      var run = 0.0;
      return result(
        'HB-H-11',
        Value<double>(inPeriod),
        previous: c.compare ? Value<double>(prev) : null,
        args: {'allTime': all, 'unit': e.habit.unit},
        chart: TimeSeriesData(
          [for (final d in days) d.localDate],
          [
            ChartSeries(const TokenLabel(LabelToken.volume), [for (final d in days) run += d.value]),
          ],
          cumulative: true,
          area: true,
        ),
      );
    }, () => _noHabit('HB-H-11')),
  ),

  // ---------------------------------------------------------------------------------------------
  // Habits section core (T6.5.13)
  // ---------------------------------------------------------------------------------------------
  metric<HabitContext>(
    id: 'HB-X-01',
    scope: MetricScope.habits,
    unit: StatUnit.percent,
    chart: ChartKind.ring,
    requires: _habitTables,
    compute: (c) {
      final p = todayProgress(c.series, today: c.today);
      var due = 0;
      var done = 0;
      for (final h in c.series) {
        for (final r in h.dayUnitsOn(c.today)) {
          if (!h.isDue(r)) continue;
          due++;
          if (r.status == PeriodStatus.done) done++;
        }
      }
      return result(
        'HB-X-01',
        p,
        unit: StatUnit.percent,
        chart: RingData([
          (const TokenLabel(LabelToken.habits), p.valueOr(0), const ToneColor(ChartTone.done)),
        ], centerValue: p.valueOrNull),
        args: {
          'done': done,
          'due': due,
          // Per-habit mini table of the Habits screen (T6.5.17): score, streak, 30-day success.
          'habits': [
            for (final e in c.evaluations)
              {
                'id': e.habit.id,
                'name': e.habit.name,
                'color': e.habit.color,
                'score': e.strength.current,
                'streak': e.streaks.currentLength,
                'rate30': successRate(e.units, from: c.today.minusDays(29), to: c.today, skipPolicy: e.skipPolicy).valueOrNull,
              },
          ],
        },
      );
    },
  ),
  metric<HabitContext>(
    id: 'HB-X-02',
    scope: MetricScope.habits,
    unit: StatUnit.count,
    chart: ChartKind.calendar,
    requires: _habitTables,
    compute: (c) {
      final p = perfectDays(c.series, range: c.elapsed, today: c.today);
      final prev = perfectDays(c.series, range: c.previous, today: c.today);
      final allTime = perfectDays(c.series, range: DateRange(c.today.minusDays(730), c.today), today: c.today);
      return result(
        'HB-X-02',
        Value<double>(p.perfectDays.length.toDouble()),
        previous: c.compare ? Value<double>(prev.perfectDays.length.toDouble()) : null,
        chart: CalendarData(
          {
            for (final d in p.perfectDays)
              d: const CalendarCell(tone: ChartTone.done, label: TokenLabel(LabelToken.done)),
          },
          from: c.elapsed.start,
          to: c.elapsed.end,
          today: c.today,
        ),
        args: {'streak': allTime.streak.currentLength, 'bestStreak': allTime.streak.bestLength},
      );
    },
  ),
  metric<HabitContext>(
    id: 'HB-X-03',
    scope: MetricScope.habits,
    unit: StatUnit.percent,
    chart: ChartKind.calendar,
    requires: _habitTables,
    compute: (c) {
      final range = c.range.days < 90 ? DateRange(c.today.minusDays(364), c.today) : c.elapsed;
      final heat = dailyCompletionHeatmap(c.series, range: range);
      return chartResult(
        'HB-X-03',
        CalendarData(
          {
            for (final p in heat)
              if (p.value != null) p.bucket: CalendarCell(value: p.value),
          },
          from: range.start,
          to: range.end,
          mode: CalendarMode.intensity,
          unit: StatUnit.percent,
          today: c.today,
          thresholds: const [0.2, 0.4, 0.6, 0.8],
        ),
        unit: StatUnit.percent,
      );
    },
  ),
  metric<HabitContext>(
    id: 'HB-X-04',
    scope: MetricScope.habits,
    unit: StatUnit.percent,
    chart: ChartKind.line,
    isRate: true,
    guard: MinDataGuard.calculator,
    requires: _habitTables,
    compute: (c) {
      final range = c.range.days < 84 ? DateRange(c.today.minusDays(83), c.today) : c.elapsed;
      final t = adherenceTrend(c.series, range: range, weekStart: c.weekStart);
      return MetricResult(
        'HB-X-04',
        value: t.lastVsPrevious.current,
        unit: StatUnit.percent,
        previous: t.lastVsPrevious.previous,
        comparison: t.lastVsPrevious,
        chart: TimeSeriesData(
          [for (final p in t.weekly) p.bucket],
          [
            ChartSeries(const TokenLabel(LabelToken.rate), [for (final p in t.weekly) p.value]),
            ChartSeries(
              const TokenLabel(LabelToken.rollingMean),
              t.rolling4,
              color: const SeriesColor(1),
              role: SeriesRole.rollingMean,
            ),
          ],
          granularity: Granularity.week,
          unit: StatUnit.percent,
          trend: trendOf([for (final p in t.weekly) p.value], granularity: Granularity.week, isRate: true),
        ),
        spark: sparkOf([for (final p in t.weekly) p.value]),
      );
    },
  ),
  metric<HabitContext>(
    id: 'HB-X-05',
    scope: MetricScope.habits,
    unit: StatUnit.currency,
    chart: ChartKind.tiles,
    estimate: true,
    requires: {StatsTable.habits, StatsTable.habitLogs, StatsTable.habitRevisions},
    compute: (c) {
      if (c.quitCalculators.isEmpty) return MetricResult.notApplicable('HB-X-05', 'noQuitTrackers');
      final r = quitRollUp(c.quitCalculators);
      final currency = r.moneySaved.keys.firstWhereOrNull((k) => k.isNotEmpty) ?? c.env.currency;
      final money = r.moneySaved[currency] ?? Decimal.zero;
      return result(
        'HB-X-05',
        Value<double>(money.toDouble()),
        unit: StatUnit.currency,
        currency: currency,
        chart: TilesData([
          ValueTile(const TokenLabel(LabelToken.money), money.toDouble(), StatUnit.currency),
          ValueTile(const TokenLabel(LabelToken.units), r.unitsAvoided, StatUnit.count),
          ValueTile(const TokenLabel(LabelToken.lifeRegained), r.lifeRegainedMinutes, StatUnit.minutes, estimate: true),
          ValueTile(const TokenLabel(LabelToken.abstinent), r.cleanDays.toDouble(), StatUnit.days),
        ]),
        args: {
          'trackers': c.quitCalculators.length,
          'otherCurrencies': [
            for (final k in r.moneySaved.keys)
              if (k != currency && k.isNotEmpty) k,
          ],
        },
      );
    },
  ),
];
