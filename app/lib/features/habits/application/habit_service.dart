import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/data/habit_logs_repository.dart';
import 'package:everslot/features/habits/data/habit_sections_repository.dart';
import 'package:everslot/features/habits/data/habits_repository.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/notifications/presentation/notification_settings_section.dart'
    show NotificationHostApi, NotificationRulesDraft, NotificationTargetType, notificationHostApiProvider;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:everslot/features/habits/data/habits_repository.dart' show RevisionScope;

/// Habit management commands (T5.1.04, T5.1.13–T5.1.15, T5.3.02, T5.4.05). Every command is one
/// operation (undoable); reminder drafts of unsaved habits are saved in the same transaction.
class HabitService {
  HabitService({
    required this.habits,
    required this.pauses,
    required this.sections,
    required this.periods,
    required this.clock,
    this.notifications,
  });

  final HabitsRepository habits;
  final HabitPausesRepository pauses;
  final HabitSectionsRepository sections;
  final HabitPeriodService periods;
  final Clock clock;

  /// Reminder persistence of the notifications feature (null in isolated tests).
  final NotificationHostApi? notifications;

  LocalDate todayOf(Habit habit) => periods.dateOf(habit, clock.nowUtc());

  /// Creates a habit / quit tracker; [reminders] (unsaved reminders) are saved with it.
  Future<OpRecord> create(Habit habit, {NotificationRulesDraft? reminders}) => habits.create(
    habit,
    inTx: reminders == null || reminders.isEmpty || notifications == null
        ? null
        : (tx) => notifications!
              .saveDraftInTx(tx, reminders, type: NotificationTargetType.habit, targetId: habit.id)
              .then((_) {}),
  );

  /// Saves an edited habit; rule changes apply from [applyFrom] (default today) or to all history.
  Future<OpRecord> update(Habit habit, {LocalDate? applyFrom, RevisionScope scope = RevisionScope.fromDate}) =>
      habits.update(habit, today: todayOf(habit), applyFrom: applyFrom, scope: scope);

  /// Deletes the habit (logs, pauses, revisions, goals and its reminders) — restorable from Trash.
  Future<OpRecord> delete(String id) => habits.delete(
    id,
    inTx: notifications == null
        ? null
        : (tx) => notifications!.deleteForTargetInTx(tx, NotificationTargetType.habit, id),
  );

  Future<OpRecord> restore(String id) => habits.restore(id);

  Future<OpRecord> setArchived(String id, {required bool archived}) => habits.setArchived(id, archived: archived);

  /// Moves [id] to [index] of [ordered] without it (drag & drop); with [changeSection] it also
  /// moves into [sectionId].
  Future<OpRecord> reorder(
    String id,
    List<Habit> ordered,
    int index, {
    bool changeSection = false,
    String? sectionId,
  }) {
    final keys = [
      for (final h in ordered)
        if (h.id != id) h.sortKey,
    ];
    final n = neighboursAt(keys, index);
    return habits.move(id, afterKey: n.after, beforeKey: n.before, changeSection: changeSection, sectionId: sectionId);
  }

  Future<OpRecord> moveToSection(String id, String? sectionId) => habits.patch(id, {'section_id': sectionId});

  Future<OpRecord> patch(String id, Map<String, Object?> columns) => habits.patch(id, columns);

  /// Pauses one habit ([habitId]) or every habit (vacation) from [start] to [end] (inclusive; null =
  /// indefinitely).
  Future<OpRecord> pause({String? habitId, required LocalDate start, LocalDate? end, String? reason}) =>
      pauses.create(start: start, end: end, habitId: habitId, reason: reason);

  /// Resume: the pause ends yesterday (today becomes active again).
  Future<OpRecord> resume(PauseSpan pause, {required LocalDate today}) => pauses.end(pause, today.minusDays(1));

  /// Challenge "Keep going" (T5.4.05): the habit continues without an end date, history kept.
  Future<OpRecord> keepGoing(BuildHabit habit) =>
      habits.patch(habit.id, {'end_date': null, 'settings': habit.settings.copyWith(challenge: null).toJson()});
}

final habitServiceProvider = Provider<HabitService>(
  (ref) => HabitService(
    habits: ref.watch(habitsRepositoryProvider),
    pauses: ref.watch(habitPausesRepositoryProvider),
    sections: ref.watch(habitSectionsRepositoryProvider),
    periods: ref.watch(habitPeriodServiceProvider),
    clock: ref.watch(clockProvider),
    notifications: ref.watch(notificationHostApiProvider),
  ),
);
