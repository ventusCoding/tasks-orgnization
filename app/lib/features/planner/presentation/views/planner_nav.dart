import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Navigation used by the planner views (overridden in tests).
abstract interface class PlannerNav {
  /// Occurrence sheet / task detail.
  void openTask(BuildContext context, PlannerItem item);

  void openTaskId(BuildContext context, String id);

  /// Full editor for a new task.
  void newTask(BuildContext context, {LocalDateTime? start, int? duration, bool allDay = false});

  /// Switches the Plan tab to another view (registry entry id or `saved:<id>`).
  void openView(BuildContext context, String viewKey, {LocalDate? date});

  void openInsights(BuildContext context, {LocalDate? from, int days = 7});
}

class GoRouterPlannerNav implements PlannerNav {
  const GoRouterPlannerNav();

  @override
  void openTask(BuildContext context, PlannerItem item) =>
      context.push(AppLinks.task(item.taskId, occurrenceKey: item.occurrenceKey));

  @override
  void openTaskId(BuildContext context, String id) => context.push(AppLinks.task(id));

  @override
  void newTask(BuildContext context, {LocalDateTime? start, int? duration, bool allDay = false}) =>
      context.push(AppLinks.taskNew(start: start?.toIso(), duration: duration, allDay: allDay));

  @override
  void openView(BuildContext context, String viewKey, {LocalDate? date}) {
    final iso = date?.toIso();
    context.go(switch (viewKey) {
      'week_table' => AppLinks.planWeek(date: iso),
      'day_list' => AppLinks.planDay(date: iso),
      _ => AppLinks.planView(viewKey, date: iso),
    });
  }

  @override
  void openInsights(BuildContext context, {LocalDate? from, int days = 7}) =>
      context.push(AppLinks.insightsScope('planner'));
}

final plannerNavProvider = Provider<PlannerNav>((ref) => const GoRouterPlannerNav());
