import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/features/goals/application/goal_providers.dart';
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_labels.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/milestone_content.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/quit.dart' show MilestoneContent, usualCravingHours;
import 'package:everslot/features/notifications/application/notification_providers.dart' show notificationTextsProvider;
import 'package:everslot/features/notifications/application/notification_texts_l10n.dart' show L10nNotificationTexts;
import 'package:everslot/features/notifications/notification_contributions.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitPeriodKind, PeriodResult, PeriodStatus, QuitMode;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

// Everything here runs in the main isolate AND in the background isolate that handles
// notification actions while the app is killed (README §2): only database-backed providers are
// read, lazily, and nothing depends on widgets.

L10nNotificationTexts? _texts(T Function<T>(ProviderListenable<T>) read) {
  try {
    return read(notificationTextsProvider);
  } on Object {
    return null;
  }
}

/// Statuses a reminder is still useful for.
bool _open(PeriodStatus s) => s == PeriodStatus.pending || s == PeriodStatus.partial;

/// The status of period [key] of a build-habit [snapshot] (future periods: pending unless a
/// planned skip/excuse or a pause says otherwise; null = not a period of the habit).
PeriodStatus? habitPeriodStatus(HabitSnapshot snapshot, HabitPeriodService service, String key) {
  final habit = snapshot.build;
  final evaluation = snapshot.evaluation;
  if (habit == null || evaluation == null) return null;
  final date = LocalDate.tryParse(key.substring(0, key.length < 10 ? key.length : 10));
  if (date == null) return null;
  if (date.isAfter(snapshot.today)) {
    if (snapshot.pauseOn(date) != null) return PeriodStatus.paused;
    return switch (snapshot.stateOf(key)?.kind) {
      HabitLogKind.skip => PeriodStatus.skipped,
      HabitLogKind.excuse => PeriodStatus.excused,
      _ => PeriodStatus.pending,
    };
  }
  if (key.length > 10) {
    for (final r in evaluation.slotsOn(date)) {
      if (r.key == key) return r.status;
    }
    return null;
  }
  final shape = ScheduleShape.of(service.rulesOn(habit, snapshot.revisions, date).schedule);
  final day = evaluation.dayOn(date);
  if (shape == ScheduleShape.quota) {
    final quota = evaluation.quotaOn(date);
    if (quota != null && !_open(quota.status)) return quota.status;
  }
  return day?.status;
}

/// Notification targets of one build habit for the local dates [from]…[to] (T7.2.06 contract):
/// one target per due day (untimed: the rules' date-only time applies), per intraday slot
/// (`slot` anchor = the slot's time), or per eligible day of a quota period (with its progress).
/// Done, skipped, excused, paused or missed periods are returned closed so replans cancel them.
List<NotificationTarget> buildHabitTargets(
  HabitSnapshot snapshot,
  HabitPeriodService service, {
  required LocalDate from,
  required LocalDate to,
  L10nNotificationTexts? texts,
}) {
  final habit = snapshot.build;
  final evaluation = snapshot.evaluation;
  if (habit == null || evaluation == null || habit.isArchived) return const [];
  final zone = service.zoneOf(habit);
  final b = snapshot.boundaries;
  final measurable = habit.goal.isMeasurable;
  final l10n = texts?.l10n;
  final streak = snapshot.summary?.currentStreak ?? 0;
  final best = snapshot.summary?.bestStreak ?? 0;
  String num(double v) => texts?.number(v) ?? (v == v.roundToDouble() ? '${v.round()}' : '$v');
  String unit(double v) => l10n?.unitLabel(habit.goal.unit, v) ?? (habit.goal.unit ?? '');

  NotificationTarget target({
    required String key,
    required DateTime periodStart,
    required DateTime periodEnd,
    required PeriodStatus status,
    DateTime? slot,
    QuotaProgress? quota,
    PeriodResult? result,
    bool withTarget = true,
  }) {
    final goalTarget = result?.target ?? habit.goal.effectiveTarget;
    final achieved = result?.achieved ?? 0;
    return NotificationTarget(
      type: NotificationTargetType.habit,
      id: habit.id,
      section: NotificationSection.habits,
      title: habit.name,
      occurrenceKey: key,
      categoryId: habit.categoryId,
      notifyMode: NotifyMode.parse(habit.notifyMode),
      itemKind: slot == null ? ItemKind.allDay : ItemKind.timed,
      timeZone: habit.timeZone,
      slot: slot,
      periodStart: periodStart,
      periodEnd: periodEnd,
      status: status.name,
      isOpen: _open(status) && (quota == null || quota.remaining > 0),
      guard: NotificationGuard.habitPeriodOpen(
        habit.id,
        key,
        goalType: habit.goal.type.name,
        target: withTarget && measurable ? goalTarget : null,
        op: withTarget && measurable ? habit.goal.op.name : null,
      ),
      streak: streak,
      quota: quota,
      variables: {
        if (measurable) ...{
          'target': num(goalTarget),
          'unit': unit(goalTarget),
          'logged_today': num(achieved),
          'progress': '${num(achieved)}/${num(goalTarget)}',
        },
        'best_streak': '$best',
      },
      deepLink: AppLinks.habit(habit.id),
      defaultActions: measurable
          ? const [NotificationActionIds.logValue, NotificationActionIds.done, NotificationActionIds.skip]
          : const [NotificationActionIds.done, NotificationActionIds.skip],
    );
  }

  final out = <NotificationTarget>[];
  final quotaDays = <String>{};
  for (final p in service.periods(habit, snapshot.revisions, from, to)) {
    switch (p.kind) {
      case HabitPeriodKind.day:
        if (!p.due) continue;
        final status = habitPeriodStatus(snapshot, service, p.key) ?? PeriodStatus.pending;
        out.add(
          target(
            key: p.key,
            periodStart: p.windowStart,
            periodEnd: p.windowEnd,
            status: status,
            result: p.startDate.isAfter(snapshot.today) ? null : evaluation.dayOn(p.startDate),
          ),
        );
      case HabitPeriodKind.slot:
        final status = habitPeriodStatus(snapshot, service, p.key) ?? PeriodStatus.pending;
        final local = LocalDateTime.tryParse(p.key);
        final slotAt = local == null ? p.windowStart : service.resolver.resolve(local, zone).utc;
        PeriodResult? result;
        for (final r in evaluation.slotsOn(p.startDate)) {
          if (r.key == p.key) result = r;
        }
        out.add(
          target(
            key: p.key,
            periodStart: b.startOf(p.startDate),
            periodEnd: b.endOf(p.startDate),
            status: status,
            slot: slotAt,
            result: result,
          ),
        );
      case HabitPeriodKind.quota:
        final eligible = p.eligibleDays ?? p.dates;
        final quotaResult = evaluation.quotaOn(p.startDate);
        final times = p.quotaTimes ?? quotaResult?.flags.requiredDays ?? 1;
        for (final date in eligible) {
          if (date.isBefore(from) || date.isAfter(to) || !quotaDays.add(date.toIso())) continue;
          final done = quotaResult?.flags.activeDays ?? 0;
          final left = eligible.where((d) => !d.isBefore(date)).length;
          out.add(
            target(
              key: date.toIso(),
              periodStart: b.startOf(date),
              periodEnd: b.endOf(date),
              status: habitPeriodStatus(snapshot, service, date.toIso()) ?? PeriodStatus.pending,
              quota: QuotaProgress(done: done, target: times, eligibleDaysLeft: left),
              result: date.isAfter(snapshot.today) ? null : evaluation.dayOn(date),
              withTarget: false,
            ),
          );
        }
    }
  }
  return out;
}

/// Streak lengths announced by `milestone {metric: streak}` (T7.5.12).
const habitStreakMilestones = [7, 30, 100, 365];

/// Running totals announced by `milestone {metric: total_value}` for measurable habits.
const habitTotalMilestones = [100, 500, 1000, 5000, 10000, 50000, 100000];

/// The habit-level target of a build habit (T7.5.12): no period, always open while the habit is
/// live; carries the last log (`inactivity`) and the milestones just reached — the current streak
/// hitting 7/30/100/365 (keyed by the streak's start, so a later streak announces again) and
/// running totals crossing 100, 500, 1 000… Milestones are dated at the triggering log, so the
/// planner delivers them right away (catch-up) and never twice.
NotificationTarget? buildHabitSummaryTarget(
  HabitSnapshot snapshot, {
  required DateTime now,
  L10nNotificationTexts? texts,
}) {
  final habit = snapshot.build;
  if (habit == null || habit.isArchived) return null;
  final logs = [...snapshot.logs]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  final lastActivity = logs.isEmpty ? null : logs.last.loggedAt;
  final milestones = <NotificationMilestone>[];
  final recent = now.subtract(const Duration(days: 2));
  final current = snapshot.summary?.streaks.current;
  if (current != null && habitStreakMilestones.contains(current.length)) {
    DateTime? at;
    for (final l in logs) {
      if (snapshot.boundaries.dateOf(l.loggedAt) == current.endDate) at = l.loggedAt;
    }
    at ??= lastActivity;
    if (at != null && !at.isBefore(recent)) {
      milestones.add(
        NotificationMilestone(
          metric: 'streak',
          threshold: current.length,
          at: at,
          runKey: current.startDate.toIso(),
          label: texts?.l10n.habitNotifStreakMilestone(current.length) ?? '${current.length}-day streak!',
        ),
      );
    }
  }
  if (habit.goal.isMeasurable) {
    var total = 0.0;
    for (final l in logs) {
      if (l.kind != HabitLogKind.progress || l.value == null) continue;
      final before = total;
      total += l.value!;
      for (final t in habitTotalMilestones) {
        if (before < t && total >= t && !l.loggedAt.isBefore(recent)) {
          final amount = texts?.number(t) ?? '$t';
          final unit = texts?.l10n.unitLabel(habit.goal.unit, t.toDouble()) ?? (habit.goal.unit ?? '');
          milestones.add(
            NotificationMilestone(
              metric: 'total_value',
              threshold: t,
              at: l.loggedAt,
              label: texts?.l10n.habitNotifTotalMilestone(amount, unit) ?? '$amount $unit in total',
            ),
          );
        }
      }
    }
  }
  return NotificationTarget(
    type: NotificationTargetType.habit,
    id: habit.id,
    section: NotificationSection.habits,
    title: habit.name,
    categoryId: habit.categoryId,
    notifyMode: NotifyMode.parse(habit.notifyMode),
    itemKind: ItemKind.any,
    timeZone: habit.timeZone,
    lastActivityAt: lastActivity ?? habit.createdAt,
    milestones: milestones,
    streak: snapshot.summary?.currentStreak,
    deepLink: AppLinks.habit(habit.id),
    defaultActions: const [NotificationActionIds.open],
  );
}

/// Savings thresholds projected as `money_saved` milestones (in the tracker's currency).
const quitMoneyThresholds = <int>[10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000];

/// Avoided-unit thresholds projected as `units_avoided` milestones (abstain trackers).
const quitUnitThresholds = <int>[100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000];

/// Projections further out than this are left for a later replan.
const _quitProjectionLimit = Duration(days: 400);

/// The notification target of one quit tracker (T7.2.06 contract, T7.5.13): the item itself (no
/// occurrence), with `milestoneBaseline` = the current abstinence start (the planner projects the
/// `clean_days` milestones) and milestones projected to exact instants at today's economics —
/// health milestones from the bundled content ([health], smoking only, keyed by the abstinence
/// start so a relapse re-projects them), `money_saved` / `units_avoided` thresholds and the
/// tracker's open all-time goals (`custom`, keyed by goal id). The guard makes milestones obsolete
/// after a relapse; today's window lets daily rules (pledge, evening review) anchor on
/// `period_start` / `period_end`.
NotificationTarget? buildQuitTarget(
  HabitSnapshot snapshot, {
  required DateTime now,
  L10nNotificationTexts? texts,
  MilestoneContent? health,
  List<Goal> goals = const [],
}) {
  final habit = snapshot.quitHabit;
  final calc = snapshot.quit;
  if (habit == null || calc == null || habit.isArchived) return null;
  final baseline = calc.currentAbstinenceStart;
  final runKey = baseline.toUtc().toIso8601String();
  final currency = habit.currency;
  final saved = calc.moneySaved;
  final avoided = calc.unitsAvoided;
  final milestones = <NotificationMilestone>[];
  final econ = calc.tracker.economicsOn(snapshot.today);
  final cost = econ.unitCost;
  final abstain = habit.mode == QuitMode.abstain;
  // Rates per minute at today's economics (abstain trackers only: reduce mode depends on usage).
  final unitsPerMinute = abstain && econ.baselinePerDay > 0 ? econ.baselinePerDay / 1440 : null;
  final moneyPerMinute = unitsPerMinute != null && cost != null && currency != null
      ? unitsPerMinute * cost.toDouble()
      : null;
  DateTime? projected(double missing, double? perMinute) {
    if (missing <= 0 || perMinute == null) return null;
    final at = now.add(Duration(minutes: (missing / perMinute).ceil()));
    return at.difference(now) > _quitProjectionLimit ? null : at;
  }

  String money(num amount) => texts?.format.currency(amount, currency!) ?? '$amount $currency';
  String units(num amount) {
    final n = texts?.number(amount) ?? '$amount';
    final unit = texts?.l10n.unitLabel(habit.unit, amount) ?? (habit.unit ?? '');
    return texts?.l10n.quitNotifUnitsMilestone(n, unit) ?? '$n $unit avoided';
  }

  if (health != null && abstain && (habit.substance?.hasHealthContent ?? false)) {
    final language = texts?.l10n.localeName ?? 'en';
    for (final m in health.milestones) {
      if (m.info) continue;
      final at = baseline.add(m.tMin);
      if (!at.isAfter(now) || at.difference(now) > _quitProjectionLimit) continue;
      milestones.add(
        NotificationMilestone(
          metric: 'health',
          threshold: m.tMin.inMinutes,
          at: at,
          runKey: runKey,
          label: m.textFor(language).title,
        ),
      );
    }
  }
  if (moneyPerMinute != null) {
    for (final t in quitMoneyThresholds) {
      final at = projected(t - saved.toDouble(), moneyPerMinute);
      if (at == null) continue;
      milestones.add(
        NotificationMilestone(
          metric: 'money_saved',
          threshold: t,
          at: at,
          label: texts?.l10n.quitNotifMoneyMilestone(money(t)),
        ),
      );
    }
  }
  if (unitsPerMinute != null) {
    for (final t in quitUnitThresholds) {
      final at = projected(t - avoided, unitsPerMinute);
      if (at == null) continue;
      milestones.add(NotificationMilestone(metric: 'units_avoided', threshold: t, at: at, label: units(t)));
    }
  }
  for (final g in goals) {
    if (g.isAchieved || g.scopeType != GoalScopeType.habit || g.scopeId != habit.id) continue;
    if (g.period != GoalPeriod.allTime) continue;
    final at = switch (g.metric) {
      GoalMetric.moneySaved => projected(g.target - saved.toDouble(), moneyPerMinute),
      GoalMetric.unitsAvoided => projected(g.target - avoided, unitsPerMinute),
      // Clean days count closed days: the target is reached when the remaining days have closed.
      GoalMetric.cleanDays when abstain && g.target > calc.cleanDays => snapshot.boundaries.endOf(
        snapshot.today.plusDays(g.target.ceil() - calc.cleanDays - 1),
      ),
      _ => null,
    };
    if (at == null || at.difference(now) > _quitProjectionLimit) continue;
    final what = switch (g.metric) {
      GoalMetric.moneySaved when currency != null =>
        texts?.l10n.quitNotifMoneyMilestone(money(g.target)) ?? '${money(g.target)} saved',
      GoalMetric.unitsAvoided => units(g.target),
      _ => texts?.l10n.notifBodyCleanDays(g.target.round()) ?? '${g.target.round()} days',
    };
    final title = g.reward ?? g.title;
    milestones.add(
      NotificationMilestone(
        metric: 'custom',
        threshold: g.target,
        at: at,
        runKey: g.id,
        label: title == null ? what : (texts?.l10n.quitNotifGoalMilestone(title, what) ?? '$title — $what'),
      ),
    );
  }
  final upcoming = [...milestones]..sort((a, b) => a.at.compareTo(b.at));
  // Ritual inputs (T7.5.14): today's / yesterday's pledge, review and relapse logs, the usual
  // craving hours and a rotating coping tip.
  final recent = snapshot.boundaries.startOf(snapshot.today.plusDays(-1));
  final events = <NotificationEvent>[];
  final cravingHours = <int>[];
  for (final l in snapshot.logs) {
    if (l.kind == HabitLogKind.craving) cravingHours.add(snapshot.boundaries.clock.toLocal(l.loggedAt).time.hour);
    if (l.loggedAt.isBefore(recent)) continue;
    switch (l.kind) {
      case HabitLogKind.pledge:
        events.add(NotificationEvent(kind: 'pledge', at: l.loggedAt));
      case HabitLogKind.clean:
        events.add(NotificationEvent(kind: 'review', at: l.loggedAt));
      case HabitLogKind.relapse:
        events
          ..add(NotificationEvent(kind: 'review', at: l.loggedAt))
          ..add(NotificationEvent(kind: 'relapse', at: l.loggedAt));
      default:
        break;
    }
  }
  final usualHours = usualCravingHours(cravingHours);
  final tips = texts == null
      ? const ['Try a minute of box breathing.', 'Drink a glass of water.', 'Take a short walk.']
      : [texts.l10n.notifCopingTipBreathe, texts.l10n.notifCopingTipWater, texts.l10n.notifCopingTipWalk];
  final pledge = habit.settings.pledge;
  return NotificationTarget(
    type: NotificationTargetType.habit,
    id: habit.id,
    section: NotificationSection.quit,
    title: habit.name,
    categoryId: habit.categoryId,
    notifyMode: NotifyMode.parse(habit.notifyMode),
    itemKind: ItemKind.any,
    timeZone: habit.timeZone,
    periodStart: snapshot.boundaries.startOf(snapshot.today),
    periodEnd: snapshot.boundaries.endOf(snapshot.today),
    status: 'clean',
    statusChangedAt: baseline,
    guard: NotificationGuard.quitNoRelapseSince(habit.id, baseline),
    milestoneBaseline: baseline,
    milestones: milestones,
    events: events,
    streak: now.difference(baseline).inDays,
    variables: {
      'pledge_time': ?pledge.morning?.toIso(),
      'review_time': ?pledge.evening?.toIso(),
      'craving_count': '${cravingHours.length}',
      if (usualHours.isNotEmpty) 'craving_hours': usualHours.join(','),
      'coping_tip': tips[snapshot.today.dayOfYear % tips.length],
      if (habit.motivation?.trim() case final reason? when reason.isNotEmpty) 'reason': reason,
      'clean_days': '${calc.cleanDays}',
      'days_free': texts?.number(now.difference(baseline).inDays) ?? '${now.difference(baseline).inDays}',
      if (unitsPerMinute != null || avoided > 0)
        'units_avoided': texts?.number(avoided.floor()) ?? '${avoided.floor()}',
      if (currency != null && cost != null)
        'money_saved': texts?.format.currency(saved.toDouble(), currency) ?? '${saved.toStringAsFixed(2)} $currency',
      if (upcoming.firstOrNull?.label case final next?) 'next_milestone': next,
    },
    deepLink: AppLinks.quit(habit.id),
    defaultActions: habit.mode == QuitMode.reduce
        ? const [NotificationActionIds.logValue, NotificationActionIds.logCraving]
        : const [NotificationActionIds.logCraving, NotificationActionIds.open],
  );
}

/// Makes build habits notifiable (section `habits`): reminders at slots / on due days, streak at
/// risk, quota behind, not done by… (README §2).
class HabitsNotificationSource implements NotificationTargetSource, TargetActivitySource {
  HabitsNotificationSource(this._ref);

  final Ref _ref;

  @override
  String get section => NotificationSection.habits.wire;

  /// Writes to `habits`, `habit_logs`, `habit_pauses` and `habit_revisions` already trigger replans.
  @override
  Stream<void> get changes => const Stream<void>.empty();

  /// Check-ins (done / progress logs) per habit (reminder effectiveness, T7.5.17).
  @override
  Future<Map<String, List<DateTime>>> activityBetween(DateTime fromUtc, DateTime toUtc) async {
    final from = LocalDate.fromDateTime(fromUtc.subtract(const Duration(days: 1)));
    final to = LocalDate.fromDateTime(toUtc.add(const Duration(days: 1)));
    final logs = await _ref.read(habitLogsRepositoryProvider).watchInRange(from, to).first;
    final out = <String, List<DateTime>>{};
    for (final l in logs) {
      if (l.kind != HabitLogKind.done && l.kind != HabitLogKind.progress) continue;
      if (l.loggedAt.isBefore(fromUtc) || l.loggedAt.isAfter(toUtc)) continue;
      (out['habit:${l.habitId}'] ??= []).add(l.loggedAt);
    }
    return out;
  }

  @override
  Future<List<NotificationTarget>> targetsBetween(DateTime fromUtc, DateTime toUtc) async {
    final habits = await _ref.read(habitsRepositoryProvider).all(includeArchived: false, kind: HabitKind.build);
    if (habits.isEmpty) return const [];
    final service = _ref.read(habitPeriodServiceProvider);
    final now = _ref.read(clockProvider).nowUtc();
    final texts = _texts(_ref.read);
    final out = <NotificationTarget>[];
    for (final habit in habits) {
      final snapshot = await loadHabitSnapshot(_ref.read, habit, now);
      final b = snapshot.boundaries;
      out.addAll(buildHabitTargets(snapshot, service, from: b.dateOf(fromUtc), to: b.dateOf(toUtc), texts: texts));
      final summary = buildHabitSummaryTarget(snapshot, now: now, texts: texts);
      if (summary != null) out.add(summary);
    }
    return out;
  }

  /// Open while the habit is live and the period still pending / partial (not done, skipped,
  /// excused, paused or closed).
  @override
  Future<bool> guardOpen(NotificationTarget t) async {
    final habit = await _ref.read(habitsRepositoryProvider).byId(t.id);
    if (habit is! BuildHabit || habit.isArchived) return false;
    final key = t.occurrenceKey;
    if (key == null) return true;
    final snapshot = await loadHabitSnapshot(_ref.read, habit, _ref.read(clockProvider).nowUtc());
    final status = habitPeriodStatus(snapshot, _ref.read(habitPeriodServiceProvider), key);
    return status != null && _open(status);
  }
}

/// Makes quit trackers notifiable (section `quit`): clean-time and savings milestones, daily
/// pledge / review rules.
class QuitNotificationSource implements NotificationTargetSource {
  QuitNotificationSource(this._ref);

  final Ref _ref;

  @override
  String get section => NotificationSection.quit.wire;

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<List<NotificationTarget>> targetsBetween(DateTime fromUtc, DateTime toUtc) async {
    final trackers = await _ref.read(habitsRepositoryProvider).all(includeArchived: false, kind: HabitKind.quit);
    if (trackers.isEmpty) return const [];
    final now = _ref.read(clockProvider).nowUtc();
    final texts = _texts(_ref.read);
    final health = trackers.any((t) => t is QuitHabit && (t.substance?.hasHealthContent ?? false))
        ? await _healthContent()
        : null;
    final goals = await _ref.read(goalsRepositoryProvider).all();
    return [
      for (final tracker in trackers)
        if (buildQuitTarget(
              await loadHabitSnapshot(_ref.read, tracker, now),
              now: now,
              texts: texts,
              health: health,
              goals: goals,
            )
            case final t?)
          t,
    ];
  }

  /// The bundled health content; null when the asset can't be loaded (milestones fall back to
  /// clean time, money and units).
  Future<MilestoneContent?> _healthContent() async {
    try {
      return await _ref.read(smokingMilestoneContentProvider.future);
    } on Object {
      return null;
    }
  }

  /// Obsolete once the tracker is gone/archived or a relapse moved the abstinence start.
  @override
  Future<bool> guardOpen(NotificationTarget t) async {
    final habit = await _ref.read(habitsRepositoryProvider).byId(t.id);
    if (habit is! QuitHabit || habit.isArchived) return false;
    final baseline = t.milestoneBaseline;
    if (baseline == null) return true;
    final snapshot = await loadHabitSnapshot(_ref.read, habit, _ref.read(clockProvider).nowUtc());
    return snapshot.quit?.currentAbstinenceStart == baseline;
  }
}

/// Habit & quit actions from notifications, banners and inbox rows (README §3), through the same
/// services as the UI with `source = notification`:
/// - build habit: *Done* (check in; measurable goals log the remaining amount), *Skip*, *Log
///   value* (typed number; empty = one increment, the "+1");
/// - quit tracker: *Log craving* (typed intensity 1–10, default 5), *Log value* (reduce mode: a
///   use, empty = +1), *Done* = "I resisted" (marks the latest unanswered craving of the last two
///   hours as resisted).
/// States are set, never toggled, so repeats from two devices converge.
class HabitNotificationActions implements NotificationActionHandler {
  HabitNotificationActions(Ref _);

  @override
  Set<NotificationTargetType> get targetTypes => const {NotificationTargetType.habit};

  @override
  Set<String> get actionIds => const {
    NotificationActionIds.done,
    NotificationActionIds.skip,
    NotificationActionIds.logValue,
    NotificationActionIds.logCraving,
    NotificationActionIds.pledge,
    NotificationActionIds.cleanDay,
    NotificationActionIds.logRelapse,
  };

  @override
  Future<NotificationActionResult> handle(NotificationActionContext c) async {
    final id = c.targetId;
    final texts = _texts(c.read);
    if (id == null) return const NotificationActionResult.failed(null);
    final habit = await c.read(habitsRepositoryProvider).byId(id);
    if (habit == null || habit.isArchived) return NotificationActionResult.failed(texts?.l10n.habitsNotifGone);
    return switch (habit) {
      final BuildHabit b => _build(c, b, texts),
      final QuitHabit q => _quit(c, q, texts),
    };
  }

  Future<NotificationActionResult> _build(
    NotificationActionContext c,
    BuildHabit habit,
    L10nNotificationTexts? texts,
  ) async {
    final checkIn = c.read(checkInServiceProvider);
    final key = c.occurrenceKey;
    try {
      switch (c.actionId) {
        case NotificationActionIds.done:
          if (key == null) {
            await checkIn.checkNow(habit, source: LogSource.notification);
          } else {
            await checkIn.markDone(habit, key, source: LogSource.notification);
          }
        case NotificationActionIds.skip:
          if (key == null) return NotificationActionResult(openLink: AppLinks.habit(habit.id), markActed: false);
          await checkIn.skip(habit, key, source: LogSource.notification);
        case NotificationActionIds.logValue:
          final input = c.input?.trim() ?? '';
          final value = input.isEmpty ? habit.settings.incrementStep : parseLocalizedDecimal(input);
          if (value == null || value <= 0) {
            return NotificationActionResult.failed(texts?.l10n.habitsNotifInvalidValue(input));
          }
          final target = key ?? (await checkIn.currentTarget(habit))?.key;
          if (target == null) return NotificationActionResult.failed(texts?.l10n.habitsErrorFuture);
          if (habit.goal.isMeasurable) {
            await checkIn.addProgress(habit, target, value, source: LogSource.notification);
          } else {
            await checkIn.markDone(habit, target, source: LogSource.notification);
          }
        default:
          return NotificationActionResult(openLink: c.payload.deepLink ?? AppLinks.habit(habit.id), markActed: false);
      }
    } on CheckInException catch (e) {
      return NotificationActionResult.failed(
        e.refusal == CheckInRefusal.future ? texts?.l10n.habitsErrorFuture : texts?.l10n.habitsErrorArchived,
      );
    }
    return NotificationActionResult.ok;
  }

  Future<NotificationActionResult> _quit(
    NotificationActionContext c,
    QuitHabit habit,
    L10nNotificationTexts? texts,
  ) async {
    final quit = c.read(quitServiceProvider);
    final input = c.input?.trim() ?? '';
    switch (c.actionId) {
      case NotificationActionIds.logCraving:
        final intensity = input.isEmpty ? 5 : int.tryParse(localizeDigitsToAscii(input));
        if (intensity == null || intensity < 1 || intensity > 10) {
          return NotificationActionResult.failed(texts?.l10n.quitNotifInvalidIntensity);
        }
        await quit.logCraving(
          habit,
          input: CravingInput(intensity: intensity),
          source: LogSource.notification,
        );
      case NotificationActionIds.logValue:
        if (habit.mode != QuitMode.reduce) {
          // A use while quitting completely is a relapse: that deserves the kind in-app flow.
          return NotificationActionResult(openLink: AppLinks.quit(habit.id), markActed: false);
        }
        final amount = input.isEmpty ? 1.0 : parseLocalizedDecimal(input);
        if (amount == null || amount <= 0) {
          return NotificationActionResult.failed(texts?.l10n.habitsNotifInvalidValue(input));
        }
        await quit.logUse(habit, amount: amount, source: LogSource.notification);
      case NotificationActionIds.done:
        final logs = await c.read(habitLogsRepositoryProvider).forHabit(habit.id);
        HabitLogEntry? latest;
        for (final l in logs) {
          if (l.kind != HabitLogKind.craving || l.resisted != null) continue;
          if (c.now.difference(l.loggedAt) > const Duration(hours: 2)) continue;
          if (latest == null || l.loggedAt.isAfter(latest.loggedAt)) latest = l;
        }
        if (latest != null) {
          await quit.updateLog(
            latest,
            craving: CravingInput(
              intensity: latest.intensity ?? 5,
              trigger: latest.trigger,
              place: latest.place,
              coping: latest.coping,
              resisted: true,
              durationSeconds: latest.durationSeconds,
              mood: latest.mood,
              note: latest.note,
            ),
          );
        }
      // Rituals (T7.5.14): the day comes from the ritual's occurrence key (`qr:pledge:2026-09-22`).
      case NotificationActionIds.pledge:
        await quit.pledge(habit, day: _ritualDay(c.occurrenceKey), source: LogSource.notification);
      case NotificationActionIds.cleanDay:
        final day = _ritualDay(c.occurrenceKey) ?? c.read(habitPeriodServiceProvider).boundariesOf(habit).dateOf(c.now);
        await quit.markClean(habit, day, source: LogSource.notification);
      case NotificationActionIds.logRelapse:
        // Never logged blind: the kind in-app relapse flow asks what happened.
        return NotificationActionResult(openLink: AppLinks.quit(habit.id), markActed: false);
      default:
        return NotificationActionResult(openLink: c.payload.deepLink ?? AppLinks.quit(habit.id), markActed: false);
    }
    return NotificationActionResult.ok;
  }

  static LocalDate? _ritualDay(String? key) {
    if (key == null || !key.startsWith('qr:')) return null;
    return LocalDate.tryParse(key.substring(key.lastIndexOf(':') + 1));
  }
}

/// Converts Arabic-Indic / Eastern Arabic-Indic digits to ASCII (typed in notification replies).
String localizeDigitsToAscii(String text) {
  final b = StringBuffer();
  for (final c in text.runes) {
    if (c >= 0x0660 && c <= 0x0669) {
      b.writeCharCode(48 + c - 0x0660);
    } else if (c >= 0x06F0 && c <= 0x06F9) {
      b.writeCharCode(48 + c - 0x06F0);
    } else {
      b.writeCharCode(c);
    }
  }
  return b.toString();
}
