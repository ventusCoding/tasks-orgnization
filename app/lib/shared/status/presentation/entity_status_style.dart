import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/shared/filters/presentation/filter_bar.dart';
import 'package:material_ui/material_ui.dart';

/// Labels, icons and colors of every entity status value (arch §7.3): checklist items
/// (`todo` … `cancelled`), task occurrences (`scheduled` … `missed`) and lifecycle states of
/// tasks/habits/checklists (`active`, `paused`, `archived`). Color is never the only signal:
/// every status has an icon and a label.
abstract final class EntityStatusStyle {
  static const itemStatuses = ['todo', 'ongoing', 'waiting', 'blocked', 'completed', 'cancelled'];
  static const occurrenceStatuses = ['scheduled', 'in_progress', 'done', 'skipped', 'missed', 'cancelled'];
  static const lifecycleStatuses = ['active', 'paused', 'archived'];

  /// Localized label; unknown values are shown as-is.
  static String label(BuildContext context, String status) {
    final l = context.l10n;
    return switch (status) {
      'todo' => l.entityStatusTodo,
      'ongoing' => l.entityStatusOngoing,
      'waiting' => l.entityStatusWaiting,
      'blocked' => l.entityStatusBlocked,
      'completed' => l.entityStatusCompleted,
      'cancelled' => l.entityStatusCancelled,
      'scheduled' => l.entityStatusScheduled,
      'in_progress' => l.entityStatusInProgress,
      'done' => l.entityStatusDone,
      'skipped' => l.entityStatusSkipped,
      'missed' => l.entityStatusMissed,
      'active' => l.entityStatusActive,
      'paused' => l.entityStatusPaused,
      'archived' => l.entityStatusArchived,
      _ => status,
    };
  }

  static IconData icon(String status) => switch (status) {
    'todo' || 'scheduled' => Icons.radio_button_unchecked,
    'ongoing' || 'in_progress' => Icons.play_circle_outline,
    'waiting' => Icons.hourglass_empty,
    'blocked' => Icons.block,
    'completed' || 'done' => Icons.check_circle_outline,
    'cancelled' => Icons.cancel_outlined,
    'skipped' => Icons.redo,
    'missed' => Icons.error_outline,
    'active' => Icons.circle_outlined,
    'paused' => Icons.pause_circle_outline,
    'archived' => Icons.archive_outlined,
    _ => Icons.help_outline,
  };

  /// Status color token (theme-aware).
  static Color color(BuildContext context, String status) {
    final c = context.appColors;
    return switch (status) {
      'todo' || 'scheduled' => c.todo,
      'ongoing' || 'in_progress' => c.ongoing,
      'waiting' => c.waiting,
      'blocked' => c.blocked,
      'completed' || 'done' => c.completed,
      'cancelled' => c.cancelled,
      'skipped' => c.skipped,
      'missed' => c.missed,
      'active' => c.success,
      'paused' => c.warning,
      'archived' => c.cancelled,
      _ => c.todo,
    };
  }

  /// Options for a [FilterBar] status chip.
  static List<FilterOption<String>> filterOptions(BuildContext context, Iterable<String> statuses) => [
    for (final s in statuses) FilterOption(s, label(context, s), icon: icon(s), color: color(context, s)),
  ];
}

/// [StatusPill] for a status value (icon + localized label + color).
class EntityStatusPill extends StatelessWidget {
  const EntityStatusPill(this.status, {super.key, this.dense = false});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) => StatusPill(
    label: EntityStatusStyle.label(context, status),
    color: EntityStatusStyle.color(context, status),
    icon: EntityStatusStyle.icon(status),
    dense: dense,
  );
}
