/// Habit stats adapter (T6.5.01, T6.6.01): expands a habit's schedule — revision by revision — into
/// [HabitPeriod]s, evaluates them with the [5.1] period evaluation of `everslot_metrics`, and builds
/// the quit calculator of a tracker. Pure Dart — runs in the stats isolate.
///
/// - Day-level rules (at most one time per day) give one `YYYY-MM-DD` unit per scheduled date.
/// - Intraday rules (several times per day, minutely/hourly windows) give `YYYY-MM-DDTHH:mm` slot
///   units, rolled up to days with the habit's roll-up rule for calendars and streaks.
/// - Quota rules give one `week:…`/`month:…` unit per period (pro-rated at the edges).
/// - Each unit uses the `habit_revisions` row in force on its date (history never shifts).
library;

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/zone_snapshot.dart';
import 'package:everslot_metrics/everslot_metrics.dart' hide PeriodUnit;
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Loop frequency (num/den) of a rule (HB-H-01, PL-S-14): expected units per interval.
StrengthFrequency ruleFrequency(RecurrenceRule? rule) {
  if (rule == null) return const StrengthFrequency.daily();
  switch (rule.type) {
    case RuleType.quota:
      final q = rule.quota;
      if (q == null) return const StrengthFrequency.daily();
      return switch (q.per) {
        PeriodUnit.day => StrengthFrequency(q.times, 1),
        PeriodUnit.week => StrengthFrequency(q.times, 7),
        PeriodUnit.month => StrengthFrequency(q.times, 30),
        PeriodUnit.year => StrengthFrequency(q.times, 365),
      };
    case RuleType.afterCompletion:
      final a = rule.afterCompletion;
      if (a == null) return const StrengthFrequency.daily();
      final amount = math.max(1, a.amount);
      return switch (a.unit) {
        RecurrenceUnit.minute => StrengthFrequency(math.max(1, 1440 ~/ amount), 1),
        RecurrenceUnit.hour => StrengthFrequency(math.max(1, 24 ~/ amount), 1),
        RecurrenceUnit.day => StrengthFrequency(1, amount),
        RecurrenceUnit.week => StrengthFrequency(1, 7 * amount),
        RecurrenceUnit.month => StrengthFrequency(1, 30 * amount),
        RecurrenceUnit.year => StrengthFrequency(1, 365 * amount),
      };
    case RuleType.fixed:
      final interval = math.max(1, rule.interval);
      final perDay = math.max(1, rule.times.length);
      final weekdays = rule.byWeekday?.length;
      switch (rule.freq) {
        case Frequency.minutely || Frequency.hourly:
          final step = interval * (rule.freq == Frequency.hourly ? 60 : 1);
          final w = rule.window;
          final span = w == null ? 1440 : math.max(1, w.end.minuteOfDay - w.start.minuteOfDay + 1);
          final slots = math.max(1, (span / step).ceil());
          return weekdays == null ? StrengthFrequency(slots, 1) : StrengthFrequency(slots * weekdays, 7);
        case Frequency.daily:
          return weekdays == null
              ? StrengthFrequency(perDay, interval)
              : StrengthFrequency(perDay * weekdays, 7 * interval);
        case Frequency.weekly:
          return StrengthFrequency(perDay * (weekdays ?? 1), 7 * interval);
        case Frequency.monthly:
          final n = math.max(1, rule.byMonthDay.length + (weekdays ?? 0));
          return StrengthFrequency(perDay * n, 30 * interval);
        case Frequency.yearly:
          final n = math.max(1, rule.byMonth.length);
          return StrengthFrequency(perDay * n, 365 * interval);
      }
  }
}

/// Whether a rule produces intraday slots (several units per day).
bool isIntradayRule(RecurrenceRule rule) =>
    rule.type == RuleType.fixed && (rule.freq.isSubDaily || rule.times.length > 1);

/// The version (schedule + goal) of a habit in force on a date.
final class HabitVersion {
  const HabitVersion({
    required this.revisionId,
    required this.from,
    required this.rule,
    required this.goal,
    required this.frequency,
  });

  final String? revisionId;
  final LocalDate from;
  final RecurrenceRule? rule;
  final HabitGoal goal;
  final StrengthFrequency frequency;

  bool get isQuota => rule?.type == RuleType.quota;
  bool get isIntraday => rule != null && isIntradayRule(rule!);
}

/// A build habit's evaluated units.
final class HabitEvaluation {
  HabitEvaluation({
    required this.habit,
    required this.versions,
    required this.units,
    required this.dayResults,
    required this.logs,
    required this.settings,
    required this.today,
    this.archivedOn,
  });

  final HabitRecord habit;

  /// Local date the habit was archived (drops out of today/trends after it, stays in history).
  final LocalDate? archivedOn;
  final List<HabitVersion> versions;

  /// Evaluation units: day results, slot results or quota periods (chronological).
  final List<PeriodResult> units;

  /// Day-level results: day units, slot roll-ups (no quota periods).
  final List<PeriodResult> dayResults;
  final List<HabitLog> logs;
  final HabitEvaluationSettings settings;
  final LocalDate today;

  SkipPolicy get skipPolicy => settings.skipPolicy;

  bool get isQuota => versions.any((v) => v.isQuota);

  bool get isIntraday => versions.any((v) => v.isIntraday);

  /// Streak units: quota periods, else day-level results.
  List<PeriodResult> get streakUnits => isQuota ? units : dayResults;

  HabitVersion versionOn(LocalDate date) => effectiveOn(versions, date, (v) => v.from) ?? versions.first;

  HabitGoal get currentGoal => versionOn(today).goal;

  bool get isMeasurable => currentGoal.isMeasurable;

  bool get isLimit => currentGoal.op == TargetOp.lte;

  late final List<HabitDayFact> dayFacts = habitDayFacts(units, skipPolicy: skipPolicy);

  StrengthGoalKind get strengthKind {
    final g = currentGoal;
    if (!g.isMeasurable) return StrengthGoalKind.boolean;
    return g.op == TargetOp.lte ? StrengthGoalKind.atMost : StrengthGoalKind.atLeast;
  }

  /// HB-H-01 — strength (Loop EWMA) with the frequency of each revision.
  late final StrengthResult strength = habitStrength(
    dayFacts,
    today: today,
    frequencyOn: (d) => versionOn(d).frequency,
    kind: strengthKind,
    targetOn: (d) {
      final v = versionOn(d);
      final t = v.goal.target;
      if (t == null || !v.goal.isMeasurable) return null;
      // Numeric targets are per unit; the Loop window sums num units of the frequency.
      return t * v.frequency.numerator;
    },
  );

  /// HB-H-02…04 — streaks with freezes.
  late final StreakSummary streaks = habitStreaks(
    streakUnits,
    skipPolicy: skipPolicy,
    freezesPerMonth: habit.freezesPerMonth,
  );

  /// Section input (HB-X-*).
  late final HabitSeries series = HabitSeries(
    habit.id,
    results: [...dayResults, ...units.where((u) => u.kind == HabitPeriodKind.quota)],
    logs: logs,
    categoryId: habit.categoryId,
    createdOn: habit.startDate,
    archivedOn: archivedOn,
    skipPolicy: skipPolicy,
    strength: strength,
  );
}

/// Expands and evaluates habits for one batch.
final class HabitResolver {
  HabitResolver(
    this.input, {
    required this.resolver,
    required this.viewerZone,
    required this.now,
    this.dayStartMinutes = 0,
    this.weekStart = Weekday.monday,
  }) : engine = RecurrenceEngine(resolver) {
    for (final l in input.logs) {
      _logs.putIfAbsent(l.habitId, () => []).add(l);
    }
    for (final r in input.revisions) {
      _revisions.putIfAbsent(r.habitId, () => []).add(r);
    }
    for (final list in _revisions.values) {
      list.sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    }
  }

  final HabitInput input;
  final ZoneResolver resolver;
  final String viewerZone;
  final DateTime now;
  final int dayStartMinutes;
  final Weekday weekStart;
  final RecurrenceEngine engine;

  final Map<String, List<HabitLogRecord>> _logs = {};
  final Map<String, List<RevisionRecord>> _revisions = {};

  String zoneOf(HabitRecord h) => h.timeZone ?? viewerZone;

  DayBoundaries boundsOf(HabitRecord h) => dayBoundariesOf(resolver, zoneOf(h), dayStartMinutes: dayStartMinutes);

  /// The habit's current local (logical) date.
  LocalDate todayOf(HabitRecord h) => boundsOf(h).dateOf(now);

  List<HabitLogRecord> logRecordsOf(String habitId) => _logs[habitId] ?? const [];

  /// Build-habit logs as evaluation logs.
  List<HabitLog> logsOf(String habitId) => [
    for (final l in logRecordsOf(habitId))
      if (_kind(l.kind) case final kind?)
        HabitLog(
          l.id,
          kind,
          loggedAt: l.loggedAt,
          localDate: l.localDate,
          value: l.value,
          occurrenceKey: l.occurrenceKey,
          createdAt: l.createdAt,
          source: l.source,
          mood: l.mood,
          durationSeconds: l.durationSeconds,
          note: l.note,
        ),
  ];

  static HabitLogKind? _kind(String value) => HabitLogKind.values.firstWhereOrNull((k) => k.name == value);

  static RecurrenceRule? _rule(String? json) {
    if (json == null || json.trim().isEmpty) return null;
    try {
      return RecurrenceRule.decode(json);
    } on Object {
      return null;
    }
  }

  static HabitGoal _goal(String? type, double? target, String? op) => HabitGoal(
    HabitGoalType.values.firstWhereOrNull((t) => t.name == type) ?? HabitGoalType.check,
    target: target,
    op: TargetOp.values.firstWhereOrNull((o) => o.name == op) ?? TargetOp.gte,
  );

  /// Versions of [h]: the habit row before the first revision, then each revision (null fields fall
  /// back to the habit row).
  List<HabitVersion> versionsOf(HabitRecord h) {
    final revisions = _revisions[h.id] ?? const <RevisionRecord>[];
    HabitVersion of(String? id, LocalDate from, String? schedule, String? type, double? target, String? op) {
      final rule = _rule(schedule ?? h.schedule);
      return HabitVersion(
        revisionId: id,
        from: from,
        rule: rule,
        goal: _goal(type ?? h.goalType, target ?? h.targetValue, op ?? h.targetOp),
        frequency: ruleFrequency(rule),
      );
    }

    final versions = <HabitVersion>[];
    if (revisions.isEmpty || revisions.first.effectiveFrom.isAfter(h.startDate)) {
      versions.add(of(null, h.startDate, null, null, null, null));
    }
    for (final r in revisions) {
      versions.add(of(r.id, r.effectiveFrom, r.schedule, r.goalType, r.targetValue, r.targetOp));
    }
    return versions;
  }

  /// Evaluates build habit [h] over `[from, to]` (default: start date … today).
  HabitEvaluation evaluate(HabitRecord h, {LocalDate? from, LocalDate? to}) {
    final today = todayOf(h);
    final bounds = boundsOf(h);
    final versions = versionsOf(h);
    final settings = HabitEvaluationSettings(
      skipPolicy: h.skipPolicy == 'breaks' ? SkipPolicy.breaks : SkipPolicy.neutral,
      requireExplicitLog: h.requireExplicitLog,
      slotRollup: SlotRollup(minSlots: h.slotMinDone),
    );
    final start = LocalDate.max(from ?? h.startDate, h.startDate);
    var end = to ?? today;
    if (h.endDate != null && h.endDate!.isBefore(end)) end = h.endDate!;
    final archived = h.archivedAt == null ? null : bounds.dateOf(h.archivedAt!);
    if (archived != null && archived.isBefore(end)) end = archived;
    final logs = logsOf(h.id);
    final pauses = [
      for (final p in input.pauses)
        if (p.habitId == null || p.habitId == h.id) p,
    ];
    final periods = <HabitPeriod>[];
    if (!end.isBefore(start)) {
      for (var i = 0; i < versions.length; i++) {
        final v = versions[i];
        final segStart = LocalDate.max(start, v.from);
        final next = i + 1 < versions.length ? versions[i + 1].from.minusDays(1) : end;
        final segEnd = LocalDate.min(end, next);
        if (segEnd.isBefore(segStart)) continue;
        periods.addAll(_expand(h, v, segStart, segEnd, bounds));
      }
    }
    final evaluated = evaluateHabitPeriods(periods, logs, now: now, today: today, pauses: pauses, settings: settings);
    final List<PeriodResult> dayResults;
    if (versions.any((v) => v.isIntraday)) {
      final byDate = <LocalDate, List<PeriodResult>>{};
      final days = <PeriodResult>[];
      for (final r in evaluated) {
        if (r.kind == HabitPeriodKind.slot) {
          byDate.putIfAbsent(r.startDate, () => []).add(r);
        } else if (r.kind == HabitPeriodKind.day) {
          days.add(r);
        }
      }
      for (final e in byDate.entries) {
        days.add(
          rollUpSlots(
            e.key,
            e.value,
            windowStart: bounds.startOf(e.key),
            windowEnd: bounds.endOf(e.key),
            settings: settings,
          ),
        );
      }
      days.sort((a, b) => a.startDate.compareTo(b.startDate));
      dayResults = days;
    } else {
      dayResults = [
        for (final r in evaluated)
          if (r.kind == HabitPeriodKind.day) r,
      ];
    }
    return HabitEvaluation(
      habit: h,
      versions: versions,
      units: evaluated,
      dayResults: dayResults,
      logs: logs,
      settings: settings,
      today: today,
      archivedOn: archived,
    );
  }

  List<HabitPeriod> _expand(HabitRecord h, HabitVersion v, LocalDate from, LocalDate to, DayBoundaries bounds) {
    final zone = zoneOf(h);
    final rule = v.rule;
    if (rule == null || rule.type == RuleType.afterCompletion) {
      return [for (var d = from; !d.isAfter(to); d = d.plusDays(1)) _dayPeriod(d, v, bounds)];
    }
    if (rule.type == RuleType.quota) {
      final anchor = RecurrenceAnchor(h.startDate.atStartOfDay, zone, allDay: true);
      final eligibleWeekdays = rule.byWeekday == null ? null : {for (final w in rule.byWeekday!) w.day};
      return [
        for (final p in engine.periods(rule, anchor, from, to, weekStart: weekStart))
          () {
            final s = LocalDate.max(p.activeStart, from);
            final e = LocalDate.min(p.activeEnd, to);
            final eligible = [
              for (var d = s; !d.isAfter(e); d = d.plusDays(1))
                if (eligibleWeekdays == null || eligibleWeekdays.contains(d.weekday)) d,
            ];
            return HabitPeriod(
              p.key,
              kind: HabitPeriodKind.quota,
              startDate: s,
              endDate: e,
              windowStart: bounds.startOf(s),
              windowEnd: bounds.endOf(e),
              goal: v.goal,
              revisionId: v.revisionId,
              quotaTimes: p.timesPerPeriod,
              eligibleDays: eligible,
              fullEligibleDays: p.periodDays,
            );
          }(),
      ];
    }
    if (isIntradayRule(rule)) {
      final anchor = RecurrenceAnchor(h.startDate.atStartOfDay, zone);
      final occurrences = engine
          .between(
            rule,
            anchor,
            from.atStartOfDay,
            to.plusDays(1).atStartOfDay,
            evalZone: zone,
            durationMinutes: 0,
            limit: 50000,
          )
          .toList();
      final result = <HabitPeriod>[];
      for (var i = 0; i < occurrences.length; i++) {
        final o = occurrences[i];
        final date = bounds.dateOf(o.startUtc);
        final next = i + 1 < occurrences.length ? occurrences[i + 1] : null;
        final dayEnd = bounds.endOf(date);
        final windowEnd = next != null && bounds.dateOf(next.startUtc) == date && next.startUtc.isBefore(dayEnd)
            ? next.startUtc
            : dayEnd;
        result.add(
          HabitPeriod(
            o.key,
            kind: HabitPeriodKind.slot,
            startDate: date,
            endDate: date,
            windowStart: o.startUtc,
            windowEnd: windowEnd,
            goal: v.goal,
            revisionId: v.revisionId,
            matchStart: o.startUtc.subtract(Duration(minutes: h.earlyToleranceMinutes)),
          ),
        );
      }
      return result;
    }
    final anchor = RecurrenceAnchor(h.startDate.atStartOfDay, zone, allDay: true);
    final dates = <LocalDate>{
      for (final o in engine.between(
        rule,
        anchor,
        from.atStartOfDay,
        to.plusDays(1).atStartOfDay,
        evalZone: zone,
        limit: 50000,
      ))
        o.startLocal.date,
    };
    return [
      for (final d in dates.toList()..sort())
        if (!d.isBefore(from) && !d.isAfter(to)) _dayPeriod(d, v, bounds),
    ];
  }

  HabitPeriod _dayPeriod(LocalDate d, HabitVersion v, DayBoundaries bounds) => HabitPeriod(
    d.toIso(),
    kind: HabitPeriodKind.day,
    startDate: d,
    endDate: d,
    windowStart: bounds.startOf(d),
    windowEnd: bounds.endOf(d),
    goal: v.goal,
    revisionId: v.revisionId,
  );

  // ------------------------------------------------------------------------------------------
  // Quit trackers (T6.6.01)

  /// Quit logs of a tracker.
  List<QuitLog> quitLogsOf(String habitId) => [
    for (final l in logRecordsOf(habitId))
      if (_kind(l.kind) case final kind?)
        QuitLog(
          l.id,
          kind,
          loggedAt: l.loggedAt,
          localDate: l.localDate,
          value: l.value,
          intensity: l.intensity,
          trigger: l.trigger,
          place: l.place,
          coping: l.coping,
          mood: l.mood,
          resisted: l.resisted,
          durationSeconds: l.durationSeconds,
          note: l.note,
        ),
  ];

  static Decimal? _money(double? v) => v == null ? null : Decimal.parse(v.toString());

  /// The quit calculator of tracker [h] at now (null without a quit date).
  QuitCalculator? quit(HabitRecord h) {
    final qd = h.quitStartedAt;
    if (qd == null) return null;
    final revisions = [
      for (final r in _revisions[h.id] ?? const <RevisionRecord>[])
        QuitRevision(
          r.effectiveFrom,
          baselinePerDay: r.baselinePerDay,
          unitCost: _money(r.unitCost),
          dailyLimit: r.dailyLimit,
        ),
    ];
    return QuitCalculator(
      QuitTracker(
        qd,
        mode: h.quitMode == 'reduce' ? QuitMode.reduce : QuitMode.abstain,
        days: boundsOf(h),
        autoSuccess: h.autoSuccess,
        baselinePerDay: h.baselinePerDay ?? 0,
        unitCost: _money(h.unitCost),
        dailyLimit: h.dailyLimit,
        revisions: revisions,
        timePerUnitMinutes: h.timePerUnitMinutes,
        lifeMinutesPerUnit: h.lifeMinutesPerUnit,
        substance: h.quitSubstance,
        currency: h.currency,
      ),
      quitLogsOf(h.id),
      now: now,
    );
  }
}
