import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/builtin_templates.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/presentation/checklist_card.dart';
import 'package:everslot/features/checklists/presentation/checklist_navigation.dart';
import 'package:everslot/features/checklists/presentation/lists_board_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Archived cards with the same card widget (T4.1.10).
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lists = ref.watch(archivedChecklistsProvider);
    final summaries = ref.watch(cardSummariesProvider(true)).value ?? const <String, CardSummary>{};
    final thumbs = ref.watch(cardThumbnailsProvider(true)).value ?? const {};
    return Scaffold(
      appBar: AppBar(title: Text(l.listsArchive)),
      body: AsyncValueView<List<Checklist>>(
        value: lists,
        data: (all) => all.isEmpty
            ? EmptyState(icon: Icons.archive_outlined, title: l.listsArchiveEmpty)
            : ListView.separated(
                padding: const EdgeInsets.all(Space.md),
                itemCount: all.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                itemBuilder: (_, i) => ChecklistCard(
                  key: ValueKey(all[i].id),
                  checklist: all[i],
                  summary: summaries[all[i].id] ?? CardSummary.empty,
                  thumbnail: thumbs[all[i].id],
                  onTap: () => openChecklist(context, all[i].id),
                  onMenu: () => showCardMenu(context, ref, all[i]),
                ),
              ),
      ),
    );
  }
}

/// Templates (T4.5.05): my templates + built-in localized ones. In [pickMode] tapping a template
/// creates a new list from it; otherwise my templates open for editing.
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key, this.pickMode = false});

  final bool pickMode;

  Future<void> _useBuiltin(BuildContext context, WidgetRef ref, BuiltinTemplate t) async {
    final parsed = t.parse(context.localeName);
    showInfoSnackBar(context, context.l10n.templatesCreated);
    await createListAndOpen(context, ref, title: parsed.title ?? '', nodes: parsed.nodes);
  }

  Future<void> _useMine(BuildContext context, WidgetRef ref, Checklist t) async {
    final created = await ref
        .read(checklistsRepositoryProvider)
        .duplicate(t.id, title: t.title, resetStatuses: true, fromTemplate: true);
    if (!context.mounted) return;
    showUndoSnackBar(context, ref, message: context.l10n.templatesCreated, record: created.record);
    await openChecklist(context, created.id);
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, Checklist t) async {
    final l = context.l10n;
    final action = await showAppSheet<String>(
      context,
      title: t.title.isEmpty ? l.listsUntitled : t.title,
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.add), title: Text(l.templatesUse), onTap: () => Navigator.pop(ctx, 'use')),
            ListTile(leading: const Icon(Icons.edit_outlined), title: Text(l.templatesEdit), onTap: () => Navigator.pop(ctx, 'edit')),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text(l.templatesRename),
              onTap: () => Navigator.pop(ctx, 'rename'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: ctx.colors.error),
              title: Text(l.listsDelete),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    final repo = ref.read(checklistsRepositoryProvider);
    switch (action) {
      case 'use':
        await _useMine(context, ref, t);
      case 'edit':
        await openChecklist(context, t.id);
      case 'rename':
        final name = await promptText(context, title: l.templatesRename, initial: t.title);
        if (name == null) return;
        final r = await repo.update(t.id, title: name);
        if (context.mounted) showUndoSnackBar(context, ref, message: l.savedSnack, record: r);
      case 'delete':
        final r = await repo.delete(t.id);
        if (context.mounted) showUndoSnackBar(context, ref, message: l.listsDeleted, record: r);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final mine = ref.watch(templatesProvider).value ?? const <Checklist>[];
    final locale = context.localeName;
    return Scaffold(
      appBar: AppBar(title: Text(l.listsTemplates)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxl),
        children: [
          SectionHeader(l.templatesMine),
          if (mine.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
              child: Text(l.templatesEmpty, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
            ),
          for (final t in mine)
            ListTile(
              leading: Icon(Icons.dashboard_customize_outlined, color: t.color == null ? null : Color(t.color!)),
              title: Text(t.title.isEmpty ? l.listsUntitled : t.title),
              onTap: () => pickMode ? _useMine(context, ref, t) : openChecklist(context, t.id),
              trailing: IconButton(
                tooltip: l.listsCardActions,
                icon: const Icon(Icons.more_vert),
                onPressed: () => _menu(context, ref, t),
              ),
            ),
          SectionHeader(l.templatesBuiltin),
          for (final t in BuiltinTemplates.all)
            Builder(
              builder: (context) {
                final parsed = t.parse(locale);
                return ListTile(
                  leading: Icon(IconCatalog.iconFor(t.icon, fallback: Icons.checklist)),
                  title: Text(parsed.title ?? t.code),
                  subtitle: Text(l.importItemsCount(parsed.count)),
                  trailing: TextButton(onPressed: () => _useBuiltin(context, ref, t), child: Text(l.templatesUse)),
                  onTap: () => _useBuiltin(context, ref, t),
                );
              },
            ),
        ],
      ),
    );
  }
}
