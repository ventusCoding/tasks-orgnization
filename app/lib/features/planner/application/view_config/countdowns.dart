import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// One countdown row (T3.7.12): "N days until X" or "N days since X".
@immutable
class CountdownEntry {
  const CountdownEntry({required this.task, required this.mode, required this.target, required this.targetLocal});

  final Task task;
  final CountdownMode mode;

  /// The instant counted to (until) or from (since).
  final DateTime target;

  /// [target] on the viewer's wall clock (day counts, labels).
  final LocalDateTime targetLocal;

  @override
  bool operator ==(Object other) =>
      other is CountdownEntry && other.task == task && other.mode == mode && other.target == target;

  @override
  int get hashCode => Object.hash(task, mode, target);
}

/// Whole calendar days from [from] to [to] (negative when [to] is earlier); DST-proof.
int calendarDaysBetween(LocalDate from, LocalDate to) => from.daysUntil(to);

/// Target of a countdown task at [nowUtc]: until → its deadline, else its next occurrence (or a
/// one-off start); since → its last occurrence before now (or a one-off start). Null when there is
/// nothing to count (unscheduled without a deadline, a finished series…).
DateTime? countdownTarget(Task task, RecurrenceService service, {required DateTime nowUtc, required String zone}) {
  final resolver = service.resolver;
  final mode = task.countdownMode;
  if (mode == null) return null;
  DateTime resolve(LocalDateTime t) => resolver.resolve(t, task.timeZone ?? zone).utc;
  final deadline = task.deadlineLocal;
  if (mode == CountdownMode.until && deadline != null) return resolve(deadline);
  final anchor = task.anchor;
  if (anchor == null) return null;
  final rule = task.recurrence;
  if (rule == null) return resolve(anchor.start);
  try {
    final occ = mode == CountdownMode.until
        ? service.nextAfter(rule, anchor, instant: nowUtc, inclusive: true)
        : service.previousBefore(rule, anchor, instant: nowUtc, inclusive: true);
    return occ?.startUtc;
  } on Object {
    return null;
  }
}

/// Countdown rows sorted by target (until: soonest first; since: most recent first).
final countdownEntriesProvider = StreamProvider.autoDispose<List<CountdownEntry>>((ref) {
  final service = ref.watch(recurrenceServiceProvider);
  final zone = ref.watch(deviceZoneProvider);
  final now = ref.read(clockProvider).nowUtc();
  return ref.watch(plannerServiceProvider).queries.watchCountdownTasks().map((tasks) {
    final out = <CountdownEntry>[];
    for (final t in tasks) {
      final target = countdownTarget(t, service, nowUtc: now, zone: zone);
      if (target == null) continue;
      out.add(
        CountdownEntry(
          task: t,
          mode: t.countdownMode!,
          target: target,
          targetLocal: service.resolver.toLocal(target, zone),
        ),
      );
    }
    out.sort((a, b) => a.mode != b.mode ? a.mode.index.compareTo(b.mode.index) : a.target.compareTo(b.target));
    return out;
  });
});
