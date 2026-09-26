import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/recurrence_ui/domain/recurrence_exception.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Exceptions manager (T2.1.19): the cancelled, moved, edited and excluded occurrences of a
/// series with *Restore* / *Open* per entry and a bulk *Restore all*. Storage-agnostic: the
/// owner (planner, habits…) maps its records to [RecurrenceExceptionEntry]s and performs the
/// restore.
class RecurrenceExceptionsView extends ConsumerStatefulWidget {
  const RecurrenceExceptionsView({
    required this.exceptions,
    required this.onRestore,
    super.key,
    this.onRestoreAll,
    this.onOpen,
    this.shrinkWrap = false,
  });

  final List<RecurrenceExceptionEntry> exceptions;
  final Future<void> Function(RecurrenceExceptionEntry entry) onRestore;

  /// Restores every entry in one operation (null hides the button).
  final Future<void> Function()? onRestoreAll;

  /// Opens the occurrence (null hides the button; cancelled/excluded entries have nothing to open).
  final void Function(RecurrenceExceptionEntry entry)? onOpen;
  final bool shrinkWrap;

  @override
  ConsumerState<RecurrenceExceptionsView> createState() => _RecurrenceExceptionsViewState();
}

class _RecurrenceExceptionsViewState extends ConsumerState<RecurrenceExceptionsView> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showInfoSnackBar(context, context.l10n.recurExceptionsRestored);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final format = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final entries = [...widget.exceptions]..sort(RecurrenceExceptionEntry.compare);
    if (entries.isEmpty) {
      return EmptyState(
        key: const ValueKey('recur-exceptions-empty'),
        title: l.recurExceptionsEmpty,
        icon: Icons.event_available_outlined,
      );
    }
    final restoreAll = widget.onRestoreAll;
    return ListView(
      shrinkWrap: widget.shrinkWrap,
      children: [
        if (restoreAll != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xs),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                key: const ValueKey('recur-exceptions-restore-all'),
                onPressed: _busy
                    ? null
                    : () async {
                        final ok = await confirmDialog(
                          context,
                          title: l.recurExceptionRestoreAllTitle(entries.length),
                          confirmLabel: l.recurExceptionRestoreAll,
                        );
                        if (ok) await _run(restoreAll);
                      },
                icon: const Icon(Icons.restore),
                label: Text(l.recurExceptionRestoreAll),
              ),
            ),
          ),
        for (final e in entries) _tile(context, e, format),
      ],
    );
  }

  Widget _tile(BuildContext context, RecurrenceExceptionEntry e, AppFormat format) {
    final l = context.l10n;
    String when(LocalDateTime? t, {bool dateOnly = false}) {
      if (t == null) return e.key;
      final date = DateFormat.yMMMEd(format.locale).format(t.date.toDateTimeUtc());
      return dateOnly ? date : '$date ${format.time(t.time)}';
    }

    final (icon, subtitle) = switch (e.kind) {
      RecurrenceExceptionKind.cancelled => (Icons.event_busy_outlined, l.recurExceptionCancelled),
      RecurrenceExceptionKind.moved => (
        Icons.move_down_outlined,
        l.recurExceptionMoved(when(e.movedTo, dateOnly: e.isDateKey)),
      ),
      RecurrenceExceptionKind.edited => (Icons.edit_outlined, l.recurExceptionEdited),
      RecurrenceExceptionKind.excluded => (Icons.block_outlined, l.recurExceptionExcluded),
    };
    final open = widget.onOpen;
    final canOpen =
        open != null && (e.kind == RecurrenceExceptionKind.moved || e.kind == RecurrenceExceptionKind.edited);
    return ListTile(
      key: ValueKey('recur-exception-${e.key}'),
      leading: Icon(icon),
      title: Text(
        when(e.originalStart, dateOnly: e.isDateKey),
        style: e.kind == RecurrenceExceptionKind.cancelled || e.kind == RecurrenceExceptionKind.excluded
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(e.title == null ? subtitle : '$subtitle · ${e.title}'),
      onTap: canOpen ? () => open(e) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canOpen)
            IconButton(
              key: ValueKey('recur-exception-open-${e.key}'),
              tooltip: l.recurExceptionOpen,
              onPressed: () => open(e),
              icon: const Icon(Icons.open_in_new),
            ),
          IconButton(
            key: ValueKey('recur-exception-restore-${e.key}'),
            tooltip: l.recurExceptionRestore,
            onPressed: _busy ? null : () => _run(() => widget.onRestore(e)),
            icon: const Icon(Icons.restore),
          ),
        ],
      ),
    );
  }
}
