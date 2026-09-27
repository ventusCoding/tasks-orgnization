import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/presentation/planner_dialogs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Task templates (T3.1.20): pick one to start a new task from it, or delete templates.
/// Returns the picked template, or null.
Future<Task?> showTemplatesSheet(BuildContext context) => showAppSheet<Task>(
  context,
  title: context.l10n.tasksTemplatesTitle,
  builder: (_) => const _TemplatesList(),
);

class _TemplatesList extends ConsumerWidget {
  const _TemplatesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final templates = ref.watch(templatesProvider).value ?? const <Task>[];
    if (templates.isEmpty) {
      return EmptyState(
        key: const ValueKey('templates-empty'),
        title: l.tasksTemplatesTitle,
        message: l.tasksTemplatesEmpty,
        icon: Icons.content_copy_outlined,
      );
    }
    final format = AppFormat(context.localeName, l10n: l);
    return ListView(
      shrinkWrap: true,
      children: [
        for (final t in templates)
          ListTile(
            key: ValueKey('template-${t.id}'),
            leading: Icon(IconCatalog.iconFor(t.icon, fallback: Icons.task_alt)),
            title: Text(t.title),
            subtitle: t.isAllDay || t.durationMinutes == null ? null : Text(format.duration(t.durationMinutes!)),
            onTap: () => Navigator.pop(context, t),
            trailing: IconButton(
              tooltip: l.tasksTemplateDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ref.read(plannerServiceProvider).deleteTemplate(t.id);
                if (context.mounted) showPlannerUndoSnack(context, ref, l.tasksDeleted);
              },
            ),
          ),
        const SizedBox(height: Space.md),
      ],
    );
  }
}
