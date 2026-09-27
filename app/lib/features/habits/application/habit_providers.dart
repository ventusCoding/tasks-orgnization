import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/features/habits/data/habit_logs_repository.dart';
import 'package:everslot/features/habits/data/habit_sections_repository.dart';
import 'package:everslot/features/habits/data/habits_repository.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_evaluation.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/quit.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show DayBoundaries, HabitLogKind, HabitPeriod, PeriodResult, QuitCalculator;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

// ------------------------------------------------------------------------------ repositories --

final habitsRepositoryProvider = Provider<HabitsRepository>(
  (ref) => HabitsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

final habitLogsRepositoryProvider = Provider<HabitLogsRepository>(
  (ref) => HabitLogsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

final habitPausesRepositoryProvider = Provider<HabitPausesRepository>(
  (ref) => HabitPausesRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

final habitSectionsRepositoryProvider = Provider<HabitSectionsRepository>(
  (ref) => HabitSectionsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

final habitVocabRepositoryProvider = Provider<HabitVocabRepository>(
  (ref) => HabitVocabRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

final habitTimerStoreProvider = Provider<HabitTimerStore>((ref) => HabitTimerStore(ref.watch(appDatabaseProvider)));

/// Local UI memory of the Habits tab (last view & filter).
final habitUiStoreProvider = Provider<HabitUiStore>((ref) => HabitUiStore(ref.watch(appDatabaseProvider)));

/// Local duration timers (T5.2.04).
final habitTimersProvider = StreamProvider<List<HabitTimer>>((ref) => ref.watch(habitTimerStoreProvider).watchAll());

// ------------------------------------------------------------------------------ time & periods --

/// The habit period service for the current zone, day start and week start (T5.1.05). It reuses
/// the engine (and resolver) of the app's recurrence facade.
final habitPeriodServiceProvider = Provider<HabitPeriodService>((ref) {
  final recurrence = ref.watch(recurrenceServiceProvider);
  return HabitPeriodService(
    engine: recurrence.engine,
    currentZone: recurrence.currentZone,
    dayStartsAt: LocalTime.fromMinuteOfDay(recurrence.dayStartMinutes.clamp(0, 1439)),
    weekStart: recurrence.weekStart,
  );
});

/// Bumped by visible habit screens (minute timer, resume, day rollover) so time-based statuses
/// (slots closing, the day ending) are re-evaluated. Data changes re-evaluate on their own.
final habitTickProvider = NotifierProvider<HabitTick, int>(HabitTick.new);

class HabitTick extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Logical today of floating habits (zone + day start).
final habitTodayProvider = Provider<LocalDate>((ref) {
  ref.watch(habitTickProvider);
  final service = ref.watch(habitPeriodServiceProvider);
  return service.boundariesIn(service.currentZone).dateOf(ref.watch(clockProvider).nowUtc());
});

// ------------------------------------------------------------------------------ reactive data --

/// Active (non-archived) habits and quit trackers, ordered.
final habitsProvider = StreamProvider<List<Habit>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(habitsRepositoryProvider).watchAll();
});

/// Every habit including archived ones (manage screen, stats).
final allHabitsProvider = StreamProvider<List<Habit>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(habitsRepositoryProvider).watchAll(includeArchived: true);
});

final habitByIdProvider = StreamProvider.family<Habit?, String>((ref, id) {
  ref.watch(currentUserIdProvider);
  return ref.watch(habitsRepositoryProvider).watchHabit(id);
});

final habitRevisionsProvider = StreamProvider.family<List<HabitRevision>, String>((ref, id) {
  ref.watch(currentUserIdProvider);
  return ref.watch(habitsRepositoryProvider).watchRevisions(id);
});

/// Every live log of one habit.
final habitLogsProvider = StreamProvider.family<List<HabitLogEntry>, String>((ref, id) {
  ref.watch(currentUserIdProvider);
  return ref.watch(habitLogsRepositoryProvider).watchForHabit(id);
});

final habitPausesProvider = StreamProvider<List<PauseSpan>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(habitPausesRepositoryProvider).watchAll();
});

final habitSectionsProvider = StreamProvider<List<HabitSection>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(habitSectionsRepositoryProvider).watchAll();
});

final allHabitSectionsProvider = StreamProvider<List<HabitSection>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(habitSectionsRepositoryProvider).watchAll(includeArchived: true);
});

final habitVocabProvider = StreamProvider<List<VocabEntry>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(habitVocabRepositoryProvider).watchAll();
});

/// Notes & moods across habits, newest first (journal, T5.2.15).
final habitJournalProvider = StreamProvider<List<HabitLogEntry>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(habitLogsRepositoryProvider).watchJournal();
});

/// Global (vacation) pauses covering [date] or later.
final vacationProvider = Provider<PauseSpan?>((ref) {
  final today = ref.watch(habitTodayProvider);
  for (final p in ref.watch(habitPausesProvider).value ?? const <PauseSpan>[]) {
    if (p.isGlobal && (p.end == null || !p.end!.isBefore(today))) return p;
  }
  return null;
});

// ------------------------------------------------------------------------------ snapshots --

/// Everything the UI needs about one habit at one instant: its evaluation and headline stats
/// (build habits) or its quit calculator (quit trackers). Recomputed only when the habit, its
/// revisions, logs, the pauses or the tick change (T5.2.14).
@immutable
class HabitSnapshot {
  const HabitSnapshot({
    required this.habit,
    required this.revisions,
    required this.logs,
    required this.pauses,
    required this.now,
    required this.today,
    required this.boundaries,
    this.evaluation,
    this.summary,
    this.currentPeriod,
    this.quit,
  });

  final Habit habit;
  final List<HabitRevision> revisions;
  final List<HabitLogEntry> logs;
  final List<PauseSpan> pauses;
  final DateTime now;

  /// The habit's own today (zone + day start).
  final LocalDate today;
  final DayBoundaries boundaries;

  /// Build habits.
  final HabitEvaluation? evaluation;
  final HabitSummary? summary;

  /// The period "check now" targets (build habits).
  final HabitPeriod? currentPeriod;

  /// Quit trackers.
  final QuitCalculator? quit;

  /// The same evaluation seen at [instant] (valid only while no period boundary passed — see
  /// [HabitSnapshotCache]).
  HabitSnapshot withNow(DateTime instant) => HabitSnapshot(
    habit: habit,
    revisions: revisions,
    logs: logs,
    pauses: pauses,
    now: instant,
    today: today,
    boundaries: boundaries,
    evaluation: evaluation,
    summary: summary,
    currentPeriod: currentPeriod,
    quit: quit,
  );

  BuildHabit? get build => habit is BuildHabit ? habit as BuildHabit : null;
  QuitHabit? get quitHabit => habit is QuitHabit ? habit as QuitHabit : null;

  /// Today's day result (roll-up for slot habits, day view for quota habits).
  PeriodResult? get todayResult => evaluation?.dayOn(today);

  /// Explicit state log of [key] (null = none).
  HabitLogEntry? stateOf(String key) {
    HabitLogEntry? best;
    for (final l in logs) {
      if (l.occurrenceKey != key || !l.kind.isState) continue;
      if (best == null || l.loggedAt.isAfter(best.loggedAt)) best = l;
    }
    return best;
  }

  /// Entries (progress / state / note) of [key].
  List<HabitLogEntry> entriesOf(String key) => [
    for (final l in logs)
      if (l.occurrenceKey == key && l.kind != HabitLogKind.craving) l,
  ];

  /// Pause covering [date] (habit-level or vacation).
  PauseSpan? pauseOn(LocalDate date) {
    for (final p in pauses) {
      if (p.appliesTo(habit.id) && p.covers(date)) return p;
    }
    return null;
  }
}

/// Snapshot of one habit (see [HabitSnapshot]).
final habitSnapshotProvider = Provider.family<AsyncValue<HabitSnapshot>, String>((ref, id) {
  ref.watch(habitTickProvider);
  final habitAsync = ref.watch(habitByIdProvider(id));
  final revisionsAsync = ref.watch(habitRevisionsProvider(id));
  final logsAsync = ref.watch(habitLogsProvider(id));
  final pausesAsync = ref.watch(habitPausesProvider);
  for (final a in <AsyncValue<Object?>>[habitAsync, revisionsAsync, logsAsync, pausesAsync]) {
    if (a.hasError) return AsyncValue.error(a.error!, a.stackTrace ?? StackTrace.current);
  }
  final habit = habitAsync.value;
  final revisions = revisionsAsync.value;
  final logs = logsAsync.value;
  final pauses = pausesAsync.value;
  if (habit == null || revisions == null || logs == null || pauses == null) {
    if (!habitAsync.isLoading && habitAsync.hasValue && habit == null) {
      return AsyncValue.error(StateError('habit $id not found'), StackTrace.current);
    }
    return const AsyncValue.loading();
  }
  final service = ref.watch(habitPeriodServiceProvider);
  final now = ref.watch(clockProvider).nowUtc();
  return AsyncValue.data(ref.watch(habitSnapshotCacheProvider).snapshot(service, habit, revisions, logs, pauses, now));
});

/// Per-user snapshot memo (T5.2.14).
final habitSnapshotCacheProvider = Provider<HabitSnapshotCache>((ref) {
  ref.watch(currentUserIdProvider);
  return HabitSnapshotCache();
});

class _SnapshotMemo {
  _SnapshotMemo(this.inputs, this.snapshot, this.computedAt, this.validUntil);

  final List<Object?> inputs;
  final HabitSnapshot snapshot;
  final DateTime computedAt;
  final DateTime validUntil;
}

class _PeriodsMemo {
  _PeriodsMemo(this.inputs, this.periods);

  final List<Object?> inputs;
  final List<HabitPeriod> periods;
}

/// Evaluation cache (T5.2.14). A habit's snapshot is reused while its inputs are the very same
/// objects (the repositories' streams are de-duplicated, so identity changes only with real
/// changes) and no period boundary has passed since it was computed: the minute tick and changes
/// to other habits cost nothing. Period expansion is memoized separately because logs and pauses
/// don't change periods, so a check-in only re-evaluates. Quit trackers are always recomputed
/// (their values grow continuously).
class HabitSnapshotCache {
  final _snapshots = <String, _SnapshotMemo>{};
  final _periods = <String, _PeriodsMemo>{};

  /// Full evaluations and period expansions performed (tests, diagnostics).
  int evaluations = 0;
  int periodExpansions = 0;

  static bool _same(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  HabitSnapshot snapshot(
    HabitPeriodService service,
    Habit habit,
    List<HabitRevision> revisions,
    List<HabitLogEntry> logs,
    List<PauseSpan> pauses,
    DateTime now,
  ) {
    if (habit is! BuildHabit) return computeSnapshot(service, habit, revisions, logs, pauses, now);
    final inputs = <Object?>[service, habit, revisions, logs, pauses];
    final memo = _snapshots[habit.id];
    if (memo != null &&
        _same(memo.inputs, inputs) &&
        !now.isBefore(memo.computedAt) &&
        now.isBefore(memo.validUntil)) {
      return memo.snapshot.withNow(now);
    }
    final boundaries = service.boundariesOf(habit);
    final today = boundaries.dateOf(now);
    final lastDay = habit.endDate != null && habit.endDate!.isBefore(today) ? habit.endDate! : today;
    final periodInputs = <Object?>[service, habit, revisions, lastDay];
    var periods = _periods[habit.id];
    if (periods == null || !_same(periods.inputs.sublist(0, 3), periodInputs.sublist(0, 3)) || periods.inputs[3] != lastDay) {
      periodExpansions++;
      periods = _PeriodsMemo(periodInputs, service.periods(habit, revisions, habit.startDate, lastDay));
      _periods[habit.id] = periods;
    }
    evaluations++;
    final snapshot = computeSnapshot(service, habit, revisions, logs, pauses, now, periods: periods.periods);
    _snapshots[habit.id] = _SnapshotMemo(inputs, snapshot, now, _validUntil(snapshot, periods.periods, now));
    return snapshot;
  }

  /// The first instant after [now] at which a result could change with time alone: the end of the
  /// habit's today, or a period window opening, closing or entering its early tolerance.
  static DateTime _validUntil(HabitSnapshot s, List<HabitPeriod> periods, DateTime now) {
    var until = s.boundaries.endOf(s.today);
    void consider(DateTime? t) {
      if (t != null && t.isAfter(now) && t.isBefore(until)) until = t;
    }

    for (final p in periods) {
      consider(p.matchStart);
      consider(p.windowStart);
      consider(p.windowEnd);
    }
    return until;
  }

  /// Forgets everything (account switch, tests).
  void clear() {
    _snapshots.clear();
    _periods.clear();
  }
}

/// Pure snapshot computation (also used by background jobs and tests).
HabitSnapshot computeSnapshot(
  HabitPeriodService service,
  Habit habit,
  List<HabitRevision> revisions,
  List<HabitLogEntry> logs,
  List<PauseSpan> pauses,
  DateTime now, {
  List<HabitPeriod>? periods,
}) {
  final boundaries = service.boundariesOf(habit);
  final today = boundaries.dateOf(now);
  switch (habit) {
    case BuildHabit():
      final lastDay = habit.endDate != null && habit.endDate!.isBefore(today) ? habit.endDate! : today;
      final evaluation = evaluateHabit(
        habit: habit,
        periods: periods ?? service.periods(habit, revisions, habit.startDate, lastDay),
        logs: logs,
        pauses: pauses,
        now: now,
        today: today,
        boundaries: boundaries,
      );
      final segments = service.segments(habit, revisions);
      HabitRules rulesOn(LocalDate d) {
        for (final s in segments.reversed) {
          if (!d.isBefore(s.start)) return s.rules;
        }
        return segments.isEmpty ? HabitRules.on(habit, revisions, d) : segments.first.rules;
      }

      return HabitSnapshot(
        habit: habit,
        revisions: revisions,
        logs: logs,
        pauses: pauses,
        now: now,
        today: today,
        boundaries: boundaries,
        evaluation: evaluation,
        summary: summarizeHabit(evaluation, rulesOn: rulesOn),
        currentPeriod: service.periodForInstant(habit, revisions, now),
      );
    case QuitHabit():
      return HabitSnapshot(
        habit: habit,
        revisions: revisions,
        logs: logs,
        pauses: pauses,
        now: now,
        today: today,
        boundaries: boundaries,
        quit: quitCalculatorOf(habit, revisions: revisions, logs: logs, days: boundaries, now: now),
      );
  }
}
