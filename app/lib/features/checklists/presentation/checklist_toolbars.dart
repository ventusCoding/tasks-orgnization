import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/checklist_editor.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/domain/visible_list.dart';
import 'package:everslot/features/checklists/presentation/checklist_header.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// One button of a toolbar.
@immutable
class ToolbarAction {
  const ToolbarAction(this.icon, this.label, this.onPressed);

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
}

/// Soft-keyboard toolbar of edit mode (T4.2.09): indent, outdent, move, status, attach, due,
/// details, line break, undo/redo, hide keyboard. Taps never steal the focused row's focus.
class EditToolbar extends StatelessWidget {
  const EditToolbar({required this.actions, super.key});

  final List<ToolbarAction> actions;

  @override
  Widget build(BuildContext context) => TextFieldTapRegion(
    child: Material(
      elevation: 3,
      color: context.colors.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.xs),
            children: [
              for (final a in actions)
                ExcludeFocus(child: IconButton(tooltip: a.label, icon: Icon(a.icon), onPressed: a.onPressed)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Bulk action bar of selection mode (T4.2.16). Every action is one op group and one undo step.
class SelectionBar extends StatelessWidget {
  const SelectionBar({required this.actions, super.key});

  final List<ToolbarAction> actions;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 3,
    color: context.colors.surfaceContainer,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.xs),
          children: [for (final a in actions) IconButton(tooltip: a.label, icon: Icon(a.icon), onPressed: a.onPressed)],
        ),
      ),
    ),
  );
}

/// Picks one of the six statuses (bulk status change, kanban-free status sheet without an item).
Future<ItemStatus?> pickStatus(BuildContext context) => showAppSheet<ItemStatus>(
  context,
  title: context.l10n.statusSheetTitle,
  builder: (ctx) => SafeArea(
    top: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in ItemStatus.values)
          ListTile(
            leading: Icon(StatusStyle.icon(s), color: StatusStyle.color(ctx, s)),
            title: Text(StatusStyle.label(ctx, s)),
            onTap: () => Navigator.pop(ctx, s),
          ),
        const SizedBox(height: Space.sm),
      ],
    ),
  ),
);

/// "Expand to level N" (Checkvist-style, T4.2.12).
Future<int?> pickExpandLevel(BuildContext context) => showAppSheet<int>(
  context,
  title: context.l10n.checklistExpandAll,
  builder: (ctx) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (var level = 1; level <= 9; level++)
            ActionChip(label: Text(ctx.l10n.checklistExpandToLevel(level)), onPressed: () => Navigator.pop(ctx, level)),
        ],
      ),
    ),
  ),
);

/// Sort-children criterion for the structural sort (T4.2.04).
Future<({ItemSortBy by, bool descending})?> pickChildrenSort(BuildContext context) async {
  var descending = false;
  return showAppSheet<({ItemSortBy by, bool descending})>(
    context,
    title: context.l10n.checklistSortChildren,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final by in ItemSortBy.values.where((b) => b != ItemSortBy.manual))
              ListTile(
                title: Text(ViewBanner.sortLabel(ctx, by)),
                onTap: () => Navigator.pop(ctx, (by: by, descending: descending)),
              ),
            SwitchListTile(
              value: descending,
              title: Text(ctx.l10n.checklistSortDescending),
              onChanged: (v) => setState(() => descending = v),
            ),
          ],
        ),
      ),
    ),
  );
}

/// View-level sort & filter of one checklist (T4.5.11). Stored order is never changed; the
/// state is saved per checklist in `ui_checklist_state` (local).
Future<void> showSortFilterSheet(BuildContext context, {required String checklistId}) => showAppSheet<void>(
  context,
  title: context.l10n.checklistSortFilter,
  builder: (_) => _SortFilterSheet(checklistId: checklistId),
);

class _SortFilterSheet extends ConsumerStatefulWidget {
  const _SortFilterSheet({required this.checklistId});

  final String checklistId;

  @override
  ConsumerState<_SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends ConsumerState<_SortFilterSheet> {
  late final TextEditingController _text = TextEditingController(
    text: ref.read(checklistEditorProvider(widget.checklistId)).filter.text,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(checklistEditorProvider(widget.checklistId));
    final editor = ref.read(checklistEditorProvider(widget.checklistId).notifier);
    final f = state.filter;
    final sort = state.sort;
    Future<void> setFilter(ItemFilter next) => editor.setFilter(next);
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _text,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.checklistFilterText,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => setFilter(f.copyWith(text: v)),
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              for (final s in ItemStatus.values)
                FilterChip(
                  avatar: Icon(StatusStyle.icon(s), size: 18, color: StatusStyle.color(context, s)),
                  label: Text(StatusStyle.label(context, s)),
                  selected: f.statuses.contains(s),
                  onSelected: (v) => setFilter(f.copyWith(statuses: v ? {...f.statuses, s} : ({...f.statuses}..remove(s)))),
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              FilterChip(
                label: Text(l.checklistFilterHasAttachments),
                selected: f.hasAttachments,
                onSelected: (v) => setFilter(f.copyWith(hasAttachments: v)),
              ),
              FilterChip(
                label: Text(l.checklistFilterDueSoon),
                selected: f.dueSoon,
                onSelected: (v) => setFilter(f.copyWith(dueSoon: v)),
              ),
              FilterChip(
                label: Text(l.checklistHideCompleted),
                selected: f.hideCompleted,
                onSelected: (v) => setFilter(f.copyWith(hideCompleted: v)),
              ),
            ],
          ),
          SectionHeader(l.checklistSortFilter, padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.xs)),
          RadioGroup<ItemSortBy>(
            groupValue: sort.by,
            onChanged: (by) {
              if (by != null) editor.setSort(ItemSort(by: by, descending: sort.descending));
            },
            child: Column(
              children: [
                for (final by in ItemSortBy.values)
                  RadioListTile<ItemSortBy>(
                    contentPadding: EdgeInsets.zero,
                    value: by,
                    title: Text(ViewBanner.sortLabel(context, by)),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: sort.descending,
            title: Text(l.checklistSortDescending),
            onChanged: sort.isManual ? null : (v) => editor.setSort(ItemSort(by: sort.by, descending: v)),
          ),
          const SizedBox(height: Space.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () async {
                _text.clear();
                await editor.setFilter(ItemFilter.none);
                await editor.setSort(ItemSort.manual);
              },
              child: Text(l.checklistResetView),
            ),
          ),
        ],
      ),
    );
  }
}
