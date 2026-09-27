import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/presentation/planner_dialogs.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Day-level bulk occurrence actions (T3.2.23).
enum DayAction { markRemainingDone, skipRest, moveToTomorrow }

/// Runs [action] on [day] (viewer wall clock) as one undoable operation and shows the result.
Future<int> runDayAction(BuildContext context, WidgetRef ref, LocalDate day, DayAction action) async {
  final l = context.l10n;
  final service = ref.read(plannerServiceProvider);
  final count = switch (action) {
    DayAction.markRemainingDone => await service.markRemainingDone(day),
    DayAction.skipRest => await service.skipRestOfDay(day),
    DayAction.moveToTomorrow => await service.moveUnfinishedToTomorrow(day),
  };
  if (!context.mounted) return count;
  final message = switch (action) {
    DayAction.markRemainingDone => l.tasksDayDoneAllSnack(count),
    DayAction.skipRest => l.tasksDaySkipRestSnack(count),
    DayAction.moveToTomorrow => l.tasksDayMoveTomorrowSnack(count),
  };
  if (count == 0) {
    showInfoSnackBar(context, message);
  } else {
    showPlannerUndoSnack(context, ref, message);
  }
  return count;
}

/// "⋮" menu of a day header (day list, week table): the three day actions.
class DayActionsMenuButton extends ConsumerWidget {
  const DayActionsMenuButton({required this.day, super.key});

  final LocalDate day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return PopupMenuButton<DayAction>(
      key: ValueKey('day-actions-${day.toIso()}'),
      icon: const Icon(Icons.more_vert),
      onSelected: (a) => unawaited(runDayAction(context, ref, day, a)),
      itemBuilder: (_) => [
        PopupMenuItem(value: DayAction.markRemainingDone, child: Text(l.tasksDayDoneAll)),
        PopupMenuItem(value: DayAction.skipRest, child: Text(l.tasksDaySkipRest)),
        PopupMenuItem(value: DayAction.moveToTomorrow, child: Text(l.tasksDayMoveTomorrow)),
      ],
    );
  }
}
