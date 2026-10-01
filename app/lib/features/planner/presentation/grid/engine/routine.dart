import 'dart:math' as math;

import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:meta/meta.dart';

// Routine player (T3.7.07) — pure: step durations, consecutive task blocks and the step state
// machine (start, tick, pause / resume, complete, skip, auto-advance, finish).

/// Durations of steps with [estimates] (minutes; null = unknown) inside [totalMinutes]: known
/// estimates are kept, the remaining time is shared equally by the others (at least 1 minute each).
List<int> stepDurations(List<int?> estimates, int totalMinutes) {
  final known = estimates.whereType<int>().fold<int>(0, (a, b) => a + b);
  final unknown = estimates.where((e) => e == null).length;
  final share = unknown == 0 ? 0 : math.max(1, ((totalMinutes - known) / unknown).floor());
  return [for (final e in estimates) e ?? share];
}

/// The block of consecutive items starting with [first] in [items] (same day, open, timed): each
/// next item starts at most [gapMinutes] after the previous one ends ("Morning block").
List<PlannerItem> consecutiveBlock(PlannerItem first, Iterable<PlannerItem> items, {int gapMinutes = 5}) {
  final sorted = [
    for (final i in items)
      if (!i.allDay && !i.isBacklog && i.startLocal.date == first.startLocal.date) i,
  ]..sort((a, b) => a.startLocal.compareTo(b.startLocal));
  final start = sorted.indexWhere((i) => i.key == first.key);
  if (start < 0) return [first];
  final block = [sorted[start]];
  for (var k = start + 1; k < sorted.length; k++) {
    final gap = block.last.endLocal.minutesUntil(sorted[k].startLocal);
    if (gap < 0 || gap > gapMinutes) {
      if (gap < 0) continue; // overlapping item: not part of the sequence
      break;
    }
    block.add(sorted[k]);
  }
  return block;
}

/// What happened to a step.
enum StepOutcome { pending, done, skipped }

/// One routine step: an id (checklist item id or occurrence key), a title and its planned length.
@immutable
class RoutineStep {
  const RoutineStep({required this.id, required this.title, required this.minutes});

  final String id;
  final String title;
  final int minutes;

  Duration get duration => Duration(minutes: minutes);
}

/// Player state: current step, time spent in it, running flag and the outcome of every step.
@immutable
class RoutineState {
  RoutineState({
    required this.steps,
    this.index = 0,
    this.elapsed = Duration.zero,
    this.running = false,
    this.started = false,
    List<StepOutcome>? outcomes,
  }) : outcomes = List.unmodifiable(outcomes ?? List.filled(steps.length, StepOutcome.pending));

  final List<RoutineStep> steps;
  final int index;
  final Duration elapsed;
  final bool running;
  final bool started;

  /// Outcome of every step.
  final List<StepOutcome> outcomes;

  bool get finished => index >= steps.length;
  RoutineStep? get current => finished ? null : steps[index];

  /// Time left in the current step (negative when over).
  Duration get remaining => (current?.duration ?? Duration.zero) - elapsed;

  int get doneCount => outcomes.where((o) => o == StepOutcome.done).length;

  RoutineState _copy({int? index, Duration? elapsed, bool? running, bool? started, List<StepOutcome>? outcomes}) =>
      RoutineState(
        steps: steps,
        index: index ?? this.index,
        elapsed: elapsed ?? this.elapsed,
        running: running ?? this.running,
        started: started ?? this.started,
        outcomes: outcomes ?? this.outcomes,
      );
}

/// Transitions of [RoutineState] (all pure).
abstract final class RoutineMachine {
  static RoutineState start(RoutineState s) => s.finished ? s : s._copy(running: true, started: true);

  static RoutineState pause(RoutineState s) => s._copy(running: false);

  static RoutineState resume(RoutineState s) => s.finished ? s : s._copy(running: true);

  /// Advances the clock by [dt] while running; with [autoAdvance] a step whose time is up
  /// completes and the next one starts with the leftover time.
  static RoutineState tick(RoutineState s, Duration dt, {required bool autoAdvance}) {
    if (!s.running || s.finished) return s;
    var next = s._copy(elapsed: s.elapsed + dt);
    while (autoAdvance && !next.finished && next.remaining <= Duration.zero) {
      final over = -next.remaining;
      next = _advance(next, StepOutcome.done)._copy(elapsed: over);
    }
    return next;
  }

  static RoutineState complete(RoutineState s) => s.finished ? s : _advance(s, StepOutcome.done);

  static RoutineState skip(RoutineState s) => s.finished ? s : _advance(s, StepOutcome.skipped);

  static RoutineState _advance(RoutineState s, StepOutcome outcome) {
    final outcomes = [...s.outcomes]..[s.index] = outcome;
    final index = s.index + 1;
    return s._copy(
      index: index,
      elapsed: Duration.zero,
      outcomes: outcomes,
      running: index < s.steps.length && s.running,
    );
  }
}
