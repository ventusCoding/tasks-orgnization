import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/domain/category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Category management (T2.3.01): create, rename, recolor, icon, reorder, archive, delete.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final categories = ref.watch(allCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.categoriesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryEditor(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.categoryNew),
      ),
      body: AsyncValueView<List<Category>>(
        value: categories,
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.label_outline,
              title: l.categoriesEmpty,
              actionLabel: l.categoryNew,
              onAction: () => showCategoryEditor(context, ref),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: items.length,
            onReorderItem: (oldIndex, target) {
              final moving = items[oldIndex];
              final list = [...items]..removeAt(oldIndex);
              final before = target > 0 ? list[target - 1].sortKey : null;
              final after = target < list.length ? list[target].sortKey : null;
              ref.read(categoriesRepositoryProvider).move(moving.id, afterKey: before, beforeKey: after);
            },
            itemBuilder: (context, i) {
              final c = items[i];
              return ListTile(
                key: ValueKey(c.id),
                leading: CircleAvatar(
                  backgroundColor: CategoryColors.background(c.color, Theme.of(context).brightness),
                  child: Icon(
                    IconCatalog.iconFor(c.icon),
                    color: CategoryColors.accent(c.color, Theme.of(context).brightness),
                  ),
                ),
                title: Text(c.name),
                subtitle: c.archived ? Text(l.categoryArchived) : null,
                onTap: () => showCategoryEditor(context, ref, existing: c),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) => _onAction(context, ref, c, action, items),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l.actionEdit)),
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(c.archived ? l.actionRestore : l.actionArchive),
                    ),
                    PopupMenuItem(value: 'delete', child: Text(l.actionDelete)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    Category c,
    String action,
    List<Category> all,
  ) async {
    final repo = ref.read(categoriesRepositoryProvider);
    final l = context.l10n;
    switch (action) {
      case 'edit':
        await showCategoryEditor(context, ref, existing: c);
      case 'archive':
        final record = await repo.setArchived(c.id, archived: !c.archived);
        if (context.mounted) showUndoSnackBar(context, ref, message: l.savedSnack, record: record);
      case 'delete':
        final ok = await confirmDialog(
          context,
          title: l.confirmDeleteTitle(c.name),
          body: l.categoryDeleteBody,
          destructive: true,
          confirmLabel: l.actionDelete,
        );
        if (!ok) return;
        final record = await repo.delete(c.id);
        if (context.mounted) {
          showUndoSnackBar(context, ref, message: l.deletedSnack(c.name), record: record);
        }
    }
  }
}

/// Create/edit sheet for a category. Returns the new/edited category id (null on cancel).
Future<void> showCategoryEditor(BuildContext context, WidgetRef ref, {Category? existing}) =>
    showAppSheet<void>(
      context,
      title: existing == null ? context.l10n.categoryNew : context.l10n.categoryEdit,
      builder: (ctx) => _CategoryEditor(existing: existing),
    );

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({this.existing});

  final Category? existing;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late int _color = widget.existing?.color ?? CategoryPalette.colors.first;
  late String? _icon = widget.existing?.icon ?? 'star';
  late bool _unavailable = widget.existing?.countsAsUnavailable ?? false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(categoriesRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.create(name: _name.text, color: _color, icon: _icon);
      } else {
        await repo.update(
          widget.existing!.id,
          name: _name.text,
          color: _color,
          icon: _icon,
          countsAsUnavailable: _unavailable,
        );
      }
      if (mounted) Navigator.pop(context);
    } on ValidationException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: widget.existing == null,
            maxLength: 60,
            decoration: InputDecoration(labelText: l.categoryName, errorText: _error),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final c = await pickColor(context, selected: _color);
                  if (c != null && c != -1) setState(() => _color = c);
                },
                icon: ColorDot(Color(_color), size: 16),
                label: Text(l.pickerColor),
              ),
              const SizedBox(width: Space.md),
              OutlinedButton.icon(
                onPressed: () async {
                  final i = await pickIcon(context, selected: _icon);
                  if (i != null) setState(() => _icon = i);
                },
                icon: Icon(IconCatalog.iconFor(_icon)),
                label: Text(l.pickerIcon),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _unavailable,
            onChanged: (v) => setState(() => _unavailable = v),
            title: Text(l.categoryUnavailable),
            subtitle: Text(l.categoryUnavailableHint),
          ),
          const SizedBox(height: Space.md),
          FilledButton(onPressed: _save, child: Text(l.actionSave)),
        ],
      ),
    );
  }
}

/// Category picker sheet with inline create. Returns the selected id, '' for "none", null on cancel.
Future<String?> pickCategory(BuildContext context, WidgetRef ref, {String? selectedId}) =>
    showAppSheet<String>(
      context,
      title: context.l10n.categoryPick,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
          return ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(ctx.l10n.categoryNone),
                selected: selectedId == null,
                onTap: () => Navigator.pop(ctx, ''),
              ),
              for (final c in categories)
                ListTile(
                  leading: Icon(
                    IconCatalog.iconFor(c.icon),
                    color: CategoryColors.accent(c.color, Theme.of(ctx).brightness),
                  ),
                  title: Text(c.name),
                  selected: c.id == selectedId,
                  onTap: () => Navigator.pop(ctx, c.id),
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(ctx.l10n.categoryNew),
                onTap: () async {
                  await showCategoryEditor(ctx, ref);
                },
              ),
            ],
          );
        },
      ),
    );
