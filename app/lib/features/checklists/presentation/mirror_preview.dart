import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Under a mirror row (T4.5.16): where the original lives and its children, live. Tapping a
/// child toggles it (edits the original); [onOpenOriginal] jumps to the original.
class MirrorPreview extends ConsumerWidget {
  const MirrorPreview({
    required this.checklistId,
    required this.item,
    required this.onToggle,
    required this.onOpenOriginal,
    super.key,
  });

  final String checklistId;
  final ChecklistItem item;
  final ValueChanged<ChecklistItem> onToggle;
  final VoidCallback onOpenOriginal;

  static const maxLines = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sources = ref.watch(mirrorSourcesProvider(checklistId)).value ?? ChecklistTree.empty;
    final original = sources[item.mirrorOfId!];
    final lists = ref.watch(boardChecklistsProvider).value ?? const <Checklist>[];
    final listTitle = original == null ? null : lists.where((c) => c.id == original.checklistId).firstOrNull?.title;
    final lines = <(ChecklistItem, int)>[];
    void walk(String id, int depth) {
      for (final child in sources.childIds(id)) {
        if (lines.length > maxLines) return;
        lines.add((sources[child]!, depth));
        walk(child, depth + 1);
      }
    }

    if (original != null) walk(original.id, 0);
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: l.checklistOpenOriginal,
          child: InkWell(
            key: ValueKey('mirror-origin-${item.id}'),
            onTap: onOpenOriginal,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flip_to_front, size: 14, color: context.colors.primary),
                  const SizedBox(width: Space.xs),
                  Flexible(
                    child: Text(
                      listTitle == null || listTitle.isEmpty ? l.checklistMirror : l.checklistMirrorOf(listTitle),
                      style: muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (final (child, depth) in lines.take(maxLines))
          InkWell(
            key: ValueKey('mirror-child-${child.id}'),
            onTap: () => onToggle(child),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: 14.0 * depth),
                child: Row(
                  children: [
                    Icon(StatusStyle.icon(child.status), size: 16, color: StatusStyle.color(context, child.status)),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Text(
                        child.text.isEmpty ? l.checklistItemHint : child.text,
                        style: muted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (lines.length > maxLines) Text(l.checklistMirrorMore, style: muted),
      ],
    );
  }
}
