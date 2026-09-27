import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot/features/planner/presentation/value_tile.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/timezone.dart' as tz;

/// Snackbar with *Undo* for an operation the planner service already put on the undo stack.
void showPlannerUndoSnack(BuildContext context, WidgetRef ref, String message) {
  final stack = ref.read(undoStackProvider);
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: context.l10n.actionUndo, onPressed: () => stack.undo()),
      ),
    );
}

// ---------------------------------------------------------------------------
// Edit / delete scope (T3.2.06, T3.2.08, T3.2.11)

/// The scope picked for a recurring task edit or delete.
@immutable
class ScopeChoice {
  const ScopeChoice(this.scope, {this.rewritePast = false});

  final EditScope scope;

  /// *Also rewrite past occurrences* (timing edits of all occurrences, T3.2.08).
  final bool rewritePast;
}

/// Asks *This occurrence* / *This and following* / *All occurrences*, showing only valid options:
/// *This occurrence* is disabled (with its explanation) for series-level edits; timing edits of
/// all occurrences explain that past ones keep their times and offer to rewrite them.
Future<ScopeChoice?> showEditScopeDialog(
  BuildContext context, {
  bool deleting = false,
  bool thisAllowed = true,
  bool followingAllowed = true,
  bool timingChange = false,
}) => showDialog<ScopeChoice>(
  context: context,
  builder: (_) => _ScopeDialog(
    deleting: deleting,
    thisAllowed: thisAllowed,
    followingAllowed: followingAllowed,
    timingChange: timingChange,
  ),
);

class _ScopeDialog extends StatefulWidget {
  const _ScopeDialog({
    required this.deleting,
    required this.thisAllowed,
    required this.followingAllowed,
    required this.timingChange,
  });

  final bool deleting;
  final bool thisAllowed;
  final bool followingAllowed;
  final bool timingChange;

  @override
  State<_ScopeDialog> createState() => _ScopeDialogState();
}

class _ScopeDialogState extends State<_ScopeDialog> {
  late EditScope _scope = widget.thisAllowed
      ? EditScope.thisOccurrence
      : (widget.followingAllowed ? EditScope.thisAndFollowing : EditScope.allOccurrences);
  bool _rewritePast = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pastNote = widget.timingChange && !widget.deleting;
    return AlertDialog(
      title: Text(widget.deleting ? l.tasksScopeDeleteTitle : l.tasksScopeTitle),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(0, Space.lg, 0, 0),
      content: SingleChildScrollView(
        child: RadioGroup<EditScope>(
          groupValue: _scope,
          onChanged: (s) {
            if (s != null) setState(() => _scope = s);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<EditScope>(
                key: const ValueKey('scope-this'),
                value: EditScope.thisOccurrence,
                enabled: widget.thisAllowed,
                title: Text(l.tasksScopeThis),
                subtitle: widget.thisAllowed ? null : Text(l.tasksScopeThisDisabled),
              ),
              if (widget.followingAllowed)
                RadioListTile<EditScope>(
                  key: const ValueKey('scope-following'),
                  value: EditScope.thisAndFollowing,
                  title: Text(l.tasksScopeFollowing),
                ),
              RadioListTile<EditScope>(
                key: const ValueKey('scope-all'),
                value: EditScope.allOccurrences,
                title: Text(l.tasksScopeAll),
                subtitle: pastNote && !_rewritePast ? Text(l.tasksScopePastKept) : null,
              ),
              if (pastNote && _scope == EditScope.allOccurrences)
                CheckboxListTile(
                  key: const ValueKey('scope-rewrite-past'),
                  value: _rewritePast,
                  onChanged: (v) => setState(() => _rewritePast = v ?? false),
                  title: Text(l.tasksScopeRewritePast),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.actionCancel)),
        FilledButton(
          key: const ValueKey('scope-ok'),
          style: widget.deleting
              ? FilledButton.styleFrom(backgroundColor: context.colors.error, foregroundColor: context.colors.onError)
              : null,
          onPressed: () => Navigator.pop(context, ScopeChoice(_scope, rewritePast: _rewritePast)),
          child: Text(widget.deleting ? l.actionDelete : l.actionContinue),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Orphans (T3.2.09)

/// Lists the records a rule change leaves behind ("2 moved occurrences, 5 completed
/// occurrences"); outcomes are always kept as one-off tasks, moved ones can be discarded.
Future<OrphanPolicy?> showOrphansDialog(BuildContext context, OrphanReport report) {
  final l = context.l10n;
  return showDialog<OrphanPolicy>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.tasksOrphansTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (report.movedCount > 0) Text('• ${l.tasksOrphansMoved(report.movedCount)}'),
            if (report.completedCount > 0) Text('• ${l.tasksOrphansCompleted(report.completedCount)}'),
            if (report.skippedCount > 0) Text('• ${l.tasksOrphansSkipped(report.skippedCount)}'),
            if (report.otherOutcomeCount > 0) Text('• ${l.tasksOrphansOther(report.otherOutcomeCount)}'),
            const SizedBox(height: Space.md),
            Text(l.tasksOrphansBody, style: ctx.text.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.actionCancel)),
        if (report.needsChoice)
          TextButton(
            key: const ValueKey('orphans-discard'),
            onPressed: () => Navigator.pop(ctx, OrphanPolicy.discard),
            child: Text(l.tasksOrphansDiscard),
          ),
        FilledButton(
          key: const ValueKey('orphans-keep'),
          onPressed: () => Navigator.pop(ctx, OrphanPolicy.keepAsOneOff),
          child: Text(l.tasksOrphansKeep),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Skip reason (T3.2.05)

/// Localized label of a stored skip reason (key or free text).
String skipReasonLabel(BuildContext context, String? reason) {
  final l = context.l10n;
  return switch (reason) {
    SkipReasons.tooBusy => l.tasksSkipTooBusy,
    SkipReasons.sick => l.tasksSkipSick,
    SkipReasons.notNeeded => l.tasksSkipNotNeeded,
    SkipReasons.forgot => l.tasksSkipForgot,
    SkipReasons.other => l.tasksSkipOther,
    null => '',
    final text => text,
  };
}

/// Quick reasons + free text. Returns the reason key or text ('' = no reason), null on cancel.
Future<String?> showSkipReasonDialog(BuildContext context) => showDialog<String>(
  context: context,
  builder: (_) => const _SkipDialog(),
);

class _SkipDialog extends StatefulWidget {
  const _SkipDialog();

  @override
  State<_SkipDialog> createState() => _SkipDialogState();
}

class _SkipDialogState extends State<_SkipDialog> {
  String? _key;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.tasksSkipTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final key in SkipReasons.all)
                  ChoiceChip(
                    key: ValueKey('skip-$key'),
                    label: Text(skipReasonLabel(context, key)),
                    selected: _key == key,
                    onSelected: (on) => setState(() => _key = on ? key : null),
                  ),
              ],
            ),
            const SizedBox(height: Space.md),
            TextField(
              key: const ValueKey('skip-text'),
              controller: _text,
              maxLength: SkipReasons.maxLength,
              decoration: InputDecoration(hintText: l.tasksSkipCustomHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.actionCancel)),
        FilledButton(
          key: const ValueKey('skip-ok'),
          onPressed: () {
            final text = _text.text.trim();
            Navigator.pop(context, text.isNotEmpty ? text : (_key ?? ''));
          },
          child: Text(l.actionSkip),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Actual time on done (T3.2.14)

@immutable
class ActualTimeChoice {
  const ActualTimeChoice(this.option, {this.start, this.end});

  final ActualTimeOption option;

  /// Custom times (UTC).
  final DateTime? start;
  final DateTime? end;
}

/// *As planned* / *Just now* / *Custom…* (start and end on the occurrence's day, viewer clock).
Future<ActualTimeChoice?> showActualTimeDialog(
  BuildContext context, {
  required PlannerItem item,
  required DateTime Function(LocalDateTime local) toUtc,
  required bool use24h,
}) => showDialog<ActualTimeChoice>(
  context: context,
  builder: (_) => _ActualTimeDialog(item: item, toUtc: toUtc, use24h: use24h),
);

class _ActualTimeDialog extends StatefulWidget {
  const _ActualTimeDialog({required this.item, required this.toUtc, required this.use24h});

  final PlannerItem item;
  final DateTime Function(LocalDateTime local) toUtc;
  final bool use24h;

  @override
  State<_ActualTimeDialog> createState() => _ActualTimeDialogState();
}

class _ActualTimeDialogState extends State<_ActualTimeDialog> {
  bool _custom = false;
  late LocalDateTime _start = widget.item.startLocal;
  late LocalDateTime _end = widget.item.startLocal.plusMinutes(widget.item.durationMinutes);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final format = AppFormat(context.localeName, use24h: widget.use24h, l10n: l);
    final invalid = _end.isBefore(_start);
    Future<void> pick(bool start) async {
      final current = start ? _start : _end;
      final t = await pickTime(context, initial: current.time, use24h: widget.use24h);
      if (t == null || !mounted) return;
      setState(() {
        final value = current.date.atTime(t);
        if (start) {
          _start = value;
        } else {
          _end = value;
        }
      });
    }

    return AlertDialog(
      title: Text(l.tasksActualTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('actual-as-planned'),
              leading: const Icon(Icons.event_available_outlined),
              title: Text(l.tasksActualAsPlanned),
              subtitle: Text(format.timeRange(widget.item.startLocal, widget.item.startLocal.plusMinutes(widget.item.durationMinutes))),
              onTap: () => Navigator.pop(context, const ActualTimeChoice(ActualTimeOption.asPlanned)),
            ),
            ListTile(
              key: const ValueKey('actual-just-now'),
              leading: const Icon(Icons.bolt_outlined),
              title: Text(l.tasksActualJustNow),
              onTap: () => Navigator.pop(context, const ActualTimeChoice(ActualTimeOption.justNow)),
            ),
            ListTile(
              key: const ValueKey('actual-custom'),
              leading: const Icon(Icons.edit_calendar_outlined),
              title: Text(l.tasksActualCustom),
              onTap: () => setState(() => _custom = true),
            ),
            if (_custom) ...[
              ValueTile(
                key: const ValueKey('actual-start'),
                label: l.tasksFieldStart,
                value: format.timeOf(_start),
                onTap: () => pick(true),
              ),
              ValueTile(
                key: const ValueKey('actual-end'),
                label: l.tasksFieldEnd,
                value: format.timeOf(_end),
                onTap: () => pick(false),
              ),
              if (invalid)
                Text(l.tasksActualEndBeforeStart, style: context.text.bodySmall?.copyWith(color: context.colors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.actionCancel)),
        if (_custom)
          FilledButton(
            key: const ValueKey('actual-ok'),
            onPressed: invalid
                ? null
                : () => Navigator.pop(
                    context,
                    ActualTimeChoice(ActualTimeOption.custom, start: widget.toUtc(_start), end: widget.toUtc(_end)),
                  ),
            child: Text(l.actionDone),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Postpone (T3.2.10)

/// *Postpone* quick options (+15 min, +1 h, this evening, tomorrow / next week same time, pick…).
/// Returns the new start (viewer wall clock) or null.
Future<LocalDateTime?> showPostponeSheet(
  BuildContext context, {
  required LocalDateTime currentStart,
  required LocalDateTime nowLocal,
  required bool use24h,
}) {
  final l = context.l10n;
  final format = AppFormat(context.localeName, use24h: use24h, l10n: l);
  String when(LocalDateTime t) =>
      t.date == nowLocal.date ? format.timeOf(t) : '${format.dayShort(t.date)} ${format.timeOf(t)}';
  return showAppSheet<LocalDateTime>(
    context,
    title: l.tasksPostponeTitle,
    builder: (ctx) => ListView(
      shrinkWrap: true,
      children: [
        for (final (option, label) in [
          (PostponeOption.plus15Minutes, l.tasksPostpone15),
          (PostponeOption.plus1Hour, l.tasksPostpone1h),
          (PostponeOption.thisEvening, l.tasksPostponeEvening),
          (PostponeOption.tomorrowSameTime, l.tasksPostponeTomorrow),
          (PostponeOption.nextWeekSameTime, l.tasksPostponeNextWeek),
        ])
          Builder(
            builder: (_) {
              final target = postponeTarget(option, currentStart: currentStart, nowLocal: nowLocal);
              return ValueTile(
                key: ValueKey('postpone-${option.name}'),
                label: label,
                value: when(target),
                onTap: () => Navigator.pop(ctx, target),
              );
            },
          ),
        ListTile(
          key: const ValueKey('postpone-pick'),
          leading: const Icon(Icons.edit_calendar_outlined),
          title: Text(l.tasksPostponePick),
          onTap: () async {
            final date = await pickDate(ctx, initial: currentStart.date);
            if (date == null || !ctx.mounted) return;
            final time = await pickTime(ctx, initial: currentStart.time, use24h: use24h);
            if (time == null || !ctx.mounted) return;
            Navigator.pop(ctx, date.atTime(time));
          },
        ),
        const SizedBox(height: Space.md),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Duplicate to… (T3.1.19)

/// Multi-date calendar. Returns the chosen dates (sorted) or null.
Future<List<LocalDate>?> showDuplicateToDialog(
  BuildContext context, {
  required LocalDate initialMonth,
  required Weekday weekStart,
}) => showDialog<List<LocalDate>>(
  context: context,
  builder: (_) => _DuplicateToDialog(initialMonth: initialMonth.firstDayOfMonth, weekStart: weekStart),
);

class _DuplicateToDialog extends StatefulWidget {
  const _DuplicateToDialog({required this.initialMonth, required this.weekStart});

  final LocalDate initialMonth;
  final Weekday weekStart;

  @override
  State<_DuplicateToDialog> createState() => _DuplicateToDialogState();
}

class _DuplicateToDialogState extends State<_DuplicateToDialog> {
  late LocalDate _month = widget.initialMonth;
  final Set<LocalDate> _picked = {};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = context.localeName;
    final format = AppFormat(locale, l10n: l);
    final first = _month.startOfWeek(widget.weekStart);
    final last = _month.lastDayOfMonth;
    final weeks = first.daysUntil(last) ~/ 7 + 1;
    final narrow = DateFormat.EEEEE(locale);
    return AlertDialog(
      title: Text(l.tasksDuplicateToTitle),
      content: SizedBox(
        width: 7 * 44,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: l.tasksPrevMonth,
                    onPressed: () => setState(() => _month = _month.plusMonths(-1)),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(child: Text(format.monthYear(_month), textAlign: TextAlign.center)),
                  IconButton(
                    tooltip: l.tasksNextMonth,
                    onPressed: () => setState(() => _month = _month.plusMonths(1)),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Row(
                children: [
                  for (final d in Weekday.ordered(widget.weekStart))
                    Expanded(child: Center(child: Text(narrow.format(DateTime.utc(2024, 1, d.iso)), style: context.text.labelSmall))),
                ],
              ),
              for (var w = 0; w < weeks; w++)
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final day = first.plusDays(w * 7 + i);
                            if (day.month != _month.month) return const SizedBox(height: 44);
                            final on = _picked.contains(day);
                            return Semantics(
                              button: true,
                              selected: on,
                              label: format.dateMedium(day),
                              excludeSemantics: true,
                              child: InkWell(
                                key: ValueKey('dup-${day.toIso()}'),
                                customBorder: const CircleBorder(),
                                onTap: () => setState(() => on ? _picked.remove(day) : _picked.add(day)),
                                child: Container(
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: on ? BoxDecoration(color: context.colors.primary, shape: BoxShape.circle) : null,
                                  child: Text('${day.day}', style: TextStyle(color: on ? context.colors.onPrimary : null)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.actionCancel)),
        FilledButton(
          key: const ValueKey('dup-ok'),
          onPressed: _picked.isEmpty ? null : () => Navigator.pop(context, _picked.toList()..sort()),
          child: Text(l.tasksDuplicateToConfirm(_picked.length)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Time zone picker (T3.1.06)

/// "UTC+05:30" for a zone at [nowUtc].
String zoneOffsetLabel(String zone, DateTime nowUtc) {
  try {
    final minutes = zone == 'UTC' ? 0 : tz.getLocation(zone).timeZone(nowUtc.millisecondsSinceEpoch).offset.inMinutes;
    final sign = minutes < 0 ? '−' : '+';
    final abs = minutes.abs();
    return 'UTC$sign${'${abs ~/ 60}'.padLeft(2, '0')}:${'${abs % 60}'.padLeft(2, '0')}';
  } on Object {
    return '';
  }
}

/// Searchable IANA zone picker showing each zone's current offset (device zone first).
Future<String?> pickTimeZone(
  BuildContext context, {
  required String deviceZone,
  required DateTime nowUtc,
  String? selected,
}) => showAppSheet<String>(
  context,
  title: context.l10n.tasksZonePickTitle,
  builder: (_) => _ZonePicker(deviceZone: deviceZone, nowUtc: nowUtc, selected: selected),
);

class _ZonePicker extends StatefulWidget {
  const _ZonePicker({required this.deviceZone, required this.nowUtc, this.selected});

  final String deviceZone;
  final DateTime nowUtc;
  final String? selected;

  @override
  State<_ZonePicker> createState() => _ZonePickerState();
}

class _ZonePickerState extends State<_ZonePicker> {
  String _query = '';
  late final List<String> _zones = () {
    final all = tz.timeZoneDatabase.locations.keys.where((z) => z.contains('/') && !z.startsWith('Etc/')).toList()..sort();
    return [
      widget.deviceZone,
      if (widget.selected != null && widget.selected != widget.deviceZone) widget.selected!,
      'UTC',
      ...all.where((z) => z != widget.deviceZone && z != widget.selected),
    ];
  }();

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase().replaceAll(' ', '_');
    final zones = q.isEmpty ? _zones : _zones.where((z) => z.toLowerCase().contains(q)).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: TextField(
              key: const ValueKey('zone-search'),
              autofocus: false,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.l10n.tasksZoneSearch),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: zones.length,
              itemBuilder: (context, i) {
                final zone = zones[i];
                return ListTile(
                  key: ValueKey('zone-$zone'),
                  title: Text(zone.replaceAll('_', ' ')),
                  trailing: Text(zoneOffsetLabel(zone, widget.nowUtc)),
                  selected: zone == widget.selected,
                  onTap: () => Navigator.pop(context, zone),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Linked checklist picker (T3.1.16)

/// Result of [pickLinkedChecklist]: the checklist to link, null to unlink, or [createNew].
@immutable
class ChecklistChoice {
  const ChecklistChoice(this.id) : createNew = false;

  /// *New checklist*: the caller creates one and links it.
  const ChecklistChoice.createNew() : id = null, createNew = true;

  final String? id;
  final bool createNew;
}

/// Picks one of the user's checklists (with progress), or *None*.
Future<ChecklistChoice?> pickLinkedChecklist(BuildContext context, {String? selected}) =>
    showAppSheet<ChecklistChoice>(
      context,
      title: context.l10n.tasksChecklistPick,
      builder: (_) => _ChecklistPicker(selected: selected),
    );

class _ChecklistPicker extends ConsumerWidget {
  const _ChecklistPicker({this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lists = ref.watch(linkedChecklistsProvider).value ?? const [];
    return ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          key: const ValueKey('checklist-none'),
          leading: const Icon(Icons.link_off),
          title: Text(l.tasksChecklistNone),
          selected: selected == null,
          onTap: () => Navigator.pop(context, const ChecklistChoice(null)),
        ),
        ListTile(
          key: const ValueKey('checklist-new'),
          leading: const Icon(Icons.add),
          title: Text(l.tasksChecklistNew),
          onTap: () => Navigator.pop(context, const ChecklistChoice.createNew()),
        ),
        if (lists.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Text(l.tasksChecklistEmpty, style: context.text.bodyMedium),
          ),
        for (final c in lists)
          ListTile(
            key: ValueKey('checklist-${c.id}'),
            leading: const Icon(Icons.checklist),
            title: Text(c.title.isEmpty ? '—' : c.title),
            subtitle: Text(l.tasksChecklistProgress(c.completed, c.total)),
            selected: c.id == selected,
            onTap: () => Navigator.pop(context, ChecklistChoice(c.id)),
          ),
        const SizedBox(height: Space.md),
      ],
    );
  }
}
