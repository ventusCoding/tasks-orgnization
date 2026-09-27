import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/presentation/categories_screen.dart' show pickCategory;
import 'package:everslot/features/organization/presentation/tag_widgets.dart' show pickTags;
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/bulk_change.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/planner_dialogs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Bulk actions on a multi-selection of occurrences (T3.1.18) — the views' selection mode
/// opens this sheet. Every action runs as ONE operation (one undo). Returns true when an
/// action ran (the caller leaves selection mode).
Future<bool> showBulkActionsSheet(BuildContext context, List<PlannerItem> items) async =>
    (await showAppSheet<bool>(context, builder: (_) => BulkActionsSheet(items: items))) ?? false;

/// The targets of [items]: occurrences, or their whole series when [series] (duplicates of the
/// same task collapse into one series target).
List<BulkTarget> bulkTargets(List<PlannerItem> items, {required bool series}) => [
  for (final i in items)
    BulkTarget(i.taskId, occurrenceKey: i.occurrenceKey.isEmpty ? null : i.occurrenceKey, series: series && i.isRecurring),
];

class BulkActionsSheet extends ConsumerStatefulWidget {
  const BulkActionsSheet({required this.items, super.key});

  final List<PlannerItem> items;

  @override
  ConsumerState<BulkActionsSheet> createState() => _BulkActionsSheetState();
}

class _BulkActionsSheetState extends ConsumerState<BulkActionsSheet> {
  bool _series = false;
  bool _busy = false;

  bool get _hasRecurring => widget.items.any((i) => i.isRecurring);

  Future<void> _apply(BulkChange change) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l = context.l10n;
    final navigator = Navigator.of(context);
    try {
      await ref.read(plannerServiceProvider).bulk(bulkTargets(widget.items, series: _series), change);
      if (!mounted) return;
      showPlannerUndoSnack(context, ref, l.tasksBulkDone(widget.items.length));
      navigator.pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _category() async {
    final picked = await pickCategory(context, ref);
    if (picked == null || !mounted) return;
    await _apply(BulkSetCategory(picked.isEmpty ? null : picked));
  }

  Future<void> _priority() async {
    final l = context.l10n;
    final value = await showDialog<int>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.tasksBulkSetPriority),
        content: PrioritySelector(value: -1, onChanged: (p) => Navigator.pop(dialog, p)),
      ),
    );
    if (value == null || !mounted) return;
    await _apply(BulkSetPriority(value));
  }

  Future<void> _tracking() async {
    final l = context.l10n;
    final mode = await showDialog<TrackingMode>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(l.tasksBulkSetTracking),
        children: [
          for (final (mode, label) in [
            (TrackingMode.check, l.tasksTrackingCheck),
            (TrackingMode.event, l.tasksTrackingEvent),
            (TrackingMode.timer, l.tasksTrackingTimer),
          ])
            SimpleDialogOption(
              key: ValueKey('bulk-tracking-${mode.name}'),
              onPressed: () => Navigator.pop(dialog, mode),
              child: Text(label),
            ),
        ],
      ),
    );
    if (mode == null || !mounted) return;
    await _apply(BulkSetTrackingMode(mode));
  }

  Future<void> _tags() async {
    final picked = await pickTags(context, ref, selected: const {});
    if (picked == null || picked.isEmpty || !mounted) return;
    await _apply(BulkAddTags(picked));
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.tasksBulkDeleteConfirm(widget.items.length),
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (ok && mounted) await _apply(const BulkDelete());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget move(String key, String label, {int days = 0, int minutes = 0}) => ActionChip(
      key: ValueKey('bulk-move-$key'),
      label: Text(label),
      onPressed: _busy ? null : () => _apply(BulkMove(days: days, minutes: minutes)),
    );
    Widget action(String key, IconData icon, String label, VoidCallback onTap, {bool destructive = false}) => ListTile(
      key: ValueKey('bulk-$key'),
      enabled: !_busy,
      leading: Icon(icon, color: destructive ? context.colors.error : null),
      title: Text(label, style: destructive ? TextStyle(color: context.colors.error) : null),
      onTap: onTap,
    );
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsetsDirectional.only(bottom: Space.lg),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
          child: Text(l.tasksBulkTitle(widget.items.length), style: context.text.titleMedium),
        ),
        if (_hasRecurring) ...[
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
            child: Text(l.tasksBulkTarget, style: context.text.labelLarge),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.xs, Space.lg, Space.sm),
            child: SegmentedButton<bool>(
              key: const ValueKey('bulk-scope'),
              segments: [
                ButtonSegment(value: false, label: Text(l.tasksBulkTargetOccurrence)),
                ButtonSegment(value: true, label: Text(l.tasksBulkTargetSeries)),
              ],
              selected: {_series},
              onSelectionChanged: (s) => setState(() => _series = s.first),
            ),
          ),
        ],
        SectionHeader(l.tasksBulkMove),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
          child: Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              move('-1d', l.tasksBulkEarlierDay, days: -1),
              move('1d', l.tasksBulkLaterDay, days: 1),
              move('7d', l.tasksBulkLaterWeek, days: 7),
              move('-15m', l.tasksBulkEarlier15, minutes: -15),
              move('15m', l.tasksBulkLater15, minutes: 15),
              move('60m', l.tasksBulkLater1h, minutes: 60),
            ],
          ),
        ),
        const SizedBox(height: Space.sm),
        action('category', Icons.label_outline, l.tasksBulkSetCategory, _category),
        action('priority', Icons.flag_outlined, l.tasksBulkSetPriority, _priority),
        action('tracking', Icons.timer_outlined, l.tasksBulkSetTracking, _tracking),
        action('tags', Icons.sell_outlined, l.tasksBulkAddTags, _tags),
        action('duplicate', Icons.copy_outlined, l.tasksBulkDuplicate, () => _apply(const BulkDuplicate())),
        action('delete', Icons.delete_outline, l.tasksBulkDelete, _delete, destructive: true),
      ],
    );
  }
}
