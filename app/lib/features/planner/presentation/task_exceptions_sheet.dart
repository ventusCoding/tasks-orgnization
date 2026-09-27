import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/recurrence_ui/recurrence_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Exceptions of a task series (T2.1.19): cancelled, moved and edited occurrences plus the
/// rule's excluded dates.
List<RecurrenceExceptionEntry> taskExceptions(Task task, List<TaskOccurrenceRecord> records) => [
  for (final r in records)
    if (r.isCancelled)
      RecurrenceExceptionEntry(key: r.occurrenceKey, kind: RecurrenceExceptionKind.cancelled, title: r.overrideTitle)
    else if (r.isMoved)
      RecurrenceExceptionEntry(
        key: r.occurrenceKey,
        kind: RecurrenceExceptionKind.moved,
        movedTo: r.overrideStartLocal,
        title: r.overrideTitle,
      )
    else if (r.hasOverride)
      RecurrenceExceptionEntry(key: r.occurrenceKey, kind: RecurrenceExceptionKind.edited, title: r.overrideTitle),
  for (final key in task.recurrence?.exdates ?? const <String>[])
    RecurrenceExceptionEntry(key: key, kind: RecurrenceExceptionKind.excluded),
];

/// Opens the exceptions manager of [taskId] (*Restore* / *Open* per entry, *Restore all*).
Future<void> showTaskExceptionsSheet(BuildContext context, {required String taskId}) => showAppSheet<void>(
  context,
  title: context.l10n.recurExceptionsTitle,
  builder: (_) => _TaskExceptions(taskId: taskId),
);

class _TaskExceptions extends ConsumerWidget {
  const _TaskExceptions({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(taskByIdProvider(taskId)).value;
    final records = ref.watch(taskRecordsProvider(taskId)).value ?? const <TaskOccurrenceRecord>[];
    if (task == null) return const SizedBox(height: 120, child: LoadingState());
    final service = ref.read(plannerServiceProvider);
    final entries = taskExceptions(task, records);
    return RecurrenceExceptionsView(
      shrinkWrap: true,
      exceptions: entries,
      onRestore: (e) async {
        if (e.kind == RecurrenceExceptionKind.excluded) {
          await service.removeExdate(taskId, e.key);
        } else {
          await service.restoreToSeries(taskId, e.key);
        }
      },
      onRestoreAll: () => service.restoreAllExceptions(taskId),
      onOpen: (e) {
        final router = GoRouter.of(context);
        Navigator.of(context).pop();
        router.push(AppLinks.task(taskId, occurrenceKey: e.key));
      },
    );
  }
}
