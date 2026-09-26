import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Target of a "Move to…" (T4.1.15 / T4.2.16).
typedef MoveTarget = ({String checklistId, String? parentId, String title});

/// Picks a target checklist, then a parent in a mini tree (items of the moved subtrees excluded).
Future<MoveTarget?> showMoveToSheet(
  BuildContext context,
  WidgetRef ref, {
  required String sourceChecklistId,
  required List<String> movingIds,
}) async {
  final l = context.l10n;
  final lists = ref.read(boardChecklistsProvider).value ?? const <Checklist>[];
  final target = await showAppSheet<Checklist>(
    context,
    title: l.moveToList,
    builder: (ctx) => ListView(
      shrinkWrap: true,
      children: [
        for (final c in lists)
          ListTile(
            leading: Icon(Icons.checklist, color: c.color == null ? null : Color(c.color!)),
            title: Text(c.title.isEmpty ? l.listsUntitled : c.title),
            selected: c.id == sourceChecklistId,
            onTap: () => Navigator.pop(ctx, c),
          ),
      ],
    ),
  );
  if (target == null || !context.mounted) return null;
  final items = await ref.read(checklistItemsRepositoryProvider).items(target.id);
  final tree = ChecklistTree.build(items);
  final excluded = <String>{};
  if (target.id == sourceChecklistId) {
    for (final id in movingIds) {
      if (tree.contains(id)) excluded.addAll([id, ...tree.descendants(id)]);
    }
  }
  if (!context.mounted) return null;
  final title = target.title.isEmpty ? l.listsUntitled : target.title;
  final parent = await showAppSheet<Object>(
    context,
    title: l.moveChooseParent,
    builder: (ctx) {
      final candidates = [for (final id in tree.order) if (!excluded.contains(id) && TreeOps.canMoveUnder(tree, const [], id)) id];
      return ListView.builder(
        shrinkWrap: true,
        itemCount: candidates.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return ListTile(leading: const Icon(Icons.vertical_align_top), title: Text(l.moveToTop), onTap: () => Navigator.pop(ctx, ''));
          }
          final id = candidates[i - 1];
          final depth = tree.depthOf(id);
          return ListTile(
            dense: true,
            contentPadding: EdgeInsetsDirectional.only(start: Space.lg + 16.0 * (depth > 8 ? 8 : depth), end: Space.lg),
            title: Text(tree[id]!.text.isEmpty ? l.checklistItemHint : tree[id]!.text, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => Navigator.pop(ctx, id),
          );
        },
      );
    },
  );
  if (parent == null) return null;
  final parentId = parent == '' ? null : parent as String;
  return (checklistId: target.id, parentId: parentId, title: title);
}
