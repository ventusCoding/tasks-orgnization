import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/undo/undo_stack.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/planner_contract.dart';
import 'package:everslot/features/planner/application/view_config/view_actions.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/day_actions_menu.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/snapping.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/planner_selection.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Haptics honouring the user's setting (appearance.haptics) with a 30/s throttle (T3.3.17).
class PlannerHaptics {
  PlannerHaptics(this._enabled);

  final bool Function() _enabled;
  final HapticThrottle _throttle = HapticThrottle();
  final Stopwatch _clock = Stopwatch()..start();

  void selection() {
    if (_enabled() && _throttle.tryFire(_clock.elapsed)) unawaited(HapticFeedback.selectionClick());
  }

  void lift() {
    if (_enabled()) unawaited(HapticFeedback.mediumImpact());
  }

  void success() {
    if (_enabled()) unawaited(HapticFeedback.lightImpact());
  }
}

final plannerHapticsProvider = Provider<PlannerHaptics>((ref) {
  bool enabled() {
    try {
      return ref.read(settingsProvider(SettingsNs.appearance)).value?['haptics'] != false;
    } on Object {
      return true;
    }
  }

  return PlannerHaptics(enabled);
});

/// Runs planner mutations from views: one undo entry per command (SyncWriter records, or the demo
/// store history), scope dialog for recurring tasks, confirmation before moving done items.
class PlannerCommands {
  PlannerCommands(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  PlannerActions get actions => ref.read(viewActionsProvider);

  /// Extra mutations (delete, duplicate, manual order, unschedule, timers).
  PlannerViewActions get extra => ref.read(viewExtraActionsProvider);

  /// Runs one user command through the contract actions (one undo entry in the snackbar).
  Future<void> run(String message, Future<void> Function(PlannerActions a) body) => track(message, () => body(actions));

  /// Runs one user command through the extra view actions.
  Future<void> runExtra(String message, Future<void> Function(PlannerViewActions a) body) => track(message, () => body(extra));

  /// Runs [body] and shows [message] with an *Undo* action covering everything it wrote. The planner
  /// service registers its own undo entries (undone from the snackbar); other SyncWriter operations
  /// are merged into one entry; demo mode rewinds the demo store.
  Future<void> track(String message, Future<void> Function() body) async {
    if (ref.read(plannerDemoModeProvider)) {
      final store = ref.read(demoPlannerStoreProvider.notifier);
      final before = store.historyLength;
      await body();
      final steps = store.historyLength - before;
      if (!context.mounted) return;
      _snack(message, steps <= 0 ? null : () {
        for (var i = 0; i < steps; i++) {
          store.undo();
        }
      });
      return;
    }
    SyncWriter? writer;
    UndoStack? stack;
    try {
      writer = ref.read(syncWriterProvider);
      stack = ref.read(undoStackProvider);
    } on Object {
      writer = null;
      stack = null;
    }
    final records = <OpRecord>[];
    var pushes = 0;
    void onStack() => pushes++;
    stack?.addListener(onStack);
    final sub = writer?.committed.listen(records.add);
    try {
      await body();
      await Future<void>.microtask(() {});
    } finally {
      // Not awaited: a cancelled subscription gets no further events, and the cancel future of a
      // broadcast stream completes in the root zone (it would stall under fake-async tests).
      unawaited(sub?.cancel());
      stack?.removeListener(onStack);
    }
    if (!context.mounted) return;
    if (pushes > 0 && stack != null) {
      final target = stack;
      final count = pushes;
      _snack(message, () async {
        for (var i = 0; i < count; i++) {
          if (!await target.undo()) break;
        }
      });
      return;
    }
    if (records.isEmpty) {
      _snack(message, null);
      return;
    }
    final merged = records.length == 1
        ? records.single
        : OpRecord(opId: records.first.opId, cause: 'user', changes: [for (final r in records) ...r.changes]);
    showUndoSnackBar(context, ref, message: message, record: merged);
  }

  void _snack(String message, VoidCallback? undo) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        action: undo == null ? null : SnackBarAction(label: context.l10n.actionUndo, onPressed: undo),
      ));
  }

  Future<EditScope?> askScope(PlannerItem item) async {
    if (!item.isRecurring) return EditScope.thisOccurrence;
    final l = context.l10n;
    return showDialog<EditScope>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.pvScopeTitle),
        children: [
          for (final (scope, label) in [
            (EditScope.thisOccurrence, l.pvScopeThis),
            (EditScope.thisAndFollowing, l.pvScopeFollowing),
            (EditScope.allOccurrences, l.pvScopeAll),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, scope),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: Space.sm), child: Text(label)),
            ),
        ],
      ),
    );
  }

  Future<bool> confirmMoveDone(PlannerItem item) async {
    if (item.status != OccurrenceStatus.done) return true;
    final l = context.l10n;
    return confirmDialog(context, title: l.pvMoveDoneTitle, body: l.pvMoveDoneBody, confirmLabel: l.pvMove);
  }

  /// Move / resize / lane ↔ grid (T3.3.16, T3.3.19): one undoable command.
  Future<bool> reschedule(
    PlannerItem item, {
    required LocalDateTime start,
    int? duration,
    bool? allDay,
    required String message,
  }) async {
    final haptics = ref.read(plannerHapticsProvider);
    if (!await confirmMoveDone(item)) return false;
    if (!context.mounted) return false;
    final scope = await askScope(item);
    if (scope == null || !context.mounted) return false;
    await run(message, (a) => a.reschedule(item, newStart: start, newDurationMinutes: duration, allDay: allDay, scope: scope));
    haptics.success();
    return true;
  }

  Future<void> setStatus(PlannerItem item, OccurrenceStatus status) =>
      run(context.l10n.pvStatusSnack(context.statusLabel(status).toLowerCase()), (a) => a.setStatus(item, status));

  Future<void> toggleDone(PlannerItem item) async {
    ref.read(plannerHapticsProvider).success();
    await setStatus(item, item.status == OccurrenceStatus.done ? OccurrenceStatus.scheduled : OccurrenceStatus.done);
  }

  /// Quick create with a title prompt (T3.3.15); "More options" opens the full editor.
  Future<String?> quickCreate({required LocalDateTime start, required int duration, bool allDay = false, String? title}) async {
    final result = title != null
        ? (title: title, more: false)
        : await showAppSheet<({String title, bool more})>(
            context,
            builder: (ctx) => QuickCreateSheet(start: start, duration: duration, allDay: allDay),
          );
    if (result == null || !context.mounted) return null;
    if (result.more) {
      ref.read(plannerNavProvider).newTask(context, start: start, duration: duration, allDay: allDay);
      return null;
    }
    String? id;
    await run(context.l10n.pvCreatedSnack, (a) async {
      id = await a.createAt(start, duration, title: result.title.isEmpty ? null : result.title, allDay: allDay);
    });
    return id;
  }

  Future<void> duplicate(PlannerItem item) => runExtra(context.l10n.pvCreatedSnack, (a) => a.duplicate(item));

  /// Deletes [item]; recurring tasks ask for the scope (*this occurrence* cancels one occurrence).
  Future<void> delete(PlannerItem item) async {
    final l = context.l10n;
    final scope = item.isRecurring && !item.isBacklog
        ? await askScope(item)
        : (await confirmDialog(context, title: l.actionDelete, body: item.title, confirmLabel: l.actionDelete, destructive: true)
              ? EditScope.allOccurrences
              : null);
    if (scope == null || !context.mounted) return;
    await runExtra(l.actionDelete, (a) => a.delete(item, scope: scope));
  }

  /// Copies [item] for Ctrl/Cmd + V (T3.1.19).
  void copy(PlannerItem item) {
    ref.read(plannerClipboardProvider.notifier).copy(item);
    _snack(context.l10n.pvCopied(item.title), null);
  }

  /// Pastes the copied item as a one-off task at [start] (one undoable operation).
  Future<void> paste(LocalDateTime start) async {
    final l = context.l10n;
    final item = ref.read(plannerClipboardProvider);
    if (item == null) {
      _snack(l.pvNothingToPaste, null);
      return;
    }
    final f = context.plannerFormat(use24h: ref.read(userPreferencesProvider).use24h);
    await runExtra(l.pvPasted('${f.dayShort(start.date)} ${f.timeOf(start)}'), (a) => a.paste(item, item.allDay ? start.date.atStartOfDay : start));
  }

  /// Long-press-release quick menu (T3.4.12): Done, Skip, Start, Postpone ▸, Edit, Duplicate, Copy,
  /// Select (views with a selection mode pass [onSelect]), Cancel, Delete.
  Future<void> showTileMenu(PlannerItem item, {VoidCallback? onSelect}) async {
    final l = context.l10n;
    final done = item.status == OccurrenceStatus.done;
    final action = await showAppSheet<String>(
      context,
      title: item.title,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          if (onSelect != null)
            ListTile(
              key: const Key('tile-menu-select'),
              leading: const Icon(Icons.check_box_outlined),
              title: Text(l.pvSelect),
              onTap: () => Navigator.pop(ctx, 'select'),
            ),
          ListTile(
            leading: Icon(done ? Icons.remove_done : Icons.check_circle_outline),
            title: Text(done ? l.pvMarkNotDone : l.pvMarkDone),
            onTap: () => Navigator.pop(ctx, 'done'),
          ),
          ListTile(leading: const Icon(Icons.skip_next_outlined), title: Text(l.pvSkip), onTap: () => Navigator.pop(ctx, 'skip')),
          if (item.status != OccurrenceStatus.inProgress)
            ListTile(leading: const Icon(Icons.play_arrow_outlined), title: Text(l.pvStart), onTap: () => Navigator.pop(ctx, 'start')),
          ExpansionTile(
            leading: const Icon(Icons.schedule_send_outlined),
            title: Text(l.pvPostpone),
            children: [
              for (final (key, label) in [
                ('p15', l.pvPostponeMinutes(15)),
                ('p60', l.pvPostponeMinutes(60)),
                ('ptomorrow', l.pvPostponeTomorrow),
                ('pweek', l.pvPostponeNextWeek),
              ])
                ListTile(
                  contentPadding: const EdgeInsetsDirectional.only(start: Space.xxxl + Space.lg, end: Space.lg),
                  title: Text(label),
                  onTap: () => Navigator.pop(ctx, key),
                ),
            ],
          ),
          ListTile(leading: const Icon(Icons.edit_outlined), title: Text(l.actionEdit), onTap: () => Navigator.pop(ctx, 'edit')),
          ListTile(leading: const Icon(Icons.copy_outlined), title: Text(l.actionDuplicate), onTap: () => Navigator.pop(ctx, 'duplicate')),
          ListTile(leading: const Icon(Icons.content_copy), title: Text(l.pvCopy), onTap: () => Navigator.pop(ctx, 'copy')),
          if (item.isRecurring)
            ListTile(leading: const Icon(Icons.block), title: Text(l.pvCancelOccurrence), onTap: () => Navigator.pop(ctx, 'cancel')),
          ListTile(
            leading: Icon(Icons.delete_outline, color: ctx.colors.error),
            title: Text(l.actionDelete, style: TextStyle(color: ctx.colors.error)),
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
          const SizedBox(height: Space.sm),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    final f = context.plannerFormat(use24h: ref.read(userPreferencesProvider).use24h);
    Future<void> postpone(LocalDateTime to) =>
        reschedule(item, start: to, message: l.pvMovedSnack('${f.dayShort(to.date)} ${f.timeOf(to)}'));
    switch (action) {
      case 'done':
        await toggleDone(item);
      case 'skip':
        await setStatus(item, OccurrenceStatus.skipped);
      case 'start':
        await setStatus(item, OccurrenceStatus.inProgress);
      case 'p15':
        await postpone(item.startLocal.plusMinutes(15));
      case 'p60':
        await postpone(item.startLocal.plusMinutes(60));
      case 'ptomorrow':
        await postpone(item.startLocal.plusDays(1));
      case 'pweek':
        await postpone(item.startLocal.plusDays(7));
      case 'edit':
        ref.read(plannerNavProvider).openTask(context, item);
      case 'duplicate':
        await duplicate(item);
      case 'copy':
        copy(item);
      case 'select':
        onSelect?.call();
      case 'cancel':
        await setStatus(item, OccurrenceStatus.cancelled);
      case 'delete':
        await delete(item);
    }
  }

  /// "+N" popover (T3.4.14): hidden items with quick actions and *Open day*.
  Future<void> showOverflow(List<PlannerItem> items, {required LocalDate date}) async {
    final l = context.l10n;
    final f = context.plannerFormat(use24h: ref.read(userPreferencesProvider).use24h);
    final open = await showAppSheet<Object>(
      context,
      title: l.pvItemsCount(items.length),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          for (final i in items)
            ListTile(
              leading: i.trackingMode == TrackingMode.check
                  ? Checkbox(
                      value: i.status == OccurrenceStatus.done,
                      onChanged: (_) => Navigator.pop(ctx, ('toggle', i)),
                    )
                  : const Icon(Icons.event_outlined),
              title: Text(i.title),
              subtitle: Text(f.timeRange(i.startLocal, i.endLocal)),
              onTap: () => Navigator.pop(ctx, ('open', i)),
            ),
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'day'),
              icon: const Icon(Icons.view_day_outlined),
              label: Text(l.pvOpenDay),
            ),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    switch (open) {
      case ('toggle', final PlannerItem i):
        await toggleDone(i);
      case ('open', final PlannerItem i):
        ref.read(plannerNavProvider).openTask(context, i);
      case 'day':
        ref.read(plannerNavProvider).openView(context, 'day_list', date: date);
    }
  }

  /// Day header long-press menu (T3.3.09): add task, open the day, and planner-core's day actions
  /// (T3.2.23: mark remaining done, skip the rest, move unfinished to tomorrow).
  Future<void> showDayMenu(LocalDate date, List<PlannerItem> dayItems, {required LocalDateTime now}) async {
    final l = context.l10n;
    final f = context.plannerFormat(use24h: ref.read(userPreferencesProvider).use24h);
    final action = await showAppSheet<String>(
      context,
      title: f.dayLong(date),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(leading: const Icon(Icons.add), title: Text(l.pvAddTask), onTap: () => Navigator.pop(ctx, 'add')),
          ListTile(leading: const Icon(Icons.view_day_outlined), title: Text(l.pvOpenDay), onTap: () => Navigator.pop(ctx, 'open')),
          ListTile(leading: const Icon(Icons.done_all), title: Text(l.tasksDayDoneAll), onTap: () => Navigator.pop(ctx, 'done')),
          ListTile(leading: const Icon(Icons.skip_next_outlined), title: Text(l.tasksDaySkipRest), onTap: () => Navigator.pop(ctx, 'skip')),
          ListTile(leading: const Icon(Icons.redo), title: Text(l.tasksDayMoveTomorrow), onTap: () => Navigator.pop(ctx, 'move')),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'add':
        ref.read(plannerNavProvider).newTask(context, start: date.atTime(LocalTime(9, 0)), duration: 30);
      case 'open':
        ref.read(plannerNavProvider).openView(context, 'day_list', date: date);
      case 'done':
        await dayAction(date, DayAction.markRemainingDone, dayItems, now: now);
      case 'skip':
        await dayAction(date, DayAction.skipRest, dayItems, now: now);
      case 'move':
        await dayAction(date, DayAction.moveToTomorrow, dayItems, now: now);
    }
  }

  /// Runs a day action (T3.2.23) on [date]: planner-core's service call (one operation, one undo),
  /// or — in demo mode — the same rule applied item by item to [dayItems].
  Future<void> dayAction(LocalDate date, DayAction action, List<PlannerItem> dayItems, {required LocalDateTime now}) async {
    if (!ref.read(plannerDemoModeProvider)) {
      await runDayAction(context, ref, date, action);
      return;
    }
    final l = context.l10n;
    final open = [
      for (final i in dayItems)
        if (i.status == OccurrenceStatus.scheduled || i.status == OccurrenceStatus.missed || i.status == OccurrenceStatus.inProgress) i,
    ];
    final upcoming = [
      for (final i in open)
        if (!i.startLocal.isBefore(now)) i,
    ];
    switch (action) {
      case DayAction.markRemainingDone:
        await run(l.tasksDayDoneAllSnack(open.length), (a) async {
          for (final i in open) {
            await a.setStatus(i, OccurrenceStatus.done);
          }
        });
      case DayAction.skipRest:
        await run(l.tasksDaySkipRestSnack(upcoming.length), (a) async {
          for (final i in upcoming) {
            await a.setStatus(i, OccurrenceStatus.skipped);
          }
        });
      case DayAction.moveToTomorrow:
        await run(l.tasksDayMoveTomorrowSnack(open.length), (a) async {
          for (final i in open) {
            await a.reschedule(i, newStart: i.startLocal.plusDays(1));
          }
        });
    }
  }
}

/// Title prompt for quick create.
class QuickCreateSheet extends ConsumerStatefulWidget {
  const QuickCreateSheet({required this.start, required this.duration, this.allDay = false, super.key});

  final LocalDateTime start;
  final int duration;
  final bool allDay;

  @override
  ConsumerState<QuickCreateSheet> createState() => _QuickCreateSheetState();
}

class _QuickCreateSheetState extends ConsumerState<QuickCreateSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, (title: _controller.text.trim(), more: false));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final end = widget.start.plusMinutes(widget.duration);
    final when = widget.allDay
        ? '${f.dayLong(widget.start.date)} · ${l.pvAllDay}'
        : '${f.dayShort(widget.start.date)} ${f.timeRange(widget.start, end)} · ${f.duration(widget.duration)}';
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.pvQuickCreateTitle, style: context.text.titleLarge),
          const SizedBox(height: Space.xs),
          Text(when, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
          const SizedBox(height: Space.md),
          TextField(
            key: const Key('quick-create-title'),
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: l.pvQuickCreateHint),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, (title: _controller.text.trim(), more: true)),
                child: Text(l.pvMoreOptions),
              ),
              const Spacer(),
              FilledButton(key: const Key('quick-create-submit'), onPressed: _submit, child: Text(l.pvCreate)),
            ],
          ),
        ],
      ),
    );
  }
}
