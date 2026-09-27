import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_evaluation.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show HabitPeriodKind, PeriodFlags, PeriodResult, PeriodStatus, evaluateHabitPeriod;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Where a habit sits in the Today list of a day (T5.2.03): *Due* → *Done* → *Not due today*.
enum DayGroup { due, done, notDue }

/// One build habit on one day: its result (day / slot roll-up / quota day view), the quota period
/// and slots, the key primary actions target, and the list group.
@immutable
class HabitDayView {
  const HabitDayView({
    required this.snapshot,
    required this.date,
    required this.key,
    required this.group,
    required this.shape,
    this.result,
    this.quota,
    this.slots = const [],
    this.future = false,
  });

  final HabitSnapshot snapshot;
  final LocalDate date;

  /// Day key (day & quota habits) or the slot key primary actions target.
  final String key;
  final DayGroup group;
  final ScheduleShape shape;
  final PeriodResult? result;
  final PeriodResult? quota;
  final List<PeriodResult> slots;

  /// The day is after the habit's today (only planned skips/excuses allowed).
  final bool future;

  BuildHabit get habit => snapshot.build!;
  PeriodStatus get status => result?.status ?? PeriodStatus.notDue;
  double get achieved => result?.achieved ?? 0;
  double get target => result?.target ?? habit.goal.effectiveTarget;
  bool get isSlot => shape == ScheduleShape.slot;
  bool get isQuota => shape == ScheduleShape.quota;
  int get streak => snapshot.summary?.currentStreak ?? 0;
  bool get atRisk => quota?.flags.atRisk ?? false;

  /// Explicit state row of the day (or of the targeted slot).
  HabitLogEntry? get explicit => snapshot.stateOf(key);

  /// Progress 0…1 for rings (limits show the remaining allowance).
  double get progress {
    if (isQuota && quota != null) {
      final q = quota!;
      if (q.target <= 0) return q.status == PeriodStatus.done ? 1 : 0;
      return (q.achieved / q.target).clamp(0, 1).toDouble();
    }
    if (target <= 0) return status == PeriodStatus.done ? 1 : 0;
    if (habit.goal.isLimit) return (achieved / target).clamp(0, 1).toDouble();
    return (achieved / target).clamp(0, 1).toDouble();
  }
}

/// Builds the day view of a build-habit [snapshot] on [date]; null when the habit is not active that
/// day (before its start, after its end).
HabitDayView? habitDayView(HabitSnapshot snapshot, LocalDate date, HabitPeriodService service) {
  final habit = snapshot.build;
  if (habit == null) return null;
  if (date.isBefore(habit.startDate) || (habit.endDate != null && date.isAfter(habit.endDate!))) return null;
  final shape = ScheduleShape.of(service.rulesOn(habit, snapshot.revisions, date).schedule);
  final eval = snapshot.evaluation!;
  final future = date.isAfter(snapshot.today);
  var slots = eval.slotsOn(date);
  var result = eval.dayOn(date);
  var quota = eval.quotaOn(date);
  if (future) {
    // Future days are not evaluated: show what is planned (due / explicit skip or excuse).
    final periods = service.periodsOn(habit, snapshot.revisions, date);
    final dayLogs = [
      for (final l in snapshot.logs)
        if (buildLogKinds.contains(l.kind)) l.toMetrics(),
    ];
    slots = [
      for (final p in periods)
        if (p.kind == HabitPeriodKind.slot) evaluateHabitPeriod(p, dayLogs, now: snapshot.now, today: snapshot.today),
    ];
    final day = periods.where((p) => p.kind == HabitPeriodKind.day).firstOrNull;
    final state = snapshot.stateOf(date.toIso());
    final planned = switch (state?.kind) {
      HabitLogKind.skip => PeriodStatus.skipped,
      HabitLogKind.excuse => PeriodStatus.excused,
      _ => null,
    };
    final due = (day?.due ?? false) || slots.isNotEmpty || periods.any((p) => p.kind == HabitPeriodKind.quota);
    final b = snapshot.boundaries;
    result = PeriodResult(
      date.toIso(),
      kind: HabitPeriodKind.day,
      startDate: date,
      endDate: date,
      windowStart: b.startOf(date),
      windowEnd: b.endOf(date),
      status: planned ?? (due ? PeriodStatus.pending : PeriodStatus.notDue),
      achieved: 0,
      target: slots.isNotEmpty ? slots.length.toDouble() : habit.goal.effectiveTarget,
      goal: habit.goal.toMetrics(),
      flags: const PeriodFlags(future: true),
    );
    quota = null;
  }
  final key = switch (shape) {
    ScheduleShape.slot => _slotKey(snapshot, date, slots) ?? date.toIso(),
    _ => date.toIso(),
  };
  final group = _groupOf(shape, result, quota, snapshot.stateOf(date.toIso()));
  return HabitDayView(
    snapshot: snapshot,
    date: date,
    key: key,
    group: group,
    shape: shape,
    result: result,
    quota: quota,
    slots: slots,
    future: future,
  );
}

String? _slotKey(HabitSnapshot s, LocalDate date, List<PeriodResult> slots) {
  if (slots.isEmpty) return null;
  if (date == s.today) {
    final current = s.currentPeriod;
    if (current != null && current.kind == HabitPeriodKind.slot && current.startDate == date) return current.key;
    for (final r in slots) {
      if (r.status == PeriodStatus.pending) return r.key;
    }
  }
  for (final r in slots) {
    if (r.status != PeriodStatus.done) return r.key;
  }
  return slots.last.key;
}

DayGroup _groupOf(ScheduleShape shape, PeriodResult? result, PeriodResult? quota, HabitLogEntry? dayState) {
  if (shape == ScheduleShape.quota && quota != null) {
    if (quota.status == PeriodStatus.done) return DayGroup.done;
    final day = result?.status;
    if (day == PeriodStatus.done || day == PeriodStatus.skipped || day == PeriodStatus.excused) return DayGroup.done;
    if (quota.status == PeriodStatus.paused || quota.status == PeriodStatus.excused) return DayGroup.notDue;
    return DayGroup.due;
  }
  return switch (result?.status) {
    null || PeriodStatus.notDue || PeriodStatus.paused => DayGroup.notDue,
    PeriodStatus.done ||
    PeriodStatus.skipped ||
    PeriodStatus.excused ||
    PeriodStatus.frozen ||
    PeriodStatus.failed => DayGroup.done,
    PeriodStatus.pending || PeriodStatus.partial || PeriodStatus.missed => DayGroup.due,
  };
}

/// Day views of every active build habit on [date] (Today list, T5.2.03), in habit order.
final habitDayViewsProvider = Provider.family<AsyncValue<List<HabitDayView>>, LocalDate>((ref, date) {
  final habitsAsync = ref.watch(habitsProvider);
  final habits = habitsAsync.value;
  if (habits == null) {
    return habitsAsync.hasError
        ? AsyncValue.error(habitsAsync.error!, habitsAsync.stackTrace ?? StackTrace.current)
        : const AsyncValue.loading();
  }
  final service = ref.watch(habitPeriodServiceProvider);
  final views = <HabitDayView>[];
  for (final h in habits) {
    if (h is! BuildHabit) continue;
    final snap = ref.watch(habitSnapshotProvider(h.id));
    if (snap.isLoading && !snap.hasValue) return const AsyncValue.loading();
    final value = snap.value;
    if (value == null) continue;
    final view = habitDayView(value, date, service);
    if (view != null) views.add(view);
  }
  return AsyncValue.data(views);
});

/// Active quit trackers with their snapshots (quit strip, all clocks).
final quitSnapshotsProvider = Provider<AsyncValue<List<HabitSnapshot>>>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final habits = habitsAsync.value;
  if (habits == null) return const AsyncValue.loading();
  final out = <HabitSnapshot>[];
  for (final h in habits) {
    if (h is! QuitHabit) continue;
    final snap = ref.watch(habitSnapshotProvider(h.id)).value;
    if (snap != null) out.add(snap);
  }
  return AsyncValue.data(out);
});
