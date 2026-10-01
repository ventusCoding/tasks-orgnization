import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/move_conflicts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// App-wide listener for checklist move conflicts (T4.1.05), installed in `MaterialApp.builder`:
/// the rejected move's undo entry becomes a no-op marker and a non-blocking snack bar explains it.
/// The local rows already show the server state.
class MoveConflictNotices extends ConsumerWidget {
  const MoveConflictNotices({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<SyncRejection>>(checklistMoveConflictsProvider, (_, next) {
      final rejection = next.value;
      if (rejection == null || next.isLoading) return;
      final l = context.l10n;
      ref.read(undoStackProvider).neutralize(rejection.opId, l.listsMoveConflictedUndo);
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(key: const Key('move-conflict-notice'), content: Text(l.listsMoveConflicted)));
    });
    return child;
  }
}
