import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/domain/category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Localized message of a category validation error.
String categoryErrorText(BuildContext context, Object error) {
  final l = context.l10n;
  if (error is ValidationException) {
    return switch (error.message) {
      CategoryNames.errorDuplicate => l.categoryErrorDuplicate,
      CategoryNames.errorInvalid => l.categoryErrorInvalid,
      _ => ErrorState.messageFor(context, error),
    };
  }
  return ErrorState.messageFor(context, error);
}

/// Category management (T2.3.01): create, rename, recolor, icon, reorder, archive, delete with a
/// reassignment prompt.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final categories = ref.watch(allCategoriesProvider);
    final usage = ref.watch(categoryUsageCountsProvider).value ?? const {};
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
              ref
                  .read(categoriesRepositoryProvider)
                  .move(moving.id, afterKey: before, beforeKey: after);
            },
            itemBuilder: (context, i) {
              final c = items[i];
              final count = usage[c.id] ?? 0;
              final brightness = Theme.of(context).brightness;
              return ListTile(
                key: ValueKey(c.id),
                leading: CircleAvatar(
                  backgroundColor: CategoryColors.background(
                    c.color,
                    brightness,
                  ),
                  child: Icon(
                    IconCatalog.iconFor(c.icon),
                    color: CategoryColors.accent(c.color, brightness),
                  ),
                ),
                title: Text(c.name),
                subtitle: Text(
                  c.archived
                      ? '${l.categoryArchived} · ${l.categoryUsage(count)}'
                      : l.categoryUsage(count),
                ),
                onTap: () => showCategoryEditor(context, ref, existing: c),
                trailing: PopupMenuButton<String>(
                  tooltip: l.actionMore,
                  onSelected: (action) => _onAction(context, ref, c, action),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l.actionEdit)),
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(
                        c.archived ? l.actionRestore : l.actionArchive,
                      ),
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
  ) async {
    final repo = ref.read(categoriesRepositoryProvider);
    final l = context.l10n;
    switch (action) {
      case 'edit':
        await showCategoryEditor(context, ref, existing: c);
      case 'archive':
        final record = await repo.setArchived(c.id, archived: !c.archived);
        if (context.mounted) {
          showUndoSnackBar(context, ref, message: l.savedSnack, record: record);
        }
      case 'delete':
        await deleteCategoryFlow(context, ref, c);
    }
  }
}

enum _DeleteChoice { reassign, clear }

/// Deletes [category] after asking what happens to the items using it: move them to another
/// category or remove the category from them (one undoable operation).
Future<void> deleteCategoryFlow(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  final l = context.l10n;
  final repo = ref.read(categoriesRepositoryProvider);
  final count = await repo.usageCount(category.id);
  if (!context.mounted) return;
  String? reassignTo;
  if (count == 0) {
    final ok = await confirmDialog(
      context,
      title: l.confirmDeleteTitle(category.name),
      body: l.confirmDeleteBody,
      destructive: true,
      confirmLabel: l.actionDelete,
    );
    if (!ok) return;
  } else {
    final choice = await showDialog<_DeleteChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.confirmDeleteTitle(category.name)),
        content: Text(ctx.l10n.categoryDeleteUsedBody(count, category.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _DeleteChoice.clear),
            child: Text(ctx.l10n.categoryClearAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _DeleteChoice.reassign),
            child: Text(ctx.l10n.categoryReassignAction),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == _DeleteChoice.reassign) {
      final target = await pickCategory(
        context,
        ref,
        title: l.categoryReassignTitle,
        exclude: {category.id},
        allowNone: false,
      );
      if (target == null || target.isEmpty || !context.mounted) return;
      reassignTo = target;
    }
  }
  final record = await repo.delete(category.id, reassignTo: reassignTo);
  if (context.mounted) {
    showUndoSnackBar(
      context,
      ref,
      message: l.deletedSnack(category.name),
      record: record,
    );
  }
}

/// Create/edit sheet for a category.
Future<void> showCategoryEditor(
  BuildContext context,
  WidgetRef ref, {
  Category? existing,
  String? initialName,
}) => showAppSheet<void>(
  context,
  title: existing == null
      ? context.l10n.categoryNew
      : context.l10n.categoryEdit,
  builder: (ctx) =>
      _CategoryEditor(existing: existing, initialName: initialName),
);

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({this.existing, this.initialName});

  final Category? existing;
  final String? initialName;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late final _name = TextEditingController(
    text: widget.existing?.name ?? widget.initialName,
  );
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
      if (mounted) setState(() => _error = categoryErrorText(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        Space.xl,
        0,
        Space.xl,
        Space.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: widget.existing == null,
            maxLength: CategoryNames.maxLength,
            decoration: InputDecoration(
              labelText: l.categoryName,
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.md,
            runSpacing: Space.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final c = await pickColor(context, selected: _color);
                  if (c != null && c != -1) setState(() => _color = c);
                },
                icon: ColorDot(Color(_color), size: 16),
                label: Text(l.pickerColor),
              ),
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

/// Category picker sheet with search and inline create (T2.3.01). Returns the selected id, `''`
/// for "No category" (when [allowNone]), or null when dismissed. Archived categories are hidden.
Future<String?> pickCategory(
  BuildContext context,
  WidgetRef ref, {
  String? selectedId,
  String? title,
  Set<String> exclude = const {},
  bool allowNone = true,
}) => showAppSheet<String>(
  context,
  title: title ?? context.l10n.categoryPick,
  builder: (ctx) => _CategoryPicker(
    selectedId: selectedId,
    exclude: exclude,
    allowNone: allowNone,
  ),
);

class _CategoryPicker extends ConsumerStatefulWidget {
  const _CategoryPicker({
    required this.selectedId,
    required this.exclude,
    required this.allowNone,
  });

  final String? selectedId;
  final Set<String> exclude;
  final bool allowNone;

  @override
  ConsumerState<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<_CategoryPicker> {
  final _query = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _create(String name, int colorIndex) async {
    try {
      final created = await ref
          .read(categoriesRepositoryProvider)
          .add(
            name: name,
            color: CategoryPalette.at(colorIndex),
            icon: 'label',
          );
      if (mounted) Navigator.pop(context, created.id);
    } on ValidationException catch (e) {
      if (mounted) setState(() => _error = categoryErrorText(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final all = ref.watch(categoriesProvider).value ?? const <Category>[];
    final query = CategoryNames.normalize(_query.text);
    final key = query.toLowerCase();
    final visible = [
      for (final c in all)
        if (!widget.exclude.contains(c.id) &&
            (key.isEmpty || c.name.toLowerCase().contains(key)))
          c,
    ];
    final exact = all.any((c) => CategoryNames.key(c.name) == key);
    final brightness = Theme.of(context).brightness;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
          child: TextField(
            controller: _query,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.categorySearch,
              errorText: _error,
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (widget.allowNone && key.isEmpty)
                ListTile(
                  leading: const Icon(Icons.block),
                  title: Text(l.categoryNone),
                  selected: widget.selectedId == null,
                  onTap: () => Navigator.pop(context, ''),
                ),
              for (final c in visible)
                ListTile(
                  leading: Icon(
                    IconCatalog.iconFor(c.icon),
                    color: CategoryColors.accent(c.color, brightness),
                  ),
                  title: Text(c.name),
                  selected: c.id == widget.selectedId,
                  onTap: () => Navigator.pop(context, c.id),
                ),
              if (query.isNotEmpty && !exact)
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(l.categoryCreateNamed(query)),
                  onTap: () => _create(query, all.length),
                )
              else if (query.isEmpty)
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(l.categoryNew),
                  onTap: () => showCategoryEditor(context, ref),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
