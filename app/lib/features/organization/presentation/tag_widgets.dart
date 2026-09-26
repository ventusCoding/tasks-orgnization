import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/domain/tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Display color of a tag (neutral outline when it has no color).
Color tagColor(BuildContext context, Tag tag) => tag.color == null
    ? context.colors.outline
    : CategoryColors.accent(tag.color!, Theme.of(context).brightness);

/// Compact tag chip: color dot + name (color is never the only signal).
class TagChip extends StatelessWidget {
  const TagChip({
    required this.tag,
    super.key,
    this.onTap,
    this.onDeleted,
    this.selected,
  });

  final Tag tag;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

  /// Non-null renders a selectable chip.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final avatar = ColorDot(tagColor(context, tag), size: 10);
    final label = Text(tag.name, overflow: TextOverflow.ellipsis);
    if (onTap == null && onDeleted == null && selected == null) {
      return Semantics(
        label: l.tagChipSemantics(tag.name),
        excludeSemantics: true,
        child: Chip(
          avatar: avatar,
          label: label,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }
    // Interactive chips keep the standard density: ≥ 48 dp targets for the chip and its delete
    // button (T1.3.15).
    return InputChip(
      avatar: avatar,
      label: label,
      selected: selected ?? false,
      showCheckmark: false,
      onPressed: onTap,
      onDeleted: onDeleted,
      deleteButtonTooltipMessage: l.tagRemoveSemantics(tag.name),
      tooltip: l.tagChipSemantics(tag.name),
    );
  }
}

/// Live tag chips of one entity; with [editable] the user can add (picker) and remove tags.
class EntityTagChips extends ConsumerWidget {
  const EntityTagChips({
    required this.entityType,
    required this.entityId,
    super.key,
    this.editable = false,
  });

  final String entityType;
  final String entityId;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final key = (type: entityType, id: entityId);
    final tags = ref.watch(entityTagsProvider(key)).value ?? const <Tag>[];
    if (tags.isEmpty && !editable) return const SizedBox.shrink();
    final repo = ref.read(tagsRepositoryProvider);
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final tag in tags)
          TagChip(
            tag: tag,
            onDeleted: editable
                ? () async {
                    final record = await repo.detach(
                      tag.id,
                      entityType,
                      entityId,
                    );
                    if (context.mounted) {
                      showUndoSnackBar(
                        context,
                        ref,
                        message: l.tagsUpdatedSnack,
                        record: record,
                      );
                    }
                  }
                : null,
          ),
        if (editable)
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: Text(l.tagAdd),
            onPressed: () async {
              final picked = await pickTags(
                context,
                ref,
                selected: {for (final t in tags) t.id},
              );
              if (picked == null) return;
              final record = await repo.setTags(entityType, entityId, picked);
              if (context.mounted && !record.isEmpty) {
                showUndoSnackBar(
                  context,
                  ref,
                  message: l.tagsUpdatedSnack,
                  record: record,
                );
              }
            },
          ),
      ],
    );
  }
}

/// Localized message of a tag validation error.
String tagErrorText(BuildContext context, Object error) {
  final l = context.l10n;
  if (error is ValidationException) {
    return switch (error.message) {
      TagNames.errorDuplicate => l.tagErrorDuplicate,
      TagNames.errorInvalid => l.tagErrorInvalid,
      _ => ErrorState.messageFor(context, error),
    };
  }
  return ErrorState.messageFor(context, error);
}

/// Multi-select tag picker with search and inline create (T2.3.10). Returns the selected tag ids,
/// or null when dismissed.
Future<Set<String>?> pickTags(
  BuildContext context,
  WidgetRef ref, {
  Set<String> selected = const {},
}) => showAppSheet<Set<String>>(
  context,
  title: context.l10n.tagPickerTitle,
  builder: (ctx) => _TagPicker(initial: selected),
);

class _TagPicker extends ConsumerStatefulWidget {
  const _TagPicker({required this.initial});

  final Set<String> initial;

  @override
  ConsumerState<_TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends ConsumerState<_TagPicker> {
  late final Set<String> _selected = {...widget.initial};
  final _query = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _create(String name) async {
    try {
      final created = await ref.read(tagsRepositoryProvider).create(name: name);
      setState(() {
        _selected.add(created.id);
        _query.clear();
        _error = null;
      });
    } on ValidationException catch (e) {
      if (mounted) setState(() => _error = tagErrorText(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    final query = TagNames.normalize(_query.text);
    final key = query.toLowerCase();
    final visible = [
      for (final t in tags)
        if (key.isEmpty || t.name.toLowerCase().contains(key)) t,
    ];
    final exact = tags.any((t) => TagNames.key(t.name) == key);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        Space.lg,
        0,
        Space.lg,
        Space.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _query,
            autofocus: tags.isEmpty,
            maxLength: TagNames.maxLength,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.tagPickerSearch,
              errorText: _error,
              counterText: '',
            ),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) {
              if (query.isNotEmpty && !exact) _create(query);
            },
          ),
          const SizedBox(height: Space.sm),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                if (query.isNotEmpty && !exact)
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: Text(l.tagCreateNamed(query)),
                    onTap: () => _create(query),
                  ),
                for (final t in visible)
                  CheckboxListTile(
                    value: _selected.contains(t.id),
                    secondary: ColorDot(tagColor(context, t), size: 14),
                    title: Text(t.name),
                    onChanged: (v) => setState(() {
                      if (v ?? false) {
                        _selected.add(t.id);
                      } else {
                        _selected.remove(t.id);
                      }
                    }),
                  ),
                if (visible.isEmpty && query.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Text(
                      l.tagsEmpty,
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          FilledButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: Text(l.actionDone),
          ),
        ],
      ),
    );
  }
}
