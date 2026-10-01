import 'dart:async';

import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/shared/links/application/linked_entity_providers.dart';
import 'package:everslot/shared/status/presentation/entity_status_style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// A link to another entity (task ↔ checklist, item → task…) with its live title and status
/// (T2.3.12). Tapping opens it through [AppLinks.forEntity]; a deleted target shows as disabled.
class LinkedEntityChip extends ConsumerWidget {
  const LinkedEntityChip({
    required this.entityType,
    required this.entityId,
    super.key,
    this.occurrenceKey,
    this.onOpen,
  });

  final String entityType;
  final String entityId;
  final String? occurrenceKey;

  /// Replaces the default navigation (`push` of the entity location).
  final void Function(String location)? onOpen;

  /// Statuses that need no badge (the "normal" state of each kind).
  static const _quiet = {'active', 'todo', 'scheduled'};
  static const _finished = {'completed', 'done', 'cancelled'};

  static IconData kindIcon(String entityType) => switch (entityType) {
    'task' => Icons.event_available,
    'checklist' => Icons.checklist,
    'checklist_item' => Icons.check_box_outlined,
    'habit' => Icons.local_fire_department_outlined,
    'habit_log' => Icons.sticky_note_2_outlined,
    _ => Icons.link,
  };

  static String kindLabel(BuildContext context, String entityType) {
    final l = context.l10n;
    return switch (entityType) {
      'task' => l.linkKindTask,
      'checklist' => l.linkKindChecklist,
      'checklist_item' => l.linkKindChecklistItem,
      'habit' => l.linkKindHabit,
      'habit_log' => l.linkKindHabitLog,
      _ => entityType,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final entity = ref.watch(linkedEntityProvider((type: entityType, id: entityId))).value;
    final kind = kindLabel(context, entityType);
    if (entity == null) {
      return Chip(
        avatar: Icon(kindIcon(entityType), size: 18),
        label: const SizedBox(width: Space.xl),
      );
    }
    if (entity.missing) {
      return Semantics(
        label: '$kind: ${l.linkedEntityMissing}',
        excludeSemantics: true,
        child: ActionChip(
          avatar: Icon(Icons.link_off, size: 18, color: context.colors.onSurfaceVariant),
          label: Text(l.linkedEntityMissing),
          onPressed: null,
        ),
      );
    }
    final title = entity.title.trim().isEmpty ? l.linkedEntityUntitled : entity.title.trim();
    final status = entity.status;
    final finished = _finished.contains(status);
    final location = AppLinks.forEntity(entityType, entityId, parentId: entity.parentId, occurrenceKey: occurrenceKey);
    void open() {
      if (location == null) return;
      final handler = onOpen;
      if (handler != null) {
        handler(location);
      } else {
        unawaited(GoRouter.maybeOf(context)?.push<void>(location));
      }
    }

    return Semantics(
      label: l.linkedEntitySemantics(kind, title, status == null ? '' : EntityStatusStyle.label(context, status)),
      button: location != null,
      excludeSemantics: true,
      child: ActionChip(
        avatar: Icon(kindIcon(entityType), size: 18),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: finished ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
              ),
            ),
            if (status != null && !_quiet.contains(status)) ...[
              const SizedBox(width: Space.xs),
              Icon(EntityStatusStyle.icon(status), size: 16, color: EntityStatusStyle.color(context, status)),
            ],
          ],
        ),
        onPressed: location == null ? null : open,
      ),
    );
  }
}
