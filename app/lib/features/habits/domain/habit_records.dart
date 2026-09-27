import 'package:decimal/decimal.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot_metrics/everslot_metrics.dart' as m;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

export 'package:everslot_metrics/everslot_metrics.dart' show HabitLogKind;

const Object _unset = Object();

/// `habit_logs.source`.
abstract final class LogSource {
  static const manual = 'manual';
  static const notification = 'notification';
  static const widget = 'widget';
  static const auto = 'auto';
  static const import = 'import';
}

/// One `habit_logs` row: check-ins, progress entries, relapses, cravings, pledges…
@immutable
class HabitLogEntry {
  const HabitLogEntry({
    required this.id,
    required this.habitId,
    required this.kind,
    required this.loggedAt,
    required this.localDate,
    this.occurrenceKey,
    this.value,
    this.mood,
    this.intensity,
    this.resisted,
    this.trigger,
    this.place,
    this.coping,
    this.durationSeconds,
    this.note,
    this.source = LogSource.manual,
    this.createdAt,
  });

  final String id;
  final String habitId;

  /// Day (`YYYY-MM-DD`) or slot (`YYYY-MM-DDTHH:mm`) key — never a quota period key.
  final String? occurrenceKey;
  final m.HabitLogKind kind;
  final double? value;

  /// Event time (instant).
  final DateTime loggedAt;

  /// Local (habit) date of the period, computed once at write time.
  final LocalDate localDate;
  final int? mood;
  final int? intensity;
  final bool? resisted;

  /// `habit_vocab` id or free text.
  final String? trigger;
  final String? place;
  final String? coping;
  final int? durationSeconds;
  final String? note;
  final String source;

  /// Real write time (differs from [loggedAt] for backfilled entries).
  final DateTime? createdAt;

  bool get isStateLog => kind.isState;

  m.HabitLog toMetrics() => m.HabitLog(
    id,
    kind,
    loggedAt: loggedAt,
    localDate: localDate,
    value: value,
    occurrenceKey: occurrenceKey,
    createdAt: createdAt,
    source: source,
    mood: mood,
    durationSeconds: durationSeconds,
    note: note,
  );

  m.QuitLog toQuitLog() => m.QuitLog(
    id,
    kind,
    loggedAt: loggedAt,
    localDate: localDate,
    value: value,
    intensity: intensity,
    trigger: trigger,
    place: place,
    coping: coping,
    mood: mood,
    resisted: resisted,
    durationSeconds: durationSeconds,
    note: note,
  );

  HabitLogEntry copyWith({
    Object? value = _unset,
    DateTime? loggedAt,
    Object? mood = _unset,
    Object? note = _unset,
    m.HabitLogKind? kind,
  }) => HabitLogEntry(
    id: id,
    habitId: habitId,
    kind: kind ?? this.kind,
    loggedAt: loggedAt ?? this.loggedAt,
    localDate: localDate,
    occurrenceKey: occurrenceKey,
    value: identical(value, _unset) ? this.value : (value as num?)?.toDouble(),
    mood: identical(mood, _unset) ? this.mood : mood as int?,
    intensity: intensity,
    resisted: resisted,
    trigger: trigger,
    place: place,
    coping: coping,
    durationSeconds: durationSeconds,
    note: identical(note, _unset) ? this.note : note as String?,
    source: source,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is HabitLogEntry &&
      other.id == id &&
      other.habitId == habitId &&
      other.occurrenceKey == occurrenceKey &&
      other.kind == kind &&
      other.value == value &&
      other.loggedAt == loggedAt &&
      other.localDate == localDate &&
      other.mood == mood &&
      other.intensity == intensity &&
      other.resisted == resisted &&
      other.trigger == trigger &&
      other.place == place &&
      other.coping == coping &&
      other.durationSeconds == durationSeconds &&
      other.note == note &&
      other.source == source &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    habitId,
    occurrenceKey,
    kind,
    value,
    loggedAt,
    localDate,
    mood,
    intensity,
    resisted,
    trigger,
    place,
    coping,
    durationSeconds,
    note,
    source,
    createdAt,
  );

  @override
  String toString() => 'HabitLogEntry($kind $occurrenceKey $value @ $loggedAt)';
}

/// `habit_pauses` row: one habit or — when [habitId] is null — all habits (vacation mode).
@immutable
class PauseSpan {
  const PauseSpan({required this.id, required this.start, this.habitId, this.end, this.reason});

  final String id;
  final String? habitId;
  final LocalDate start;

  /// Inclusive; null = open-ended.
  final LocalDate? end;
  final String? reason;

  bool get isGlobal => habitId == null;

  bool covers(LocalDate date) => !date.isBefore(start) && (end == null || !date.isAfter(end!));

  /// Whether the pause applies to [habit] (its own pauses and global ones).
  bool appliesTo(String habitId) => this.habitId == null || this.habitId == habitId;

  m.HabitPause toMetrics() => m.HabitPause(start, end: end, habitId: habitId, reason: reason);

  @override
  bool operator ==(Object other) =>
      other is PauseSpan &&
      other.id == id &&
      other.habitId == habitId &&
      other.start == start &&
      other.end == end &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(id, habitId, start, end, reason);
}

/// `habit_revisions` row: the schedule, goal and quit economics in force from [effectiveFrom] so
/// past periods keep the rules they had (arch §6.11). Revisions are full snapshots.
@immutable
class HabitRevision {
  const HabitRevision({
    required this.id,
    required this.habitId,
    required this.effectiveFrom,
    this.schedule,
    this.goalType,
    this.targetValue,
    this.targetOp,
    this.unit,
    this.baselinePerDay,
    this.unitCost,
    this.dailyLimit,
  });

  final String id;
  final String habitId;
  final LocalDate effectiveFrom;
  final RecurrenceRule? schedule;
  final HabitGoalType? goalType;
  final double? targetValue;
  final TargetOp? targetOp;
  final String? unit;
  final double? baselinePerDay;
  final Decimal? unitCost;
  final double? dailyLimit;

  /// Latest revision with `effective_from ≤ date`, or null (→ the habit's current values).
  static HabitRevision? effectiveFor(Iterable<HabitRevision> revisions, LocalDate date) =>
      m.effectiveOn(revisions, date, (r) => r.effectiveFrom);

  HabitTarget? goalOr(HabitTarget fallback) {
    if (goalType == null) return null;
    return HabitTarget(type: goalType!, target: targetValue, op: targetOp ?? fallback.op, unit: unit);
  }

  m.QuitRevision toQuitRevision() => m.QuitRevision(
    effectiveFrom,
    baselinePerDay: baselinePerDay,
    unitCost: unitCost,
    dailyLimit: dailyLimit,
  );

  @override
  bool operator ==(Object other) =>
      other is HabitRevision &&
      other.id == id &&
      other.habitId == habitId &&
      other.effectiveFrom == effectiveFrom &&
      other.schedule == schedule &&
      other.goalType == goalType &&
      other.targetValue == targetValue &&
      other.targetOp == targetOp &&
      other.unit == unit &&
      other.baselinePerDay == baselinePerDay &&
      other.unitCost == unitCost &&
      other.dailyLimit == dailyLimit;

  @override
  int get hashCode => Object.hash(
    id,
    habitId,
    effectiveFrom,
    schedule,
    goalType,
    targetValue,
    targetOp,
    unit,
    baselinePerDay,
    unitCost,
    dailyLimit,
  );
}

/// Rules of a build habit in force on one date (revision-aware).
@immutable
class HabitRules {
  const HabitRules({required this.schedule, required this.goal, required this.anchorDate, this.revisionId});

  final RecurrenceRule schedule;
  final HabitTarget goal;

  /// Anchor of the schedule ("every N days" counts from here): the revision's effective date.
  final LocalDate anchorDate;
  final String? revisionId;

  /// Resolves the rules of [habit] on [date].
  static HabitRules on(BuildHabit habit, List<HabitRevision> revisions, LocalDate date) {
    final r = HabitRevision.effectiveFor(revisions, date);
    if (r == null) {
      return HabitRules(schedule: habit.schedule, goal: habit.goal, anchorDate: habit.startDate);
    }
    final anchor = r.effectiveFrom.isBefore(habit.startDate) ? habit.startDate : r.effectiveFrom;
    return HabitRules(
      schedule: r.schedule ?? habit.schedule,
      goal: r.goalOr(habit.goal) ?? habit.goal,
      anchorDate: anchor,
      revisionId: r.id,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HabitRules &&
      other.schedule == schedule &&
      other.goal == goal &&
      other.anchorDate == anchorDate &&
      other.revisionId == revisionId;

  @override
  int get hashCode => Object.hash(schedule, goal, anchorDate, revisionId);
}

/// User-defined time-of-day group (`habit_sections`).
@immutable
class HabitSection {
  const HabitSection({
    required this.id,
    required this.name,
    required this.sortKey,
    this.icon,
    this.startTime,
    this.endTime,
    this.archived = false,
    this.defaultKey,
  });

  final String id;
  final String name;
  final String? icon;
  final String sortKey;
  final LocalTime? startTime;
  final LocalTime? endTime;
  final bool archived;

  /// `morning` | `afternoon` | `evening` | `anytime` for seeded defaults.
  final String? defaultKey;

  bool get hasWindow => startTime != null && endTime != null;

  /// Whether [time] falls in the section's window (windows may cross midnight).
  bool containsTime(LocalTime time) {
    final s = startTime;
    final e = endTime;
    if (s == null || e == null) return false;
    final t = time.minuteOfDay;
    if (s.minuteOfDay <= e.minuteOfDay) return t >= s.minuteOfDay && t < e.minuteOfDay;
    return t >= s.minuteOfDay || t < e.minuteOfDay;
  }

  @override
  bool operator ==(Object other) =>
      other is HabitSection &&
      other.id == id &&
      other.name == name &&
      other.icon == icon &&
      other.sortKey == sortKey &&
      other.startTime == startTime &&
      other.endTime == endTime &&
      other.archived == archived &&
      other.defaultKey == defaultKey;

  @override
  int get hashCode => Object.hash(id, name, icon, sortKey, startTime, endTime, archived, defaultKey);
}

/// Default sections seeded per user (T5.1.11).
abstract final class DefaultSections {
  static const morning = 'morning';
  static const afternoon = 'afternoon';
  static const evening = 'evening';
  static const anytime = 'anytime';

  /// (key, icon, start, end).
  static final List<(String, String, LocalTime?, LocalTime?)> all = [
    (morning, 'sun', LocalTime(4, 0), LocalTime(12, 0)),
    (afternoon, 'calendar', LocalTime(12, 0), LocalTime(18, 0)),
    (evening, 'moon', LocalTime(18, 0), LocalTime(23, 59)),
    (anytime, 'star', null, null),
  ];
}

/// A local-only duration timer of a period (T5.2.04, `habit_timer_state` — never synced). The
/// running state is derived from instants, so it survives app kills without drift.
@immutable
class HabitTimer {
  const HabitTimer({
    required this.habitId,
    required this.key,
    required this.startedAt,
    this.accumulatedSeconds = 0,
    this.running = true,
  });

  final String habitId;

  /// Day or slot key.
  final String key;

  /// Start of the current running segment (or of the pause).
  final DateTime startedAt;

  /// Seconds accumulated before the current running segment.
  final int accumulatedSeconds;
  final bool running;

  int elapsedSeconds(DateTime now) {
    if (!running) return accumulatedSeconds;
    final segment = now.toUtc().difference(startedAt.toUtc()).inSeconds;
    return accumulatedSeconds + (segment < 0 ? 0 : segment);
  }

  @override
  bool operator ==(Object other) =>
      other is HabitTimer &&
      other.habitId == habitId &&
      other.key == key &&
      other.startedAt == startedAt &&
      other.accumulatedSeconds == accumulatedSeconds &&
      other.running == running;

  @override
  int get hashCode => Object.hash(habitId, key, startedAt, accumulatedSeconds, running);
}

/// `habit_vocab.kind`.
enum VocabKind {
  trigger,
  place,
  coping,
  distraction;

  static VocabKind parse(String? value) =>
      VocabKind.values.firstWhere((k) => k.name == value, orElse: () => VocabKind.trigger);
}

/// A reusable trigger / place / coping strategy / distraction (T5.3.14).
@immutable
class VocabEntry {
  const VocabEntry({
    required this.id,
    required this.kind,
    required this.name,
    required this.sortKey,
    this.icon,
    this.color,
    this.archived = false,
  });

  final String id;
  final VocabKind kind;
  final String name;
  final String? icon;
  final int? color;
  final String sortKey;
  final bool archived;

  @override
  bool operator ==(Object other) =>
      other is VocabEntry &&
      other.id == id &&
      other.kind == kind &&
      other.name == name &&
      other.icon == icon &&
      other.color == color &&
      other.sortKey == sortKey &&
      other.archived == archived;

  @override
  int get hashCode => Object.hash(id, kind, name, icon, color, sortKey, archived);
}

/// Default vocabularies (keys → localized names at seeding time).
abstract final class DefaultVocab {
  static const triggers = [
    'stress',
    'coffee',
    'alcohol',
    'after_meals',
    'social',
    'boredom',
    'driving',
    'work_break',
    'phone',
    'waking_up',
  ];
  static const places = ['home', 'work', 'car', 'bar', 'outside', 'friends'];
  static const coping = ['breathing', 'walk', 'water', 'gum', 'call_friend', 'delay_10'];
  static const distractions = ['music', 'game', 'read', 'exercise', 'snack', 'shower'];

  static List<String> keysFor(VocabKind kind) => switch (kind) {
    VocabKind.trigger => triggers,
    VocabKind.place => places,
    VocabKind.coping => coping,
    VocabKind.distraction => distractions,
  };
}
