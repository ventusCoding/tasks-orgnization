import 'package:meta/meta.dart';

/// One running timer as the lock screen needs it.
@immutable
class RunningTimerInfo {
  const RunningTimerInfo({
    required this.taskId,
    required this.occurrenceKey,
    required this.title,
    required this.startedAt,
    this.plannedEnd,
  });

  final String taskId;
  final String occurrenceKey;
  final String title;

  /// Start of the running session (UTC): the chronometer counts from here.
  final DateTime startedAt;

  /// End of the planned occurrence (UTC), when it has one.
  final DateTime? plannedEnd;
}

/// What the running-timer surface shows (T8.2.10): the Android ongoing notification and the iOS
/// Live Activity. The most recently started timer leads; others are counted.
@immutable
class TimerSurface {
  const TimerSurface({
    required this.taskId,
    required this.occurrenceKey,
    required this.title,
    required this.startedAt,
    this.plannedEnd,
    this.others = 0,
  });

  final String taskId;
  final String occurrenceKey;
  final String title;
  final DateTime startedAt;
  final DateTime? plannedEnd;

  /// Other timers running at the same time.
  final int others;

  /// Null when nothing runs.
  static TimerSurface? of(List<RunningTimerInfo> running) {
    if (running.isEmpty) return null;
    final lead = running.reduce((a, b) => b.startedAt.isAfter(a.startedAt) ? b : a);
    return TimerSurface(
      taskId: lead.taskId,
      occurrenceKey: lead.occurrenceKey,
      title: lead.title,
      startedAt: lead.startedAt,
      plannedEnd: lead.plannedEnd,
      others: running.length - 1,
    );
  }

  /// Past the planned end at [now].
  bool isOver(DateTime now) => plannedEnd != null && !now.isBefore(plannedEnd!);

  /// Stable notification id / activity id of the surface.
  static const notificationId = 0x7E7E5107;
  static const activityId = 'everslot-timer';

  /// Payload key (the action dispatcher routes Stop / Done to the planner handler).
  String get dedupeKey => 'timer|$taskId|$occurrenceKey';

  @override
  bool operator ==(Object other) =>
      other is TimerSurface &&
      other.taskId == taskId &&
      other.occurrenceKey == occurrenceKey &&
      other.title == title &&
      other.startedAt == startedAt &&
      other.plannedEnd == plannedEnd &&
      other.others == others;

  @override
  int get hashCode => Object.hash(taskId, occurrenceKey, title, startedAt, plannedEnd, others);
}
