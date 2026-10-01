import 'dart:async';

import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/domain/tag.dart';
import 'package:everslot/features/organization/presentation/tag_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Tag management (T2.3.10): create, rename, recolor, reorder, merge two tags, delete.
class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tags = ref.watch(tagsProvider);
    final usage = ref.watch(tagUsageCountsProvider).value ?? const <String, int>{};
    return Scaffold(
      appBar: AppBar(title: Text(l.tagsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTagEditor(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.tagNew),
      ),
      body: AsyncValueView<List<Tag>>(
        value: tags,
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.sell_outlined,
              title: l.tagsEmpty,
              message: l.tagsEmptyHint,
              actionLabel: l.tagNew,
              onAction: () => showTagEditor(context, ref),
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
              unawaited(ref.read(tagsRepositoryProvider).move(moving.id, afterKey: before, beforeKey: after));
            },
            itemBuilder: (context, i) {
              final tag = items[i];
              final count = usage[tag.id] ?? 0;
              return ListTile(
                key: ValueKey(tag.id),
                leading: CircleAvatar(
                  backgroundColor: tag.color == null
                      ? context.colors.surfaceContainerHighest
                      : CategoryColors.background(tag.color!, Theme.of(context).brightness),
                  child: Icon(Icons.sell_outlined, color: tagColor(context, tag)),
                ),
                title: Text(tag.name),
                subtitle: Text(l.tagUsage(count)),
                onTap: () => showTagEditor(context, ref, existing: tag),
                trailing: PopupMenuButton<String>(
                  tooltip: l.actionMore,
                  onSelected: (action) => _onAction(context, ref, tag, action, items, count),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l.actionEdit)),
                    if (items.length > 1) PopupMenuItem(value: 'merge', child: Text(l.tagMerge)),
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

  Future<void> _onAction(BuildContext context, WidgetRef ref, Tag tag, String action, List<Tag> all, int usage) async {
    final repo = ref.read(tagsRepositoryProvider);
    final l = context.l10n;
    switch (action) {
      case 'edit':
        await showTagEditor(context, ref, existing: tag);
      case 'merge':
        final target = await _pickMergeTarget(context, tag, all);
        if (target == null || !context.mounted) return;
        final ok = await confirmDialog(
          context,
          title: l.tagMergeConfirmTitle,
          body: l.tagMergeConfirmBody(tag.name, target.name),
          confirmLabel: l.tagMergeAction,
        );
        if (!ok) return;
        final record = await repo.merge(sourceId: tag.id, targetId: target.id);
        if (context.mounted) {
          showUndoSnackBar(context, ref, message: l.tagMergedSnack(target.name), record: record);
        }
      case 'delete':
        final ok = await confirmDialog(
          context,
          title: l.confirmDeleteTitle(tag.name),
          body: l.tagDeleteBody(usage),
          destructive: true,
          confirmLabel: l.actionDelete,
        );
        if (!ok) return;
        final record = await repo.delete(tag.id);
        if (context.mounted) {
          showUndoSnackBar(context, ref, message: l.deletedSnack(tag.name), record: record);
        }
    }
  }

  Future<Tag?> _pickMergeTarget(BuildContext context, Tag source, List<Tag> all) => showAppSheet<Tag>(
    context,
    title: context.l10n.tagMergeTitle(source.name),
    builder: (ctx) => ListView(
      shrinkWrap: true,
      children: [
        for (final t in all)
          if (t.id != source.id)
            ListTile(
              leading: ColorDot(tagColor(ctx, t), size: 14),
              title: Text(t.name),
              onTap: () => Navigator.pop(ctx, t),
            ),
      ],
    ),
  );
}

/// Create/edit sheet for a tag (name + color).
Future<void> showTagEditor(BuildContext context, WidgetRef ref, {Tag? existing}) => showAppSheet<void>(
  context,
  title: existing == null ? context.l10n.tagNew : context.l10n.tagEdit,
  builder: (ctx) => _TagEditor(existing: existing),
);

class _TagEditor extends ConsumerStatefulWidget {
  const _TagEditor({this.existing});

  final Tag? existing;

  @override
  ConsumerState<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends ConsumerState<_TagEditor> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late int? _color = widget.existing?.color;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(tagsRepositoryProvider);
    final existing = widget.existing;
    try {
      if (existing == null) {
        await repo.create(name: _name.text, color: _color);
      } else {
        await repo.update(existing.id, name: _name.text, color: _color, clearColor: _color == null);
      }
      if (mounted) Navigator.pop(context);
    } on ValidationException catch (e) {
      if (mounted) setState(() => _error = tagErrorText(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = _color;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, 0, Space.xl, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: widget.existing == null,
            maxLength: TagNames.maxLength,
            decoration: InputDecoration(labelText: l.tagName, errorText: _error),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: Space.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () async {
                final c = await pickColor(context, selected: color, allowNone: true);
                if (c != null) setState(() => _color = c == -1 ? null : c);
              },
              icon: color == null ? const Icon(Icons.format_color_reset_outlined) : ColorDot(Color(color), size: 16),
              label: Text(color == null ? l.tagNoColor : l.pickerColor),
            ),
          ),
          const SizedBox(height: Space.lg),
          FilledButton(onPressed: _save, child: Text(l.actionSave)),
        ],
      ),
    );
  }
}
