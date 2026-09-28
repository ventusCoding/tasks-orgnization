import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/settings/application/trash_providers.dart';
import 'package:everslot/features/settings/domain/trash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Trash (T8.3.06): deletions of the last 30 days, newest first, with Restore (the
/// entry and everything deleted with it) and Delete forever; Empty trash in the app bar.
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final entries = ref.watch(trashEntriesProvider);
    final list = entries.value ?? const <TrashEntry>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTrash),
        actions: [
          if (list.isNotEmpty)
            IconButton(
              key: const ValueKey('trash-empty'),
              tooltip: l.settingsTrashEmptyAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _emptyAll(context, ref, list),
            ),
        ],
      ),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: l.syncError),
        data: (list) => list.isEmpty
            ? EmptyState(icon: Icons.delete_outline, title: l.settingsTrashEmptyState, message: l.settingsTrashHint)
            : ListView(
                padding: const EdgeInsetsDirectional.only(bottom: Space.xxl),
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, Space.sm),
                    child: Text(
                      l.settingsTrashHint,
                      style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                  for (final e in list) _TrashTile(entry: e),
                ],
              ),
      ),
    );
  }

  Future<void> _emptyAll(BuildContext context, WidgetRef ref, List<TrashEntry> list) async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.settingsTrashEmptyAll,
      body: l.settingsTrashEmptyAllBody(list.length),
      confirmLabel: l.settingsTrashDeleteForever,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await _guard(context, () => ref.read(trashServiceProvider).emptyTrash(list), done: l.settingsTrashDeleted);
  }
}

/// Runs a trash action and reports the outcome in a snackbar.
Future<void> _guard(BuildContext context, Future<Object?> Function() run, {required String done}) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  String message;
  try {
    await run();
    message = done;
  } on TrashException catch (e) {
    message = switch (e.failure) {
      TrashFailure.offline => l.settingsTrashOffline,
      TrashFailure.notSynced => l.settingsTrashNotSynced,
    };
  } on SyncApiException {
    message = l.syncError;
  }
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _TrashTile extends ConsumerWidget {
  const _TrashTile({required this.entry});

  final TrashEntry entry;

  static IconData icon(TrashKind kind) => switch (kind) {
    TrashKind.task => Icons.event_note_outlined,
    TrashKind.checklist => Icons.checklist,
    TrashKind.checklistItem => Icons.check_box_outlined,
    TrashKind.habit => Icons.local_fire_department_outlined,
    TrashKind.attachment => Icons.attach_file,
  };

  static String kindLabel(BuildContext context, TrashKind kind) {
    final l = context.l10n;
    return switch (kind) {
      TrashKind.task => l.settingsTrashKindTask,
      TrashKind.checklist => l.settingsTrashKindChecklist,
      TrashKind.checklistItem => l.settingsTrashKindItem,
      TrashKind.habit => l.settingsTrashKindHabit,
      TrashKind.attachment => l.settingsTrashKindAttachment,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider).nowUtc();
    final format = AppFormat(Localizations.localeOf(context).toLanguageTag(), l10n: l);
    final title = entry.title.trim().isEmpty ? l.settingsTrashUntitled : entry.title;
    final lines = [
      [kindLabel(context, entry.kind), if (entry.path.isNotEmpty) entry.path.where((p) => p.isNotEmpty).join(' › ')].join(' · '),
      [l.settingsTrashDeletedWhen(format.relative(entry.deletedAt, now)), if (entry.withCount > 0) l.settingsTrashWith(entry.withCount)]
          .join(' · '),
    ];
    return ListTile(
      key: ValueKey('trash-${entry.id}'),
      leading: Icon(icon(entry.kind)),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(lines.join('\n')),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        key: ValueKey('trash-menu-${entry.id}'),
        tooltip: MaterialLocalizations.of(context).showMenuTooltip,
        onSelected: (action) async {
          if (action == 'restore') {
            await _guard(context, () => ref.read(trashServiceProvider).restore(entry), done: l.settingsTrashRestored);
            return;
          }
          final ok = await confirmDialog(
            context,
            title: l.settingsTrashDeleteForeverTitle(title),
            body: l.settingsTrashDeleteForeverBody,
            confirmLabel: l.settingsTrashDeleteForever,
            destructive: true,
          );
          if (ok && context.mounted) {
            await _guard(context, () => ref.read(trashServiceProvider).deleteForever(entry), done: l.settingsTrashDeleted);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            key: const ValueKey('trash-restore'),
            value: 'restore',
            child: ListTile(leading: const Icon(Icons.restore), title: Text(l.settingsTrashRestore)),
          ),
          PopupMenuItem(
            key: const ValueKey('trash-delete'),
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_forever_outlined, color: context.colors.error),
              title: Text(l.settingsTrashDeleteForever, style: TextStyle(color: context.colors.error)),
            ),
          ),
        ],
      ),
    );
  }
}
