import 'dart:async';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/data/habit_logs_repository.dart';
import 'package:everslot/features/habits/data/habit_mappers.dart';
import 'package:everslot/features/habits/data/habits_repository.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_evaluation.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show HabitPeriod, HabitPeriodKind, PeriodResult, evaluateHabitPeriod;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// A refused check-in (future period, archived habit…), mapped to a localized message.
class CheckInException implements Exception {
  const CheckInException(this.refusal);

  final CheckInRefusal refusal;

  @override
  String toString() => 'CheckInException(${refusal.name})';
}

/// What a check-in did (consumed by celebrations [T5.2.13], notification re-planning [7.2] and
/// widgets [8.2]).
@immutable
class HabitCheckInEvent {
  const HabitCheckInEvent({
    required this.habitId,
    required this.key,
    required this.kind,
    required this.source,
    required this.at,
    this.value,
  });

  final String habitId;

  /// Day or slot key.
  final String key;

  /// `done` / `fail` / `skip` / `excuse` / `progress` / `note`, or null for *clear*.
  final HabitLogKind? kind;
  final String source;
  final DateTime at;
  final double? value;
}

/// Result of a check-in: the operation (for *Undo*) and where it landed.
@immutable
class CheckInResult {
  const CheckInResult(this.record, this.target);

  final OpRecord record;
  final CheckInTarget target;
}

/// The one service performing every check-in action identically from any surface — Habits tab,
/// Today [8.1], notification actions [7.2] and widgets [8.2] (T5.2.01).
///
/// - Yes/no & explicit states: exactly one state row per period key with the deterministic id
///   `v5(habit|key|state)`; switching state updates `kind`; *clear* soft-deletes it.
/// - Measurable goals: every addition is a new `progress` row (UUIDv7) so time-of-day patterns
///   survive; *Done* logs the remaining amount as one entry.
/// - Each log carries `logged_at` (event time; backfills use the period's date at the chosen time,
///   default slot time else 12:00), `local_date` (the period's day), the day or slot key and the
///   source. Guards: no done/progress in the future, planned skips/excuses allowed, archived habits
///   are read-only.
class CheckInService {
  CheckInService({required this.logs, required this.habits, required this.periods, required this.clock});

  final HabitLogsRepository logs;
  final HabitsRepository habits;
  final HabitPeriodService periods;
  final Clock clock;

  final _events = StreamController<HabitCheckInEvent>.broadcast();

  /// Committed check-ins.
  Stream<HabitCheckInEvent> get events => _events.stream;

  void dispose() => unawaited(_events.close());

  /// The check-in target of [key] for [habit]: a day key (day and quota habits) or a slot key.
  Future<CheckInTarget> targetFor(BuildHabit habit, String key) async {
    final b = periods.boundariesOf(habit);
    if (key.length == 10) {
      final date = LocalDate.tryParse(key);
      if (date == null) throw ArgumentError.value(key, 'key', 'not a day key');
      return CheckInTarget.day(date, b);
    }
    final revisions = await habits.revisionsFor(habit.id);
    final period = periods.periodForKey(habit, revisions, key);
    if (period == null || period.kind != HabitPeriodKind.slot) {
      throw ArgumentError.value(key, 'key', 'not a slot of this habit');
    }
    return CheckInTarget.ofPeriod(period, b);
  }

  /// The period "check now" targets (the current day, the slot per early tolerance, or today inside
  /// a quota period); null when nothing is due yet.
  Future<CheckInTarget?> currentTarget(BuildHabit habit) async {
    final now = clock.nowUtc();
    final revisions = await habits.revisionsFor(habit.id);
    final period = periods.periodForInstant(habit, revisions, now);
    if (period == null) return null;
    return CheckInTarget.ofPeriod(period, periods.boundariesOf(habit), date: periods.dateOf(habit, now));
  }

  void _guard(Habit habit, CheckInTarget target, {CheckInState? state, bool progress = false}) {
    final refusal = checkInRefusal(
      target: target,
      now: clock.nowUtc(),
      archived: habit.isArchived,
      state: state,
      progress: progress,
    );
    if (refusal != null) throw CheckInException(refusal);
  }

  DateTime _instant(BuildHabit habit, CheckInTarget target, LocalTime? at) =>
      checkInInstant(target, now: clock.nowUtc(), boundaries: periods.boundariesOf(habit), chosenTime: at);

  void _emit(BuildHabit habit, CheckInTarget target, HabitLogKind? kind, String source, DateTime at, {double? value}) {
    if (!_events.isClosed) {
      _events.add(
        HabitCheckInEvent(habitId: habit.id, key: target.key, kind: kind, source: source, at: at, value: value),
      );
    }
  }

  /// Sets (or clears, with a null [state]) the explicit state of a period. On a measurable habit,
  /// [CheckInState.done] logs the remaining amount as one progress entry instead.
  Future<CheckInResult> setState(
    BuildHabit habit,
    String key,
    CheckInState? state, {
    String source = LogSource.manual,
    String? note,
    int? mood,
    LocalTime? at,
  }) async {
    if (state == CheckInState.done && habit.goal.isMeasurable && !_isQuota(habit)) {
      return markDone(habit, key, source: source, note: note, mood: mood, at: at);
    }
    final target = await targetFor(habit, key);
    if (state == null) return clear(habit, key);
    _guard(habit, target, state: state);
    final loggedAt = _instant(habit, target, at);
    final record = await logs.write((tx) async {
      await HabitLogsRepository.upsertStateInTx(
        tx,
        habitId: habit.id,
        key: target.key,
        kind: state.kind,
        loggedAt: loggedAt,
        localDate: target.localDate,
        source: source,
        note: note,
        mood: mood,
      );
    });
    _emit(habit, target, state.kind, source, loggedAt);
    return CheckInResult(record, target);
  }

  bool _isQuota(BuildHabit habit) => ScheduleShape.of(habit.schedule) == ScheduleShape.quota;

  /// "I did it": yes/no → `done` state; measurable → the remaining amount as one progress entry.
  Future<CheckInResult> markDone(
    BuildHabit habit,
    String key, {
    String source = LogSource.manual,
    String? note,
    int? mood,
    LocalTime? at,
  }) async {
    if (!habit.goal.isMeasurable || _isQuota(habit)) {
      return setState(habit, key, CheckInState.done, source: source, note: note, mood: mood, at: at);
    }
    final target = await targetFor(habit, key);
    _guard(habit, target, state: CheckInState.done, progress: true);
    final period = await _periodResult(habit, target);
    final remaining = period == null ? habit.goal.effectiveTarget : remainingToTarget(period);
    if (remaining <= 0) {
      // Already reached: record the explicit statement without inflating the total.
      return setState(habit, key, CheckInState.done, source: source, note: note, mood: mood, at: at);
    }
    return addProgress(habit, key, remaining, source: source, note: note, mood: mood, at: at);
  }

  Future<CheckInResult> markNotDone(BuildHabit habit, String key, {String source = LogSource.manual, String? note}) =>
      setState(habit, key, CheckInState.notDone, source: source, note: note);

  Future<CheckInResult> skip(BuildHabit habit, String key, {String source = LogSource.manual, String? note}) =>
      setState(habit, key, CheckInState.skip, source: source, note: note);

  Future<CheckInResult> excuse(BuildHabit habit, String key, {String source = LogSource.manual, String? note}) =>
      setState(habit, key, CheckInState.excuse, source: source, note: note);

  /// Clears the explicit state of a period (progress entries are kept).
  Future<CheckInResult> clear(BuildHabit habit, String key, {String source = LogSource.manual}) async {
    final target = await targetFor(habit, key);
    if (habit.isArchived) throw const CheckInException(CheckInRefusal.archived);
    final record = await logs.write((tx) async {
      await HabitLogsRepository.clearStateInTx(tx, habit.id, target.key);
    });
    _emit(habit, target, null, source, clock.nowUtc());
    return CheckInResult(record, target);
  }

  /// Adds a progress entry (count, minutes, numeric value) to a period.
  Future<CheckInResult> addProgress(
    BuildHabit habit,
    String key,
    double value, {
    String source = LogSource.manual,
    String? note,
    int? mood,
    int? durationSeconds,
    LocalTime? at,
  }) async {
    if (value <= 0 || value.isNaN) throw ArgumentError.value(value, 'value', 'must be > 0');
    final target = await targetFor(habit, key);
    _guard(habit, target, progress: true);
    final loggedAt = _instant(habit, target, at);
    final entry = HabitLogEntry(
      id: Ids.v7(),
      habitId: habit.id,
      kind: HabitLogKind.progress,
      loggedAt: loggedAt,
      localDate: target.localDate,
      occurrenceKey: target.key,
      value: value,
      note: note,
      mood: mood,
      durationSeconds: durationSeconds,
      source: source,
    );
    final record = await logs.write((tx) => HabitLogsRepository.insertInTx(tx, entry));
    _emit(habit, target, HabitLogKind.progress, source, loggedAt, value: value);
    return CheckInResult(record, target);
  }

  /// Edits an entry (value, time, note, mood).
  Future<OpRecord> updateEntry(
    HabitLogEntry entry, {
    double? value,
    DateTime? loggedAt,
    Object? note = _keep,
    Object? mood = _keep,
  }) {
    if (value != null && (value < 0 || value.isNaN)) throw ArgumentError.value(value, 'value', 'must be ≥ 0');
    return logs.write(
      (tx) => HabitLogsRepository.updateInTx(tx, entry.id, {
        'value': ?value,
        if (loggedAt != null) 'logged_at': loggedAt.toUtc(),
        if (!identical(note, _keep)) 'note': _cleanNote(note as String?),
        if (!identical(mood, _keep)) 'mood': mood as int?,
      }),
    );
  }

  Future<OpRecord> deleteEntry(HabitLogEntry entry) => logs.write((tx) => HabitLogsRepository.deleteInTx(tx, entry.id));

  /// Note & mood of a period (T5.2.09): on the state row when there is one (yes/no habits), else on
  /// the period's `note` row (deterministic id).
  Future<CheckInResult> setNoteAndMood(BuildHabit habit, String key, {String? note, int? mood}) async {
    final target = await targetFor(habit, key);
    if (habit.isArchived) throw const CheckInException(CheckInRefusal.archived);
    final cleanNote = note?.trim().isEmpty ?? true ? null : note!.trim();
    final record = await logs.write((tx) async {
      final stateId = HabitLogsRepository.stateId(habit.id, target.key);
      final state = await tx.readRaw('habit_logs', stateId);
      if (state != null && state['deleted_at'] == null) {
        await tx.update('habit_logs', stateId, {'note': cleanNote, 'mood': mood});
        return;
      }
      await HabitLogsRepository.upsertInTx(
        tx,
        HabitLogEntry(
          id: HabitIds.periodNote(habit.id, target.key),
          habitId: habit.id,
          kind: HabitLogKind.note,
          loggedAt: _instant(habit, target, null),
          localDate: target.localDate,
          occurrenceKey: target.key,
          note: cleanNote,
          mood: mood,
        ),
      );
    });
    _emit(habit, target, HabitLogKind.note, LogSource.manual, clock.nowUtc());
    return CheckInResult(record, target);
  }

  /// "Check now": marks the current period (slot per early tolerance) done.
  Future<CheckInResult> checkNow(BuildHabit habit, {String source = LogSource.manual}) async {
    final target = await currentTarget(habit);
    if (target == null) throw const CheckInException(CheckInRefusal.future);
    return markDone(habit, target.key, source: source);
  }

  /// Evaluates the period of [target] right now (remaining amounts, "2/3").
  Future<PeriodResult?> _periodResult(BuildHabit habit, CheckInTarget target) async {
    final revisions = await habits.revisionsFor(habit.id);
    final HabitPeriod? period;
    if (target.isSlot) {
      period = periods.periodForKey(habit, revisions, target.key);
    } else {
      final ps = periods.periodsOn(habit, revisions, target.localDate);
      period = ps.isEmpty ? null : ps.first;
    }
    if (period == null) return null;
    final entries = [
      for (final l in await logs.forHabit(habit.id))
        if (buildLogKinds.contains(l.kind)) l.toMetrics(),
    ];
    final now = clock.nowUtc();
    return evaluateHabitPeriod(period, entries, now: now, today: periods.dateOf(habit, now));
  }

  static String? _cleanNote(String? note) => note == null || note.trim().isEmpty ? null : note.trim();

  static const Object _keep = Object();
}

final checkInServiceProvider = Provider<CheckInService>((ref) {
  final service = CheckInService(
    logs: ref.watch(habitLogsRepositoryProvider),
    habits: ref.watch(habitsRepositoryProvider),
    periods: ref.watch(habitPeriodServiceProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Committed check-ins (celebrations, re-planning, widgets).
final habitCheckInEventsProvider = StreamProvider<HabitCheckInEvent>((ref) => ref.watch(checkInServiceProvider).events);
