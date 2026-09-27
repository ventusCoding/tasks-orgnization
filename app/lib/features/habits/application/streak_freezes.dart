import 'package:everslot/core/providers.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/data/habit_logs_repository.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

/// How far back the job materializes freezes (older ones stay virtual in the streak engine).
const freezeLookbackDays = 62;

/// The "close periods" job of streak freezes (T5.4.06). The streak engine (`everslot_metrics`)
/// already forgives the first freezable misses of each month (`freezesPerMonth`, no carry-over);
/// this job materializes those as the period's state row with kind `freeze` — deterministic id
/// `v5(habit|key|state)` and the period's end as the clock — so every device converges on the
/// same rows, calendars and stats label them *Frozen*, and completion rates still count them as
/// misses. Idempotent; runs at start-up and when the Habits tab opens or resumes (day rollover).
class StreakFreezeJob {
  StreakFreezeJob(this._read);

  final T Function<T>(ProviderListenable<T> provider) _read;

  /// Writes the missing freeze rows; returns how many were written.
  Future<int> run() async {
    final habits = await _read(habitsRepositoryProvider).all(includeArchived: false, kind: HabitKind.build);
    final now = _read(clockProvider).nowUtc();
    var written = 0;
    for (final habit in habits) {
      if (habit is! BuildHabit || habit.freezesPerMonth <= 0) continue;
      final snapshot = await loadHabitSnapshot(_read, habit, now);
      final summary = snapshot.summary;
      final evaluation = snapshot.evaluation;
      if (summary == null || evaluation == null) continue;
      final since = snapshot.today.minusDays(freezeLookbackDays);
      for (final key in summary.streaks.frozenKeys) {
        // Logs carry day or slot keys only (quota periods stay virtual).
        final date = key.length == 10 ? LocalDate.tryParse(key) : null;
        if (date == null || date.isBefore(since)) continue;
        if (snapshot.stateOf(key)?.kind == HabitLogKind.freeze) continue;
        final unit = evaluation.units.where((u) => u.key == key).firstOrNull;
        if (unit == null) continue;
        await _read(habitLogsRepositoryProvider).write(
          (tx) => HabitLogsRepository.upsertStateInTx(
            tx,
            habitId: habit.id,
            key: key,
            kind: HabitLogKind.freeze,
            loggedAt: unit.windowEnd,
            localDate: date,
            source: LogSource.auto,
          ),
          cause: 'auto',
          scheduledAt: unit.windowEnd,
        );
        written++;
      }
    }
    return written;
  }
}

final streakFreezeJobProvider = Provider<StreakFreezeJob>((ref) => StreakFreezeJob(ref.read));
