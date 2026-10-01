import 'dart:math' as math;

import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

// Eisenhower matrix (T3.7.09) — pure classification and the field changes of a drag.

/// Quadrants: important × urgent.
enum Quadrant {
  doNow(important: true, urgent: true),
  schedule(important: true, urgent: false),
  delegate(important: false, urgent: true),
  eliminate(important: false, urgent: false);

  Quadrant({required this.important, required this.urgent});

  final bool important;
  final bool urgent;

  static Quadrant of({required bool important, required bool urgent}) =>
      values.firstWhere((q) => q.important == important && q.urgent == urgent);
}

/// Editable rules (`options.importanceThreshold`, `options.urgencyDays`).
@immutable
class MatrixRules {
  const MatrixRules({this.importanceThreshold = 3, this.urgencyDays = 2});

  /// Priority from which an item is important (1–4).
  final int importanceThreshold;

  /// An item is urgent when its deadline (or, when scheduled, its start) falls within this many
  /// days from today (overdue deadlines are urgent too).
  final int urgencyDays;

  @override
  bool operator ==(Object other) =>
      other is MatrixRules && other.importanceThreshold == importanceThreshold && other.urgencyDays == urgencyDays;

  @override
  int get hashCode => Object.hash(importanceThreshold, urgencyDays);
}

bool isImportant(PlannerItem i, MatrixRules r) => i.priority >= r.importanceThreshold;

bool isUrgent(PlannerItem i, MatrixRules r, LocalDate today) {
  final limit = today.plusDays(r.urgencyDays);
  final deadline = i.deadlineLocal;
  if (deadline != null && !deadline.date.isAfter(limit)) return true;
  return !i.isBacklog && !i.startLocal.date.isAfter(limit);
}

Quadrant quadrantOf(PlannerItem i, MatrixRules r, LocalDate today) =>
    Quadrant.of(important: isImportant(i, r), urgent: isUrgent(i, r, today));

/// Field changes moving [i] into [to]: a priority (null = unchanged) and a deadline change.
@immutable
class MatrixMove {
  const MatrixMove({this.priority, this.deadline, this.clearDeadline = false});

  final int? priority;
  final LocalDateTime? deadline;
  final bool clearDeadline;

  bool get isEmpty => priority == null && deadline == null && !clearDeadline;
}

/// Becoming important raises the priority to the threshold; unimportant lowers it below; becoming
/// urgent sets the deadline to the end of the urgency window; not urgent clears a deadline that
/// made it urgent (a scheduled start inside the window still counts).
MatrixMove matrixMove(PlannerItem i, Quadrant to, MatrixRules r, LocalDate today) {
  final from = quadrantOf(i, r, today);
  int? priority;
  if (to.important != from.important) {
    priority = to.important
        ? math.max(i.priority, r.importanceThreshold)
        : math.min(i.priority, r.importanceThreshold - 1);
  }
  if (to.urgent == from.urgent) return MatrixMove(priority: priority);
  if (to.urgent) {
    return MatrixMove(priority: priority, deadline: today.plusDays(r.urgencyDays).atTime(LocalTime(23, 59)));
  }
  return MatrixMove(priority: priority, clearDeadline: i.deadlineLocal != null);
}
