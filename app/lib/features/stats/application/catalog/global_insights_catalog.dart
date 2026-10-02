/// Overview reports & insights catalog ([6.7] P1/P2, GL-04…GL-19): review streak, monthly review,
/// personal records, day score, day-of-week effects, goals, year heatmap, correlations, year in
/// review, XP, time budget, Monte Carlo goal forecasts and the insights-feed candidates. Everything
/// is built from the per-day section facts of [GlobalContext] (and its history) plus the section
/// calculators, so every number matches the section screens.
library;

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:everslot/features/stats/application/catalog/catalog_support.dart';
import 'package:everslot/features/stats/application/catalog/global_catalog.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/quit_health_content.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, Weekday;

// -------------------------------------------------------------------------------------------------
// Shared helpers
// -------------------------------------------------------------------------------------------------

double _sum(Iterable<DaySectionFacts> days, num? Function(DaySectionFacts d) pick) =>
    days.fold<double>(0, (a, d) => a + (pick(d) ?? 0));

Decimal _money(Iterable<DaySectionFacts> days) => days.fold(Decimal.zero, (a, d) => a + (d.moneySaved ?? Decimal.zero));

/// Stable 32-bit FNV-1a hash (seeds Monte Carlo runs per goal, identical across isolates).
int stableHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// The month reviewed by GL-05: `extra` `current` (this month so far), `YYYY-MM`, else the last
/// completed month.
LocalDate reviewMonthStart(GlobalContext c) {
  final extra = c.request.extra;
  if (extra == 'current') return c.today.firstDayOfMonth;
  if (extra != null && RegExp(r'^\d{4}-\d{2}$').hasMatch(extra)) {
    return LocalDate(int.parse(extra.substring(0, 4)), int.parse(extra.substring(5)), 1);
  }
  return c.today.firstDayOfMonth.plusMonths(-1);
}

/// The year of GL-11/GL-14: `extra` `YYYY`, else the closing year from Dec 15 to Jan 31 and the
/// current year otherwise.
int reviewYear(GlobalContext c) {
  final extra = c.request.extra;
  if (extra != null && RegExp(r'^\d{4}$').hasMatch(extra)) return int.parse(extra);
  return c.today.month == 1 ? c.today.year - 1 : c.today.year;
}

// -------------------------------------------------------------------------------------------------
// GL-06 personal records
// -------------------------------------------------------------------------------------------------

/// Record types of GL-06 (label tokens and units).
enum RecordType {
  habitStreak(LabelToken.recordHabitStreak, StatUnit.days),
  tasksDay(LabelToken.recordTasksDay, StatUnit.count),
  actualWeek(LabelToken.recordActualWeek, StatUnit.hours),
  deepWorkWeek(LabelToken.recordDeepWorkWeek, StatUnit.hours),
  habitMaxDay(LabelToken.recordHabitMaxDay, StatUnit.count),
  habitVolumeWeek(LabelToken.recordHabitVolumeWeek, StatUnit.count),
  abstinence(LabelToken.recordAbstinence, StatUnit.days),
  itemsWeek(LabelToken.recordItemsWeek, StatUnit.count),
  perfectStreak(LabelToken.recordPerfectStreak, StatUnit.days),
  completionWeek(LabelToken.recordCompletionWeek, StatUnit.percent),
  moneyMonth(LabelToken.recordMoneyMonth, StatUnit.currency);

  RecordType(this.token, this.unit);

  final LabelToken token;
  final StatUnit unit;
}

/// One personal record with its entity (habit / tracker) when per entity.
typedef PersonalRecord = ({RecordType type, String? entityId, RecordEntry entry});

typedef _Point = ({LocalDate date, double value, num? denominator});

/// Runs of consecutive true days ([flags] chronological; null = neutral, bridged): one point per
/// run, dated on its last day.
List<_Point> _runs(List<(LocalDate, bool?)> flags) {
  final points = <_Point>[];
  var length = 0;
  LocalDate? last;
  for (final (d, ok) in flags) {
    if (ok == null) continue;
    if (ok) {
      length++;
      last = d;
    } else if (length > 0) {
      points.add((date: last!, value: length.toDouble(), denominator: null));
      length = 0;
    }
  }
  if (length > 0) points.add((date: last!, value: length.toDouble(), denominator: null));
  return points;
}

final _records = Expando<List<PersonalRecord>>('records');
final _goals = Expando<List<GoalView>>('goals');

/// GL-06 — every personal record over the history; "new" when set within the last 7 days and
/// above everything before (so backfilled old data never produces a record dated today). Memoized
/// per batch (GL-05, GL-06, GL-14 and GL-19 share it).
List<PersonalRecord> personalRecords(GlobalContext c) => _records[c] ??= _personalRecords(c);

List<PersonalRecord> _personalRecords(GlobalContext c) {
  final since = c.today.minusDays(6);
  final days = [
    for (final d in c.historyDays)
      if (!d.date.isAfter(c.today)) d,
  ];
  final out = <PersonalRecord>[];
  void add(RecordType type, List<_Point> series, {String? entityId, num? minDenominator}) {
    final r = personalRecord(
      entityId == null ? type.name : '${type.name}:$entityId',
      series,
      currentPeriodStart: since,
      minBucketDenominator: minDenominator,
    );
    if (r case Value<RecordEntry>(:final value) when value.value > 0) {
      out.add((type: type, entityId: entityId, entry: value));
    }
  }

  List<_Point> bucketed(LocalDate Function(LocalDate) key, double Function(List<DaySectionFacts>) value) => [
    for (final e in groupBy(days, (d) => key(d.date)).entries)
      (date: e.value.last.date, value: value(e.value), denominator: null),
  ];
  LocalDate week(LocalDate d) => d.startOfWeek(c.weekStart);

  if (c.hasPlanner) {
    final doneByDay = <LocalDate, int>{};
    for (final f in c.historyPlanner.facts) {
      if (f.status != PlannerOccurrenceStatus.done || f.doneAt == null || !f.trackingMode.countsForCompletion) continue;
      final d = c.bounds.dateOf(f.doneAt!);
      doneByDay[d] = (doneByDay[d] ?? 0) + 1;
    }
    add(RecordType.tasksDay, [
      for (final e in doneByDay.entries) (date: e.key, value: e.value.toDouble(), denominator: null),
    ]);
    add(RecordType.actualWeek, bucketed(week, (w) => _sum(w, (d) => d.actualMinutes) / 60));
    add(RecordType.deepWorkWeek, bucketed(week, (w) => _sum(w, (d) => d.deepWorkMinutes) / 60));
    add(RecordType.completionWeek, [
      for (final e in groupBy(days, (d) => week(d.date)).entries)
        if (_sum(e.value, (d) => d.plannerPlanned) > 0)
          (
            date: e.value.last.date,
            value: _sum(e.value, (d) => d.plannerDone) / _sum(e.value, (d) => d.plannerPlanned),
            denominator: _sum(e.value, (d) => d.plannerPlanned),
          ),
    ], minDenominator: 10);
  }
  if (c.hasLists) add(RecordType.itemsWeek, bucketed(week, (w) => _sum(w, (d) => d.itemsCompleted)));
  if (c.hasQuit) {
    add(RecordType.moneyMonth, bucketed((d) => d.firstDayOfMonth, (m) => _money(m).toDouble()));
    for (final (h, q) in c.habits.quitTrackers) {
      add(RecordType.abstinence, [
        for (final i in q.abstinenceIntervals)
          (
            date: c.bounds.dateOf(i.end ?? c.now),
            value: (i.end ?? c.now).difference(i.start).inMinutes / 1440,
            denominator: null,
          ),
      ], entityId: h.id);
    }
  }
  if (c.hasHabits) {
    add(
      RecordType.perfectStreak,
      _runs([
        for (final d in days)
          (
            d.date,
            (d.habitsDue ?? 0) == 0 ? null : (d.habitsDone == d.habitsDue ? true : (d.date == c.today ? null : false)),
          ),
      ]),
    );
    final allStreaks = <_Point>[];
    for (final e in c.habits.evaluations) {
      final streaks = [
        for (final s in e.streaks.streaks) (date: s.endDate, value: s.length.toDouble(), denominator: null),
      ];
      allStreaks.addAll(streaks);
      add(RecordType.habitStreak, streaks, entityId: e.habit.id);
      if (e.isMeasurable && !e.isLimit) {
        final byDay = <LocalDate, double>{};
        for (final r in e.dayResults) {
          if (r.achieved > 0 && !r.startDate.isAfter(c.today)) {
            byDay[r.startDate] = (byDay[r.startDate] ?? 0) + r.achieved;
          }
        }
        add(RecordType.habitMaxDay, [
          for (final x in byDay.entries) (date: x.key, value: x.value, denominator: null),
        ], entityId: e.habit.id);
        add(RecordType.habitVolumeWeek, [
          for (final w in groupBy(byDay.entries, (x) => week(x.key)).entries)
            (
              date: w.value.map((x) => x.key).reduce(LocalDate.max),
              value: w.value.fold<double>(0, (a, x) => a + x.value),
              denominator: null,
            ),
        ], entityId: e.habit.id);
      }
    }
    add(RecordType.habitStreak, allStreaks);
  }
  return out;
}

// -------------------------------------------------------------------------------------------------
// GL-09 / GL-18 goals
// -------------------------------------------------------------------------------------------------

/// The inclusive dates a goal covers as of [asOf] (the goals feature's `Goal.window`): the
/// current year / quarter / month / week (not before `start_date`), the custom range, or for
/// all-time goals `start_date` (else [origin]) with an open end (projected over 10 years).
(LocalDate, LocalDate, bool) goalWindowOf(
  GoalRecord g,
  LocalDate asOf, {
  required Weekday weekStart,
  required LocalDate origin,
}) {
  LocalDate clip(LocalDate s) => g.startDate != null && g.startDate!.isAfter(s) ? g.startDate! : s;
  switch (g.period) {
    case 'custom':
      final s = g.startDate ?? origin;
      return (s, g.endDate ?? s.plusDays(3649), g.endDate == null);
    case 'year':
      return (clip(LocalDate(asOf.year, 1, 1)), LocalDate(asOf.year, 12, 31), false);
    case 'quarter':
      final first = LocalDate(asOf.year, ((asOf.month - 1) ~/ 3) * 3 + 1, 1);
      return (clip(first), first.plusMonths(3).minusDays(1), false);
    case 'month':
      return (clip(asOf.firstDayOfMonth), asOf.lastDayOfMonth, false);
    case 'week':
      final first = asOf.startOfWeek(weekStart);
      return (clip(first), first.plusDays(6), false);
    default:
      final s = g.startDate ?? origin;
      return (s, g.endDate ?? s.plusDays(3649), g.endDate == null);
  }
}

/// A goal with its progress (GL-09) and daily contributions (GL-18).
typedef GoalView = ({
  GoalRecord goal,
  GoalProgress progress,
  Map<LocalDate, double> daily,
  bool openEnded,
  ChartLabel label,
  DrillRef? ref,
});

/// GL-09 — progress of every goal: habit goals exactly as HB-H-26 (day results), quit goals from
/// the tracker's days, series / category / checklist / global goals from the section facts.
List<GoalView> goalViews(GlobalContext c) => _goals[c] ??= _goalViews(c);

List<GoalView> _goalViews(GlobalContext c) {
  final goals = {
    for (final g in [...?c.job.habits?.goals, ...?c.job.planner?.goals]) g.id: g,
  }.values.toList();
  final result = <GoalView>[];
  for (final g in goals) {
    final daily = <LocalDate, double>{};
    void add(LocalDate d, double v) {
      if (v != 0) daily[d] = (daily[d] ?? 0) + v;
    }

    double? actual;
    double? rate;
    var origin = c.firstDataDate ?? c.today;
    ChartLabel label = TextLabel(g.title ?? '');
    DrillRef? ref;
    switch (g.scopeType) {
      case 'habit':
        final h = c.habits.byId[g.scopeId];
        if (h == null) continue;
        origin = h.startDate;
        if (g.title == null) label = TextLabel(h.name);
        if (h.isQuit) {
          ref = DrillRef(DrillKind.quit, h.id, title: h.name);
          final q = c.habits.quitTrackers.firstWhereOrNull((t) => t.$1.id == h.id)?.$2;
          if (q == null) continue;
          switch (g.metric) {
            case 'clean_days':
              for (final d in q.days) {
                if (d.closed && d.status == QuitDayStatus.clean) add(d.localDate, 1);
              }
            case 'money_saved':
              for (final (d, amount) in q.moneySavedByDay) {
                add(d, amount.toDouble());
              }
            case 'units_avoided':
              for (final d in q.days) {
                add(d.localDate, d.avoided);
              }
            default:
              continue;
          }
        } else {
          ref = DrillRef(DrillKind.habit, h.id, title: h.name);
          final e = c.habits.evaluation(h);
          switch (g.metric) {
            case 'completions':
              for (final r in e.dayResults) {
                if (r.status == PeriodStatus.done) add(r.startDate, 1);
              }
            case 'total_value' || 'volume':
              for (final r in e.dayResults) {
                add(r.startDate, r.achieved);
              }
            case 'streak_days':
              actual = e.streaks.currentLength.toDouble();
              rate = actual > 0 ? 1 : 0;
            default:
              continue;
          }
        }
      case 'series' || 'category' || 'global':
        bool inScope(PlannerOccurrenceFact f) => switch (g.scopeType) {
          'series' => f.seriesId == g.scopeId,
          'category' => f.categoryId == g.scopeId,
          _ => true,
        };
        if (g.scopeType == 'category') label = g.title == null ? c.planner.categoryLabel(g.scopeId) : label;
        if (g.metric == 'items_completed') {
          for (final t in completionInstants(c.lists.sectionFacts)) {
            add(c.bounds.dateOf(t), 1);
          }
        } else {
          for (final f in c.historyPlanner.facts) {
            if (!inScope(f)) continue;
            if (g.metric == 'completions') {
              if (f.status == PlannerOccurrenceStatus.done && f.doneAt != null) add(c.bounds.dateOf(f.doneAt!), 1);
            } else if (g.metric == 'tracked_minutes') {
              for (final s in f.effectiveSessions) {
                add(c.bounds.dateOf(s.start), s.end.difference(s.start).inSeconds / 60);
              }
            }
          }
        }
        if (g.scopeType == 'series') {
          final f = c.historyPlanner.facts.firstWhereOrNull((f) => f.seriesId == g.scopeId);
          if (g.title == null && f?.title != null) label = TextLabel(f!.title!);
          if (f != null) ref = DrillRef(DrillKind.task, f.taskId, title: f.title);
        }
      case 'checklist':
        final list = c.lists.data.listById(g.scopeId ?? '');
        if (list == null) continue;
        if (g.title == null) label = TextLabel(list.title);
        ref = DrillRef(DrillKind.checklist, list.id, title: list.title);
        for (final t in completionInstants(c.lists.sectionFacts, checklistId: list.id)) {
          add(c.bounds.dateOf(t), 1);
        }
      default:
        continue;
    }
    final (start, end, open) = goalWindowOf(g, c.today, weekStart: c.weekStart, origin: origin);
    daily.removeWhere((d, _) => d.isBefore(start) || d.isAfter(end) || d.isAfter(c.today));
    final progress = goalProgress(
      GoalSpec(g.target, start: start, end: end),
      asOf: LocalDate.min(c.today, end),
      dailyValues: daily,
      actual: actual,
      recentDailyRate: rate,
    );
    result.add((goal: g, progress: progress, daily: daily, openEnded: open, label: label, ref: ref));
  }
  return result;
}

LabelToken _statusToken(GoalStatus s) => switch (s) {
  GoalStatus.achieved => LabelToken.achieved,
  GoalStatus.onTrack => LabelToken.onTrack,
  GoalStatus.behind => LabelToken.behind,
  GoalStatus.atRisk => LabelToken.atRisk,
};

ChartTone _statusTone(GoalStatus s) => switch (s) {
  GoalStatus.achieved => ChartTone.done,
  GoalStatus.onTrack => ChartTone.positive,
  GoalStatus.behind => ChartTone.warning,
  GoalStatus.atRisk => ChartTone.negative,
};

// -------------------------------------------------------------------------------------------------
// GL-13 correlations
// -------------------------------------------------------------------------------------------------

/// Candidate daily series of GL-13 over [r] (today excluded: an open day biases every series).
List<DailySeries> correlationSeries(GlobalContext c, DateRange r) {
  final days = c.daysIn(r).where((d) => d.date.isBefore(c.today)).toList();
  Map<LocalDate, double> pick(double? Function(DaySectionFacts d) f) => {
    for (final d in days)
      if (f(d) case final v?) d.date: v,
  };
  final series = <DailySeries>[
    if (c.hasPlanner) ...[
      DailySeries(
        'plannerRate',
        values: pick((d) => (d.plannerPlanned ?? 0) == 0 ? null : d.plannerDone! / d.plannerPlanned!),
        binary: false,
        groupKey: 'plannerRate',
      ),
      DailySeries(
        'plannedHours',
        values: pick((d) => d.plannedMinutes == null ? null : d.plannedMinutes! / 60),
        binary: false,
        groupKey: 'plannerTime',
      ),
      DailySeries(
        'actualHours',
        values: pick((d) => d.actualMinutes == null ? null : d.actualMinutes! / 60),
        binary: false,
        groupKey: 'plannerTime',
      ),
      DailySeries(
        'deepWork',
        values: pick((d) => d.deepWorkMinutes == null ? null : d.deepWorkMinutes! / 60),
        binary: false,
        groupKey: 'plannerTime',
      ),
    ],
    if (c.hasLists)
      DailySeries('items', values: pick((d) => d.itemsCompleted?.toDouble()), binary: false, groupKey: 'lists'),
    if (c.hasQuit) ...[
      DailySeries('cravings', values: pick((d) => d.cravings?.toDouble()), binary: false, groupKey: 'quit'),
      DailySeries(
        'quitUse',
        values: pick((d) => d.quitAbstinent == null ? null : (d.quitAbstinent! ? 0.0 : 1.0)),
        binary: true,
        groupKey: 'quit',
      ),
    ],
    if (days.any((d) => d.mood != null))
      DailySeries('mood', values: pick((d) => d.mood), binary: false, groupKey: 'mood'),
  ];
  for (final e in c.habits.evaluations) {
    final flags = <LocalDate, double>{};
    final values = <LocalDate, double>{};
    for (final u in e.dayResults) {
      if (!r.contains(u.startDate) || !u.startDate.isBefore(c.today) || !isClosedScheduled(u)) continue;
      if (isExcludedUnit(u, skipPolicy: e.skipPolicy)) continue;
      flags[u.startDate] = u.status == PeriodStatus.done ? 1 : 0;
      if (e.isMeasurable) values[u.startDate] = u.achieved;
    }
    series.add(DailySeries('habit:${e.habit.id}', values: flags, binary: true, groupKey: 'habit:${e.habit.id}'));
    if (e.isMeasurable) {
      series.add(DailySeries('value:${e.habit.id}', values: values, binary: false, groupKey: 'habit:${e.habit.id}'));
    }
  }
  return [
    for (final s in series)
      if (s.values.length >= 21) s,
  ];
}

/// Label of a GL-13 series id.
ChartLabel correlationLabel(GlobalContext c, String id) {
  if (id.startsWith('habit:')) return TextLabel(c.habits.byId[id.substring(6)]?.name ?? '');
  if (id.startsWith('value:')) return TextLabel('${c.habits.byId[id.substring(6)]?.name ?? ''} #');
  return TokenLabel(switch (id) {
    'plannerRate' => LabelToken.agenda,
    'plannedHours' => LabelToken.planned,
    'actualHours' => LabelToken.actual,
    'deepWork' => LabelToken.deepWork,
    'items' => LabelToken.items,
    'cravings' => LabelToken.cravings,
    'quitUse' => LabelToken.used,
    'mood' => LabelToken.mood,
    _ => LabelToken.other,
  });
}

// -------------------------------------------------------------------------------------------------
// GL-15 XP
// -------------------------------------------------------------------------------------------------

/// GL-15 — XP events derived from the current state (an undone completion is no longer done, so
/// undo removes its XP; creating items earns nothing).
List<XpEvent> xpEvents(GlobalContext c) {
  final events = <XpEvent>[];
  for (final f in c.historyPlanner.facts) {
    if (f.status != PlannerOccurrenceStatus.done || f.doneAt == null || !f.trackingMode.countsForCompletion) continue;
    final o = plannerOutcome(f, now: c.now, settings: c.historyPlanner.ps);
    events.add(
      XpEvent(f.doneAt!, XpSource.taskCompletion, priority: f.priority, onTime: o == PlannerOutcome.doneOnTime),
    );
  }
  for (final e in c.habits.evaluations) {
    var streak = 0;
    for (final u in e.dayResults) {
      if (u.startDate.isAfter(c.today)) break;
      if (u.status == PeriodStatus.done) {
        streak++;
        final at = u.entries.isEmpty
            ? c.bounds.startOf(u.startDate).add(const Duration(hours: 12))
            : u.entries.last.loggedAt;
        events.add(XpEvent(at, XpSource.habitCheckIn, streak: streak - 1));
      } else if (isClosedScheduled(u) && !isExcludedUnit(u, skipPolicy: e.skipPolicy)) {
        streak = 0;
      }
    }
  }
  for (final t in completionInstants(c.lists.sectionFacts)) {
    events.add(XpEvent(t, XpSource.checklistLeaf));
  }
  for (final q in c.habits.quitCalculators) {
    for (final d in q.closedDays) {
      if (d.abstinent) {
        events.add(XpEvent(c.bounds.startOf(d.localDate).add(const Duration(hours: 12)), XpSource.abstinentDay));
      }
    }
  }
  return events;
}

// -------------------------------------------------------------------------------------------------
// GL-19 insight candidates
// -------------------------------------------------------------------------------------------------

/// JSON form of a candidate insight (sent from the isolate, stored in `insight_state.payload`).
Map<String, Object?> insightJson(Insight i, {DrillRef? ref, String? metricId, String? name}) => {
  'trigger': i.trigger.name,
  'entity': i.entityId,
  'value': i.valueKey,
  'key': i.dedupeKey,
  'args': {
    for (final e in i.args.entries)
      e.key: switch (e.value) {
        final LocalDate d => d.toIso(),
        final List<LocalDate> ds => [for (final d in ds) d.toIso()],
        final Weekday w => w.code,
        final v => v,
      },
    'name': ?name,
  },
  if (metricId != null) 'metric': metricId,
  if (ref != null) 'ref': {'kind': ref.kind.name, 'id': ref.id, if (ref.extra != null) 'extra': ref.extra},
};

/// Every insight trigger of T6.7.08 evaluated on the current data (the feed service filters them
/// with the local `insight_state` and the muted trigger types).
List<Map<String, Object?>> insightCandidates(GlobalContext c) {
  final out = <Map<String, Object?>>[];
  final today = c.today;
  final habitName = {for (final h in c.habits.input.habits) h.id: h.name};
  DrillRef habitRef(String id) => DrillRef(DrillKind.habit, id, title: habitName[id]);

  // 1 — new personal records.
  for (final r in personalRecords(c)) {
    if (newRecordInsight(r.entry) case final i?) {
      out.add(
        insightJson(
            i,
            metricId: 'GL-06',
            name: r.entityId == null ? null : habitName[r.entityId],
            ref: r.entityId == null ? null : habitRef(r.entityId!),
          )
          ..['args'] = {
            ...(insightJson(i)['args']! as Map<String, Object?>),
            'type': r.type.name,
            if (r.entityId != null) 'name': habitName[r.entityId],
          },
      );
    }
  }
  if (c.hasHabits) {
    for (final e in c.habits.evaluations) {
      final id = e.habit.id;
      // 2 — streak milestones (crossed within the last 7 days).
      final current = e.streaks.currentLength;
      final before = habitStreaks(
        [
          for (final u in e.streakUnits)
            if (!u.endDate.isAfter(today.minusDays(7))) u,
        ],
        skipPolicy: e.skipPolicy,
        freezesPerMonth: e.habit.freezesPerMonth,
      ).currentLength;
      for (final i in streakMilestoneInsights(id, before, current)) {
        out.add(insightJson(i, metricId: 'HB-H-02', ref: habitRef(id), name: e.habit.name));
      }
      // 3 — significant adherence trend over the last 8+ weeks.
      final weekly = <double?>[
        for (var w = 11; w >= 0; w--)
          successRate(
            e.outcomeUnits,
            from: today.minusDays(7 * w + 6),
            to: today.minusDays(7 * w),
            skipPolicy: e.skipPolicy,
          ).valueOrNull,
      ];
      if (trend(weekly, bucketDays: 7, random: math.Random(stableHash(id))) case Value<TrendResult>(:final value)) {
        if (significantTrendInsight(id, value, today: today) case final i?) {
          out.add(insightJson(i, metricId: 'HB-H-05', ref: habitRef(id), name: e.habit.name));
        }
      }
      // 15 — habit at risk.
      final scores = e.strength.series;
      final drop = scores.length < 8 ? 0.0 : scores[scores.length - 8].score - scores.last.score;
      final quotaBehind = e.units.any(
        (u) => u.kind == HabitPeriodKind.quota && u.status == PeriodStatus.pending && u.flags.atRisk,
      );
      if (habitAtRiskInsight(id, quotaBehind: quotaBehind, scoreDrop7Days: drop, today: today) case final i?) {
        out.add(insightJson(i, metricId: 'HB-X-07', ref: habitRef(id), name: e.habit.name));
      }
      // 16 — strength thresholds crossed in the last 7 days.
      for (final i in strengthThresholdInsights(id, [for (final p in scores) (p.date, p.score)])) {
        final date = LocalDate.tryParse('${i.args['date']}');
        if (date != null && !date.isBefore(today.minusDays(6))) {
          out.add(insightJson(i, metricId: 'HB-H-01', ref: habitRef(id), name: e.habit.name));
        }
      }
      // 17 — comebacks in the last 7 days.
      final outcomes = [
        for (final u in e.outcomeUnits)
          if (isClosedScheduled(u) && !isExcludedUnit(u, skipPolicy: e.skipPolicy))
            (u.endDate, u.status == PeriodStatus.done),
      ];
      for (final i in comebackInsights(id, outcomes)) {
        if (!LocalDate.parse(i.valueKey).isBefore(today.minusDays(6))) {
          out.add(insightJson(i, metricId: 'HB-H-22', ref: habitRef(id), name: e.habit.name));
        }
      }
    }
    // 13 — perfect habit week (the last completed week).
    final lastWeek = c.thisWeekStart.minusDays(7);
    if (perfectWeekInsight(c.daysIn(DateRange(lastWeek, lastWeek.plusDays(6))), weekStart: lastWeek) case final i?) {
      out.add(insightJson(i, metricId: 'HB-X-02'));
    }
  }
  if (c.hasPlanner) {
    // 4 — estimation bias over the last 30 days.
    final last30 = c.historyPlanner.plannedIn(c.last30);
    final bias = estimationAccuracy(last30).bias;
    if (estimationBiasInsight(bias, today: today) case final i?) out.add(insightJson(i, metricId: 'PL-X-21'));
    // 5 — rising overdue (now vs 4 weeks ago).
    int overdueAt(DateTime at) => [
      for (final f in c.historyPlanner.facts)
        if (overdueAge(f, now: at).hasValue && f.plannedStart != null && f.plannedStart!.isBefore(at)) f,
    ].length;
    final nowCount = overdueAt(c.now);
    final before = overdueAt(c.now.subtract(const Duration(days: 28)));
    if (risingOverdueInsight(nowCount, before, today: today) case final i?) {
      out.add(insightJson(i, metricId: 'PL-X-06'));
    }
    // 6 — overbooked days next week.
    final next = DateRange(c.thisWeekStart.plusDays(7), c.thisWeekStart.plusDays(13));
    final over = [
      for (final d in capacityReport(
        c.planner.plannedIn(next),
        range: next,
        clock: c.planner.clock,
        settings: c.planner.ps,
      ).days)
        if (d.capacityMinutes > 0 && d.plannedMinutes > d.capacityMinutes) d.date,
    ];
    if (overbookedNextWeekInsight(over, weekStart: next.start) case final i?) {
      out.add(insightJson(i, metricId: 'PL-X-08'));
    }
  }
  if (c.hasLists) {
    final facts = c.lists.sectionFacts.where((f) => !f.isDeleted).toList();
    // 7 — blocker clusters (normalized reasons, user merges applied).
    final episodes = [
      for (final f in facts)
        for (final e in f.timeline.intervals)
          if (e.status == 'blocked' && e.note != null)
            (
              cluster: c.settings.blockerClusters[normalizeReason(e.note!)] ?? normalizeReason(e.note!),
              startedAt: e.start,
            ),
    ];
    for (final i in blockerClusterInsights(episodes, now: c.now)) {
      out.add(insightJson(i, metricId: 'CL-X-06'));
    }
    // 8 — follow-ups due.
    final overdueFollowUps = followUpDiscipline(facts, now: c.now).overdue.length;
    if (followUpsDueInsight(overdueFollowUps, today: today) case final i?) out.add(insightJson(i, metricId: 'CL-X-03'));
    // 9 — stale lists.
    final stale = listsOverview(
      c.lists.data.lists,
      c.lists.data.facts,
      now: c.now,
      staleDays: c.settings.staleDays,
    ).staleListIds;
    for (final id in stale) {
      final last = c.lists.data
          .factsOf(id)
          .map((f) => f.lastActivityAt)
          .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
      final list = c.lists.data.listById(id);
      final daysInactive = last == null ? c.settings.staleDays : c.now.difference(last).inDays;
      if (staleListInsight(id, daysInactive, threshold: list?.staleAfterDays ?? c.settings.staleDays) case final i?) {
        out.add(
          insightJson(
            i,
            metricId: 'CL-X-01',
            ref: DrillRef(DrillKind.checklist, id, title: list?.title),
            name: list?.title,
          ),
        );
      }
    }
  }
  for (final (h, q) in c.habits.quitTrackers) {
    final id = h.id;
    final ref = DrillRef(DrillKind.quit, id, title: h.name);
    // 10 — falling cravings.
    int cravingsIn(LocalDate from, LocalDate to) => q.logs
        .where((l) => l.kind == HabitLogKind.craving && !l.localDate.isBefore(from) && !l.localDate.isAfter(to))
        .length;
    final last7 = cravingsIn(today.minusDays(6), today);
    final prev7 = cravingsIn(today.minusDays(13), today.minusDays(7));
    if (fallingCravingsInsight(id, last7: last7, previous7: prev7, today: today) case final i?) {
      out.add(insightJson(i, metricId: 'QT-13', ref: ref, name: h.name));
    }
    // 11 — health milestones reached within the last 7 days (smoking).
    if (q.tracker.substance == smokingSubstance) {
      final start = q.currentAbstinenceStart;
      for (final m in smokingHealthMilestones) {
        final at = start.add(m.tMax ?? m.tMin);
        if (!at.isAfter(c.now) && c.now.difference(at) <= const Duration(days: 7)) {
          out.add(
            insightJson(healthMilestoneInsight(id, m.id, q.attempts.length), metricId: 'QT-11', ref: ref, name: h.name)
              ..['args'] = {'milestone': m.id, 'name': h.name},
          );
        }
      }
    }
    // 12 — money thresholds crossed within the last 7 days.
    final byDay = q.moneySavedByDay;
    var total = Decimal.zero;
    var weekAgo = Decimal.zero;
    for (final (d, amount) in byDay) {
      total += amount;
      if (d.isBefore(today.minusDays(6))) weekAgo += amount;
    }
    for (final i in moneyMilestoneInsights(id, weekAgo, total)) {
      out.add(
        insightJson(i, metricId: 'QT-07', ref: ref, name: h.name)
          ..['args'] = {'amount': i.args['amount'], 'currency': q.tracker.currency ?? c.env.currency, 'name': h.name},
      );
    }
  }
  // 14 — best weekday (habit success).
  final effect = dayOfWeekEffect(_dailyOf(c, _WeekdayMetric.habits));
  if (effect case Value<WeekdayEffect>(:final value)) {
    if (bestWeekdayInsight('habits', value, today: today) case final i?) out.add(insightJson(i, metricId: 'GL-08'));
  }
  // 18 — significant correlations (P2).
  for (final f in correlationExplorer(correlationSeries(c, DateRange(today.minusDays(180), today))).take(3)) {
    if (correlationInsight(f, today: today) case final i?) {
      out.add(
        insightJson(i, metricId: 'GL-13')
          ..['args'] = {...i.args, 'a': f.a, 'b': f.b, 'aName': _seriesName(c, f.a), 'bName': _seriesName(c, f.b)},
      );
    }
  }
  return out;
}

String? _seriesName(GlobalContext c, String id) => switch (correlationLabel(c, id)) {
  TextLabel(:final text) => text,
  TokenLabel(:final token) => token.name,
  _ => null,
};

// -------------------------------------------------------------------------------------------------
// GL-08 day-of-week effects
// -------------------------------------------------------------------------------------------------

enum _WeekdayMetric {
  planner(LabelToken.agenda, StatUnit.percent),
  habits(LabelToken.habits, StatUnit.percent),
  items(LabelToken.items, StatUnit.count),
  cravings(LabelToken.cravings, StatUnit.count),
  deepWork(LabelToken.deepWork, StatUnit.hours);

  _WeekdayMetric(this.token, this.unit);

  final LabelToken token;
  final StatUnit unit;
}

/// Daily values of [m] over the last 26 weeks (today excluded).
Map<LocalDate, double> _dailyOf(GlobalContext c, _WeekdayMetric m) => {
  for (final d in c.daysIn(DateRange(c.today.minusDays(182), c.today.minusDays(1))))
    if (switch (m) {
          _WeekdayMetric.planner => (d.plannerPlanned ?? 0) == 0 ? null : d.plannerDone! / d.plannerPlanned!,
          _WeekdayMetric.habits => (d.habitsDue ?? 0) == 0 ? null : d.habitsDone! / d.habitsDue!,
          _WeekdayMetric.items => d.itemsCompleted?.toDouble(),
          _WeekdayMetric.cravings => d.cravings?.toDouble(),
          _WeekdayMetric.deepWork => d.deepWorkMinutes == null ? null : d.deepWorkMinutes! / 60,
        }
        case final v?)
      d.date: v,
};

// -------------------------------------------------------------------------------------------------
// Metrics
// -------------------------------------------------------------------------------------------------

const _goalTables = {...globalTables, StatsTable.goals};

/// Every P1/P2 overview metric.
final List<MetricDefinition> globalInsightMetrics = [
  // ---------------------------------------------------------------------------------------------
  // Guided weekly review streak (T6.7.03)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-04',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.kpi,
    priority: MetricPriority.p1,
    requires: {StatsTable.activityEvents},
    compute: (c) {
      // The week due for review is the last completed one; it stays open until reviewed.
      final due = c.thisWeekStart.minusDays(7);
      final reviewed = {for (final w in c.job.reviewedWeeks) w.startOfWeek(c.weekStart)};
      if (reviewed.isEmpty) {
        return result('GL-04', const Value<double>(0), args: const {'longest': 0, 'reviewedDue': false});
      }
      final s = weeklyReviewStreak(
        reviewed,
        firstWeekStart: LocalDate.min(reviewed.reduce(LocalDate.min), due),
        currentWeekStart: due,
      );
      return result(
        'GL-04',
        Value<double>(s.currentLength.toDouble()),
        args: {'longest': s.bestLength, 'reviewedDue': reviewed.contains(due), 'week': due.toIso()},
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Monthly review (T6.7.04)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-05',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: globalTables,
    compute: (c) {
      final start = reviewMonthStart(c);
      final month = DateRange(start, LocalDate.min(start.lastDayOfMonth, c.today));
      final prevStart = start.plusMonths(-1);
      final prev = DateRange(prevStart, prevStart.lastDayOfMonth);
      final yoyStart = start.plusMonths(-12);
      final yoy = DateRange(yoyStart, LocalDate.min(yoyStart.lastDayOfMonth, yoyStart.plusDays(month.days - 1)));
      final hasYoy = c.firstDataDate != null && !c.firstDataDate!.isAfter(yoyStart);
      final cur = c.daysIn(month);
      final before = c.daysIn(prev);
      final lastYear = hasYoy ? c.daysIn(yoy) : const <DaySectionFacts>[];
      final currency = c.currency();
      final kpis = <(String, LabelToken, StatUnit, MetricDirection, PeriodComparison, PeriodComparison?)>[];
      PeriodComparison perDay(
        num Function(List<DaySectionFacts>) sum,
        List<DaySectionFacts> a,
        List<DaySectionFacts> b,
      ) => perDayComparison(currentSum: sum(a), currentDays: a.length, previousSum: sum(b), previousDays: b.length);
      PeriodComparison rateOf(
        List<DaySectionFacts> a,
        List<DaySectionFacts> b,
        num? Function(DaySectionFacts) n,
        num? Function(DaySectionFacts) d,
      ) => compareWithPrevious(rate(_sum(a, n), _sum(a, d)), rate(_sum(b, n), _sum(b, d)), isRate: true);
      if (c.hasPlanner) {
        kpis
          ..add((
            'PL-X-01',
            LabelToken.agenda,
            StatUnit.percent,
            MetricDirection.higherIsBetter,
            rateOf(cur, before, (d) => d.plannerDone, (d) => d.plannerPlanned),
            hasYoy ? rateOf(cur, lastYear, (d) => d.plannerDone, (d) => d.plannerPlanned) : null,
          ))
          ..add((
            'PL-X-12',
            LabelToken.actual,
            StatUnit.hours,
            MetricDirection.neutral,
            perDay((x) => _sum(x, (d) => d.actualMinutes) / 60, cur, before),
            hasYoy ? perDay((x) => _sum(x, (d) => d.actualMinutes) / 60, cur, lastYear) : null,
          ));
      }
      if (c.hasHabits) {
        final lastYearRange = hasYoy ? yoy : null;
        kpis.add((
          'HB-X-04',
          LabelToken.habits,
          StatUnit.percent,
          MetricDirection.higherIsBetter,
          compareWithPrevious(habitAdherenceIn(c, month), habitAdherenceIn(c, prev), isRate: true),
          lastYearRange == null
              ? null
              : compareWithPrevious(habitAdherenceIn(c, month), habitAdherenceIn(c, lastYearRange), isRate: true),
        ));
      }
      if (c.hasLists) {
        kpis.add((
          'CL-X-04',
          LabelToken.items,
          StatUnit.count,
          MetricDirection.higherIsBetter,
          perDay((x) => _sum(x, (d) => d.itemsCompleted), cur, before),
          hasYoy ? perDay((x) => _sum(x, (d) => d.itemsCompleted), cur, lastYear) : null,
        ));
      }
      if (c.hasQuit) {
        kpis.add((
          'QT-07',
          LabelToken.money,
          StatUnit.currency,
          MetricDirection.higherIsBetter,
          perDay((x) => _money(x).toDouble(), cur, before),
          hasYoy ? perDay((x) => _money(x).toDouble(), cur, lastYear) : null,
        ));
      }
      // Wins: streak milestones, perfect days, records set during the month.
      final wins = <ReviewEntry>[];
      for (final e in c.habits.evaluations) {
        StreakSummary upTo(LocalDate d) => habitStreaks(
          [
            for (final u in e.streakUnits)
              if (!u.endDate.isAfter(d)) u,
          ],
          skipPolicy: e.skipPolicy,
          freezesPerMonth: e.habit.freezesPerMonth,
        );
        final crossed = streakMilestonesCrossed(
          upTo(month.start.minusDays(1)).currentLength,
          upTo(month.end).currentLength,
        );
        if (crossed.isNotEmpty) {
          wins.add(
            ReviewEntry(
              ReviewEntryKind.streakMilestone,
              ref: DrillRef(DrillKind.habit, e.habit.id, title: e.habit.name),
              title: e.habit.name,
              value: crossed.last.toDouble(),
            ),
          );
        }
      }
      final perfect = cur.where((d) => (d.habitsDue ?? 0) > 0 && d.habitsDone == d.habitsDue).length;
      if (perfect > 0) wins.add(ReviewEntry(ReviewEntryKind.perfectDays, value: perfect.toDouble()));
      for (final r in personalRecords(c)) {
        if (month.contains(r.entry.date) && r.entry.previous != null && r.entry.value > r.entry.previous!) {
          wins.add(
            ReviewEntry(ReviewEntryKind.newRecord, title: r.type.name, value: r.entry.value, date: r.entry.date),
          );
        }
      }
      final activity = yearActivityHeatmap(cur);
      List<({String? categoryId, double minutes})> byCategory(DateRange r) => [
        for (final s in timeByCategory(c.historyPlanner.plannedIn(r)).slices) (categoryId: s.key, minutes: s.minutes),
      ];
      final prevCats = {for (final x in byCategory(prev)) x.categoryId: x.minutes};
      final cats = byCategory(month)..sort((a, b) => b.minutes.compareTo(a.minutes));
      return chartResult(
        'GL-05',
        ReviewData(
          from: month.start,
          to: start.lastDayOfMonth,
          perDay: true,
          headline: [
            for (final k in kpis)
              ValueTile(
                TokenLabel(k.$2),
                k.$5.current.valueOrNull,
                k.$3,
                delta: k.$5.delta.valueOrNull,
                deltaIsPp: k.$5.isRate,
                direction: k.$4,
                metricId: k.$1,
                currency: k.$3 == StatUnit.currency ? currency : null,
              ),
          ],
          wins: wins,
          topCategories: [
            for (final x in cats.take(3))
              (
                c.planner.categoryLabel(x.categoryId),
                x.minutes,
                prevCats[x.categoryId] == null
                    ? null
                    // Per-day normalized Δ in minutes over the month's length.
                    : x.minutes - prevCats[x.categoryId]! * month.days / prev.days,
              ),
          ],
          calendar: CalendarData(
            {for (final a in activity) a.date: CalendarCell(value: a.total.toDouble(), breakdown: _breakdown(a))},
            from: month.start,
            to: start.lastDayOfMonth,
            mode: CalendarMode.intensity,
            today: c.today,
          ),
        ),
        value: Value<double>(kpis.length.toDouble()),
        args: {
          'month': '${start.year}-${start.month.toString().padLeft(2, '0')}',
          'days': month.days,
          'previousDays': prev.days,
          'perDay': true,
          'current': c.request.extra == 'current',
          'yoy': {
            for (final k in kpis)
              if (k.$6 != null) k.$1: k.$6!.delta.valueOrNull,
          },
        },
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Personal records (T6.7.05)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-06',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.list,
    priority: MetricPriority.p1,
    requires: globalTables,
    compute: (c) {
      final records = personalRecords(c);
      final names = {for (final h in c.habits.input.habits) h.id: h.name};
      ListRow row(PersonalRecord r) => ListRow(
        r.entityId == null ? TokenLabel(r.type.token) : TextLabel(names[r.entityId] ?? ''),
        value: r.entry.value,
        unit: r.type.unit,
        secondary: r.entityId == null ? DateLabel(r.entry.date) : TokenLabel(r.type.token),
        tone: r.entry.isNew ? ChartTone.positive : null,
        ref: r.entityId == null
            ? null
            : DrillRef(
                c.habits.byId[r.entityId]?.isQuit ?? false ? DrillKind.quit : DrillKind.habit,
                r.entityId!,
                title: names[r.entityId],
              ),
      );
      final overall = [
        for (final r in records)
          if (r.entityId == null) r,
      ];
      final perEntity = [
        for (final r in records)
          if (r.entityId != null) r,
      ]..sort((a, b) => b.entry.date.compareTo(a.entry.date));
      return chartResult(
        'GL-06',
        ChartGroup([
          (const TokenLabel(LabelToken.total), ListData([for (final r in overall) row(r)])),
          if (perEntity.isNotEmpty)
            (const TokenLabel(LabelToken.habits), ListData([for (final r in perEntity) row(r)])),
        ]),
        value: Value<double>(records.where((r) => r.entry.isNew).length.toDouble()),
        currency: c.currency(),
        args: {
          'records': [
            for (final r in records)
              {
                'type': r.type.name,
                'entity': ?r.entityId,
                'value': r.entry.value,
                'date': r.entry.date.toIso(),
                'previous': r.entry.previous,
                'isNew': r.entry.isNew,
                'key': r.entry.announceKey,
              },
          ],
          'toAnnounce': [
            for (final r in recordsToAnnounce([for (final r in records) r.entry], c.settings.announcedRecords))
              r.announceKey,
          ],
        },
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Day score (T6.7.06)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-07',
    scope: MetricScope.global,
    unit: StatUnit.score,
    chart: ChartKind.line,
    priority: MetricPriority.p1,
    requires: {...globalTables, StatsTable.userSettings},
    compute: (c) {
      final w = c.settings.dayScoreWeights;
      final weights = DayScoreWeights(
        planner: w['planner'] ?? 1,
        habits: w['habits'] ?? 1,
        lists: w['lists'] ?? 1,
        quit: w['quit'] ?? 1,
      );
      // 28 shown days, each needing 28 prior scores and a 28-active-day lists median.
      final series = dayScoreSeries(c.daysIn(DateRange(c.today.minusDays(119), c.today)), weights: weights);
      final shown = series.where((p) => !p.date.isBefore(c.today.minusDays(27))).toList();
      final todayPoint = series.lastWhereOrNull((p) => p.date == c.today);
      final score = todayPoint?.score ?? const NotApplicable<double>(Reasons.noData);
      final prior = [
        for (final p in series)
          if (p.date.isBefore(c.today) && !p.date.isBefore(c.today.minusDays(28))) ?p.score.valueOrNull,
      ];
      final p25 = quantile(prior, 0.25).valueOrNull;
      final p75 = quantile(prior, 0.75).valueOrNull;
      final med = median(prior).valueOrNull;
      final todayFacts = c.byDate[c.today];
      return result(
        'GL-07',
        score.map((s) => s / 100),
        unit: StatUnit.score,
        chart: TimeSeriesData(
          [for (final p in shown) p.date],
          [
            ChartSeries(const TokenLabel(LabelToken.score), [
              for (final p in shown) p.score.valueOrNull == null ? null : p.score.valueOrNull! / 100,
            ]),
          ],
          unit: StatUnit.score,
          targetBand: p25 == null || p75 == null ? null : (p25 / 100, p75 / 100),
        ),
        args: {
          'median': med == null ? null : med / 100,
          'deltaVsMedian': todayPoint?.deltaVsMedian.valueOrNull == null
              ? null
              : todayPoint!.deltaVsMedian.valueOrNull! / 100,
          'sections': [
            if ((todayFacts?.plannerPlanned ?? 0) > 0 && weights.planner > 0) 'planner',
            if ((todayFacts?.habitsDue ?? 0) > 0 && weights.habits > 0) 'habits',
            if (todayFacts?.itemsCompleted != null && weights.lists > 0) 'lists',
            if (todayFacts?.quitAbstinent != null && weights.quit > 0) 'quit',
          ],
        },
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Day-of-week effects (T6.7.07)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-08',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.bars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: globalTables,
    compute: (c) {
      final has = {
        _WeekdayMetric.planner: c.hasPlanner,
        _WeekdayMetric.habits: c.hasHabits,
        _WeekdayMetric.items: c.hasLists,
        _WeekdayMetric.cravings: c.hasQuit,
        _WeekdayMetric.deepWork: c.hasPlanner,
      };
      final effects = <(_WeekdayMetric, WeekdayEffect)>[];
      var weeksSeen = 0;
      for (final m in _WeekdayMetric.values) {
        if (!has[m]!) continue;
        switch (dayOfWeekEffect(_dailyOf(c, m))) {
          case Value<WeekdayEffect>(:final value):
            effects.add((m, value));
          case Insufficient<WeekdayEffect>(:final haveN):
            weeksSeen = math.max(weeksSeen, haveN.toInt());
          default:
            break;
        }
      }
      if (effects.isEmpty) return result('GL-08', Insufficient<double>(4, weeksSeen));
      final order = Weekday.ordered(c.weekStart);
      return chartResult(
        'GL-08',
        ChartGroup([
          for (final (m, e) in effects)
            (
              TokenLabel(m.token),
              BarData(
                [for (final d in order) WeekdayLabel(d)],
                [
                  BarSeries(TokenLabel(m.token), [for (final d in order) e.means[d] ?? 0]),
                ],
                unit: m.unit,
                overlays: [
                  BarOverlay(const TokenLabel(LabelToken.mean), [
                    e.means.values.fold<double>(0, (a, b) => a + b) / e.means.length,
                  ]),
                ],
              ),
            ),
        ]),
        value: Value<double>(effects.where((e) => e.$2.significant).length.toDouble()),
        args: {
          'effects': [
            for (final (m, e) in effects)
              {
                'metric': m.name,
                'significant': e.significant,
                'best': e.best.code,
                'worst': e.worst.code,
                'p': e.test.pValue,
                'epsilon2': e.test.epsilonSquared,
                'unit': m.unit.name,
                'bestValue': e.means[e.best],
                'worstValue': e.means[e.worst],
              },
          ],
        },
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Goals & projections (T6.7.09)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-09',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.bullet,
    priority: MetricPriority.p1,
    requires: _goalTables,
    compute: (c) {
      final views = goalViews(c);
      if (views.isEmpty) return const MetricResult.notApplicable('GL-09', 'noGoal');
      final achieved = [
        for (final v in views)
          if (v.goal.achievedAt != null || v.progress.status == GoalStatus.achieved) v,
      ];
      final active = [
        for (final v in views)
          if (!achieved.contains(v)) v,
      ];
      ListRow row(GoalView v) => ListRow(
        v.label,
        value: v.goal.target <= 0 ? null : v.progress.actual / v.goal.target,
        unit: StatUnit.percent,
        secondary: TokenLabel(_statusToken(v.progress.status)),
        tone: _statusTone(v.progress.status),
        ref: v.ref,
      );
      final first = active.firstOrNull;
      final days = first == null
          ? const <LocalDate>[]
          : DateRange(first.progress.goal.start, first.progress.asOf).dates.toList();
      var run = 0.0;
      return chartResult(
        'GL-09',
        ChartGroup([
          if (active.isNotEmpty) (const TokenLabel(LabelToken.active), ListData([for (final v in active) row(v)])),
          if (first != null && days.isNotEmpty && !first.openEnded)
            (
              first.label,
              TimeSeriesData(days, [
                ChartSeries(const TokenLabel(LabelToken.actual), [for (final d in days) run += first.daily[d] ?? 0]),
                ChartSeries(
                  const TokenLabel(LabelToken.pace),
                  [
                    for (final d in days)
                      first.goal.target * (first.progress.goal.start.daysUntil(d) + 1) / first.progress.goal.totalDays,
                  ],
                  color: const SeriesColor(1),
                  role: SeriesRole.pace,
                ),
              ], goal: first.goal.target),
            ),
          if (achieved.isNotEmpty)
            (const TokenLabel(LabelToken.achieved), ListData([for (final v in achieved) row(v)])),
        ]),
        value: Value<double>(active.length.toDouble()),
        args: {
          'goals': [
            for (final v in views)
              {
                'id': v.goal.id,
                'actual': v.progress.actual,
                'target': v.goal.target,
                'pace': v.progress.pace,
                'status': v.progress.status.name,
                'projectedEnd': v.progress.projectedEnd,
                'eta': ?v.progress.eta?.toIso(),
                'openEnded': v.openEnded,
                'achievedAt': ?(v.goal.achievedAt?.toIso8601String() ?? v.progress.achievedOn?.toIso()),
              },
          ],
        },
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Year activity heatmap (T6.7.11)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-11',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.yearGrid,
    priority: MetricPriority.p1,
    requires: globalTables,
    compute: (c) {
      final explicitYear = c.request.extra != null && RegExp(r'^\d{4}$').hasMatch(c.request.extra!);
      final from = explicitYear ? LocalDate(reviewYear(c), 1, 1) : c.today.minusDays(364);
      final to = explicitYear ? LocalDate(reviewYear(c), 12, 31) : c.today;
      final cells = yearActivityHeatmap(c.daysIn(DateRange(from, LocalDate.min(to, c.today))));
      return chartResult(
        'GL-11',
        CalendarData(
          {
            for (final a in cells)
              if (a.total > 0 || a.abstinent != null)
                a.date: CalendarCell(value: a.total.toDouble(), breakdown: _breakdown(a)),
          },
          from: from,
          to: to,
          mode: CalendarMode.intensity,
          today: c.today,
        ),
        value: Value<double>(cells.fold<double>(0, (s, a) => s + a.total)),
        args: {
          'activeDays': cells.where((a) => a.total > 0).length,
          'abstinentDays': cells.where((a) => a.abstinent ?? false).length,
        },
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Correlations explorer (T6.7.13)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-13',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    requires: globalTables,
    compute: (c) {
      final range = DateRange(c.today.minusDays(180), c.today);
      final series = correlationSeries(c, range);
      if (series.length < 2) return result('GL-13', const Insufficient<double>(21, 0), note: 'correlationNotCausation');
      final findings = correlationExplorer(series);
      final significant = [
        for (final f in findings)
          if (f.significant) f,
      ];
      final top = significant.firstOrNull;
      final byId = {for (final s in series) s.id: s};
      return chartResult(
        'GL-13',
        ChartGroup([
          (
            const TokenLabel(LabelToken.rate),
            ListData([
              for (final f in significant.take(20))
                ListRow(
                  correlationLabel(c, f.a),
                  value: f.coefficient,
                  unit: StatUnit.ratio,
                  secondary: correlationLabel(c, f.b),
                  tone: f.coefficient >= 0 ? ChartTone.positive : ChartTone.negative,
                ),
            ]),
          ),
          if (top != null)
            (
              correlationLabel(c, top.a),
              ScatterData(
                [
                  for (final e in byId[top.a]!.values.entries)
                    if (byId[top.b]!.values[e.key.plusDays(top.lag)] case final y?) ScatterPoint(e.value, y),
                ],
                variant: ScatterVariant.planVsActual,
                xUnit: StatUnit.count,
                yUnit: StatUnit.count,
              ),
            ),
        ]),
        value: Value<double>(significant.length.toDouble()),
        note: 'correlationNotCausation',
        args: {
          'tested': findings.length,
          'pairs': [
            for (final f in significant.take(20))
              {
                'a': f.a,
                'b': f.b,
                'lag': f.lag,
                'method': f.method.name,
                'r': f.coefficient,
                'n': f.n,
                'q': f.adjustedP,
                'stars': f.stars,
              },
          ],
        },
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Year in review (T6.7.14)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-14',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.tiles,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    requires: globalTables,
    compute: (c) {
      final year = reviewYear(c);
      final range = DateRange(LocalDate(year, 1, 1), LocalDate.min(LocalDate(year, 12, 31), c.today));
      if (range.end.isBefore(range.start)) return const MetricResult.notApplicable('GL-14', Reasons.noData);
      final days = c.daysIn(range);
      final n = yearInNumbers(days);
      final prevDays = c.daysIn(DateRange(LocalDate(year - 1, 1, 1), LocalDate(year - 1, 12, 31)));
      final hasPrev =
          c.firstDataDate != null && c.firstDataDate!.isBefore(LocalDate(year, 1, 1)) && prevDays.isNotEmpty;
      final p = yearInNumbers(prevDays);
      final currency = c.currency();
      final facts = [
        for (final f in c.historyPlanner.facts)
          if (f.plannedDate != null && range.contains(f.plannedDate!)) f,
      ];
      // Archetype inputs: first task start and last habit check-in per day (local clock minutes).
      final firstStarts = <LocalDate, int>{};
      for (final f in facts) {
        if (f.status != PlannerOccurrenceStatus.done) continue;
        final start = f.effectiveSessions.firstOrNull?.start ?? f.plannedStart;
        if (start == null || f.isAllDay) continue;
        final local = c.bounds.clock.toLocal(start);
        final m = local.time.minuteOfDay;
        if (firstStarts[local.date] == null || m < firstStarts[local.date]!) firstStarts[local.date] = m;
      }
      final lastCheckIns = <LocalDate, int>{};
      for (final l in c.habits.input.logs) {
        if (!range.contains(l.localDate) || l.kind == 'craving') continue;
        final m = c.bounds.clock.toLocal(l.loggedAt).time.minuteOfDay;
        if (lastCheckIns[l.localDate] == null || m > lastCheckIns[l.localDate]!) lastCheckIns[l.localDate] = m;
      }
      final deepWorkHours = _sum(days, (d) => d.deepWorkMinutes) / 60;
      final habitSuccess = habitAdherenceIn(c, range).valueOrNull;
      final types = archetypes(
        medianFirstTaskStartMinute: median([for (final v in firstStarts.values) v]).valueOrNull,
        medianLastCheckInMinute: median([for (final v in lastCheckIns.values) v]).valueOrNull,
        deepWorkHours: deepWorkHours,
        habitSuccess: habitSuccess,
        itemsCompleted: n.itemsCompleted,
      );
      final longest = [
        for (final e in c.habits.evaluations)
          if (e.streaks.streaks.where((s) => range.contains(s.endDate)).map((s) => s.length).maxOrNull case final best?)
            (e.habit, best),
      ]..sort((a, b) => b.$2.compareTo(a.$2));
      final records = [
        for (final r in personalRecords(c))
          if (range.contains(r.entry.date) && r.entry.previous != null && r.entry.value > r.entry.previous!) r,
      ];
      final health = <String>[];
      for (final q in c.habits.quitCalculators) {
        if (q.tracker.substance != smokingSubstance) continue;
        for (final m in smokingHealthMilestones) {
          final at = c.bounds.dateOf(q.currentAbstinenceStart.add(m.tMax ?? m.tMin));
          if (range.contains(at) && !at.isAfter(c.today)) health.add(m.id);
        }
      }
      ValueTile tile(LabelToken t, double v, StatUnit u, {double? prev}) => ValueTile(
        TokenLabel(t),
        v,
        u,
        delta: prev == null ? null : v - prev,
        currency: u == StatUnit.currency ? currency : null,
      );
      final cards = <(ChartLabel, ChartData)>[
        (
          const TokenLabel(LabelToken.yearInNumbers),
          TilesData([
            if (c.hasPlanner) ...[
              tile(LabelToken.tasks, n.tasksDone.toDouble(), StatUnit.count),
              tile(LabelToken.planned, n.plannedHours, StatUnit.hours),
              tile(LabelToken.actual, n.actualHours, StatUnit.hours),
            ],
            if (c.hasHabits) tile(LabelToken.checkIns, n.habitCheckIns.toDouble(), StatUnit.count),
            if (c.hasLists) tile(LabelToken.items, n.itemsCompleted.toDouble(), StatUnit.count),
            if (c.hasQuit) tile(LabelToken.saved, n.moneySaved.toDouble(), StatUnit.currency),
          ]),
        ),
        if (n.busiestMonth != null)
          (
            const TokenLabel(LabelToken.busiest),
            TilesData([
              ValueTile(
                const TokenLabel(LabelToken.month),
                yearActivityHeatmap(days)
                    .where((a) => a.date.month == n.busiestMonth)
                    .fold<double>(0, (s, a) => s + a.total),
                StatUnit.count,
                secondary: DateLabel(LocalDate(year, n.busiestMonth!, 1), Granularity.month),
              ),
              if (n.busiestWeekday case final w?)
                ValueTile(
                  const TokenLabel(LabelToken.weekdayLabel),
                  yearActivityHeatmap(days).where((a) => a.date.weekday == w).fold<double>(0, (s, a) => s + a.total),
                  StatUnit.count,
                  secondary: WeekdayLabel(w),
                ),
            ]),
          ),
        if (c.hasPlanner && facts.isNotEmpty)
          (
            const TokenLabel(LabelToken.topCategories),
            DonutData([
              for (final s in timeByCategory(facts).slices.take(7))
                DonutSlice(c.planner.categoryLabel(s.key), s.minutes / 60, color: c.planner.categoryColor(s.key)),
            ], unit: StatUnit.hours),
          ),
        if (longest.isNotEmpty)
          (
            const TokenLabel(LabelToken.longestStreaks),
            ListData([
              for (final (h, best) in longest.take(5))
                ListRow(
                  TextLabel(h.name),
                  value: best.toDouble(),
                  unit: StatUnit.days,
                  ref: DrillRef(DrillKind.habit, h.id, title: h.name),
                ),
            ]),
          ),
        if (c.hasPlanner)
          (
            const TokenLabel(LabelToken.deepWork),
            TilesData([tile(LabelToken.deepWork, deepWorkHours, StatUnit.hours)]),
          ),
        if (c.hasQuit)
          (
            const TokenLabel(LabelToken.quitJourney),
            TilesData([
              tile(LabelToken.abstinent, n.abstinentDays.toDouble(), StatUnit.days),
              tile(LabelToken.saved, n.moneySaved.toDouble(), StatUnit.currency),
              tile(LabelToken.milestones, health.length.toDouble(), StatUnit.count),
            ]),
          ),
        if (records.isNotEmpty)
          (
            const TokenLabel(LabelToken.recordsBroken),
            ListData([
              for (final r in records)
                ListRow(
                  TokenLabel(r.type.token),
                  value: r.entry.value,
                  unit: r.type.unit,
                  secondary: DateLabel(r.entry.date),
                ),
            ]),
          ),
        if (hasPrev)
          (
            const TokenLabel(LabelToken.yearOverYear),
            TilesData([
              if (c.hasPlanner)
                tile(LabelToken.tasks, n.tasksDone.toDouble(), StatUnit.count, prev: p.tasksDone.toDouble()),
              if (c.hasHabits)
                tile(LabelToken.checkIns, n.habitCheckIns.toDouble(), StatUnit.count, prev: p.habitCheckIns.toDouble()),
              if (c.hasLists)
                tile(LabelToken.items, n.itemsCompleted.toDouble(), StatUnit.count, prev: p.itemsCompleted.toDouble()),
              if (c.hasQuit)
                tile(LabelToken.saved, n.moneySaved.toDouble(), StatUnit.currency, prev: p.moneySaved.toDouble()),
            ]),
          ),
        if (types.isNotEmpty)
          (
            const TokenLabel(LabelToken.archetype),
            ListData([
              for (final a in types)
                ListRow(
                  TokenLabel(switch (a) {
                    Archetype.earlyBird => LabelToken.earlyBird,
                    Archetype.nightOwl => LabelToken.nightOwl,
                    Archetype.marathoner => LabelToken.marathoner,
                    Archetype.consistent => LabelToken.consistent,
                    Archetype.finisher => LabelToken.finisher,
                  }),
                ),
            ]),
          ),
      ];
      return chartResult(
        'GL-14',
        ChartGroup(cards),
        value: Value<double>(yearActivityHeatmap(days).fold<double>(0, (s, a) => s + a.total)),
        currency: currency,
        args: {
          'year': year,
          'tasksDone': n.tasksDone,
          'plannedHours': n.plannedHours,
          'actualHours': n.actualHours,
          'habitCheckIns': n.habitCheckIns,
          'itemsCompleted': n.itemsCompleted,
          'moneySaved': n.moneySaved.toDouble(),
          'abstinentDays': n.abstinentDays,
          'busiestMonth': n.busiestMonth,
          'busiestWeekday': n.busiestWeekday?.code,
          'deepWorkHours': deepWorkHours,
          'archetypes': [for (final a in types) a.name],
          'records': records.length,
          'offered': (c.today.month == 12 && c.today.day >= 15) || c.today.month == 1,
        },
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Gamification (T6.7.15) — opt-in
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-15',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.bullet,
    priority: MetricPriority.p2,
    requires: {...globalTables, StatsTable.userSettings},
    compute: (c) {
      if (!c.settings.gamification) return const MetricResult.notApplicable('GL-15', 'gamificationOff');
      final s = xpSummary(xpEvents(c), bounds: c.bounds);
      final levelStart = s.level == 0 ? 0.0 : 100 * math.pow(s.level, 1.5).toDouble();
      final nextAt = 100 * math.pow(s.level + 1, 1.5).toDouble();
      final days = DateRange(c.today.minusDays(13), c.today).dates.toList();
      return chartResult(
        'GL-15',
        ChartGroup([
          (
            const TokenLabel(LabelToken.level),
            BulletData(
              actual: s.total - levelStart,
              target: nextAt - levelStart,
              max: nextAt - levelStart,
              label: OrdinalLabel(OrdinalKind.level, s.level),
            ),
          ),
          (
            const TokenLabel(LabelToken.xp),
            BarData(
              [for (final d in days) DateLabel(d)],
              [
                BarSeries(const TokenLabel(LabelToken.xp), [for (final d in days) s.perDay[d] ?? 0]),
              ],
              isTimeAxis: true,
            ),
          ),
        ]),
        value: Value<double>(s.total),
        args: {
          'level': s.level,
          'toNextLevel': s.toNextLevel,
          'today': s.perDay[c.today] ?? 0,
          'week': [for (final d in DateRange(c.thisWeekStart, c.today).dates) s.perDay[d] ?? 0]
              .fold<double>(0, (a, b) => a + b),
        },
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Cross-section time budget (T6.7.17)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-17',
    scope: MetricScope.global,
    unit: StatUnit.hours,
    chart: ChartKind.stackedBars,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p2,
    requires: {...globalTables, StatsTable.timeEntries},
    compute: (c) {
      final range = c.elapsed;
      final waking = c.settings.wakingMinutes.toDouble();
      final habitById = c.habits.byId;
      final habitIntervals = <LocalDate, List<(DateTime, DateTime)>>{};
      for (final l in c.habits.input.logs) {
        final h = habitById[l.habitId];
        if (h == null || h.isQuit || !range.contains(l.localDate)) continue;
        final seconds =
            l.durationSeconds ?? (h.goalType == 'duration' && l.value != null ? (l.value! * 60).round() : null);
        if (seconds == null || seconds <= 0) continue;
        habitIntervals.putIfAbsent(l.localDate, () => []).add((
          l.loggedAt.subtract(Duration(seconds: seconds)),
          l.loggedAt,
        ));
      }
      final sessions = <LocalDate, List<(DateTime, DateTime)>>{};
      final planned = <LocalDate, double>{};
      for (final f in c.historyPlanner.plannedIn(range)) {
        if (f.status == PlannerOccurrenceStatus.cancelled) continue;
        planned[f.plannedDate!] = (planned[f.plannedDate!] ?? 0) + (f.isAllDay ? 0 : f.plannedDurationMinutes ?? 0);
      }
      for (final f in c.historyPlanner.facts) {
        for (final s in f.effectiveSessions) {
          final d = c.bounds.dateOf(s.start);
          if (range.contains(d)) sessions.putIfAbsent(d, () => []).add((s.start, s.end));
        }
      }
      final days = range.dates.toList();
      final budgets = [
        for (final d in days)
          timeBudget(
            plannedTaskMinutes: planned[d] ?? 0,
            habitIntervals: habitIntervals[d] ?? const [],
            sessionIntervals: sessions[d] ?? const [],
            wakingMinutes: waking,
          ),
      ];
      final weekly = days.length > 31;
      final buckets = weekly
          ? groupBy(Iterable<int>.generate(days.length), (i) => days[i].startOfWeek(c.weekStart))
          : null;
      List<double> values(double Function(int i) pick) => weekly
          ? [for (final e in buckets!.entries) e.value.fold<double>(0, (a, i) => a + pick(i)) / 60]
          : [for (var i = 0; i < days.length; i++) pick(i) / 60];
      double tasks(int i) => math.max(budgets[i].plannedTasks, budgets[i].trackedFocus);
      double habits(int i) => budgets[i].habitMinutes - budgets[i].overlap;
      final total = budgets.fold<double>(
        0,
        (a, b) => a + math.max(b.plannedTasks, b.trackedFocus) + b.habitMinutes - b.overlap,
      );
      return result(
        'GL-17',
        Value<double>(total / 60),
        unit: StatUnit.hours,
        chart: BarData(
          weekly
              ? [for (final k in buckets!.keys) DateLabel(k, Granularity.week)]
              : [for (final d in days) DateLabel(d)],
          [
            BarSeries(const TokenLabel(LabelToken.tasks), values(tasks)),
            BarSeries(const TokenLabel(LabelToken.habits), values(habits), color: const SeriesColor(1)),
            BarSeries(
              const TokenLabel(LabelToken.free),
              values((i) => budgets[i].free),
              color: const ToneColor(ChartTone.muted),
            ),
          ],
          layout: BarLayout.stacked,
          unit: StatUnit.hours,
          isTimeAxis: true,
        ),
        args: {
          'wakingMinutes': waking,
          'overlapMinutes': budgets.fold<double>(0, (a, b) => a + b.overlap),
          'focusMinutes': budgets.fold<double>(0, (a, b) => a + b.trackedFocus),
          'freeMinutes': budgets.fold<double>(0, (a, b) => a + b.free),
        },
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Monte Carlo goal forecasts (T6.7.18)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-18',
    scope: MetricScope.global,
    unit: StatUnit.days,
    chart: ChartKind.forecast,
    direction: MetricDirection.lowerIsBetter,
    priority: MetricPriority.p2,
    estimate: true,
    requires: _goalTables,
    compute: (c) {
      final candidates = [
        for (final v in goalViews(c))
          if (v.goal.achievedAt == null && v.progress.status != GoalStatus.achieved && v.goal.metric != 'streak_days')
            v,
      ];
      if (candidates.isEmpty) return const MetricResult.notApplicable('GL-18', 'noGoal');
      final charts = <(ChartLabel, ChartData)>[];
      final forecasts = <Map<String, Object?>>[];
      var history = 0;
      for (final v in candidates) {
        // ≥ 30 days of history: days since the goal (or the data) started.
        final since = LocalDate.max(v.progress.goal.start, c.firstDataDate ?? c.today);
        final days = since.daysUntil(c.today) + 1;
        history = math.max(history, days);
        if (days < 30) continue;
        final f = goalForecast(v.progress, dailyValues: v.daily, random: math.Random(stableHash(v.goal.id)));
        if (f case Value(:final value)) {
          charts.add((
            v.label,
            ForecastData(
              c.today,
              value.forecast.histogram,
              p50: value.forecast.p50Days,
              p85: value.forecast.p85Days,
              p95: value.forecast.p95Days,
              trials: value.forecast.trials,
            ),
          ));
          forecasts.add({
            'id': v.goal.id,
            'p50': value.p50.toIso(),
            'p85': value.p85.toIso(),
            'p95': value.p95.toIso(),
            'end': v.progress.goal.end.toIso(),
            'unfinished': value.forecast.unfinishedTrials,
          });
        }
      }
      if (charts.isEmpty) return result('GL-18', Insufficient<double>(30, math.min(history, 29)), estimate: true);
      final first = forecasts.first;
      return chartResult(
        'GL-18',
        ChartGroup(charts),
        value: Value<double>(c.today.daysUntil(LocalDate.parse(first['p85']! as String)).toDouble()),
        estimate: true,
        args: {'forecasts': forecasts},
      );
    },
  ),

  // ---------------------------------------------------------------------------------------------
  // Insights feed candidates (T6.7.08)
  // ---------------------------------------------------------------------------------------------
  metric<GlobalContext>(
    id: 'GL-19',
    scope: MetricScope.global,
    unit: StatUnit.count,
    chart: ChartKind.list,
    direction: MetricDirection.neutral,
    priority: MetricPriority.p1,
    requires: {...globalTables, StatsTable.userSettings, StatsTable.goals},
    compute: (c) {
      final candidates = insightCandidates(c);
      return result('GL-19', Value<double>(candidates.length.toDouble()), args: {'insights': candidates});
    },
  ),
];

/// Per-section breakdown of an activity day (calendar tooltips).
List<(ChartLabel, double)> _breakdown(
  ({LocalDate date, int total, int tasks, int habits, int items, bool? abstinent}) a,
) => [
  if (a.tasks > 0) (const TokenLabel(LabelToken.tasks), a.tasks.toDouble()),
  if (a.habits > 0) (const TokenLabel(LabelToken.habits), a.habits.toDouble()),
  if (a.items > 0) (const TokenLabel(LabelToken.items), a.items.toDouble()),
  if (a.abstinent ?? false) (const TokenLabel(LabelToken.abstinent), 1),
];
