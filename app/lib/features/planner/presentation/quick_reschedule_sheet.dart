/// Quick reschedule from an overdue reminder (T7.5.03): *in 1 hour*, *tonight at 20:00* (while still
/// before 19:00) and *tomorrow at the same time*. Opened by the notification's *Reschedule* action
/// (`/task/<id>?occ=…&reschedule=1`); one undoable move through the planner service.
library;

import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The choices offered at [now] (viewer wall clock) for an occurrence starting at [start].
List<(QuickRescheduleKind, LocalDateTime)> quickRescheduleChoices(LocalDateTime now, LocalDateTime start) {
  final minute = now.time.minuteOfDay;
  final rounded = ((minute + 4) ~/ 5) * 5 + 60;
  final inAnHour = now.date.atStartOfDay.plusMinutes(rounded);
  return [
    (QuickRescheduleKind.inAnHour, inAnHour),
    if (minute < 19 * 60) (QuickRescheduleKind.tonight, LocalDateTime(now.date, LocalTime(20, 0))),
    (QuickRescheduleKind.tomorrow, LocalDateTime(now.date.plusDays(1), start.time)),
  ];
}

enum QuickRescheduleKind { inAnHour, tonight, tomorrow }

Future<void> showQuickReschedule(BuildContext context, WidgetRef ref, PlannerItem item) async {
  final l = context.l10n;
  final zone = ref.read(deviceZoneProvider);
  final now = ref.read(zoneResolverProvider).toLocal(ref.read(clockProvider).nowUtc(), zone);
  final format = AppFormat(context.localeName, use24h: ref.read(userPreferencesProvider).use24h, l10n: l);
  final choice = await showModalBottomSheet<LocalDateTime>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
            child: Text(l.tasksQuickRescheduleTitle, style: context.text.titleMedium),
          ),
          for (final (kind, at) in quickRescheduleChoices(now, item.startLocal))
            ListTile(
              key: ValueKey('quick-reschedule-${kind.name}'),
              leading: Icon(switch (kind) {
                QuickRescheduleKind.inAnHour => Icons.schedule,
                QuickRescheduleKind.tonight => Icons.nights_stay_outlined,
                QuickRescheduleKind.tomorrow => Icons.event_outlined,
              }),
              title: Text(switch (kind) {
                QuickRescheduleKind.inAnHour => l.tasksQuickRescheduleHour(format.time(at.time)),
                QuickRescheduleKind.tonight => l.tasksQuickRescheduleTonight(format.time(at.time)),
                QuickRescheduleKind.tomorrow => l.tasksQuickRescheduleTomorrow(format.time(at.time)),
              }),
              onTap: () => Navigator.of(context).pop(at),
            ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final undo = ref.read(undoStackProvider);
  await ref.read(plannerServiceProvider).reschedule(item, newStart: choice, source: 'notification');
  messenger?.showSnackBar(
    SnackBar(
      content: Text(l.tasksQuickRescheduled),
      action: SnackBarAction(label: l.actionUndo, onPressed: () => unawaited(undo.undo())),
    ),
  );
}

/// Opens the quick-reschedule sheet once, as soon as the occurrence is loaded.
class QuickRescheduleOnOpen extends ConsumerStatefulWidget {
  const QuickRescheduleOnOpen({required this.item, super.key});

  final PlannerItem? item;

  @override
  ConsumerState<QuickRescheduleOnOpen> createState() => _QuickRescheduleOnOpenState();
}

class _QuickRescheduleOnOpenState extends ConsumerState<QuickRescheduleOnOpen> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (!_shown && item != null) {
      _shown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(showQuickReschedule(context, ref, item));
      });
    }
    return const SizedBox.shrink();
  }
}
