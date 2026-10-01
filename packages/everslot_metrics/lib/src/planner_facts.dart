/// Canonical planner facts (T6.3.01): one [PlannerOccurrenceFact] per resolved occurrence. Every
/// planner metric is computed from these facts, never from raw rows.
///
/// Notation ([6.3]): ps/pe = planned start/end instants, Dp = pe − ps; sessions = `time_entries`
/// (fallback: one session [`actual_start_at`, `actual_end_at`]); as = first session start, ae = last
/// session end, Da = Σ session lengths (gaps are pauses); done_at = `completed_at`; g = on-time grace.
library;

import 'package:everslot_metrics/src/habit_period.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:meta/meta.dart';

/// `tasks.tracking_mode`.
enum TrackingMode {
  /// Counts in completion metrics.
  check,

  /// Excluded from completion/adherence, included in planned time, allocation and capacity.
  event,

  /// Completion plus sessions.
  timer;

  bool get countsForCompletion => this != event;
}

/// `task_occurrences.status`.
enum PlannerOccurrenceStatus { scheduled, inProgress, done, skipped, missed, cancelled }

/// Outcome class of an occurrence (PL-T-06).
enum PlannerOutcome {
  doneOnTime,
  doneLate,
  partial,
  skipped,
  missed,
  cancelled,
  pending,
  future,

  /// `event` occurrences that were not explicitly resolved (no completion semantics).
  notTracked;

  bool get isDone => this == doneOnTime || this == doneLate || this == partial;
}

/// One tracked session (`time_entries` row) with its wall-clock values.
@immutable
final class const TimeSessionFact(
  final DateTime start,
  final DateTime end, {
  final LocalDateTime? startLocal,
  final LocalDateTime? endLocal,
  final String? taskId,
  final String? occurrenceKey,
  final String? categoryId,
}) {
  Duration get length => end.isAfter(start) ? end.difference(start) : Duration.zero;

  double get minutes => length.inSeconds / 60;
}

/// A `rescheduled` activity event of one occurrence (series moves are expanded per affected
/// occurrence by the adapter). Task `updated` time-field changes are represented the same way.
@immutable
final class const RescheduleFact(
  final DateTime occurredAt, {
  required final LocalDateTime fromStart,
  required final LocalDateTime toStart,
  final int? fromDurationMinutes,
  final int? toDurationMinutes,
  final bool seriesScope = false,
  final String? source,
}) {
  /// toStart − fromStart in wall-clock minutes.
  int get deltaMinutes => fromStart.minutesUntil(toStart);
}

/// The canonical fact of one occurrence.
@immutable
final class const PlannerOccurrenceFact(
  final String taskId,
  final String occurrenceKey, {
  required final String seriesId,
  required final DateTime taskCreatedAt,
  final bool isRecurring = false,
  final LocalDateTime? plannedStartLocal,
  final int? plannedDurationMinutes,
  final DateTime? plannedStart,
  final DateTime? plannedEnd,
  final bool isAllDay = false,
  final PlannerOccurrenceStatus status = PlannerOccurrenceStatus.scheduled,
  final TrackingMode trackingMode = TrackingMode.check,
  final List<TimeSessionFact> sessions = const [],
  final DateTime? actualStart,
  final DateTime? actualEnd,
  final DateTime? doneAt,
  final DateTime? cancelledAt,
  final String? categoryId,
  final int priority = 0,
  final List<String> tagIds = const [],
  final List<RescheduleFact> moves = const [],
  final String? skipReason,
  final int? rating,
  final String? outcomeNote,
  final int? completionPercent,
  final double? linkedChecklistProgress,
  final bool seriesPaused = false,
  final String? title,
}) {
  /// Planned local date (null when unscheduled).
  LocalDate? get plannedDate => plannedStartLocal?.date;

  /// Planned local end (start + duration).
  LocalDateTime? get plannedEndLocal => plannedStartLocal?.plusMinutes(plannedDurationMinutes ?? 0);

  /// Whether the occurrence has a timed slot (not all-day, scheduled).
  bool get isTimed => !isAllDay && plannedStart != null && plannedEnd != null;

  /// Sessions, falling back to [actualStart]…[actualEnd].
  List<TimeSessionFact> get effectiveSessions {
    if (sessions.isNotEmpty) {
      return [...sessions]..sort((a, b) => a.start.compareTo(b.start));
    }
    if (actualStart != null && actualEnd != null) {
      return [TimeSessionFact(actualStart!, actualEnd!, taskId: taskId, categoryId: categoryId)];
    }
    return const [];
  }

  bool get hasActualTime => effectiveSessions.isNotEmpty;

  /// Da in minutes (null = unknown, never 0).
  double? get actualMinutes {
    final s = effectiveSessions;
    if (s.isEmpty) return null;
    return s.fold<double>(0, (acc, x) => acc + x.minutes);
  }

  /// Dp in minutes (null for all-day or unscheduled occurrences).
  double? get plannedMinutes {
    if (isAllDay) return null;
    if (plannedStart != null && plannedEnd != null) {
      return plannedEnd!.difference(plannedStart!).inSeconds / 60;
    }
    return plannedDurationMinutes?.toDouble();
  }

  /// First planned start (before any move) in wall-clock time.
  LocalDateTime? get firstPlannedStartLocal => moves.isEmpty ? plannedStartLocal : _sortedMoves.first.fromStart;

  List<RescheduleFact> get _sortedMoves => [...moves]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

  /// Moves in chronological order.
  List<RescheduleFact> get sortedMoves => _sortedMoves;
}

/// A wall-clock window within a day (e.g. work hours 09:00–17:00).
@immutable
final class const LocalTimeWindow(final int startMinute, final int endMinute) {
  factory of(LocalTime start, LocalTime end) => LocalTimeWindow(start.minuteOfDay, end.minuteOfDay);

  int get minutes => endMinute > startMinute ? endMinute - startMinute : 0;
}

/// Planner stats settings, read once per batch (T6.3.01).
@immutable
final class const PlannerStatsSettings({
  final Duration grace = const Duration(minutes: 5),
  final Duration missedGrace = Duration.zero,
  final SkipPolicy skipPolicy = SkipPolicy.neutral,
  final int deepWorkMinutes = 60,
  final Map<Weekday, List<LocalTimeWindow>> workHours = const {},
  final Set<String> unavailableCategoryIds = const {},
  final Map<String, int> categoryWeights = const {},
});

/// Default work hours 09:00–17:00 Monday–Friday.
final Map<Weekday, List<LocalTimeWindow>> defaultWorkHours = {
  for (final w in Weekday.values)
    if (!w.isWeekend) w: const [LocalTimeWindow(540, 1020)],
};
