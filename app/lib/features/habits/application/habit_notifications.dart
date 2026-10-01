import 'package:decimal/decimal.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_labels.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
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

/// Savings thresholds projected as `money_saved` milestones (in the tracker's currency).
const quitMoneyThresholds = <int>[10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000];

/// The notification target of one quit tracker (T7.2.06 contract): the item itself (no
/// occurrence), with `milestoneBaseline` = the current abstinence start (the planner projects the
/// `clean_days` milestones) and projected `money_saved` milestones at the current saving rate.
/// The guard makes milestones obsolete after a relapse; today's window lets daily rules (pledge,
/// evening review) anchor on `period_start` / `period_end`.
NotificationTarget? buildQuitTarget(HabitSnapshot snapshot, {required DateTime now, L10nNotificationTexts? texts}) {
  final habit = snapshot.quitHabit;
  final calc = snapshot.quit;
  if (habit == null || calc == null || habit.isArchived) return null;
  final baseline = calc.currentAbstinenceStart;
  final currency = habit.currency;
  final saved = calc.moneySaved;
  final milestones = <NotificationMilestone>[];
  final econ = calc.tracker.economicsOn(snapshot.today);
  final cost = econ.unitCost;
  if (habit.mode == QuitMode.abstain && cost != null && currency != null && econ.baselinePerDay > 0) {
    // Saving rate per minute at today's economics.
    final perMinute = econ.baselinePerDay * cost.toDouble() / 1440;
    for (final t in quitMoneyThresholds) {
      final missing = Decimal.fromInt(t) - saved;
      if (missing <= Decimal.zero) continue;
      final at = now.add(Duration(minutes: (missing.toDouble() / perMinute).ceil()));
      if (at.difference(now) > const Duration(days: 400)) break;
      final amount = texts?.format.currency(t, currency) ?? '$t $currency';
      milestones.add(
        NotificationMilestone(
          metric: 'money_saved',
          threshold: t,
          at: at,
          label: texts?.l10n.quitNotifMoneyMilestone(amount),
        ),
      );
    }
  }
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
    streak: now.difference(baseline).inDays,
    variables: {
      'clean_days': '${calc.cleanDays}',
      if (currency != null && cost != null)
        'money_saved': texts?.format.currency(saved.toDouble(), currency) ?? '${saved.toStringAsFixed(2)} $currency',
    },
    deepLink: AppLinks.quit(habit.id),
    defaultActions: habit.mode == QuitMode.reduce
        ? const [NotificationActionIds.logValue, NotificationActionIds.logCraving]
        : const [NotificationActionIds.logCraving, NotificationActionIds.open],
  );
}

/// Makes build habits notifiable (section `habits`): reminders at slots / on due days, streak at
/// risk, quota behind, not done by… (README §2).
class HabitsNotificationSource implements NotificationTargetSource {
  HabitsNotificationSource(this._ref);

  final Ref _ref;

  @override
  String get section => NotificationSection.habits.wire;

  /// Writes to `habits`, `habit_logs`, `habit_pauses` and `habit_revisions` already trigger replans.
  @override
  Stream<void> get changes => const Stream<void>.empty();

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
    return [
      for (final tracker in trackers)
        if (buildQuitTarget(await loadHabitSnapshot(_ref.read, tracker, now), now: now, texts: texts) case final t?) t,
    ];
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
      default:
        return NotificationActionResult(openLink: c.payload.deepLink ?? AppLinks.quit(habit.id), markActed: false);
    }
    return NotificationActionResult.ok;
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
