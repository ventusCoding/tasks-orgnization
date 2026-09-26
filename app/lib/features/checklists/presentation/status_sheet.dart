import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/item_time.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A status chosen in the sheets (applied by the caller through the status service).
@immutable
class StatusChoice {
  const StatusChoice({required this.status, this.note, this.followUpAt, this.keepFollowUp = false, this.setNote = true});

  final ItemStatus status;
  final String? note;
  final DateTime? followUpAt;
  final bool keepFollowUp;

  /// False when the note must stay untouched (plain checkbox-style changes).
  final bool setNote;
}

/// Reason & follow-up captured by [showReasonSheet].
@immutable
class ReasonResult {
  const ReasonResult({this.note, this.followUpAt});

  final String? note;
  final DateTime? followUpAt;
}

/// The 6-status sheet (long-press on the status control / row menu, T4.3.03).
/// Waiting and blocked open the reason sheet directly (≤ 2 taps + typing, T4.3.08).
Future<StatusChoice?> showStatusSheet(
  BuildContext context,
  WidgetRef ref, {
  required ChecklistItem item,
  required ChecklistSettings settings,
}) async {
  final picked = await showAppSheet<Object>(
    context,
    title: context.l10n.statusSheetTitle,
    builder: (ctx) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in ItemStatus.values)
              ListTile(
                leading: Icon(StatusStyle.icon(s), color: StatusStyle.color(ctx, s)),
                title: Text(StatusStyle.label(ctx, s)),
                selected: s == item.status,
                trailing: s == item.status ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, s),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: Text(ctx.l10n.statusAddNote),
              subtitle: item.statusNote == null ? null : Text(item.statusNote!, maxLines: 2),
              onTap: () => Navigator.pop(ctx, 'note'),
            ),
            const SizedBox(height: Space.sm),
          ],
        ),
      ),
    ),
  );
  if (picked == null || !context.mounted) return null;
  final status = picked is ItemStatus ? picked : item.status;
  final wantsNote = picked == 'note' || status.promptsReason || settings.requiresReason(status);
  if (!wantsNote) return StatusChoice(status: status, setNote: false);
  final reason = await showReasonSheet(
    context,
    ref,
    status: status,
    initialNote: status == item.status ? item.statusNote : null,
    initialFollowUp: item.followUpAt,
    required: settings.requiresReason(status),
  );
  if (reason == null) return null;
  return StatusChoice(status: status, note: reason.note, followUpAt: reason.followUpAt);
}

/// Reason & follow-up sheet (T4.3.02): note field with the keyboard up, recent reasons as
/// chips, follow-up quick picks for waiting/blocked, Skip when the note is optional.
Future<ReasonResult?> showReasonSheet(
  BuildContext context,
  WidgetRef ref, {
  required ItemStatus status,
  String? initialNote,
  DateTime? initialFollowUp,
  bool required = false,
}) async {
  final recent = await ref.read(checklistItemsRepositoryProvider).recentStatusEvents(status);
  if (!context.mounted) return null;
  return showAppSheet<ReasonResult>(
    context,
    title: StatusStyle.label(context, status),
    builder: (ctx) => _ReasonSheet(
      status: status,
      initialNote: initialNote,
      initialFollowUp: initialFollowUp,
      required: required,
      recent: StatusHistory.recentReasons(recent, status),
    ),
  );
}

class _ReasonSheet extends ConsumerStatefulWidget {
  const _ReasonSheet({
    required this.status,
    required this.initialNote,
    required this.initialFollowUp,
    required this.required,
    required this.recent,
  });

  final ItemStatus status;
  final String? initialNote;
  final DateTime? initialFollowUp;
  final bool required;
  final List<String> recent;

  @override
  ConsumerState<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends ConsumerState<_ReasonSheet> {
  late final _note = TextEditingController(text: widget.initialNote);
  late DateTime? _followUp = widget.initialFollowUp;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String get _zone => ref.read(deviceZoneProvider);

  DateTime _at(LocalDate date, int hour) =>
      ref.read(zoneResolverProvider).resolve(date.atTime(LocalTime(hour, 0)), _zone).utc;

  LocalDateTime get _nowLocal => ref.read(zoneResolverProvider).toLocal(ref.read(clockProvider).nowUtc(), _zone);

  void _save() {
    final text = _note.text.trim();
    if (widget.required && text.isEmpty) {
      setState(() => _error = context.l10n.statusReasonRequired);
      return;
    }
    Navigator.pop(context, ReasonResult(note: text.isEmpty ? null : text, followUpAt: _followUp));
  }

  Future<void> _custom() async {
    final prefs = ref.read(userPreferencesProvider);
    final date = await pickDate(context, initial: _nowLocal.date.plusDays(1));
    if (date == null || !mounted) return;
    final time = await pickTime(context, initial: LocalTime(9, 0), use24h: prefs.use24h);
    if (!mounted) return;
    setState(() => _followUp = ref.read(zoneResolverProvider).resolve(date.atTime(time ?? LocalTime(9, 0)), _zone).utc);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hint = switch (widget.status) {
      ItemStatus.waiting => l.statusReasonWaiting,
      ItemStatus.blocked => l.statusReasonBlocked,
      _ => l.statusReasonOther,
    };
    final now = ref.read(clockProvider).nowUtc();
    final today = _nowLocal.date;
    final picks = <(String, DateTime)>[
      (l.statusFollowUpLaterToday, now.add(const Duration(hours: 3))),
      (l.statusFollowUpTomorrow, _at(today.plusDays(1), 9)),
      (l.statusFollowUpIn3Days, _at(today.plusDays(3), 9)),
      (l.statusFollowUpNextWeek, _at(today.startOfWeek(ref.read(userPreferencesProvider).weekStart).plusDays(7), 9)),
    ];
    final fmt = AppFormat(context.localeName, use24h: ref.read(userPreferencesProvider).use24h, l10n: l);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.pop(context),
      },
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, 0, Space.xl, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _note,
              autofocus: true,
              minLines: 2,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(hintText: hint, errorText: _error, border: const OutlineInputBorder()),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (widget.recent.isNotEmpty) ...[
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.xs,
                children: [
                  for (final r in widget.recent)
                    ActionChip(
                      label: Text(r, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onPressed: () => setState(() {
                        _note.text = r;
                        _note.selection = TextSelection.collapsed(offset: r.length);
                        _error = null;
                      }),
                    ),
                ],
              ),
            ],
            if (widget.status.keepsFollowUp) ...[
              const SizedBox(height: Space.md),
              Text(l.statusFollowUp, style: context.text.titleSmall),
              const SizedBox(height: Space.xs),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.xs,
                children: [
                  for (final (label, at) in picks)
                    ChoiceChip(
                      label: Text(label),
                      selected: _followUp == at,
                      onSelected: (v) => setState(() => _followUp = v ? at : null),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.event, size: 18),
                    label: Text(
                      _followUp != null && !picks.any((p) => p.$2 == _followUp)
                          ? fmt.dateTime(ref.read(zoneResolverProvider).toLocal(_followUp!, _zone))
                          : l.statusFollowUpCustom,
                    ),
                    onPressed: _custom,
                  ),
                  if (_followUp != null)
                    ActionChip(
                      avatar: const Icon(Icons.close, size: 18),
                      label: Text(l.statusFollowUpNone),
                      onPressed: () => setState(() => _followUp = null),
                    ),
                ],
              ),
            ],
            const SizedBox(height: Space.lg),
            Row(
              children: [
                if (!widget.required)
                  TextButton(
                    onPressed: () => Navigator.pop(context, ReasonResult(followUpAt: _followUp)),
                    child: Text(l.actionSkip),
                  ),
                const Spacer(),
                FilledButton(onPressed: _save, child: Text(l.actionSave)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Also complete N open sub-items?" (T4.3.07). Returns null on cancel.
Future<bool?> askCompleteDescendants(BuildContext context, int count) => showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(ctx.l10n.statusCascadeTitle(count)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.actionCancel)),
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.statusCascadeOnlyThis)),
      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l10n.statusCascadeAll)),
    ],
  ),
);
