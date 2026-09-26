import 'dart:async';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/data/habit_logs_repository.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// A quit event that other features react to (celebrations, notifications, widgets).
@immutable
class QuitEvent {
  const QuitEvent(this.habitId, this.kind, this.at);

  final String habitId;
  final HabitLogKind kind;
  final DateTime at;
}

/// Craving details (T5.3.08).
@immutable
class CravingInput {
  const CravingInput({
    this.intensity = 5,
    this.trigger,
    this.place,
    this.coping,
    this.resisted,
    this.durationSeconds,
    this.mood,
    this.note,
  });

  final int intensity;
  final String? trigger;
  final String? place;
  final String? coping;

  /// yes / no / not sure (null).
  final bool? resisted;
  final int? durationSeconds;
  final int? mood;
  final String? note;
}

/// Quit tracker actions (T5.3.06–T5.3.09, T5.3.13) — the same service is used by the dashboard,
/// Today [8.1], notification actions [7.2] and widgets [8.2]. `quit_started_at` is the first quit
/// and is never overwritten: new attempts are `restart` logs.
class QuitService {
  QuitService({required this.logs, required this.periods, required this.clock});

  final HabitLogsRepository logs;
  final HabitPeriodService periods;
  final Clock clock;

  final _events = StreamController<QuitEvent>.broadcast();

  Stream<QuitEvent> get events => _events.stream;

  void dispose() => unawaited(_events.close());

  void _emit(String habitId, HabitLogKind kind, DateTime at) {
    if (!_events.isClosed) _events.add(QuitEvent(habitId, kind, at));
  }

  LocalDate _dateOf(QuitHabit habit, DateTime at) => periods.dateOf(habit, at);

  DateTime _at(DateTime? at) {
    final now = clock.nowUtc();
    final value = (at ?? now).toUtc();
    return value.isAfter(now) ? now : value;
  }

  static String? _clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();

  HabitLogEntry _entry(
    QuitHabit habit,
    HabitLogKind kind,
    DateTime at, {
    double? value,
    int? intensity,
    String? trigger,
    String? place,
    String? coping,
    bool? resisted,
    int? durationSeconds,
    int? mood,
    String? note,
    String source = LogSource.manual,
    String? id,
  }) => HabitLogEntry(
    id: id ?? Ids.v7(),
    habitId: habit.id,
    kind: kind,
    loggedAt: at,
    localDate: _dateOf(habit, at),
    value: value,
    intensity: intensity,
    trigger: _clean(trigger),
    place: _clean(place),
    coping: _clean(coping),
    resisted: resisted,
    durationSeconds: durationSeconds,
    mood: mood,
    note: _clean(note),
    source: source,
  );

  /// Logs a relapse at [at] (default now; may be in the past). With [newAttempt] a `restart` log
  /// starts a new quit attempt at [restartAt] (default: the relapse time); otherwise it is a slip
  /// (the quit date stays, the streak restarts at the relapse).
  Future<OpRecord> logRelapse(
    QuitHabit habit, {
    DateTime? at,
    double? amount,
    String? trigger,
    String? place,
    int? mood,
    String? note,
    bool newAttempt = false,
    DateTime? restartAt,
    String source = LogSource.manual,
  }) async {
    if (amount != null && amount < 0) throw ArgumentError.value(amount, 'amount', 'must be ≥ 0');
    final when = _at(at);
    final record = await logs.write((tx) async {
      await HabitLogsRepository.insertInTx(
        tx,
        _entry(habit, HabitLogKind.relapse, when, value: amount, trigger: trigger, place: place, mood: mood, note: note, source: source),
      );
      if (newAttempt) {
        final restart = _at(restartAt ?? when);
        await HabitLogsRepository.insertInTx(
          tx,
          _entry(
            habit,
            HabitLogKind.restart,
            restart.isBefore(when) ? when : restart,
            source: source,
          ),
        );
      }
      await tx.logEvent(
        entityType: 'habit',
        entityId: habit.id,
        eventType: 'relapse',
        payload: {'newAttempt': newAttempt},
      );
    });
    _emit(habit.id, HabitLogKind.relapse, when);
    return record;
  }

  /// Overflow "Reset counter" = relapse without amount, note "manual reset".
  Future<OpRecord> resetCounter(QuitHabit habit, {required String note}) => logRelapse(habit, note: note);

  /// Reduce mode: one consumption log ("+1" or a custom amount).
  Future<OpRecord> logUse(
    QuitHabit habit, {
    double amount = 1,
    DateTime? at,
    String? trigger,
    String? place,
    int? mood,
    String? note,
    String source = LogSource.manual,
  }) async {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount', 'must be > 0');
    final when = _at(at);
    final record = await logs.write(
      (tx) => HabitLogsRepository.insertInTx(
        tx,
        _entry(habit, HabitLogKind.use, when, value: amount, trigger: trigger, place: place, mood: mood, note: note, source: source),
      ),
    );
    _emit(habit.id, HabitLogKind.use, when);
    return record;
  }

  /// Logs a craving (one tap = now at intensity 5, editable afterwards).
  Future<({OpRecord record, String id})> logCraving(
    QuitHabit habit, {
    DateTime? at,
    CravingInput input = const CravingInput(),
    String source = LogSource.manual,
  }) async {
    final when = _at(at);
    final entry = _entry(
      habit,
      HabitLogKind.craving,
      when,
      intensity: input.intensity.clamp(1, 10),
      trigger: input.trigger,
      place: input.place,
      coping: input.coping,
      resisted: input.resisted,
      durationSeconds: input.durationSeconds,
      mood: input.mood,
      note: input.note,
      source: source,
    );
    final record = await logs.write((tx) => HabitLogsRepository.insertInTx(tx, entry));
    _emit(habit.id, HabitLogKind.craving, when);
    return (record: record, id: entry.id);
  }

  /// Edits a craving / relapse / use (the calculator recomputes everything from the logs).
  Future<OpRecord> updateLog(HabitLogEntry entry, {CravingInput? craving, double? amount, DateTime? at, String? note}) =>
      logs.write(
        (tx) => HabitLogsRepository.updateInTx(tx, entry.id, {
          if (craving != null) ...{
            'intensity': craving.intensity.clamp(1, 10),
            'trigger': _clean(craving.trigger),
            'place': _clean(craving.place),
            'coping': _clean(craving.coping),
            'resisted': craving.resisted,
            'duration_seconds': craving.durationSeconds,
            'mood': craving.mood,
            'note': _clean(craving.note),
          },
          'value': ?amount,
          if (at != null) 'logged_at': _at(at),
          if (note != null) 'note': _clean(note),
        }),
      );

  Future<OpRecord> deleteLog(HabitLogEntry entry) => logs.write((tx) => HabitLogsRepository.deleteInTx(tx, entry.id));

  /// Evening review "Yes" / explicit mode: the `clean` state of [day] (`v5(habit|day|state)`).
  Future<OpRecord> markClean(QuitHabit habit, LocalDate day, {String source = LogSource.manual}) async {
    final b = periods.boundariesOf(habit);
    final now = clock.nowUtc();
    final end = b.endOf(day);
    final at = end.isAfter(now) ? now : end.subtract(const Duration(minutes: 1));
    final record = await logs.write(
      (tx) => HabitLogsRepository.upsertStateInTx(
        tx,
        habitId: habit.id,
        key: day.toIso(),
        kind: HabitLogKind.clean,
        loggedAt: at,
        localDate: day,
        source: source,
      ),
    );
    _emit(habit.id, HabitLogKind.clean, at);
    return record;
  }

  Future<OpRecord> clearClean(QuitHabit habit, LocalDate day) =>
      logs.write((tx) => HabitLogsRepository.clearStateInTx(tx, habit.id, day.toIso()));

  /// Morning pledge of [day] (default today) — one row per day `v5(habit|day|pledge)`, so pledging on
  /// two devices converges.
  Future<OpRecord> pledge(QuitHabit habit, {LocalDate? day, String source = LogSource.manual}) async {
    final now = clock.nowUtc();
    final date = day ?? _dateOf(habit, now);
    final record = await logs.write(
      (tx) => HabitLogsRepository.upsertInTx(
        tx,
        HabitLogEntry(
          id: Ids.habitPledge(habit.id, date.toIso()),
          habitId: habit.id,
          kind: HabitLogKind.pledge,
          loggedAt: now,
          localDate: date,
          occurrenceKey: date.toIso(),
          source: source,
        ),
      ),
    );
    _emit(habit.id, HabitLogKind.pledge, now);
    return record;
  }
}

final quitServiceProvider = Provider<QuitService>((ref) {
  final service = QuitService(
    logs: ref.watch(habitLogsRepositoryProvider),
    periods: ref.watch(habitPeriodServiceProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final quitEventsProvider = StreamProvider<QuitEvent>((ref) => ref.watch(quitServiceProvider).events);
