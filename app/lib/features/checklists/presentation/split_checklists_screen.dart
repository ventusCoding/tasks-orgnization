import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_pane_scope.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Two checklists side by side on tablets and in landscape, as in Workflowy panes (T4.5.17). Both
/// panes are fully editable; dragging a row into the other pane moves it (with its subtree) to
/// the end of that list, undoably.
class SplitChecklistsScreen extends ConsumerStatefulWidget {
  const SplitChecklistsScreen({required this.leftId, required this.rightId, super.key});

  final String leftId;
  final String rightId;

  @override
  ConsumerState<SplitChecklistsScreen> createState() => _SplitChecklistsScreenState();
}

class _SplitChecklistsScreenState extends ConsumerState<SplitChecklistsScreen> {
  final _panes = [GlobalKey(debugLabel: 'pane-start'), GlobalKey(debugLabel: 'pane-end')];

  List<String> get _ids => [widget.leftId, widget.rightId];

  Future<bool> _dropOutside(String sourceId, String itemId, Offset global) async {
    for (var i = 0; i < _panes.length; i++) {
      final box = _panes[i].currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !(box.localToGlobal(Offset.zero) & box.size).contains(global)) {
        continue;
      }
      final targetId = _ids[i];
      if (targetId == sourceId) return false;
      final target = ref.read(checklistTreeProvider(targetId));
      final roots = target?.childIds(null) ?? const <String>[];
      final afterKey = roots.isEmpty ? null : target![roots.last]!.sortKey;
      final result = await ref
          .read(checklistServiceProvider)
          .run(
            sourceId,
            (src, ctx, _) => TreeOps.moveToChecklist(
              src,
              ctx,
              [itemId],
              targetChecklistId: targetId,
              targetParentId: null,
              afterKey: afterKey,
            ),
          );
      // Shown in the pane the item landed in (each pane has its own messenger).
      final paneContext = _panes[i].currentContext;
      if (result != null && mounted && paneContext != null && paneContext.mounted) {
        final l = context.l10n;
        announce(context, l.checklistItemsMoved);
        showUndoSnackBar(paneContext, ref, message: l.checklistItemsMoved, record: result.record);
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => ChecklistPaneScope(
    onDropOutside: _dropOutside,
    child: Material(
      child: Row(
        children: [
          // Each pane keeps its own snack bars.
          Expanded(
            child: ScaffoldMessenger(
              child: KeyedSubtree(
                key: _panes[0],
                child: ChecklistScreen(checklistId: widget.leftId),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: ScaffoldMessenger(
              child: KeyedSubtree(
                key: _panes[1],
                child: ChecklistScreen(checklistId: widget.rightId),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
